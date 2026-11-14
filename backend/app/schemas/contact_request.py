from typing import Optional, List
from pydantic import BaseModel, Field, ConfigDict
from datetime import datetime
import uuid


class ContactUserSummary(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    name: str
    email: Optional[str] = None
    phone: Optional[str] = None
    profile_image_url: Optional[str] = None


class ContactReportSummary(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    report_type: str
    pet_name: Optional[str] = None
    animal_type: str
    breed: Optional[str] = None
    status: str
    primary_image_url: Optional[str] = None


class ContactRequestCreate(BaseModel):
    report_id: uuid.UUID
    message: Optional[str] = Field(None, max_length=1000)
    sender_contact_info: Optional[str] = Field(None, max_length=255)


class ContactRequestStatusUpdate(BaseModel):
    status: str = Field(..., pattern="^(accepted|rejected|cancelled|ACCEPTED|REJECTED|CANCELLED)$")
    receiver_contact_info: Optional[str] = Field(None, max_length=255)


class ContactRequestResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    report_id: uuid.UUID
    sender_id: uuid.UUID
    receiver_id: uuid.UUID
    message: Optional[str] = None
    status: str
    created_at: datetime
    updated_at: datetime
    
    # Authorized contact exchange fields (populated only when status is accepted and requester is participant)
    sender_contact_info: Optional[str] = None
    receiver_contact_info: Optional[str] = None
    
    # Populated entity summaries
    sender: ContactUserSummary
    receiver: ContactUserSummary
    report: Optional[ContactReportSummary] = None


class ContactRequestListResponse(BaseModel):
    items: List[ContactRequestResponse]
    total: int
