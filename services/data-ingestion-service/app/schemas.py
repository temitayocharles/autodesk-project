"""
Pydantic schemas for request/response validation
"""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel


class FileUploadResponse(BaseModel):
    """Response schema for file upload"""
    id: int
    filename: str
    s3_key: str
    s3_bucket: str
    file_size: int
    upload_timestamp: datetime
    message: str
    
    class Config:
        from_attributes = True


class FileMetadataResponse(BaseModel):
    """Response schema for file metadata"""
    id: int
    filename: str
    s3_key: str
    s3_bucket: str
    file_size: int
    content_type: Optional[str]
    project_id: Optional[str]
    description: Optional[str]
    upload_timestamp: datetime
    
    class Config:
        from_attributes = True
