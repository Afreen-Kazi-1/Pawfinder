import uuid
from datetime import datetime
from typing import Optional, Dict, Any, List
from pydantic import BaseModel, ConfigDict
from app.schemas.report import PetReportResponse


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


class MatchRunResponse(BaseModel):
    report_id: uuid.UUID
    matches_found: int
    matches: List[MatchResponse]

