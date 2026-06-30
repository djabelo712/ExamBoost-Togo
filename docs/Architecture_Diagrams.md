# ExamBoost Togo — Diagrammes d'Architecture

*Documentation technique visuelle — Juin 2026*

Ce document rassemble l'intégralité des diagrammes d'architecture du projet ExamBoost Togo. Il est conçu pour servir à la fois de référence technique pour l'équipe de développement et de support visuel pour le pitch DJANTA Tech Hub (24 juillet 2026). Tous les diagrammes Mermaid sont compatibles avec l'éditeur en ligne [mermaid.live](https://mermaid.live) et peuvent être exportés en PNG/SVG pour les slides.

Les sections sont organisées du macro (système global) vers le micro (algorithmes, données), puis orientées utilisateur (parcours, sync), et enfin temporel (roadmap) et opérationnel (déploiement). Chaque section combine en général un diagramme Mermaid formel et une représentation ASCII simplifiée pour les slides ne supportant pas Mermaid.

---

## Sommaire

1. Architecture système globale
2. Architecture mobile (Flutter)
3. Architecture backend (FastAPI)
4. Pipeline de données (OCR)
5. Algorithmes ML (SM-2, IRT, BKT, XGBoost)
6. Parcours utilisateur (5 écrans)
7. Modèle de données (ER diagram)
8. Flux de synchronisation offline/online
9. Roadmap technique (18 mois)
10. Diagramme de déploiement (Railway/Render + Play Store)
11. Annexe — Légende des couleurs et conventions

---

## 1. Architecture système globale

La plateforme ExamBoost Togo repose sur une architecture client-serveur **offline-first**. Le client mobile (Flutter) fonctionne de manière autonome grâce à une base locale SQLite/Hive, et se synchronise avec un backend FastAPI lorsque le réseau est disponible. Le backend orchestre quatre services algorithmiques (IRT, BKT, SM-2, XGBoost) et communique avec des services externes pour l'OCR, les SMS et les paiements Mobile Money.

### Mermaid — Diagramme de composants

```mermaid
graph TB
    subgraph "Client Mobile (Flutter)"
        UI[UI Screens<br/>Home, Onboarding, Revision, Simulation, Dashboard]
        BL[Business Logic<br/>Providers + Services]
        DB[SQLite / Hive<br/>Local DB]
        SYNC[Sync Service<br/>Offline Queue]
    end

    subgraph "Backend (FastAPI)"
        API[REST API<br/>FastAPI Router]
        AUTH[JWT Auth<br/>bcrypt + HS256]
        IRT[IRT Service<br/>3PL calibration]
        BKT[BKT Service<br/>Bayesian update]
        SRS[SM-2 Service<br/>Spaced repetition]
        ML[ML Service<br/>XGBoost predictor]
    end

    subgraph "Database"
        PG[(PostgreSQL<br/>Railway managed)]
    end

    subgraph "External Services"
        OCR[OCR Pipeline<br/>Tesseract + GPT-4o]
        SMS["Africa's Talking<br/>SMS gateway"]
        PAY[Flooz / TMoney<br/>Mobile Money]
    end

    UI --> BL
    BL --> DB
    BL --> SYNC
    SYNC --> API
    API --> AUTH
    API --> IRT
    API --> BKT
    API --> SRS
    API --> ML
    IRT --> PG
    BKT --> PG
    SRS --> PG
    ML --> PG
    OCR --> API
    API --> SMS
    API --> PAY
```

### ASCII Art — Vue d'ensemble simplifiée

Cette représentation monolinéaire est destinée aux slides et aux documents qui ne rendent pas Mermaid (PDF statiques, impressions).

```
+-------------------------------------------------------+
|              EXAMBOOST TOGO — SYSTEM VIEW             |
+-------------------------------------------------------+

  +-----------------+         +-----------------------+
  |  Mobile Flutter |         |   Backend FastAPI     |
  |  (Android 5+)   |         |   (Railway.app)       |
  |                 |  HTTPS  |                       |
  |  UI + Providers |<------->|  /auth /questions     |
  |  Hive/SQLite    |  JSON   |  /sessions /predict   |
  |  offline queue  |         |                       |
  +-----------------+         +-----------+-----------+
                                          |
                +-------------------------+-------------------------+
                |                         |                         |
                v                         v                         v
        +--------------+         +---------------+         +---------------+
        | PostgreSQL   |         | ML Services   |         | External      |
        | (Railway)    |         | IRT/BKT/SM-2  |         | OCR/SMS/MoMo  |
        | users, cards |         | XGBoost       |         | OpenAI/AT/Flooz|
        +--------------+         +---------------+         +---------------+
```

### Lecture du diagramme

- **Client mobile** : unique point d'interaction élève. Tout fonctionne hors-ligne ; la file d'attente `Sync Service` persiste les réponses en local et rejoue les requêtes au retour du réseau.
- **Backend FastAPI** : stateless, scalabilité horizontale facile. Quatre services ML indépendants permettent de les calibrer/mettre à jour sans redéployer l'ensemble.
- **PostgreSQL** : seule source de vérité partagée. Le schéma relationnel est détaillé section 7 (ER diagram).
- **OCR Pipeline** : job batch asynchrone (pas en temps réel), tourne hors-ligne sur un serveur de dev pour produire `questions.json`, qui est ensuite intégré au backend via `seed.py` et embarqué dans l'app Flutter.

---

## 2. Architecture mobile (Flutter)

L'application mobile suit une architecture en **4 couches** inspirée du Clean Architecture adaptée à Flutter. La règle de dépendance est unidirectionnelle : la couche Presentation dépend de la couche Domain, qui dépend de la couche Data. Aucune couche inférieure ne connaît les couches supérieures.

### Mermaid — Diagramme des couches Flutter

```mermaid
graph TB
    subgraph "Presentation Layer"
        Screens[Screens<br/>Home, Onboarding, Revision,<br/>Simulation, Dashboard]
        Widgets[Widgets<br/>QuestionCard, SrsButtons,<br/>ScoreChart, Heatmap]
    end

    subgraph "State Management"
        Providers[Providers<br/>UserProvider, SrsService,<br/>QuestionService]
    end

    subgraph "Domain Layer"
        Models[Models<br/>Question, ReviewCard,<br/>AppUser, SrsStats]
        Services[Services<br/>SrsService, QuestionService]
    end

    subgraph "Data Layer"
        Hive[(Hive Boxes<br/>users, review_cards)]
        SQLite[(SQLite<br/>sessions, audit)]
        SharedPrefs[SharedPreferences<br/>current_user_id, theme]
        Assets[assets/data/questions.json<br/>64 questions embarquees]
    end

    Screens --> Widgets
    Screens --> Providers
    Providers --> Services
    Services --> Models
    Services --> Hive
    Services --> SQLite
    Services --> SharedPrefs
    Services --> Assets
```

### Hiérarchie des fichiers (arbre ASCII)

```
lib/
├── main.dart                          # Entry point + MultiProvider
├── providers/
│   └── user_provider.dart             # Auth + persistance globale
├── models/
│   ├── question.dart                  # Question + IRT 3PL params
│   ├── question.g.dart                # (généré par build_runner)
│   ├── review_card.dart               # Carte SM-2 (EF, interval, reps)
│   ├── review_card.g.dart             # (généré)
│   ├── user.dart                      # AppUser + BKT par compétence
│   └── user.g.dart                    # (généré)
├── services/
│   ├── srs_service.dart               # SM-2 + IRT + sélection adaptative
│   └── question_service.dart          # Chargement + filtres questions
├── screens/
│   ├── auth/
│   │   └── onboarding_screen.dart     # 5 étapes profil élève
│   ├── home/
│   │   └── home_screen.dart           # Accueil + cartes d'action
│   ├── revision/
│   │   └── revision_screen.dart       # Flashcard 3D + SRS branché
│   ├── simulation/
│   │   └── simulation_screen.dart     # Examen chrono (BEPC 2h / BAC 4h)
│   └── dashboard/
│       └── dashboard_screen.dart      # BKT + prédiction + heatmap
├── widgets/
│   ├── cards/
│   │   └── question_card.dart         # Flip animation 3D
│   └── buttons/
│       └── srs_buttons.dart           # 4 boutons (Facile/Correct/Difficile/Oublié)
├── theme/
│   └── app_theme.dart                 # Material 3 + couleurs Togo
└── utils/
    ├── app_router.dart                # GoRouter + redirect auth
    └── app_logger.dart                # Logger centralisé

assets/
└── data/
    └── questions.json                 # 64 questions BEPC/BAC structurées
```

### Détails par couche

- **Presentation** : 5 écrans principaux, widgets réutilisables. Pas de logique métier ici, uniquement des appels vers `Provider.of<X>(context)`. Le pattern `StatefulWidget` est préféré pour les écrans avec timer ou chargement asynchrone.
- **State Management** : `Provider` (package `provider`) — choix minimaliste, pas de boilerplate Redux. `UserProvider` est un `ChangeNotifier` global injecté dans `main.dart` via `MultiProvider`.
- **Domain** : modèles Hive annotés `@HiveType` (typeId 1=Question, 2=ReviewCard, 3=AppUser). Les services `SrsService` et `QuestionService` encapsulent la logique algorithmique et les accès données.
- **Data** : trois mécanismes de persistance complémentaires — Hive pour les objets structurés (users, review_cards), SQLite pour les sessions d'examen historisées, SharedPreferences pour les flags simples (`current_user_id`, thème). Le fichier `assets/data/questions.json` est embarqué dans l'APK et chargé au démarrage via `rootBundle`.

---

## 3. Architecture backend (FastAPI)

Le backend FastAPI expose une API REST documentée automatiquement via Swagger UI (`/docs`) et ReDoc (`/redoc`). Quatre routeurs thématiques (`auth`, `questions`, `sessions`, `predict`) délèguent à cinq services métier. Le point d'entrée `main.py` configure CORS, le lifespan (init DB + seed silencieux) et inclus les routeurs avec leurs préfixes.

### Mermaid — Diagramme endpoints API

```mermaid
graph LR
    subgraph "Routers"
        AUTH_R["/auth<br/>register, login, me"]
        Q_R["/questions<br/>list, get, random, create"]
        S_R["/sessions<br/>record, due, stats"]
        P_R["/predict<br/>score, dropout"]
    end

    subgraph "Services"
        AUTH_S["auth_service.py<br/>JWT HS256 + bcrypt"]
        IRT_S["irt_service.py<br/>IRT 3PL + MLE theta"]
        BKT_S["bkt_service.py<br/>Bayesian update"]
        SRS_S["srs_service.py<br/>SM-2 algorithm"]
        ML_S["ml_service.py<br/>XGBoost + heuristic"]
    end

    subgraph "Data Layer"
        ORM[SQLAlchemy ORM<br/>models/db_models.py]
        DB[(SQLite dev /<br/>PostgreSQL prod)]
        SEED["scripts/seed_db.py<br/>64 questions + admin"]
    end

    AUTH_R --> AUTH_S
    Q_R --> ORM
    S_R --> IRT_S
    S_R --> BKT_S
    S_R --> SRS_S
    P_R --> ML_S
    P_R --> BKT_S
    ORM --> DB
    SEED --> DB
    AUTH_S --> ORM
    IRT_S --> ORM
    BKT_S --> ORM
    SRS_S --> ORM
```

### Sequence diagram — `POST /sessions`

Cet endpoint est le cœur du système : il enregistre une réponse élève, met à jour la carte SM-2, recalcule le P(L) BKT pour la compétence associée, et renvoie la date de prochaine révision. Si l'utilisateur est suffisamment actif, l'IRT peut aussi être recalibré en arrière-plan (job asynchrone).

```mermaid
sequenceDiagram
    participant App as Flutter App
    participant API as FastAPI /sessions
    participant DB as Database
    participant BKT as BKT Service
    participant SRS as SM-2 Service
    participant IRT as IRT Service

    App->>API: POST /sessions<br/>{user_id, question_id, quality, time_spent}
    API->>DB: SELECT user, question, review_card
    DB-->>API: User.bktMaitrise, Question.competenceId,<br/>ReviewCard (EF, interval, reps)

    API->>BKT: update_bkt(pL, correct=quality>=3,<br/>pT=0.2, pS=0.1, pG=0.2)
    BKT-->>API: new_pL (clamp 0..1)

    API->>SRS: apply_sm2(ef, interval, reps, quality)
    SRS-->>API: new_ef, new_interval,<br/>next_review_date

    API->>DB: UPDATE review_card,<br/>UPDATE user.bktMaitrise,<br/>INSERT session_log

    alt Plus de 100 réponses sur cette question
        API->>IRT: calibrate_irt(question_id)
        IRT-->>API: new_a, new_b, new_c
        API->>DB: UPDATE question SET irt_a, irt_b, irt_c
    end

    API-->>App: 200 OK<br/>{next_review_date, new_bkt_pl,<br/>is_mastered, score_prediction}
```

### Endpoints complets (tableau de référence)

| Méthode | Endpoint | Description | Auth |
|---|---|---|---|
| POST | `/auth/register` | Inscription élève, retourne JWT 7 jours | non |
| POST | `/auth/login` | Connexion, retourne JWT | non |
| GET | `/auth/me` | Profil courant + bktMaitrise | oui |
| GET | `/questions` | Liste filtrée (matière, examen, série, pagination) | non |
| GET | `/questions/{id}` | Détail d'une question | non |
| POST | `/questions` | Création (admin uniquement) | oui |
| GET | `/questions/random/list` | Tirage aléatoire pour simulation | non |
| POST | `/sessions` | Enregistrer une réponse (SM-2 + BKT) | non* |
| GET | `/sessions/{id}/due` | Cartes dues pour révision | non* |
| GET | `/sessions/{id}/stats` | Stats SRS (dueToday, mastered, learning) | non* |
| GET | `/predict-score/{id}` | Prédiction score BEPC/BAC | non* |
| GET | `/predict-dropout/{id}` | Risque de décrochage | non* |
| GET | `/health` | Healthcheck Railway/Render | non |

\* Authentification non exigée en dev pour faciliter la démo — à activer en production (déjà codée sur `POST /questions`).

---

## 4. Pipeline de données (OCR)

Le pipeline OCR transforme les PDF d'annales (BEPC, BAC toutes séries, 2010-2025) en questions JSON structurées prêtes à l'emploi dans l'app. Il est conçu pour être **resumable** (cache MD5 par PDF, manifeste JSON) et **hybride** (Tesseract pour le texte, GPT-4o Vision pour les formules mathématiques complexes).

### Mermaid — Flow diagram

```mermaid
graph LR
    A["Sources Web<br/>5 sites d'annales"] --> B["scrape_pdfs.py<br/>BeautifulSoup"]
    B --> C["PDFs bruts<br/>~1500 fichiers"]
    C --> D["ocr_extract.py"]
    D --> E1["Tesseract FR<br/>texte brut"]
    D --> E2["GPT-4o Vision<br/>maths / formules LaTeX"]
    E1 --> F["Texte extrait<br/>par page"]
    E2 --> F
    F --> G["structure_questions.py<br/>GPT-4o-mini + prompt JSON"]
    G --> H["JSON structuré<br/>par question"]
    H --> I["validate_questions.py<br/>jsonschema + règles métier"]
    I --> J["deduplicate.py<br/>SimHash 64 bits"]
    J --> K["estimate_irt.py<br/>heuristique b initial"]
    K --> L["questions.json final<br/>5000+ questions"]
    L --> M["App Flutter<br/>assets/data/"]
    L --> N["Backend seed<br/>scripts/seed_db.py"]
```

### Détail des étapes

| Étape | Script | Entrée | Sortie | Coût / performance |
|---|---|---|---|---|
| 1. Scraping | `scrape_pdfs.py` | URLs de 5 sites (fomesoutra, epreuvesetcorriges, etc.) | ~1500 PDFs | 0 USD (requests + BeautifulSoup) |
| 2. OCR texte | `ocr_extract.py` (mode Tesseract) | Pages texte pur | Texte brut | 0 USD (local, ~5 sec/page) |
| 2b. OCR maths | `ocr_extract.py` (mode Vision) | Pages avec formules | Texte + LaTeX | ~0.01 USD/page GPT-4o Vision |
| 3. Structuration | `structure_questions.py` | Texte brut | JSON par question | ~0.001 USD/question (GPT-4o-mini) |
| 4. Validation | `validate_questions.py` | JSON brut | JSON valide + rapport | 0 USD (jsonschema) |
| 5. Déduplication | `deduplicate.py` | JSON valide | JSON dédoublonné | 0 USD (SimHash Hamming ≤ 9) |
| 6. Estimation IRT | `estimate_irt.py` | JSON dédoublonné | JSON avec `irt.b` initial | 0 USD (heuristique) |
| 7. Calibration réelle | `scripts/calibrate_irt.py` (backend) | Réponses élèves accumulées | `irt.a`, `irt.b`, `irt.c` calibrés | py-irt ou fallback probit |

### Convention d'ID

Toutes les questions suivent le format `TG-{EXAMEN}-{MAT}-{ANNEE}-Q{NN}`. Exemples :

- `TG-BEPC-MATHS-2023-Q01` — Maths BEPC 2023, question 1
- `TG-BAC-MATHC-2022-Q03` — Maths série C BAC 2022, question 3
- `TG-BAC-SVT-2024-Q12` — SVT BAC série D 2024, question 12

Cette convention garantit l'unicité et la traçabilité jusqu'à l'année et la série d'origine.

---

## 5. Algorithmes ML

ExamBoost Togo combine **quatre algorithmes** complémentaires qui s'enchaînent à chaque interaction élève. SM-2 planifie la révision, BKT estime la maîtrise par compétence, IRT calibre la difficulté des questions et sélectionne adaptativement la prochaine, XGBoost prédit le score final à l'examen.

### Mermaid — Flow algorithmes

```mermaid
graph TB
    Q["Question présentée à l'élève"] --> R["Élève répond<br/>(quality 0-5)"]
    R --> SM2["SM-2 algorithm<br/>EF, interval, next_review_date"]
    SM2 --> NR["Date de prochaine révision"]

    R --> BKT["BKT update<br/>P(L) par compétence"]
    BKT --> PL["P(L) mise à jour"]
    PL --> MAST{"P(L) >= 0.85 ?"}
    MAST -->|Oui| MASTERED["Compétence maîtrisée"]
    MAST -->|Non| LEARNING["Toujours en apprentissage"]

    R --> IRT["IRT calibration<br/>(si > 100 réponses)"]
    IRT --> AB["C[a, b, c] par question"]
    AB --> SELECT["Sélection adaptative<br/>b le plus proche de theta"]
    SELECT --> Q

    PL --> ML["XGBoost features<br/>pL_global, pL_maths, ..."]
    ML --> PRED["Prédiction score BEPC/BAC"]
    PRED --> DASH["Dashboard élève"]
```

### Pseudocode — SM-2 (Spaced Repetition)

L'algorithme SM-2 (SuperMemo 2, 1987) planifie la prochaine révision d'une carte en fonction de la qualité `q` de la réponse (0 à 5). Une réponse `q < 3` réinitialise la carte, une réponse `q >= 3` augmente l'intervalle de manière exponentielle.

```
fonction applyReview(q):
    // q : qualité de la réponse (0=oublié, 5=parfait)
    totalAttempts += 1
    lastReviewDate = aujourd'hui

    si q >= 3:   // réponse correcte
        correctAttempts += 1
        si repetitions == 0:
            intervalDays = 1
        sinon si repetitions == 1:
            intervalDays = 6
        sinon:
            intervalDays = floor(intervalDays * easinessFactor)
        repetitions += 1
        isLearning = false
    sinon:       // réponse incorrecte
        repetitions = 0
        intervalDays = 1
        isLearning = true

    // Mise à jour du facteur d'aisance EF
    easinessFactor = easinessFactor
                     + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
    si easinessFactor < 1.3:
        easinessFactor = 1.3

    nextReviewDate = aujourd'hui + intervalDays jours
```

**Référence** : lib/models/review_card.dart, méthode `applyReview(int q)`.

### Pseudocode — BKT (Bayesian Knowledge Tracing)

Le BKT maintient pour chaque compétence une probabilité `P(L)` que l'élève aie maîtrisé cette compétence. Après chaque réponse, `P(L)` est mise à jour selon le théorème de Bayes, puis transitée par `P(T)` (probabilité d'apprendre entre deux questions).

