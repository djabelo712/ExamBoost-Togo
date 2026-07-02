# ExamBoost Togo — Architecture Technique

*Document consolide de reference technique — Juillet 2026*

Ce document est la **reference unique** pour l'architecture technique du projet ExamBoost Togo. Il consolide les diagrammes d'architecture (Agent O, Session 2), les informations techniques du README principal et les elements d'infrastructure du Guide de Deploiement (Agent AF, Session 3). Il remplace, pour la consultation technique, les versions anterieures eparses et sert de point d'entree pour tout developpeur rejoignant l'equipe.

Tous les diagrammes Mermaid sont valides et compatibles avec l'editeur en ligne [mermaid.live](https://mermaid.live). Le document est organise du macro (systeme global) vers le micro (algorithmes, donnees), puis oriente operationnel (sync, securite, deploiement, monitoring).

---

## Sommaire

1. Vue d'ensemble
2. Stack technique
3. Architecture mobile (Flutter)
4. Architecture backend (FastAPI)
5. Pipeline de donnees OCR
6. Algorithmes ML
7. Modele de donnees
8. Synchronisation offline/online
9. Securite
10. Deploiement
11. Monitoring

---

## 1. Vue d'ensemble

La plateforme ExamBoost Togo repose sur une architecture client-serveur **offline-first**. Le client mobile (Flutter) fonctionne de maniere autonome grace a une base locale SQLite/Hive, et se synchronise avec un backend FastAPI lorsque le reseau est disponible. Le backend orchestre quatre services algorithmiques (IRT, BKT, SM-2, XGBoost) et communique avec des services externes pour l'OCR, les SMS et les paiements Mobile Money.

### Diagramme de composants global

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

### Lecture du diagramme

- **Client mobile** : unique point d'interaction eleve. Tout fonctionne hors-ligne ; la file d'attente `Sync Service` persiste les reponses en local et rejoue les requetes au retour du reseau.
- **Backend FastAPI** : stateless, scalabilite horizontale facile. Quatre services ML independants permettent de les calibrer/mettre a jour sans redeployer l'ensemble.
- **PostgreSQL** : seule source de verite partagee. Le schema relationnel est detaille section 7.
- **OCR Pipeline** : job batch asynchrone (pas en temps reel), tourne hors-ligne sur un serveur de dev pour produire `questions.json`, qui est ensuite integre au backend via `seed_db.py` et embarque dans l'app Flutter.

---

## 2. Stack technique

La stack a ete choisie pour trois contraintes togolaises : connectivite intermittente, budgets mobiles modestes (Android 5+ dominant), et couts cloud a minimiser. Chaque couche est remplacable independamment (par exemple Hive peut etre remplace par Drift, XGBoost par LightGBM) sans casser l'architecture globale.

| Couche | Technologie | Version min | Version cible |
|---|---|---|---|
| Mobile | Flutter | 3.44 | 3.22+ stable |
| Langage mobile | Dart | 3.4 | 3.4+ |
| State management | Provider + Riverpod | 6.x | 2.5+ |
| Routing | GoRouter | 13.2 | 14+ |
| DB locale | Hive + SQLite (sqflite) | 2.x / 2.x | stable |
| Backend | FastAPI | 0.111 | 0.110+ |
| Langage backend | Python | 3.11 | 3.12 |
| ORM | SQLAlchemy 2.x + Pydantic v2 | 2.0 | 2.0+ |
| DB cloud | PostgreSQL | 14 | 16 |
| Cache | Redis | 7 | 7+ |
| ML | scikit-learn, XGBoost, py-irt, pyBKT | 1.4 / 2.0 / — | dernieres stables |
| Deep learning | PyTorch (DKT LSTM) | 2.2 | 2.2+ |
| OCR | Tesseract 5 + GPT-4o Vision | 5.3 | — |
| Auth | JWT (HS256) + bcrypt | — | — |
| CI/CD | GitHub Actions | — | — |
| Backend hosting | Railway.app | Hobby | Pro |
| Landing hosting | Vercel | Hobby | Hobby |
| Analytics | PostHog | Cloud | Cloud |
| SMS | Africa's Talking API | — | — |
| Paiement | Flooz (Moov) + TMoney (YAS) | — | — |
| Storage | AWS S3 (af-south-1) | — | — |
| DNS | Cloudflare | — | — |

### Justification des choix cles

- **Flutter** : un seul codebase pour Android + iOS + Web, APK < 25 Mo atteignable, excellent support offline. Specifiquement adapte au contexte togolais ou Android 5+ represente plus de 60 % du parc.
- **Hive** : base NoSQL locale ultra-rapide, pas de boot FFI requise, serialisation binaire compacte. Idiome naturel pour stocker les `ReviewCard` et `AppUser`.
- **FastAPI** : performances proches de Node/Go, documentation Swagger auto-generee, async natif. Permet de coder les 4 services ML en Python sans pont inter-langage.
- **PostgreSQL + JSONB** : support natif du JSON pour le champ `bkt_maitrise` (Map<String, double>), tout en gardant les avantages relationnels pour les jointures USER/QUESTION/SESSION.
- **Provider plutot que Bloc/Redux** : minimal boilerplate, equipe reduite, courbe d'apprentissage courte. Riverpod ajoute la safety pour les futures grosses features.

---

## 3. Architecture mobile (Flutter)

L'application mobile suit une architecture en **4 couches** inspiree du Clean Architecture adaptee a Flutter. La regle de dependance est unidirectionnelle : la couche Presentation depend de la couche Domain, qui depend de la couche Data. Aucune couche inferieure ne connait les couches superieures.

### Diagramme des couches Flutter

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
        Assets[assets/data/questions.json<br/>64+ questions embarquees]
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

### Arborescence lib/

