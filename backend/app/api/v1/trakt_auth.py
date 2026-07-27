from fastapi import APIRouter, Depends, HTTPException, status
from jose import JWTError
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_trakt_state_token, decode_trakt_state_token
from app.core.token_crypto import encrypt_token
from app.db.session import get_db
from app.dependencies import get_current_user
from app.models.trakt_credentials import TraktCredentials
from app.models.user import User
from app.schemas.trakt import TraktConnectResponse, TraktStatus
from app.services.trakt_client import (
    build_authorize_url,
    exchange_code_for_tokens,
    get_valid_access_token,
    token_response_to_expiry,
)

router = APIRouter(prefix="/auth/trakt", tags=["trakt"])


@router.get("/connect", response_model=TraktConnectResponse)
async def connect(current_user: User = Depends(get_current_user)) -> TraktConnectResponse:
    state = create_trakt_state_token(str(current_user.id))
    return TraktConnectResponse(authorize_url=build_authorize_url(state))


@router.get("/callback")
async def callback(code: str, state: str, db: AsyncSession = Depends(get_db)) -> dict:
    try:
        user_id = int(decode_trakt_state_token(state))
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid or expired state"
        )

    token_data = await exchange_code_for_tokens(code)

    expires_at = token_response_to_expiry(token_data)
    credentials = await db.scalar(
        select(TraktCredentials).where(TraktCredentials.user_id == user_id)
    )
    if credentials is None:
        credentials = TraktCredentials(user_id=user_id)
        db.add(credentials)

    credentials.access_token = encrypt_token(token_data["access_token"])
    credentials.refresh_token = encrypt_token(token_data["refresh_token"])
    credentials.expires_at = expires_at

    await db.commit()
    return {"status": "connected"}


@router.get("/status", response_model=TraktStatus)
async def get_trakt_status(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> TraktStatus:
    credentials = await db.scalar(
        select(TraktCredentials).where(TraktCredentials.user_id == current_user.id)
    )
    if credentials is None:
        return TraktStatus(connected=False)

    await get_valid_access_token(credentials, db)

    return TraktStatus(connected=True, expires_at=credentials.expires_at)
