import uuid
from typing import Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.schemas.notification import (
    NotificationResponse,
    NotificationListResponse,
    NotificationBatchReadResponse,
)
from app.services.notification_service import NotificationService

router = APIRouter()


@router.get("", response_model=NotificationListResponse)
def get_notifications(
    is_read: Optional[bool] = Query(None, description="Filter by read status"),
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Retrieve current user's persistent in-app notifications with unread count.
    """
    items, total, unread_count = NotificationService.get_user_notifications(
        db=db,
        current_user=current_user,
        is_read=is_read,
        skip=skip,
        limit=limit,
    )
    return NotificationListResponse(items=items, total=total, unread_count=unread_count)


@router.patch("/read-all", response_model=NotificationBatchReadResponse)
def mark_all_notifications_as_read(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Mark all unread notifications for the current user as read.
    """
    updated_count = NotificationService.mark_all_as_read(
        db=db, current_user=current_user
    )
    return NotificationBatchReadResponse(
        updated_count=updated_count,
        message=f"Marked {updated_count} notification(s) as read",
    )


@router.patch("/{id}/read", response_model=NotificationResponse)
def mark_notification_as_read(
    id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Mark a single notification as read by ID.
    Enforces that users can only update their own notifications.
    """
    return NotificationService.mark_as_read(
        db=db, notification_id=id, current_user=current_user
    )

