#!/usr/bin/env bash
# check_apk_size.sh - Verify an APK stays under the 25 MB Togo constraint.
#
# Usage:
#   ./scripts/check_apk_size.sh                                    # default: app-release.apk
#   ./scripts/check_apk_size.sh build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
#   ./scripts/check_apk_size.sh path/to/any.apk 15                 # custom limit (MB)
#
# Exit codes:
#   0 — APK is under the limit (default 25 MB)
#   1 — APK exceeds the limit (or file not found)
#
# The 25 MB constraint matches the distribution plan for low-end Android
# devices on cellular data in Togo (see docs/Pitch_Deck_10_slides.md).

set -euo pipefail

APK="${1:-build/app/outputs/flutter-apk/app-release.apk}"
LIMIT_MB="${2:-25}"

echo "📊 Vérification taille APK"
echo "========================================="
echo "APK      : $APK"
echo "Limite   : ${LIMIT_MB} Mo"

if [ ! -f "$APK" ]; then
  echo ""
  echo "❌ APK non trouvé : $APK"
  echo ""
  echo "APK disponibles dans build/app/outputs/flutter-apk/ :"
  if [ -d "build/app/outputs/flutter-apk" ]; then
    ls -1 build/app/outputs/flutter-apk/ 2>/dev/null | sed 's/^/  - /'
  else
    echo "  (dossier build/ introuvable — lance un script build_apk_*.sh d'abord)"
  fi
  exit 1
fi

SIZE_BYTES=$(stat -c%s "$APK")
# Use awk for floating-point MB (bash arithmetic is integer-only)
SIZE_MB=$(awk -v b="$SIZE_BYTES" 'BEGIN { printf "%.2f", b / 1024 / 1024 }')

echo "Taille  : ${SIZE_MB} Mo"
echo ""

# Compare with limit using awk (handles floats)
WITHIN_LIMIT=$(awk -v s="$SIZE_MB" -v l="$LIMIT_MB" 'BEGIN { print (s < l) ? "1" : "0" }')

if [ "$WITHIN_LIMIT" = "1" ]; then
  echo "✅ OK — APK < ${LIMIT_MB} Mo (contrainte Togo respectée)"
  exit 0
else
  echo "⚠️  ATTENTION — APK > ${LIMIT_MB} Mo"
  echo ""
  echo "Optimisations recommandées :"
  echo "  - flutter build apk --release --split-per-abi  (3 APK plus légers)"
  echo "  - Compresser les assets (PNG → WebP, qualité 80)"
  echo "  - Retirer les assets non utilisés (dart run dependency_validator)"
  echo "  - Activer R8/ProGuard (minifyEnabled + shrinkResources)"
  echo "  - Lancer ./scripts/optimize_apk.sh pour un audit complet"
  exit 1
fi
