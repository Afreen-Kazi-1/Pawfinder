import uuid
from sqlalchemy import Column, String, Text, Float, Numeric, DateTime, ForeignKey, Index
from sqlalchemy.orm import relationship
from app.core.database import Base, GUID, get_utc_now


class PetReport(Base):
    __tablename__ = "pet_reports"

    id = Column(GUID, primary_key=True, default=uuid.uuid4)
    user_id = Column(GUID, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    report_type = Column(String(20), nullable=False, index=True)  # 'LOST' or 'FOUND'
    pet_name = Column(String(100), nullable=True)
    animal_type = Column(String(50), nullable=False, index=True)  # 'Dog', 'Cat', 'Bird', 'Other'
    breed = Column(String(100), nullable=True, index=True)
    color = Column(String(100), nullable=False)
    gender = Column(String(20), nullable=True)  # 'Male', 'Female', 'Unknown'
    approximate_age = Column(String(50), nullable=True)
    distinguishing_features = Column(Text, nullable=False, default="")
    description = Column(Text, nullable=False, default="")
    latitude = Column(Float, nullable=False, index=True)
    longitude = Column(Float, nullable=False, index=True)
    location_label = Column(String(255), nullable=False)
    event_datetime = Column(DateTime(timezone=True), nullable=False)
    reward = Column(Numeric(10, 2), nullable=True)
    status = Column(String(30), default="Open", nullable=False, index=True)  # 'Open', 'Under Review', 'Reunited / Resolved', 'Closed'
    created_at = Column(DateTime(timezone=True), default=get_utc_now, nullable=False, index=True)
    updated_at = Column(DateTime(timezone=True), default=get_utc_now, onupdate=get_utc_now, nullable=False)

    # Relationships
    user = relationship("User", back_populates="reports")
    images = relationship("PetImage", back_populates="report", cascade="all, delete-orphan", order_by="PetImage.uploaded_at")
    lost_matches = relationship(
        "Match",
        foreign_keys="Match.lost_report_id",
        back_populates="lost_report",
        cascade="all, delete-orphan"
    )
    found_matches = relationship(
        "Match",
        foreign_keys="Match.found_report_id",
        back_populates="found_report",
        cascade="all, delete-orphan"
    )
    contact_requests = relationship("ContactRequest", back_populates="report", cascade="all, delete-orphan")
    abuse_reports = relationship("AbuseReport", back_populates="pet_report")

    __table_args__ = (
        Index("idx_pet_reports_search", "report_type", "status", "animal_type"),
        Index("idx_pet_reports_geo", "latitude", "longitude"),
    )

