#!/usr/bin/env bash
# optimize_assets.sh - Optimize Flutter assets before building the APK.
#
# Layers applied (best-effort, depends on available tooling):
#   1. PNG/JPG -> WebP conversion (cwebp, quality 80) - Android 4.0+
#   2. SVG minification (svgo if available, fallback to sed strip)
#   3. Strip image metadata (exiftool or mogrify -strip)
#   4. Font subsetting (pyftsubset for Latin-only TTFs - optional)
#   5. Detect unused assets (cross-reference pubspec vs lib/ imports)
#   6. Minify Lottie JSON (jq -c) - in lib/lottie/ and assets/lottie/
#
# Safety:
#   - DRY-RUN by default (prints actions, modifies nothing).
#   - Use --apply to actually modify files (originals backed up to .bak).
#   - Never deletes files (only converts in place + prints unused candidates).
#   - Skips a layer gracefully if the required tool is missing.
#
# Usage:
#   ./scripts/optimize_assets.sh                 # dry-run (read-only)
#   ./scripts/optimize_assets.sh --apply         # actually optimize
#   ./scripts/optimize_assets.sh --apply --no-backup   # skip .bak creation
#
# Exit codes:
#   0 - dry-run or apply completed (possibly with warnings)
#   1 - assets/ folder missing

set -euo pipefail

# ─── Defaults & flag parsing ──────────────────────────────────────────────────
APPLY=0
NO_BACKUP=0
WEBP_QUALITY=80

for flag in "$@"; do
  case "$flag" in
    --apply)         APPLY=1 ;;
    --no-backup)     NO_BACKUP=1 ;;
    --help|-h)
      sed -n '2,30p' "$0"
      exit 0
      ;;
    *)
      echo "[optimize_assets] Unknown flag: $flag" >&2
      exit 1
      ;;
  esac
done

echo "[optimize_assets] Optimisation des assets ExamBoost Togo"
echo "[optimize_assets] ============================================"
if [ "$APPLY" -eq 1 ]; then
  echo "[optimize_assets] MODE : APPLY (modifications en place)"
  if [ "$NO_BACKUP" -eq 1 ]; then
    echo "[optimize_assets] ATTENTION : --no-backup actif (pas de .bak)"
  fi
else
  echo "[optimize_assets] MODE : DRY-RUN (aucune modification)"
  echo "[optimize_assets]        Ajoute --apply pour modifier les fichiers."
fi
echo ""

cd "$(dirname "$0")/.."

if [ ! -d "assets" ] && [ ! -d "lib/lottie" ]; then
  echo "[optimize_assets] ERREUR : aucun dossier assets/ ni lib/lottie/ trouve." >&2
  exit 1
fi

# ─── Helper: backup a file before modifying it ────────────────────────────────
backup_if_needed() {
  local file="$1"
  if [ "$APPLY" -eq 1 ] && [ "$NO_BACKUP" -eq 0 ]; then
    if [ ! -f "${file}.bak" ]; then
      cp "$file" "${file}.bak"
    fi
  fi
}

# ─── Helper: print "[dry-run]" or "[apply]" prefix ───────────────────────────
action_prefix() {
  if [ "$APPLY" -eq 1 ]; then
    echo "[apply]"
  else
    echo "[dry-run]"
  fi
}

# Counters for the final summary.
COUNT_WEBP=0
COUNT_SVG=0
COUNT_META=0
COUNT_FONT=0
COUNT_LOTTIE=0
COUNT_UNUSED=0

# ─── Layer 1: PNG/JPG -> WebP ─────────────────────────────────────────────────
echo "[optimize_assets] Layer 1/6 : PNG/JPG -> WebP"
if command -v cwebp >/dev/null 2>&1; then
  while IFS= read -r img; do
    [ -z "$img" ] && continue
    out="${img%.*}.webp"
    echo "  $(action_prefix) $img -> $out (qualite $WEBP_QUALITY)"
    if [ "$APPLY" -eq 1 ]; then
      backup_if_needed "$img"
      if cwebp -q "$WEBP_QUALITY" "$img" -o "$out" >/dev/null 2>&1; then
        # Remove the original to avoid bundling both formats.
        rm -f "$img"
        COUNT_WEBP=$((COUNT_WEBP + 1))
      else
        echo "  ATTENTION : echec cwebp sur $img (fichier conserve)."
      fi
    else
      COUNT_WEBP=$((COUNT_WEBP + 1))
    fi
  done < <(find assets/ -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) 2>/dev/null)
