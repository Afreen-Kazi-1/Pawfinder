import uuid
import pytest
from datetime import datetime, timezone
from fastapi.testclient import TestClient

from app.models.user import User
from app.models.pet_report import PetReport
from app.models.contact_request import ContactRequest
from app.models.notification import Notification
from app.core.security import get_password_hash, create_access_token


@pytest.fixture
def auth_headers_factory(db_session):
    def _create(email="user@example.com", name="Test User", phone="+15551234567"):
        user = db_session.query(User).filter(User.email == email).first()
        if not user:
            user = User(
                id=uuid.uuid4(),
                email=email,
                name=name,
                password_hash=get_password_hash("password123"),
                phone=phone,
            )
            db_session.add(user)
            db_session.commit()
            db_session.refresh(user)
        token = create_access_token(subject=str(user.id))
        return {"Authorization": f"Bearer {token}"}, user
    return _create


@pytest.fixture
def test_reports(db_session, auth_headers_factory):
    _, owner_user = auth_headers_factory(email="owner@example.com", name="Report Owner", phone="+19876543210")
    
    open_report = PetReport(
        id=uuid.uuid4(),
        user_id=owner_user.id,
        report_type="LOST",
        pet_name="Buddy",
        animal_type="Dog",
        breed="Golden Retriever",
        color="Golden",
        location_label="San Francisco, CA",
        status="Open",
        latitude=37.7749,
        longitude=-122.4194,
        event_datetime=datetime.now(timezone.utc),
    )
    db_session.add(open_report)

    closed_report = PetReport(
        id=uuid.uuid4(),
        user_id=owner_user.id,
        report_type="LOST",
        pet_name="Milo",
        animal_type="Cat",
        breed="Tabby",
        color="Orange",
        location_label="San Francisco, CA",
        status="Closed",
        latitude=37.7749,
        longitude=-122.4194,
        event_datetime=datetime.now(timezone.utc),
    )
    db_session.add(closed_report)

    db_session.commit()
    db_session.refresh(open_report)
    db_session.refresh(closed_report)
    return open_report, closed_report, owner_user


