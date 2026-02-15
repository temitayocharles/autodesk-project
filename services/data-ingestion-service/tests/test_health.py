import importlib
import os


def test_health_endpoint(monkeypatch):
    # Force a sqlite engine for tests and set harmless AWS placeholders before import.
    monkeypatch.setenv("DATABASE_URL", "sqlite+pysqlite:///:memory:")
    monkeypatch.setenv("AWS_ACCESS_KEY_ID", "test")
    monkeypatch.setenv("AWS_SECRET_ACCESS_KEY", "test")
    monkeypatch.setenv("AWS_REGION", "us-west-2")
    monkeypatch.setenv("S3_BUCKET_NAME", "test-bucket")

    main = importlib.import_module("app.main")
    from fastapi.testclient import TestClient

    # Replace the real boto3 client with a stub to avoid network.
    class _S3:
        def head_bucket(self, Bucket):  # noqa: N803
            return None

    main.s3_client = _S3()

    client = TestClient(main.app)
    resp = client.get("/health")
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "healthy"
    assert data["service"] == "data-ingestion-service"

