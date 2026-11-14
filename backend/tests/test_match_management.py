import uuid
from datetime import datetime
import pytest
from fastapi.testclient import TestClient

from app.core.security import create_access_token
from app.models.user import User
from app.models.pet_report import PetReport
from app.models.match import Match


@pytest.fixture
def owner_user(db_session) -> User:
    user = User(
        name="Report Owner",
        email=f"owner_{uuid.uuid4().hex[:8]}@example.com",
        password_hash="fakehash",
        role="user",
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    return user


@pytest.fixture
def owner_headers(owner_user) -> dict:
    token = create_access_token(subject=str(owner_user.id))
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
def stranger_user(db_session) -> User:
    user = User(
        name="Stranger",
        email=f"stranger_{uuid.uuid4().hex[:8]}@example.com",
        password_hash="fakehash",
        role="user",
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    return user


@pytest.fixture
def stranger_headers(stranger_user) -> dict:
    token = create_access_token(subject=str(stranger_user.id))
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
def sample_match(db_session, owner_user) -> Match:
    lost = PetReport(
        user_id=owner_user.id,
        report_type="LOST",
        pet_name="Daisy",
        animal_type="Dog",
        breed="Beagle",
        color="Tricolor",
        latitude=37.77,
        longitude=-122.41,
        location_label="Mission",
        event_datetime=datetime(2026, 11, 10, 10, 0),
        status="Open",
    )
    found = PetReport(
        user_id=owner_user.id,
        report_type="FOUND",
        animal_type="Dog",
        breed="Beagle",
        color="Tricolor",
        latitude=37.772,
        longitude=-122.412,
        location_label="Mission Park",
        event_datetime=datetime(2026, 11, 10, 12, 0),
        status="Open",
    )
    db_session.add_all([lost, found])
    db_session.commit()

    match = Match(
        lost_report_id=lost.id,
        found_report_id=found.id,
        match_score=92.5,
        match_category="High potential match",
        match_reasons={
            "animal_type": {"score": 100.0, "explanation": "Exact animal type match: Dog."},
            "final_score": 92.5,
        },
        status="Suggested",
    )
    db_session.add(match)
    db_session.commit()
    db_session.refresh(match)
    return match


class TestMatchManagement:
    def test_list_own_matches(self, client: TestClient, owner_headers, sample_match):
        resp = client.get("/api/matches", headers=owner_headers)
        assert resp.status_code == 200
        data = resp.json()
        assert data["total"] >= 1
        ids = [m["id"] for m in data["items"]]
        assert str(sample_match.id) in ids

    def test_unauthorized_user_cannot_view_matches(self, client: TestClient, stranger_headers, sample_match):
        resp = client.get(f"/api/matches/{sample_match.id}", headers=stranger_headers)
        assert resp.status_code == 403

    def test_authorized_user_views_match_detail(self, client: TestClient, owner_headers, sample_match):
        resp = client.get(f"/api/matches/{sample_match.id}", headers=owner_headers)
        assert resp.status_code == 200
        data = resp.json()
        assert data["id"] == str(sample_match.id)
        assert data["match_score"] == 92.5
        assert data["match_category"] == "High potential match"
        assert "lost_report" in data
        assert "found_report" in data
        assert "animal_type" in data["match_reasons"]

    def test_mark_match_relevant(self, client: TestClient, owner_headers, sample_match):
        resp = client.patch(
            f"/api/matches/{sample_match.id}/status",
            json={"status": "Relevant"},
            headers=owner_headers,
        )
        assert resp.status_code == 200
        assert resp.json()["status"] == "Relevant"

    def test_dismiss_match(self, client: TestClient, owner_headers, sample_match):
        resp = client.patch(
            f"/api/matches/{sample_match.id}/status",
            json={"status": "Dismissed"},
            headers=owner_headers,
        )
        assert resp.status_code == 200
        assert resp.json()["status"] == "Dismissed"

    def test_resolve_match(self, client: TestClient, owner_headers, sample_match):
        resp = client.patch(
            f"/api/matches/{sample_match.id}/status",
            json={"status": "Resolved"},
            headers=owner_headers,
        )
        assert resp.status_code == 200
        assert resp.json()["status"] == "Resolved"

    def test_invalid_transition_from_resolved_fails(self, client: TestClient, owner_headers, sample_match):
        # Resolve it first
        client.patch(
            f"/api/matches/{sample_match.id}/status",
            json={"status": "Resolved"},
            headers=owner_headers,
        )
        # Attempt to transition back to Suggested
        resp = client.patch(
            f"/api/matches/{sample_match.id}/status",
            json={"status": "Suggested"},
            headers=owner_headers,
        )
        assert resp.status_code == 400
        assert "Invalid status transition" in resp.json()["detail"]

    def test_invalid_status_value_rejected(self, client: TestClient, owner_headers, sample_match):
        resp = client.patch(
            f"/api/matches/{sample_match.id}/status",
            json={"status": "NonexistentStatus"},
            headers=owner_headers,
        )
        assert resp.status_code == 422

