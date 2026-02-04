"""
AEC Data Ingestion Service
FastAPI-based microservice for handling file uploads and data ingestion
"""

import os
import logging
from datetime import datetime
from typing import Optional
import boto3
from fastapi import FastAPI, File, UploadFile, Depends, HTTPException, status
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
from prometheus_client import Counter, Histogram, generate_latest
from pythonjsonlogger import jsonlogger

from app import models, schemas, database
from app.config import settings

# Configure structured logging
logHandler = logging.StreamHandler()
formatter = jsonlogger.JsonFormatter()
logHandler.setFormatter(formatter)
logger = logging.getLogger(__name__)
logger.addHandler(logHandler)
logger.setLevel(logging.INFO)

# Create FastAPI app
app = FastAPI(
    title="AEC Data Ingestion Service",
    description="Handles file uploads for AEC data infrastructure",
    version="1.0.0"
)

# Prometheus metrics
file_uploads_counter = Counter(
    'file_uploads_total',
    'Total number of file uploads',
    ['status']
)
upload_duration = Histogram(
    'file_upload_duration_seconds',
    'Time spent uploading files'
)

# Initialize S3 client
s3_client = boto3.client(
    's3',
    aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
    aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
    region_name=settings.AWS_REGION
)

# Dependency to get database session
def get_db():
    db = database.SessionLocal()
    try:
        yield db
    finally:
        db.close()


@app.on_event("startup")
async def startup_event():
    """Initialize database on startup"""
    logger.info("Starting Data Ingestion Service", extra={"event": "startup"})
    database.Base.metadata.create_all(bind=database.engine)


@app.get("/health")
async def health_check():
    """Health check endpoint for Kubernetes probes"""
    return {
        "status": "healthy",
        "service": "data-ingestion-service",
        "timestamp": datetime.utcnow().isoformat()
    }


@app.get("/ready")
async def readiness_check(db: Session = Depends(get_db)):
    """Readiness check - verifies database and S3 connectivity"""
    try:
        # Check database
        db.execute("SELECT 1")
        
        # Check S3
        s3_client.head_bucket(Bucket=settings.S3_BUCKET_NAME)
        
        return {
            "status": "ready",
            "database": "connected",
            "s3": "accessible"
        }
    except Exception as e:
        logger.error(f"Readiness check failed: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Service not ready"
        )


@app.post("/api/v1/files/upload", response_model=schemas.FileUploadResponse)
@upload_duration.time()
async def upload_file(
    file: UploadFile = File(...),
    project_id: str = None,
    description: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """
    Upload a file to S3 and store metadata in database
    
    Args:
        file: The file to upload (simulating CAD/BIM files)
        project_id: Project identifier
        description: File description
        db: Database session
    
    Returns:
        FileUploadResponse with file metadata and S3 location
    """
    try:
        logger.info(
            "File upload initiated",
            extra={
                "filename": file.filename,
                "content_type": file.content_type,
                "project_id": project_id
            }
        )
        
        # Validate file
        if not file.filename:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Filename is required"
            )
        
        # Simulate file type validation (CAD/BIM files)
        allowed_extensions = ['.dwg', '.rvt', '.ifc', '.nwd', '.pdf', '.txt']
        file_ext = os.path.splitext(file.filename)[1].lower()
        
        if file_ext not in allowed_extensions:
            logger.warning(f"Invalid file type: {file_ext}")
            file_uploads_counter.labels(status='rejected').inc()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"File type {file_ext} not supported"
            )
        
        # Generate S3 key
        timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
        s3_key = f"uploads/{project_id or 'general'}/{timestamp}_{file.filename}"
        
        # Upload to S3
        file_content = await file.read()
        s3_client.put_object(
            Bucket=settings.S3_BUCKET_NAME,
            Key=s3_key,
            Body=file_content,
            ContentType=file.content_type or 'application/octet-stream'
        )
        
        # Store metadata in database
        db_file = models.FileMetadata(
            filename=file.filename,
            s3_key=s3_key,
            s3_bucket=settings.S3_BUCKET_NAME,
            file_size=len(file_content),
            content_type=file.content_type,
            project_id=project_id,
            description=description,
            upload_timestamp=datetime.utcnow()
        )
        db.add(db_file)
        db.commit()
        db.refresh(db_file)
        
        logger.info(
            "File uploaded successfully",
            extra={
                "file_id": db_file.id,
                "s3_key": s3_key,
                "size": len(file_content)
            }
        )
        
        file_uploads_counter.labels(status='success').inc()
        
        return schemas.FileUploadResponse(
            id=db_file.id,
            filename=db_file.filename,
            s3_key=s3_key,
            s3_bucket=settings.S3_BUCKET_NAME,
            file_size=db_file.file_size,
            upload_timestamp=db_file.upload_timestamp,
            message="File uploaded successfully"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"File upload failed: {str(e)}", exc_info=True)
        file_uploads_counter.labels(status='error').inc()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"File upload failed: {str(e)}"
        )


@app.get("/api/v1/files/{file_id}", response_model=schemas.FileMetadataResponse)
async def get_file_metadata(file_id: int, db: Session = Depends(get_db)):
    """Retrieve file metadata by ID"""
    db_file = db.query(models.FileMetadata).filter(
        models.FileMetadata.id == file_id
    ).first()
    
    if not db_file:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="File not found"
        )
    
    return db_file


@app.get("/api/v1/files")
async def list_files(
    skip: int = 0,
    limit: int = 100,
    project_id: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """List files with optional filtering"""
    query = db.query(models.FileMetadata)
    
    if project_id:
        query = query.filter(models.FileMetadata.project_id == project_id)
    
    files = query.offset(skip).limit(limit).all()
    return {"files": files, "count": len(files)}


@app.get("/metrics")
async def metrics():
    """Prometheus metrics endpoint"""
    return JSONResponse(
        content=generate_latest().decode('utf-8'),
        media_type="text/plain"
    )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )
