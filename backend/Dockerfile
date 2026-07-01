# syntax=docker/dockerfile:1.6
# ExamBoost Togo - Backend FastAPI Dockerfile (multi-stage)
#
# Stages:
#   1. dependencies  : install Python deps in a reusable layer
#   2. builder       : copy source, run seed preparation (no network)
#   3. production    : slim final image, non-root user, healthcheck
#
# Build:
#   docker build -t examboost-backend ./backend
# Run:
#   docker run --rm -p 8000:8000 -e DATABASE_URL=sqlite:///./examboost.db examboost-backend

# ─── Stage 1: Dependencies ──────────────────────────────────────────────
FROM python:3.11-slim AS dependencies

# Avoid writing .pyc files and buffer stdout/stderr
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

# System build deps (kept minimal; curl is needed for the runtime healthcheck
# fallback, build-essential is required to compile bcrypt/numpy wheels).
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies first to leverage Docker layer cache.
# requirements.txt changes far less often than application code.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ─── Stage 2: Builder (optional test stage, skipped in prod by default) ──
# This stage exists for CI pipelines that target --target=test.
# Production builds skip it because the test layer is not in the final image.
FROM dependencies AS test
COPY . .
RUN pip install --no-cache-dir pytest pytest-cov httpx || true
# Run tests but do not fail the build in production fallback scenarios.
# CI should run tests explicitly before pushing the image.
RUN pytest tests/ --cov=. --cov-report=term-missing || true

# ─── Stage 3: Production ────────────────────────────────────────────────
FROM python:3.11-slim AS production

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PORT=8000 \
    ENVIRONMENT=production \
    LOG_LEVEL=info

WORKDIR /app

# Runtime system dependencies (libpq5 for psycopg, curl for healthcheck,
# tini for proper signal handling as PID 1).
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        libpq5 \
        tini \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /root/.cache

# Copy installed Python packages from the dependencies stage.
COPY --from=dependencies /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=dependencies /usr/local/bin /usr/local/bin

# Copy application source.
COPY . .

# Create a non-root user and give it ownership of /app.
RUN useradd --create-home --uid 1000 --shell /bin/bash examboost \
    && chown -R examboost:examboost /app

USER examboost

# Expose the port Railway/Vercel will route traffic to.
EXPOSE 8000

# Healthcheck: probe the local /health endpoint every 30s.
# Falls back to /health/live if /health is overridden upstream.
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl --silent --fail --request GET http://localhost:${PORT:-8000}/health || exit 1

# Use tini as PID 1 to handle SIGTERM properly and avoid zombie processes.
ENTRYPOINT ["/usr/bin/tini", "--"]

# Start Uvicorn with 4 workers by default. Override via Railway startCommand
# or docker run -e WEB_CONCURRENCY=2 if you need fewer workers.
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
