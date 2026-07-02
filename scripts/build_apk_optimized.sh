#!/usr/bin/env bash
# build_apk_optimized.sh - Build ultra-optimized release APKs for ExamBoost Togo.
#
# Applies 5 optimization layers on top of the standard release build:
#   1. Pre-build asset optimization (PNG -> WebP, SVG minify, Lottie jq -c)
#      delegated to scripts/optimize_assets.sh (skipped with --skip-assets).
#   2. --split-per-abi       (3 lighter APKs instead of one fat APK)
#   3. --shrink              (R8/ProGuard: removes unreachable Dart/Java code)
#   4. --tree-shake-icons    (drops unused Material icon font glyphs)
#   5. --obfuscate + --split-debug-info (renames symbols, strips debug info)
#
# Note: --shrink, --obfuscate and --tree-shake-icons are release-only flags.
# This script therefore produces RELEASE APKs (not debug). Debug APKs cannot
# be shrunk/obfuscated by Flutter.
#
# Each produced APK is verified to stay under 25 MB (Togo low-end constraint
# for Tecno/Itel/Infinix smartphones on cellular data). If any APK exceeds
# 25 MB, the script prints concrete optimization hints and exits with code 2
# (the build itself is considered successful).
#
# Usage:
#   ./scripts/build_apk_optimized.sh                # full pipeline
#   ./scripts/build_apk_optimized.sh --skip-assets  # skip optimize_assets.sh
#   ./scripts/build_apk_optimized.sh --no-build     # only verify existing APKs
#   ./scripts/build_apk_optimized.sh --analyze      # also run analyze_apk_size.sh
#
# Output:
#   build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
#   build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
#   build/app/outputs/flutter-apk/app-x86_64-release.apk
#   examboost-v<version>-<abi>-optimized.apk        (versioned copies)
#   build/symbols/<abi>/                             (debug-info for crash deobf.)
#   scripts/apk_size_report.md                       (when --analyze is passed)

set -euo pipefail

# ─── Defaults & flag parsing ──────────────────────────────────────────────────
SKIP_ASSETS=0
NO_BUILD=0
RUN_ANALYZE=0
SIZE_LIMIT_MB=25

for flag in "$@"; do
  case "$flag" in
    --skip-assets) SKIP_ASSETS=1 ;;
    --no-build)    NO_BUILD=1 ;;
    --analyze)     RUN_ANALYZE=1 ;;
    --help|-h)
      sed -n '2,30p' "$0"
      exit 0
      ;;
    *)
      echo "[build_apk_optimized] Unknown flag: $flag" >&2
      exit 1
      ;;
  esac
done

echo "[build_apk_optimized] Build APK ultra-optimise ExamBoost Togo"
echo "[build_apk_optimized] ============================================"

cd "$(dirname "$0")/.."

# ─── Pre-flight: Flutter SDK ──────────────────────────────────────────────────
if [ "$NO_BUILD" -eq 0 ] && ! command -v flutter >/dev/null 2>&1; then
  echo "[build_apk_optimized] ERREUR : Flutter non installe ou absent du PATH."
  echo "[build_apk_optimized]         Installe Flutter depuis https://flutter.dev"
  exit 1
fi

if [ "$NO_BUILD" -eq 0 ]; then
  flutter --version | head -1 | sed 's/^/[build_apk_optimized] Flutter : /'
fi

# ─── Layer 1: asset optimization (optional) ───────────────────────────────────
if [ "$SKIP_ASSETS" -eq 1 ]; then
  echo "[build_apk_optimized] SKIP : optimization des assets (--skip-assets)"
elif [ "$NO_BUILD" -eq 1 ]; then
  echo "[build_apk_optimized] SKIP : optimization des assets (--no-build)"
else
  OPT_SCRIPT="scripts/optimize_assets.sh"
  if [ -x "$OPT_SCRIPT" ]; then
    echo "[build_apk_optimized] Layer 1/5 : optimisation des assets..."
    # Apply for real (not dry-run) so the build picks up compressed assets.
    # optimize_assets.sh backs up originals to .bak before modifying.
    bash "$OPT_SCRIPT" --apply || {
      echo "[build_apk_optimized] ATTENTION : optimize_assets.sh a echoue (non bloquant)."
      echo "[build_apk_optimized]          Build continue avec les assets originaux."
    }
  else
    echo "[build_apk_optimized] SKIP : $OPT_SCRIPT introuvable."
  fi
