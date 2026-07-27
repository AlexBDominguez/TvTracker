from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1.auth import router as auth_router
from app.api.v1.content import content_router, router as content_router_legacy
from app.api.v1.library import router as library_router
from app.api.v1.sync import router as sync_router
from app.api.v1.trakt_auth import router as trakt_auth_router
from app.api.v1.tracking import router as tracking_router
from app.api.v1.users import router as users_router
from app.core.config import get_settings
from app.core.exceptions import register_exception_handlers
from app.core.logging import configure_logging

configure_logging()

settings = get_settings()

app = FastAPI(title=settings.APP_NAME)

register_exception_handlers(app)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router, prefix="/api/v1")
app.include_router(trakt_auth_router, prefix="/api/v1")
app.include_router(content_router_legacy, prefix="/api/v1")
app.include_router(content_router, prefix="/api/v1")
app.include_router(sync_router, prefix="/api/v1")
app.include_router(users_router, prefix="/api/v1")
app.include_router(library_router, prefix="/api/v1")
app.include_router(tracking_router, prefix="/api/v1")


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}
