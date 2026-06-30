# ExamBoost Togo

Plateforme de préparation intelligente aux examens nationaux togolais (BEPC, Probatoire, BAC 1 et BAC 2) basée sur l'IA adaptative.

> Projet candidat au **DJANTA Tech Hub — Idée-Action Challenge** (pitch le 24 juillet 2026).

## 🎯 Le problème

- **BEPC 2024 : 44 % de réussite** (−37 pts vs 2023)
- **BAC 2 2024 : 46,71 %**
- **86 % des élèves togolais** ne savent pas lire couramment à 10 ans (Banque Mondiale)
- Aucun outil numérique aligné sur le programme togolais (MEPST)

## ✨ La solution

Application mobile **Flutter** (Android 5+, APK <25 Mo, **offline-first**) qui combine :

- **Répétition espacée** (algorithme SM-2 → migration FSRS après 10k révisions)
- **Théorie de la Réponse aux Items** (IRT 1PL→2PL→3PL pour calibrer les questions)
- **Bayesian Knowledge Tracing** (BKT — seuil de maîtrise P(L) ≥ 0,85)
- **XGBoost** pour prédire le score final à l'examen
- Banque de **64 questions BEPC/BAC** (objectif 5 000+ via pipeline OCR)

## 🏗 Architecture

```
examboost_togo/
├── lib/                              # App Flutter
│   ├── main.dart                     # Entry point + Providers
│   ├── providers/user_provider.dart  # Auth + persistance UserProvider
│   ├── models/
│   │   ├── question.dart             # Question + paramètres IRT
│   │   ├── review_card.dart          # Carte SRS (SM-2)
│   │   └── user.dart                 # Profil élève + BKT
│   ├── services/
│   │   ├── srs_service.dart          # SM-2 + sélection adaptative IRT
│   │   └── question_service.dart     # Chargement + filtres questions
│   ├── screens/
│   │   ├── auth/onboarding_screen.dart       # 5 étapes (identité, niveau, série, matières)
│   │   ├── home/home_screen.dart             # Accueil + cartes d'action
│   │   ├── revision/revision_screen.dart     # Flashcard animée + SRS branché
│   │   ├── simulation/simulation_screen.dart # Examen chronométré (BEPC 2h / BAC 4h)
│   │   └── dashboard/dashboard_screen.dart   # BKT + prédiction + heatmap chapitres
│   ├── widgets/
│   │   ├── cards/question_card.dart          # Carte flip 3D
│   │   └── buttons/srs_buttons.dart          # Facile / Correct / Difficile / Oublié
│   ├── theme/app_theme.dart                  # Palette vert Togo + orange
│   └── utils/
│       ├── app_router.dart                   # GoRouter + redirect auth
│       └── app_logger.dart                   # Logger centralisé
│
├── backend/                          # API FastAPI (Python)
│   ├── main.py                       # App FastAPI + CORS
│   ├── routers/                      # auth, questions, sessions, predict
│   ├── services/                     # IRT, BKT, SM-2 (miroirs Flutter)
│   ├── models/                       # SQLAlchemy + Pydantic schemas
│   ├── seed.py                       # Peuple DB avec 64 questions
│   ├── Dockerfile                    # Déploiement Railway
│   └── requirements.txt
│
├── data_pipeline/                    # Pipeline OCR annales → questions JSON
│   ├── scrape_pdfs.py                # BeautifulSoup → PDFs d'annales
│   ├── ocr_extract.py                # Tesseract + GPT-4o Vision (maths)
│   ├── structure_questions.py        # GPT-4o-mini → JSON structuré
│   ├── validate_questions.py         # Validation schéma + qualité
│   ├── deduplicate.py                # SimHash (distance Hamming)
│   ├── estimate_irt.py               # Heuristique IRT initiale
│   └── run_pipeline.py               # Orchestrateur CLI
│
├── assets/data/questions.json        # 64 questions BEPC/BAC structurées
│
├── docs/                             # Documentation stratégique
│   ├── ExamBoost_Togo_Etude_Faisabilite_2025.pdf       # Architecture + budget
│   ├── ExamBoost_Togo_Cours_Theorique_2025.pdf         # SM-2, IRT, BKT, XGBoost
│   ├── ExamBoost_Togo_Guide_Outils_IA_2025.pdf         # Stack IA par tâche
│   ├── IA_Education_Togo_2025.pdf                      # Diagnostic 5 crises
│   ├── ExamBoost_DJANTA_Plan_Strategique_2026.pdf      # Plan d'action DJANTA
│   ├── Djanta-Reglement-fr.pdf                         # Règlement officiel
│   ├── Pitch_Deck_10_slides.md                        # Script pitch bilingue
│   ├── QA_jury_anticipe.md                            # 57 questions/réponses jury
│   └── slide 4/                                        # Maquettes HTML/PNG des 5 écrans
│
├── setup.sh                          # Script d'initialisation (pub get + build_runner + backend)
├── pubspec.yaml                      # Dépendances Flutter
└── README.md
```

## 🚀 Démarrage rapide

### Prérequis

