import uuid
from sqlalchemy import Column, String, Text, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base, GUID, get_utc_now


class ContactRequest(Base):
    __tablename__ = "contact_requests"

    id = Column(GUID, primary_key=True, default=uuid.uuid4)
    sender_id = Column(GUID, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    receiver_id = Column(GUID, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    report_id = Column(GUID, ForeignKey("pet_reports.id", ondelete="CASCADE"), nullable=False, index=True)
    message = Column(Text, nullable=False)
    sender_contact_info = Column(String(255), nullable=True)
    receiver_contact_info = Column(String(255), nullable=True)
    status = Column(String(30), default="pending", nullable=False, index=True)  # 'pending', 'accepted', 'rejected'
    created_at = Column(DateTime(timezone=True), default=get_utc_now, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=get_utc_now, onupdate=get_utc_now, nullable=False)

    # Relationships
    sender = relationship("User", foreign_keys=[sender_id], back_populates="sent_contact_requests")
    receiver = relationship("User", foreign_keys=[receiver_id], back_populates="received_contact_requests")
    report = relationship("PetReport", back_populates="contact_requests")