```
lib/
├── main.dart                          # Entry point + MultiProvider
├── providers/
│   ├── user_provider.dart             # Auth + persistance globale
│   ├── locale_provider.dart           # i18n (fr, en, ewe, kabye)
│   └── theme_provider.dart            # Light/Dark + system
├── models/
│   ├── question.dart                  # Question + IRT 3PL params
│   ├── review_card.dart               # Carte SM-2 (EF, interval, reps)
│   ├── user.dart                      # AppUser + BKT par competence
│   ├── score_prediction.dart          # Prediction XGBoost cachee
│   ├── badge.dart                     # Badges gamification
│   ├── sync_action.dart               # File offline
│   ├── sync_status.dart               # Etats sync
│   └── ...
├── services/
│   ├── srs_service.dart               # SM-2 + IRT + selection adaptive
│   ├── question_service.dart          # Chargement + filtres questions
│   ├── sync_service.dart              # File offline + CRDT merge
│   ├── sync_queue.dart                # Persistance queue Hive
│   ├── conflict_resolver.dart         # Last-write-wins + merge BKT
│   ├── score_predictor.dart           # Wrapper prediction (heuristique ou API)
│   ├── score_calculator.dart          # Calcul score BEPC/BAC avec coeffs
│   ├── notification_service.dart      # Notifications locales
│   ├── tts_service.dart               # Lecture vocale (FR)
│   ├── audio_cache_service.dart       # Cache audio hors-ligne
│   ├── accessibility_service.dart     # TalkBack, gros texte
│   ├── badge_service.dart             # Logique deblocage badges
│   └── ...
├── screens/
│   ├── splash/                        # Splash + transitions
│   ├── auth/onboarding_screen.dart    # 5 etapes profil eleve
│   ├── home/home_screen.dart          # Accueil + cartes d'action
│   ├── revision/revision_screen.dart  # Flashcard 3D + SRS branche
│   ├── simulation/                    # Examen chrono + plan + rapport
│   ├── dashboard/                     # BKT + prediction + heatmap
│   ├── stats/                         # Radar + timeline + recommandations
│   ├── score/                         # Prediction + coefficients BEPC
│   ├── tutor/                         # Chat IA (Claude) + vocal
│   ├── search/                        # Recherche + filtres avances
│   ├── favorites/                     # Favoris + notes perso
│   ├── classroom/                     # Mode prof + live quiz
│   ├── community/                     # Leaderboard + forum + challenges
│   ├── badges/                        # Collection + deblocage
│   ├── admin/                         # Dashboard admin + content mgmt
│   └── settings/                      # Sync, TTS, notif, accessibilite
├── widgets/
│   ├── cards/question_card.dart       # Flip animation 3D
│   ├── buttons/srs_buttons.dart       # 4 boutons (Facile/Correct/Difficile/Oublie)
│   ├── math/                          # LaTeX + FlutterMath
│   ├── figures/                       # SVG figures geometrie
│   ├── exam/                          # Timer, calculatrice, brouillon
│   ├── animations/                    # Confetti, shimmer, count_up
│   ├── states/                        # Empty/error/skeletons
│   └── sync_indicator.dart            # Badge sync offline
├── theme/
│   ├── app_theme.dart                 # Material 3 + couleurs Togo
│   ├── adaptive_colors.dart           # Dark mode + contrastes
│   └── dark_mode_fixes.dart           # Patchs contraste WCAG
├── utils/
│   ├── app_router.dart                # GoRouter + redirect auth
│   ├── app_logger.dart                # Logger centralise
│   └── notification_actions.dart      # Deep links
├── l10n/
│   ├── app_fr.arb                     # 200+ cles
│   ├── app_en.arb
│   └── (ewe + kabye en cours)
└── lottie/                            # Animations JSON (loading, success, badge)

assets/
└── data/
    ├── questions.json                 # 64+ questions BEPC/BAC
    └── geometry_questions.json        # Questions avec figures SVG
```

### Parcours utilisateur

L'application comporte 5 ecrans principaux organises autour de deux modes de travail : la **revision quotidienne** (SRS, flashcards, sessions courtes) et la **simulation mensuelle** (examen chronometre, conditions reelles). Le dashboard centralise la progression et oriente l'eleve.

```mermaid
journey
    title Parcours eleve ExamBoost
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

### Etats de l'application

Le routeur GoRouter pilote les transitions entre etats, avec un `redirect` qui verifie l'authentification (existence d'un `current_user_id` dans SharedPreferences) et oriente vers Onboarding ou Home selon le contexte.

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

### Details par couche

- **Presentation** : 5 ecrans principaux + modules secondaires. Pas de logique metier ici, uniquement des appels vers `Provider.of<X>(context)`. Le pattern `StatefulWidget` est prefere pour les ecrans avec timer ou chargement asynchrone.
- **State Management** : `Provider` (package `provider`) — choix minimaliste. `UserProvider` est un `ChangeNotifier` global injecte dans `main.dart` via `MultiProvider`. Riverpod est ajoute pour les futures features critiques (auth flows).
- **Domain** : modeles Hive annotes `@HiveType` (typeId 1=Question, 2=ReviewCard, 3=AppUser). Les services `SrsService` et `QuestionService` encapsulent la logique algorithmique et les acces donnees.
- **Data** : trois mecanismes de persistance complementaires — Hive pour les objets structures (users, review_cards), SQLite pour les sessions d'examen historisees, SharedPreferences pour les flags simples (`current_user_id`, theme). Le fichier `assets/data/questions.json` est embarque dans l'APK et charge au demarrage via `rootBundle`.

---

## 4. Architecture backend (FastAPI)

Le backend FastAPI expose une API REST documentee automatiquement via Swagger UI (`/docs`) et ReDoc (`/redoc`). Quatre routeurs thematiques (`auth`, `questions`, `sessions`, `predict`) deleguent a cinq services metier. Le point d'entree `main.py` configure CORS, le lifespan (init DB + seed silencieux) et inclus les routeurs avec leurs prefixes.

### Diagramme endpoints API

```mermaid
graph LR
    subgraph "Routers"
        AUTH_R["/auth<br/>register, login, me"]
        Q_R["/questions<br/>list, get, random, create"]
        S_R["/sessions<br/>record, due, stats"]
        P_R["/predict<br/>score, dropout"]
        T_R["/tutor<br/>chat IA Claude"]
        C_R["/classroom<br/>live quiz, teacher"]
        A_R["/admin<br/>content mgmt, alerts"]
    end

    subgraph "Services"
        AUTH_S["auth_service.py<br/>JWT HS256 + bcrypt"]
        IRT_S["irt_service.py<br/>IRT 3PL + MLE theta"]
        BKT_S["bkt_service.py<br/>Bayesian update"]
        SRS_S["srs_service.py<br/>SM-2 algorithm"]
        ML_S["ml_service.py<br/>XGBoost + heuristic"]
        TUT_S["tutor_service.py<br/>Claude 3.5 Sonnet"]
        CM_S["classroom_manager.py<br/>Socket.IO + REST"]
    end

    subgraph "Data Layer"
        ORM[SQLAlchemy ORM<br/>models/db_models.py]
        DB[(PostgreSQL prod /<br/>SQLite dev)]
        CACHE[(Redis<br/>rate-limit + cache)]
        SEED["scripts/seed_db.py<br/>64+ questions + admin"]
    end

    AUTH_R --> AUTH_S
    Q_R --> ORM
    S_R --> IRT_S
    S_R --> BKT_S
    S_R --> SRS_S
    P_R --> ML_S
    P_R --> BKT_S
    T_R --> TUT_S
    C_R --> CM_S
    AUTH_S --> ORM
    IRT_S --> ORM
    BKT_S --> ORM
    SRS_S --> ORM
    ML_S --> ORM
    ORM --> DB
    ORM --> CACHE
    SEED --> DB
