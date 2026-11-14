import uuid
import pytest
from datetime import datetime, timezone
from fastapi.testclient import TestClient

from app.models.user import User
from app.models.pet_report import PetReport
from app.models.abuse_report import AbuseReport
from app.core.security import get_password_hash, create_access_token


@pytest.fixture
def auth_headers_factory(db_session):
    def _create(email="user@example.com", name="Regular User", role="user"):
        user = db_session.query(User).filter(User.email == email).first()
        if not user:
            user = User(
                id=uuid.uuid4(),
                email=email,
                name=name,
                password_hash=get_password_hash("password123"),
                role=role,
            )
            db_session.add(user)
            db_session.commit()
            db_session.refresh(user)
        token = create_access_token(subject=str(user.id))
        return {"Authorization": f"Bearer {token}"}, user
    return _create


@pytest.fixture
def target_report(db_session, auth_headers_factory):
    _, poster = auth_headers_factory(email="bad_actor@example.com", name="Bad Actor")
    rep = PetReport(
        id=uuid.uuid4(),
        user_id=poster.id,
        report_type="LOST",
        pet_name="Fido",
        animal_type="Dog",
        breed="Pug",
        color="Fawn",
        location_label="Downtown, SF",
        status="Open",
        latitude=37.77,
        longitude=-122.41,
        event_datetime=datetime.now(timezone.utc),
    )
    db_session.add(rep)
    db_session.commit()
    db_session.refresh(rep)
    return rep, poster


class TestAbuseReportingAndModeration:
    def test_unauthenticated_submission_rejected(self, client: TestClient, target_report):
        rep, _ = target_report
        res = client.post(
            "/api/abuse-reports",
            json={"pet_report_id": str(rep.id), "reason": "This is a scam listing."}
        )
        assert res.status_code == 401

    def test_missing_reason_rejected(self, client: TestClient, target_report, auth_headers_factory):
        rep, _ = target_report
        headers, _ = auth_headers_factory(email="reporter1@example.com")
        res = client.post(
            "/api/abuse-reports",
            json={"pet_report_id": str(rep.id), "reason": ""},
            headers=headers
        )
        assert res.status_code == 422

    def test_invalid_report_reference_rejected(self, client: TestClient, auth_headers_factory):
        headers, _ = auth_headers_factory(email="reporter2@example.com")
        fake_id = str(uuid.uuid4())
        res = client.post(
            "/api/abuse-reports",
            json={"pet_report_id": fake_id, "reason": "Valid reason for non-existent report."},
            headers=headers
        )
        assert res.status_code == 404

    def test_cannot_report_own_listing(self, client: TestClient, target_report, auth_headers_factory):
        rep, poster = target_report
        headers, _ = auth_headers_factory(email=poster.email)
        res = client.post(
            "/api/abuse-reports",
            json={"pet_report_id": str(rep.id), "reason": "I want to flag my own report?"},
            headers=headers
        )
        assert res.status_code == 400
        assert "own account" in res.json()["detail"].lower()

    def test_valid_abuse_report_submission(self, client: TestClient, target_report, auth_headers_factory):
        rep, poster = target_report
        headers, reporter = auth_headers_factory(email="good_citizen@example.com")
        
        payload = {
            "pet_report_id": str(rep.id),
            "reason": "This poster is demanding money via gift cards for pet return.",
        }
        res = client.post("/api/abuse-reports", json=payload, headers=headers)
        assert res.status_code == 201
        data = res.json()
        assert data["reporter_id"] == str(reporter.id)
        assert data["reported_user_id"] == str(poster.id)
        assert data["pet_report_id"] == str(rep.id)
        assert data["status"] == "pending"
        assert "gift cards" in data["reason"]

    def test_regular_user_cannot_access_admin_endpoints(self, client: TestClient, auth_headers_factory, db_session):
        headers, _ = auth_headers_factory(email="regular_joe@example.com", role="user")
        
        # GET admin reports
        res1 = client.get("/api/admin/abuse-reports", headers=headers)
        assert res1.status_code == 403

        # PATCH admin status
        fake_id = str(uuid.uuid4())
        res2 = client.patch(
            f"/api/admin/abuse-reports/{fake_id}",
            json={"status": "resolved"},
            headers=headers
        )
        assert res2.status_code == 403

    def test_admin_retrieves_and_manages_abuse_reports(self, client: TestClient, target_report, auth_headers_factory, db_session):
        rep, poster = target_report
        headers_user, _ = auth_headers_factory(email="submitter@example.com")
        admin_headers, _ = auth_headers_factory(email="super_admin@example.com", role="admin")

        # Submit an abuse report first
        res_create = client.post(
            "/api/abuse-reports",
            json={"pet_report_id": str(rep.id), "reason": "Demanding payment before showing proof."},
            headers=headers_user
        )
        assert res_create.status_code == 201

        # Admin fetches moderation queue
        res = client.get("/api/admin/abuse-reports", headers=admin_headers)
        assert res.status_code == 200
        data = res.json()
        assert "items" in data
        assert "total" in data
        assert data["total"] >= 1

        ar_id = data["items"][0]["id"]

        # Admin transitions status from pending -> under_review
        res_review = client.patch(
            f"/api/admin/abuse-reports/{ar_id}",
            json={"status": "under_review"},
            headers=admin_headers
        )
        assert res_review.status_code == 200
        assert res_review.json()["status"] == "under_review"

        # Admin transitions status from under_review -> resolved
        res_resolved = client.patch(
            f"/api/admin/abuse-reports/{ar_id}",
            json={"status": "resolved"},
            headers=admin_headers
        )
        assert res_resolved.status_code == 200
        assert res_resolved.json()["status"] == "resolved"

    def test_invalid_status_transition_rejected(self, client: TestClient, auth_headers_factory, db_session):
        admin_headers, _ = auth_headers_factory(email="super_admin@example.com", role="admin")

        # Create abuse report directly
        ar = AbuseReport(
            reporter_id=uuid.uuid4(),
            reported_user_id=uuid.uuid4(),
            reason="Abuse test",
            status="resolved",
        )
        db_session.add(ar)
        db_session.commit()
        db_session.refresh(ar)

        # Transitioning resolved directly to pending is invalid
        res = client.patch(
            f"/api/admin/abuse-reports/{ar.id}",
            json={"status": "pending"},
            headers=admin_headers
        )
        assert res.status_code == 400
        assert "cannot transition" in res.json()["detail"].lower()
