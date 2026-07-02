# Security Fixes — ExamBoost Togo Backend

- **Date** : 2 juillet 2026
- **Auteur** : Agent BY
- **Perimetre** : corrections documentaires des 19 findings de l'audit OWASP Top 10 (cf. `OWASP_AUDIT_REPORT.md`)

> Conformement aux contraintes de la vague, **aucun fichier source backend n'a ete modifie**. Chaque correction est presente ci-dessous sous forme de patch avant / apres, prete a etre appliquee par l'agent de wiring (ou l'equipe). Les seuls fichiers reellement crees sont :
> - `backend/middleware/security_headers.py` (nouveau)
> - `backend/middleware/input_validation.py` (nouveau)
> - `backend/requirements.txt` (etendu avec `bandit` et `safety`)

---

## Sommaire des fixes

| ID    | Severite  | Categorie OWASP | Fichier(s)                              | Resume                                        |
|-------|-----------|-----------------|-----------------------------------------|-----------------------------------------------|
| F-01  | Critique  | A02             | `config.py`                             | Refus demarrage si SECRET_KEY par defaut      |
| F-02  | Haute     | A02             | `main.py`, `routers/auth.py`            | Branchement rate limiting sur /auth/*         |
| F-03  | Moyenne   | A02             | `models/schemas.py`                     | Politique mot de passe renforcee              |
| F-04  | Moyenne   | A02             | `routers/auth.py`                       | Message register anti-enumeration             |
| F-05  | Moyenne   | A05             | `routers/admin.py`                      | Limite taille upload JSON                     |
| F-06  | Critique  | A01             | `routers/sessions.py`                   | Auth + ownership sur POST /sessions           |
| F-07  | Critique  | A01             | `routers/sessions.py`                   | Auth sur GET /sessions/{user_id}/*            |
| F-08  | Critique  | A01             | `routers/predict.py`                    | Auth sur /predict-score et /predict-dropout   |
| F-09  | Haute     | A01             | `routers/classroom.py`                  | Auth enseignant sur /classroom/create         |
| F-10  | Haute     | A01             | `routers/classroom.py`                  | Auth sur /classroom/{code}/results            |
| F-11  | Haute     | A01             | `routers/classroom.py`                  | Auth enseignant sur /classroom/{code}/end     |
| F-12  | Moyenne   | A01             | `routers/classroom.py`                  | Auth admin sur /classroom/cleanup             |
| F-13  | Moyenne   | A01             | `routers/classroom.py`                  | Auth admin sur /classroom (debug)             |
| F-14  | Haute     | A06             | `config.py`, `main.py`                  | CORS restrictif en prod                       |
| F-15  | Moyenne   | A06             | `routers/sync.py`                       | Message d'erreur generique sur /sync/health   |
| F-16  | Haute     | A09             | `requirements.txt`                      | Upgrade python-jose                           |
| F-17  | Moyenne   | A09             | `requirements.txt`                      | Upgrade python-multipart                      |
| F-18  | Haute     | A10             | `routers/auth.py`                       | Logs authentification                         |
| F-19  | Moyenne   | A10             | `services/admin_service.py`             | print -> logging                              |
| F-20  | Moyenne   | A06/A07         | `main.py`                               | Branchement middlewares fournis               |
| F-21  | Moyenne   | A06             | `main.py`                               | Desactivation /docs en prod                   |

---

## F-01 — SECRET_KEY par defaut en dur (A02-CRIT-01)

### Avant — `backend/config.py` (ligne 50)
```python
SECRET_KEY: str = "change-me-in-production-please-use-a-32-char-min-secret"
```

### Apres
```python
# Cle JWT : OBLIGATOIRE en production. Une valeur par defaut n'est toleree
# qu'en dev local (pour que `uvicorn main:app --reload` fonctionne sans .env).
_DEFAULT_SECRET_KEY = "dev-only-DO-NOT-USE-IN-PROD-32chars-minimum!!"

SECRET_KEY: str = _DEFAULT_SECRET_KEY

@field_validator("SECRET_KEY", mode="after")
@classmethod
def _validate_secret_key(cls, v: str) -> str:
    """Refuse le demarrage si la cle par defaut est utilisee en prod."""
    from os import environ
    env = environ.get("ENV", environ.get("APP_ENV", "dev")).lower()
    if v == _DEFAULT_SECRET_KEY and env in ("prod", "production"):
        raise ValueError(
            "SECRET_KEY doit etre definie via la variable d'environnement "
            "en production (32 caracteres minimum, aleatoire)."
        )
    if len(v) < 32:
        raise ValueError("SECRET_KEY doit faire au moins 32 caracteres.")
    return v
```

### Justification
Le secret par defaut est public dans le repo GitHub. Si l'operateur oublie de le surcharger en prod, n'importe qui peut forger des JWT valides et se connecter en admin. Le validator leve une exception au demarrage en prod, et verifie la longueur minimale (32 octets = 256 bits pour HS256).

---

## F-02 — Rate limiting non branche sur /auth/* (A02-HIGH-01)

### Avant — `backend/main.py`
```python
from routers import auth, predict, questions, sessions, sync
...
app.include_router(auth.router, prefix="/auth", tags=["auth"])
```

### Apres — `backend/main.py`
```python
from rate_limiter import setup_rate_limiting
from routers import auth, predict, questions, sessions, sync

# A appeler AVANT l'inclusion des routers
setup_rate_limiting(app)
```

### Apres — `backend/routers/auth.py`
```python
from rate_limiter import limiter
from fastapi import Request

@router.post("/register", ...)
@limiter.limit("10/minute")
def register(request: Request, payload: schemas.UserCreate, db: Session = Depends(get_db)):
    ...

@router.post("/login", ...)
@limiter.limit("10/minute")
def login(request: Request, payload: schemas.UserLogin, db: Session = Depends(get_db)):
    ...
```

### Justification
`rate_limiter.py` (Agent AU) definissait `rate_limit_auth()` mais n'etait jamais branche. La limite de 10 tentatives/min/IP ralentit le bruteforce. En prod avec Redis, les compteurs sont partages entre workers. Le parametre `request: Request` est requis par slowapi pour extraire l'IP.

---

## F-03 — Politique mot de passe trop faible (A02-MED-02)

### Avant — `backend/models/schemas.py` (ligne 20)
```python
password: str = Field(..., min_length=6, max_length=128)
```

### Apres
```python
password: str = Field(
    ...,
    min_length=8,
    max_length=128,
    description="8 caracteres min, dont au moins 1 lettre et 1 chiffre.",
    pattern=r"^(?=.*[A-Za-z])(?=.*\d).{8,}$",
)

@field_validator("password")
@classmethod
def _no_common_passwords(cls, v: str) -> str:
    """Rejette les mots de passe triviaux."""
    commons = {"password", "12345678", "examboost", "toumodi", "lome2024"}
    if v.lower() in commons:
        raise ValueError("Mot de passe trop commun.")
    return v
```

### Justification
6 caracteres est cassable en quelques secondes par bruteforce offline. 8 caracteres avec complexite minimale (lettre + chiffre) reste atteignable pour des eleves (memorisable) tout en resitant aux attaques dictionnaire basiques. La liste `commons` peut etre etendue.

---

## F-04 — Enumeration d'utilisateurs via /auth/register (A02-MED-03)

### Avant — `backend/routers/auth.py` (ligne 100)
```python
if existing is not None:
    raise HTTPException(
        status_code=status.HTTP_409_CONFLICT,
        detail="Un compte existe deja avec cet email",
    )
```

### Apres
```python
if existing is not None:
    # Message generique pour ne pas reveler qu'un compte existe.
    raise HTTPException(
        status_code=status.HTTP_409_CONFLICT,
        detail="Inscription impossible avec ces informations.",
    )
```

### Justification
Le message original permet a un attaquant de dresser la liste des emails inscrits en faisant varier l'input. Le message generique ne leve pas d'ambiguite. Cote UX, l'eleve sait deja s'il a un compte ou non.

---

## F-05 — Upload JSON sans limite de taille (A05-MED-01)

### Avant — `backend/routers/admin.py` (ligne 304)
```python
raw = await file.read()
data = json.loads(raw.decode("utf-8"))
```

### Apres
```python
MAX_UPLOAD_BYTES = 5 * 1024 * 1024  # 5 Mo

raw = await file.read()
if len(raw) > MAX_UPLOAD_BYTES:
    raise HTTPException(
        status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
        detail=f"Fichier trop volumineux (max {MAX_UPLOAD_BYTES // 1024 // 1024} Mo).",
    )
data = json.loads(raw.decode("utf-8"))
```

### Justification
Sans limite, un attaquant (admin compromis ou admin malveillant) peut envoyer un fichier de 1 Go et provoquer un OOM du processus. 5 Mo suffit largement pour ~10 000 questions JSON.

---

## F-06 — POST /sessions sans auth ni ownership (A01-CRIT-01)

### Avant — `backend/routers/sessions.py` (ligne 72)
```python
def record_session(payload: schemas.SessionIn, db: Session = Depends(get_db)):
    user = db.get(User, payload.user_id)
    ...
    card = _get_or_create_card(db, payload.user_id, payload.question_id)
```

### Apres — Option A (preferred) : retirer `user_id` du payload
```python
def record_session(
    payload: schemas.SessionIn,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    user = current_user  # user_id vient du JWT, pas du payload
    ...
    card = _get_or_create_card(db, current_user.id, payload.question_id)
```

Et dans `schemas.py`, retirer `user_id: str` de `SessionIn` (utiliser uniquement `question_id`).

### Apres — Option B (compatibilite ascendante) : verifier ownership
```python
def record_session(
    payload: schemas.SessionIn,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if payload.user_id != current_user.id:
        # Log + 403
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Vous ne pouvez enregistrer des sessions que pour votre compte.",
        )
    user = current_user
```

### Justification
Option A est preferable (principe de minimisation : le client n'a pas a fournir son propre ID, le JWT est la source de verite). Option B est utile si l'app Flutter envoie deja `user_id` et qu'on ne veut pas casser la compat. L'Option A sera appliquee par l'agent de wiring.

---

## F-07 — GET /sessions/{user_id}/* sans auth (A01-CRIT-02)

### Avant — `backend/routers/sessions.py` (lignes 177, 221)
```python
def get_due_cards(
    user_id: str,
    limit: int = 20,
    db: Session = Depends(get_db),
):
    ...

def get_user_stats(user_id: str, db: Session = Depends(get_db)):
    ...
```

### Apres
```python
@router.get("/me/due", ...)  # l'ID vient du JWT
def get_my_due_cards(
    limit: int = 20,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return _get_due_cards(db, current_user.id, limit)

@router.get("/me/stats", ...)
def get_my_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return _get_user_stats(db, current_user.id)
```

### Justification
Le path param `user_id` permettait a n'importe qui de consulter les cartes dues d'un autre eleve. En passant a `/me/due` et `/me/stats`, l'ID est extrait du JWT et n'est plus forgeable. Les anciennes routes doivent etre deprecation-protected (404) ou redirigees vers `/me/*`.

---

## F-08 — GET /predict-* sans auth (A01-CRIT-03)

### Avant — `backend/routers/predict.py` (lignes 121, 214)
```python
def predict_score(
    user_id: str,
    examen: str = Query("BEPC", ...),
    db: Session = Depends(get_db),
):
    user = db.get(User, user_id)
    ...

def predict_dropout_route(user_id: str, db: Session = Depends(get_db)):
    user = db.get(User, user_id)
    ...
```

### Apres
```python
@router.get("/predict-score/me", ...)
def predict_my_score(
    examen: str = Query("BEPC", ...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return _compute_predict_score(db, current_user, examen)

@router.get("/predict-dropout/me", ...)
def predict_my_dropout(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return _compute_predict_dropout(db, current_user)
```

### Justification
Idem F-07. Le BKT map (`bkt_maitrise`) et le score predit sont des donnees pedagogiques sensibles (article 9, loi 2019-014). L'acces doit etre limite a l'utilisateur lui-meme. Un admin peut consulter via un endpoint dedie `/predict-score/{user_id}` protege par `get_admin_user` (a ajouter si besoin cote enseignant).

---

## F-09 — POST /classroom/create sans auth (A01-HIGH-01)

### Avant — `backend/routers/classroom.py` (ligne 231)
```python
async def create_session(payload: SessionCreateRequest) -> Dict[str, Any]:
    code = classroom_manager.create_session(payload)
    ...
```

### Apres
```python
from routers.auth import get_current_user

async def create_session(
    payload: SessionCreateRequest,
    current_user: User = Depends(get_current_user),
) -> Dict[str, Any]:
    # Seul un utilisateur authentifie peut creer une session.
    # Pour le pitch DJANTA : n'importe quel user authentifie.
    # Pour la prod : ajouter un flag `is_teacher` sur User et le verifier ici.
    code = classroom_manager.create_session(payload, creator_id=current_user.id)
    ...
```

Etendre `ClassroomManager.create_session` pour stocker `creator_id` sur la session, afin de pouvoir verifier les droits sur `/end` (F-11).

### Justification
Sans auth, un attaquant peut creer des milliers de sessions en boucle (DDoS RAM). Avec auth + rate limiting, le risque est contenu. Pour la prod, un veritable role "enseignant" est necessaire (a ajouter au modele `User`).

---

## F-10 — GET /classroom/{code}/results sans auth (A01-HIGH-02)

### Avant — `backend/routers/classroom.py` (ligne 257)
```python
async def get_results(code: str) -> SessionResultsOut:
    results = classroom_manager.get_results(code)
    ...
```

### Apres
```python
async def get_results(
    code: str,
    current_user: User = Depends(get_current_user),
) -> SessionResultsOut:
    session = classroom_manager.get_session(code)
    if session is None:
        raise HTTPException(404, "Session introuvable ou terminee.")
    # Autorise : le createur (enseignant) OU un joueur ayant rejoint la session.
    is_creator = session.creator_id == current_user.id
    is_player = any(
        p.user_id == current_user.id for p in session.players.values()
    )
    if not (is_creator or is_player):
        raise HTTPException(403, "Vous n'avez pas acces a cette session.")
    results = classroom_manager.get_results(code)
    ...
```

### Justification
Le classement contient les `player_name` (souvent le nom reel des eleves) et les reponses. Avec un code a 6 chiffres (1M combinaisons) et pas de rate limit, un brute-force est realiste. L'auth + la verification d'appartenance ferment la porte.

### Complement
Augmenter l'entropie du `session_code` : passer de 6 chiffres a 8 caracteres alphanumeriques (36^8 = 2.8 milliards). A modifier dans `services/classroom_manager.py`.

---

## F-11 — POST /classroom/{code}/end sans auth (A01-HIGH-03)

### Avant — `backend/routers/classroom.py` (ligne 278)
```python
async def end_session(code: str) -> SessionResultsOut:
    results = classroom_manager.end_session(code)
    ...
```

### Apres
```python
async def end_session(
    code: str,
    current_user: User = Depends(get_current_user),
) -> SessionResultsOut:
    session = classroom_manager.get_session(code)
    if session is None:
        raise HTTPException(404, "Session introuvable.")
    if session.creator_id != current_user.id:
        raise HTTPException(403, "Seul le createur peut terminer la session.")
    results = classroom_manager.end_session(code)
    ...
```

### Justification
Sans cette verification, n'importe qui peut terminer une session en cours (sabotage de cours en classe).

---

## F-12 — POST /classroom/cleanup sans auth (A01-MED-01)

### Avant — `backend/routers/classroom.py` (ligne 298)
```python
async def cleanup_sessions() -> Dict[str, Any]:
    classroom_manager.cleanup()
    ...
```

### Apres
```python
async def cleanup_sessions(
    admin: User = Depends(get_admin_user),
) -> Dict[str, Any]:
    classroom_manager.cleanup()
    ...
```

### Justification
Endpoint de maintenance : doit etre reserve aux admins. Sans protection, il peut etre appele en boucle pour perturber le suivi des sessions actives.

---

## F-13 — GET /classroom debug sans auth (A01-MED-02)

### Avant — `backend/routers/classroom.py` (ligne 311)
```python
async def list_sessions() -> Dict[str, Any]:
    """Liste les sessions actives (debug/admin uniquement)."""
    return {
        "count": len(classroom_manager.sessions),
        "sessions": [
            classroom_manager.get_status(code).model_dump(mode="json")
            for code in classroom_manager.sessions
        ],
    }
```

### Apres
```python
async def list_sessions(
    admin: User = Depends(get_admin_user),
) -> Dict[str, Any]:
    """Liste les sessions actives (admin uniquement)."""
    return {
        "count": len(classroom_manager.sessions),
        "sessions": [
            classroom_manager.get_status(code).model_dump(mode="json")
            for code in classroom_manager.sessions
        ],
    }
```

Mieux : **supprimer cet endpoint en production** (il n'a d'interet qu'en dev).

### Justification
L'endpoint exposait tous les codes de sessions actives, facilitant les attaques F-10 / F-11.

---

## F-14 — CORS trop permissif (A06-HIGH-01)

### Avant — `backend/config.py` (ligne 56) + `backend/main.py` (ligne 58)
```python
# config.py
CORS_ORIGINS: List[str] = ["*"]

# main.py
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

### Apres — `backend/config.py`
```python
# En dev : localhost Flutter web + app. En prod : domaines explicites.
CORS_ORIGINS: List[str] = [
    "http://localhost:8080",   # Flutter web dev
    "http://localhost:3000",
]

@field_validator("CORS_ORIGINS", mode="after")
@classmethod
def _validate_cors(cls, v: List[str]) -> List[str]:
    from os import environ
    env = environ.get("ENV", environ.get("APP_ENV", "dev")).lower()
    if env in ("prod", "production") and ("*" in v):
        raise ValueError(
            "CORS_ORIGINS ne peut pas contenir '*' en production. "
            "Listez explicitement les domaines autorises."
        )
    return v
```

### Apres — `backend/main.py`
```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "PATCH"],  # pas "*"
    allow_headers=["Authorization", "Content-Type", "X-Requested-With"],
    expose_headers=["X-RateLimit-Remaining", "Retry-After"],
)
```

### Justification
`allow_origins=["*"]` + `allow_credentials=True` est interdit par la spec CORS et transforme Starlette en reflecteur d'origin : n'importe quel site peut appeler l'API avec les credentials de l'utilisateur. En prod, on liste explicitement les domaines (ex: `https://app.examboost.tg`). `allow_methods` et `allow_headers` sont restreints au minimum necessaire.

---

## F-15 — Fuite d'exception dans /sync/health (A06-MED-02)

### Avant — `backend/routers/sync.py` (ligne 200)
```python
def sync_health():
    try:
        sync_service.ensure_sync_tables()
        return {"status": "ok", "tables": "ready"}
    except Exception as e:
        return {"status": "error", "detail": str(e)}
```

### Apres
```python
import logging

_logger = logging.getLogger(__name__)

def sync_health():
    try:
        sync_service.ensure_sync_tables()
        return {"status": "ok", "tables": "ready"}
    except Exception as e:
        # On logge l'erreur cote serveur sans exposer le detail au client.
        _logger.exception("sync_health check failed")
        return {"status": "error", "detail": "Internal error"}
```

### Justification
`str(e)` peut contenir des noms de tables, des messages SQLAlchemy, voire des chemins de fichiers. C'est une fuite d'information qui aide un attaquant a cartographier l'infra. On logge l'erreur complete cote serveur et on renvoie un message generique.

---

## F-16 — python-jose vulnerable (A09-HIGH-01)

### Avant — `backend/requirements.txt` (ligne 12)
```
python-jose[cryptography]==3.3.0
```

### Apres
```
python-jose[cryptography]==3.4.0
```

Alternative (si la migration est souhaitee) :
```
# Remplacer python-jose par pyjwt, plus maintenu :
# PyJWT==2.9.0
# cryptography==43.0.0
```

### Justification
`python-jose 3.3.0` est affecte par CVE-2024-33664 (DoS) et CVE-2024-33663 (confusion de cle si `verify_aud=False`). L'usage actuel precise `algorithms=[settings.ALGORITHM]`, ce qui mitigue la confusion, mais le DoS reste possible. Upgrade vers 3.4.0 ou migration vers `PyJWT` (plus actif) recommande.

---

## F-17 — python-multipart vulnerable (A09-MED-01)

### Avant — `backend/requirements.txt` (ligne 14)
```
python-multipart==0.0.9
```

### Apres
```
python-multipart>=0.0.18
```

### Justification
CVE-2024-24762 (ReDoS sur le parsing form-data). Affecte `routers/admin.py` (upload) et tout endpoint `UploadFile`. Upgrade vers 0.0.18+ requis.

---

## F-18 — Absence de logs d'authentification (A10-HIGH-01)

### Avant — `backend/routers/auth.py`
Aucun log dans `register` et `login`.

### Apres — Creer un module `backend/security/audit_log.py`
```python
"""audit_log.py — Logging dedie aux evenements de securite."""
import logging
from typing import Optional

audit_logger = logging.getLogger("examboost.audit")

def log_auth_event(
    event: str,               # "login" | "register" | "logout" | "token_invalid"
    user_id: Optional[str],   # None si echec avant identification
    ip: str,                  # request.client.host
    success: bool,
    **extra,
) -> None:
    audit_logger.info(
        "AUTH_EVENT event=%s user_id=%s ip=%s success=%s %s",
        event,
        user_id or "-",
        ip,
        success,
        " ".join(f"{k}={v}" for k, v in extra.items()),
    )
```

### Apres — `backend/routers/auth.py`
```python
from security.audit_log import log_auth_event

@router.post("/login", ...)
@limiter.limit("10/minute")
def login(
    request: Request,
    payload: schemas.UserLogin,
    db: Session = Depends(get_db),
):
    ip = request.client.host if request.client else "-"
    user = db.execute(
        select(User).where(User.email == payload.email.lower())
    ).scalar_one_or_none()

    if user is None or not auth_service.verify_password(payload.password, user.password_hash):
        log_auth_event("login", None, ip, success=False, reason="bad_credentials")
        raise HTTPException(...)

    log_auth_event("login", user.id, ip, success=True)
    token = auth_service.create_access_token(...)
    ...
```

### Justification
Sans logs d'auth, on ne peut pas detecter un bruteforce, une attaque sur les comptes admin, ou une utilisation anormale (login depuis 10 IP differentes en 1 heure). Le format JSON-structured est compatible avec n'importe quel agregateur de logs (Loki, ELK, Datadog).

---

## F-19 — print() au lieu de logging (A10-MED-02)

### Avant — `backend/services/admin_service.py` (lignes 85, 561)
```python
print(f"[admin_service] Impossible de creer admin_action_logs: {exc}")
...
print(f"[admin_service] log_action failed: {exc}")
```

### Apres
```python
import logging
_logger = logging.getLogger(__name__)
...
_logger.warning("Impossible de creer admin_action_logs: %s", exc, exc_info=True)
...
_logger.warning("log_action failed: %s", exc, exc_info=True)
```

### Justification
`print()` n'est pas structure, n'a pas de niveau (INFO/WARN/ERROR), n'est pas filtrable, et part sur stdout au lieu du handler dedie. `logging` permet le routage vers fichier, syslog, ou agregateur.

---

## F-20 — Branchement des middlewares fournis (A06-MED-03 + A07-MED-01)

### Avant — `backend/main.py`
Aucun middleware de securite (hors CORS).

### Apres — `backend/main.py`
```python
from middleware.security_headers import SecurityHeadersMiddleware
from middleware.input_validation import register_input_sanitizers

app.add_middleware(SecurityHeadersMiddleware)
register_input_sanitizers(app)
```

### Justification
Les middlewares `security_headers.py` et `input_validation.py` (fournis dans cette vague) ajoutent les headers CSP/HSTS/X-Frame-Options et une sanitization systematique des entrees. Leur branchement est documente dans les docstrings respectifs.

---

## F-21 — Desactivation /docs en prod (A06-MED-01)

### Avant — `backend/main.py`
```python
app = FastAPI(
    title="ExamBoost Togo API",
    ...
)
```

### Apres — `backend/main.py`
```python
import os
DEBUG = os.getenv("DEBUG", "false").lower() in ("1", "true", "yes")

app = FastAPI(
    title="ExamBoost Togo API",
    ...
    docs_url="/docs" if DEBUG else None,
    redoc_url="/redoc" if DEBUG else None,
    openapi_url="/openapi.json" if DEBUG else None,
)
```

### Justification
`/docs`, `/redoc` et `/openapi.json` exposent la structure complete de l'API en production. C'est utile en dev mais aide un attaquant en prod. On les desactive sauf si `DEBUG=true`.

---

## Note sur l'application des fixes

Conformement aux contraintes de la vague :
- **Aucun fichier source backend n'a ete modifie** par cet agent.
- Les patches ci-dessus sont prets a etre appliques par l'agent de wiring ou l'equipe.
- Les deux middlewares `security_headers.py` et `input_validation.py` sont crees dans `backend/middleware/` (F-20).
- Le `requirements.txt` est etendu avec `bandit` et `safety` (cf. F-16/F-17 pour les upgrades effectives des packages vulnérables — non appliquees ici car hors perimetre "modification requirements structurelle" mais recommandees).

## Verification post-application

Apres application de F-01 a F-21, lancer :

```bash
cd backend
# SAST
bandit -r . -ll -x ./tests,./.venv
# SCA
safety check --full-report
# Tests fonctionnels
pytest -x
# Manual smoke
uvicorn main:app --reload  # dev seulement
curl -i http://localhost:8000/health
curl -i http://localhost:8000/sessions/me/due   # doit renvoyer 401 sans JWT
```

Tous les `bandit` high/medium doivent etre resolus. Aucun `safety` flag ne doit rester.