```
fonction updateBkt(competenceId, correct):
    // Paramètres (calibrés empiriquement, configurables)
    pLearn = 0.20   // P(T) : probabilité d'apprendre
    pSlip = 0.10    // P(S) : probabilité d'erreur malgré maîtrise
    pGuess = 0.20   // P(G) : probabilité de deviner juste

    // P(L) initial pour cette compétence (0.10 si jamais vue)
    pL = bktMaitrise[competenceId] ?? 0.10

    si correct:
        // P(C) = P(L)*(1-P(S)) + (1-P(L))*P(G)
        pCorrect = pL * (1 - pSlip) + (1 - pL) * pGuess
        // P(L|obs=correct) = P(L)*(1-P(S)) / P(C)
        pLGivenObs = (pL * (1 - pSlip)) / pCorrect
    sinon:
        // P(I) = P(L)*P(S) + (1-P(L))*(1-P(G))
        pIncorrect = pL * pSlip + (1 - pL) * (1 - pGuess)
        // P(L|obs=incorrect) = P(L)*P(S) / P(I)
        pLGivenObs = (pL * pSlip) / pIncorrect

    // Transition : P(L_next) = P(L|obs) + (1 - P(L|obs))*P(T)
    pLNext = pLGivenObs + (1 - pLGivenObs) * pLearn

    // Contrainte [0, 1]
    bktMaitrise[competenceId] = clamp(pLNext, 0, 1)

    // Seuil de maîtrise : P(L) >= 0.85
    si pLNext >= 0.85:
        marquer compétence comme maîtrisée
```

