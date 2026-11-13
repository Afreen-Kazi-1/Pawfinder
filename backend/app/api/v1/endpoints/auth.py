from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.schemas.auth import (
    UserRegisterRequest,
    UserLoginRequest,
    TokenResponse,
    RefreshTokenRequest,
    UserResponse,
    UserProfileUpdateRequest,
    PasswordChangeRequest,
    MessageResponse,
)
from app.services.auth_service import auth_service

router = APIRouter()


@router.post(
    "/register",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register a new user account",
)
def register(
    data: UserRegisterRequest,
    db: Session = Depends(get_db),
):
    """Registers a new user with name, email, and password.
    Password must meet strength criteria (min 8 chars, 1 digit, 1 letter).
    Passwords are salted and hashed using bcrypt.
    """
    user = auth_service.register_user(db=db, data=data)
    return user


@router.post(
    "/login",
    response_model=TokenResponse,
    status_code=status.HTTP_200_OK,
    summary="Authenticate user and return JWT access and refresh tokens",
)
def login(
    data: UserLoginRequest,
    db: Session = Depends(get_db),
):
    """Authenticates a user with email and password.
    Returns access token and refresh token upon success.
    Returns generic 401 response on failure to prevent user enumeration.
    """
    user = auth_service.authenticate_user(db=db, email=data.email, password=data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return auth_service.create_user_tokens(db=db, user=user)


@router.post(
    "/refresh",
    response_model=TokenResponse,
    status_code=status.HTTP_200_OK,
    summary="Rotate refresh token and obtain a new token pair",
)
def refresh_token(
    data: RefreshTokenRequest,
    db: Session = Depends(get_db),
):
    """Rotates an existing refresh token, revoking it and returning a new access/refresh token pair.
    Detects and blocks reused or expired tokens.
    """
    return auth_service.rotate_refresh_token(db=db, refresh_token_str=data.refresh_token)


@router.post(
    "/logout",
    response_model=MessageResponse,
    status_code=status.HTTP_200_OK,
    summary="Revoke the provided refresh token",
)
def logout(
    data: RefreshTokenRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Revokes the specified refresh token, logging out the active mobile session."""
    auth_service.revoke_refresh_token(db=db, refresh_token_str=data.refresh_token)
    return MessageResponse(message="Successfully logged out.")


@router.get(
    "/me",
    response_model=UserResponse,
    status_code=status.HTTP_200_OK,
    summary="Get current user profile information",
)
def get_me(
    current_user: User = Depends(get_current_user),
):
    """Retrieves profile information for the authenticated user."""
    return current_user


@router.put(
    "/me",
    response_model=UserResponse,
    status_code=status.HTTP_200_OK,
    summary="Update current user profile information",
)
def update_me(
    data: UserProfileUpdateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Updates user profile details (name, phone, profile image URL)."""
    updated_user = auth_service.update_user_profile(db=db, user=current_user, update_data=data)
    return updated_user


@router.post(
    "/change-password",
    response_model=MessageResponse,
    status_code=status.HTTP_200_OK,
    summary="Change user password and revoke existing sessions",
)
def change_password(
    data: PasswordChangeRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Validates the current password, sets the new password, and revokes active refresh tokens."""
    auth_service.change_user_password(
        db=db,
        user=current_user,
        current_password=data.current_password,
        new_password=data.new_password,
    )
    return MessageResponse(message="Password changed successfully. Please log in with your new password.")

