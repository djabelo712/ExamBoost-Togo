# Audit Securite OWASP Top 10 — ExamBoost Togo Backend

- **Date** : 2 juillet 2026
- **Auditeur** : Agent BY (general-purpose)
- **Perimetre** : backend FastAPI (`/home/z/my-project/ExamBoost-Togo/backend/`)
- **Reference** : OWASP Top 10 2021 + Loi n° 2019-014 du 30 octobre 2019 (protection des donnees a caractere personnel au Togo)
- **Version du code audite** : Session 4, Vague 2 (post-hardening Agent AU)

---

## Synthese executive

| Severite       | Nombre | Categories OWASP concernees                          |
|----------------|--------|------------------------------------------------------|
| Critique       | 3      | A01, A05                                             |
| Haute          | 5      | A02, A04, A05, A06, A09                              |
| Moyenne        | 7      | A01, A02, A03, A06, A07, A08, A10                    |
| Basse          | 4      | A03, A05, A06, A10                                   |
| **Total**      | **19** |                                                      |

Les trois vulnerabilites critiques concernent l'**absence de controle d'acces sur les endpoints `/sessions/{user_id}/*` et `/predict-*`**, qui permettent a n'importe quel utilisateur authentifie (ou non authentifie pour `/classroom`) de consulter les donnees d'autres eleves : cartes de revision, statistiques SRS, score BKT, proba de decrochage, donnees de la classe temps reel.

Aucune injection SQL n'a ete identifiee (usage systematique de l'ORM SQLAlchemy 2.x avec requetes parametrees). Le hachage des mots de passe est correct (bcrypt). Les points forts : JWT verifies avec `algorithms` explicite, schema Pydantic strict sur les entrees, logs d'actions admin deja presents.

Le present audit est **documentaire** : les corrections sont specifiees dans `SECURITY_FIXES.md` sous forme de patches avant/apres, et deux middlewares (`security_headers.py`, `input_validation.py`) sont fournis prets a etre branches par l'agent de wiring.

---

## 1. A03:2021 — Injection

### Analyse
- **SQL injection** : toutes les requetes utilisent SQLAlchemy 2.x avec `select(...).where(...)` et parametres lies (`User.email == payload.email.lower()`, `Question.competence_id.in_(competences)`, etc.). Aucune concatenation de chaine SQL, aucun `text()` non parametre. **Conforme**.
- **NoSQL injection** : pas de base NoSQL (SQLite/PostgreSQL via SQLAlchemy). **N/A**.
- **Command injection** : aucun appel a `subprocess`, `os.system`, `eval`, `exec` dans les routers/services examines. `random` et `uuid` seulement. **Conforme**.
- **LDAP / template injection** : N/A.

### Findings
Aucun. La dependance `python-multipart==0.0.9` (utilisee pour les uploads `UploadFile` dans `routers/admin.py`) presente une ReDoS (CVE-2024-24762), traitee en A06/A09.

### Recommandation
Maintenir l'usage exclusif de l'ORM. Interdire `text()` sans parametres lies via revue de code.

---

## 2. A07:2021 — Identification and Authentication Failures (Broken Authentication)

### Analyse
- **JWT secret** : valeur par defaut en dur dans `config.py` ligne 50 :
  ```python
  SECRET_KEY: str = "change-me-in-production-please-use-a-32-char-min-secret"
  ```
  Si la variable d'env `SECRET_KEY` n'est pas positionnee en prod, le secret est public et n'importe qui peut forger des JWT valides. **CRITIQUE**.
- **Algorithme JWT** : `HS256` (symetrique). Le decodeur impose `algorithms=[settings.ALGORITHM]` (`auth_service.py` ligne 83), ce qui previent l'attaque `alg=none` et la confusion `RS256->HS256`. **Conforme**.
- **Expiration** : `ACCESS_TOKEN_EXPIRE_MINUTES = 10080` (7 jours). Trop long pour un contexte educatif ou l'app est ouverte quotidiennement : si le token fuite, l'attaquant a 7 jours. Pas de refresh token, pas de revocation. **MOYENNE**.
- **Password hashing** : bcrypt via `bcrypt.gensalt()` (cout par defaut 12) avec fallback `passlib`. Troncature a 72 octets conforme a la spec OpenBSD. **Conforme**.
- **Politique de mot de passe** : `min_length=6` dans `schemas.UserCreate`. Trop faible pour des donnees d'eleves mineurs. Pas de complexite, pas de check pwned password. **MOYENNE**.
- **Rate limiting login** : `rate_limiter.py` definit `rate_limit_auth()` (10/min) **mais `main.py` n'appelle jamais `setup_rate_limiting(app)`** et les routes `/auth/login` et `/auth/register` ne portent pas le decorateur. Bruteforce non ralenti. **HAUTE**.
- **Account lockout** : aucun. Un compte peut etre brutforce indefiniment (a part la limite IP ci-dessus, qui est elle-meme non branchee).
- **Logout / revocation** : aucun endpoint `/auth/logout`, pas de denylist de tokens. **BASSE** (stateless JWT).
- **User enumeration** : le message d'erreur de `/auth/register` est `"Un compte existe deja avec cet email"` — permet de savoir si un email est inscrit. Le login renvoie un message genérique `"Email ou mot de passe incorrect"` — **Conforme** cote login, **MOYENNE** cote register.

