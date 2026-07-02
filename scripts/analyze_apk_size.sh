#!/usr/bin/env bash
# analyze_apk_size.sh - Detailed APK composition analysis for ExamBoost Togo.
#
# Decompresses the APK listing (unzip -l, no extraction to disk) and
# aggregates the contents by category to pinpoint size hotspots:
#   - lib/                       native .so libraries (Flutter engine, libapp.so)
#   - assets/flutter_assets/     bundled Flutter assets (images, JSON, fonts, Lottie)
#   - classes*.dex               compiled Java/Kotlin bytecode
#   - res/                       compiled Android resources (layouts, drawables)
#   - resources.arsc             resource table
#   - META-INF/                  signatures + manifest
#   - AndroidManifest.xml        manifest
#   - Other
#
# Prints:
#   1. Total APK size (bytes / MiB)
#   2. Size by category (bytes + percentage of total)
#   3. Top 10 heaviest files
#   4. Concrete optimization suggestions based on the heaviest category
#
# Also writes a Markdown report to scripts/apk_size_report.md (overwrites).
#
# Usage:
#   ./scripts/analyze_apk_size.sh                                 # default: arm64 APK
#   ./scripts/analyze_apk_size.sh path/to/app.apk
#   ./scripts/analyze_apk_size.sh path/to/app.apk 20              # custom limit (MB)
#
# Exit codes:
#   0 - analysis completed
#   1 - APK not found or unzip not available

set -euo pipefail

# ─── Defaults & args ──────────────────────────────────────────────────────────
APK="${1:-build/app/outputs/flutter-apk/app-arm64-v8a-release.apk}"
SIZE_LIMIT_MB="${2:-25}"
REPORT="scripts/apk_size_report.md"

echo "[analyze_apk_size] Analyse composition APK"
echo "[analyze_apk_size] ============================================"
echo "[analyze_apk_size] APK      : $APK"
echo "[analyze_apk_size] Limite   : ${SIZE_LIMIT_MB} Mo"

# ─── Pre-flight checks ────────────────────────────────────────────────────────
if [ ! -f "$APK" ]; then
  echo "[analyze_apk_size] ERREUR : APK introuvable : $APK" >&2
  echo "[analyze_apk_size]         APK disponibles dans build/app/outputs/flutter-apk/ :"
  if [ -d "build/app/outputs/flutter-apk" ]; then
    ls -1 build/app/outputs/flutter-apk/ 2>/dev/null | sed 's/^/           - /' >&2
  else
    echo "           (dossier build/ introuvable - lance un build d'abord)" >&2
  fi
  exit 1
fi

if ! command -v unzip >/dev/null 2>&1; then
  echo "[analyze_apk_size] ERREUR : unzip requis (apt install unzip)." >&2
  exit 1
fi

if ! command -v awk >/dev/null 2>&1; then
  echo "[analyze_apk_size] ERREUR : awk requis (normalement preinstalle)." >&2
  exit 1
fi

# Absolute path of the APK (for the report).
APK_ABS=$(readlink -f "$APK" 2>/dev/null || echo "$APK")
cd "$(dirname "$0")/.."

