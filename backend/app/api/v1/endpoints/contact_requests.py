import uuid
from typing import Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.schemas.contact_request import (
    ContactRequestCreate,
    ContactRequestStatusUpdate,
    ContactRequestResponse,
    ContactRequestListResponse,
)
from app.services.contact_request_service import ContactRequestService

router = APIRouter()


@router.post("", response_model=ContactRequestResponse, status_code=status.HTTP_201_CREATED)
def create_contact_request(
    request_in: ContactRequestCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Send a contact request regarding a pet report to the report owner.
    """
    return ContactRequestService.create_request(
        db=db, current_user=current_user, request_in=request_in
    )


@router.get("", response_model=ContactRequestListResponse)
def get_contact_requests(
    filter_type: Optional[str] = Query(None, pattern="^(sent|received)$"),
    status: Optional[str] = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Get contact requests sent or received by the current user.
    """
    return ContactRequestService.get_user_requests(
        db=db,
        current_user=current_user,
        filter_type=filter_type,
        status_filter=status,
        skip=skip,
        limit=limit,
    )


@router.get("/{id}", response_model=ContactRequestResponse)
def get_contact_request(
    id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Get a specific contact request. Only participants (sender/receiver) may view.
    """
    return ContactRequestService.get_request_by_id(
        db=db, current_user=current_user, request_id=id
    )


@router.patch("/{id}/status", response_model=ContactRequestResponse)
def update_contact_request_status(
    id: uuid.UUID,
    status_in: ContactRequestStatusUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Update contact request status:
    - Receiver may 'accepted' or 'rejected'.
    - Sender may 'cancelled'.
    """
    return ContactRequestService.update_request_status(
        db=db, current_user=current_user, request_id=id, status_in=status_in
    )