**Référence** : lib/models/user.dart, méthode `updateBkt(...)`. Paramètres par défaut `pT=0.20, pS=0.10, pG=0.20` — seront recalibrés avec données pilote (M6-M7).

### Pseudocode — IRT 3PL (Item Response Theory)

L'IRT modélise la probabilité qu'un élève de niveau `theta` réponde correctement à une question de paramètres `(a, b, c)`. La calibration se fait via py-irt ou un fallback probit si py-irt n'est pas installé.

```
fonction irtProbability(theta, a, b, c=0):
    // theta : niveau de l'élève (typiquement -3 à +3)
    // a     : discriminance de la question (>0)
    // b     : difficulté (typiquement -3 à +3)
    // c     : pseudo-guessing (proba de deviner, 0 pour questions ouvertes)

    exponent = -1.7 * a * (theta - b)
    return c + (1 - c) * (1 / (1 + exp(exponent)))


fonction estimateTheta(reponses):
    // Maximum de vraisemblance (MLE) sur l'ensemble des réponses
    // Initialisation theta = 0
    // Itération Newton-Raphson jusqu'à convergence
    theta = 0
    pour i de 1 à 50:
        gradient = somme sur réponses de (correct - irtProbability(theta, a, b, c)) * a * 1.7
        hessian  = -somme de irtProbability * (1 - irtProbability) * (1.7*a)^2
        theta = theta - gradient / hessian
        si |gradient| < 0.001: break
    return theta


fonction selectBestQuestion(available, thetaUser):
    // Sélection adaptative : b le plus proche de theta
    best = null
    bestDistance = +infini
    pour chaque q dans available:
        distance = abs(q.irtB - thetaUser)
        si distance < bestDistance:
            bestDistance = distance
            best = q
    return best
```

