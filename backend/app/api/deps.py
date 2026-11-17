import uuid
from typing import Optional
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.database import get_db
from app.core.security import decode_token
from app.models.user import User

security = HTTPBearer(auto_error=False)


def get_current_user(
    db: Session = Depends(get_db),
    auth: Optional[HTTPAuthorizationCredentials] = Depends(security),
) -> User:
    """Dependency that authenticates the user via JWT Bearer access token."""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    if not auth or not auth.credentials:
        raise credentials_exception

    token = auth.credentials
    payload = decode_token(token)
    if not payload:
        raise credentials_exception

    token_type = payload.get("type")
    if token_type != "access":
        raise credentials_exception

    user_id_str: Optional[str] = payload.get("sub")
    if not user_id_str:
        raise credentials_exception

    try:
        user_uuid = uuid.UUID(user_id_str)
    except ValueError:
        raise credentials_exception

    user = db.query(User).filter(User.id == user_uuid).first()
    if not user:
        raise credentials_exception

    return user


def get_current_active_user(
    current_user: User = Depends(get_current_user),
) -> User:
    """Dependency that ensures the authenticated user is active."""
    return current_user


def get_current_admin(
    current_user: User = Depends(get_current_user),
) -> User:
    """Dependency that ensures the authenticated user has admin role."""
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="The user does not have sufficient privileges for this operation.",
        )
    return current_user


def get_optional_current_user(
    db: Session = Depends(get_db),
    auth: Optional[HTTPAuthorizationCredentials] = Depends(security),
) -> Optional[User]:
    """Dependency for public endpoints that may provide customized data when logged in."""
    if not auth or not auth.credentials:
        return None

    token = auth.credentials
    payload = decode_token(token)
    if not payload or payload.get("type") != "access":
        return None

    user_id_str: Optional[str] = payload.get("sub")
    if not user_id_str:
        return None

    try:
        user_uuid = uuid.UUID(user_id_str)
    except ValueError:
        return None

    return db.query(User).filter(User.id == user_uuid).first()

