from collections.abc import Iterable

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import ACCESS_TOKEN, decode_token
from app.models import User, UserRole, UserStatus

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="api/v1/auth/login", auto_error=True)

_CREDENTIALS_EXC = HTTPException(
    status_code=status.HTTP_401_UNAUTHORIZED,
    detail={"code": "invalid_token", "message": "Could not validate credentials"},
    headers={"WWW-Authenticate": "Bearer"},
)


def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
) -> User:
    payload = decode_token(token)
    if not payload or payload.get("type") != ACCESS_TOKEN:
        raise _CREDENTIALS_EXC
    user_id = payload.get("sub")
    if user_id is None:
        raise _CREDENTIALS_EXC
    user = db.get(User, int(user_id))
    if user is None:
        raise _CREDENTIALS_EXC
    if user.status == UserStatus.blocked:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={"code": "account_blocked", "message": "Account is blocked"},
        )
    return user


def get_active_user(user: User = Depends(get_current_user)) -> User:
    """User whose registration has been approved (status=active)."""
    if user.status != UserStatus.active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={"code": "pending_approval", "message": "Account is awaiting approval"},
        )
    return user


def require_roles(*roles: UserRole):
    """Dependency factory guarding an endpoint to the given roles (active users only)."""

    allowed: Iterable[UserRole] = roles

    def _guard(user: User = Depends(get_active_user)) -> User:
        if user.role not in allowed:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail={"code": "forbidden", "message": "Insufficient permissions"},
            )
        return user

    return _guard