class TestContactRequests:
    def test_unauthenticated_request_rejected(self, client: TestClient, test_reports):
        open_report, _, _ = test_reports
        res = client.post(
            "/api/contact-requests",
            json={"report_id": str(open_report.id), "message": "I found Buddy!"}
        )
        assert res.status_code == 401

    def test_self_contact_prevention(self, client: TestClient, test_reports, auth_headers_factory):
        open_report, _, owner_user = test_reports
        headers, _ = auth_headers_factory(email=owner_user.email)
        res = client.post(
            "/api/contact-requests",
            json={"report_id": str(open_report.id), "message": "Trying to contact myself"},
            headers=headers
        )
        assert res.status_code == 400
        assert "yourself" in res.json()["detail"].lower()

    def test_closed_report_contact_prevention(self, client: TestClient, test_reports, auth_headers_factory):
        _, closed_report, _ = test_reports
        headers, _ = auth_headers_factory(email="sender1@example.com", name="Good Samaritan")
        res = client.post(
            "/api/contact-requests",
            json={"report_id": str(closed_report.id), "message": "I saw your cat"},
            headers=headers
        )
        assert res.status_code == 400
        assert "closed" in res.json()["detail"].lower()

    def test_create_valid_contact_request_and_notification(self, client: TestClient, test_reports, auth_headers_factory, db_session):
        open_report, _, owner_user = test_reports
        headers, sender = auth_headers_factory(email="samaritan@example.com", name="Samaritan Dave")
        
        payload = {
            "report_id": str(open_report.id),
            "message": "I saw your dog near Golden Gate Park!",
            "sender_contact_info": "+14155550199"
        }
        res = client.post("/api/contact-requests", json=payload, headers=headers)
        assert res.status_code == 201
        data = res.json()
        assert data["report_id"] == str(open_report.id)
        assert data["sender_id"] == str(sender.id)
        assert data["receiver_id"] == str(owner_user.id)
        assert data["status"] == "pending"
        # Since status is pending, contact details should be masked
        assert data["sender"]["phone"] is None
        assert data["receiver"]["phone"] is None

        # Check notification created for owner
        notif = db_session.query(Notification).filter(
            Notification.user_id == owner_user.id,
            Notification.notification_type == "contact_request"
        ).first()
        assert notif is not None
        assert "Samaritan Dave" in notif.message

    def test_duplicate_pending_request_prevention(self, client: TestClient, test_reports, auth_headers_factory):
        open_report, _, _ = test_reports
        headers, _ = auth_headers_factory(email="samaritan_dup@example.com")
        
        # 1st request succeeds
        res1 = client.post(
            "/api/contact-requests",
            json={"report_id": str(open_report.id), "message": "First message"},
            headers=headers
        )
        assert res1.status_code == 201

        # 2nd request with same report & user fails with 409
        res2 = client.post(
            "/api/contact-requests",
            json={"report_id": str(open_report.id), "message": "Duplicate message"},
            headers=headers
        )
        assert res2.status_code == 409
        assert "already exists" in res2.json()["detail"].lower()

    def test_list_requests_sent_and_received(self, client: TestClient, test_reports, auth_headers_factory):
        open_report, _, owner_user = test_reports
        sender_headers, _ = auth_headers_factory(email="samaritan_list@example.com")
        receiver_headers, _ = auth_headers_factory(email=owner_user.email)

        # Create a request first
        res_create = client.post(
            "/api/contact-requests",
            json={"report_id": str(open_report.id), "message": "List test message"},
            headers=sender_headers
        )
        assert res_create.status_code == 201

        # Sender list sent
        res_sent = client.get("/api/contact-requests?filter_type=sent", headers=sender_headers)
        assert res_sent.status_code == 200
        sent_items = res_sent.json()["items"]
        assert len(sent_items) >= 1

        # Receiver list received
        res_recv = client.get("/api/contact-requests?filter_type=received", headers=receiver_headers)
        assert res_recv.status_code == 200
        recv_items = res_recv.json()["items"]
        assert len(recv_items) >= 1

    def test_unauthorized_accept_or_reject(self, client: TestClient, test_reports, auth_headers_factory):
        open_report, _, _ = test_reports
        sender_headers, _ = auth_headers_factory(email="samaritan_auth@example.com")
        other_headers, _ = auth_headers_factory(email="intruder@example.com", name="Intruder")

        # Create request
        res_create = client.post(
            "/api/contact-requests",
            json={"report_id": str(open_report.id), "message": "Auth test message"},
            headers=sender_headers
        )
        assert res_create.status_code == 201
        cr_id = res_create.json()["id"]

        # Sender tries to accept own request -> forbidden
        res1 = client.patch(
            f"/api/contact-requests/{cr_id}/status",
            json={"status": "accepted"},
            headers=sender_headers
        )
        assert res1.status_code == 403

        # Stranger tries to accept/reject -> forbidden
        res2 = client.patch(
            f"/api/contact-requests/{cr_id}/status",
            json={"status": "rejected"},
            headers=other_headers
        )
        assert res2.status_code == 403

    def test_accept_request_and_reveal_privacy(self, client: TestClient, test_reports, auth_headers_factory, db_session):
        open_report, _, owner_user = test_reports
        receiver_headers, _ = auth_headers_factory(email=owner_user.email)
        sender_headers, sender_user = auth_headers_factory(email="samaritan_accept@example.com", phone="+14155559999")

        # Create request
        res_create = client.post(
            "/api/contact-requests",
            json={"report_id": str(open_report.id), "message": "Please accept", "sender_contact_info": "+14155559999"},
            headers=sender_headers
        )
        assert res_create.status_code == 201
        cr_id = res_create.json()["id"]

        # Receiver accepts request
        res = client.patch(
            f"/api/contact-requests/{cr_id}/status",
            json={"status": "accepted", "receiver_contact_info": "+19876543210 (text only)"},
            headers=receiver_headers
        )
        assert res.status_code == 200
        data = res.json()
        assert data["status"] == "accepted"
        # Receiver should see contact details
        assert data["receiver_contact_info"] == "+19876543210 (text only)"
        assert data["sender_contact_info"] == "+14155559999"

        # Sender viewing accepted request also gets contact details
        res_sender = client.get(f"/api/contact-requests/{cr_id}", headers=sender_headers)
        assert res_sender.status_code == 200
        sender_view = res_sender.json()
        assert sender_view["receiver_contact_info"] == "+19876543210 (text only)"

        # Notification created for sender
        notif = db_session.query(Notification).filter(
            Notification.user_id == sender_user.id,
            Notification.notification_type == "contact_response"
        ).first()
        assert notif is not None
        assert "accepted" in notif.title.lower()

    def test_transition_from_terminal_state_fails(self, client: TestClient, test_reports, auth_headers_factory):
        open_report, _, owner_user = test_reports
        receiver_headers, _ = auth_headers_factory(email=owner_user.email)
        sender_headers, _ = auth_headers_factory(email="samaritan_term@example.com")

        # Create and accept
        res_create = client.post(
            "/api/contact-requests",
            json={"report_id": str(open_report.id), "message": "Terminal test"},
            headers=sender_headers
        )
        cr_id = res_create.json()["id"]

        res_acc = client.patch(
            f"/api/contact-requests/{cr_id}/status",
            json={"status": "accepted"},
            headers=receiver_headers
        )
        assert res_acc.status_code == 200

        # Try to reject an already accepted request
        res = client.patch(
            f"/api/contact-requests/{cr_id}/status",
            json={"status": "rejected"},
            headers=receiver_headers
        )
        assert res.status_code == 400
        assert "cannot transition" in res.json()["detail"].lower()

    def test_reject_request_keeps_contact_private(self, client: TestClient, test_reports, auth_headers_factory):
        open_report, _, owner_user = test_reports
        headers_sender, _ = auth_headers_factory(email="sender_rej@example.com", name="Sender Two", phone="+1112223333")
        headers_receiver, _ = auth_headers_factory(email=owner_user.email)

        # Create new request
        res_create = client.post(
            "/api/contact-requests",
            json={"report_id": str(open_report.id), "message": "Is this your dog?", "sender_contact_info": "+1112223333"},
            headers=headers_sender
        )
        assert res_create.status_code == 201
        cr_id = res_create.json()["id"]

        # Reject it
        res_reject = client.patch(
            f"/api/contact-requests/{cr_id}/status",
            json={"status": "rejected"},
            headers=headers_receiver
        )
        assert res_reject.status_code == 200
        data = res_reject.json()
        assert data["status"] == "rejected"
        # Contact details must remain hidden / None
        assert data["sender_contact_info"] is None
        assert data["receiver_contact_info"] is None
        assert data["sender"]["phone"] is None
        assert data["receiver"]["phone"] is None
