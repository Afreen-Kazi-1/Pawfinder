import uuid
from sqlalchemy import Column, String, Text, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base, GUID, get_utc_now


class PetImage(Base):
    __tablename__ = "pet_images"

    id = Column(GUID, primary_key=True, default=uuid.uuid4)
    report_id = Column(GUID, ForeignKey("pet_reports.id", ondelete="CASCADE"), nullable=False, index=True)
    image_url = Column(Text, nullable=False)
    storage_path = Column(Text, nullable=False)
    uploaded_at = Column(DateTime(timezone=True), default=get_utc_now, nullable=False)

    # Relationships
    report = relationship("PetReport", back_populates="images")