# ─── Parse the unzip -l listing ONCE (used by sections 1, 2, 3) ──────────────
# unzip -l output columns: Length  Date  Time  Name
# We extract length + name and aggregate by category prefix.
RAW_LIST=$(unzip -l "$APK" 2>/dev/null | awk '
  NF >= 4 && $1 ~ /^[0-9]+$/ {
    size = $1
    # Reconstruct name in case it contains spaces (column 4+).
    name = $4
    for (i = 5; i <= NF; i++) name = name " " $i
    print size "\t" name
  }
')

# ─── 1. Total APK size ────────────────────────────────────────────────────────
# Two distinct totals:
#   - COMPRESSED size = the actual APK file size (what the user downloads).
#     This is the number that must stay < 25 Mo for the Togo constraint.
#   - UNCOMPRESSED size = sum of file sizes inside the APK (what the APK
#     occupies on the device after install). Always >= compressed size.
TOTAL_BYTES=$(stat -c%s "$APK")
TOTAL_MB=$(awk -v b="$TOTAL_BYTES" 'BEGIN { printf "%.2f", b / 1024 / 1024 }')

# Sum the uncompressed sizes parsed from unzip -l.
UNCOMPRESSED_BYTES=$(echo "$RAW_LIST" \
  | awk -F'\t' '{ sum += $1 } END { print sum + 0 }')
UNCOMPRESSED_MB=$(awk -v b="$UNCOMPRESSED_BYTES" 'BEGIN { printf "%.2f", b / 1024 / 1024 }')

echo ""
echo "[analyze_apk_size] 1. Taille totale"
echo "   APK (compresse, a telecharger) : ${TOTAL_BYTES} octets (${TOTAL_MB} Mo)"
echo "   APK (decompresse, sur device)  : ${UNCOMPRESSED_BYTES} octets (${UNCOMPRESSED_MB} Mo)"

# ─── 2. Size by category ──────────────────────────────────────────────────────
# Aggregate.
LIB_BYTES=0
ASSETS_BYTES=0
DEX_BYTES=0
RES_BYTES=0
ARSC_BYTES=0
META_BYTES=0
MANIFEST_BYTES=0
OTHER_BYTES=0

while IFS=$'\t' read -r size name; do
  [ -z "$size" ] && continue
  case "$name" in
    lib/*)                          LIB_BYTES=$((LIB_BYTES + size)) ;;
    assets/flutter_assets/*)        ASSETS_BYTES=$((ASSETS_BYTES + size)) ;;
    classes*.dex)                   DEX_BYTES=$((DEX_BYTES + size)) ;;
    res/*)                          RES_BYTES=$((RES_BYTES + size)) ;;
    resources.arsc)                 ARSC_BYTES=$((ARSC_BYTES + size)) ;;
    META-INF/*)                     META_BYTES=$((META_BYTES + size)) ;;
    AndroidManifest.xml)            MANIFEST_BYTES=$((MANIFEST_BYTES + size)) ;;
    *)                              OTHER_BYTES=$((OTHER_BYTES + size)) ;;
  esac
done <<< "$RAW_LIST"

# Format helpers (MiB with 2 decimals + percentage of UNCOMPRESSED total,
# since the category sizes are themselves uncompressed sizes from unzip -l).
fmt_mib() {
  awk -v b="$1" -v t="$UNCOMPRESSED_BYTES" 'BEGIN {
    mb = b / 1024 / 1024
    pct = (t > 0) ? (b / t * 100) : 0
    printf "%8.2f Mo  (%5.1f%%)", mb, pct
  }'
}

echo ""
echo "[analyze_apk_size] 2. Repartition par categorie (taille decompressee)"
printf "   %-32s %s\n" "Categorie" "Taille"
printf "   %-32s %s\n" "--------------------------------" "-------------------------"
printf "   %-32s %s\n" "lib/  (natif Flutter + Dart)"    "$(fmt_mib "$LIB_BYTES")"
printf "   %-32s %s\n" "assets/flutter_assets/"          "$(fmt_mib "$ASSETS_BYTES")"
printf "   %-32s %s\n" "classes*.dex (Java/Kotlin)"      "$(fmt_mib "$DEX_BYTES")"
printf "   %-32s %s\n" "res/  (resources Android)"       "$(fmt_mib "$RES_BYTES")"
printf "   %-32s %s\n" "resources.arsc"                  "$(fmt_mib "$ARSC_BYTES")"
printf "   %-32s %s\n" "META-INF/ (signatures)"          "$(fmt_mib "$META_BYTES")"
printf "   %-32s %s\n" "AndroidManifest.xml"             "$(fmt_mib "$MANIFEST_BYTES")"
printf "   %-32s %s\n" "Autre"                           "$(fmt_mib "$OTHER_BYTES")"

# ─── 3. Top 10 heaviest files ─────────────────────────────────────────────────
echo ""
echo "[analyze_apk_size] 3. Top 10 fichiers les plus lourds"
echo "   Taille       Fichier"
echo "   -----------  ----------------------------------------------------------"
TOP10=$(echo "$RAW_LIST" | sort -t$'\t' -k1,1 -n -r | head -10)
i=1
while IFS=$'\t' read -r size name; do
  [ -z "$size" ] && continue
  SIZE_FMT=$(awk -v b="$size" 'BEGIN { printf "%7.2f Mo", b / 1024 / 1024 }')
  printf "   %2d. %s  %s\n" "$i" "$SIZE_FMT" "$name"
  i=$((i + 1))
done <<< "$TOP10"

# ─── 4. Optimization suggestions based on the heaviest category ───────────────
echo ""
echo "[analyze_apk_size] 4. Suggestions d'optimisation"

# Find the heaviest category (excluding OTHER which is unactionable noise).
MAX_CAT="lib/"
MAX_BYTES=$LIB_BYTES
if [ "$ASSETS_BYTES" -gt "$MAX_BYTES" ]; then MAX_CAT="assets/"; MAX_BYTES=$ASSETS_BYTES; fi
if [ "$DEX_BYTES"   -gt "$MAX_BYTES" ]; then MAX_CAT="dex";    MAX_BYTES=$DEX_BYTES;   fi
if [ "$RES_BYTES"   -gt "$MAX_BYTES" ]; then MAX_CAT="res/";   MAX_BYTES=$RES_BYTES;   fi

case "$MAX_CAT" in
  lib/)
    echo "   - lib/ est la categorie dominante (${MAX_BYTES} octets)."
    echo "     * Verifier que le build utilise --split-per-abi (1 seule ABI par APK)."
    echo "     * libflutter.so (~6-8 Mo) est le moteur Flutter : non reductible."
    echo "     * libapp.so contient le code Dart compile en AOT :"
    echo "       - retirer les packages inutilises : dart run dependency_validator"
    echo "       - activer --shrink et --obfuscate dans flutter build apk."
    echo "     * Si > 20 Mo : considerer les Deferred Components."
    ;;
  assets/)
    echo "   - assets/ est la categorie dominante (${MAX_BYTES} octets)."
    echo "     * Compresser les PNG en WebP : cwebp -q 80 input.png -o output.webp"
    echo "     * Minifier les SVG : svgo input.svg -o output.svg"
    echo "     * Compresser les Lottie JSON : jq -c . input.json > output.json"
    echo "     * Retirer les assets non utilises : ./scripts/optimize_assets.sh --apply"
    echo "     * Subsetter les polices (latin-only) : pyftsubset font.ttf --unicodes='U+0020-007E'"
    ;;
  dex)
    echo "   - classes.dex est la categorie dominante (${MAX_BYTES} octets)."
    echo "     * Activer R8/ProGuard dans android/app/build.gradle :"
    echo "         buildTypes { release { minifyEnabled true; shrinkResources true } }"
    echo "     * Verifier les deps Kotlin/Java natives (proguard-rules.pro)."
    ;;
  res/)
    echo "   - res/ est la categorie dominante (${MAX_BYTES} octets)."
    echo "     * Activer shrinkResources true dans android/app/build.gradle."
    echo "     * Retirer les ressources Android non utilisees."
    ;;
esac

# Universal checks.
if [ "$ASSETS_BYTES" -gt 1048576 ]; then
  ASSETS_MB=$(awk -v b="$ASSETS_BYTES" 'BEGIN { printf "%.1f", b / 1024 / 1024 }')
  echo "   - assets/flutter_assets/ pese ${ASSETS_MB} Mo : lancer ./scripts/optimize_assets.sh --apply"
fi
if [ "$DEX_BYTES" -gt 5242880 ]; then
  echo "   - classes*.dex > 5 Mo : verifier les plugins natifs lourds (ex: video_player)."
fi
WITHIN=$(awk -v s="$TOTAL_MB" -v l="$SIZE_LIMIT_MB" 'BEGIN { print (s < l) ? "1" : "0" }')
if [ "$WITHIN" = "1" ]; then
  echo "   - OK : APK < ${SIZE_LIMIT_MB} Mo (contrainte Togo respectee)."
else
  echo "   - ATTENTION : APK > ${SIZE_LIMIT_MB} Mo - contrainte Togo NON respectee."
  echo "     Lancer ./scripts/build_apk_optimized.sh pour un build ultra-optimise."
fi

# ─── 5. Write Markdown report ─────────────────────────────────────────────────
mkdir -p "$(dirname "$REPORT")"
{
  echo "# Rapport taille APK - ExamBoost Togo"
  echo ""
  echo "Genere le : $(date '+%Y-%m-%d a %H:%M:%S')"
  echo "APK analyse : \`$APK_ABS\`"
  echo ""
  echo "## Resume"
  echo ""
  echo "| Metrique | Valeur |"
  echo "|----------|--------|"
  echo "| Taille compresse (telechargement) | ${TOTAL_BYTES} octets (${TOTAL_MB} Mo) |"
  echo "| Taille decompresse (sur device)   | ${UNCOMPRESSED_BYTES} octets (${UNCOMPRESSED_MB} Mo) |"
  echo "| Limite cible (APK compresse)      | ${SIZE_LIMIT_MB} Mo |"
  if [ "$WITHIN" = "1" ]; then
    echo "| Statut                            | OK (sous la limite) |"
  else
    echo "| Statut                            | DEPASSE (optimisation requise) |"
  fi
  echo ""
  echo "## Repartition par categorie (taille decompressee)"
  echo ""
  echo "| Categorie | Octets | Mo | % du total decompresse |"
  echo "|-----------|--------|-----|------------------------|"
  awk -v lib="$LIB_BYTES"      -v t="$UNCOMPRESSED_BYTES" 'BEGIN { printf "| lib/ (natif) | %d | %.2f | %.1f%% |\n", lib, lib/1048576, (t>0)?lib/t*100:0 }'
  awk -v a="$ASSETS_BYTES"     -v t="$UNCOMPRESSED_BYTES" 'BEGIN { printf "| assets/flutter_assets/ | %d | %.2f | %.1f%% |\n", a, a/1048576, (t>0)?a/t*100:0 }'
  awk -v d="$DEX_BYTES"        -v t="$UNCOMPRESSED_BYTES" 'BEGIN { printf "| classes*.dex | %d | %.2f | %.1f%% |\n", d, d/1048576, (t>0)?d/t*100:0 }'
  awk -v r="$RES_BYTES"        -v t="$UNCOMPRESSED_BYTES" 'BEGIN { printf "| res/ | %d | %.2f | %.1f%% |\n", r, r/1048576, (t>0)?r/t*100:0 }'
  awk -v ar="$ARSC_BYTES"      -v t="$UNCOMPRESSED_BYTES" 'BEGIN { printf "| resources.arsc | %d | %.2f | %.1f%% |\n", ar, ar/1048576, (t>0)?ar/t*100:0 }'
  awk -v m="$META_BYTES"       -v t="$UNCOMPRESSED_BYTES" 'BEGIN { printf "| META-INF/ | %d | %.2f | %.1f%% |\n", m, m/1048576, (t>0)?m/t*100:0 }'
  awk -v man="$MANIFEST_BYTES" -v t="$UNCOMPRESSED_BYTES" 'BEGIN { printf "| AndroidManifest.xml | %d | %.2f | %.1f%% |\n", man, man/1048576, (t>0)?man/t*100:0 }'
  awk -v o="$OTHER_BYTES"      -v t="$UNCOMPRESSED_BYTES" 'BEGIN { printf "| Autre | %d | %.2f | %.1f%% |\n", o, o/1048576, (t>0)?o/t*100:0 }'
  echo ""
  echo "## Top 10 fichiers les plus lourds"
  echo ""
  echo "| # | Mo (decompresse) | Fichier |"
  echo "|---|------------------|---------|"
  i=1
  echo "$TOP10" | while IFS=$'\t' read -r size name; do
    [ -z "$size" ] && continue
    awk -v n="$i" -v b="$size" -v f="$name" 'BEGIN { printf "| %d | %.2f | %s |\n", n, b/1048576, f }'
    i=$((i + 1))
  done
  echo ""
  echo "## Suggestions"
  echo ""
  echo "Voir sortie console de \`./scripts/analyze_apk_size.sh\` pour les"
  echo "suggestions contextuelles (basees sur la categorie dominante)."
  echo ""
  echo "## Scripts associes"
  echo ""
  echo "- \`./scripts/build_apk_optimized.sh\` : build ultra-optimise (5 couches)."
  echo "- \`./scripts/optimize_assets.sh --apply\` : compression assets en place."
  echo "- \`./scripts/check_apk_size.sh <apk>\` : verification rapide < 25 Mo."
  echo "- \`./scripts/optimize_apk.sh\` : audit read-only (top 10 assets)."
  echo ""
} > "$REPORT"

echo ""
echo "[analyze_apk_size] Rapport Markdown ecrit : $REPORT"
echo "[analyze_apk_size] Analyse terminee."
