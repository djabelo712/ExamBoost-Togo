"""healthcheck.py - Health endpoints and Docker health probe.

This module exposes:
  * An ``APIRouter`` (``health_router``) with detailed health endpoints that
    can be mounted in ``main.py`` (NOT modified by this agent):

        from healthcheck import health_router
        app.include_router(health_router, tags=["meta"])

    Endpoints:
      - GET /health/live     : liveness probe (always 200 if process is up)
      - GET /health/ready    : readiness probe (DB must be reachable)
      - GET /health/detailed : full status (DB + Redis + config)
      - GET /health/stats    : lightweight DB counts (questions/users/...)

  * A ``__main__`` entrypoint usable as a Docker HEALTHCHECK probe:

        python healthcheck.py

    Exits 0 if ``GET /health`` responds 2xx on localhost, 1 otherwise.

The basic ``GET /health`` endpoint is already defined in ``main.py`` and
returns ``{"status": "ok", ...}``. This module complements it without
conflicting with the existing route.
"""

from __future__ import annotations

import os
import sys
import time
from datetime import datetime, timezone
from typing import Any, Dict

from fastapi import APIRouter, Depends
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from config import settings
from database import get_db
from models.db_models import Question, Response, Simulation, User

# Process start time (module-level, captured at import). Used for uptime.
_PROCESS_START: float = time.time()

# Application version (single source of truth: keep in sync with main.py).
APP_VERSION: str = "0.1.0"

health_router = APIRouter(prefix="/health", tags=["meta"])


def _uptime_seconds() -> float:
    """Seconds elapsed since the Python process started."""
    return round(time.time() - _PROCESS_START, 2)


def _check_database(db: Session) -> Dict[str, Any]:
    """Run a trivial SELECT 1 to verify DB connectivity."""
    try:
        db.execute(select(1))
        return {"status": "healthy"}
    except Exception as exc:  # pragma: no cover - defensive
        return {"status": "unhealthy", "error": str(exc)}


def _check_redis() -> Dict[str, Any]:
    """Optionally probe Redis if REDIS_URL is configured."""
    redis_url = os.getenv("REDIS_URL", "").strip()
    if not redis_url:
        return {"status": "not_configured"}
    try:
        # Lazy import: redis is optional and may not be installed.
        import redis  # type: ignore

        client = redis.from_url(redis_url, socket_connect_timeout=2)
        pong = client.ping()
        return {"status": "healthy" if pong else "unhealthy"}
    except Exception as exc:  # pragma: no cover - defensive
        return {"status": "unhealthy", "error": str(exc)}


def _safe_database_url() -> str:
    """Return DATABASE_URL with credentials stripped for safe logging."""
    url = settings.DATABASE_URL
    if "@" in url:
        # Strip user:pass@ from the URL
        scheme, rest = url.split("://", 1) if "://" in url else ("", url)
        if "@" in rest:
            host_part = rest.split("@", 1)[1]
            return f"{scheme}://***@{host_part}"
    if url.startswith("sqlite"):
        return url
    return "***"


@health_router.get(
    "/live",
    summary="Liveness probe (always 200 if the process is up)",
)
def health_live() -> Dict[str, Any]:
    return {
        "status": "alive",
        "service": "examboost-backend",
        "version": APP_VERSION,
        "uptime_seconds": _uptime_seconds(),
    }


@health_router.get(
    "/ready",
    summary="Readiness probe (database must be reachable)",
)
def health_ready(db: Session = Depends(get_db)) -> Dict[str, Any]:
    db_status = _check_database(db)
    ready = db_status.get("status") == "healthy"
    return {
        "status": "ready" if ready else "not_ready",
        "database": db_status,
    }


@health_router.get(
    "/detailed",
    summary="Detailed health (DB + Redis + config)",
)
def health_detailed(db: Session = Depends(get_db)) -> Dict[str, Any]:
    db_status = _check_database(db)
    redis_status = _check_redis()
    overall = "healthy" if db_status.get("status") == "healthy" else "unhealthy"
    return {
        "status": overall,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "version": APP_VERSION,
        "environment": os.getenv("ENVIRONMENT", "development"),
        "uptime_seconds": _uptime_seconds(),
        "services": {
            "database": db_status,
            "redis": redis_status,
        },
        "config": {
            "cors_origins": settings.CORS_ORIGINS,
            "database_url": _safe_database_url(),
            "log_level": os.getenv("LOG_LEVEL", "info"),
        },
    }


@health_router.get(
    "/stats",
    summary="Lightweight DB counts (questions / users / responses / simulations)",
)
def health_stats(db: Session = Depends(get_db)) -> Dict[str, Any]:
    try:
        questions = db.scalar(select(func.count(Question.id))) or 0
        users = db.scalar(select(func.count(User.id))) or 0
        responses = db.scalar(select(func.count(Response.id))) or 0
        simulations = db.scalar(select(func.count(Simulation.id))) or 0
        return {
            "status": "healthy",
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "stats": {
                "questions": questions,
                "users": users,
                "responses": responses,
                "simulations": simulations,
            },
            "uptime_seconds": _uptime_seconds(),
        }
    except Exception as exc:  # pragma: no cover - defensive
        return {
            "status": "unhealthy",
            "error": str(exc),
            "timestamp": datetime.now(timezone.utc).isoformat(),
        }


# ─── Docker HEALTHCHECK probe ───────────────────────────────────────────
def _probe_local_health(port: int | None = None) -> int:
    """Probe the local /health endpoint. Returns 0 on success, 1 on failure.

    Used as the Docker HEALTHCHECK command:
        python healthcheck.py
    """
    import urllib.error
    import urllib.request

    target_port = port or int(os.getenv("PORT", "8000"))
    url = f"http://localhost:{target_port}/health"
    try:
        with urllib.request.urlopen(url, timeout=5) as resp:
            if 200 <= resp.status < 300:
                return 0
            return 1
    except (urllib.error.URLError, TimeoutError, ConnectionError, OSError):
        return 1


if __name__ == "__main__":  # pragma: no cover - manual / Docker invocation
    sys.exit(_probe_local_health())
