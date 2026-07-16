from typing import Any

from cachetools import TTLCache

# TTL 24h per REQUISITOS_BACKEND.md 6.2. Async on purpose even though the current
# backend is a plain in-memory dict, so swapping to Redis later doesn't touch callers.
_cache: TTLCache = TTLCache(maxsize=1000, ttl=60 * 60 * 24)


async def cache_get(key: str) -> Any | None:
    return _cache.get(key)


async def cache_set(key: str, value: Any) -> None:
    _cache[key] = value