```

### Sequence diagram — `POST /sessions`

Cet endpoint est le coeur du systeme : il enregistre une reponse eleve, met a jour la carte SM-2, recalcule le P(L) BKT pour la competence associee, et renvoie la date de prochaine revision. Si l'utilisateur est suffisamment actif, l'IRT peut aussi etre recaliore en arriere-plan (job asynchrone).

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

    alt Plus de 100 reponses sur cette question
        API->>IRT: calibrate_irt(question_id)
        IRT-->>API: new_a, new_b, new_c
        API->>DB: UPDATE question SET irt_a, irt_b, irt_c
    end

    API-->>App: 200 OK<br/>{next_review_date, new_bkt_pl,<br/>is_mastered, score_prediction}
```

### Endpoints complets

| Methode | Endpoint | Description | Auth |
|---|---|---|---|
| POST | `/auth/register` | Inscription eleve, retourne JWT 7 jours | non |
| POST | `/auth/login` | Connexion, retourne JWT | non |
| GET | `/auth/me` | Profil courant + bktMaitrise | oui |
| GET | `/questions` | Liste filtree (matiere, examen, serie, pagination) | non |
| GET | `/questions/{id}` | Detail d'une question | non |
| POST | `/questions` | Creation (admin uniquement) | oui |
| GET | `/questions/random/list` | Tirage aleatoire pour simulation | non |
| POST | `/sessions` | Enregistrer une reponse (SM-2 + BKT) | non* |
| GET | `/sessions/{id}/due` | Cartes dues pour revision | non* |
| GET | `/sessions/{id}/stats` | Stats SRS (dueToday, mastered, learning) | non* |
| GET | `/predict-score/{id}` | Prediction score BEPC/BAC | non* |
| GET | `/predict-dropout/{id}` | Risque de decrochage | non* |
| POST | `/tutor/chat` | Chat IA tutor (Claude 3.5 Sonnet) | oui |
| GET | `/classroom/{code}/join` | Rejoindre session live | oui |
| POST | `/admin/questions` | CRUD questions | admin |
| GET | `/admin/students` | Liste eleves + stats | admin |
| GET | `/health` | Healthcheck Railway/Render | non |
| GET | `/health/ready` | Readiness probe (DB + Redis) | non |
| GET | `/health/stats` | Stats globales (nb users, questions) | non |

\* Authentification non exigee en dev pour faciliter la demo — a activer en production (deja codee sur `POST /questions`).

---

## 5. Pipeline de donnees OCR

Le pipeline OCR transforme les PDF d'annales (BEPC, BAC toutes series, 2010-2025) en questions JSON structurees pretes a l'emploi dans l'app. Il est concu pour etre **resumable** (cache MD5 par PDF, manifeste JSON) et **hybride** (Tesseract pour le texte, GPT-4o Vision pour les formules mathematiques complexes).

### Flow diagram du pipeline

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
    G --> H["JSON structure<br/>par question"]
    H --> I["validate_questions.py<br/>jsonschema + regles metier"]
    I --> J["deduplicate.py<br/>SimHash 64 bits"]
    J --> K["estimate_irt.py<br/>heuristique b initial"]
    K --> L["questions.json final<br/>5000+ questions"]
    L --> M["App Flutter<br/>assets/data/"]
    L --> N["Backend seed<br/>scripts/seed_db.py"]
```

### Detail des etapes

| Etape | Script | Entree | Sortie | Cout / performance |
|---|---|---|---|---|
| 1. Scraping | `scrape_pdfs.py` | URLs de 5 sites (fomesoutra, epreuvesetcorriges, etc.) | ~1500 PDFs | 0 USD (requests + BeautifulSoup) |
| 2. OCR texte | `ocr_extract.py` (mode Tesseract) | Pages texte pur | Texte brut | 0 USD (local, ~5 sec/page) |
| 2b. OCR maths | `ocr_extract.py` (mode Vision) | Pages avec formules | Texte + LaTeX | ~0.01 USD/page GPT-4o Vision |
| 3. Structuration | `structure_questions.py` | Texte brut | JSON par question | ~0.001 USD/question (GPT-4o-mini) |
| 4. Validation | `validate_questions.py` | JSON brut | JSON valide + rapport | 0 USD (jsonschema) |
| 5. Deduplication | `deduplicate.py` | JSON valide | JSON dedoublonne | 0 USD (SimHash Hamming <= 9) |
| 6. Estimation IRT | `estimate_irt.py` | JSON dedoublonne | JSON avec `irt.b` initial | 0 USD (heuristique) |
| 7. Calibration reelle | `scripts/calibrate_irt.py` (backend) | Reponses eleves accumulees | `irt.a`, `irt.b`, `irt.c` calibres | py-irt ou fallback probit |

### Convention d'ID

Toutes les questions suivent le format `TG-{EXAMEN}-{MAT}-{ANNEE}-Q{NN}`. Exemples :

- `TG-BEPC-MATHS-2023-Q01` — Maths BEPC 2023, question 1
- `TG-BAC-MATHC-2022-Q03` — Maths serie C BAC 2022, question 3
- `TG-BAC-SVT-2024-Q12` — SVT BAC serie D 2024, question 12

Cette convention garantit l'unicite et la tracabilite jusqu'a l'annee et la serie d'origine.

### Cout total estime pour 5000 questions

- Scraping + Tesseract : 0 USD
- GPT-4o Vision (formules, ~30 % des pages) : ~5 USD
- GPT-4o-mini structuration : ~5 USD
- **Total** : ~10-15 USD pour 5000 questions, soit ~0,003 USD/question

---

## 6. Algorithmes ML

ExamBoost Togo combine **cinq algorithmes** complementaires qui s'enchainent a chaque interaction eleve. SM-2 planifie la revision, BKT estime la maitrise par competence, IRT calibre la difficulte des questions et selectionne adaptativement la prochaine, XGBoost predit le score final a l'examen, et un K-Means clusterise les eleves en personas pour adapter les recommandations pedagogiques.

### Flow algorithmes

```mermaid
graph TB
    Q["Question presentee a l'eleve"] --> R["Eleve repond<br/>(quality 0-5)"]
    R --> SM2["SM-2 algorithm<br/>EF, interval, next_review_date"]
    SM2 --> NR["Date de prochaine revision"]

    R --> BKT["BKT update<br/>P(L) par competence"]
    BKT --> PL["P(L) mise a jour"]
    PL --> MAST{"P(L) >= 0.85 ?"}
    MAST -->|Oui| MASTERED["Competence maitrisee"]
    MAST -->|Non| LEARNING["Toujours en apprentissage"]

    R --> IRT["IRT calibration<br/>(si > 100 reponses)"]
    IRT --> AB["C[a, b, c] par question"]
    AB --> SELECT["Selection adaptive<br/>b le plus proche de theta"]
    SELECT --> Q

    PL --> ML["XGBoost features<br/>pL_global, pL_maths, ..."]
    ML --> PRED["Prediction score BEPC/BAC"]
    PRED --> DASH["Dashboard eleve"]

    PL --> CLUST["K-Means<br/>4 personas eleves"]
    CLUST --> REC["Recommandations personnalisees"]
