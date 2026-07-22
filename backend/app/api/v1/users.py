from fastapi import APIRouter, Depends

from app.dependencies import get_current_user
from app.models.user import User
from app.schemas.users import UserMeOut

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/me", response_model=UserMeOut)
async def get_me(current_user: User = Depends(get_current_user)) -> UserMeOut:
    return UserMeOut(id=current_user.id, email=current_user.email, name=current_user.username)