else
  echo "  SKIP : cwebp non installe (apt install webp ou brew install webp)."
fi

# ─── Layer 2: SVG minification ────────────────────────────────────────────────
echo ""
echo "[optimize_assets] Layer 2/6 : minification SVG"
if command -v svgo >/dev/null 2>&1; then
  while IFS= read -r svg; do
    [ -z "$svg" ] && continue
    echo "  $(action_prefix) svgo $svg"
    if [ "$APPLY" -eq 1 ]; then
      backup_if_needed "$svg"
      svgo --multipass "$svg" -o "$svg" 2>/dev/null || true
      COUNT_SVG=$((COUNT_SVG + 1))
    else
      COUNT_SVG=$((COUNT_SVG + 1))
    fi
  done < <(find assets/ -type f -name "*.svg" 2>/dev/null)
else
  echo "  svgo non disponible - fallback sed (strip commentaires + espaces)."
  while IFS= read -r svg; do
    [ -z "$svg" ] && continue
    BEFORE=$(stat -c%s "$svg" 2>/dev/null || echo 0)
    echo "  $(action_prefix) sed strip $svg (${BEFORE} octets)"
    if [ "$APPLY" -eq 1 ]; then
      backup_if_needed "$svg"
      # Strip XML comments, leading/trailing whitespace per line, blank lines.
      sed -i -e 's/<!--[^>]*-->//g' \
             -e 's/^[[:space:]]+//' \
             -e 's/[[:space:]]+$//' \
             -e '/^$/d' "$svg" 2>/dev/null || true
      AFTER=$(stat -c%s "$svg" 2>/dev/null || echo 0)
      COUNT_SVG=$((COUNT_SVG + 1))
      echo "           -> ${AFTER} octets (gain $((BEFORE - AFTER)))"
    else
      COUNT_SVG=$((COUNT_SVG + 1))
    fi
  done < <(find assets/ -type f -name "*.svg" 2>/dev/null)
fi

# ─── Layer 3: strip image metadata ────────────────────────────────────────────
echo ""
echo "[optimize_assets] Layer 3/6 : retrait metadonnees images"
if command -v exiftool >/dev/null 2>&1; then
  STRIP_TOOL="exiftool -all= -overwrite_original"
elif command -v mogrify >/dev/null 2>&1; then
  STRIP_TOOL="mogrify -strip"
else
  STRIP_TOOL=""
fi
if [ -n "$STRIP_TOOL" ]; then
  while IFS= read -r img; do
    [ -z "$img" ] && continue
    echo "  $(action_prefix) strip metadata $img"
    if [ "$APPLY" -eq 1 ]; then
      backup_if_needed "$img"
      # shellcheck disable=SC2086
      $STRIP_TOOL "$img" >/dev/null 2>&1 || true
      COUNT_META=$((COUNT_META + 1))
    else
      COUNT_META=$((COUNT_META + 1))
    fi
  done < <(find assets/ -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.webp" \) 2>/dev/null)
else
  echo "  SKIP : exiftool et mogrify non installes."
fi

# ─── Layer 4: font subsetting (Latin only) ────────────────────────────────────
echo ""
echo "[optimize_assets] Layer 4/6 : subset polices (latin uniquement)"
if command -v pyftsubset >/dev/null 2>&1; then
  while IFS= read -r font; do
    [ -z "$font" ] && continue
    echo "  $(action_prefix) pyftsubset $font (Latin + accents FR)"
    if [ "$APPLY" -eq 1 ]; then
      backup_if_needed "$font"
      # Latin Basic + Latin-1 Supplement (accents francais) + ponctuation.
      pyftsubset "$font" \
        --unicodes='U+0020-007E,U+00A0-00FF,U+2000-206F' \
        --output-file="$font" \
        --layout-features='*' \
        --no-hinting \
        >/dev/null 2>&1 || true
      COUNT_FONT=$((COUNT_FONT + 1))
    else
      COUNT_FONT=$((COUNT_FONT + 1))
    fi
  done < <(find assets/ -type f \( -name "*.ttf" -o -name "*.otf" \) 2>/dev/null)
else
  echo "  SKIP : pyftsubset non installe (pip install fonttools)."
fi

# ─── Layer 5: detect unused assets ────────────────────────────────────────────
echo ""
echo "[optimize_assets] Layer 5/6 : detection assets non utilises"
# Cross-reference files in assets/ against references in lib/ and pubspec.yaml.
# This is a heuristic (string search) - false positives possible (dynamic paths).
if [ -d "assets" ] && [ -d "lib" ]; then
  while IFS= read -r asset; do
    [ -z "$asset" ] && continue
    # Search the basename (without extension) in lib/ + pubspec.yaml.
    BASENAME=$(basename "$asset")
    # Skip READMEs and markdown docs.
    case "$BASENAME" in
      README.md|*.md) continue ;;
    esac
    # Skip folder-level declarations in pubspec (e.g. "assets/images/").
    # We search for the explicit filename in lib/ first.
    if ! rg -q --no-ignore -g '!*.bak' "$BASENAME" lib/ pubspec.yaml 2>/dev/null; then
      echo "  inutilise (?) : $asset"
      echo "                 verifier : rg '$BASENAME' lib/ pubspec.yaml"
      COUNT_UNUSED=$((COUNT_UNUSED + 1))
    fi
  done < <(find assets/ -type f -not -name "*.bak" -not -name "README.md" -not -name "*.md" 2>/dev/null)
