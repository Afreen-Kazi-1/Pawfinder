import uuid
from datetime import datetime, timezone, timedelta
from sqlalchemy.orm import Session

from app.models import (
    User,
    PetReport,
    PetImage,
    Match,
    ContactRequest,
    Notification,
    AbuseReport,
    RefreshToken,
    ReportTypeEnum,
    ReportStatusEnum,
    AnimalTypeEnum,
    GenderEnum,
    MatchCategoryEnum,
    MatchStatusEnum,
    ContactRequestStatusEnum,
    NotificationTypeEnum,
    AbuseStatusEnum,
)


def test_user_creation_and_uuid(db_session: Session):
    """Test User model creation, UUID generation, and UTC timestamps."""
    user = User(
        name="Alex Smith",
        email="alex@example.com",
        password_hash="hashedpassword123",
        phone="+1234567890",
        role="user",
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)

    assert user.id is not None
    assert isinstance(uuid.UUID(str(user.id)), uuid.UUID)
    assert user.name == "Alex Smith"
    assert user.email == "alex@example.com"
    assert user.created_at is not None
    assert user.updated_at is not None


def test_pet_report_and_image_creation(db_session: Session):
    """Test PetReport and PetImage models creation and relationship."""
    user = User(
        name="Sam Lost",
        email="sam@example.com",
        password_hash="hashedpassword123",
    )
    db_session.add(user)
    db_session.commit()

    event_time = datetime.now(timezone.utc)
    report = PetReport(
        user_id=user.id,
        report_type=ReportTypeEnum.LOST.value,
        pet_name="Buddy",
        animal_type=AnimalTypeEnum.DOG.value,
        breed="Golden Retriever",
        color="Golden",
        gender=GenderEnum.MALE.value,
        approximate_age="3 years",
        distinguishing_features="Red collar with bell",
        description="Friendly golden retriever missing near central park",
        latitude=40.785091,
        longitude=-73.968285,
        location_label="Central Park, New York",
        event_datetime=event_time,
        status=ReportStatusEnum.OPEN.value,
    )
    db_session.add(report)
    db_session.commit()
    db_session.refresh(report)

    assert report.id is not None
    assert report.pet_name == "Buddy"
    assert report.user_id == user.id

    image = PetImage(
        report_id=report.id,
        image_url="https://supabase.co/storage/pet-images/buddy1.jpg",
        storage_path="pet-images/buddy1.jpg",
    )
    db_session.add(image)
    db_session.commit()
    db_session.refresh(image)

    assert image.id is not None
    assert image.report_id == report.id
    assert len(report.images) == 1
    assert report.images[0].image_url == "https://supabase.co/storage/pet-images/buddy1.jpg"


def test_match_creation(db_session: Session):
    """Test Match model creation with JSON reasons and score."""
    user = User(name="Owner", email="owner@example.com", password_hash="hash")
    db_session.add(user)
    db_session.commit()

    lost_report = PetReport(
        user_id=user.id,
        report_type=ReportTypeEnum.LOST.value,
        pet_name="Max",
        animal_type=AnimalTypeEnum.DOG.value,
        color="Brown",
        distinguishing_features="",
        description="",
        latitude=40.0,
        longitude=-74.0,
        location_label="City",
        event_datetime=datetime.now(timezone.utc),
    )
    found_report = PetReport(
        user_id=user.id,
        report_type=ReportTypeEnum.FOUND.value,
        animal_type=AnimalTypeEnum.DOG.value,
        color="Brown",
        distinguishing_features="",
        description="",
        latitude=40.01,
        longitude=-74.01,
        location_label="Nearby City",
        event_datetime=datetime.now(timezone.utc),
    )
    db_session.add_all([lost_report, found_report])
    db_session.commit()

    match = Match(
        lost_report_id=lost_report.id,
        found_report_id=found_report.id,
        match_score=85.5,
        match_category=MatchCategoryEnum.HIGH.value,
        match_reasons={"animal_type_score": 100, "breed_score": 90, "distance_km": 1.2},
        status=MatchStatusEnum.SUGGESTED.value,
    )
    db_session.add(match)
    db_session.commit()
    db_session.refresh(match)

    assert match.id is not None
    assert match.match_score == 85.5
    assert match.match_reasons["animal_type_score"] == 100


def test_contact_request_and_notifications(db_session: Session):
    """Test ContactRequest and Notification models."""
    user1 = User(name="User 1", email="u1@example.com", password_hash="hash")
    user2 = User(name="User 2", email="u2@example.com", password_hash="hash")
    db_session.add_all([user1, user2])
    db_session.commit()

    report = PetReport(
        user_id=user1.id,
        report_type=ReportTypeEnum.LOST.value,
        animal_type=AnimalTypeEnum.CAT.value,
        color="Black",
        distinguishing_features="",
        description="",
        latitude=37.77,
        longitude=-122.41,
        location_label="Downtown",
        event_datetime=datetime.now(timezone.utc),
    )
    db_session.add(report)
    db_session.commit()

    contact_req = ContactRequest(
        sender_id=user2.id,
        receiver_id=user1.id,
        report_id=report.id,
        message="I think I found your cat!",
        status=ContactRequestStatusEnum.PENDING.value,
    )
    db_session.add(contact_req)

    notification = Notification(
        user_id=user1.id,
        title="New Contact Request",
        message="User 2 sent a contact request regarding your report.",
        notification_type=NotificationTypeEnum.CONTACT_REQUEST.value,
        related_entity_id=contact_req.id,
    )
    db_session.add(notification)
    db_session.commit()
    db_session.refresh(contact_req)
    db_session.refresh(notification)

    assert contact_req.id is not None
    assert notification.id is not None
    assert notification.is_read is False


def test_abuse_report_and_refresh_token(db_session: Session):
    """Test AbuseReport and RefreshToken creation."""
    user1 = User(name="Reporter", email="rep@example.com", password_hash="hash")
    user2 = User(name="BadActor", email="bad@example.com", password_hash="hash")
    db_session.add_all([user1, user2])
    db_session.commit()

    abuse = AbuseReport(
        reporter_id=user1.id,
        reported_user_id=user2.id,
        reason="Suspicious spam listing asking for money",
        status=AbuseStatusEnum.PENDING.value,
    )
    db_session.add(abuse)

    token = RefreshToken(
        user_id=user1.id,
        token_hash="fake-token-hash-12345",
        expires_at=datetime.now(timezone.utc) + timedelta(days=7),
    )
    db_session.add(token)
    db_session.commit()

    assert abuse.id is not None
    assert token.id is not None
    assert token.revoked is False

