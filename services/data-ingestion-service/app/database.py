"""
Database connection and session management
"""

from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from app.config import settings

# Create database engine
# - In prod, we expect a real DB (Postgres) with pooling.
# - In tests/dev, sqlite is useful; sqlite does not support the same pooling args.
engine_kwargs = {
    "pool_pre_ping": True,  # Enable connection health checks
}
if settings.DATABASE_URL.startswith("sqlite"):
    # Safe defaults for sqlite (especially in unit tests).
    engine_kwargs["connect_args"] = {"check_same_thread": False}
else:
    engine_kwargs["pool_size"] = 10
    engine_kwargs["max_overflow"] = 20

engine = create_engine(settings.DATABASE_URL, **engine_kwargs)

# Create session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base class for models
Base = declarative_base()