```

### SM-2 (Repetition espacee)

L'algorithme SM-2 (SuperMemo 2, 1987) planifie la prochaine revision d'une carte en fonction de la qualite `q` de la reponse (0 a 5). Une reponse `q < 3` reinitialise la carte, une reponse `q >= 3` augmente l'intervalle de maniere exponentielle.

```
fonction applyReview(q):
    // q : qualite de la reponse (0=oublie, 5=parfait)
    totalAttempts += 1
    lastReviewDate = aujourd'hui

    si q >= 3:   // reponse correcte
        correctAttempts += 1
        si repetitions == 0:
            intervalDays = 1
        sinon si repetitions == 1:
            intervalDays = 6
        sinon:
            intervalDays = floor(intervalDays * easinessFactor)
        repetitions += 1
        isLearning = false
    sinon:       // reponse incorrecte
        repetitions = 0
        intervalDays = 1
        isLearning = true

    // Mise a jour du facteur d'aisance EF
    easinessFactor = easinessFactor
                     + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
    si easinessFactor < 1.3:
        easinessFactor = 1.3

    nextReviewDate = aujourd'hui + intervalDays jours
```

**Reference** : `lib/models/review_card.dart`, methode `applyReview(int q)`.

### BKT (Bayesian Knowledge Tracing)

Le BKT maintient pour chaque competence une probabilite `P(L)` que l'eleve ait maitrise cette competence. Apres chaque reponse, `P(L)` est mise a jour selon le theoreme de Bayes, puis transitee par `P(T)` (probabilite d'apprendre entre deux questions).

```
fonction updateBkt(competenceId, correct):
    // Parametres (calibres empiriquement, configurables)
    pLearn = 0.20   // P(T) : probabilite d'apprendre
    pSlip = 0.10    // P(S) : probabilite d'erreur malgre maitrise
    pGuess = 0.20   // P(G) : probabilite de deviner juste

    // P(L) initial pour cette competence (0.10 si jamais vue)
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

    // Seuil de maitrise : P(L) >= 0.85
    si pLNext >= 0.85:
        marquer competence comme maitrisee
```

**Reference** : `lib/models/user.dart`, methode `updateBkt(...)`. Parametres par defaut `pT=0.20, pS=0.10, pG=0.20` — seront recaliibres avec donnees pilote (M6-M7).

### IRT 3PL (Theorie de la Reponse aux Items)

L'IRT modelise la probabilite qu'un eleve de niveau `theta` reponde correctement a une question de parametres `(a, b, c)`. La calibration se fait via py-irt ou un fallback probit si py-irt n'est pas installe.

Formule de la courbe caracteristique d'item (ICC) :

```
P(X=1 | theta, a, b, c) = c + (1 - c) * 1 / (1 + exp(-1.7 * a * (theta - b)))

ou :
  theta : niveau de l'eleve (typiquement -3 a +3)
  a     : discriminance de la question (>0)
  b     : difficulte (typiquement -3 a +3)
  c     : pseudo-guessing (proba de deviner, 0 pour questions ouvertes)
```

Pseudocode de selection adaptive :

```
fonction selectBestQuestion(available, thetaUser):
    // Selection adaptive : b le plus proche de theta
    best = null
    bestDistance = +infini
    pour chaque q dans available:
        distance = abs(q.irtB - thetaUser)
        si distance < bestDistance:
            bestDistance = distance
            best = q
    return best


fonction estimateTheta(reponses):
    // Maximum de vraisemblance (MLE) sur l'ensemble des reponses
    // Initialisation theta = 0
    // Iteration Newton-Raphson jusqu'a convergence
    theta = 0
    pour i de 1 a 50:
        gradient = somme sur reponses de (correct - irtProbability(theta, a, b, c)) * a * 1.7
        hessian  = -somme de irtProbability * (1 - irtProbability) * (1.7*a)^2
        theta = theta - gradient / hessian
        si |gradient| < 0.001: break
    return theta
```

**Reference** : `lib/services/srs_service.dart`, methodes `irtProbability(...)` et `selectBestQuestion(...)`.

### XGBoost (prediction score examen)

XGBoost predit le score attendu a l'examen (BEPC ou BAC) a partir de 8 features calculees depuis les donnees BKT et l'activite de l'eleve sur 7 jours glissants.

```
features = [
    pL_global,                 // moyenne des P(L) sur toutes competences
    pL_maths,                  // moyenne P(L) sur competences maths
    pL_francais,               // moyenne P(L) sur competences francais
    pL_sciences,               // moyenne P(L) sur competences sciences
    sessions_7j,               // nb de sessions actives les 7 derniers jours
    avg_time_per_question,     // temps moyen par question (sec)
    simulations_completed,     // nb d'examens blancs termines
    last_simulation_score,     // dernier score en simulation (/20)
]

score_pred = xgboost_model.predict(features)   // sortie : 0-20

// Fallback heuristique si modele non entraîne :
// score = moyenne(pL_global) * 20
```

**Reference** : `backend/services/ml_service.py` + `backend/scripts/ml_training/train_score_predictor.py`. Modele entraîne sur dataset synthetique (200 echantillons, R²=0.956 en demo) — sera reentraîne sur vraies donnees pilote M6-M8. SHAP analysis disponible dans `backend/scripts/ml_training/output/`.

### DKT LSTM (alternative a BKT)

Le Deep Knowledge Tracing utilise un reseau LSTM pour predire la probabilite de reussite a la prochaine question, en tenant compte de la sequence complete des reponses passees. Plus precis que BKT mais necessite PyTorch et GPU pour l'inference (< 50 ms en CPU avec ONNX, acceptable).

```
architecture :
  input  : sequence de (question_id, correct) one-hot encoded
  LSTM   : 200 units, 1 layer
  output : Dense(softmax) -> P(correct|next_question)

