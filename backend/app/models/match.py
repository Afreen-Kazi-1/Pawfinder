import uuid
from sqlalchemy import Column, String, Float, DateTime, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship
from app.core.database import Base, GUID, JSONType, get_utc_now


class Match(Base):
    __tablename__ = "matches"

    id = Column(GUID, primary_key=True, default=uuid.uuid4)
    lost_report_id = Column(GUID, ForeignKey("pet_reports.id", ondelete="CASCADE"), nullable=False, index=True)
    found_report_id = Column(GUID, ForeignKey("pet_reports.id", ondelete="CASCADE"), nullable=False, index=True)
    match_score = Column(Float, nullable=False)
    match_category = Column(String(50), nullable=False)  # 'High potential match', 'Possible match'
    match_reasons = Column(JSONType, nullable=False, default=dict)
    status = Column(String(30), default="Suggested", nullable=False, index=True)  # 'Suggested', 'Relevant', 'Dismissed', 'Resolved'
    created_at = Column(DateTime(timezone=True), default=get_utc_now, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=get_utc_now, onupdate=get_utc_now, nullable=False)

    # Relationships
    lost_report = relationship("PetReport", foreign_keys=[lost_report_id], back_populates="lost_matches")
    found_report = relationship("PetReport", foreign_keys=[found_report_id], back_populates="found_matches")

    __table_args__ = (
        UniqueConstraint("lost_report_id", "found_report_id", name="uq_lost_found_match"),
    )

