import uuid
from datetime import datetime
from typing import Optional, Dict, Any, List
from pydantic import BaseModel, ConfigDict, field_validator
from app.schemas.report import PetReportResponse

VALID_MATCH_STATUSES = {"Suggested", "Relevant", "Dismissed", "Resolved"}


class MatchStatusUpdate(BaseModel):
    status: str

    @field_validator("status")
    @classmethod
    def validate_status(cls, v: str) -> str:
        title_val = v.strip().title()
        if title_val not in VALID_MATCH_STATUSES:
            raise ValueError(
                f"Invalid match status '{v}'. Must be one of: {', '.join(sorted(VALID_MATCH_STATUSES))}"
            )
        return title_val


class MatchResponse(BaseModel):
    id: uuid.UUID
    lost_report_id: uuid.UUID
    found_report_id: uuid.UUID
    match_score: float
    match_category: str
    match_reasons: Dict[str, Any]
    status: str
    created_at: datetime
    updated_at: datetime
    lost_report: Optional[PetReportResponse] = None
    found_report: Optional[PetReportResponse] = None

    model_config = ConfigDict(from_attributes=True)


class MatchListResponse(BaseModel):
    items: List[MatchResponse]
    total: int
    page: int
    size: int


class MatchRunResponse(BaseModel):
    report_id: uuid.UUID
    matches_found: int
    matches: List[MatchResponse]
