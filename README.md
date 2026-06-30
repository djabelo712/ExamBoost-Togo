# ExamBoost Togo

Plateforme de préparation intelligente aux examens nationaux togolais (BEPC, Probatoire, BAC 1 et BAC 2) basée sur l'IA adaptative.

## Technologies clés

- **Flutter 3.x** — Application mobile Android + iOS (offline-first)
- **Hive + SQLite** — Stockage local hors-ligne
- **Algorithme SM-2** — Répétition espacée pour optimiser la mémorisation
- **IRT (Item Response Theory)** — Calibration adaptative des questions
- **BKT (Bayesian Knowledge Tracing)** — Suivi de maîtrise par compétence
- **FastAPI (Python)** — Backend API (dossier `/backend`)

## Structure du projet

```
examboost_togo/
├── lib/
│   ├── main.dart                    # Point d'entrée
│   ├── theme/
│   │   └── app_theme.dart           # Couleurs, typographie, composants
│   ├── models/
│   │   ├── question.dart            # Modèle Question + paramètres IRT
│   │   ├── review_card.dart         # Carte SRS (SM-2) par (user × question)
│   │   └── user.dart                # Profil élève + suivi BKT
│   ├── services/
│   │   ├── srs_service.dart         # Algorithme SM-2, planification révisions
│   │   └── question_service.dart    # Chargement et filtrage des questions
│   ├── screens/
│   │   ├── home/                    # Écran d'accueil
│   │   ├── revision/                # Révision adaptative (flashcards)
│   │   ├── simulation/              # Simulation d'examen complet
│   │   ├── dashboard/               # Tableau de bord progression
│   │   └── auth/                    # Onboarding et authentification
│   ├── widgets/
│   │   ├── cards/                   # QuestionCard (flip animation)
│   │   └── buttons/                 # SrsButtons (Facile/Correct/Difficile/Oublié)
│   └── utils/
│       ├── app_router.dart          # Navigation GoRouter
│       └── app_logger.dart          # Logger centralisé
├── assets/
│   └── data/
│       └── questions.json           # 20 questions BEPC/BAC de démo
├── backend/                         # API FastAPI (Python)
├── data_pipeline/                   # Scripts OCR et annotation
└── tests/                           # Tests unitaires et widget
```

## Lancer le projet

### Prérequis

- Flutter SDK >= 3.3.0 ([flutter.dev](https://flutter.dev))
- Android Studio ou VS Code avec l'extension Flutter
- Cursor Pro recommandé ([cursor.com](https://cursor.com))

### Installation

```bash
# Cloner le repository
git clone https://github.com/TON_USERNAME/examboost-togo.git
cd examboost_togo

# Installer les dépendances
flutter pub get

# Générer les adaptateurs Hive
dart run build_runner build --delete-conflicting-outputs

# Lancer sur Android
flutter run
```

### Générer les adaptateurs Hive

Les modèles Hive nécessitent la génération de code :

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Algorithmes implémentés

### SM-2 (Répétition espacée)

Voir `lib/models/review_card.dart` — méthode `applyReview(int q)`.

Formule~: `EF' = EF + (0.1 - (5-q) × (0.08 + (5-q) × 0.02))`

### BKT (Bayesian Knowledge Tracing)

Voir `lib/models/user.dart` — méthode `updateBkt(...)`.

Mise à jour après réponse correcte~:
`P(L|obs=1) = P(L) × (1 - P(S)) / P(correct)`

### IRT (Théorie de la Réponse aux Items)

Voir `lib/services/srs_service.dart` — méthode `irtProbability(...)`.

Modèle 3PL~: `P(θ) = c + (1-c) × 1/(1 + e^(-1.7a(θ-b)))`

## Données

Le fichier `assets/data/questions.json` contient 20 questions de démo couvrant~:
- Mathématiques (BEPC et BAC séries C et D)
- Français (BEPC)
- Sciences Physiques (BEPC et BAC)
- SVT (BEPC)
- Histoire-Géographie (BEPC)
- Anglais (BEPC)

## Roadmap

- [ ] Écran de simulation d'examen complet
- [ ] Tableau de bord avec graphiques de progression
- [ ] Onboarding (sélection niveau/série)
- [ ] Backend FastAPI avec calibration IRT
- [ ] Pipeline OCR pour les annales scannées
- [ ] Synchronisation offline/online
- [ ] Module communauté (classements inter-établissements)

## Équipe

SmartFarm Togo / AIMS Ghana — Juin 2026

## Licence

Propriétaire — Tous droits réservés ExamBoost Togo
