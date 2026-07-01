#!/usr/bin/env bash
# seed_prod_db.sh - Seed the production (or staging) database via the API.
#
# Usage:
#   ./scripts/seed_prod_db.sh
#   BACKEND_URL=https://examboost-togo-staging.up.railway.app ./scripts/seed_prod_db.sh
#
# This script is idempotent: re-running it will not duplicate questions
# (the backend dedupes by question id).
#
# Prerequisites:
#   - The backend must be deployed and reachable.
#   - The /admin/seed endpoint must be implemented (or fall back to a direct
#     Postgres exec if you have DATABASE_URL access).
#   - ADMIN_TOKEN env var: a JWT for an admin user, OR a shared secret
#     configured in ADMIN_SEED_TOKEN on the backend.

set -euo pipefail

# ─── Helpers ────────────────────────────────────────────────────────────
log() { printf '[seed_prod] %s\n' "$*"; }
err() { printf '[seed_prod] ERROR: %s\n' "$*" >&2; }

# ─── Configuration ──────────────────────────────────────────────────────
BACKEND_URL="${BACKEND_URL:-https://examboost-togo.up.railway.app}"
BACKEND_URL="${BACKEND_URL%/}"

if [ -z "${ADMIN_TOKEN:-}" ]; then
    err "ADMIN_TOKEN is not set. Generate a JWT for an admin user or set"
    err "ADMIN_SEED_TOKEN on the backend and use that value."
    exit 1
fi

log "Seeding database at $BACKEND_URL"

# ─── Pre-flight: backend reachable? ─────────────────────────────────────
log "Pre-flight: $BACKEND_URL/health"
if ! curl --silent --fail --max-time 10 "$BACKEND_URL/health" >/dev/null; then
    err "Backend is not reachable or unhealthy at $BACKEND_URL"
    exit 1
fi

# ─── Stats before seeding ───────────────────────────────────────────────
log "Stats BEFORE seeding:"
curl --silent --max-time 10 "$BACKEND_URL/health/stats" | jq . || true

# ─── Seed via /admin/seed ───────────────────────────────────────────────
SEED_PAYLOAD='{"source": "data/questions_seed.json", "mode": "upsert"}'

log "Calling POST $BACKEND_URL/admin/seed..."
HTTP_CODE="$(curl --silent --max-time 60 --write-out '%{http_code}' \
    -o /tmp/seed_response.json \
    -X POST "$BACKEND_URL/admin/seed" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$SEED_PAYLOAD" || true)"

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
    log "Seed response:"
    jq . /tmp/seed_response.json || cat /tmp/seed_response.json
else
    err "Seed failed with HTTP $HTTP_CODE"
    cat /tmp/seed_response.json || true
    err ""
    err "Fallback: run the seed directly against the database:"
    err "  DATABASE_URL='<your-postgres-url>' python backend/scripts/seed_db.py"
    exit 1
fi

# ─── Stats after seeding ────────────────────────────────────────────────
log "Stats AFTER seeding:"
curl --silent --max-time 10 "$BACKEND_URL/health/stats" | jq .

log "Seed complete."
