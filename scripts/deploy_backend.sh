#!/usr/bin/env bash
# deploy_backend.sh - Deploy the FastAPI backend to Railway.
#
# Usage:
#   ./scripts/deploy_backend.sh           # deploys to staging
#   ./scripts/deploy_backend.sh staging   # explicit staging
#   ./scripts/deploy_backend.sh production # deploys to production
#
# Prerequisites:
#   - Railway CLI installed (npm install -g @railway/cli)
#   - RAILWAY_TOKEN env var set (service token from Railway dashboard)
#   - Project linked to Railway: `railway link` (one-time)
#
# Environment variables (optional overrides):
#   RAILWAY_TOKEN       - Railway service token (required)
#   RAILWAY_SERVICE     - service name (default: examboost-backend)
#   BACKEND_DIR         - path to backend/ (default: ./backend)
#   HEALTH_TIMEOUT      - seconds to wait for /health (default: 120)

set -euo pipefail

# ─── Helpers ────────────────────────────────────────────────────────────
log() { printf '[deploy_backend] %s\n' "$*"; }
err() { printf '[deploy_backend] ERROR: %s\n' "$*" >&2; }

# ─── Configuration ──────────────────────────────────────────────────────
ENV="${1:-staging}"
RAILWAY_SERVICE="${RAILWAY_SERVICE:-examboost-backend}"
BACKEND_DIR="${BACKEND_DIR:-./backend}"
HEALTH_TIMEOUT="${HEALTH_TIMEOUT:-120}"

log "Deploying ExamBoost backend to Railway (environment: $ENV)"

# ─── Pre-flight checks ─────────────────────────────────────────────────
if ! command -v railway >/dev/null 2>&1; then
    err "Railway CLI not found. Install with: npm install -g @railway/cli"
    exit 1
fi

if [ -z "${RAILWAY_TOKEN:-}" ]; then
    err "RAILWAY_TOKEN is not set. Create a service token in Railway > Settings > Tokens."
    exit 1
fi

if [ ! -d "$BACKEND_DIR" ]; then
    err "Backend directory not found: $BACKEND_DIR"
    exit 1
fi

# Authenticate using the service token (non-interactive).
log "Authenticating to Railway with RAILWAY_TOKEN..."
RAILWAY_TOKEN="$RAILWAY_TOKEN" railway login --token "$RAILWAY_TOKEN" 2>/dev/null \
    || true  # already logged in via token env var

# Verify project link.
log "Checking Railway project link..."
railway status >/dev/null 2>&1 || {
    err "Railway project not linked. Run 'railway link' from the repo root first."
    exit 1
}

# ─── Build & deploy ─────────────────────────────────────────────────────
log "Pushing $BACKEND_DIR to Railway service '$RAILWAY_SERVICE' (env: $ENV)..."
(
    cd "$BACKEND_DIR"
    railway up --service "$RAILWAY_SERVICE" --environment "$ENV"
)

# ─── Wait for deployment to be live ────────────────────────────────────
log "Waiting for deployment to be promoted (timeout: ${HEALTH_TIMEOUT}s)..."
elapsed=0
while [ "$elapsed" -lt "$HEALTH_TIMEOUT" ]; do
    sleep 5
    elapsed=$((elapsed + 5))
    printf '.'
done
echo

# Resolve the public URL for the deployed service.
PUBLIC_URL="$(railway status --service "$RAILWAY_SERVICE" --environment "$ENV" --json 2>/dev/null \
    | jq -r '.deployments[0].url // .service.url // empty' 2>/dev/null || true)"

if [ -z "$PUBLIC_URL" ]; then
    log "Could not resolve the public URL automatically."
    log "Check the Railway dashboard for the live URL and run:"
    log "  curl -f https://<your-backend-url>/health"
    log "Backend deployment pushed. Verify manually."
    exit 0
fi

# Normalize URL (strip trailing slash).
PUBLIC_URL="${PUBLIC_URL%/}"
HEALTH_URL="${PUBLIC_URL}/health"

# ─── Health check ───────────────────────────────────────────────────────
log "Health check: $HEALTH_URL"
if curl --silent --fail --max-time 10 "$HEALTH_URL" >/dev/null; then
    log "OK: backend is healthy."
    log "Public URL: $PUBLIC_URL"
    log "Swagger UI: $PUBLIC_URL/docs"
    log "Detailed health: $PUBLIC_URL/health/detailed"
    exit 0
else
    err "Health check failed on $HEALTH_URL"
    err "Inspect logs: railway logs --service $RAILWAY_SERVICE --environment $ENV"
    exit 1
fi
