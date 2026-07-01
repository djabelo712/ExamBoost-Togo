#!/usr/bin/env bash
# health_check.sh - Verify that backend + landing are reachable and healthy.
#
# Usage:
#   ./scripts/health_check.sh
#   BACKEND_URL=https://examboost-togo.up.railway.app ./scripts/health_check.sh
#   LANDING_URL=https://examboost-togo.vercel.app  ./scripts/health_check.sh
#
# Exit codes:
#   0 - all endpoints healthy
#   1 - at least one endpoint failed

set -uo pipefail

# ─── Helpers ────────────────────────────────────────────────────────────
log() { printf '[health_check] %s\n' "$*"; }
ok()  { printf '[health_check] OK    %s\n' "$*"; }
bad() { printf '[health_check] FAIL  %s\n' "$*" >&2; }

# ─── Configuration ──────────────────────────────────────────────────────
BACKEND_URL="${BACKEND_URL:-https://examboost-togo-staging.up.railway.app}"
LANDING_URL="${LANDING_URL:-https://examboost-togo.vercel.app}"
TIMEOUT="${TIMEOUT:-10}"

# Strip trailing slash.
BACKEND_URL="${BACKEND_URL%/}"
LANDING_URL="${LANDING_URL%/}"

log "Backend : $BACKEND_URL"
log "Landing : $LANDING_URL"
log ""

FAILURES=0

# ─── Check a single URL and increment FAILURES on error ─────────────────
check_url() {
    local label="$1"
    local url="$2"
    local expected_status="${3:-200}"
    if curl --silent --fail --max-time "$TIMEOUT" -o /dev/null -w '%{http_code}' "$url" \
        | grep -q "^${expected_status}"; then
        ok "$label ($url)"
    else
        bad "$label ($url) - expected HTTP $expected_status"
        FAILURES=$((FAILURES + 1))
    fi
}

# ─── Backend endpoints ──────────────────────────────────────────────────
check_url "Backend /health           " "$BACKEND_URL/health"
check_url "Backend /health/live      " "$BACKEND_URL/health/live"
check_url "Backend /health/ready     " "$BACKEND_URL/health/ready"
check_url "Backend /docs (Swagger)   " "$BACKEND_URL/docs"
check_url "Backend /openapi.json     " "$BACKEND_URL/openapi.json"
check_url "Backend / (root)          " "$BACKEND_URL/"

# ─── Landing endpoints ──────────────────────────────────────────────────
check_url "Landing /                 " "$LANDING_URL/"
check_url "Landing /merci            " "$LANDING_URL/merci"

# ─── Summary ────────────────────────────────────────────────────────────
log ""
if [ "$FAILURES" -eq 0 ]; then
    log "All endpoints healthy."
    exit 0
else
    bad "$FAILURES endpoint(s) failed."
    exit 1
fi
