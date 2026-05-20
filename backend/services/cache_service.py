import json
import logging
import time

import redis.asyncio as aioredis

from config import settings


logger = logging.getLogger(__name__)
redis_client = aioredis.from_url(settings.redis_url, decode_responses=True)
_redis_available = True
_memory_cache: dict[str, tuple[float, object]] = {}


def _memory_get(key: str):
    row = _memory_cache.get(key)
    if row is None:
        return None
    expires_at, value = row
    if expires_at < time.time():
        _memory_cache.pop(key, None)
        return None
    return value


def _memory_set(key: str, value, ttl_seconds: int):
    _memory_cache[key] = (time.time() + ttl_seconds, value)


def _memory_delete_pattern(pattern: str):
    prefix = pattern[:-1] if pattern.endswith("*") else pattern
    for key in list(_memory_cache):
        if key.startswith(prefix):
            _memory_cache.pop(key, None)


async def get_cached(key: str):
    global _redis_available
    fallback = _memory_get(key)
    if fallback is not None:
        return fallback
    if not _redis_available:
        return None
    try:
        val = await redis_client.get(key)
        return json.loads(val) if val else None
    except Exception as exc:
        _redis_available = False
        logger.warning("Redis unavailable; using in-memory cache fallback: %s", exc)
        return None


async def set_cached(key: str, value, ttl_seconds: int = 300):
    global _redis_available
    _memory_set(key, value, ttl_seconds)
    if not _redis_available:
        return
    try:
        await redis_client.setex(key, ttl_seconds, json.dumps(value, default=str, ensure_ascii=False))
    except Exception as exc:
        _redis_available = False
        logger.warning("Redis unavailable; cache kept in memory: %s", exc)


async def invalidate(key: str):
    global _redis_available
    _memory_cache.pop(key, None)
    if not _redis_available:
        return
    try:
        await redis_client.delete(key)
    except Exception as exc:
        _redis_available = False
        logger.warning("Redis unavailable; invalidated memory cache only: %s", exc)


async def invalidate_pattern(pattern: str):
    global _redis_available
    _memory_delete_pattern(pattern)
    if not _redis_available:
        return
    try:
        keys = await redis_client.keys(pattern)
        if keys:
            await redis_client.delete(*keys)
    except Exception as exc:
        _redis_available = False
        logger.warning("Redis unavailable; invalidated memory cache only: %s", exc)
