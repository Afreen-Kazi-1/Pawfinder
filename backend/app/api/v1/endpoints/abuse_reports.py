import uuid
from typing import Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.api.deps import get_current_user, get_current_admin
from app.models.user import User
from app.schemas.abuse_report import (
    AbuseReportCreate,
    AbuseReportStatusUpdate,
    AbuseReportResponse,
    AbuseReportListResponse,
)
from app.services.abuse_report_service import AbuseReportService

router = APIRouter()


@router.post("/abuse-reports", response_model=AbuseReportResponse, status_code=status.HTTP_201_CREATED)
def submit_abuse_report(
    report_in: AbuseReportCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Submit an abuse report regarding a suspicious pet report or user.
    Open to all authenticated users.
    """
    return AbuseReportService.create_abuse_report(
        db=db, current_user=current_user, report_in=report_in
    )


@router.get("/admin/abuse-reports", response_model=AbuseReportListResponse)
def get_abuse_reports_admin(
    status: Optional[str] = Query(None, description="pending, under_review, resolved, dismissed"),
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    db: Session = Depends(get_db),
    admin_user: User = Depends(get_current_admin),
):
    """
    List all abuse reports. Strictly restricted to administrators.
    """
    return AbuseReportService.list_abuse_reports_admin(
        db=db, status_filter=status, skip=skip, limit=limit
    )


@router.get("/admin/abuse-reports/{id}", response_model=AbuseReportResponse)
def get_abuse_report_details_admin(
    id: uuid.UUID,
    db: Session = Depends(get_db),
    admin_user: User = Depends(get_current_admin),
):
    """
    Get detailed abuse report. Strictly restricted to administrators.
    """
    return AbuseReportService.get_abuse_report_admin(db=db, report_id=id)


@router.patch("/admin/abuse-reports/{id}", response_model=AbuseReportResponse)
def update_abuse_report_status_admin(
    id: uuid.UUID,
    status_in: AbuseReportStatusUpdate,
    db: Session = Depends(get_db),
    admin_user: User = Depends(get_current_admin),
):
    """
    Update abuse report moderation status (under_review, resolved, dismissed).
    Strictly restricted to administrators.
    """
    return AbuseReportService.update_abuse_report_status_admin(
        db=db, report_id=id, status_in=status_in
    )

