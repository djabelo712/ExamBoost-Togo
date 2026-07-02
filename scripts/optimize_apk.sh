#!/usr/bin/env bash
# optimize_apk.sh - Audit and suggest size optimizations for the APK.
#
# Usage:
#   ./scripts/optimize_apk.sh
#
# This script does NOT modify any file - it only reports:
#   - Heaviest assets (top 10)
#   - Bundled fonts
#   - Current APK size (debug + release if present)
#   - Concrete optimization suggestions
#
# Apply the suggestions manually (compress PNG→WebP, remove unused
# assets, enable R8/ProGuard) then re-run build_apk_release.sh and
# check_apk_size.sh to verify the improvement.

set -euo pipefail

echo "⚡ Optimisation taille APK ExamBoost Togo"
echo "========================================="

cd "$(dirname "$0")/.."

# ─── 1. Heaviest assets (top 10) ───────────────────────────────────
echo ""
echo "📦 Assets (top 10 plus lourds) :"
if [ -d "assets" ]; then
  find assets/ -type f -exec du -h {} + 2>/dev/null \
    | sort -rh | head -10 | sed 's/^/  /'
else
  echo "  (dossier assets/ introuvable)"
fi

# ─── 2. Bundled fonts ──────────────────────────────────────────────
echo ""
echo "🔤 Polices (.ttf / .otf) :"
FONTS_FOUND=0
while IFS= read -r font; do
  if [ -n "$font" ]; then
    FONTS_FOUND=1
    SIZE=$(du -h "$font" | cut -f1)
    echo "  $font : $SIZE"
  fi
done < <(find . -type f \( -name "*.ttf" -o -name "*.otf" \) \
           -not -path "./build/*" -not -path "./.dart_tool/*" 2>/dev/null \
           | head -20)
if [ "$FONTS_FOUND" -eq 0 ]; then
  echo "  (aucune police trouvée)"
fi

# ─── 3. Image formats (PNG vs WebP) ────────────────────────────────
echo ""
echo "🖼️  Images — répartition par format :"
if [ -d "assets" ]; then
  PNG_COUNT=$(find assets/ -type f -name "*.png" 2>/dev/null | wc -l)
  WEBP_COUNT=$(find assets/ -type f -name "*.webp" 2>/dev/null | wc -l)
  JPG_COUNT=$(find assets/ -type f \( -name "*.jpg" -o -name "*.jpeg" \) 2>/dev/null | wc -l)
  SVG_COUNT=$(find assets/ -type f -name "*.svg" 2>/dev/null | wc -l)
  echo "  PNG  : $PNG_COUNT"
  echo "  WebP : $WEBP_COUNT"
  echo "  JPG  : $JPG_COUNT"
  echo "  SVG  : $SVG_COUNT"
else
  echo "  (dossier assets/ introuvable)"
fi

# ─── 4. Current APK sizes ──────────────────────────────────────────
echo ""
echo "📊 Taille actuelle des APK :"
DEBUG_APK="build/app/outputs/flutter-apk/app-debug.apk"
if [ -f "$DEBUG_APK" ]; then
  echo "  Debug   : $(du -h "$DEBUG_APK" | cut -f1)"
else
  echo "  Debug   : (non trouvé — lance ./scripts/build_apk_debug.sh)"
fi

for apk in build/app/outputs/flutter-apk/app-*-release.apk; do
  [ -f "$apk" ] || continue
  echo "  Release : $(du -h "$apk" | cut -f1)  ($apk)"
done

# ─── 5. Suggestions ────────────────────────────────────────────────
echo ""
echo "💡 Suggestions d'optimisation :"
echo "  1. Utiliser --split-per-abi (déjà fait par build_apk_release.sh)"
echo "     → 3 APK plus légers au lieu d'un seul fat APK."
echo "  2. Compresser les images PNG en WebP :"
echo "       cwebp -q 80 assets/images/foo.png -o assets/images/foo.webp"
echo "     puis mettre à jour pubspec.yaml et les références dans le code."
echo "  3. Retirer les assets non utilisés (vérifier avec :"
echo "       dart run dependency_validator)"
echo "  4. Minifier le code Dart (déjà fait en release par défaut)."
echo "  5. Activer R8/ProGuard dans android/app/build.gradle :"
echo "       android { buildTypes { release { minifyEnabled true"
echo "         shrinkResources true proguardFiles 'proguard-rules.pro' } } }"
echo "  6. Tree-shake Material icons (déjà fait par défaut en release)."
echo "  7. Éviter les polices lourdes : préférer Material Symbols au lieu"
echo "     d'un set iconique complet (~1 Mo)."
echo "  8. Pour les Lottie, compresser les JSON (jq -c) ou utiliser"
echo "     des animations plus simples."
echo ""
echo "Après optimisation, relancer :"
echo "  ./scripts/build_apk_release.sh && ./scripts/check_apk_size.sh \\"
echo "    build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"
