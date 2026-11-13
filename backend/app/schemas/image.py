import uuid
from datetime import datetime
from pydantic import BaseModel, ConfigDict


class PetImageBase(BaseModel):
    image_url: str
    storage_path: str


class PetImageCreate(PetImageBase):
    report_id: uuid.UUID


class PetImageResponse(PetImageBase):
    id: uuid.UUID
    report_id: uuid.UUID
    uploaded_at: datetime

    model_config = ConfigDict(from_attributes=True)