**Référence** : lib/services/srs_service.dart, méthode `irtProbability(...)` et `selectBestQuestion(...)`.

### Pseudocode — XGBoost (prédiction score examen)

XGBoost prédit le score attendu à l'examen (BEPC ou BAC) à partir de 8 features calculées depuis les données BKT et l'activité de l'élève sur 7 jours glissants.

```
features = [
    pL_global,                 // moyenne des P(L) sur toutes compétences
    pL_maths,                  // moyenne P(L) sur compétences maths
    pL_francais,               // moyenne P(L) sur compétences français
    pL_sciences,               // moyenne P(L) sur compétences sciences
    sessions_7j,               // nb de sessions actives les 7 derniers jours
    avg_time_per_question,     // temps moyen par question (sec)
    simulations_completed,     // nb d'examens blancs terminés
    last_simulation_score,     // dernier score en simulation (/20)
]

score_pred = xgboost_model.predict(features)   // sortie : 0-20

// Fallback heuristique si modèle non entraîné :
// score = moyenne(pL_global) * 20
```

**Référence** : backend/services/ml_service.py. Modèle entraîné sur dataset synthétique (200 échantillons, R²=0.956 en démo) — sera réentraîné sur vraies données pilote M6-M8.

---

## 6. Parcours utilisateur (5 écrans)