training :
  loss    : binary cross-entropy
  optim   : Adam lr=0.001
  epochs  : 20 (early stopping)
  data    : sequences de 50+ reponses par eleve

export :
  PyTorch -> ONNX -> inference FastAPI (onnxruntime)
```

**Reference** : `backend/scripts/dkt_model/dkt_model.py` + `train_dkt.py`. Modele exporte en ONNX dans `output/dkt_model.pt`. A utiliser en A/B test contre BKT en M9+.

### K-Means clustering (personnas eleves)

Le K-Means partitionne les eleves en 4 personas a partir de leurs features d'activite pour personnaliser les recommandations pedagogiques. Le nombre de clusters a ete determine par la methode du coude sur le dataset synthetique.

```
features_cluster = [
    pL_global,
    sessions_7j,
    avg_time_per_question,
    streak_days,                // nb de jours consecutifs d'activite
    simulations_completed,
    favorite_matiere,           // one-hot encodee
]

kmeans = KMeans(n_clusters=4, random_state=42, n_init=10)
cluster = kmeans.fit_predict(features_cluster)

// Personnas identifies (apres analyse) :
// 0 : "Decrocheur"     - faible activite, faible pL -> notifications + remediation
// 1 : "Regulier moyen" - activite moyenne, pL ~0.5 -> encourage + challenges
// 2 : "Assidu fort"    - activite haute, pL > 0.7 -> simulation + perfectionnement
// 3 : "Bourreau"       - activite haute mais pL bas -> changement methode + tutor IA
```

**Reference** : `backend/scripts/student_clustering/cluster_students.py` + `generate_personas.py`. Sorties dans `output/personas.md` et `output/cluster_stats.json`.

---

## 7. Modele de donnees

Le modele de donnees relationnel comprend 5 entites principales. `USER` et `QUESTION` sont les entites centrales, reliees par `REVIEW_CARD` (relation 1-N des deux cotes) qui materialise l'etat SRS pour chaque paire (eleve, question). `SESSION` et `SESSION_QUESTION` historisent les examens blancs.

### Diagramme ER

```mermaid
erDiagram
    USER ||--o{ REVIEW_CARD : "possede"
    USER ||--o{ SESSION : "complete"
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

### Notes de modele

- **USER.bkt_maitrise** : `Map<String, double>` — cle = `competenceId` (format `TG-MATHS-ALGEBRE`), valeur = `P(L)` entre 0 et 1. Serialisee en JSON en base (PostgreSQL `JSONB` ou SQLite `TEXT`).
- **QUESTION.irt_a / irt_b / irt_c** : `null` jusqu'a calibration par `py-irt` (backend). En attendant, `irt_b` est initialise par heuristique (estimate_irt.py), `irt_a` et `irt_c` restent `null` (equivalent IRT 1PL).
- **REVIEW_CARD** : cle composite `(user_id, question_id)` — un seul enregistrement par paire. Si l'eleve repond a nouveau, on `UPDATE` au lieu d'`INSERT`.
- **SESSION_QUESTION** : table de liaison N-N entre `SESSION` et `QUESTION`. Inclut la reponse exacte de l'eleve, le temps passe et le flag "marque pour revoir".
- **Hive typeIds** : `Question` = 1, `ReviewCard` = 2, `AppUser` = 3 (cf. annotations `@HiveType` dans les modeles Dart).

### Migrations Alembic

Deux migrations sont versionnees dans `backend/alembic/versions/` :

- `001_initial_schema.py` — schema de base (users, questions, review_cards, sessions, session_questions)
- `002_add_tutor_tables.py` — tables tutor (conversations, messages) et classroom (sessions live, participants)

Procedure de migration : `./scripts/run_migrations.sh` (wrapper Alembic qui detecte l'environnement et applique `alembic upgrade head`).

---

## 8. Synchronisation offline/online

L'app est **offline-first** : toutes les operations de revision fonctionnent sans reseau, grace a la base locale Hive. Une file d'attente de synchronisation (`Sync Queue`) accumule les requetes `POST /sessions` en attente et les rejoue des que le reseau revient. A la fin de la sync, le backend peut renvoyer un delta (ex. : nouveaux parametres IRT calibres) que l'app applique localement.

### Sequence diagram — Sync differée

```mermaid
sequenceDiagram
    participant App as App (offline)
    participant Local as Local DB Hive
    participant Queue as Sync Queue
    participant API as Backend FastAPI
    participant Cloud as Cloud DB

    Note over App,Local: Mode hors-ligne (pas de reseau)
    App->>Local: Save answer (SM-2 + BKT local)
    Local-->>App: OK, nextReviewDate calcule
    App->>Queue: Push {user_id, question_id, quality}
    Note over Queue: File persistee Hive<br/>(survit a un crash app)

    Note over App,Cloud: Reseau restaure
    Queue->>API: POST /sessions (batch)
    API->>Cloud: Update PostgreSQL<br/>(review_card, user.bkt_maitrise)
    Note over API,Cloud: Si > 100 reponses sur question,<br/>calibration IRT asynchrone
    Cloud-->>API: New calibrated IRT params (delta)
    API-->>Queue: 200 OK + delta {question_id: (a,b,c)}
    Queue->>Local: Apply delta (update question.irt_*)
    Local-->>App: Notify UI refresh<br/>(stream / provider)
```

### Etats de la sync queue

```
            OFFLINE                                  ONLINE
            -------                                  ------

  +-----------------------+                +-----------------------+
  |   Sync Queue          |                |   Sync Queue          |
  |                       |                |                       |
  |   [req1] pending      |   ------>      |   [req1] sent         |
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

### Strategies de resolution de conflits

- **Last-write-wins** pour `ReviewCard` : la derniere reponse de l'eleve gagne (pas de merge complexe, la carte est atomique).
- **Merge BKT** pour `User.bktMaitrise` : on prend le `P(L)` maximum entre local et cloud (hypothese : si l'eleve a revise hors-ligne ET en ligne, la valeur la plus haute reflete le plus grand apprentissage).
- **Prefixe `_dirty`** : chaque carte modifiee hors-ligne est marquee `_dirty=true` jusqu'a sync reussie, puis `_dirty=false` (permet le debogage et la reprise sur crash).

### CRDT et idempotence

Chaque action de la sync queue embarque un `client_uuid` (UUID v4 genere localement) et un `timestamp_ms`. Le backend stocke ces identifiants dans une table `sync_log` avec contrainte d'unicite sur `(client_uuid, timestamp_ms)`, garantissant qu'un meme replay (apres crash reseau) ne compte pas deux fois. C'est une forme simplifiee de CRDT (Conflict-free Replicated Data Type) adaptee au contexte de file d'attente.

---

## 9. Securite

La securite d'ExamBoost Togo suit une approche defense-en-profondeur, en respectant les principes OWASP Top 10 et la legislation togolaise sur la protection des donnees (Loi 2019-014 du 29 octobre 2019 relative a la protection des donnees a caractere personnel).

### Authentification et autorisation

- **JWT HS256** : tokens de 7 jours, signature avec `SECRET_KEY` (32+ caracteres, genere via `openssl rand -hex 32`).
- **bcrypt** : hash des mots de passe avec cost factor 12.
- **Refresh tokens** : non implantes en MVP, prevus en M9 (access token 1h + refresh 30j).
- **Admin** : role booleen `is_admin` sur la table `users`. Routes `/admin/*` protegees par dependency `require_admin`.
- **Tutor chat** : rate limit 30 questions/heure/user (configurable) pour eviter l'abus API Claude.

### Rate limiting

Implemente dans `backend/rate_limiter.py` :

| Endpoint | Limite | Fenetre |
|---|---|---|
| `/auth/login` | 5 echecs | 15 min par IP |
| `/auth/register` | 3 inscriptions | 1 h par IP |
| `/tutor/chat` | 30 questions | 1 h par user |
| `/sessions` | 100 posts | 1 min par user |
| Autres endpoints | 60 req | 1 min par IP |

En mode multi-replicas, le state du rate limiter est partage via Redis (`REDIS_URL`).

### CORS et headers

- `CORS_ORIGINS` : liste blanche stricte (`https://examboost.tg`, `https://examboost-togo.vercel.app`). En staging, `localhost:3000` ajoute.
- `Strict-Transport-Security` : `max-age=31536000; includeSubDomains` (HSTS).
- `X-Content-Type-Options: nosniff`.
- `X-Frame-Options: DENY` (anti clickjacking).
- `Content-Security-Policy` : restrictive sur la landing Next.js.

### Conformite loi 2019-014 Togo

- **Consentement explicite** : l'onboarding inclut un ecran de consentement (case a cocher obligatoire) detailnant les finalites du traitement.
- **Droit a l'oubli** : endpoint `DELETE /auth/me` a implementer (M9) pour suppression complete des donnees d'un eleve.
- **Portabilite** : endpoint `GET /auth/me/export` a implementer (M9) pour export JSON de toutes les donnees.
- **Hebergement** : donnees sensibles (PII) hebergees sur Railway (US/EU) — notification a faire aupres de l'IPDCP (Instance Togolaise de Protection des Donnees) avant lancement public.
- **Mineurs** : politique transparente sur les mineurs (orientee BEPC), pas de tracking publicitaire, pas de revente de donnees.
- **Chiffrement** : HTTPS obligatoire (TLS 1.2+), DB PostgreSQL chiffree au repos sur Railway.

### Considerations OWASP Top 10

| Risque OWASP | Mitigation ExamBoost |
|---|---|
| A01 - Broken Access Control | JWT verify sur chaque route, dependency `require_admin` |
| A02 - Cryptographic Failures | bcrypt + TLS 1.2+ + `SECRET_KEY` rotate tous les 6 mois |
| A03 - Injection | SQLAlchemy ORM (parametres lies), Pydantic validation stricte |
| A04 - Insecure Design | Threat model par feature, review par 1 dev min |
| A05 - Security Misconfiguration | `.env.example` verifie, pas de secrets en dur |
| A06 - Vulnerable Components | `pip audit` + `npm audit` en CI |
| A07 - Auth Failures | Rate limit login, lock apres 5 echecs |
| A08 - Software/Data Integrity | Signatures de releases Git (`git tag -s`) |
| A09 - Logging/Monitoring Failures | Sentry + PostHog + logs Railway |
| A10 - SSRF | Pas de requetes utilisateur vers URLs internes |

### Secrets management

- **Dev** : fichiers `.env` (backend) et `.env.local` (landing), gitignored.
- **CI/CD** : GitHub Secrets (`RAILWAY_TOKEN`, `VERCEL_TOKEN`, `ANTHROPIC_API_KEY`).
- **Prod** : variables Railway et Vercel, accessibles uniquement aux admins du projet.
- **Rotation** : `SECRET_KEY` tous les 6 mois, `RAILWAY_TOKEN` annuel, `ANTHROPIC_API_KEY` si compromission.

---

## 10. Deploiement

Le deploiement production cible utilise **Railway.app** pour le backend FastAPI et PostgreSQL managed. La landing Next.js 16 est sur Vercel. Les apps mobiles sont distribuees via Google Play Store (Android) et Apple App Store (iOS). Les services tiers (OpenAI/Anthropic, Africa's Talking, Flooz, TMoney, PostHog) sont consommes en HTTPS depuis le backend uniquement (jamais depuis l'app, pour ne pas exposer les cles API).

### Diagramme de deploiement

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
        OPENAI["OpenAI / Anthropic API<br/>OCR Vision + tutor chat"]
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

### URLs (prod + staging)

| Service | Environnement | URL |
|---|---|---|
| Landing | Production | `https://examboost-togo.vercel.app` |
| Landing | Custom domain | `https://examboost.tg` |
| Landing | Preview | `https://examboost-togo-git-<branch>.vercel.app` |
| Backend | Production | `https://examboost-togo.up.railway.app` |
| Backend | Staging | `https://examboost-togo-staging.up.railway.app` |
| Backend | Swagger | `https://examboost-togo.up.railway.app/docs` |
| Backend | Health | `https://examboost-togo.up.railway.app/health` |
| Backend | Stats | `https://examboost-togo.up.railway.app/health/stats` |
| Repo | GitHub | `https://github.com/djabelo712/ExamBoost-Togo` |

### Railway config (extrait)

```yaml
# backend/railway.json
{
  "build": { "builder": "DOCKERFILE" },
  "deploy": {
    "startCommand": "uvicorn main:app --host 0.0.0.0 --port $PORT --workers 4",
    "healthcheckPath": "/health",
    "restartPolicyType": "ON_FAILURE",
    "numReplicas": 1
  }
}
```

### Variables d'environnement production

| Variable | Description | Valeur exemple |
|---|---|---|
| `DATABASE_URL` | Connexion PostgreSQL Railway | `postgresql://user:pass@host:5432/examboost` |
| `SECRET_KEY` (JWT) | Cle HS256 (32+ caracteres) | (generee aleatoirement) |
| `ANTHROPIC_API_KEY` | Cle Anthropic (tutor chat) | `sk-ant-...` |
| `OPENAI_API_KEY` | Cle OpenAI (OCR Vision) | `sk-proj-...` |
| `AT_API_KEY` | Cle Africa's Talking SMS | `atsk_...` |
| `CORS_ORIGINS` | Origines autorisees | `["https://examboost.tg"]` |
| `ADMIN_EMAIL` | Email admin bootstrap | `admin@examboost.tg` |
| `POSTHOG_KEY` | Cle PostHog project | `phc_...` |
| `SENTRY_DSN` | DSN Sentry | `https://...@sentry.io/...` |
| `REDIS_URL` | Connexion Redis (optionnel) | `redis://...` |

### CI/CD GitHub Actions

Workflows existants :

| Workflow | Fichier | Trigger |
|---|---|---|
| Backend CI (test + lint + docker build) | `.github/workflows/backend_ci.yml` | push/PR sur `main`, paths `backend/**` |
| Flutter CI | `.github/workflows/flutter_ci.yml` | push/PR sur `main` |
| Flutter Release (APK) | `.github/workflows/flutter_release.yml` | tag `v*.*.*` |
| Data Pipeline CI | `.github/workflows/data_pipeline_ci.yml` | push/PR, paths `data_pipeline/**` |

Flow de release :

1. Developper sur une branche `feat/xxx` ou `fix/xxx`.
2. Ouvrir une PR → CI tourne (tests + lint + build).
3. Merge dans `main` → deploiement auto **staging** + preview Vercel.
4. Tester en staging (QA manuelle + smoke tests via `health_check.sh`).
5. Promouvoir en production : `./scripts/deploy_all.sh --prod`.
6. Verifier `health_check.sh` en prod.
7. Si incident : `./scripts/rollback_backend.sh production`.

### Roadmap technique (18 mois)

La roadmap s'articule en 6 phases : fondations (M1-M2), donnees (M2-M3), MVP (M3-M5), pilote (M5-M6), lancement (M6-M8), croissance (M9-M18). Le pitch DJANTA du 24 juillet 2026 se situe en debut de phase MVP.

```mermaid
gantt
    title ExamBoost Togo — Roadmap 18 mois
    dateFormat  YYYY-MM-DD
    section M1-M2 Fondations
    Enquete terrain Lome        :a1, 2026-06-01, 30d
    Accord MEPST Togo           :a2, 2026-06-01, 30d
    Recrutement equipe 4 pers   :a3, 2026-06-01, 30d

    section M2-M3 Donnees
    OCR + annotation 1500 PDFs  :b1, 2026-07-01, 30d
    Calibration IRT initiale    :b2, 2026-07-15, 15d

    section M3-M5 MVP Flutter
    Flutter Android 5+          :c1, 2026-08-01, 60d
    Module SRS SM-2             :c2, 2026-08-01, 30d
    Simulation BEPC chrono      :c3, 2026-08-15, 30d
    Dashboard BKT               :c4, 2026-09-01, 30d

    section M5-M6 Pilote
    5 etablissements Lome       :d1, 2026-10-01, 30d
    300 eleves actifs           :d2, 2026-10-01, 30d

    section M6-M8 Lancement
    iOS app + App Store         :e1, 2026-11-01, 30d
    Mobile Money Flooz + TMoney :e2, 2026-11-15, 15d
    Play Store national         :e3, 2026-12-01, 30d

    section M9-M18 Croissance
    200 etablissements          :f1, 2027-01-01, 270d
    Expansion CEDEAO            :f2, 2027-06-01, 180d
```

| Phase | Mois | Jalon | KPI cible |
|---|---|---|---|
| Fondations | M1-M2 | Accord MEPST + equipe recrutee | 4 personnes a temps plein |
| Donnees | M2-M3 | 5000+ questions en base | Couverture 2010-2025 BEPC + BAC |
| MVP | M3-M5 | App Play Store interne (beta fermee) | 5 ecrans fonctionnels, 3 algos ML |
| Pilote | M5-M6 | 5 lycees pilotes Lome | 300 eleves actifs, +8 pts aux controles |
| Lancement | M6-M8 | Play Store public national | 5000 utilisateurs M12, retention >50 % |
| Croissance | M9-M18 | 200 etablissements partenaires | 50000 utilisateurs M18, +15 pts aux controles |

### Contraintes mobiles cibles

- **APK Android** < 25 Mo (optimisation images, fonts embarquees uniquement Outfit + Inter, R8/ProGuard active).
- **Compatibilite Android 5+** (API 21) — cible les Tecno Spark, Itel A series, Infinix Hot courants au Togo (40 % du parc, 4 Go RAM minimum).
- **iOS 12+** — cible iPhone 7+ et iPad 2017+ (compatibilite rear-facing camera pour OCR si ajoute plus tard).
- **Mode hors-ligne complet** : toutes les fonctionnalites sauf sync cloud et paiement Mobile Money fonctionnent sans reseau.
- **Mode donnees economiques** : pas de streaming video, images compressees WebP, requetes API batchees.

### Estimation des couts (mensuels)

| Service | Plan | Cout |
|---|---|---|
| Railway | Hobby | $5 |
| Railway Postgres | Inclus Hobby | $0 |
| Vercel | Hobby (free) | $0 |
| GitHub Actions | Free | $0 (2000 min/mois) |
| Domaine `.tg` | Annuel | ~$4/mois |
| Sentry | Developer (free) | $0 |
| PostHog | Open-source (free) | $0 |
| Anthropic Claude | Pay-as-you-go | $5-30 |
| AWS S3 | Free tier + | $1-5 |
| Cloudflare DNS | Free | $0 |
| **Total estime** | | **~$15-50/mois** |

Projection scaling : 1000 users ~$60/mois, 10 000 users ~$280/mois, 50 000 users ~$1300/mois. Claude API est le poste qui scale le plus vite — un cache Redis + quota par utilisateur (deja 30 questions/heure/user) limite le cout.

---

## 11. Monitoring

Le monitoring s'articule autour de quatre axes : disponibilite (health checks), erreurs (Sentry), performance (PostHog + Vercel Analytics), logs centralises (Railway + Vercel).

### Health endpoints (backend)

| Endpoint | Frequence suggeree | Alerte si |
|---|---|---|
| `/health` | 30 s | HTTP != 200 pendant > 2 min |
| `/health/ready` | 1 min | status != "ready" |
| `/health/stats` | 5 min | `users` < 1 apres seed |
| `/docs` | 1 h | HTTP != 200 |

Configurer un ping avec **UptimeRobot** (gratuit) ou **BetterUptime** :

```
URL     : https://examboost-togo.up.railway.app/health
Methode : GET
Expect  : 200
Timeout : 10s
Frequence : 5 min
Alerte  : email + Slack webhook
```

### Erreurs (Sentry)

1. Creer un projet Sentry (Python pour backend, Next.js pour landing, Flutter pour mobile).
2. Backend : `pip install sentry-sdk[fastapi]` + init dans `main.py`.
3. Landing : `npm install @sentry/nextjs` + `sentry.config.ts`.
4. Mobile : `flutter pub add sentry_flutter` + init dans `main.dart`.
5. Set `SENTRY_DSN` dans Railway, Vercel et compile-time Flutter.

### Performance (PostHog + Vercel Analytics)

- **Vercel Analytics** : built-in, gratuit. Visible dans Vercel > Analytics.
- **PostHog** : product analytics (funnels, retention, feature flags). SDK ajoute dans `landing/app/layout.tsx` et `lib/main.dart`.
- **Railway metrics** : CPU/RAM par service. Visible dans Railway > Service > Metrics.
- **Flutter Performance Overlay** : active en dev via `MaterialApp(showPerformanceOverlay: true)`.

### Logs centralises

- **Backend** : `railway logs --service examboost-backend --environment production`
- **Landing** : Vercel > Project > Logs (runtime + build)
- **CI/CD** : GitHub Actions > Workflow runs
- **Mobile** : logs centralises via `AppLogger` (lib/utils/app_logger.dart), envoi optionnel a Sentry en prod

Pour une centralisation, forwarder les logs Railway vers Logtail ou Loggly (via webhook). En staging, `LOG_LEVEL=debug` active les logs detailles.

### Backup base de donnees

- **Automatique** : Railway snapshots quotidiens (retention 7 jours en Hobby, 30 jours en Pro).
- **Manuel** : script `pg_dump` via `railway connect`.
- **Restore** : `psql $DATABASE_URL < backup_YYYYMMDD.sql` sur un environnement de test.
- **Cron GitHub Action** recommande : `0 3 * * *` (tous les jours a 03:00 UTC) avec webhook Railway.

### Disaster recovery

| Scenario | RTO | RPO | Action |
|---|---|---|---|
| Backend down | 5 min | 0 | Railway auto-restart (ON_FAILURE, 3x) |
| Backend deploie casse | 5 min | 0 | `./scripts/rollback_backend.sh` |
| DB corrompue | 30 min | 24 h | Restore depuis snapshot Railway |
| Region Railway down | 1 h | 24 h | Redeployer sur autre region (manuelle) |
| Vercel down | 30 min | 0 | Basculer DNS vers backup (Netlify) |
| GitHub down | 2 h | 0 | Railway peut redeployer depuis cache |

### Tests de reprise (quarterly)

- Restaurer un backup sur un environnement de test, verifier l'app.
- Simuler un deploiement casse (commit une erreur syntaxique) → tester le rollback.
- Verifier que `health_check.sh` detecte bien le probleme.

### Checklist pre-pitch (24 juillet 2026)

- [ ] Backend deploye en prod : `https://examboost-togo.up.railway.app/health` 200 OK
- [ ] Landing deployee en prod : `https://examboost-togo.vercel.app` 200 OK
- [ ] Domaine `examboost.tg` pointe vers Vercel + SSL actif
- [ ] Base seeded : `/health/stats` retourne > 0 questions
- [ ] CORS configure pour `https://examboost.tg` et `https://examboost-togo.vercel.app`
- [ ] `SECRET_KEY` en prod different de dev
- [ ] Sentry + PostHog branches (optionnel mais recommande)
- [ ] Backup DB automatique actif
- [ ] `health_check.sh` en cron UptimeRobot (5 min)
- [ ] Demo Flutter connectee au backend prod
- [ ] Test end-to-end : register → login → repondre → voir stats → tutor chat
- [ ] Plan B : APK Flutter fonctionnel offline (en cas de panne reseau pendant le pitch)

---

## References croisees

- **README principal** : `README.md` (vue d'ensemble projet, KPIs, roadmap)
- **Guide de contribution** : `docs/CONTRIBUTING.md` (setup, conventions, workflow Git)
- **Guide de deploiement detaille** : `docs/DEPLOYMENT_GUIDE.md` (infrastructure complete, scripts, disaster recovery)
- **Pitch deck detaille** : `docs/Pitch_Deck_10_slides.md` (slides 4 et 8 reprennent les diagrammes systeme et roadmap)
- **Q&A jury anticipe** : `docs/QA_jury_anticipe.md` (theme 3 Technologie & IA developpe les algos en profondeur)
- **Etude de faisabilite** : `docs/ExamBoost_Togo_Etude_Faisabilite_2025.pdf` (budget 246 400 USD, projections M18)
- **Cours theorique** : `docs/ExamBoost_Togo_Cours_Theorique_2025.pdf` (demonstrations mathematiques SM-2, BKT, IRT)
- **Plan strategique DJANTA** : `docs/ExamBoost_DJANTA_Plan_Strategique_2026.pdf` (echeance 24 juillet 2026, criteres jury)
- **Code source algorithmes** :
  - Flutter : `lib/services/srs_service.dart`, `lib/models/review_card.dart`, `lib/models/user.dart`
  - Python : `backend/services/irt_service.py`, `backend/services/bkt_service.py`, `backend/services/srs_service.py`, `backend/services/ml_service.py`
  - Pipeline OCR : `data_pipeline/run_pipeline.py` (orchestrateur), `data_pipeline/README.md`
  - ML training : `backend/scripts/ml_training/`, `backend/scripts/student_clustering/`, `backend/scripts/dkt_model/`, `backend/scripts/irt_calibration/`

---

*Document consolide par l'Agent BG (Session 4, Vague 1). Remplace les versions anterieures eparses (Architecture_Diagrams.md reste valide comme annexe visuelle). Derniere mise a jour : 1er juillet 2026.*