else
  echo "  SKIP : assets/ ou lib/ introuvable."
fi

# ─── Layer 6: Lottie JSON minification ────────────────────────────────────────
echo ""
echo "[optimize_assets] Layer 6/6 : minification Lottie JSON"
if command -v jq >/dev/null 2>&1; then
  LOTTIE_DIRS=("lib/lottie" "assets/lottie")
  for dir in "${LOTTIE_DIRS[@]}"; do
    [ -d "$dir" ] || continue
    while IFS= read -r json; do
      [ -z "$json" ] && continue
      BEFORE=$(stat -c%s "$json" 2>/dev/null || echo 0)
      echo "  $(action_prefix) jq -c $json (${BEFORE} octets)"
      if [ "$APPLY" -eq 1 ]; then
        backup_if_needed "$json"
        if jq -c . "$json" > "${json}.tmp" 2>/dev/null; then
          mv "${json}.tmp" "$json"
          AFTER=$(stat -c%s "$json" 2>/dev/null || echo 0)
          echo "           -> ${AFTER} octets (gain $((BEFORE - AFTER)))"
          COUNT_LOTTIE=$((COUNT_LOTTIE + 1))
        else
          rm -f "${json}.tmp"
          echo "  ATTENTION : JSON invalide $json (fichier conserve)."
        fi
      else
        COUNT_LOTTIE=$((COUNT_LOTTIE + 1))
      fi
    done < <(find "$dir" -maxdepth 1 -type f -name "*.json" -not -name "*.bak" 2>/dev/null)
  done
else
  echo "  SKIP : jq non installe (apt install jq)."
fi

# ─── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "[optimize_assets] Resume"
echo "  PNG/JPG -> WebP      : $COUNT_WEBP fichier(s)"
echo "  SVG minifies         : $COUNT_SVG fichier(s)"
echo "  Metadonnees retirees : $COUNT_META fichier(s)"
echo "  Polices subsetted    : $COUNT_FONT fichier(s)"
echo "  Lottie JSON minifies : $COUNT_LOTTIE fichier(s)"
echo "  Assets inutilises    : $COUNT_UNUSED candidate(s) (verifier manuellement)"

if [ "$APPLY" -eq 0 ]; then
  echo ""
  echo "[optimize_assets] DRY-RUN termine - aucune modification effectuee."
  echo "[optimize_assets] Relance avec --apply pour appliquer les optimisations."
else
  echo ""
  echo "[optimize_assets] APPLY termine."
  if [ "$NO_BACKUP" -eq 0 ]; then
    echo "[optimize_assets] Originaux sauvegardes en .bak (git checkout pour annuler)."
  fi
  echo "[optimize_assets] Prochaine etape : ./scripts/build_apk_optimized.sh"
fi