L'application comporte 5 écrans principaux organisés autour de deux modes de travail : la **révision quotidienne** (SRS, flashcards, sessions courtes) et la **simulation mensuelle** (examen chronométré, conditions réelles). Le dashboard centralise la progression et oriente l'élève.

### Mermaid — User journey

```mermaid
journey
    title Parcours élève ExamBoost
    section Premier lancement
      Splash : 5 : App
      Onboarding 5 etapes : 5 : User
      Choix niveau et serie : 5 : User
      Choix matieres preferees : 4 : User
    section Revision quotidienne
      Accueil personnalise : 5 : User
      Selection matiere : 5 : User
      Flashcard SRS animee : 4 : User
      Voit reponse flip 3D : 5 : User
      Auto-evaluation 4 boutons : 4 : User
      Resume fin de session : 5 : User
    section Simulation mensuelle
      Config examen BEPC : 5 : User
      Questions chronometrees : 3 : User
      Plan de l'examen : 4 : User
      Rapport score + corrections : 5 : User
    section Suivi progression
      Dashboard global : 5 : User
      Heatmap chapitres faibles : 5 : User
      Prediction score BEPC : 5 : User
```

### State diagram — États de l'application

```mermaid
stateDiagram-v2
    [*] --> Splash
    Splash --> Onboarding: Premier lancement
    Splash --> Home: Utilisateur existant
    Onboarding --> Home: Profil cree
    Home --> Revision: Tap Reviser
    Home --> Simulation: Tap Simulation
    Home --> Dashboard: Tap Dashboard
    Revision --> Home: Session terminee
    Simulation --> Home: Examen fini
    Dashboard --> Revision: Tap chapitre faible
    Dashboard --> Simulation: Tap Examen blanc
    Home --> Profil: Tap avatar
    Profil --> Home: Fermer dialog
    Profil --> Onboarding: Deconnexion
```

### Détail des 5 écrans

| Écran | Fichier | Lignes | Fonction principale |
|---|---|---|---|
| Onboarding | `lib/screens/auth/onboarding_screen.dart` | 885 | 5 étapes : bienvenue, identité, niveau, série, matières préférées |
| Home | `lib/screens/home/home_screen.dart` | ~250 | Accueil personnalisé avec prénom, 3 cartes d'action (Réviser, Simulation, Dashboard) |
| Revision | `lib/screens/revision/revision_screen.dart` | ~600 | Flashcard animée 3D flip, 4 boutons SRS (Facile/Correct/Difficile/Oublié), barre de progression |
| Simulation | `lib/screens/simulation/simulation_screen.dart` | 1998 | Config examen (BEPC/BAC, série, nb questions, durée), timer HH:MM:SS, plan, rapport + corrections détaillées |
| Dashboard | `lib/screens/dashboard/dashboard_screen.dart` | ~910 | Score global circulaire, prédiction BEPC, progression par matière, heatmap chapitres, activité 7 jours (LineChart) |

---

## 7. Modèle de données (ER diagram)

Le modèle de données relationnel comprend 5 entités principales. `USER` et `QUESTION` sont les entités centrales, reliées par `REVIEW_CARD` (relation 1-N des deux côtés) qui matérialise l'état SRS pour chaque paire (élève, question). `SESSION` et `SESSION_QUESTION` historisent les examens blancs.

### Mermaid ER