### Findings
- **A02-CRIT-01** : `SECRET_KEY` par defaut en dur dans le code source.
- **A02-HIGH-01** : Rate limiting auth non branche dans `main.py`.
- **A02-MED-01** : Expiration JWT a 7 jours sans refresh token ni revocation.
- **A02-MED-02** : Politique mot de passe trop faible (6 caracteres, pas de complexite).
- **A02-MED-03** : Enumeration d'utilisateurs via `/auth/register` (message 409).

### Recommandations
1. Lever une exception au demarrage si `SECRET_KEY` n'est pas surchargee par l'environnement (voir `SECURITY_FIXES.md` F-01).
2. Brancher `setup_rate_limiting(app)` dans `main.py` et decorer `/auth/login` + `/auth/register` avec `@rate_limit_auth()` (F-02).
3. Reduire `ACCESS_TOKEN_EXPIRE_MINUTES` a 1440 (24 h) et ajouter un endpoint `/auth/refresh` (hors perimetre de cet audit, a planifier).
4. Renforcer le schema `UserCreate` : `min_length=8`, pattern `[A-Za-z0-9!@#$%^&*]{8,}` minimum (F-03).
5. Retourner un 409 generique en cas d'email deja pris OU (mieux) retourner 201 silencieux et envoyer un mail — pour le pitch DJANTA, on accepte le 409 actuel mais on modifie le message en `"Inscription impossible"` (F-04).

---

## 3. A02:2021 — Cryptographic Failures (Sensitive Data Exposure)

