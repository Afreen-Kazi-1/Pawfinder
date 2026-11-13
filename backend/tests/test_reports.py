import io
import uuid
from decimal import Decimal
import pytest
from fastapi.testclient import TestClient

from app.core.security import create_access_token
from app.models.user import User


@pytest.fixture
def test_user(db_session) -> User:
    user = User(
        name="Report Tester",
        email=f"reporter_{uuid.uuid4().hex[:8]}@example.com",
        password_hash="fakehash",
        role="user",
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    return user


@pytest.fixture
def other_user(db_session) -> User:
    user = User(
        name="Other User",
        email=f"other_{uuid.uuid4().hex[:8]}@example.com",
        password_hash="fakehash",
        role="user",
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    return user


@pytest.fixture
def auth_headers(test_user) -> dict:
    token = create_access_token(subject=str(test_user.id))
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
def other_auth_headers(other_user) -> dict:
    token = create_access_token(subject=str(other_user.id))
    return {"Authorization": f"Bearer {token}"}


def test_create_lost_report(client: TestClient, auth_headers: dict):
    payload = {
        "report_type": "LOST",
        "pet_name": "Buddy",
        "animal_type": "Dog",
        "breed": "Golden Retriever",
        "color": "Golden",
        "gender": "Male",
        "approximate_age": "3 years",
        "distinguishing_features": "Red collar with silver tag",
        "description": "Friendly dog slipped out through front gate.",
        "latitude": 37.7749,
        "longitude": -122.4194,
        "location_label": "Market St, San Francisco, CA",
        "event_datetime": "2026-11-13T10:00:00Z",
        "reward": 150.00,
    }
    response = client.post("/api/reports", json=payload, headers=auth_headers)
    assert response.status_code == 201
    data = response.json()
    assert data["report_type"] == "LOST"
    assert data["pet_name"] == "Buddy"
    assert data["animal_type"] == "Dog"
    assert data["status"] == "Open"
    assert float(data["reward"]) == 150.00
    assert "id" in data


def test_create_found_report(client: TestClient, auth_headers: dict):
    payload = {
        "report_type": "FOUND",
        "pet_name": None,
        "animal_type": "Cat",
        "breed": "Tabby (approximate)",
        "color": "Grey striped with white paws",
        "gender": "Unknown",
        "approximate_age": "Adult",
        "distinguishing_features": "No collar, very docile",
        "description": "Found sheltering under front porch in the rain.",
        "latitude": 37.7833,
        "longitude": -122.4167,
        "location_label": "Union Square, San Francisco, CA",
        "event_datetime": "2026-11-13T12:30:00Z",
        "reward": None,
    }
    response = client.post("/api/reports", json=payload, headers=auth_headers)
    assert response.status_code == 201
    data = response.json()
    assert data["report_type"] == "FOUND"
    assert data["animal_type"] == "Cat"
    assert data["pet_name"] is None
    assert data["status"] == "Open"


def test_missing_required_fields(client: TestClient, auth_headers: dict):
    # Missing animal_type, color, location_label, latitude, longitude
    payload = {
        "report_type": "LOST",
        "pet_name": "Ghost",
    }
    response = client.post("/api/reports", json=payload, headers=auth_headers)
    assert response.status_code == 422


def test_invalid_report_type(client: TestClient, auth_headers: dict):
    payload = {
        "report_type": "STOLEN",  # Invalid enum value
        "animal_type": "Dog",
        "color": "Black",
        "latitude": 37.77,
        "longitude": -122.41,
        "location_label": "Downtown",
        "event_datetime": "2026-11-13T10:00:00Z",
    }
    response = client.post("/api/reports", json=payload, headers=auth_headers)
    assert response.status_code == 422


def test_invalid_coordinates(client: TestClient, auth_headers: dict):
    # Latitude > 90
    payload = {
        "report_type": "LOST",
        "animal_type": "Dog",
        "color": "Brown",
        "latitude": 95.0,  # Invalid
        "longitude": -122.41,
        "location_label": "North Pole",
        "event_datetime": "2026-11-13T10:00:00Z",
    }
    response = client.post("/api/reports", json=payload, headers=auth_headers)
    assert response.status_code == 422

    # Longitude < -180
    payload["latitude"] = 45.0
    payload["longitude"] = -185.0
    response = client.post("/api/reports", json=payload, headers=auth_headers)
    assert response.status_code == 422


def test_invalid_reward(client: TestClient, auth_headers: dict):
    payload = {
        "report_type": "LOST",
        "animal_type": "Dog",
        "color": "Brown",
        "latitude": 37.77,
        "longitude": -122.41,
        "location_label": "Mission",
        "event_datetime": "2026-11-13T10:00:00Z",
        "reward": -50.00,  # Negative reward
    }
    response = client.post("/api/reports", json=payload, headers=auth_headers)
    assert response.status_code == 422


def test_unauthorized_creation(client: TestClient):
    payload = {
        "report_type": "LOST",
        "animal_type": "Dog",
        "color": "Brown",
        "latitude": 37.77,
        "longitude": -122.41,
        "location_label": "Downtown",
        "event_datetime": "2026-11-13T10:00:00Z",
    }
    response = client.post("/api/reports", json=payload)
    assert response.status_code == 401


def test_report_retrieval(client: TestClient, auth_headers: dict):
    # Create report
    payload = {
        "report_type": "LOST",
        "animal_type": "Bird",
        "breed": "Parrot",
        "color": "Green and Yellow",
        "latitude": 37.77,
        "longitude": -122.41,
        "location_label": "City Park",
        "event_datetime": "2026-11-13T10:00:00Z",
    }
    create_resp = client.post("/api/reports", json=payload, headers=auth_headers)
    assert create_resp.status_code == 201
    report_id = create_resp.json()["id"]

    # Public retrieval
    get_resp = client.get(f"/api/reports/{report_id}")
    assert get_resp.status_code == 200
    assert get_resp.json()["id"] == report_id
    assert get_resp.json()["animal_type"] == "Bird"


def test_update_own_report(client: TestClient, auth_headers: dict):
    payload = {
        "report_type": "LOST",
        "animal_type": "Dog",
        "color": "White",
        "latitude": 37.77,
        "longitude": -122.41,
        "location_label": "Park",
        "event_datetime": "2026-11-13T10:00:00Z",
    }
    create_resp = client.post("/api/reports", json=payload, headers=auth_headers)
    report_id = create_resp.json()["id"]

    update_payload = {
        "pet_name": "Snowball",
        "reward": 200.00,
        "description": "Updated description: seen near playground",
    }
    update_resp = client.put(f"/api/reports/{report_id}", json=update_payload, headers=auth_headers)
    assert update_resp.status_code == 200
    updated_data = update_resp.json()
    assert updated_data["pet_name"] == "Snowball"
    assert float(updated_data["reward"]) == 200.00
    assert "playground" in updated_data["description"]


def test_update_another_users_report_forbidden(
    client: TestClient,
    auth_headers: dict,
    other_auth_headers: dict,
):
    payload = {
        "report_type": "LOST",
        "animal_type": "Cat",
        "color": "Black",
        "latitude": 37.77,
        "longitude": -122.41,
        "location_label": "Alley",
        "event_datetime": "2026-11-13T10:00:00Z",
    }
    create_resp = client.post("/api/reports", json=payload, headers=auth_headers)
    report_id = create_resp.json()["id"]

    # Attempt update using other user's token
    hack_payload = {"pet_name": "Hacked"}
    update_resp = client.put(f"/api/reports/{report_id}", json=hack_payload, headers=other_auth_headers)
    assert update_resp.status_code == 403


def test_update_report_status(client: TestClient, auth_headers: dict):
    payload = {
        "report_type": "LOST",
        "animal_type": "Dog",
        "color": "Spotted",
        "latitude": 37.77,
        "longitude": -122.41,
        "location_label": "Beach",
        "event_datetime": "2026-11-13T10:00:00Z",
    }
    create_resp = client.post("/api/reports", json=payload, headers=auth_headers)
    report_id = create_resp.json()["id"]

    status_resp = client.patch(
        f"/api/reports/{report_id}/status",
        json={"status": "Reunited / Resolved"},
        headers=auth_headers,
    )
    assert status_resp.status_code == 200
    assert status_resp.json()["status"] == "Reunited / Resolved"


def test_delete_own_report(client: TestClient, auth_headers: dict):
    payload = {
        "report_type": "FOUND",
        "animal_type": "Dog",
        "color": "Tan",
        "latitude": 37.77,
        "longitude": -122.41,
        "location_label": "Main St",
        "event_datetime": "2026-11-13T10:00:00Z",
    }
    create_resp = client.post("/api/reports", json=payload, headers=auth_headers)
    report_id = create_resp.json()["id"]

    del_resp = client.delete(f"/api/reports/{report_id}", headers=auth_headers)
    assert del_resp.status_code == 204

    # Verify report is gone
    get_resp = client.get(f"/api/reports/{report_id}")
    assert get_resp.status_code == 404


def test_delete_another_users_report_forbidden(
    client: TestClient,
    auth_headers: dict,
    other_auth_headers: dict,
):
    payload = {
        "report_type": "FOUND",
        "animal_type": "Cat",
        "color": "Calico",
        "latitude": 37.77,
        "longitude": -122.41,
        "location_label": "Garden",
        "event_datetime": "2026-11-13T10:00:00Z",
    }
    create_resp = client.post("/api/reports", json=payload, headers=auth_headers)
    report_id = create_resp.json()["id"]

    del_resp = client.delete(f"/api/reports/{report_id}", headers=other_auth_headers)
    assert del_resp.status_code == 403


def test_image_upload_and_retrieval(client: TestClient, auth_headers: dict):
    # Create report first
    payload = {
        "report_type": "LOST",
        "pet_name": "Bella",
        "animal_type": "Dog",
        "color": "Golden",
        "latitude": 37.77,
        "longitude": -122.41,
        "location_label": "Park Ave",
        "event_datetime": "2026-11-13T10:00:00Z",
    }
    create_resp = client.post("/api/reports", json=payload, headers=auth_headers)
    report_id = create_resp.json()["id"]

    # Upload mock JPEG image
    fake_jpeg = b"\xff\xd8\xff\xe0\x00\x10JFIF" + b"A" * 500
    files = [("files", ("dog.jpg", io.BytesIO(fake_jpeg), "image/jpeg"))]

    upload_resp = client.post(
        f"/api/reports/{report_id}/images",
        files=files,
        headers=auth_headers,
    )
    assert upload_resp.status_code == 201
    images = upload_resp.json()
    assert len(images) == 1
    image_id = images[0]["id"]
    assert images[0]["image_url"] != ""
    assert images[0]["storage_path"] != ""

    # Retrieve report images
    list_resp = client.get(f"/api/reports/{report_id}/images")
    assert list_resp.status_code == 200
    assert len(list_resp.json()) == 1


def test_invalid_image_type(client: TestClient, auth_headers: dict):
    payload = {
        "report_type": "LOST",
        "animal_type": "Dog",
        "color": "Black",
        "latitude": 37.77,
        "longitude": -122.41,
        "location_label": "Street",
        "event_datetime": "2026-11-13T10:00:00Z",
    }
    create_resp = client.post("/api/reports", json=payload, headers=auth_headers)
    report_id = create_resp.json()["id"]

    # Upload text/plain instead of an image
    fake_pdf = b"%PDF-1.4 Fake document"
    files = [("files", ("document.pdf", io.BytesIO(fake_pdf), "application/pdf"))]

    upload_resp = client.post(
        f"/api/reports/{report_id}/images",
        files=files,
        headers=auth_headers,
    )
    assert upload_resp.status_code == 400
    assert "Unsupported image type" in upload_resp.json()["detail"]


def test_oversized_image(client: TestClient, auth_headers: dict):
    payload = {
        "report_type": "LOST",
        "animal_type": "Dog",
        "color": "Black",
        "latitude": 37.77,
        "longitude": -122.41,
        "location_label": "Street",
        "event_datetime": "2026-11-13T10:00:00Z",
    }
    create_resp = client.post("/api/reports", json=payload, headers=auth_headers)
    report_id = create_resp.json()["id"]

    # Generate oversized image (5MB + 1024 bytes)
    huge_bytes = b"X" * (5 * 1024 * 1024 + 1024)
    files = [("files", ("huge.jpg", io.BytesIO(huge_bytes), "image/jpeg"))]

    upload_resp = client.post(
        f"/api/reports/{report_id}/images",
        files=files,
        headers=auth_headers,
    )
    assert upload_resp.status_code == 400
    assert "exceeds maximum allowed size" in upload_resp.json()["detail"]


def test_image_deletion(client: TestClient, auth_headers: dict, other_auth_headers: dict):
    payload = {
        "report_type": "FOUND",
        "animal_type": "Dog",
        "color": "Brown",
        "latitude": 37.77,
        "longitude": -122.41,
        "location_label": "Subway",
        "event_datetime": "2026-11-13T10:00:00Z",
    }
    create_resp = client.post("/api/reports", json=payload, headers=auth_headers)
    report_id = create_resp.json()["id"]

    # Upload image
    fake_png = b"\x89PNG\r\n\x1a\n" + b"B" * 200
    files = [("files", ("pet.png", io.BytesIO(fake_png), "image/png"))]
    upload_resp = client.post(
        f"/api/reports/{report_id}/images",
        files=files,
        headers=auth_headers,
    )
    image_id = upload_resp.json()[0]["id"]

    # Unauthorized delete attempt
    del_forbidden = client.delete(f"/api/images/{image_id}", headers=other_auth_headers)
    assert del_forbidden.status_code == 403

    # Authorized delete
    del_resp = client.delete(f"/api/images/{image_id}", headers=auth_headers)
    assert del_resp.status_code == 204

    # Verify image list is empty
    list_resp = client.get(f"/api/reports/{report_id}/images")
    assert len(list_resp.json()) == 0


def test_storage_failure_handling(client: TestClient, auth_headers: dict, monkeypatch):
    from app.services import storage_service

    # Create report
    payload = {
        "report_type": "LOST",
        "animal_type": "Cat",
        "color": "Ginger",
        "latitude": 37.77,
        "longitude": -122.41,
        "location_label": "Rooftop",
        "event_datetime": "2026-11-13T10:00:00Z",
    }
    create_resp = client.post("/api/reports", json=payload, headers=auth_headers)
    report_id = create_resp.json()["id"]

    # Monkeypatch storage service upload to simulate network failure
    def mock_upload_failure(*args, **kwargs):
        from fastapi import HTTPException
        raise HTTPException(status_code=503, detail="Storage service unavailable")

    monkeypatch.setattr(storage_service.storage_service, "upload_image", mock_upload_failure)

    fake_jpeg = b"\xff\xd8\xff\xe0" + b"X" * 100
    files = [("files", ("cat.jpg", io.BytesIO(fake_jpeg), "image/jpeg"))]
    upload_resp = client.post(
        f"/api/reports/{report_id}/images",
        files=files,
        headers=auth_headers,
    )
    assert upload_resp.status_code == 503
    assert "Storage service unavailable" in upload_resp.json()["detail"]


def test_my_reports_endpoint(client: TestClient, auth_headers: dict):
    # Post 2 reports
    for i in range(2):
        client.post(
            "/api/reports",
            json={
                "report_type": "LOST",
                "animal_type": "Dog",
                "color": f"Color {i}",
                "latitude": 37.77,
                "longitude": -122.41,
                "location_label": f"Location {i}",
                "event_datetime": "2026-11-13T10:00:00Z",
            },
            headers=auth_headers,
        )

    my_reports_resp = client.get("/api/reports/mine", headers=auth_headers)
    assert my_reports_resp.status_code == 200
    data = my_reports_resp.json()
    assert data["total"] >= 2
    assert len(data["items"]) >= 2

