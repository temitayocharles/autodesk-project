-- Initialize database schema
CREATE TABLE IF NOT EXISTS file_metadata (
    id SERIAL PRIMARY KEY,
    filename VARCHAR(255) NOT NULL,
    s3_key VARCHAR(512) NOT NULL UNIQUE,
    s3_bucket VARCHAR(255) NOT NULL,
    file_size BIGINT NOT NULL,
    content_type VARCHAR(100),
    project_id VARCHAR(100),
    description TEXT,
    upload_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_project_id ON file_metadata(project_id);
CREATE INDEX IF NOT EXISTS idx_upload_timestamp ON file_metadata(upload_timestamp);

-- Insert sample data
INSERT INTO file_metadata (filename, s3_key, s3_bucket, file_size, content_type, project_id, description)
VALUES 
    ('building_plan.dwg', 'uploads/proj001/building_plan.dwg', 'aec-data-local', 1024000, 'application/acad', 'proj001', 'Main building plan'),
    ('electrical.rvt', 'uploads/proj001/electrical.rvt', 'aec-data-local', 2048000, 'application/revit', 'proj001', 'Electrical systems'),
    ('structural.ifc', 'uploads/proj002/structural.ifc', 'aec-data-local', 3072000, 'application/ifc', 'proj002', 'Structural model')
ON CONFLICT (s3_key) DO NOTHING;
