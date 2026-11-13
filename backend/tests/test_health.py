from fastapi.testclient import TestClient


def test_app_startup_root(client: TestClient):
    """Test root endpoint returns 200 and correct project information."""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["project"] == "PawFinder"
    assert data["version"] == "1.0.0"
    assert data["docs_url"] == "/docs"


def test_health_check_endpoint(client: TestClient):
    """Test health check returns healthy status and connected database."""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert data["database"] == "connected"
    assert data["project"] == "PawFinder"


def test_api_v1_health_check_endpoint(client: TestClient):
    """Test /api/health endpoint returns healthy status and connected database."""
    response = client.get("/api/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert data["database"] == "connected"

