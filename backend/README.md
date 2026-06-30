# ExamBoost Togo — Backend FastAPI

API REST pour la plateforme ExamBoost Togo (preparation BEPC / BAC).

Trois algorithmes pedagogiques au coeur du systeme :

- **IRT 3PL** (Item Response Theory) — calibration des questions
- **BKT** (Bayesian Knowledge Tracing) — suivi de la maitrise par competence
- **SM-2** (Spaced Repetition System) — planification des revisions
- **XGBoost** — prediction du score attendu a l'examen

> Miroir Python des modeles Flutter `lib/models/*` et services `lib/services/*`.

---

## Sommaire

- [Demarrage local](#demarrage-local)
- [Endpoints](#endpoints)
- [Algorithmes](#algorithmes)
- [Scripts](#scripts)
- [Tests](#tests)
- [Deploiement Railway](#deploiement-railway)
- [Variables d'environnement](#variables-denvironnement)

---

## Demarrage local

### Pre-requis

- Python 3.11+
- pip / venv

### Installation

```bash
cd backend

# Environnement virtuel
python -m venv venv
source venv/bin/activate        # Linux / macOS
# venv\Scripts\activate         # Windows

# Dependances
pip install -r requirements.txt

# Variables d'environnement (optionnel en dev)
cp .env.example .env

# Seed de la base (20 questions BEPC/BAC de demo)
python scripts/seed_db.py

# Lancement en mode dev (hot reload)
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

- Swagger UI : http://localhost:8000/docs
- ReDoc : http://localhost:8000/redoc
- OpenAPI JSON : http://localhost:8000/openapi.json
- Healthcheck : http://localhost:8000/health

---

## Endpoints

### Auth (`/auth`)

| Methode | Route           | Description                                  | Auth |
|---------|-----------------|----------------------------------------------|------|
| POST    | `/auth/register`| Cree un eleve, renvoie un JWT                 | non  |
| POST    | `/auth/login`   | Authentifie et renvoie un JWT                 | non  |
| GET     | `/auth/me`      | Profil de l'utilisateur courant               | oui  |

**Exemple** :

```bash
# Inscription
curl -X POST http://localhost:8000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "jean@test.tg",
    "password": "secret123",
    "nom": "Doe",
    "prenom": "Jean",
    "niveau_scolaire": "Terminale",
    "serie": "C"
  }'

# Reponse
{
  "access_token": "eyJhbGciOi...",
  "token_type": "bearer",
  "user_id": "abc123",
  "user": { "email": "jean@test.tg", "nom": "Doe", ... }
}
```

### Questions (`/questions`)

| Methode | Route                     | Description                            | Auth |
|---------|---------------------------|----------------------------------------|------|
| GET     | `/questions`              | Liste paginee avec filtres              | non  |
| GET     | `/questions/{id}`         | Detail d'une question                   | non  |
| GET     | `/questions/random/list`  | Tirage aleatoire (simulation)           | non  |
| POST    | `/questions`              | Cree une question (admin)               | admin|

Filtres disponibles sur `GET /questions` : `matiere`, `examen`, `serie`,
`competence_id`, `chapitre`, `limit` (1-200), `offset`.

### Sessions (`/sessions`)

| Methode | Route                        | Description                                | Auth |
|---------|------------------------------|--------------------------------------------|------|
| POST    | `/sessions`                  | Enregistre une reponse (SM-2 + BKT)         | non* |
| GET     | `/sessions/{user_id}/due`    | Cartes dues pour revision aujourd'hui       | non* |
| GET     | `/sessions/{user_id}/stats`  | Stats SM-2 (miroir de SrsStats Flutter)     | non* |

> (*) Authentification non exigee pour la demo — a activer en production.

**Exemple POST /sessions** :

```bash
curl -X POST http://localhost:8000/sessions \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "abc123",
    "question_id": "TG-BEPC-MATHS-2022-Q01",
    "quality": 4,
    "time_spent_sec": 35
  }'

# Reponse
{
  "user_id": "abc123",
  "question_id": "TG-BEPC-MATHS-2022-Q01",
  "quality": 4,
  "correct": true,
  "interval_days": 1,
  "easiness_factor": 2.6,
  "next_review_date": "2026-07-15T10:30:00Z",
  "bkt_update": {
    "competence_id": "TG-MATHS-EQ1D-001",
    "pL_before": 0.1,
    "pL_after": 0.3667,
    "mastered": false
  }
}
```

### Predictions

| Methode | Route                            | Description                                |
|---------|----------------------------------|--------------------------------------------|
| GET     | `/predict-score/{user_id}`       | Score attendu a l'examen (XGBoost ou BKT)   |
| GET     | `/predict-dropout/{user_id}`     | Probabilite de decrochage (mock regle metier)|

**Exemple** :

```bash
curl "http://localhost:8000/predict-score/abc123?examen=BEPC"

# Reponse
{
  "user_id": "abc123",
  "examen": "BEPC",
  "predicted_score": 12.5,
  "confidence": 0.65,
  "method": "heuristic",
  "breakdown": [
    {"matiere": "Mathematiques", "score_estime": 14.2, "pL_moyen": 0.71, "nb_questions": 12},
    {"matiere": "Francais",      "score_estime": 10.8, "pL_moyen": 0.54, "nb_questions": 8}
  ],
  "total_responses": 20
}
```

Strategie de prediction :
- < 100 reponses ou modele non entraîne -> **heuristique** (moyenne des P(L) × 20, confiance 0.3-0.7)
- >= 100 reponses et modele dispo -> **XGBoost** (confiance 0.85)

---

## Algorithmes

### IRT 3PL (`services/irt_service.py`)

```
P(theta) = c + (1 - c) * 1 / (1 + exp(-1.7 * a * (theta - b)))
```

- `a` : discrimination de l'item
- `b` : difficulte
- `c` : probabilite de deviner (pseudo-chance)
- `1.7` : constante d'echelle logistique (Birnbaum)

Inclut egalement :
- `estimate_theta(responses)` : maximum de vraisemblance
- `fisher_information(theta, a, b, c)` : information de Fisher (CAT)
- `calibrate_irt(df)` : py-irt si dispo, sinon fallback probit

### BKT (`services/bkt_service.py`)

Miroir exact de `lib/models/user.dart`.

```
Si correct :
    P(L|1) = P(L) * (1 - P(S)) / [ P(L) * (1 - P(S)) + (1 - P(L)) * P(G) ]
Sinon :
    P(L|0) = P(L) * P(S)     / [ P(L) * P(S)     + (1 - P(L)) * (1 - P(G)) ]

P(L_next) = P(L|obs) + (1 - P(L|obs)) * P(T)
```

Parametres par defaut : P(T)=0.20, P(S)=0.10, P(G)=0.20.
Seuil de maitrise : P(L) >= 0.85.

### SM-2 (`services/srs_service.py`)

Miroir exact de `lib/models/review_card.dart`.

```
Si q >= 3 (correct) :
    reps == 0 -> interval = 1
    reps == 1 -> interval = 6
    reps >= 2 -> interval = floor(interval * EF)
    reps += 1
Sinon :
    reps = 0, interval = 1

EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
EF' = max(EF', 1.3)

next_review_date = now + interval_days
```

### XGBoost (`services/ml_service.py`)

Features :

| # | Feature                  | Description                                |
|---|--------------------------|--------------------------------------------|
| 0 | pL_global                | Moyenne des P(L) toutes competences        |
| 1 | pL_maths                 | P(L) moyen en Mathematiques                |
| 2 | pL_fr                    | P(L) moyen en Francais                     |
| 3 | pL_sciences              | P(L) moyen en Sciences / SVT               |
| 4 | sessions_7j              | Nombre de sessions sur les 7 derniers jours|
| 5 | avg_time_per_q           | Temps moyen par question (sec)             |
| 6 | simulations_completed    | Nombre de simulations d'examen realisees    |
| 7 | last_score_simulation    | Score de la derniere simulation (0-20)      |

Cible : score sur 20 obtenu a l'examen blanc.

---

## Scripts

### 1. Seed de la base

```bash
python scripts/seed_db.py
```

Peuple la table `questions` avec `data/questions_seed.json` (20 questions
BEPC/BAC). Cree aussi un compte admin par defaut (`ADMIN_EMAIL`).

### 2. Calibration IRT

```bash
python scripts/calibrate_irt.py
```

Charge toutes les reponses collectees, calibre les parametres IRT (a, b, c)
de chaque question, et met a jour la table `questions`.
Tente `py-irt` (3PL) en premier ; fallback sur estimation `b = -probit(p_success)`.

### 3. Entrainement XGBoost

```bash
python scripts/train_score_model.py
```

Construit le dataset d'entraînement depuis la table `simulations` + historique
de reponses. Si trop peu de donnees reelles (< 20), genere un dataset
synthetique pour permettre une demo fonctionnelle.
Sauve le modele dans `services/models/score_predictor.joblib`.

---

## Tests

```bash
# Tous les tests
pytest tests/ -v

# Tests d'un module
pytest tests/test_irt.py -v

# Avec couverture
pytest tests/ --cov=. --cov-report=term-missing
```

Trois fichiers de tests :

- `tests/test_auth.py` — register / login / me (succes + erreurs)
- `tests/test_questions.py` — liste, filtres, detail, random, creation admin
- `tests/test_irt.py` — formule IRT 3PL, estimation theta, calibration, BKT (correct + incorrect), SM-2 (interval, EF, plancher 1.3)

---

## Deploiement Railway

### Etape 1 — Connecter le repo

1. Aller sur https://railway.app
2. **New Project** > **Deploy from GitHub repo**
3. Selectionner `djabelo712/ExamBoost-Togo`
4. Root Directory : `backend/`

### Etape 2 — Variables d'environnement

Dans l'onglet **Variables** du service Railway, ajouter :

| Variable                          | Valeur                                              |
|-----------------------------------|-----------------------------------------------------|
| `DATABASE_URL`                    | `${{Postgres.DATABASE_URL}}` (auto avec plugin PG)  |
| `SECRET_KEY`                      | `openssl rand -hex 32`                              |
| `ACCESS_TOKEN_EXPIRE_MINUTES`     | `10080` (7 jours)                                    |
| `CORS_ORIGINS`                    | `["https://examboost.tg"]`                           |
| `ADMIN_EMAIL`                     | `admin@examboost.tg`                                 |

### Etape 3 — Base de donnees + deploiement

1. **New** > **Database** > **PostgreSQL** (Railway provisionne automatiquement)
2. Le `Dockerfile` installe les dependances, fait le seed initial, et lance
   `uvicorn main:app --host 0.0.0.0 --port $PORT`
3. Healthcheck configure sur `/health` (voir `railway.json`)
4. Domaine public : `https://examboost-backend.up.railway.app/docs`

> Render : meme principe. Creer un **Web Service** depuis le repo, dossier
> racine `backend/`, build `pip install -r requirements.txt`,
> start `uvicorn main:app --host 0.0.0.0 --port $PORT`.

---

## Variables d'environnement

| Variable                        | Defaut                                              | Description                       |
|---------------------------------|-----------------------------------------------------|-----------------------------------|
| `DATABASE_URL`                  | `sqlite:///./examboost.db`                          | URL SQLAlchemy                    |
| `SECRET_KEY`                    | `change-me-...`                                     | Cle JWT (32+ caracteres)          |
| `ALGORITHM`                     | `HS256`                                             | Algorithme JWT                    |
| `ACCESS_TOKEN_EXPIRE_MINUTES`   | `10080` (7 jours)                                   | Duree de validite du token        |
| `CORS_ORIGINS`                  | `["*"]`                                             | Liste JSON ou CSV                 |
| `ADMIN_EMAIL`                   | `admin@examboost.tg`                                | Email admin par defaut            |
| `BKT_P_LEARN`                   | `0.20`                                              | P(T)                              |
| `BKT_P_SLIP`                    | `0.10`                                              | P(S)                              |
| `BKT_P_GUESS`                   | `0.20`                                              | P(G)                              |
| `BKT_MASTERY_THRESHOLD`         | `0.85`                                              | Seuil de maitrise                 |
| `MIN_RESPONSES_FOR_ML`          | `100`                                               | Seuil activation XGBoost          |

---

## Structure

```
backend/
├── README.md
├── requirements.txt
├── .env.example
├── .gitignore
├── Dockerfile
├── railway.json
├── main.py                 # FastAPI app + CORS + routers
├── config.py               # pydantic-settings
├── database.py             # SQLAlchemy engine + SessionLocal
├── models/
│   ├── __init__.py
│   ├── schemas.py          # Pydantic (UserCreate, QuestionOut, ...)
│   └── db_models.py        # ORM (User, Question, ReviewCard, Response, Simulation)
├── routers/
│   ├── __init__.py
│   ├── auth.py             # /auth/register, /auth/login, /auth/me
│   ├── questions.py        # /questions, /questions/{id}, /questions/random/list
│   ├── sessions.py         # /sessions, /sessions/{user_id}/due, /sessions/{user_id}/stats
│   └── predict.py          # /predict-score/{user_id}, /predict-dropout/{user_id}
├── services/
│   ├── __init__.py
│   ├── auth_service.py     # JWT + bcrypt
│   ├── irt_service.py      # IRT 3PL + calibration + theta MLE
│   ├── bkt_service.py      # BKT update
│   ├── srs_service.py      # SM-2 algorithm
│   └── ml_service.py       # XGBoost score + dropout
├── data/
│   └── questions_seed.json # 20 questions BEPC/BAC
├── scripts/
│   ├── __init__.py
│   ├── seed_db.py          # Peuple la base
│   ├── calibrate_irt.py    # Calibration IRT
│   └── train_score_model.py # Entrainement XGBoost
└── tests/
    ├── __init__.py
    ├── conftest.py
    ├── test_auth.py
    ├── test_questions.py
    └── test_irt.py
```

---

## Licence

MIT — Projet ExamBoost Togo.
