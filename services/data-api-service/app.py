"""
AEC Data API Service
Flask-based REST API for data retrieval with caching and rate limiting
"""

import os
import json
import logging
from datetime import datetime
from functools import wraps

import redis
from flask import Flask, jsonify, request, g
from flask_cors import CORS
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from prometheus_client import Counter, Histogram, generate_latest
from pythonjsonlogger import jsonlogger
import psycopg2
from psycopg2.extras import RealDictCursor

# Configure structured logging
logHandler = logging.StreamHandler()
formatter = jsonlogger.JsonFormatter()
logHandler.setFormatter(formatter)
logger = logging.getLogger(__name__)
logger.addHandler(logHandler)
logger.setLevel(logging.INFO)

# Create Flask app
app = Flask(__name__)
CORS(app)

# Configuration
app.config['DATABASE_URL'] = os.getenv(
    'DATABASE_URL',
    'postgresql://postgres:postgres@localhost:5432/aec_data'
)
app.config['REDIS_URL'] = os.getenv('REDIS_URL', 'redis://localhost:6379/0')
app.config['CACHE_TTL'] = int(os.getenv('CACHE_TTL', 300))  # 5 minutes

# Initialize Redis
redis_client = redis.from_url(app.config['REDIS_URL'])

# Initialize rate limiter
limiter = Limiter(
    app=app,
    key_func=get_remote_address,
    storage_uri=app.config['REDIS_URL'],
    default_limits=["200 per day", "50 per hour"]
)

# Prometheus metrics
api_requests = Counter(
    'api_requests_total',
    'Total API requests',
    ['method', 'endpoint', 'status']
)
request_duration = Histogram(
    'api_request_duration_seconds',
    'API request duration',
    ['method', 'endpoint']
)
cache_hits = Counter('cache_hits_total', 'Total cache hits')
cache_misses = Counter('cache_misses_total', 'Total cache misses')


def get_db_connection():
    """Get database connection"""
    if 'db' not in g:
        g.db = psycopg2.connect(
            app.config['DATABASE_URL'],
            cursor_factory=RealDictCursor
        )
    return g.db


@app.teardown_appcontext
def close_db(error):
    """Close database connection"""
    db = g.pop('db', None)
    if db is not None:
        db.close()


def cache_result(timeout=None):
    """Decorator to cache function results in Redis"""
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            # Create cache key from function name and arguments
            cache_key = f"cache:{f.__name__}:{request.full_path}"
            
            # Try to get from cache
            try:
                cached = redis_client.get(cache_key)
                if cached:
                    cache_hits.inc()
                    logger.info(f"Cache hit for {cache_key}")
                    return json.loads(cached)
            except Exception as e:
                logger.warning(f"Cache get error: {e}")
            
            # Cache miss - execute function
            cache_misses.inc()
            result = f(*args, **kwargs)
            
            # Store in cache
            try:
                ttl = timeout or app.config['CACHE_TTL']
                redis_client.setex(
                    cache_key,
                    ttl,
                    json.dumps(result)
                )
            except Exception as e:
                logger.warning(f"Cache set error: {e}")
            
            return result
        return decorated_function
    return decorator


@app.before_request
def before_request():
    """Track request metrics"""
    g.start_time = datetime.utcnow()


@app.after_request
def after_request(response):
    """Record metrics after request"""
    if hasattr(g, 'start_time'):
        duration = (datetime.utcnow() - g.start_time).total_seconds()
        request_duration.labels(
            method=request.method,
            endpoint=request.endpoint or 'unknown'
        ).observe(duration)
    
    api_requests.labels(
        method=request.method,
        endpoint=request.endpoint or 'unknown',
        status=response.status_code
    ).inc()
    
    return response


@app.route('/health', methods=['GET'])
@limiter.exempt
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'service': 'data-api-service',
        'timestamp': datetime.utcnow().isoformat()
    })


@app.route('/ready', methods=['GET'])
@limiter.exempt
def readiness_check():
    """Readiness check - verifies dependencies"""
    try:
        # Check database
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute('SELECT 1')
        cursor.close()
        
        # Check Redis
        redis_client.ping()
        
        return jsonify({
            'status': 'ready',
            'database': 'connected',
            'redis': 'connected'
        })
    except Exception as e:
        logger.error(f"Readiness check failed: {e}")
        return jsonify({
            'status': 'not ready',
            'error': str(e)
        }), 503


