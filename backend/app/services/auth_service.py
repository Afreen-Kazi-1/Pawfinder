import uuid
from datetime import datetime, timezone, timedelta
from typing import Optional
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.security import (
    get_password_hash,
    verify_password,
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_token,
)
from app.models.user import User
from app.models.refresh_token import RefreshToken
from app.schemas.auth import (
    UserRegisterRequest,
    TokenResponse,
    UserProfileUpdateRequest,
)


class AuthService:
    @staticmethod
    def register_user(db: Session, data: UserRegisterRequest) -> User:
        """Registers a new user after verifying email uniqueness and hashing password."""
        email_clean = data.email.lower().strip()
        existing_user = db.query(User).filter(User.email == email_clean).first()
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="A user with this email address already exists.",
            )

        hashed_password = get_password_hash(data.password)
        new_user = User(
            name=data.name.strip(),
            email=email_clean,
            password_hash=hashed_password,
            role="user",
        )
        db.add(new_user)
        db.commit()
        db.refresh(new_user)
        return new_user

    @staticmethod
    def authenticate_user(db: Session, email: str, password: str) -> Optional[User]:
        """Authenticates a user against their stored bcrypt hash."""
        email_clean = email.lower().strip()
        user = db.query(User).filter(User.email == email_clean).first()
        if not user:
            return None
        if not verify_password(password, user.password_hash):
            return None
        return user

    @staticmethod
    def create_user_tokens(db: Session, user: User) -> TokenResponse:
        """Issues an access token and refresh token, persisting the refresh token hash."""
        user_id_str = str(user.id)
        access_token = create_access_token(subject=user_id_str)
        refresh_token = create_refresh_token(subject=user_id_str)

        # Calculate expiration in UTC
        expires_at = datetime.now(timezone.utc) + timedelta(days=settings.JWT_REFRESH_TOKEN_EXPIRE_DAYS)

        # Store hashed refresh token
        db_refresh_token = RefreshToken(
            user_id=user.id,
            token_hash=hash_token(refresh_token),
            expires_at=expires_at,
            revoked=False,
        )
        db.add(db_refresh_token)
        db.commit()

        return TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            token_type="bearer",
            expires_in=settings.JWT_ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        )

    @staticmethod
    def rotate_refresh_token(db: Session, refresh_token_str: str) -> TokenResponse:
        """Rotates a refresh token: revokes the old one and issues a fresh token pair."""
        payload = decode_token(refresh_token_str)
        if not payload or payload.get("type") != "refresh":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid or expired refresh token.",
                headers={"WWW-Authenticate": "Bearer"},
            )

        token_h = hash_token(refresh_token_str)
        stored_token = db.query(RefreshToken).filter(RefreshToken.token_hash == token_h).first()

        if not stored_token:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Refresh token not recognized or revoked.",
                headers={"WWW-Authenticate": "Bearer"},
            )

        if stored_token.revoked:
            # Token reuse detected! Revoke all tokens for this user for security
            AuthService.revoke_all_user_tokens(db, stored_token.user_id)
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Revoked refresh token reuse detected. Please log in again.",
                headers={"WWW-Authenticate": "Bearer"},
            )

        # Check expiration with timezone-awareness
        expires_at = stored_token.expires_at
        if expires_at.tzinfo is None:
            expires_at = expires_at.replace(tzinfo=timezone.utc)
        if expires_at < datetime.now(timezone.utc):
            stored_token.revoked = True
            db.commit()
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Refresh token has expired.",
                headers={"WWW-Authenticate": "Bearer"},
            )

        user = db.query(User).filter(User.id == stored_token.user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User associated with token no longer exists.",
                headers={"WWW-Authenticate": "Bearer"},
            )

        # Mark current token as revoked
        stored_token.revoked = True
        db.commit()

        # Issue new pair
        return AuthService.create_user_tokens(db, user)

    @staticmethod
    def revoke_refresh_token(db: Session, refresh_token_str: str) -> None:
        """Revokes a specific refresh token during logout."""
        token_h = hash_token(refresh_token_str)
        stored_token = db.query(RefreshToken).filter(RefreshToken.token_hash == token_h).first()
        if stored_token:
            stored_token.revoked = True
            db.commit()

    @staticmethod
    def revoke_all_user_tokens(db: Session, user_id: uuid.UUID) -> None:
        """Revokes all active refresh tokens for a user."""
        db.query(RefreshToken).filter(
            RefreshToken.user_id == user_id,
            RefreshToken.revoked == False,
        ).update({"revoked": True})
        db.commit()

    @staticmethod
    def change_user_password(
        db: Session, user: User, current_password: str, new_password: str
    ) -> None:
        """Validates current password and updates to new password, revoking existing tokens."""
        if not verify_password(current_password, user.password_hash):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Current password is incorrect.",
            )

        user.password_hash = get_password_hash(new_password)
        db.commit()

        # Revoke all existing sessions
        AuthService.revoke_all_user_tokens(db, user.id)

    @staticmethod
    def update_user_profile(
        db: Session, user: User, update_data: UserProfileUpdateRequest
    ) -> User:
        """Updates user profile details."""
        if update_data.name is not None:
            user.name = update_data.name.strip()
        if update_data.phone is not None:
            user.phone = update_data.phone.strip()
        if update_data.profile_image_url is not None:
            user.profile_image_url = update_data.profile_image_url

        db.commit()
        db.refresh(user)
        return user


auth_service = AuthService()

