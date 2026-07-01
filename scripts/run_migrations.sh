#!/usr/bin/env bash
# run_migrations.sh — Applique les migrations Alembic sur la DB cible.
#
# Usage :
#   ./scripts/run_migrations.sh                # utilise DATABASE_URL de l'env
#   DATABASE_URL=sqlite:///./examboost.db ./scripts/run_migrations.sh
#   DATABASE_URL=postgresql://user:pass@host/db ./scripts/run_migrations.sh
#
# Flags :
#   --downgrade-base   annule toutes les migrations (DANGEREUX, drop tables)
#   --downgrade-one    annule la derniere migration
#   --current          affiche seulement la revision courante
#   --history          affiche l'historique des revisions
#   --help             affiche cette aide
#
# Prerequis : avoir installe les deps backend (pip install -r backend/requirements.txt)

set -euo pipefail

# ─── Couleurs (desactivees si sortie non TTY) ────────────────────────
if [ -t 1 ]; then
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    YELLOW='\033[0;33m'
    NC='\033[0m'
else
    GREEN=''
    RED=''
    YELLOW=''
    NC=''
fi

log_info()  { echo -e "${GREEN}[run_migrations]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[run_migrations]${NC} $*"; }
log_error() { echo -e "${RED}[run_migrations]${NC} $*" >&2; }

# ─── Parsing des flags ───────────────────────────────────────────────
ACTION="upgrade"
TARGET="head"
SHOW_HELP=0

for arg in "$@"; do
    case "$arg" in
        --downgrade-base)
            ACTION="downgrade"
            TARGET="base"
            ;;
        --downgrade-one)
            ACTION="downgrade"
            TARGET="-1"
            ;;
        --current)
            ACTION="current"
            ;;
        --history)
            ACTION="history"
            ;;
        --help|-h)
            SHOW_HELP=1
            ;;
        *)
            log_warn "Flag inconnu : $arg (ignore)"
            ;;
    esac
done

if [ "$SHOW_HELP" = "1" ]; then
    sed -n '2,20p' "$0"
    exit 0
fi

# ─── Localisation du backend ─────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKEND_DIR="$REPO_ROOT/ExamBoost-Togo/backend"

if [ ! -d "$BACKEND_DIR" ]; then
    log_error "Dossier backend introuvable : $BACKEND_DIR"
    exit 1
fi

if [ ! -f "$BACKEND_DIR/alembic.ini" ]; then
    log_error "alembic.ini manquant dans $BACKEND_DIR"
    exit 1
fi

cd "$BACKEND_DIR"

# ─── Verification qu'Alembic est installe ────────────────────────────
if ! command -v alembic >/dev/null 2>&1; then
    # Tente le alembic du venv Python courant
    if python -m alembic --help >/dev/null 2>&1; then
        ALEMBIC_CMD="python -m alembic"
    else
        log_error "Alembic n'est pas installe. Lance : pip install -r backend/requirements.txt"
        exit 1
    fi
else
    ALEMBIC_CMD="alembic"
fi

# ─── Verification de DATABASE_URL ────────────────────────────────────
if [ -z "${DATABASE_URL:-}" ]; then
    # On laisse alembic.ini fournir sa valeur par defaut (sqlite:///./examboost.db)
    log_warn "DATABASE_URL non definie — utilisation de la valeur par defaut d'alembic.ini"
else
    log_info "DATABASE_URL = $DATABASE_URL"
fi

# ─── Execution de l'action ───────────────────────────────────────────
case "$ACTION" in
    upgrade)
        log_info "Application des migrations (target: $TARGET)..."
        $ALEMBIC_CMD upgrade "$TARGET"
        log_info "Migrations appliquees avec succes"
        $ALEMBIC_CMD current
        ;;
    downgrade)
        if [ "$TARGET" = "base" ]; then
            log_warn "ANNULATION de TOUTES les migrations — les tables metier seront supprimees !"
            read -r -p "Confirmer ? (tapez OUI) : " confirm
            if [ "$confirm" != "OUI" ]; then
                log_warn "Annule par l'utilisateur"
                exit 0
            fi
        fi
        log_info "Downgrade vers $TARGET..."
        $ALEMBIC_CMD downgrade "$TARGET"
        log_info "Downgrade applique"
        $ALEMBIC_CMD current
        ;;
    current)
        log_info "Revision courante :"
        $ALEMBIC_CMD current
        ;;
    history)
        log_info "Historique des revisions :"
        $ALEMBIC_CMD history --verbose
        ;;
esac
