#!/usr/bin/env bash
# rollback_backend.sh - Roll back the latest Railway backend deployment.
#
# Usage:
#   ./scripts/rollback_backend.sh                    # rolls back staging
#   ./scripts/rollback_backend.sh production         # rolls back production
#
# Notes:
#   Railway supports rollbacks through the CLI (`railway rollback`) or via
#   the dashboard (Deployment > ... > Rollback). This script wraps the CLI
#   command and runs a health check afterwards.
#
# Environment variables:
#   RAILWAY_TOKEN    - Railway service token (required)
#   RAILWAY_SERVICE  - service name (default: examboost-backend)

set -euo pipefail

# ─── Helpers ────────────────────────────────────────────────────────────
log() { printf '[rollback_backend] %s\n' "$*"; }
err() { printf '[rollback_backend] ERROR: %s\n' "$*" >&2; }

# ─── Configuration ──────────────────────────────────────────────────────
ENV="${1:-staging}"
RAILWAY_SERVICE="${RAILWAY_SERVICE:-examboost-backend}"

log "Rolling back Railway service '$RAILWAY_SERVICE' (env: $ENV)"

# ─── Pre-flight checks ─────────────────────────────────────────────────
if ! command -v railway >/dev/null 2>&1; then
    err "Railway CLI not found. Install with: npm install -g @railway/cli"
    exit 1
fi

if [ -z "${RAILWAY_TOKEN:-}" ]; then
    err "RAILWAY_TOKEN is not set."
    exit 1
fi

# ─── Rollback ───────────────────────────────────────────────────────────
log "Listing recent deployments for $RAILWAY_SERVICE ($ENV)..."
railway status --service "$RAILWAY_SERVICE" --environment "$ENV" || true

log "Triggering rollback..."
# Railway CLI may prompt for the deployment to roll back to. In CI, pipe
# the deployment ID via stdin or use the --detached flag if available.
if railway rollback --service "$RAILWAY_SERVICE" --environment "$ENV"; then
    log "Rollback command accepted."
else
    err "Railway rollback failed (maybe interactive prompt required)."
    err "Fallback: open the Railway dashboard and use Deployments > Rollback."
    err "URL: https://railway.app/project/<project-id>/service/<service-id>"
    exit 1
fi

# ─── Wait + health check ────────────────────────────────────────────────
log "Waiting 30s for the rollback to propagate..."
sleep 30

PUBLIC_URL="$(railway status --service "$RAILWAY_SERVICE" --environment "$ENV" --json 2>/dev/null \
    | jq -r '.deployments[0].url // .service.url // empty' 2>/dev/null || true)"

if [ -z "$PUBLIC_URL" ]; then
    log "Could not resolve the public URL automatically. Verify /health manually."
    exit 0
fi

PUBLIC_URL="${PUBLIC_URL%/}"
HEALTH_URL="${PUBLIC_URL}/health"

log "Health check: $HEALTH_URL"
if curl --silent --fail --max-time 10 "$HEALTH_URL" >/dev/null; then
    log "OK: rolled-back backend is healthy."
    log "Public URL: $PUBLIC_URL"
    exit 0
else
    err "Health check failed after rollback on $HEALTH_URL"
    err "Inspect logs: railway logs --service $RAILWAY_SERVICE --environment $ENV"
    exit 1
fi
