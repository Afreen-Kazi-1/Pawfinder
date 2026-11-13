import uuid
from sqlalchemy import Column, String, Text, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base, GUID, get_utc_now


class AbuseReport(Base):
    __tablename__ = "abuse_reports"

    id = Column(GUID, primary_key=True, default=uuid.uuid4)
    reporter_id = Column(GUID, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    reported_user_id = Column(GUID, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    pet_report_id = Column(GUID, ForeignKey("pet_reports.id", ondelete="SET NULL"), nullable=True, index=True)
    reason = Column(Text, nullable=False)
    status = Column(String(30), default="pending", nullable=False, index=True)  # 'pending', 'reviewed', 'dismissed', 'action_taken'
    created_at = Column(DateTime(timezone=True), default=get_utc_now, nullable=False)

    # Relationships
    reporter = relationship("User", foreign_keys=[reporter_id], back_populates="abuse_reports_submitted")
    reported_user = relationship("User", foreign_keys=[reported_user_id], back_populates="abuse_reports_received")
    pet_report = relationship("PetReport", back_populates="abuse_reports")

