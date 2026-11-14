import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.api.deps import get_db, get_current_user
from app.models.user import User
from app.schemas.match import (
    MatchRunResponse,
    MatchResponse,
    MatchListResponse,
    MatchStatusUpdate,
)
from app.services.match_service import MatchService

router = APIRouter()


@router.get(
    "",
    response_model=MatchListResponse,
    summary="Get matches for the authenticated user's reports",
)
def list_user_matches(
    status: Optional[str] = Query(None, description="Filter by status: Suggested, Relevant, Dismissed, Resolved"),
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Retrieves all matches for reports submitted by the logged-in user.
    Includes original lost and found reports, match scores, and explainable reasons.
    """
    service = MatchService(db)
    items, total = service.get_user_matches(
        current_user=current_user,
        status_filter=status,
        page=page,
        size=size,
    )
    return MatchListResponse(items=items, total=total, page=page, size=size)


@router.get(
    "/{id}",
    response_model=MatchResponse,
    summary="Get match details by ID",
)
def get_match_detail(
    id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Retrieves specific match details, verifying authorization."""
    service = MatchService(db)
    return service.get_match_by_id(id, current_user)


@router.patch(
    "/{id}/status",
    response_model=MatchResponse,
    summary="Update match status (e.g. Relevant, Dismissed, Resolved)",
)
def update_match_status(
    id: uuid.UUID,
    status_in: MatchStatusUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Updates match status enforcing valid lifecycle transitions."""
    service = MatchService(db)
    return service.update_match_status(id, status_in.status, current_user)


@router.post(
    "/run/{report_id}",
    response_model=MatchRunResponse,
    status_code=status.HTTP_200_OK,
    summary="Run the matching engine for a pet report",
)
def run_matching(
    report_id: uuid.UUID,
    db: Session = Depends(get_db),
    _: User = Depends(get_current_user),
):
    """Executes the automated matching algorithm for a given report (lost or found).
    Compares against existing counter-reports, scores compatibility, and persists matches.
    """
    service = MatchService(db)
    matches = service.run_matching_for_report(report_id)
    return MatchRunResponse(
        report_id=report_id,
        matches_found=len(matches),
        matches=matches,
    )


@router.get(
    "/report/{report_id}",
    response_model=List[MatchResponse],
    summary="Get all persisted matches for a report",
)
def get_report_matches(
    report_id: uuid.UUID,
    db: Session = Depends(get_db),
    _: User = Depends(get_current_user),
):
    """Returns stored matches for the specified report."""
    service = MatchService(db)
    return service.get_matches_for_report(report_id)