fi

if [ "$NO_BUILD" -eq 1 ]; then
  echo "[build_apk_optimized] SKIP : build (--no-build) - verification des APK existants."
  APK_LIST=()
  for apk in build/app/outputs/flutter-apk/app-*-release.apk; do
    [ -f "$apk" ] || continue
    APK_LIST+=("$apk")
  done
  if [ "${#APK_LIST[@]}" -eq 0 ]; then
    echo "[build_apk_optimized] ERREUR : aucun APK release trouve dans build/app/outputs/flutter-apk/."
    echo "[build_apk_optimized]         Lance ./scripts/build_apk_optimized.sh sans --no-build."
    exit 1
  fi
else
  # ─── Clean + deps + codegen ───────────────────────────────────────────────────
  echo "[build_apk_optimized] Clean + dependances + codegen..."
  flutter clean >/dev/null
  flutter pub get >/dev/null
  dart run build_runner build --delete-conflicting-outputs >/dev/null

  # ─── Layers 2-5: build with all optimization flags ────────────────────────────
  echo "[build_apk_optimized] Layers 2-5 : build avec --split-per-abi --shrink --tree-shake-icons --obfuscate..."
  # --split-debug-info stores the symbol map needed to deobfuscate stack traces.
  # Keep it in build/symbols/<timestamp>/ so production crashes can be decoded.
  SYMBOLS_DIR="build/symbols/$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$SYMBOLS_DIR"

  # shellcheck disable=SC2086
  flutter build apk \
    --release \
    --split-per-abi \
    --shrink \
    --tree-shake-icons \
    --obfuscate \
    --split-debug-info="$SYMBOLS_DIR"

  APK_LIST=()
  for apk in build/app/outputs/flutter-apk/app-*-release.apk; do
    [ -f "$apk" ] || continue
    APK_LIST+=("$apk")
  done

  if [ "${#APK_LIST[@]}" -eq 0 ]; then
    echo "[build_apk_optimized] ERREUR : aucun APK genere par flutter build apk."
    exit 1
  fi
fi

# ─── Size report ──────────────────────────────────────────────────────────────
echo ""
echo "[build_apk_optimized] Tailles des APK optimises :"
ALL_OK=1
for apk in "${APK_LIST[@]}"; do
  SIZE_BYTES=$(stat -c%s "$apk")
  SIZE_MB=$(awk -v b="$SIZE_BYTES" 'BEGIN { printf "%.2f", b / 1024 / 1024 }')
  ABI=$(echo "$apk" | grep -oE 'arm64-v8a|armeabi-v7a|x86_64' || echo "unknown")
  printf "  %-12s %8s Mo   %s\n" "$ABI" "$SIZE_MB" "$apk"
done

# ─── Verify each APK < 25 MB ──────────────────────────────────────────────────
echo ""
echo "[build_apk_optimized] Verification taille < ${SIZE_LIMIT_MB} Mo (contrainte Togo)..."
OVER_LIMIT=()
for apk in "${APK_LIST[@]}"; do
  SIZE_BYTES=$(stat -c%s "$apk")
  SIZE_MB=$(awk -v b="$SIZE_BYTES" 'BEGIN { printf "%.2f", b / 1024 / 1024 }')
  WITHIN=$(awk -v s="$SIZE_MB" -v l="$SIZE_LIMIT_MB" 'BEGIN { print (s < l) ? "1" : "0" }')
  if [ "$WITHIN" = "1" ]; then
    echo "  OK     ${SIZE_MB} Mo   $(basename "$apk")"
  else
    echo "  DEPASSE ${SIZE_MB} Mo   $(basename "$apk")"
    ALL_OK=0
    OVER_LIMIT+=("$apk")
  fi
done

