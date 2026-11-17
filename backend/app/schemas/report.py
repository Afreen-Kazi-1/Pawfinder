import uuid
from decimal import Decimal
from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, Field, field_validator, ConfigDict
from app.schemas.image import PetImageResponse


VALID_REPORT_TYPES = {"LOST", "FOUND"}
VALID_STATUSES = {"Open", "Under Review", "Reunited / Resolved", "Closed", "RESOLVED", "CLOSED", "UNDER_REVIEW", "OPEN"}
VALID_GENDERS = {"Male", "Female", "Unknown", None}


class UserSummaryResponse(BaseModel):
    id: uuid.UUID
    name: str
    email: str
    phone: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


class PetReportBase(BaseModel):
    report_type: str = Field(..., description="Report type: 'LOST' or 'FOUND'")
    pet_name: Optional[str] = Field(None, max_length=100)
    animal_type: str = Field(..., min_length=1, max_length=50)
    breed: Optional[str] = Field(None, max_length=100)
    color: str = Field(..., min_length=1, max_length=100)
    gender: Optional[str] = Field(None, max_length=20)
    approximate_age: Optional[str] = Field(None, max_length=50)
    distinguishing_features: str = Field("", description="Markings, scars, collar, etc.")
    description: str = Field("", description="Detailed narrative and observations")
    latitude: float = Field(..., ge=-90.0, le=90.0)
    longitude: float = Field(..., ge=-180.0, le=180.0)
    location_label: str = Field(..., min_length=1, max_length=255)
    event_datetime: datetime
    reward: Optional[Decimal] = Field(None, ge=Decimal(0), decimal_places=2)

    @field_validator("report_type")
    @classmethod
    def validate_report_type(cls, v: str) -> str:
        upper = v.upper()
        if upper not in VALID_REPORT_TYPES:
            raise ValueError(f"Invalid report_type '{v}'. Must be 'LOST' or 'FOUND'.")
        return upper

    @field_validator("gender")
    @classmethod
    def validate_gender(cls, v: Optional[str]) -> Optional[str]:
        if v is None or not v.strip():
            return None
        title = v.strip().capitalize()
        if title not in {"Male", "Female", "Unknown"}:
            return title  # Allow custom or normalized
        return title


class PetReportCreate(PetReportBase):
    pass


class PetReportUpdate(BaseModel):
    pet_name: Optional[str] = None
    animal_type: Optional[str] = None
    breed: Optional[str] = None
    color: Optional[str] = None
    gender: Optional[str] = None
    approximate_age: Optional[str] = None
    distinguishing_features: Optional[str] = None
    description: Optional[str] = None
    latitude: Optional[float] = Field(None, ge=-90.0, le=90.0)
    longitude: Optional[float] = Field(None, ge=-180.0, le=180.0)
    location_label: Optional[str] = None
    event_datetime: Optional[datetime] = None
    reward: Optional[Decimal] = Field(None, ge=Decimal(0), decimal_places=2)
    status: Optional[str] = None

    @field_validator("status")
    @classmethod
    def validate_status(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and v not in VALID_STATUSES:
            raise ValueError(f"Invalid status '{v}'. Must be one of: {', '.join(VALID_STATUSES)}")
        return v


class PetReportStatusUpdate(BaseModel):
    status: str

    @field_validator("status")
    @classmethod
    def validate_status(cls, v: str) -> str:
        # Normalize uppercase/variants
        canonical_map = {
            "OPEN": "Open",
            "UNDER_REVIEW": "Under Review",
            "UNDER REVIEW": "Under Review",
            "RESOLVED": "Reunited / Resolved",
            "REUNITED / RESOLVED": "Reunited / Resolved",
            "CLOSED": "Closed",
        }
        val = canonical_map.get(v.strip().upper(), v.strip().title())
        allowed = {"Open", "Under Review", "Reunited / Resolved", "Closed"}
        if val not in allowed:
            raise ValueError(f"Invalid status '{v}'. Must be one of: {', '.join(allowed)}")
        return val


class PetReportResponse(PetReportBase):
    id: uuid.UUID
    user_id: uuid.UUID
    status: str
    reward: Optional[float] = None
    created_at: datetime
    updated_at: datetime
    images: List[PetImageResponse] = []
    user: Optional[UserSummaryResponse] = None

    model_config = ConfigDict(from_attributes=True)


class PetReportListResponse(BaseModel):
    items: List[PetReportResponse]
    total: int
    page: int
    size: int


class PetReportPublicResponse(BaseModel):
    """Public version of a pet report – hides exact coordinates.
    Approximate coordinates are rounded to 3 decimal places (~100 m) to preserve privacy.
    """
    id: uuid.UUID
    user_id: uuid.UUID
    report_type: str
    pet_name: Optional[str] = None
    animal_type: str
    breed: Optional[str] = None
    color: str
    gender: Optional[str] = None
    approximate_age: Optional[str] = None
    distinguishing_features: str = ""
    description: str = ""
    approx_latitude: float = Field(..., description="Rounded latitude for public display")
    approx_longitude: float = Field(..., description="Rounded longitude for public display")
    location_label: str
    event_datetime: datetime
    reward: Optional[float] = None
    status: str
    created_at: datetime
    updated_at: datetime
    images: List[PetImageResponse] = []
    distance_km: Optional[float] = None
    user: Optional[UserSummaryResponse] = None

    model_config = ConfigDict(from_attributes=True)


class PetReportPublicListResponse(BaseModel):
    items: List[PetReportPublicResponse]
    total: int
    page: int
    size: int

