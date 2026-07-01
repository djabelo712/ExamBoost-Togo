#!/usr/bin/env bash
# deploy_all.sh - Deploy both the backend (Railway) and landing (Vercel).
#
# Usage:
#   ./scripts/deploy_all.sh                 # backend=staging, landing=preview
#   ./scripts/deploy_all.sh --prod          # backend=production, landing=prod
#   ./scripts/deploy_all.sh staging         # backend=staging, landing=preview
#   ./scripts/deploy_all.sh production --prod
#
# Prerequisites:
#   - ./scripts/deploy_backend.sh pre-flight requirements
#   - ./scripts/deploy_landing.sh pre-flight requirements
#   - ./scripts/health_check.sh

set -euo pipefail

# ─── Helpers ────────────────────────────────────────────────────────────
log() { printf '[deploy_all] %s\n' "$*"; }
err() { printf '[deploy_all] ERROR: %s\n' "$*" >&2; }

# ─── Argument parsing ───────────────────────────────────────────────────
BACKEND_ENV="staging"
LANDING_FLAG=""
for arg in "$@"; do
    case "$arg" in
        --prod)
            BACKEND_ENV="production"
            LANDING_FLAG="--prod"
            ;;
        staging|production)
            BACKEND_ENV="$arg"
            ;;
        *)
            err "Unknown argument: $arg"
            err "Usage: $0 [--prod] [staging|production]"
            exit 1
            ;;
    esac
done

# Resolve repo root (script lives in <root>/scripts/).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

log "Repository root: $REPO_ROOT"
log "Backend target:  Railway ($BACKEND_ENV)"
log "Landing target:  Vercel ($LANDING_FLAG -> ${LANDING_FLAG:-preview})"

# ─── Step 1: Backend ────────────────────────────────────────────────────
log "[1/3] Deploying backend to Railway ($BACKEND_ENV)..."
./scripts/deploy_backend.sh "$BACKEND_ENV"

# ─── Step 2: Landing ────────────────────────────────────────────────────
log "[2/3] Deploying landing to Vercel..."
./scripts/deploy_landing.sh $LANDING_FLAG

# ─── Step 3: Health check ───────────────────────────────────────────────
log "[3/3] Running health checks..."
case "$BACKEND_ENV" in
    production)
        export BACKEND_URL="${BACKEND_URL:-https://examboost-togo.up.railway.app}"
        export LANDING_URL="${LANDING_URL:-https://examboost-togo.vercel.app}"
        ;;
    *)
        export BACKEND_URL="${BACKEND_URL:-https://examboost-togo-staging.up.railway.app}"
        export LANDING_URL="${LANDING_URL:-https://examboost-togo.vercel.app}"
        ;;
esac
./scripts/health_check.sh

log "Deployment pipeline complete."
log "Backend: $BACKEND_URL"
log "Landing: $LANDING_URL"
log "Swagger: $BACKEND_URL/docs"
