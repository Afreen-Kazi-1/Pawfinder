import uuid
from typing import List
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.api.deps import get_db, get_current_user
from app.models.user import User
from app.schemas.match import MatchRunResponse, MatchResponse
from app.services.match_service import MatchService

router = APIRouter()


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