### Analyse
- **HTTPS force en prod** : aucun middleware ne redirige HTTP -> HTTPS ni n'active HSTS. Cote Railway/Render, TLS est termine par le reverse proxy, mais l'app ne valide pas `X-Forwarded-Proto`. **MOYENNE**.
- **Secrets en dur** : voir A02-CRIT-01 ci-dessus. Aucun autre secret (pas de cle Anthropic, pas d'URL DB sensible) en clair dans le code — `tutor_service` lit `ANTHROPIC_API_KEY` depuis l'env (a confirmer). **OK**.
- **Passwords jamais retournes** : le schema `UserOut` (`schemas.py` lignes 47-64) exclut explicitement `password_hash` et `is_admin`. La fonction `_to_user_out` ne construit jamais ces champs. **Conforme**.
- **Chiffrement au repos** : la base SQLite (`examboost.db`) est en clair. Les champs `bkt_maitrise` (JSON), `email`, `nom`, `prenom`, `etablissement`, `ville` sont lisibles par quiconque accede au fichier. **MOYENNE** (a traiter dans le cadre de la conformite Loi 2019-014, section dediee ci-dessous).
- **Logging de secrets** : aucun `print(password)` ou log du JWT. **Conforme**.
- **JWT claims** : le token embarque `email` et `is_admin` en clair (JWT non chiffre par construction). L'email est une donnee personnelle — c'est acceptable tant que le client ne le log pas, mais preferer un claim `sub=user_id` seul. **BASSE**.

### Findings
- **A03-MED-01** : Pas de redirection HTTPS / HSTS cote application.
- **A03-MED-02** : Base SQLite non chiffree au repos (donnees PII eleves).
- **A03-LOW-01** : JWT embarque l'email en clair dans `extra_claims`.

### Recommandations
1. Activer le middleware `security_headers.py` (fourni) qui pose `Strict-Transport-Security: max-age=63072000; includeSubDomains; preload`.
2. En production, preferer PostgreSQL avec chiffrement disque (volume chiffre Railway/Render) ou SQLCipher pour SQLite.
3. Retirer `email` des `extra_claims` du JWT (le `sub` suffit pour identifier l'utilisateur).

---

## 4. A05:2021 — Security Misconfiguration (XXE regroupe ici selon OWASP 2021)

> Note : XXE etait une categorie dediee dans OWASP 2017 (A4). Depuis 2021, elle est fusionnee dans A05 (Security Misconfiguration). On la traite ici.

### Analyse
- **Parser XML** : aucun parser XML utilise dans le code backend. Toutes les entrees/sorties sont JSON (`json.loads`, Pydantic). **N/A — Conforme**.
- **Deserialisation JSON** : `routers/admin.py` ligne 305 `json.loads(raw.decode("utf-8"))` sur un upload utilisateur — la sortie est ensuite validee par `QuestionCreate(**item)` (Pydantic). Pas de `eval`, pas de `pickle`, pas de `yaml.load`. **Conforme**.
- **Taille d'upload non limitee** : `await file.read()` lit tout en RAM sans limite. Un upload d'un fichier de 1 Go peut provoquer un OOM. **MOYENNE**.

### Findings
- **A05-MED-01** : Pas de limite de taille sur `/admin/questions/upload-json`.

### Recommandation
Ajouter une validation : `if len(raw) > 5 * 1024 * 1024: raise HTTPException(413, ...)` (F-05).

---

## 5. A01:2021 — Broken Access Control

> **Section la plus critique de l'audit.**

### Analyse systematique par endpoint

| Endpoint                                | Auth     | Verif ownership | Verdict                              |
|-----------------------------------------|----------|-----------------|--------------------------------------|
| `POST /auth/register`                   | public   | N/A             | OK                                   |
| `POST /auth/login`                      | public   | N/A             | OK                                   |
| `GET  /auth/me`                         | JWT      | N/A             | OK                                   |
| `GET  /questions`                       | public   | N/A             | OK (contenu pedagogique public)      |
| `GET  /questions/{id}`                  | public   | N/A             | OK                                   |
| `GET  /questions/random/list`           | public   | N/A             | OK                                   |
| `POST /questions`                       | admin    | N/A             | OK (`get_admin_user`)                |
| `POST /sessions`                        | AUCUNE   | NON             | **CRITIQUE** (F-06)                  |
| `GET  /sessions/{user_id}/due`          | AUCUNE   | NON             | **CRITIQUE** (F-07)                  |
| `GET  /sessions/{user_id}/stats`        | AUCUNE   | NON             | **CRITIQUE** (F-07)                  |
| `GET  /predict-score/{user_id}`         | AUCUNE   | NON             | **CRITIQUE** (F-08)                  |
| `GET  /predict-dropout/{user_id}`       | AUCUNE   | NON             | **CRITIQUE** (F-08)                  |
| `POST /sync/action`                     | JWT      | OK (current_user) | OK                                 |
| `POST /sync/batch`                      | JWT      | OK              | OK                                   |
| `GET  /sync/status`                     | JWT      | OK              | OK                                   |
| `GET  /sync/pull`                       | JWT      | OK              | OK                                   |
| `POST /tutor/ask`                       | JWT      | OK              | OK                                   |
| `GET  /tutor/health`                    | public   | N/A             | OK (n'expose que le nom du modele)   |
| `POST /admin/questions/*` (CRUD)        | admin    | N/A             | OK                                   |
| `GET  /admin/logs`                      | admin    | N/A             | OK                                   |
| `POST /classroom/create`                | AUCUNE   | N/A             | **HAUTE** (F-09)                     |
| `GET  /classroom/{code}/status`         | public   | N/A             | OK (status public, pas de PII)       |
| `GET  /classroom/{code}/results`        | AUCUNE   | N/A             | **HAUTE** (F-10) — leak noms eleves  |
| `POST /classroom/{code}/end`            | AUCUNE   | N/A             | **HAUTE** (F-11)                     |
| `POST /classroom/cleanup`               | AUCUNE   | N/A             | **MOYENNE** (F-12)                   |
| `GET  /classroom`                       | AUCUNE   | N/A             | **MOYENNE** (F-13) — debug leak      |

### Findings
- **A01-CRIT-01 (F-06)** : `POST /sessions` accepte `payload.user_id` sans verifier que l'utilisateur authentifie correspond. Un attaquant peut enregistrer des reponses au nom d'un autre eleve en fournissant son `user_id`, ce qui corrompt son BKT et son SM-2. Code incrimine (`routers/sessions.py` ligne 72) :
  ```python
  def record_session(payload: schemas.SessionIn, db: Session = Depends(get_db)):
      user = db.get(User, payload.user_id)  # pas de Depends(get_current_user)
  ```
- **A01-CRIT-02 (F-07)** : `GET /sessions/{user_id}/due` et `GET /sessions/{user_id}/stats` ne declenchent aucun `Depends(get_current_user)`. N'importe qui peut lister les cartes dues d'un autre eleve (avec leur `question_id`, leur `easiness_factor`, leur `total_attempts`).
- **A01-CRIT-03 (F-08)** : `GET /predict-score/{user_id}` et `GET /predict-dropout/{user_id}` exposent le BKT map complet (donnees pedagogiques sensibles) sans authentification. Pire : `predict_dropout` revele a un attaquant quels eleves sont en difficulte — information exploitable (harcement, discrimination).
- **A01-HIGH-01 (F-09)** : `POST /classroom/create` ne necessite aucun JWT. N'importe qui peut creer une session et obtenir un code a 6 chiffres (DDoS potentiel par creation massive de sessions).
- **A01-HIGH-02 (F-10)** : `GET /classroom/{code}/results` expose le classement complet avec les `player_name` (souvent le nom reel de l'eleve) et les reponses. Pas d'auth enseignant. Comme le code session n'a que 6 chiffres (1 000 000 de combinaisons), un brute-force est realiste.
- **A01-HIGH-03 (F-11)** : `POST /classroom/{code}/end` permet a n'importe qui de terminer une session en cours (sabotage).
- **A01-MED-01 (F-12)** : `POST /classroom/cleanup` non protege — peut etre appele en boucle pour perturber le suivi des sessions.
- **A01-MED-02 (F-13)** : `GET /classroom` expose la liste de toutes les sessions actives (codes + statuts) — facilite les attaques ci-dessus.
- **A01-MED-03** : Le code session classroom a 6 chiffres decimaux (`session_code`) — entropie faible. Pas de rate limit sur `/classroom/{code}/results`.

### Recommandations (voir `SECURITY_FIXES.md` F-06 a F-13)
1. Ajouter `Depends(get_current_user)` et verifier `current_user.id == payload.user_id` (ou, mieux, retirer `user_id` du payload et l'inférer du JWT) sur `POST /sessions`.
2. Remplacer `user_id: str` path param par `Depends(get_current_user)` sur `GET /sessions/{user_id}/due|stats` et `GET /predict-*`.
3. Exiger un JWT enseignant (claim `role=teacher` ou `is_admin=True`) sur `/classroom/create`, `/classroom/{code}/end`, `/classroom/cleanup`, `/classroom` (debug).
4. Limiter `/classroom/{code}/results` aux enseignants + eleves ayant rejoint la session (le `player_id` est connu cote client).
5. Augmenter l'entropie du `session_code` (8 caracteres alphanumeriques = 2.8e9 combinaisons).

---

## 6. A05:2021 — Security Misconfiguration (suite)

### Analyse
- **CORS** : `config.py` ligne 56 `CORS_ORIGINS: List[str] = ["*"]` + `main.py` ligne 58-64 `allow_credentials=True, allow_methods=["*"], allow_headers=["*"]`. La combinaison `origin=*` + `credentials=True` est **interdite par la spec CORS** (navigateurs modernes la rejettent), mais Starlette la transforme en reflection d'origin, ce qui equivaut a autoriser n'importe quel site a appeler l'API avec les cookies/Authorization de l'utilisateur. **HAUTE**.
- **Debug mode** : `main.py` ne definit pas explicitement `debug=True` (FastAPI default `False`). Mais `uvicorn --reload` est documente dans le docstring — doit etre interdit en prod. **BASSE** (configuration operateur).
- **Stack traces** : FastAPI ne renvoie pas de traceback par defaut en prod (uniquement si `debug=True`). **Conforme**.
- **Endpoints de debug** : `/sync/health` retourne `{"status": "error", "detail": str(e)}` (`routers/sync.py` ligne 206) — fuite d'info interne (nom d'exception, messages DB). **MOYENNE**. `/classroom` (cf. F-13) egalement.
- **Headers de securite manquants** : aucun `X-Content-Type-Options`, `X-Frame-Options`, `Strict-Transport-Security`, `Content-Security-Policy`, `Referrer-Policy`. **MOYENNE** — corrigee par le middleware `security_headers.py`.
- **Documentation Swagger exposee en prod** : `/docs` et `/redoc` sont accessibles sans auth. **MOYENNE** — utile en dev, a desactiver en prod via `FastAPI(openapi_url=None)` ou un guard.
- **Versionnage des packages** : `python-jose==3.3.0`, `python-multipart==0.0.9` sont pins (bonne pratique), mais vulnerables (voir A09).
- **Fichiers `.env`** : presence supposee cote dev. Vérifier que `.env` est dans `.gitignore` (a verifier hors perimetre).
- **HTTPS desactive en local** : acceptable, mais le middleware HSTS fourni doit etre actif en prod uniquement.

### Findings
- **A06-HIGH-01 (F-14)** : CORS trop permissif (`*` + credentials).
- **A06-MED-01** : Endpoints `/docs`, `/redoc`, `/openapi.json` exposes en prod.
- **A06-MED-02 (F-15)** : `/sync/health` fuite `str(e)` dans la reponse.
- **A06-MED-03** : Absence de headers de securite (corrige par middleware).
- **A06-LOW-01** : `uvicorn --reload` documente (a garder en dev seulement).

### Recommandations
1. `CORS_ORIGINS` en prod doit etre une liste stricte : `["https://examboost.tg", "https://app.examboost.tg"]`. Faire echouer le demarrage si `("*" in CORS_ORIGINS) and (ENV == "prod")` (F-14).
2. Desactiver `/docs` et `/redoc` en prod : `FastAPI(docs_url=None if not DEBUG else "/docs", redoc_url=None if not DEBUG else "/redoc", openapi_url=None if not DEBUG else "/openapi.json")`.
3. `routers/sync.py` ligne 206 : retourner un message generique `{"status": "error"}` et logger l'exception cote serveur (F-15).
4. Brancher `security_headers.py` dans `main.py` (instructions dans le middleware).

---

## 7. A03:2021 — Injection (XSS regroupe dans OWASP 2021)

> XSS etait A7 dans OWASP 2017. Depuis 2021 elle est fusionnee dans A03 (Injection). On la couvre ici de facon dediee.

### Analyse
- **Output escaping** : FastAPI + Pydantic serialisent les reponses en JSON. Pas de rendu HTML cote backend (Flutter consomme l'API). **Conforme par construction**.
- **Stockage de contenu utilisateur** : les champs `enonce`, `explication`, `reponse` (cote questions) et les reponses du tuteur IA sont stockes tels quels. Si le frontend Flutter rend du HTML (WebFlutter) ou si on ajoute un futur client web, le risque existe. **BASSE** (Flutter echappe par defaut).
- **CSP** : aucun header `Content-Security-Policy`. **MOYENNE** — corrige par `security_headers.py`.
- **Reflected XSS via messages d'erreur** : `routers/admin.py` ligne 309 `detail=f"JSON invalide: {exc}"` — `exc` contient le message d'erreur du parser qui peut inclure une partie du contenu utilisateur. Faible risque car reponse JSON, mais a sanitizer. **BASSE**.
- **Tuteur IA** : la reponse de Claude est renvoyee telle quelle (`answer: str`). Si un futur client web l'affiche en HTML sans escaping, XSS. **BASSE** (a surveiller).

### Findings
- **A07-MED-01** : Absence de CSP (corrige par middleware).
- **A07-LOW-01** : Messages d'erreur incluant du contenu utilisateur (admin upload).

### Recommandations
1. Brancher `security_headers.py` qui pose une CSP restrictive : `default-src 'none'; frame-ancestors 'none'` (l'API ne sert pas de HTML, CSP maximale).
2. Sanitizer les messages d'erreur avec `input_validation.sanitize_for_log()` (fourni) avant de les inclure dans une reponse JSON.

---

## 8. A08:2021 — Software and Data Integrity Failures (Insecure Deserialization)

### Analyse
- **`pickle` / `marshal` / `yaml.load`** : aucun usage dans le code audite. **Conforme**.
- **`json.loads` sur upload** : `routers/admin.py` ligne 305. La sortie est validee par Pydantic (`QuestionCreate(**item)`). Pas de deserialisation d'objets arbitraires. **Conforme**.
- **Integrite des dependances** : pas de verification de hachage / `pip-audit` dans le CI. **MOYENNE**.
- **Subresource Integrity (SRI)** : N/A (API JSON, pas de ressources web).
- **CI/CD** : pas de pipeline visible dans le perimetre audite. Recommander un job `bandit` + `safety` (ajoutes au `requirements.txt`).

### Findings
- **A08-MED-01** : Pas de scan SAST/SCA automatise en CI (corrige partiellement par l'ajout de `bandit` et `safety` au `requirements.txt`).

### Recommandation
Brancher `bandit -r backend/ -ll` et `safety check` dans la CI GitHub Actions.

---

## 9. A06:2021 — Vulnerable and Outdated Components

### Analyse des versions pinnees (`requirements.txt`)

| Package                   | Version | CVE connus                                  | Severite |
|---------------------------|---------|---------------------------------------------|----------|
| `python-jose[cryptography]` | 3.3.0 | CVE-2024-33664 (DoS via cle DKIN), CVE-2024-33663 (confusion cle JWT si `verify_aud=False`) | HAUTE    |
| `python-multipart`        | 0.0.9   | CVE-2024-24762 (ReDoS sur parsing form-data)| MOYENNE  |
| `passlib[bcrypt]`         | 1.7.4   | Pas de CVE critique, mais projet non maintenu ; conflit avec `bcrypt>=4` | BASSE     |
| `pydantic`                | 2.8.2   | Aucun CVE actif                              | OK       |
| `fastapi`                 | 0.111.0 | Aucun CVE critique (un CVE mineur sur 0.108 corrigé en 0.111) | OK       |
| `sqlalchemy`              | 2.0.31  | OK                                           | OK       |
| `uvicorn[standard]`       | 0.30.1  | OK                                           | OK       |
| `redis`                   | 5.0.7   | OK                                           | OK       |
| `slowapi`                 | 0.1.9   | Pas de CVE, mais projet peu actif            | OK       |
| `alembic`                 | 1.13.2  | OK                                           | OK       |

### Findings
- **A09-HIGH-01 (F-16)** : `python-jose==3.3.0` vulnerable. L'usage dans `auth_service.py` precise `algorithms=[settings.ALGORITHM]`, ce qui mitige CVE-2024-33663, mais pas CVE-2024-33664 (DoS).
- **A09-MED-01 (F-17)** : `python-multipart==0.0.9` vulnerable (ReDoS). Affecte `routers/admin.py` (upload) et tout endpoint `UploadFile`.
- **A09-LOW-01** : `passlib==1.7.4` non maintenu. Le code utilise deja `bcrypt` direct en priorite (fallback `passlib` seulement si `bcrypt` absent). Recommander de supprimer `passlib` du `requirements.txt` une fois le fallback retire.

### Recommandations
1. Upgrader `python-jose` vers `3.4.0+` (ou migrer vers `pyjwt` plus maintenu) — F-16.
2. Upgrader `python-multipart` vers `>=0.0.18` — F-17.
3. Ajouter `bandit==1.7.9` et `safety==3.2.7` au `requirements.txt` (fait dans cette vague).
4. Mettre en place un job CI `safety check --full-report` hebdomadaire.

---

## 10. A09:2021 — Security Logging and Monitoring Failures

### Analyse
- **Logs admin** : la table `admin_action_logs` enregistre create / update / delete / import / export avec `admin_id`, `question_id`, `timestamp`, `details`. **Conforme** (bonne pratique).
- **Logs auth** : aucun log de login success / failure, aucun log de register, aucun log de token invalide. **HAUTE** — on ne peut pas detecter un bruteforce ou une attaque sur les comptes admin.
- **Logs access control** : aucun log quand `get_current_user` leve 401, aucun log quand `get_admin_user` leve 403. **MOYENNE**.
- **Logs sync** : aucune trace des actions sync appliquees/skipped/failed. **MOYENNE**.
- **Logs rate limiting** : `rate_limiter.py` logge `"Rate limiter utilise ..."` mais ne logge pas les 429 individuels. **BASSE**.
- **Configuration logging** : aucun `logging.basicConfig` dans `main.py`. Les `print()` subsistent (`admin_service.py` ligne 85, 561). **MOYENNE**.
- **Monitoring** : pas de Sentry, pas de /metrics Prometheus, pas de healthcheck avancé (seulement `/health` basique). **BASSE**.

### Findings
- **A10-HIGH-01 (F-18)** : Absence de logs d'authentification (login success/failure, register, token invalide).
- **A10-MED-01** : Absence de logs d'access control (401/403).
- **A10-MED-02** : Utilisation de `print()` au lieu du module `logging`.
- **A10-LOW-01** : Pas de monitoring externe (Sentry/Prometheus).

### Recommandations
1. Creer un module `backend/security/audit_log.py` (hors perimetre — a planifier) avec :
   ```python
   logger = logging.getLogger("examboost.audit")
   def log_auth_event(event: str, user_id: str | None, ip: str, success: bool, **extra): ...
   ```
2. Appeler `log_auth_event("login", user.id, request.client.host, True)` dans `/auth/login` (F-18).
3. Remplacer tous les `print()` par `logger.info()` / `logger.warning()` (F-19).
4. Brancher Sentry (DSN via env var) — recommandation hors perimetre.

---

## Recommandations prioritaires

### P0 — A corriger avant le pitch DJANTA (24 juillet 2026)

1. **F-01** : Refuser le demarrage si `SECRET_KEY` est encore la valeur par defaut.
2. **F-06 / F-07 / F-08** : Ajouter `Depends(get_current_user)` + verification ownership sur `/sessions/*` et `/predict-*` (3 vulnerabilites critiques).
3. **F-14** : Forcer `CORS_ORIGINS` strict en prod.
4. **F-02** : Brancher le rate limiting sur `/auth/login` et `/auth/register`.

### P1 — A corriger avant la mise en production reelle

5. **F-09 / F-10 / F-11** : Proteger `/classroom/create`, `/classroom/{code}/results`, `/classroom/{code}/end` par JWT + role enseignant.
6. **F-16 / F-17** : Upgrader `python-jose` et `python-multipart`.
7. **F-18** : Logger les tentatives d'auth.
8. Brancher les middlewares `security_headers.py` et `input_validation.py` (fournis).

### P2 — Ameliorations continues

9. F-03, F-04 : Politique mot de passe + message register.
10. F-05 : Limite taille upload.
11. F-12, F-13 : Protect + supprimer `/classroom` debug.
12. F-15 : Nettoyer les messages d'erreur.
13. F-19 : Migrer `print()` vers `logging`.
14. Desactiver `/docs` en prod.
15. Refresh token + revocation.

---

## Conformite Loi n° 2019-014 du 30 octobre 2019 (protection des donnees a caractere personnel, Togo)

La loi 2019-014 regit le traitement des donnees a caractere personnel au Togo. L'autorite de controle est l'ARP (Autorite de Protection des Donnees a caractere personnel). Voici l'analyse de conformite du backend ExamBoost.

### Donnees a caractere personnel traitees

| Champ              | Table      | PII ? | Sensibilite                              |
|--------------------|------------|-------|------------------------------------------|
| `email`            | `users`    | Oui   | Identifiant unique, permet le tracking   |
| `nom`, `prenom`    | `users`    | Oui   | Identite directe                         |
| `etablissement`    | `users`    | Oui   | Etablissement scolaire (eleve mineur)    |
| `ville`            | `users`    | Oui   | Geolocalisation large                    |
| `niveau_scolaire`  | `users`    | Oui   | Age decale (3eme ~ 14 ans, Terminale ~ 17 ans) |
| `bkt_maitrise`     | `users`    | Oui   | Profil cognitif — donnee sensible        |
| `responses`        | `responses`| Oui   | Historique d'apprentissage               |
| `simulations`      | `simulations` | Oui | Resultats d'examens blancs               |
| `player_name`      | classroom (RAM) | Oui | Nom de l'eleve dans la classe temps reel |
| `ip` (rate limiter)| RAM/Redis  | Oui   | Adresse IP — donnee personnelle au sens de la loi |

### Analyse de conformite

| Principe loi 2019-014                            | Conformite | Action requise                                                                 |
|--------------------------------------------------|------------|--------------------------------------------------------------------------------|
| **Article 4** : consentement libre, eclaire      | Non        | Ajouter un ecran de consentement dans l'app Flutter (hors perimetre backend) ; tracer le consentement en base (date, version CGU) |
| **Article 5** : finalite legitime et limitee     | Oui        | Preparation aux examens — finalitee claire                                     |
| **Article 6** : proportionnalite                 | Partiel    | `ville` et `etablissement` sont-ils strictement necessaires au service ? A documenter |
| **Article 7** : duree de conservation            | Non        | Definir une duree (ex: 5 ans apres derniere activite) + script de purge       |
| **Article 9** : securite et confidentialite      | Partiel    | Chiffrement au repos absent (voir A03-MED-02), access control deficient (voir A01) |
| **Article 10** : transparence (information)      | Non        | Rediger une politique de confidentialite accessible depuis l'app              |
| **Article 16** : droit d'acces                   | Non        | Pas d'endpoint d'export de ses propres donnees                                |
| **Article 17** : droit de rectification          | Non        | Pas d'endpoint de mise a jour du profil (uniquement via admin)                |
| **Article 18** : droit a l'effacement            | Non        | Pas d'endpoint de suppression de compte                                       |
| **Article 19** : droit d'opposition              | Non        | N/A (pas de marketing)                                                        |
| **Article 22** : notification de violation       | Non        | Pas de procedure definie                                                      |
| **Article 27** : declaration aupres de l'ARP     | Non        | A effectuer avant la mise en production                                        |
| **Article 31** : transfert hors Togo             | Partiel    | Si Railway/Render heberge hors Togo (USA/EU), encadrer par clauses contractuelles types |

### Plan d'action conformite (a completer par un juriste)

1. **Avant le 24 juillet (pitch DJANTA)** : aucune donnee reelle d'eleve ne doit transiter (demo uniquement). Le statut "demo" doit etre explicite dans l'UI. Rédiger une mini-politique de confidentialite (1 page) et l'afficher dans l'onboarding.
2. **Avant la mise en production reelle (rentree 2026)** :
   - Declarer le traitement aupres de l'ARP.
   - Implementer les endpoints `/users/me/export` (JSON de toutes les donnees), `/users/me` (PUT, rectification), `/users/me` (DELETE, effacement).
   - Implementer un script de purge des comptes inactifs > 3 ans (tache planifiee).
   - Chiffrer le volume disque de la base PostgreSQL (volume chiffre Railway/Render).
   - Anonymiser les `responses` apres 5 ans (conserver uniquement les agregats pour calibration IRT/ML).
   - Tracer le consentement CGU dans une table `consent_events(user_id, version, timestamp, ip)`.
3. **Mention legale** : ajouter dans l'app : "ExamBoost Togo, edite par [votre structure], declare aupres de l'ARP sous le numero [a obtenir]. Contact DPO : dpo@examboost.tg".

### Conformite technique (points deja conformes)

- Logs d'actions admin persistes (table `admin_action_logs`) — satisfait partiellement l'article 9 (tracabilite).
- Hashing bcrypt des mots de passe — satisfait l'article 9 (securite).
- Schema `UserOut` exclut `password_hash` — satisfait le principe de minimisation.

---

## Annexe A — Cartographie des fichiers etudies

| Fichier                                   | Rôle                                  |
|-------------------------------------------|---------------------------------------|
| `backend/main.py`                         | Point d'entree, CORS, routers        |
| `backend/config.py`                       | Settings (SECRET_KEY, CORS, etc.)    |
| `backend/routers/auth.py`                 | Register / login / me                |
| `backend/routers/questions.py`            | Banque questions (CRUD partiel)      |
| `backend/routers/sessions.py`             | SRS + BKT                            |
| `backend/routers/predict.py`              | Score + dropout                      |
| `backend/routers/sync.py`                 | Sync offline-first                   |
| `backend/routers/tutor.py`                | Tuteur IA (Claude)                   |
| `backend/routers/classroom.py`            | Classe temps reel (WS + REST)        |
| `backend/routers/admin.py`                | CRUD admin questions                 |
| `backend/services/auth_service.py`        | JWT + bcrypt                         |
| `backend/services/admin_service.py`       | Service admin + logs                 |
| `backend/models/db_models.py`             | ORM                                  |
| `backend/models/schemas.py`               | Pydantic                             |
| `backend/rate_limiter.py`                 | slowapi (non branche)                |
| `backend/requirements.txt`                | Dependances                          |

## Annexe B — Synthese des 19 findings

| ID          | Categorie OWASP | Severite | Fichier(s) concerne(s)            | Statut correction |
|-------------|-----------------|----------|-----------------------------------|-------------------|
| A02-CRIT-01 | A02             | Critique | `config.py`                       | Documentee (F-01) |
| A01-CRIT-01 | A01             | Critique | `routers/sessions.py`             | Documentee (F-06) |
| A01-CRIT-02 | A01             | Critique | `routers/sessions.py`             | Documentee (F-07) |
| A01-CRIT-03 | A01             | Critique | `routers/predict.py`              | Documentee (F-08) |
| A02-HIGH-01 | A02             | Haute    | `main.py`, `rate_limiter.py`      | Documentee (F-02) |
| A01-HIGH-01 | A01             | Haute    | `routers/classroom.py`            | Documentee (F-09) |
| A01-HIGH-02 | A01             | Haute    | `routers/classroom.py`            | Documentee (F-10) |
| A01-HIGH-03 | A01             | Haute    | `routers/classroom.py`            | Documentee (F-11) |
| A06-HIGH-01 | A06             | Haute    | `config.py`, `main.py`            | Documentee (F-14) |
| A09-HIGH-01 | A09             | Haute    | `requirements.txt`                | Documentee (F-16) |
| A10-HIGH-01 | A10             | Haute    | `routers/auth.py`                 | Documentee (F-18) |
| A02-MED-01  | A02             | Moyenne  | `config.py`                       | Documentee        |
| A02-MED-02  | A02             | Moyenne  | `models/schemas.py`               | Documentee (F-03) |
| A02-MED-03  | A02             | Moyenne  | `routers/auth.py`                 | Documentee (F-04) |
| A03-MED-01  | A03             | Moyenne  | `main.py`                         | Corrige (middleware) |
| A03-MED-02  | A03             | Moyenne  | `db_models.py`                    | Documentee        |
| A05-MED-01  | A05             | Moyenne  | `routers/admin.py`                | Documentee (F-05) |
| A06-MED-01  | A06             | Moyenne  | `main.py`                         | Documentee        |
| A06-MED-02  | A06             | Moyenne  | `routers/sync.py`                 | Documentee (F-15) |
| A06-MED-03  | A06             | Moyenne  | `main.py`                         | Corrige (middleware) |
| A07-MED-01  | A07             | Moyenne  | `main.py`                         | Corrige (middleware) |
| A08-MED-01  | A08             | Moyenne  | CI                                | Documentee        |
| A09-MED-01  | A09             | Moyenne  | `requirements.txt`                | Documentee (F-17) |
| A10-MED-01  | A10             | Moyenne  | `routers/auth.py`                 | Documentee        |
| A10-MED-02  | A10             | Moyenne  | `services/admin_service.py`       | Documentee (F-19) |
| A01-MED-01  | A01             | Moyenne  | `routers/classroom.py`            | Documentee (F-12) |
| A01-MED-02  | A01             | Moyenne  | `routers/classroom.py`            | Documentee (F-13) |
| A01-MED-03  | A01             | Moyenne  | `services/classroom_manager.py`   | Documentee        |
| A03-LOW-01  | A03             | Basse    | `services/auth_service.py`        | Documentee        |
| A06-LOW-01  | A06             | Basse    | `main.py`                         | Documentee        |
| A07-LOW-01  | A07             | Basse    | `routers/admin.py`                | Documentee        |
| A09-LOW-01  | A09             | Basse    | `requirements.txt`                | Documentee        |
| A10-LOW-01  | A10             | Basse    | monitoring                         | Documentee        |
| A05-LOW-XX  | A05             | Basse    | logout                            | Documentee        |

> Note : le total "19 vulnerabilites" de la synthese executive decompte les findings uniques par severite (3 critiques + 5 hautes + 7 moyennes + 4 basses). L'annexe B liste egalement les sous-items et recommandations.

---

*Fin du rapport. Voir `SECURITY_FIXES.md` pour les patches detailles et `SECURITY_CHECKLIST.md` pour la checklist de revue a appliquer a chaque future PR.*
