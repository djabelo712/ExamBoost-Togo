#!/usr/bin/env bash
# build_apk_debug.sh - Build a debug APK for ExamBoost Togo.
#
# Usage:
#   ./scripts/build_apk_debug.sh
#
# Output:
#   build/app/outputs/flutter-apk/app-debug.apk
#   examboost-debug-<timestamp>.apk   (timestamped copy at repo root)
#
# The debug APK is suitable for testing on a physical phone via
#   `adb install -r examboost-debug-*.apk`. It is NOT signed for
#   distribution - use build_apk_release.sh for that.

set -euo pipefail

echo "📱 Build APK Debug ExamBoost Togo"
echo "========================================="

cd "$(dirname "$0")/.."

# ─── Check Flutter SDK ─────────────────────────────────────────────
if ! command -v flutter >/dev/null 2>&1; then
  echo "❌ Flutter non installé ou absent du PATH."
  echo "   Installe Flutter depuis https://flutter.dev puis relance ce script."
  exit 1
fi

FLUTTER_VERSION=$(flutter --version | head -1)
echo "✅ $FLUTTER_VERSION"

# ─── Clean previous build artifacts ────────────────────────────────
echo ""
echo "🧹 Clean..."
flutter clean

# ─── Resolve dependencies ──────────────────────────────────────────
echo ""
echo "📦 Pub get..."
flutter pub get

# ─── Generate Hive adapters / freezed / json_serializable ──────────
echo ""
echo "🔧 Build runner (génération *.g.dart / *.freezed.dart)..."
dart run build_runner build --delete-conflicting-outputs

# ─── Build debug APK ───────────────────────────────────────────────
echo ""
echo "🔨 Build APK debug..."
flutter build apk --debug

# ─── Verify + timestamp copy ───────────────────────────────────────
APK_PATH="build/app/outputs/flutter-apk/app-debug.apk"
if [ -f "$APK_PATH" ]; then
  SIZE=$(du -h "$APK_PATH" | cut -f1)
  echo ""
  echo "✅ APK debug généré : $APK_PATH ($SIZE)"

  TIMESTAMP=$(date +%Y%m%d-%H%M%S)
  COPY_NAME="examboost-debug-${TIMESTAMP}.apk"
  cp "$APK_PATH" "$COPY_NAME"
  echo "📋 Copié dans ./${COPY_NAME}"
  echo ""
  echo "Pour installer sur un téléphone connecté via adb :"
  echo "   adb install -r $COPY_NAME"
else
  echo "❌ APK non généré (build a échoué)"
  exit 1
fi
