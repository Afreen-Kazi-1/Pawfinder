import pytest
from datetime import datetime, timezone
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError

from app.models import (
    User,
    PetReport,
    Match,
    ReportTypeEnum,
    ReportStatusEnum,
    AnimalTypeEnum,
    MatchCategoryEnum,
    MatchStatusEnum,
)


def test_unique_email_constraint(db_session: Session):
    """Test that creating two users with the same email raises IntegrityError."""
    user1 = User(name="User A", email="duplicate@example.com", password_hash="hashA")
    db_session.add(user1)
    db_session.commit()

    user2 = User(name="User B", email="duplicate@example.com", password_hash="hashB")
    db_session.add(user2)
    with pytest.raises(IntegrityError):
        db_session.commit()
    db_session.rollback()


def test_duplicate_match_constraint(db_session: Session):
    """Test that creating a second match between identical lost and found reports raises IntegrityError."""
    user = User(name="User Test", email="unique_match@example.com", password_hash="hash")
    db_session.add(user)
    db_session.commit()

    lost = PetReport(
        user_id=user.id,
        report_type=ReportTypeEnum.LOST.value,
        animal_type=AnimalTypeEnum.DOG.value,
        color="Black",
        latitude=10.0,
        longitude=10.0,
        location_label="Loc",
        event_datetime=datetime.now(timezone.utc),
    )
    found = PetReport(
        user_id=user.id,
        report_type=ReportTypeEnum.FOUND.value,
        animal_type=AnimalTypeEnum.DOG.value,
        color="Black",
        latitude=10.1,
        longitude=10.1,
        location_label="Loc",
        event_datetime=datetime.now(timezone.utc),
    )
    db_session.add_all([lost, found])
    db_session.commit()

    match1 = Match(
        lost_report_id=lost.id,
        found_report_id=found.id,
        match_score=90.0,
        match_category=MatchCategoryEnum.HIGH.value,
        match_reasons={},
        status=MatchStatusEnum.SUGGESTED.value,
    )
    db_session.add(match1)
    db_session.commit()

    match2 = Match(
        lost_report_id=lost.id,
        found_report_id=found.id,
        match_score=95.0,
        match_category=MatchCategoryEnum.HIGH.value,
        match_reasons={},
        status=MatchStatusEnum.SUGGESTED.value,
    )
    db_session.add(match2)
    with pytest.raises(IntegrityError):
        db_session.commit()
    db_session.rollback()


def test_cascade_delete_user_reports(db_session: Session):
    """Test that deleting a user cascades and removes their reports."""
    user = User(name="Delete Me", email="delete_me@example.com", password_hash="hash")
    db_session.add(user)
    db_session.commit()

    report = PetReport(
        user_id=user.id,
        report_type=ReportTypeEnum.LOST.value,
        animal_type=AnimalTypeEnum.CAT.value,
        color="Orange",
        latitude=0.0,
        longitude=0.0,
        location_label="Loc",
        event_datetime=datetime.now(timezone.utc),
    )
    db_session.add(report)
    db_session.commit()

    report_id = report.id
    db_session.delete(user)
    db_session.commit()

    deleted_report = db_session.query(PetReport).filter(PetReport.id == report_id).first()
    assert deleted_report is None


def test_enum_values_integrity():
    """Verify that domain enum classes have expected string values."""
    assert ReportTypeEnum.LOST.value == "LOST"
    assert ReportTypeEnum.FOUND.value == "FOUND"
    assert ReportStatusEnum.OPEN.value == "Open"
    assert ReportStatusEnum.CLOSED.value == "Closed"
    assert AnimalTypeEnum.DOG.value == "Dog"
    assert AnimalTypeEnum.CAT.value == "Cat"
    assert MatchCategoryEnum.HIGH.value == "High potential match"
    assert MatchCategoryEnum.POSSIBLE.value == "Possible match"

