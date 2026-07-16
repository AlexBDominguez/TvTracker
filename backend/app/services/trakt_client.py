from datetime import datetime, timedelta, timezone

import httpx
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_settings
from app.core.token_crypto import decrypt_token, encrypt_token
from app.models.trakt_credentials import TraktCredentials

settings = get_settings()

TRAKT_AUTHORIZE_URL = "https://trakt.tv/oauth/authorize"

# Refresh a bit before actual expiry to avoid using a token that dies mid-request.
REFRESH_SAFETY_MARGIN = timedelta(minutes=5)


def build_authorize_url(state: str) -> str:
    url = httpx.URL(
        TRAKT_AUTHORIZE_URL,
        params={
            "response_type": "code",
            "client_id": settings.TRAKT_CLIENT_ID,
            "redirect_uri": settings.TRAKT_REDIRECT_URI,
            "state": state,
        },
    )
    return str(url)


async def exchange_code_for_tokens(code: str) -> dict:
    async with httpx.AsyncClient(base_url=settings.TRAKT_BASE_URL, timeout=10) as client:
        response = await client.post(
            "/oauth/token",
            json={
                "code": code,
                "client_id": settings.TRAKT_CLIENT_ID,
                "client_secret": settings.TRAKT_CLIENT_SECRET,
                "redirect_uri": settings.TRAKT_REDIRECT_URI,
                "grant_type": "authorization_code",
            },
        )
        response.raise_for_status()
        return response.json()


async def refresh_tokens(refresh_token: str) -> dict:
    async with httpx.AsyncClient(base_url=settings.TRAKT_BASE_URL, timeout=10) as client:
        response = await client.post(
            "/oauth/token",
            json={
                "refresh_token": refresh_token,
                "client_id": settings.TRAKT_CLIENT_ID,
                "client_secret": settings.TRAKT_CLIENT_SECRET,
                "redirect_uri": settings.TRAKT_REDIRECT_URI,
                "grant_type": "refresh_token",
            },
        )
        response.raise_for_status()
        return response.json()


def token_response_to_expiry(token_data: dict) -> datetime:
    return datetime.now(timezone.utc) + timedelta(seconds=token_data["expires_in"])


async def get_valid_access_token(credentials: TraktCredentials, db: AsyncSession) -> str:
    """Return a usable Trakt access token for these credentials, refreshing (and
    persisting the refresh) first if it's expired or about to expire."""
    expires_at = credentials.expires_at
    if expires_at.tzinfo is None:
        expires_at = expires_at.replace(tzinfo=timezone.utc)

    if expires_at - REFRESH_SAFETY_MARGIN <= datetime.now(timezone.utc):
        token_data = await refresh_tokens(decrypt_token(credentials.refresh_token))
        credentials.access_token = encrypt_token(token_data["access_token"])
        credentials.refresh_token = encrypt_token(token_data["refresh_token"])
        credentials.expires_at = token_response_to_expiry(token_data)
        await db.commit()
        await db.refresh(credentials)

    return decrypt_token(credentials.access_token)
