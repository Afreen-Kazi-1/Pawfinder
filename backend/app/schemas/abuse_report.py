import uuid
from typing import Optional, List
from pydantic import BaseModel, Field, ConfigDict
from datetime import datetime


class AbuseReportUserSummary(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    name: str
    email: str
    role: str


class AbuseReportPetSummary(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    pet_name: Optional[str] = None
    animal_type: str
    report_type: str
    status: str


class AbuseReportCreate(BaseModel):
    pet_report_id: Optional[uuid.UUID] = None
    reported_user_id: Optional[uuid.UUID] = None
    reason: str = Field(..., min_length=5, max_length=1500)


class AbuseReportStatusUpdate(BaseModel):
    status: str = Field(..., pattern="^(pending|under_review|resolved|dismissed|PENDING|UNDER_REVIEW|RESOLVED|DISMISSED)$")


class AbuseReportResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    reporter_id: uuid.UUID
    reported_user_id: uuid.UUID
    pet_report_id: Optional[uuid.UUID] = None
    reason: str
    status: str
    created_at: datetime
    reporter: Optional[AbuseReportUserSummary] = None
    reported_user: Optional[AbuseReportUserSummary] = None
    pet_report: Optional[AbuseReportPetSummary] = None


class AbuseReportListResponse(BaseModel):
    items: List[AbuseReportResponse]
    total: int

