import asyncio
import uuid
from collections.abc import AsyncGenerator, Iterator

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.pool import StaticPool

from app.db.base import Base
from app.db.session import get_db
from app.main import app
from app.services.cache import _cache

TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"


@pytest.fixture(autouse=True)
def _clear_cache() -> Iterator[None]:
    _cache.clear()
    yield
    _cache.clear()


@pytest.fixture()
def client() -> Iterator[TestClient]:
    engine = create_async_engine(
        TEST_DATABASE_URL,
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    session_factory = async_sessionmaker(engine, expire_on_commit=False)

    async def _create_tables() -> None:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)

    asyncio.run(_create_tables())

    async def override_get_db() -> AsyncGenerator[AsyncSession, None]:
        async with session_factory() as session:
            yield session

    app.dependency_overrides[get_db] = override_get_db

    with TestClient(app) as test_client:
        test_client.session_factory = session_factory  # type: ignore[attr-defined]
        yield test_client

    app.dependency_overrides.clear()
    asyncio.run(engine.dispose())


@pytest.fixture()
def auth_headers(client: TestClient) -> dict[str, str]:
    username = f"user_{uuid.uuid4().hex[:10]}"
    password = "supersecret1"
    client.post(
        "/api/v1/auth/register",
        json={"username": username, "email": f"{username}@example.com", "password": password},
    )
    response = client.post(
        "/api/v1/auth/login", json={"username": username, "password": password}
    )
    token = response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}