@app.route('/api/v1/files/<int:file_id>', methods=['GET'])
@limiter.limit("100 per minute")
@cache_result(timeout=300)
def get_file(file_id):
    """Get file metadata by ID"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute(
            'SELECT * FROM file_metadata WHERE id = %s',
            (file_id,)
        )
        file = cursor.fetchone()
        cursor.close()
        
        if not file:
            return jsonify({'error': 'File not found'}), 404
        
        # Convert datetime to string for JSON serialization
        result = dict(file)
        if 'upload_timestamp' in result:
            result['upload_timestamp'] = result['upload_timestamp'].isoformat()
        
        return jsonify(result)
    except Exception as e:
        logger.error(f"Error retrieving file: {e}", exc_info=True)
        return jsonify({'error': 'Internal server error'}), 500


@app.route('/api/v1/files', methods=['GET'])
@limiter.limit("50 per minute")
@cache_result(timeout=60)
def list_files():
    """List files with pagination and filtering"""
    try:
        # Get query parameters
        page = int(request.args.get('page', 1))
        per_page = min(int(request.args.get('per_page', 20)), 100)
        project_id = request.args.get('project_id')
        
        offset = (page - 1) * per_page
        
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Build query
        query = 'SELECT * FROM file_metadata'
        params = []
        
        if project_id:
            query += ' WHERE project_id = %s'
            params.append(project_id)
        
        query += ' ORDER BY upload_timestamp DESC LIMIT %s OFFSET %s'
        params.extend([per_page, offset])
        
        cursor.execute(query, params)
        files = cursor.fetchall()
        
        # Get total count
        count_query = 'SELECT COUNT(*) FROM file_metadata'
        if project_id:
            count_query += ' WHERE project_id = %s'
            cursor.execute(count_query, [project_id])
        else:
            cursor.execute(count_query)
        
        total = cursor.fetchone()['count']
        cursor.close()
        
        # Convert datetimes
        results = []
        for file in files:
            file_dict = dict(file)
            if 'upload_timestamp' in file_dict:
                file_dict['upload_timestamp'] = file_dict['upload_timestamp'].isoformat()
            results.append(file_dict)
        
        return jsonify({
            'files': results,
            'pagination': {
                'page': page,
                'per_page': per_page,
                'total': total,
                'pages': (total + per_page - 1) // per_page
            }
        })
    except Exception as e:
        logger.error(f"Error listing files: {e}", exc_info=True)
        return jsonify({'error': 'Internal server error'}), 500


@app.route('/api/v1/projects/<project_id>/stats', methods=['GET'])
@limiter.limit("30 per minute")
@cache_result(timeout=300)
def get_project_stats(project_id):
    """Get statistics for a project"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT 
                COUNT(*) as file_count,
                SUM(file_size) as total_size,
                AVG(file_size) as avg_size,
                MIN(upload_timestamp) as first_upload,
                MAX(upload_timestamp) as last_upload
            FROM file_metadata
            WHERE project_id = %s
        ''', (project_id,))
        
        stats = cursor.fetchone()
        cursor.close()
        
        if not stats or stats['file_count'] == 0:
            return jsonify({'error': 'Project not found'}), 404
        
        # Convert values
        result = dict(stats)
        result['file_count'] = int(result['file_count'])
        result['total_size'] = int(result['total_size'] or 0)
        result['avg_size'] = float(result['avg_size'] or 0)
        
        if result['first_upload']:
            result['first_upload'] = result['first_upload'].isoformat()
        if result['last_upload']:
            result['last_upload'] = result['last_upload'].isoformat()
        
        return jsonify(result)
    except Exception as e:
        logger.error(f"Error getting project stats: {e}", exc_info=True)
        return jsonify({'error': 'Internal server error'}), 500


@app.route('/metrics', methods=['GET'])
def metrics():
    """Prometheus metrics endpoint"""
    return generate_latest(), 200, {'Content-Type': 'text/plain; charset=utf-8'}


@app.errorhandler(429)
def ratelimit_handler(e):
    """Handle rate limit exceeded"""
    return jsonify({
        'error': 'Rate limit exceeded',
        'message': str(e.description)
    }), 429


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8002, debug=False)
