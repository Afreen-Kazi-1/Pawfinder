import uuid
from sqlalchemy import Column, String, Text, DateTime
from sqlalchemy.orm import relationship
from app.core.database import Base, GUID, get_utc_now


class User(Base):
    __tablename__ = "users"

    id = Column(GUID, primary_key=True, default=uuid.uuid4)
    name = Column(String(100), nullable=False)
    email = Column(String(255), unique=True, index=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    phone = Column(String(30), nullable=True)
    profile_image_url = Column(Text, nullable=True)
    role = Column(String(20), default="user", nullable=False)  # 'user', 'admin'
    created_at = Column(DateTime(timezone=True), default=get_utc_now, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=get_utc_now, onupdate=get_utc_now, nullable=False)

    # Relationships
    reports = relationship("PetReport", back_populates="user", cascade="all, delete-orphan")
    sent_contact_requests = relationship(
        "ContactRequest",
        foreign_keys="ContactRequest.sender_id",
        back_populates="sender",
        cascade="all, delete-orphan"
    )
    received_contact_requests = relationship(
        "ContactRequest",
        foreign_keys="ContactRequest.receiver_id",
        back_populates="receiver",
        cascade="all, delete-orphan"
    )
    notifications = relationship("Notification", back_populates="user", cascade="all, delete-orphan")
    refresh_tokens = relationship("RefreshToken", back_populates="user", cascade="all, delete-orphan")
    abuse_reports_submitted = relationship(
        "AbuseReport",
        foreign_keys="AbuseReport.reporter_id",
        back_populates="reporter"
    )
    abuse_reports_received = relationship(
        "AbuseReport",
        foreign_keys="AbuseReport.reported_user_id",
        back_populates="reported_user"
    )

