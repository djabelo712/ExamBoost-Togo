#!/usr/bin/env bash
# build_apk_release.sh - Build release APKs for ExamBoost Togo.
#
# Usage:
#   ./scripts/build_apk_release.sh
#
# Output:
#   build/app/outputs/flutter-apk/app-arm64-v8a-release.apk     (modern phones)
#   build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk   (older phones)
#   build/app/outputs/flutter-apk/app-x86_64-release.apk        (emulators)
#   examboost-v<version>-<abi>.apk                              (timestamped copies)
#
# The release APKs are split per ABI to keep each one under 25 MB
# (constraint for distribution on low-end devices in Togo). They are
# signed with the debug keystore by default - configure a production
# keystore in android/key.properties for Play Store distribution.

set -euo pipefail

echo "🚀 Build APK Release ExamBoost Togo"
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

# ─── Build release APK split per ABI (3 lighter APKs) ──────────────
echo ""
echo "🔨 Build APK release (split per ABI)..."
flutter build apk --release --split-per-abi

# ─── Size report ───────────────────────────────────────────────────
echo ""
echo "📊 Tailles APK release :"
for apk in build/app/outputs/flutter-apk/app-*-release.apk; do
  [ -f "$apk" ] || continue
  SIZE=$(du -h "$apk" | cut -f1)
  echo "  $apk : $SIZE"
done

# ─── Verify < 25 MB (Togo constraint) ──────────────────────────────
echo ""
echo "🔍 Vérification taille < 25 Mo (contrainte Togo)..."
ALL_OK=1
for apk in build/app/outputs/flutter-apk/app-*-release.apk; do
  [ -f "$apk" ] || continue
  SIZE_BYTES=$(stat -c%s "$apk")
  SIZE_MB=$((SIZE_BYTES / 1024 / 1024))
  if [ "$SIZE_MB" -lt 25 ]; then
    echo "  ✅ $apk : ${SIZE_MB} Mo (OK)"
  else
    echo "  ⚠️  $apk : ${SIZE_MB} Mo (> 25 Mo — optimisation nécessaire)"
    ALL_OK=0
  fi
done

if [ "$ALL_OK" -ne 1 ]; then
  echo ""
  echo "⚠️  Au moins un APK dépasse 25 Mo. Lance ./scripts/optimize_apk.sh"
  echo "   pour identifier les assets lourds à compresser/supprimer."
fi

# ─── Copy with version tag ─────────────────────────────────────────
VERSION=$(grep "^version:" pubspec.yaml | head -1 | sed -E 's/^version: ([^++]+).*/\1/' | tr -d '"' | tr -d "'")
if [ -z "$VERSION" ]; then
  echo ""
  echo "⚠️  Version non détectée dans pubspec.yaml — copie sans tag de version."
  VERSION="unknown"
fi

echo ""
echo "📋 Copie des APK avec tag de version (v${VERSION})..."
for apk in build/app/outputs/flutter-apk/app-*-release.apk; do
  [ -f "$apk" ] || continue
  ABI=$(echo "$apk" | grep -oE 'arm64-v8a|armeabi-v7a|x86_64')
  if [ -n "$ABI" ]; then
    COPY_NAME="examboost-v${VERSION}-${ABI}.apk"
    cp "$apk" "$COPY_NAME"
    echo "  → ./${COPY_NAME}"
  fi
done

echo ""
echo "✅ APK release générés"