- **Flutter SDK** ≥ 3.3.0 ([flutter.dev](https://flutter.dev))
- **Python 3.11+** (pour le backend, optionnel)
- Android Studio ou VS Code avec extension Flutter

### Installation automatique

```bash
git clone https://github.com/djabelo712/ExamBoost-Togo.git
cd ExamBoost-Togo
chmod +x setup.sh && ./setup.sh
```

Le script :
1. Installe les dépendances Flutter (`flutter pub get`)
2. Génère les adaptateurs Hive (`dart run build_runner build`)
3. Lance l'analyse statique (`flutter analyze`)
4. Propose d'installer et lancer le backend FastAPI

### Installation manuelle

```bash
# Dépendances Flutter
flutter pub get

# Générer les adaptateurs Hive (question.g.dart, review_card.g.dart, user.g.dart)
dart run build_runner build --delete-conflicting-outputs

# Lancer l'app sur Android (ou Chrome pour démo web)
flutter run

# Backend (optionnel)
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python seed.py
uvicorn main:app --reload  # → http://localhost:8000/docs
```

## 🧠 Algorithmes implémentés

### SM-2 (Répétition espacée)
Fichier : `lib/models/review_card.dart` → méthode `applyReview(int q)`

```
EF' = EF + (0.1 - (5-q) × (0.08 + (5-q) × 0.02))   [plancher 1.3]
I(1) = 1, I(2) = 6, I(n) = floor(I(n-1) × EF)
Si q < 3 : n ← 0, I ← 1 (carte recommence)
```

### BKT (Bayesian Knowledge Tracing)
Fichier : `lib/models/user.dart` → méthode `updateBkt(...)`

```
Après correcte :   P(L|obs=1) = P(L)·(1-P(S)) / P(C)        où P(C) = P(L)·(1-P(S)) + (1-P(L))·P(G)
Après incorrecte : P(L|obs=0) = P(L)·P(S)   / (1-P(C))
Transition :       P(L_next) = P(L|obs) + (1-P(L|obs))·P(T)
Seuil de maîtrise : P(L) ≥ 0,85
```

### IRT 3PL (Théorie de la Réponse aux Items)
Fichier : `lib/services/srs_service.dart` → méthode `irtProbability(...)`

```
P(X=1 | θ, a, b, c) = c + (1-c) × 1 / (1 + e^(-1.7·a·(θ-b)))
```

Sélection adaptative : la prochaine question est celle dont la difficulté `b` est la plus proche du niveau `θ` de l'élève.

## 📊 Données

`assets/data/questions.json` contient **64 questions** couvrant :

| Examen | Matière | Nb questions |
|---|---|---|
| BEPC | Mathématiques | 12 |
| BEPC | Français | 8 |
| BEPC | Sciences Physiques | 6 |
| BEPC | SVT | 5 |
| BEPC | Histoire-Géographie | 5 |
| BEPC | Anglais | 4 |
| BAC série C | Mathématiques | 8 |
| BAC série C | Sciences Physiques | 6 |
| BAC série D | Mathématiques | 4 |
| BAC série D | SVT | 6 |

Pipeline OCR (`data_pipeline/`) permet de passer à 5 000+ questions en traitant les annales 2010-2025 (~1 500 PDFs, ~15 USD de coût OCR GPT-4o Vision).

## 🌐 Backend API

FastAPI minimal avec 7 endpoints :

| Endpoint | Méthode | Description |
|---|---|---|
| `/auth/register` | POST | Inscription élève (JWT) |
| `/auth/login` | POST | Connexion |
| `/auth/me` | GET | Profil courant |
| `/questions` | GET | Liste filtrée (matière, examen, série) |
| `/questions/random` | GET | Tirage aléatoire pour simulation |
| `/sessions` | POST | Enregistrer une réponse → update BKT + SM-2 |
| `/predict-score/{user_id}` | GET | Prédiction score BEPC/BAC (heuristique BKT) |

Swagger UI : `http://localhost:8000/docs` après `uvicorn main:app --reload`

## 🎤 Pitch DJANTA Tech Hub (24 juillet 2026)

- **Pitch deck 10 slides** : `docs/Pitch_Deck_10_slides.md` (script FR + EN, ~9 000 mots)
- **Q&A jury anticipé** : `docs/QA_jury_anticipe.md` (57 questions, 10 thèmes)
- **Plan stratégique** : `docs/ExamBoost_DJANTA_Plan_Strategique_2026.pdf`

## 🛠 Stack technique

| Couche | Technologie |
|---|---|
| Mobile | Flutter 3.x + Hive + SQLite |
| Backend | FastAPI + SQLAlchemy + JWT |
| Algorithmes | SM-2, IRT 3PL, BKT (Dart + Python) |
| ML prédiction | XGBoost / scikit-learn (production) |
| OCR | Tesseract + GPT-4o Vision |
| Cloud | Railway.app / Render.com |
| Analytics | PostHog (open source) |
| SMS | Africa's Talking API |
| Paiement | Flooz (Moov) + TMoney (YAS) |

## 📈 KPIs cibles (18 mois)

| KPI | M6 (pilote) | M12 | M18 |
|---|---|---|---|
| Utilisateurs actifs/mois | 300 | 5 000 | 50 000 |
| Rétention 30 jours | >40 % | >50 % | >60 % |
| Amélioration aux contrôles | +8 pts | +12 pts | +15 pts |
| Établissements partenaires | 5 | 50 | 200 |
| Revenus mensuels | 0 | 1 M FCFA | 5 M FCFA |

## 📅 Roadmap post-DJANTA

- [x] MVP Flutter (5 écrans + 3 algos ML)
- [x] Backend FastAPI minimal
- [x] Pipeline OCR (scripts Python)
- [ ] Pilote 5 établissements Lomé, 300 élèves (M5-M6)
- [ ] Calibration IRT réelle avec données pilote (M6-M7)
- [ ] Modèle XGBoost entraîné (M7-M8)
- [ ] Déploiement Play Store national (M8)
- [ ] Expansion Bénin / Côte d'Ivoire / Burkina Faso (M13+)

## 👥 Équipe

SmartFarm Togo / AIMS Ghana — Juin 2026

## 📄 Licence

Propriétaire — Tous droits réservés ExamBoost Togo
