import uuid
from typing import List, Optional
from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_, desc

from app.models.contact_request import ContactRequest
from app.models.pet_report import PetReport
from app.models.user import User
from app.models.notification import Notification
from app.schemas.contact_request import (
    ContactRequestCreate,
    ContactRequestStatusUpdate,
    ContactRequestResponse,
    ContactRequestListResponse,
    ContactUserSummary,
    ContactReportSummary,
)


class ContactRequestService:
    @staticmethod
    def _to_response_dto(cr: ContactRequest, current_user_id: uuid.UUID) -> ContactRequestResponse:
        """
        Formats ContactRequest to response DTO while strictly enforcing privacy rules:
        - If status == 'accepted', authorized participants (sender and receiver) get contact details.
        - Otherwise, private phone & email are masked/omitted.
        """
        is_participant = (cr.sender_id == current_user_id or cr.receiver_id == current_user_id)
        is_accepted = cr.status.lower() == "accepted"

        # Sender summary
        sender_email = None
        sender_phone = None
        sender_contact = None
        if is_accepted and is_participant:
            sender_email = cr.sender.email if cr.sender else None
            sender_phone = cr.sender.phone if cr.sender else None
            sender_contact = cr.sender_contact_info or sender_phone or sender_email

        sender_summary = ContactUserSummary(
            id=cr.sender.id,
            name=cr.sender.name,
            email=sender_email,
            phone=sender_phone,
            profile_image_url=cr.sender.profile_image_url if cr.sender else None,
        )

        # Receiver summary
        receiver_email = None
        receiver_phone = None
        receiver_contact = None
        if is_accepted and is_participant:
            receiver_email = cr.receiver.email if cr.receiver else None
            receiver_phone = cr.receiver.phone if cr.receiver else None
            receiver_contact = cr.receiver_contact_info or receiver_phone or receiver_email

        receiver_summary = ContactUserSummary(
            id=cr.receiver.id,
            name=cr.receiver.name,
            email=receiver_email,
            phone=receiver_phone,
            profile_image_url=cr.receiver.profile_image_url if cr.receiver else None,
        )

        report_summary = None
        if cr.report:
            primary_img = None
            if hasattr(cr.report, "images") and cr.report.images:
                primary = next((img for img in cr.report.images if getattr(img, "is_primary", False)), cr.report.images[0])
                primary_img = primary.image_url if primary else None

            report_summary = ContactReportSummary(
                id=cr.report.id,
                report_type=cr.report.report_type,
                pet_name=cr.report.pet_name,
                animal_type=cr.report.animal_type,
                breed=cr.report.breed,
                status=cr.report.status,
                primary_image_url=primary_img,
            )

        return ContactRequestResponse(
            id=cr.id,
            report_id=cr.report_id,
            sender_id=cr.sender_id,
            receiver_id=cr.receiver_id,
            message=cr.message,
            status=cr.status.lower(),
            created_at=cr.created_at,
            updated_at=cr.updated_at,
            sender_contact_info=sender_contact,
            receiver_contact_info=receiver_contact,
            sender=sender_summary,
            receiver=receiver_summary,
            report=report_summary,
        )

    @classmethod
    def create_request(
        cls, db: Session, current_user: User, request_in: ContactRequestCreate
    ) -> ContactRequestResponse:
        # 1. Target report exists
        report = db.query(PetReport).filter(PetReport.id == request_in.report_id).first()
        if not report:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Pet report not found"
            )

        # 2. Check if report is closed or resolved
        if report.status.lower() in ["closed", "resolved"]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cannot send contact request for a {report.status.lower()} report"
            )

        # 3. Report owner is receiver; prevent self-contact
        receiver_id = report.user_id
        if receiver_id == current_user.id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="You cannot send a contact request to yourself"
            )

        # 4. Check duplicate pending request
        existing_pending = db.query(ContactRequest).filter(
            ContactRequest.sender_id == current_user.id,
            ContactRequest.receiver_id == receiver_id,
            ContactRequest.report_id == report.id,
            ContactRequest.status == "pending"
        ).first()

        if existing_pending:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="A pending contact request already exists for this report"
            )

        # 5. Create ContactRequest
        contact_request = ContactRequest(
            sender_id=current_user.id,
            receiver_id=receiver_id,
            report_id=report.id,
            message=request_in.message or "I have information regarding your pet report.",
            sender_contact_info=request_in.sender_contact_info or current_user.phone or current_user.email,
            status="pending"
        )
        db.add(contact_request)

        # 6. Create Notification for receiver
        pet_title = report.pet_name or f"{report.animal_type}"
        notif = Notification(
            user_id=receiver_id,
            title="New Contact Request",
            message=f"{current_user.name} sent you a contact request regarding report for '{pet_title}'.",
            notification_type="contact_request",
            related_entity_id=contact_request.id,
            is_read=False,
        )
        db.add(notif)
        db.commit()
        db.refresh(contact_request)

        return cls._to_response_dto(contact_request, current_user.id)

    @classmethod
    def get_user_requests(
        cls,
        db: Session,
        current_user: User,
        filter_type: Optional[str] = None, # 'sent', 'received', or None (both)
        status_filter: Optional[str] = None,
        skip: int = 0,
        limit: int = 50,
    ) -> ContactRequestListResponse:
        query = db.query(ContactRequest)

        if filter_type == "sent":
            query = query.filter(ContactRequest.sender_id == current_user.id)
        elif filter_type == "received":
            query = query.filter(ContactRequest.receiver_id == current_user.id)
        else:
            query = query.filter(
                or_(
                    ContactRequest.sender_id == current_user.id,
                    ContactRequest.receiver_id == current_user.id
                )
            )

        if status_filter:
            query = query.filter(ContactRequest.status == status_filter.lower())

        total = query.count()
        requests = query.order_by(desc(ContactRequest.created_at)).offset(skip).limit(limit).all()

        items = [cls._to_response_dto(cr, current_user.id) for cr in requests]
        return ContactRequestListResponse(items=items, total=total)

    @classmethod
    def get_request_by_id(
        cls, db: Session, current_user: User, request_id: uuid.UUID
    ) -> ContactRequestResponse:
        cr = db.query(ContactRequest).filter(ContactRequest.id == request_id).first()
        if not cr:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Contact request not found"
            )

        # Ensure authorization
        if cr.sender_id != current_user.id and cr.receiver_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You do not have access to this contact request"
            )

        return cls._to_response_dto(cr, current_user.id)

    @classmethod
    def update_request_status(
        cls,
        db: Session,
        current_user: User,
        request_id: uuid.UUID,
        status_in: ContactRequestStatusUpdate,
    ) -> ContactRequestResponse:
        cr = db.query(ContactRequest).filter(ContactRequest.id == request_id).first()
        if not cr:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Contact request not found"
            )

        target_status = status_in.status.lower()

        # Authorization & State Machine
        # Pending is the only state that can transition
        if cr.status.lower() != "pending":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cannot transition contact request from '{cr.status}' to '{target_status}'"
            )

        if target_status in ["accepted", "rejected"]:
            # Only receiver can accept or reject
            if cr.receiver_id != current_user.id:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Only the receiver can accept or reject a contact request"
                )
            if target_status == "accepted" and status_in.receiver_contact_info:
                cr.receiver_contact_info = status_in.receiver_contact_info
            elif target_status == "accepted" and not cr.receiver_contact_info:
                cr.receiver_contact_info = current_user.phone or current_user.email

        elif target_status == "cancelled":
            # Only sender can cancel
            if cr.sender_id != current_user.id:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Only the sender can cancel a contact request"
                )
        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid target status: {target_status}"
            )

        cr.status = target_status
        db.add(cr)

        # Generate notification for counterpart
        pet_title = cr.report.pet_name if cr.report and cr.report.pet_name else "pet report"
        if target_status == "accepted":
            notif = Notification(
                user_id=cr.sender_id,
                title="Contact Request Accepted!",
                message=f"{current_user.name} accepted your contact request for '{pet_title}'. Contact details are now available.",
                notification_type="contact_response",
                related_entity_id=cr.id,
                is_read=False,
            )
            db.add(notif)
        elif target_status == "rejected":
            notif = Notification(
                user_id=cr.sender_id,
                title="Contact Request Declined",
                message=f"Your contact request for '{pet_title}' was declined.",
                notification_type="contact_response",
                related_entity_id=cr.id,
                is_read=False,
            )
            db.add(notif)

        db.commit()
        db.refresh(cr)
        return cls._to_response_dto(cr, current_user.id)

