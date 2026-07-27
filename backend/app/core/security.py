from datetime import datetime, timedelta, timezone

from jose import JWTError, jwt
from passlib.context import CryptContext

from app.core.config import get_settings

settings = get_settings()

pwd_context = CryptContext(schemes=["argon2"], deprecated="auto")

TRAKT_STATE_TOKEN_MINUTES = 10
_TRAKT_STATE_PURPOSE = "trakt_state"


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain_password: str, password_hash: str) -> bool:
    return pwd_context.verify(plain_password, password_hash)


def create_access_token(subject: str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(
        minutes=settings.JWT_ACCESS_TOKEN_EXPIRE_MINUTES
    )
    to_encode = {"sub": subject, "exp": expire}
    return jwt.encode(to_encode, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)


def decode_access_token(token: str) -> str:
    payload = jwt.decode(token, settings.JWT_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM])
    return payload["sub"]


def create_trakt_state_token(user_id: str) -> str:
    """Short-lived signed token carrying the user id through the Trakt OAuth2 redirect,
    since the callback request comes from the browser without our JWT header."""
    expire = datetime.now(timezone.utc) + timedelta(minutes=TRAKT_STATE_TOKEN_MINUTES)
    to_encode = {"sub": user_id, "exp": expire, "purpose": _TRAKT_STATE_PURPOSE}
    return jwt.encode(to_encode, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)


def decode_trakt_state_token(token: str) -> str:
    payload = jwt.decode(token, settings.JWT_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM])
    if payload.get("purpose") != _TRAKT_STATE_PURPOSE:
        raise JWTError("Invalid state token purpose")
    return payload["sub"]
