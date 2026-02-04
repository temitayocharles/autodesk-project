"""
Database models for Data Ingestion Service
"""

from datetime import datetime
from sqlalchemy import Column, Integer, String, DateTime, BigInteger
from app.database import Base


class FileMetadata(Base):
    """File metadata table"""
    __tablename__ = "file_metadata"
    
    id = Column(Integer, primary_key=True, index=True)
    filename = Column(String, nullable=False)
    s3_key = Column(String, nullable=False, unique=True)
    s3_bucket = Column(String, nullable=False)
    file_size = Column(BigInteger, nullable=False)
    content_type = Column(String)
    project_id = Column(String, index=True)
    description = Column(String)
    upload_timestamp = Column(DateTime, default=datetime.utcnow)
    
    def __repr__(self):
        return f"<FileMetadata(id={self.id}, filename={self.filename})>"
