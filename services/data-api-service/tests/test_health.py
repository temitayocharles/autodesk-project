import importlib


def test_health_endpoint():
    # Import as a module from the service directory.
    app_mod = importlib.import_module("app")
    client = app_mod.app.test_client()
    resp = client.get("/health")
    assert resp.status_code == 200
    data = resp.get_json()
    assert data["status"] == "healthy"
    assert data["service"] == "data-api-service"

