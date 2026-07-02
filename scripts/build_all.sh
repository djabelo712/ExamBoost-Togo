#!/usr/bin/env bash
# build_all.sh - Build everything: debug APK + release APKs + web bundle.
#
# Usage:
#   ./scripts/build_all.sh
#
# This is the convenience wrapper to run all 3 build scripts in
# sequence. Useful for release day or to verify that all targets
# still build before tagging a release.

set -euo pipefail

echo "🎯 Build complet ExamBoost Togo (APK debug + APK release + Web)"
echo "========================================="
echo ""

cd "$(dirname "$0")/.."

# ─── Verify scripts exist ──────────────────────────────────────────
for s in build_apk_debug.sh build_apk_release.sh build_web.sh; do
  if [ ! -f "scripts/$s" ]; then
    echo "❌ Script manquant : scripts/$s"
    exit 1
  fi
  if [ ! -x "scripts/$s" ]; then
    chmod +x "scripts/$s"
  fi
done

# ─── Debug APK ─────────────────────────────────────────────────────
echo "─── Étape 1/3 : APK debug ─────────────────────────────────"
./scripts/build_apk_debug.sh

echo ""
echo "─── Étape 2/3 : APK release ───────────────────────────────"
./scripts/build_apk_release.sh

echo ""
echo "─── Étape 3/3 : Web build ─────────────────────────────────"
./scripts/build_web.sh

# ─── Summary ───────────────────────────────────────────────────────
echo ""
echo "========================================="
echo "🎉 Tous les builds sont terminés !"
echo ""
echo "Sorties :"
echo "  • APK debug      : build/app/outputs/flutter-apk/app-debug.apk"
echo "  • APK release    : build/app/outputs/flutter-apk/app-*-release.apk"
echo "  • Web            : build/web/"
echo ""
echo "Vérifier la taille des APK release :"
echo "  ./scripts/check_apk_size.sh build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"
