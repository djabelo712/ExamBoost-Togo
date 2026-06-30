#!/usr/bin/env bash
# setup.sh — Initialise le projet ExamBoost Togo après pull
#
# Usage :
#   chmod +x setup.sh && ./setup.sh
#
# Ce script :
#   1. Installe les dépendances Flutter
#   2. Génère les adaptateurs Hive (*.g.dart)
#   3. Vérifie la compilation
#   4. (Optionnel) Installe et lance le backend FastAPI

set -e  # arrêt à la première erreur

echo "🚀 Setup ExamBoost Togo — Démarrage"
echo "========================================="

# ─── Vérifications préalables ─────────────────────────────────────
echo ""
echo "1. Vérification de l'environnement..."

if ! command -v flutter &> /dev/null; then
  echo "❌ Flutter SDK n'est pas installé ou pas dans le PATH."
  echo "   Installe Flutter depuis https://flutter.dev avant de relancer ce script."
  exit 1
fi

FLUTTER_VERSION=$(flutter --version | head -1)
echo "✅ $FLUTTER_VERSION"

# ─── Dépendances Flutter ──────────────────────────────────────────
echo ""
echo "2. Installation des dépendances Flutter..."
flutter pub get
echo "✅ Dépendances installées"

# ─── Génération des adaptateurs Hive ──────────────────────────────
echo ""
echo "3. Génération des adaptateurs Hive (*.g.dart)..."
echo "   Cela peut prendre 30-60 secondes la première fois..."
dart run build_runner build --delete-conflicting-outputs
echo "✅ Adaptateurs générés :"
ls -1 lib/models/*.g.dart 2>/dev/null | sed 's/^/   • /'

# ─── Vérification de la compilation ───────────────────────────────
echo ""
echo "4. Analyse statique du code (flutter analyze)..."
flutter analyze --no-fatal-infos 2>&1 | tail -20
echo "✅ Analyse terminée (voir warnings ci-dessus le cas échéant)"

# ─── Backend FastAPI (optionnel) ──────────────────────────────────
echo ""
echo "5. Backend FastAPI (optionnel — appuyer sur Entrée pour skipper, 'y' pour installer)..."
read -r -p "   Installer et lancer le backend ? [y/N] " BACKEND_CHOICE
if [[ "$BACKEND_CHOICE" =~ ^[Yy]$ ]]; then
  if [ ! -d "backend" ]; then
    echo "❌ Dossier backend/ introuvable. Vérifie que tu as bien pullé tout le repo."
    exit 1
  fi
  cd backend

  if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 n'est pas installé."
    exit 1
  fi

  # Création venv
  python3 -m venv venv
  source venv/bin/activate
  pip install --upgrade pip
  pip install -r requirements.txt

  # Seed DB
  python seed.py || echo "⚠️ Seed déjà fait ou erreur non bloquante"

  echo ""
  echo "✅ Backend installé. Pour le lancer :"
  echo "   cd backend && source venv/bin/activate && uvicorn main:app --reload"
  echo "   → API dispo sur http://localhost:8000/docs (Swagger UI)"

  cd ..
fi

# ─── Lancement de l'app ───────────────────────────────────────────
echo ""
echo "========================================="
echo "🎉 Setup terminé !"
echo ""
echo "Pour lancer l'app Flutter :"
echo "   flutter run"
echo ""
echo "Pour générer un APK debug (pour tester sur téléphone) :"
echo "   flutter build apk --debug"
echo "   → APK généré dans build/app/outputs/flutter-apk/app-debug.apk"
echo ""
echo "Pour générer un APK release (plus léger) :"
echo "   flutter build apk --release"
echo ""
echo "Branches utiles :"
echo "   • Accueil → choisir Révision / Simulation / Dashboard"
echo "   • Onboarding au premier lancement (prénom, nom, niveau, série, matières)"
echo ""
