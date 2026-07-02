#!/usr/bin/env bash
# build_web.sh - Build the Flutter web bundle for ExamBoost Togo.
#
# Usage:
#   ./scripts/build_web.sh
#
# Output:
#   build/web/   (static files ready to serve)
#
# To serve locally for testing:
#   cd build/web && python3 -m http.server 8080
#   Then open http://localhost:8080

set -euo pipefail

echo "🌐 Build Web ExamBoost Togo"
echo "========================================="

cd "$(dirname "$0")/.."

# ─── Check Flutter SDK ─────────────────────────────────────────────
if ! command -v flutter >/dev/null 2>&1; then
  echo "❌ Flutter non installé ou absent du PATH."
  exit 1
fi

flutter --version

# ─── Clean + deps + codegen ────────────────────────────────────────
echo ""
echo "🧹 Clean..."
flutter clean

echo ""
echo "📦 Pub get..."
flutter pub get

echo ""
echo "🔧 Build runner..."
dart run build_runner build --delete-conflicting-outputs

# ─── Build web with HTML renderer (lighter, no CanvasKit overhead) ─
# The HTML renderer is preferred for low-end devices and limited data
# plans common in Togo. Switch to '--web-renderer canvaskit' if you
# need pixel-perfect rendering at the cost of a larger initial bundle.
echo ""
echo "🔨 Build web (renderer html)..."
flutter build web --release --web-renderer html

# ─── Verify + serve instructions ───────────────────────────────────
WEB_DIR="build/web"
if [ -d "$WEB_DIR" ]; then
  SIZE=$(du -sh "$WEB_DIR" | cut -f1)
  echo ""
  echo "✅ Build web généré : $WEB_DIR ($SIZE)"

  echo ""
  echo "🌐 Pour tester en local :"
  echo "   cd build/web && python3 -m http.server 8080"
  echo "   Ouvrir http://localhost:8080"
  echo ""
  echo "📦 Pour déployer :"
  echo "   - GitHub Pages : voir .github/workflows/build_web.yml"
  echo "   - Vercel/Netlify : connecter le repo, build command 'flutter build web --release',"
  echo "     publish directory 'build/web'"
else
  echo "❌ Build web échoué — dossier $WEB_DIR introuvable"
  exit 1
fi
