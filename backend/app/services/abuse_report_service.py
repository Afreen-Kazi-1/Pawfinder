import uuid
from typing import Optional, List, Tuple
from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import desc

from app.models.abuse_report import AbuseReport
from app.models.pet_report import PetReport
from app.models.user import User
from app.schemas.abuse_report import (
    AbuseReportCreate,
    AbuseReportStatusUpdate,
    AbuseReportResponse,
    AbuseReportListResponse,
    AbuseReportUserSummary,
    AbuseReportPetSummary,
)

# Permitted state transitions for moderation lifecycle
VALID_MODERATION_STATUSES = {"pending", "under_review", "resolved", "dismissed"}

PERMITTED_MODERATION_TRANSITIONS = {
    "pending": {"under_review", "resolved", "dismissed"},
    "under_review": {"resolved", "dismissed"},
    "resolved": {"under_review"}, # Re-open if necessary
    "dismissed": {"under_review"}, # Re-open if necessary
}


class AbuseReportService:
    @staticmethod
    def _to_response_dto(ar: AbuseReport) -> AbuseReportResponse:
        reporter_summary = None
        if ar.reporter:
            reporter_summary = AbuseReportUserSummary(
                id=ar.reporter.id,
                name=ar.reporter.name,
                email=ar.reporter.email,
                role=ar.reporter.role,
            )

        reported_summary = None
        if ar.reported_user:
            reported_summary = AbuseReportUserSummary(
                id=ar.reported_user.id,
                name=ar.reported_user.name,
                email=ar.reported_user.email,
                role=ar.reported_user.role,
            )

        pet_summary = None
        if ar.pet_report:
            pet_summary = AbuseReportPetSummary(
                id=ar.pet_report.id,
                pet_name=ar.pet_report.pet_name,
                animal_type=ar.pet_report.animal_type,
                report_type=ar.pet_report.report_type,
                status=ar.pet_report.status,
            )

        return AbuseReportResponse(
            id=ar.id,
            reporter_id=ar.reporter_id,
            reported_user_id=ar.reported_user_id,
            pet_report_id=ar.pet_report_id,
            reason=ar.reason,
            status=ar.status.lower(),
            created_at=ar.created_at,
            reporter=reporter_summary,
            reported_user=reported_summary,
            pet_report=pet_summary,
        )

    @classmethod
    def create_abuse_report(
        cls, db: Session, current_user: User, report_in: AbuseReportCreate
    ) -> AbuseReportResponse:
        reported_user_id = report_in.reported_user_id
        pet_report_id = report_in.pet_report_id

        # Must target either a pet report or a specific user
        if not pet_report_id and not reported_user_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Either pet_report_id or reported_user_id must be provided.",
            )

        # If a pet report is specified, verify it exists and determine the reported user
        if pet_report_id:
            pet_report = db.query(PetReport).filter(PetReport.id == pet_report_id).first()
            if not pet_report:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Pet report not found.",
                )
            if reported_user_id and reported_user_id != pet_report.user_id:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Reported user does not match pet report owner.",
                )
            reported_user_id = pet_report.user_id

        # Verify reported user exists
        reported_user = db.query(User).filter(User.id == reported_user_id).first()
        if not reported_user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Reported user not found.",
            )

        # Cannot report oneself
        if reported_user_id == current_user.id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="You cannot report your own account or listing.",
            )

        abuse_report = AbuseReport(
            reporter_id=current_user.id,
            reported_user_id=reported_user_id,
            pet_report_id=pet_report_id,
            reason=report_in.reason.strip(),
            status="pending",
        )
        db.add(abuse_report)
        db.commit()
        db.refresh(abuse_report)

        return cls._to_response_dto(abuse_report)

    @classmethod
    def list_abuse_reports_admin(
        cls,
        db: Session,
        status_filter: Optional[str] = None,
        skip: int = 0,
        limit: int = 50,
    ) -> AbuseReportListResponse:
        query = db.query(AbuseReport)
        if status_filter:
            norm_status = status_filter.lower()
            if norm_status in VALID_MODERATION_STATUSES:
                query = query.filter(AbuseReport.status == norm_status)

        total = query.count()
        reports = query.order_by(desc(AbuseReport.created_at)).offset(skip).limit(limit).all()

        items = [cls._to_response_dto(r) for r in reports]
        return AbuseReportListResponse(items=items, total=total)

    @classmethod
    def get_abuse_report_admin(
        cls, db: Session, report_id: uuid.UUID
    ) -> AbuseReportResponse:
        ar = db.query(AbuseReport).filter(AbuseReport.id == report_id).first()
        if not ar:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Abuse report not found.",
            )
        return cls._to_response_dto(ar)

    @classmethod
    def update_abuse_report_status_admin(
        cls, db: Session, report_id: uuid.UUID, status_in: AbuseReportStatusUpdate
    ) -> AbuseReportResponse:
        ar = db.query(AbuseReport).filter(AbuseReport.id == report_id).first()
        if not ar:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Abuse report not found.",
            )

        current_st = ar.status.lower()
        target_st = status_in.status.lower()

        if target_st not in VALID_MODERATION_STATUSES:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid moderation status: {target_st}",
            )

        if target_st == current_st:
            return cls._to_response_dto(ar)

        allowed_next = PERMITTED_MODERATION_TRANSITIONS.get(current_st, set())
        if target_st not in allowed_next:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cannot transition abuse report from '{current_st}' to '{target_st}'.",
            )

        ar.status = target_st
        db.add(ar)
        db.commit()
        db.refresh(ar)

        return cls._to_response_dto(ar)

