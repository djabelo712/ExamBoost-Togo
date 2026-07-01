#!/usr/bin/env bash
# deploy_landing.sh - Deploy the Next.js landing page to Vercel.
#
# Usage:
#   ./scripts/deploy_landing.sh             # preview deployment
#   ./scripts/deploy_landing.sh --prod      # production deployment
#
# Prerequisites:
#   - Vercel CLI installed (npm install -g vercel)
#   - Authenticated: `vercel login` (one-time, interactive)
#   - Project linked: `vercel link` (one-time, run from landing/)
#
# Environment variables (optional overrides):
#   LANDING_DIR  - path to landing/ (default: ./landing)
#   SKIP_BUILD   - set to "1" to skip the local build verification

set -euo pipefail

# ─── Helpers ────────────────────────────────────────────────────────────
log() { printf '[deploy_landing] %s\n' "$*"; }
err() { printf '[deploy_landing] ERROR: %s\n' "$*" >&2; }

# ─── Configuration ──────────────────────────────────────────────────────
PROD_FLAG="${1:-}"
LANDING_DIR="${LANDING_DIR:-./landing}"
SKIP_BUILD="${SKIP_BUILD:-0}"

log "Deploying ExamBoost landing page to Vercel"

# ─── Pre-flight checks ─────────────────────────────────────────────────
if ! command -v vercel >/dev/null 2>&1; then
    err "Vercel CLI not found. Install with: npm install -g vercel"
    exit 1
fi

if [ ! -d "$LANDING_DIR" ]; then
    err "Landing directory not found: $LANDING_DIR"
    exit 1
fi

if [ ! -f "$LANDING_DIR/package.json" ]; then
    err "package.json not found in $LANDING_DIR"
    exit 1
fi

# Verify authentication (non-fatal if already authed via token).
log "Checking Vercel authentication..."
vercel whoami >/dev/null 2>&1 || {
    err "Not authenticated. Run 'vercel login' first."
    exit 1
}

# Verify project link (creates .vercel/project.json).
if [ ! -f "$LANDING_DIR/.vercel/project.json" ]; then
    log "Project not linked. Run 'vercel link' inside $LANDING_DIR first."
    log "Or set VERCEL_PROJECT_ID and VERCEL_ORG_ID env vars."
    err "Aborting."
    exit 1
fi

# ─── Local build verification (optional) ────────────────────────────────
if [ "$SKIP_BUILD" != "1" ]; then
    log "Running local build verification..."
    (
        cd "$LANDING_DIR"
        if [ ! -d node_modules ]; then
            log "Installing dependencies (npm ci)..."
            npm ci
        fi
        npm run build
    )
    log "Local build OK."
else
    log "SKIP_BUILD=1, skipping local build verification."
fi

# ─── Deploy ─────────────────────────────────────────────────────────────
log "Deploying to Vercel..."
(
    cd "$LANDING_DIR"
    if [ "$PROD_FLAG" = "--prod" ]; then
        log "Target: PRODUCTION"
        vercel --prod --yes
    else
        log "Target: PREVIEW (use --prod for production)"
        vercel --yes
    fi
)

log "Landing deployment complete."
log "Preview URL: https://examboost-togo.vercel.app (once promoted to production)"
log "Dashboard:   https://vercel.com/dashboard"
