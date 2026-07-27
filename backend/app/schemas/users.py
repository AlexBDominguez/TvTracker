from app.schemas.base import CamelModel


class UserMeOut(CamelModel):
    id: int
    email: str
    name: str
