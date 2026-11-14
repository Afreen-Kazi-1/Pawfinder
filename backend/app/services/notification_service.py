import uuid
from typing import Optional, List, Tuple
from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import desc

from app.models.notification import Notification
from app.models.user import User


class NotificationService:
    @staticmethod
    def create_notification(
        db: Session,
        user_id: uuid.UUID,
        title: str,
        message: str,
        notification_type: str,
        related_entity_id: Optional[uuid.UUID] = None,
        prevent_duplicates: bool = True,
    ) -> Optional[Notification]:
        """
        Creates a persistent notification in PostgreSQL / database.
        If prevent_duplicates is True and related_entity_id is given,
        verifies that an unread notification of the same type and entity doesn't already exist.
        """
        if prevent_duplicates and related_entity_id is not None:
            existing = (
                db.query(Notification)
                .filter(
                    Notification.user_id == user_id,
                    Notification.notification_type == notification_type,
                    Notification.related_entity_id == related_entity_id,
                )
                .first()
            )
            if existing:
                return existing

        notif = Notification(
            user_id=user_id,
            title=title,
            message=message,
            notification_type=notification_type,
            related_entity_id=related_entity_id,
            is_read=False,
        )
        db.add(notif)
        db.commit()
        db.refresh(notif)
        return notif

    @staticmethod
    def get_user_notifications(
        db: Session,
        current_user: User,
        is_read: Optional[bool] = None,
        skip: int = 0,
        limit: int = 50,
    ) -> Tuple[List[Notification], int, int]:
        """
        Retrieves paginated notifications for the current user and total unread count.
        Ensures users can only view their own notifications.
        """
        base_query = db.query(Notification).filter(Notification.user_id == current_user.id)
        
        unread_count = (
            db.query(Notification)
            .filter(Notification.user_id == current_user.id, Notification.is_read.is_(False))
            .count()
        )

        query = base_query
        if is_read is not None:
            query = query.filter(Notification.is_read == is_read)

        total = query.count()
        items = query.order_by(desc(Notification.created_at)).offset(skip).limit(limit).all()

        return items, total, unread_count

    @staticmethod
    def mark_as_read(
        db: Session,
        notification_id: uuid.UUID,
        current_user: User,
    ) -> Notification:
        """
        Marks a specific notification as read.
        Enforces user ownership check.
        """
        notif = db.query(Notification).filter(Notification.id == notification_id).first()
        if not notif:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Notification not found",
            )

        if notif.user_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You do not have permission to modify this notification",
            )

        if not notif.is_read:
            notif.is_read = True
            db.add(notif)
            db.commit()
            db.refresh(notif)

        return notif

    @staticmethod
    def mark_all_as_read(
        db: Session,
        current_user: User,
    ) -> int:
        """
        Marks all unread notifications for the current user as read.
        """
        updated_count = (
            db.query(Notification)
            .filter(Notification.user_id == current_user.id, Notification.is_read.is_(False))
            .update({Notification.is_read: True}, synchronize_session=False)
        )
        db.commit()
        return updated_count

