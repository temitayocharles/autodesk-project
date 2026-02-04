#!/bin/bash
# Start the complete development environment

set -e

echo "🚀 Starting AEC Data Infrastructure Platform..."
echo ""

PROJECT_ROOT="/Users/charlie/Desktop/autodesk-project"
cd "$PROJECT_ROOT/infrastructure/docker-compose"

# Check if .env exists
if [ ! -f .env ]; then
    echo "⚠️  .env file not found!"
    echo "Creating .env from .env.example..."
    cp .env.example .env
    echo ""
    echo "⚠️  Please edit .env file with your AWS credentials:"
    echo "    - AWS_ACCESS_KEY_ID"
    echo "    - AWS_SECRET_ACCESS_KEY"
    echo "    - S3_BUCKET_NAME"
    echo ""
    read -p "Press Enter after updating .env file..."
fi

# Load environment variables
export $(cat .env | grep -v '^#' | xargs)

# Check Docker
if ! docker ps &> /dev/null; then
    echo "❌ Docker is not running. Please start Docker Desktop."
    exit 1
fi

echo "📦 Building services..."
cd "$PROJECT_ROOT"
./scripts/build-all.sh

echo ""
echo "🐳 Starting Docker Compose services..."
cd "$PROJECT_ROOT/infrastructure/docker-compose"
docker-compose up -d

echo ""
echo "⏳ Waiting for services to be ready..."
sleep 10

# Health checks
echo ""
echo "🏥 Performing health checks..."

check_service() {
    local name=$1
    local url=$2
    
    if curl -f -s "$url" > /dev/null; then
        echo "✅ $name is healthy"
    else
        echo "⚠️  $name is not responding yet"
    fi
}

check_service "PostgreSQL" "http://localhost:5432" || true
check_service "Redis" "http://localhost:6379" || true
check_service "RabbitMQ Management" "http://localhost:15672"
check_service "Data Ingestion Service" "http://localhost:8000/health"
check_service "Data Processing Service" "http://localhost:8081/health"
check_service "Data API Service" "http://localhost:8002/health"
check_service "Nginx Gateway" "http://localhost:8080/health"
check_service "Prometheus" "http://localhost:9090/-/healthy"
check_service "Grafana" "http://localhost:3000/api/health"

echo ""
echo "=================================================="
echo "🎉 Platform is running!"
echo ""
echo "📊 Access URLs:"
echo "  API Gateway:          http://localhost:8080"
echo "  Data Ingestion API:   http://localhost:8000"
echo "  Data API:             http://localhost:8002"
echo "  Prometheus:           http://localhost:9090"
echo "  Grafana:              http://localhost:3000 (admin/admin)"
echo "  RabbitMQ Management:  http://localhost:15672 (guest/guest)"
echo ""
echo "📝 Useful commands:"
echo "  View logs:       docker-compose logs -f [service-name]"
echo "  Stop services:   docker-compose down"
echo "  Restart:         docker-compose restart [service-name]"
echo "  View status:     docker-compose ps"
echo ""
echo "🧪 Test the platform:"
echo "  ./scripts/test-services.sh"
echo ""