# ─── Optimization hints if any APK is over 25 MB ──────────────────────────────
if [ "$ALL_OK" -ne 1 ]; then
  echo ""
  echo "[build_apk_optimized] Au moins un APK depasse ${SIZE_LIMIT_MB} Mo. Suggestions :"
  echo ""
  echo "  1. Analyser la composition de l'APK :"
  echo "       ./scripts/analyze_apk_size.sh ${OVER_LIMIT[0]}"
  echo ""
  echo "  2. Compresser les images PNG en WebP (qualite 80) :"
  echo "       ./scripts/optimize_assets.sh --apply"
  echo ""
  echo "  3. Retirer les assets non utilises (cross-check pubspec.yaml vs lib/) :"
  echo "       ./scripts/optimize_assets.sh --apply | grep 'inutilise'"
  echo ""
  echo "  4. Minifier les animations Lottie (jq -c) :"
  echo "       for f in lib/lottie/*.json; do jq -c . \"\$f\" > \"\$f.tmp\" && mv \"\$f.tmp\" \"\$f\"; done"
  echo ""
  echo "  5. Verifier que android/app/build.gradle active R8/ProGuard :"
  echo "       buildTypes { release { minifyEnabled true; shrinkResources true } }"
  echo ""
  echo "  6. Considerer les Deferred Components (Flutter 2.0+) pour les assets"
  echo "     lourds telecharges a la demande (gain potentiel -10 Mo)."
  echo ""
  echo "  7. Si libapp.so est le plus gros fichier (>10 Mo), le code Dart compile"
  echo "     en AOT est volumineux : verifier les imports inutilises avec"
  echo "       dart run dependency_validator"
  echo "     et retirer les packages non utilises du pubspec.yaml."
fi

# ─── Versioned copies ─────────────────────────────────────────────────────────
VERSION=$(grep "^version:" pubspec.yaml | head -1 \
  | sed -E 's/^version: ([^+]+).*/\1/' | tr -d '"' | tr -d "'")
if [ -z "$VERSION" ]; then
  echo "[build_apk_optimized] ATTENTION : version non detectee dans pubspec.yaml."
  VERSION="unknown"
fi

echo ""
echo "[build_apk_optimized] Copie des APK avec tag de version (v${VERSION}-optimized)..."
for apk in "${APK_LIST[@]}"; do
  ABI=$(echo "$apk" | grep -oE 'arm64-v8a|armeabi-v7a|x86_64' || echo "unknown")
  COPY_NAME="examboost-v${VERSION}-${ABI}-optimized.apk"
  cp "$apk" "$COPY_NAME"
  echo "  -> ./${COPY_NAME}"
done

# Save the symbols dir path next to the APKs for easy retrieval.
if [ "$NO_BUILD" -eq 0 ]; then
  echo "$SYMBOLS_DIR" > build/symbols/LATEST
  echo "[build_apk_optimized] Symboles de deobfuscation : $SYMBOLS_DIR"
  echo "[build_apk_optimized] Conserver ce dossier pour decoder les stack traces prod."
fi

# ─── Optional: detailed analysis report ───────────────────────────────────────
if [ "$RUN_ANALYZE" -eq 1 ]; then
  echo ""
  echo "[build_apk_optimized] Generation du rapport detaille (--analyze)..."
  ANALYZE_SCRIPT="scripts/analyze_apk_size.sh"
  if [ -x "$ANALYZE_SCRIPT" ]; then
    # Analyze the first APK (typically arm64-v8a, the most common in Togo).
    bash "$ANALYZE_SCRIPT" "${APK_LIST[0]}" || true
  else
    echo "[build_apk_optimized] ATTENTION : $ANALYZE_SCRIPT introuvable."
  fi
fi

# ─── Final status ─────────────────────────────────────────────────────────────
echo ""
if [ "$ALL_OK" -eq 1 ]; then
  echo "[build_apk_optimized] SUCCES : tous les APK < ${SIZE_LIMIT_MB} Mo (contrainte Togo respectee)."
  exit 0
else
  echo "[build_apk_optimized] ATTENTION : au moins un APK depasse ${SIZE_LIMIT_MB} Mo."
  echo "[build_apk_optimized]            Les APK sont tout de meme generes - voir suggestions ci-dessus."
  exit 2
fi