```mermaid
erDiagram
    USER ||--o{ REVIEW_CARD : "possède"
    USER ||--o{ SESSION : "complète"
    QUESTION ||--o{ REVIEW_CARD : "dans"
    QUESTION ||--o{ SESSION_QUESTION : "dans"
    SESSION ||--o{ SESSION_QUESTION : "contient"

    USER {
        string id PK
        string nom
        string prenom
        string email
        string niveau_scolaire
        string serie
        string etablissement
        string ville
        datetime date_inscription
        map bkt_maitrise
        double theta_irt
        int total_sessions_count
        int total_questions_answered
        datetime last_active_date
    }

    QUESTION {
        string id PK
        string enonce
        string reponse
        string explication
        string matiere
        string chapitre
        string competence_id
        string examen
        string serie
        int annee
        string type
        int points
        list choix
        double irt_a
        double irt_b
        double irt_c
        bool irt_calibre
    }

    REVIEW_CARD {
        string user_id FK
        string question_id FK
        int repetitions
        double easiness_factor
        int interval_days
        datetime next_review_date
        datetime last_review_date
        int total_attempts
        int correct_attempts
        bool is_learning
    }

    SESSION {
        string id PK
        string user_id FK
        string examen
        string serie
        datetime started_at
        datetime ended_at
        int total_score
        int max_score
    }

    SESSION_QUESTION {
        string session_id FK
        string question_id FK
        string user_answer
        bool is_correct
        int time_spent_sec
        bool is_flagged
    }
```

### Notes de modèle

- **USER.bkt_maitrise** : `Map<String, double>` — clé = `competenceId` (format `TG-MATHS-ALGEBRE`), valeur = `P(L)` entre 0 et 1. Sérialisée en JSON en base (PostgreSQL `JSONB` ou SQLite `TEXT`).
- **QUESTION.irt_a / irt_b / irt_c** : `null` jusqu'à calibration par `py-irt` (backend). En attendant, `irt_b` est initialisé par heuristique (estimate_irt.py), `irt_a` et `irt_c` restent `null` (équivalent IRT 1PL).
- **REVIEW_CARD** : clé composite `(user_id, question_id)` — un seul enregistrement par paire. Si l'élève répond à nouveau, on `UPDATE` au lieu d'`INSERT`.
- **SESSION_QUESTION** : table de liaison N-N entre `SESSION` et `QUESTION`. Inclut la réponse exacte de l'élève, le temps passé et le flag "marqué pour revoir".
- **Hive typeIds** : `Question` = 1, `ReviewCard` = 2, `AppUser` = 3 (cf. annotations `@HiveType` dans les modèles Dart).

---

## 8. Flux de synchronisation offline/online

L'app est **offline-first** : toutes les opérations de révision fonctionnent sans réseau, grâce à la base locale Hive. Une file d'attente de synchronisation (`Sync Queue`) accumule les requêtes `POST /sessions` en attente et les rejoue dès que le réseau revient. À la fin de la sync, le backend peut renvoyer un delta (ex. : nouveaux paramètres IRT calibrés) que l'app applique localement.

### Mermaid sequence — Sync différée

```mermaid
sequenceDiagram
    participant App as App (offline)
    participant Local as Local DB Hive
    participant Queue as Sync Queue
    participant API as Backend FastAPI
    participant Cloud as Cloud DB

    Note over App,Local: Mode hors-ligne (pas de réseau)
    App->>Local: Save answer (SM-2 + BKT local)
    Local-->>App: OK, nextReviewDate calculé
    App->>Queue: Push {user_id, question_id, quality}
    Note over Queue: File persistée Hive<br/>(survit à un crash app)

    Note over App,Cloud: Réseau restauré
    Queue->>API: POST /sessions (batch)
    API->>Cloud: Update PostgreSQL<br/>(review_card, user.bkt_maitrise)
    Note over API,Cloud: Si > 100 réponses sur question,<br/>calibration IRT asynchrone
    Cloud-->>API: New calibrated IRT params (delta)
    API-->>Queue: 200 OK + delta {question_id: (a,b,c)}
    Queue->>Local: Apply delta (update question.irt_*)
    Local-->>App: Notify UI refresh<br/>(stream / provider)
```

### ASCII Art — États de la sync queue

```
            OFFLINE                                  ONLINE
            ───────                                  ──────

  +-----------------------+                +-----------------------+
  |   Sync Queue          |                |   Sync Queue          |
  |                       |                |                       |
  |   [req1] pending      |   ───────>     |   [req1] sent         |
  |   [req2] pending      |   network      |   [req2] sent         |
  |   [req3] pending      |   restored     |   [req3] sending...   |
  |                       |                |                       |
  |   next sync: auto     |                |   next sync: idle     |
  +-----------------------+                +-----------------------+
          |                                          |
          v                                          v
  +-----------------------+                +-----------------------+
  |   Local DB (Hive)     |                |   Cloud DB (PG)       |
  |   - review_cards      |                |   - review_cards      |
  |   - users (bkt)       |                |   - users (bkt)       |
  |   - sync_queue        |                |   - sessions_log      |
  +-----------------------+                +-----------------------+
```

### Stratégies de résolution de conflits

