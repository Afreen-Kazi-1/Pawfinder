import uuid
import pytest
from datetime import datetime, timezone
from fastapi.testclient import TestClient

from app.models.user import User
from app.models.pet_report import PetReport
from app.models.notification import Notification
from app.core.security import get_password_hash, create_access_token
from app.services.notification_service import NotificationService
from app.services.match_service import MatchService


@pytest.fixture
def auth_headers_factory(db_session):
    def _create(email="user@example.com", name="Test User"):
        user = db_session.query(User).filter(User.email == email).first()
        if not user:
            user = User(
                id=uuid.uuid4(),
                email=email,
                name=name,
                password_hash=get_password_hash("password123"),
            )
            db_session.add(user)
            db_session.commit()
            db_session.refresh(user)
        token = create_access_token(subject=str(user.id))
        return {"Authorization": f"Bearer {token}"}, user
    return _create


class TestNotificationSystem:
    def test_unauthenticated_access_rejected(self, client: TestClient):
        res = client.get("/api/notifications")
        assert res.status_code == 401

    def test_notification_creation_and_retrieval(self, client: TestClient, auth_headers_factory, db_session):
        headers, user = auth_headers_factory(email="notif_user1@example.com", name="User One")
        
        # Create notifications directly via NotificationService
        NotificationService.create_notification(
            db=db_session,
            user_id=user.id,
            title="Test Title 1",
            message="Test Message 1",
            notification_type="match",
            related_entity_id=uuid.uuid4(),
        )
        NotificationService.create_notification(
            db=db_session,
            user_id=user.id,
            title="Test Title 2",
            message="Test Message 2",
            notification_type="contact_request",
            related_entity_id=uuid.uuid4(),
        )

        res = client.get("/api/notifications", headers=headers)
        assert res.status_code == 200
        data = res.json()
        assert data["total"] == 2
        assert data["unread_count"] == 2
        assert len(data["items"]) == 2
        assert data["items"][0]["title"] in ["Test Title 1", "Test Title 2"]

    def test_user_only_sees_own_notifications(self, client: TestClient, auth_headers_factory, db_session):
        headers1, user1 = auth_headers_factory(email="user_a@example.com")
        headers2, user2 = auth_headers_factory(email="user_b@example.com")

        NotificationService.create_notification(
            db=db_session,
            user_id=user1.id,
            title="User A's Notification",
            message="Secret message for A",
            notification_type="match",
        )
        NotificationService.create_notification(
            db=db_session,
            user_id=user2.id,
            title="User B's Notification",
            message="Secret message for B",
            notification_type="match",
        )

        res1 = client.get("/api/notifications", headers=headers1)
        data1 = res1.json()
        assert data1["total"] == 1
        assert data1["items"][0]["title"] == "User A's Notification"

        res2 = client.get("/api/notifications", headers=headers2)
        data2 = res2.json()
        assert data2["total"] == 1
        assert data2["items"][0]["title"] == "User B's Notification"

    def test_mark_as_read(self, client: TestClient, auth_headers_factory, db_session):
        headers, user = auth_headers_factory(email="user_read@example.com")

        notif = NotificationService.create_notification(
            db=db_session,
            user_id=user.id,
            title="Read Me",
            message="Check read status",
            notification_type="status_update",
        )
        assert notif.is_read is False

        # Mark as read
        res = client.patch(f"/api/notifications/{notif.id}/read", headers=headers)
        assert res.status_code == 200
        assert res.json()["is_read"] is True

        # Check list unread count updated
        res_list = client.get("/api/notifications", headers=headers)
        assert res_list.json()["unread_count"] == 0

    def test_unauthorized_mark_as_read(self, client: TestClient, auth_headers_factory, db_session):
        _, victim = auth_headers_factory(email="victim@example.com")
        attacker_headers, _ = auth_headers_factory(email="attacker@example.com")

        notif = NotificationService.create_notification(
            db=db_session,
            user_id=victim.id,
            title="Victim Notification",
            message="Private alert",
            notification_type="status_update",
        )

        res = client.patch(f"/api/notifications/{notif.id}/read", headers=attacker_headers)
        assert res.status_code == 403
        assert "permission" in res.json()["detail"].lower()

    def test_mark_all_as_read(self, client: TestClient, auth_headers_factory, db_session):
        headers, user = auth_headers_factory(email="bulk_read@example.com")

        for i in range(3):
            NotificationService.create_notification(
                db=db_session,
                user_id=user.id,
                title=f"Notification {i}",
                message=f"Message {i}",
                notification_type="match",
                prevent_duplicates=False,
            )

        res_before = client.get("/api/notifications", headers=headers)
        assert res_before.json()["unread_count"] == 3

        # Mark all read
        res_patch = client.patch("/api/notifications/read-all", headers=headers)
        assert res_patch.status_code == 200
        assert res_patch.json()["updated_count"] == 3

        res_after = client.get("/api/notifications", headers=headers)
        assert res_after.json()["unread_count"] == 0

    def test_duplicate_notification_prevention(self, db_session, auth_headers_factory):
        _, user = auth_headers_factory(email="dedup_user@example.com")
        entity_id = uuid.uuid4()

        n1 = NotificationService.create_notification(
            db=db_session,
            user_id=user.id,
            title="Match Found",
            message="Match alert",
            notification_type="match",
            related_entity_id=entity_id,
            prevent_duplicates=True,
        )
        n2 = NotificationService.create_notification(
            db=db_session,
            user_id=user.id,
            title="Match Found",
            message="Match alert",
            notification_type="match",
            related_entity_id=entity_id,
            prevent_duplicates=True,
        )

        assert n1.id == n2.id
        total = db_session.query(Notification).filter(Notification.user_id == user.id).count()
        assert total == 1

    def test_match_identified_generates_notification(self, db_session, auth_headers_factory):
        _, owner1 = auth_headers_factory(email="lost_parent@example.com")
        _, owner2 = auth_headers_factory(email="finder_person@example.com")

        lost_rep = PetReport(
            id=uuid.uuid4(),
            user_id=owner1.id,
            report_type="LOST",
            pet_name="Shadow",
            animal_type="Cat",
            breed="Bombay",
            color="Black",
            location_label="Mission District, SF",
            status="Open",
            latitude=37.76,
            longitude=-122.42,
            event_datetime=datetime.now(timezone.utc),
        )
        found_rep = PetReport(
            id=uuid.uuid4(),
            user_id=owner2.id,
            report_type="FOUND",
            pet_name="Found Cat",
            animal_type="Cat",
            breed="Bombay",
            color="Black",
            location_label="Mission District, SF",
            status="Open",
            latitude=37.761,
            longitude=-122.421,
            event_datetime=datetime.now(timezone.utc),
        )
        db_session.add(lost_rep)
        db_session.add(found_rep)
        db_session.commit()

        # Run match service
        service = MatchService(db_session)
        matches = service.run_matching_for_report(lost_rep.id)
        assert len(matches) >= 1

        # Check notifications generated for both owners
        notif_lost = db_session.query(Notification).filter(
            Notification.user_id == owner1.id,
            Notification.notification_type == "match"
        ).first()
        assert notif_lost is not None
        assert "Potential Match Identified" in notif_lost.title

        notif_found = db_session.query(Notification).filter(
            Notification.user_id == owner2.id,
            Notification.notification_type == "match"
        ).first()
        assert notif_found is not None
        assert "Potential Match Identified" in notif_found.title

    def test_report_status_and_resolved_notifications(self, client: TestClient, auth_headers_factory, db_session):
        headers, user = auth_headers_factory(email="report_owner_notif@example.com")

        report = PetReport(
            id=uuid.uuid4(),
            user_id=user.id,
            report_type="LOST",
            pet_name="Cooper",
            animal_type="Dog",
            breed="Beagle",
            color="Tri-color",
            location_label="Sunset, SF",
            status="Open",
            latitude=37.75,
            longitude=-122.48,
            event_datetime=datetime.now(timezone.utc),
        )
        db_session.add(report)
        db_session.commit()

        # 1. Update status to Under Review -> generates status_update notification
        res_review = client.patch(
            f"/api/reports/{report.id}/status",
            json={"status": "Under Review"},
            headers=headers
        )
        assert res_review.status_code == 200

        notif_status = db_session.query(Notification).filter(
            Notification.user_id == user.id,
            Notification.notification_type == "status_update"
        ).first()
        assert notif_status is not None
        assert "Under Review" in notif_status.message

        # 2. Update status to Resolved -> generates resolved notification
        res_resolved = client.patch(
            f"/api/reports/{report.id}/status",
            json={"status": "Resolved"},
            headers=headers
        )
        assert res_resolved.status_code == 200

        notif_resolved = db_session.query(Notification).filter(
            Notification.user_id == user.id,
            Notification.notification_type == "resolved"
        ).first()
        assert notif_resolved is not None
        assert "resolved" in notif_resolved.message.lower()

