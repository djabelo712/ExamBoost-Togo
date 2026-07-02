#!/usr/bin/env bash
# test_on_low_end.sh - Smoke-test the app on a low-end Android emulator.
#
# Usage:
#   ./scripts/test_on_low_end.sh
#
# The script simulates a Tecno Spark 4 (a common entry-level phone in
# Togo) by launching an AVD with constrained resources:
#   - Android 9 (API 28)
#   - 2 GB RAM
#   - armeabi-v7a ABI (matches the older split APK)
#   - 720x1560 screen
#
# It then installs the debug APK, launches the app, captures memory
# usage at T0 and after 60s, and kills the emulator.
#
# Prerequisites:
#   - Android SDK installed (emulator, adb, avdmanager in PATH)
#   - ANDROID_HOME or ANDROID_SDK_ROOT set
#   - System image 'system-images;android-28;default;armeabi-v7a' installed
#     (sdkmanager "system-images;android-28;default;armeabi-v7a")

set -euo pipefail

APP_PACKAGE="com.example.examboost_togo"
APP_ACTIVITY=".MainActivity"
AVD_NAME="examboost_low_end"
MONITOR_SECONDS="${MONITOR_SECONDS:-60}"

echo "📱 Test sur device bas de gamme (simulation Tecno Spark 4)"
echo "========================================="
echo "AVD          : $AVD_NAME"
echo "App package  : $APP_PACKAGE"
echo "Monitor (s)  : $MONITOR_SECONDS"
echo ""

cd "$(dirname "$0")/.."

# ─── Verify Android SDK tools ──────────────────────────────────────
for cmd in emulator adb avdmanager; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "❌ '$cmd' absent du PATH."
    echo "   Installe Android SDK + ajoute $ANDROID_HOME/emulator,"
    echo "   $ANDROID_HOME/platform-tools, $ANDROID_HOME/cmdline-tools/latest/bin au PATH."
    exit 1
  fi
done

# ─── Create AVD if missing ─────────────────────────────────────────
if ! emulator -list-avds 2>/dev/null | grep -q "^${AVD_NAME}$"; then
  echo "⚠️  AVD $AVD_NAME n'existe pas. Création..."
  echo "no" | avdmanager create avd \
    -n "$AVD_NAME" \
    -k "system-images;android-28;default;armeabi-v7a" \
    -d "Nexus 4" \
    --force
  echo "✅ AVD $AVD_NAME créé"
fi

# ─── Launch emulator headless ──────────────────────────────────────
echo ""
echo "🚀 Lancement de l'émulateur (headless, 2 Go RAM)..."
emulator -avd "$AVD_NAME" \
  -memory 2048 \
  -no-window \
  -no-audio \
  -no-boot-anim \
  -gpu swiftshader_indirect \
  >/dev/null 2>&1 &
EMU_PID=$!

# Make sure we kill the emulator on exit (even on error)
trap 'kill $EMU_PID 2>/dev/null || true' EXIT

# ─── Wait for boot ─────────────────────────────────────────────────
echo "⏳ Attente démarrage émulateur (peut prendre 60-120s)..."
adb wait-for-device
# Wait until boot completed
for _ in $(seq 1 120); do
  BOOT=$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r\n')
  if [ "$BOOT" = "1" ]; then
    break
  fi
  sleep 2
done

if [ "$BOOT" != "1" ]; then
  echo "❌ L'émulateur n'a pas fini de démarrer après 240s"
  exit 1
fi
echo "✅ Émulateur démarré"

# ─── Build + install debug APK ─────────────────────────────────────
echo ""
echo "🔨 Build APK debug..."
flutter build apk --debug >/dev/null 2>&1

APK="build/app/outputs/flutter-apk/app-debug.apk"
if [ ! -f "$APK" ]; then
  echo "❌ APK debug introuvable : $APK"
  exit 1
fi

echo "📦 Installation de l'APK sur l'émulateur..."
adb install -r "$APK"

# ─── Launch app ────────────────────────────────────────────────────
echo ""
echo "▶️  Lancement de l'activité principale..."
adb shell am start -n "${APP_PACKAGE}/${APP_ACTIVITY}" 2>&1 | sed 's/^/   /'

sleep 5   # let the app settle

# ─── Memory snapshot at T0 ─────────────────────────────────────────
echo ""
echo "📊 Memoire a T0 :"
adb shell dumpsys meminfo "$APP_PACKAGE" 2>/dev/null \
  | grep -E "TOTAL PSS|TOTAL RSS|TOTAL SWAP" | head -3 | sed 's/^/   /'

# ─── Monitor for N seconds ─────────────────────────────────────────
echo ""
echo "⏳ Monitoring pendant ${MONITOR_SECONDS}s (interactions utilisateur simulées)..."
END=$((SECONDS + MONITOR_SECONDS))
while [ "$SECONDS" -lt "$END" ]; do
  # Simulate taps every 5s (top-left + center)
  adb shell input tap 100 200 2>/dev/null || true
  sleep 2
  adb shell input tap 540 1000 2>/dev/null || true
  sleep 3
done

# ─── Memory snapshot at T1 ─────────────────────────────────────────
echo ""
echo "📊 Memoire a T0+${MONITOR_SECONDS}s :"
adb shell dumpsys meminfo "$APP_PACKAGE" 2>/dev/null \
  | grep -E "TOTAL PSS|TOTAL RSS|TOTAL SWAP" | head -3 | sed 's/^/   /'

# ─── Check for ANR / crash ─────────────────────────────────────────
echo ""
echo "🔍 Vérification crashes / ANR..."
CRASH=$(adb logcat -d -b crash 2>/dev/null | grep -c "$APP_PACKAGE" || true)
if [ "$CRASH" -gt 0 ]; then
  echo "  ⚠️  $CRASH entrées dans le crash buffer — voir 'adb logcat -b crash'"
else
  echo "  ✅ Aucun crash détecté"
fi

# ─── Cleanup ───────────────────────────────────────────────────────
echo ""
echo "🛑 Arrêt de l'émulateur..."
adb emu kill 2>/dev/null || kill "$EMU_PID" 2>/dev/null || true
trap - EXIT

echo ""
echo "✅ Test terminé"