- **Last-write-wins** pour `ReviewCard` : la dernière réponse de l'élève gagne (pas de merge complexe, la carte est atomique).
- **Merge BKT** pour `User.bktMaitrise` : on prend le `P(L)` maximum entre local et cloud (hypothèse : si l'élève a révisé hors-ligne ET en ligne, la valeur la plus haute reflète le plus grand apprentissage).
- **Préfixe `_dirty`** : chaque carte modifiée hors-ligne est marquée `_dirty=true` jusqu'à sync réussie, puis `_dirty=false` (permet le débogage et la reprise sur crash).

---

## 9. Roadmap technique (18 mois)

La roadmap s'articule en 6 phases : fondations (M1-M2), données (M2-M3), MVP (M3-M5), pilote (M5-M6), lancement (M6-M8), croissance (M9-M18). Le pitch DJANTA du 24 juillet 2026 se situe en début de phase MVP.

### Mermaid Gantt

```mermaid
gantt
    title ExamBoost Togo — Roadmap 18 mois
    dateFormat  YYYY-MM-DD
    section M1-M2 Fondations
    Enquête terrain Lomé        :a1, 2026-06-01, 30d
    Accord MEPST Togo           :a2, 2026-06-01, 30d
    Recrutement équipe 4 pers   :a3, 2026-06-01, 30d

    section M2-M3 Données
    OCR + annotation 1500 PDFs  :b1, 2026-07-01, 30d
    Calibration IRT initiale    :b2, 2026-07-15, 15d

    section M3-M5 MVP Flutter
    Flutter Android 5+          :c1, 2026-08-01, 60d
    Module SRS SM-2             :c2, 2026-08-01, 30d
    Simulation BEPC chrono      :c3, 2026-08-15, 30d
    Dashboard BKT               :c4, 2026-09-01, 30d

    section M5-M6 Pilote
    5 établissements Lomé       :d1, 2026-10-01, 30d
    300 élèves actifs           :d2, 2026-10-01, 30d

    section M6-M8 Lancement
    iOS app + App Store         :e1, 2026-11-01, 30d
    Mobile Money Flooz + TMoney :e2, 2026-11-15, 15d
    Play Store national         :e3, 2026-12-01, 30d

    section M9-M18 Croissance
    200 établissements          :f1, 2027-01-01, 270d
    Expansion CEDEAO            :f2, 2027-06-01, 180d
```

### Jalons clés et KPIs

| Phase | Mois | Jalon | KPI cible |
|---|---|---|---|
| Fondations | M1-M2 | Accord MEPST + équipe recrutée | 4 personnes à temps plein |
| Données | M2-M3 | 5000+ questions en base | Couverture 2010-2025 BEPC + BAC |
| MVP | M3-M5 | App Play Store interne (beta fermée) | 5 écrans fonctionnels, 3 algos ML |
| Pilote | M5-M6 | 5 lycées pilotes Lomé | 300 élèves actifs, +8 pts aux contrôles |
| Lancement | M6-M8 | Play Store public national | 5000 utilisateurs M12, rétention >50% |
| Croissance | M9-M18 | 200 établissements partenaires | 50000 utilisateurs M18, +15 pts aux contrôles |

### Dépendances critiques

- **Accord MEPST** (M1) → conditionne l'accès aux annales officielles et la légitimité vis-à-vis des directeurs d'établissements.
- **Calibration IRT** (M2-M3) → nécessite ≥ 1000 réponses élèves collectées. Si le pilote démarre sans IRT calibré, l'app fonctionne en mode `irt_b` heuristique (dégradé mais fonctionnel).
- **Modèle XGBoost entraîné** (M7-M8) → nécessite ≥ 200 simulations terminées pour atteindre un R² > 0.85 sur données réelles.
- **Déploiement Play Store** (M8) → dépend de la conformité aux politiques Google (autorisation éducation, transparence données mineurs).

---

## 10. Diagramme de déploiement

Le déploiement production cible utilise **Railway.app** pour le backend FastAPI et PostgreSQL managé. Les apps mobiles sont distribuées via Google Play Store (Android) et Apple App Store (iOS). Les services tiers (OpenAI, Africa's Talking, Flooz, TMoney, PostHog) sont consommés en HTTPS depuis le backend uniquement (jamais depuis l'app, pour ne pas exposer les clés API).

### Mermaid — Deployment

```mermaid
graph TB
    subgraph "Production Cloud"
        RAILWAY["Railway.app<br/>FastAPI container<br/>uvicorn + gunicorn"]
        PG[("PostgreSQL<br/>Railway managed<br/>daily backups")]
        STORE["Google Play Store<br/>APK under 25 MB"]
        APPSTORE["Apple App Store<br/>iOS 12+"]
    end

    subgraph "Mobile Devices"
        ANDROID["Android 5+<br/>Tecno / Itel / Infinix<br/>4 Go RAM min"]
        IOS["iOS 12+<br/>iPhone 7+ / iPad 2017+"]
    end

    subgraph "Third-party Services"
        OPENAI["OpenAI API<br/>OCR Vision + chatbot"]
        AFRICASTALK["Africa's Talking<br/>SMS gateway"]
        MOOV["Flooz Moov<br/>Mobile Money"]
        YAS["TMoney YAS<br/>Mobile Money"]
        POSTHOG["PostHog Cloud<br/>Analytics + feature flags"]
    end

    subgraph "Dev CI/CD"
        GITHUB["GitHub Actions<br/>test + build + deploy"]
        DOCKER["Docker Hub<br/>examboost/backend:tag"]
    end

    RAILWAY --> PG
    ANDROID --> STORE
    IOS --> APPSTORE
    STORE --> ANDROID
    APPSTORE --> IOS
    ANDROID --> RAILWAY
    IOS --> RAILWAY
    RAILWAY --> OPENAI
    RAILWAY --> AFRICASTALK
    RAILWAY --> MOOV
    RAILWAY --> YAS
    ANDROID --> POSTHOG
    IOS --> POSTHOG
    GITHUB --> DOCKER
    DOCKER --> RAILWAY
    GITHUB --> STORE
    GITHUB --> APPSTORE
```

### Détail du déploiement Railway

```yaml
# railway.json (extrait)
{
  "build": { "builder": "DOCKERFILE" },
  "deploy": {
    "startCommand": "uvicorn main:app --host 0.0.0.0 --port $PORT",
    "healthcheckPath": "/health",
    "restartPolicyType": "ON_FAILURE"
  }
}
```

### Variables d'environnement production

| Variable | Description | Valeur exemple |
|---|---|---|
| `DATABASE_URL` | Connexion PostgreSQL Railway | `postgresql://user:pass@host:5432/examboost` |
| `JWT_SECRET` | Clé JWT HS256 (32+ caractères) | (générée aléatoirement) |
| `OPENAI_API_KEY` | Clé OpenAI (OCR + chatbot) | `sk-proj-...` |
| `AT_API_KEY` | Clé Africa's Talking SMS | `atsk_...` |
| `CORS_ORIGINS` | Origines autorisées | `["https://app.examboost.tg"]` |
| `ADMIN_EMAIL` | Email admin bootstrap | `admin@examboost.tg` |
| `POSTHOG_KEY` | Clé PostHog project | `phc_...` |

### Contraintes mobiles cibles

- **APK Android** < 25 Mo (optimisation images, fonts embarquées uniquement Outfit + Inter, R8/ProGuard activé).
- **Compatibilité Android 5+** (API 21) — cible les Tecno Spark, Itel A series, Infinix Hot courants au Togo (40% du parc, 4 Go RAM minimum).
- **iOS 12+** — cible iPhone 7+ et iPad 2017+ (compatibilité rear-facing camera pour OCR si ajouté plus tard).
- **Mode hors-ligne complet** : toutes les fonctionnalités sauf sync cloud et paiement Mobile Money fonctionnent sans réseau.
- **Mode données économiques** : pas de streaming vidéo, images compressées WebP, requêtes API batchées.

---

## 11. Annexe — Légende des couleurs et conventions

### Palette graphique ExamBoost

| Couleur | Hex | Usage | Sémantique |
|---|---|---|---|
| Vert Togo | `#006837` | Primaire, boutons d'action, succès | Couleur nationale, engagement |
| Orange | `#D97700` | Accent, highlights, KPIs | Énergie, motivation, call-to-action secondaire |
| Blanc cassé | `#F8F9FA` | Fond, surfaces | lisibilité, douceur |
| Gris foncé | `#1A1A1A` | Texte principal | Contraste optimal |
| Rouge | `#DC2626` | Erreurs, alertes, cartes dues | Sémantique universelle erreur |
| Vert clair | `#10B981` | Succès, compétences maîtrisées | Sémantique universelle OK |
| Orange clair | `#F59E0B` | Avertissement, en apprentissage | Sémantique universelle attention |

### Code couleur des diagrammes

| Couleur Mermaid | Représente |
|---|---|
| Vert (subgraph `Client Mobile`) | Composants ExamBoost côté client |
| Bleu (subgraph `Backend`) | Composants ExamBoost côté serveur |
| Gris (subgraph `Database`) | Couches de persistance |
| Orange (subgraph `External`) | Services tiers payants |
| Violet (nodes `ML`) | Algorithmes ML (IRT, BKT, SM-2, XGBoost) |

### Conventions de nommage

- **IDs questions** : `TG-{EXAMEN}-{MAT}-{ANNEE}-Q{NN}` (ex. `TG-BEPC-MATHS-2023-Q01`)
- **IDs compétences** : `TG-{MATIERE}-{CHAPITRE}` (ex. `TG-MATHS-ALGEBRE`, `TG-SVT-GENETIQUE`)
- **Variables Dart** : camelCase (`easinessFactor`, `nextReviewDate`, `bktMaitrise`)
- **Variables Python** : snake_case (`easiness_factor`, `next_review_date`, `bkt_maitrise`)
- **Fichiers Dart** : snake_case (`review_card.dart`, `srs_service.dart`)
- **Fichiers Python** : snake_case (`srs_service.py`, `irt_service.py`)
- **Routes API** : kebab-case ou path simple (`/predict-score/{id}`)

### Typographies

- **Titres** : Outfit (Black pour impact, Bold pour titres principaux)
- **Body** : Inter (Regular 14-16 px, Medium 14 px pour labels)
- **Code / chiffres tabulaires** : Inter avec `FontFeature.tabularFigures()` pour alignement timer et scores

### Versions et compatibilité

| Composant | Version min | Version cible |
|---|---|---|
| Flutter SDK | 3.3.0 | 3.22+ |
| Dart | 2.18 | 3.4+ |
| Python | 3.11 | 3.12 |
| FastAPI | 0.100 | 0.110+ |
| PostgreSQL | 14 | 16 |
| Android min | 5.0 (API 21) | 14 (API 34) |
| iOS min | 12.0 | 17.0 |

### Outils recommandés pour visualiser les diagrammes

- **mermaid.live** : éditeur en ligne, export PNG/SVG, validation syntaxique en temps réel.
- **VS Code + extension "Markdown Preview Mermaid Support"** : preview direct dans l'éditeur.
- **GitHub** : rendu natif Mermaid dans les fichiers `.md` depuis 2022.
- **Obsidian** : support natif Mermaid + export PDF pour pitch deck.
- **Pandoc + mermaid-filter** : conversion Markdown → PDF avec diagrammes rendus (utile pour dossiers de candidature DJANTA).

---

## Références croisées

- **Pitch deck détaillé** : `docs/Pitch_Deck_10_slides.md` (slides 4 et 8 reprennent les diagrammes système et roadmap)
- **Q&A jury anticipé** : `docs/QA_jury_anticipe.md` (thème 3 Technologie & IA développe les algos en profondeur)
- **Étude de faisabilité** : `docs/ExamBoost_Togo_Etude_Faisabilite_2025.pdf` (budget 246 400 USD, projections M18)
- **Cours théorique** : `docs/ExamBoost_Togo_Cours_Theorique_2025.pdf` (démonstrations mathématiques SM-2, BKT, IRT)
- **Plan stratégique DJANTA** : `docs/ExamBoost_DJANTA_Plan_Strategique_2026.pdf` (échéance 24 juillet 2026, critères jury)
- **Code source** :
  - Algorithmes ML Flutter : `lib/services/srs_service.dart`, `lib/models/review_card.dart`, `lib/models/user.dart`
  - Algorithmes ML Python : `backend/services/irt_service.py`, `backend/services/bkt_service.py`, `backend/services/srs_service.py`, `backend/services/ml_service.py`
  - Pipeline OCR : `data_pipeline/run_pipeline.py` (orchestrateur), `data_pipeline/README.md` (schéma ASCII détaillé)

---

*Document maintenu par l'équipe ExamBoost Togo. Dernière mise à jour : 30 juin 2026 (Session 2, Task 17-diagrams).*
