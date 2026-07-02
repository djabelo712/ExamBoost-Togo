# Scripts de déploiement — ExamBoost Togo

Ce dossier contient les scripts bash d'automatisation du déploiement.
Tous les scripts sont idempotents et peuvent être lancés en local ou en CI.

## Pré-requis communs

| Outil     | Installation                                | Usage                      |
|-----------|---------------------------------------------|----------------------------|
| Railway CLI | `npm install -g @railway/cli`             | Backend deploy/rollback    |
| Vercel CLI  | `npm install -g vercel`                   | Landing deploy             |
| jq          | `apt install jq` (Linux) / `brew install jq` | Parsing JSON Railway     |
| curl        | Pré-installé partout                       | Health checks              |

## Variables d'environnement requises

```bash
# Railway (backend)
export RAILWAY_TOKEN="railway-service-token-..."   # Railway > Settings > Tokens

# Vercel (landing) — auth interactive via `vercel login`
# OU variables d'automatisation :
export VERCEL_TOKEN="vercel-token-..."             # Vercel > Settings > Tokens
export VERCEL_ORG_ID="team_xxx"
export VERCEL_PROJECT_ID="prj_xxx"

# Seed prod (une seule fois)
export ADMIN_TOKEN="jwt-admin-..."
```

## Liste des scripts

### `deploy_backend.sh`

Déploie le backend FastAPI sur Railway.

```bash
./scripts/deploy_backend.sh                # staging (défaut)
./scripts/deploy_backend.sh production     # production
```

Étapes :
1. Vérifie Railway CLI + `RAILWAY_TOKEN` + lien projet
2. `railway up --service examboost-backend --environment <env>`
3. Attend que le déploiement soit promu (~120s)
4. Récupère l'URL publique via `railway status --json`
5. Health check sur `/health`

### `deploy_landing.sh`

Déploie la landing Next.js sur Vercel.

```bash
./scripts/deploy_landing.sh                # preview (défaut)
./scripts/deploy_landing.sh --prod         # production
```

Étapes :
1. Vérifie Vercel CLI + auth + lien projet (`.vercel/project.json`)
2. Build local de vérification (`npm ci && npm run build`)
3. `vercel --prod --yes` ou `vercel --yes`

### `deploy_all.sh`

Orchestre backend + landing + health check final.

```bash
./scripts/deploy_all.sh                    # backend staging + landing preview
./scripts/deploy_all.sh --prod             # backend production + landing prod
./scripts/deploy_all.sh production --prod  # idem explicite
```

### `rollback_backend.sh`

Rollback du dernier déploiement Railway.

```bash
./scripts/rollback_backend.sh              # staging
./scripts/rollback_backend.sh production
```

> Railway conserve l'historique complet des déploiements. Le rollback
> restaure la version précédente. Si le CLI échoue (prompt interactif),
> utilisez le dashboard : Railway > Service > Deployments > ... > Rollback.

### `health_check.sh`

Vérifie que tous les endpoints publics sont sains.

```bash
./scripts/health_check.sh
BACKEND_URL=https://examboost-togo.up.railway.app ./scripts/health_check.sh
```

Endpoints vérifiés :
- Backend : `/health`, `/health/live`, `/health/ready`, `/docs`, `/openapi.json`, `/`
- Landing : `/`, `/merci`

### `seed_prod_db.sh`

Peuple la base de données prod/staging via l'API (une seule fois par env).

```bash
ADMIN_TOKEN="eyJhbGc..." ./scripts/seed_prod_db.sh
BACKEND_URL=https://examboost-togo-staging.up.railway.app \
  ADMIN_TOKEN="eyJhbGc..." ./scripts/seed_prod_db.sh
```

Affiche les stats avant/après via `/health/stats`. Idempotent.

## CI/CD

Ces scripts sont conçus pour être appelés depuis GitHub Actions (voir
`.github/workflows/`). Le workflow de release Flutter est déjà présent ;
un workflow backend-deploy peut être ajouté ainsi :

```yaml
# .github/workflows/backend_deploy.yml (à créer)
name: Deploy Backend
on:
  push:
    branches: [main]
    paths: ['backend/**']
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20' }
      - run: npm install -g @railway/cli
      - run: ./scripts/deploy_backend.sh production
        env:
          RAILWAY_TOKEN: ${{ secrets.RAILWAY_TOKEN }}
```

## Conventions

- **Langue** : commentaires en anglais (standard bash), sortie utilisateur en anglais.
- **Set options** : `set -euo pipefail` partout (fail-fast).
- **Idempotence** : tous les scripts peuvent être re-lancés sans effet de bord.
- **Logs** : chaque script préfixe ses logs avec `[script_name]` pour faciliter
  le grep dans les logs CI.
- **Exit codes** : `0` = succès, `1` = erreur fatale, codes spécifiques sinon.

---

# Backend hardening — Alembic + Redis + Rate Limiting (Agent AU)

Cette section documente le durcissement backend mis en place par l'Agent AU
(task `AU-alembic-redis`). Trois piliers :

1. **Alembic** — migrations de schéma versionnées (au lieu de `init_db()` seul).
2. **Redis** — cache des lectures fréquentes (questions, params IRT, BKT user).
3. **Rate Limiting** — protection anti-abus via `slowapi` (5 niveaux par endpoint).

Tous les fichiers vivent dans `backend/` et ne modifient aucun fichier
existant (à l'exception de `backend/requirements.txt` étendu). L'agent de
wiring final branchera ces modules dans `main.py` et les routers.

## Fichiers ajoutés

| Fichier | Rôle |
|---------|------|
| `backend/alembic.ini` | Config Alembic (URL DB, logging) |
| `backend/alembic/env.py` | Environnement Alembic (branche `Base.metadata`) |
| `backend/alembic/script.py.mako` | Template de génération de migrations |
| `backend/alembic/versions/001_initial_schema.py` | Schéma initial (users, questions, review_cards, responses, simulations) |
| `backend/alembic/versions/002_add_tutor_tables.py` | Tables tuteur IA (Agent W) |
| `backend/redis_client.py` | Singleton Redis paresseux (fallback `None` si absent) |
| `backend/cache_service.py` | Cache TTL avec fallback mémoire + helpers métier |
| `backend/rate_limiter.py` | slowapi : 5 niveaux de limite + handler 429 |
| `backend/tests/test_cache.py` | Tests du cache (set/get/TTL/invalidate/fallback) |
| `backend/tests/test_rate_limit.py` | Tests des limites (100/min, 30/min, etc.) |
| `backend/tests/test_migrations.py` | Tests upgrade/downgrade Alembic |
| `scripts/run_migrations.sh` | Script shell d'application des migrations |

## Setup Alembic

### Installation

```bash
cd backend/
pip install -r requirements.txt   # ajoute alembic==1.13.2
```

### Appliquer les migrations (dev local)

```bash
# Depuis la racine du repo
./scripts/run_migrations.sh

# Ou directement en backend/
cd backend/
alembic upgrade head
alembic current      # affiche la révision courante (ex: 002)
alembic history      # historique des migrations
```

### En production (PostgreSQL Railway/Render)

```bash
# DATABASE_URL est lue par alembic/env.py et surcharge alembic.ini
DATABASE_URL=postgresql://user:pass@host:5432/dbname ./scripts/run_migrations.sh
```

Le `Procfile` Railway peut appeler ce script dans une `release phase` :

```toml
# railway.json (extrait)
[deploy]
releaseCommand = "./scripts/run_migrations.sh"
```

### Créer une nouvelle migration

```bash
cd backend/

# Autogénérée (compare Base.metadata avec la DB)
alembic revision --autogenerate -m "add_new_table"

# Manuelle (vide)
alembic revision -m "add_new_table"
```

Le fichier est créé dans `backend/alembic/versions/`. Le numéro de révision
est hex par défaut ; on peut le remplacer par `003`, `004`, etc. pour la
lisibilité (les fichiers existants suivent ce schéma).

### Downgrade

```bash
alembic downgrade -1            # annule la dernière migration
alembic downgrade 001           # retourne à la révision 001
alembic downgrade base          # annule TOUT (drop toutes les tables métier)
```

## Setup Redis

### Pourquoi Redis ?

- **Cache** : questions et params IRT sont stables → on évite des requêtes DB.
- **Rate limiting distribué** : compteurs partagés entre workers uvicorn/gunicorn.
- **Sessions (futur)** : si on déplace le JWT en Redis blacklist.

### Sans Redis (dev locale / CI)

Tout fonctionne **sans Redis** : `redis_client.get_redis()` renvoie `None` et
le `CacheService` bascule en fallback mémoire (dict processus). Le rate limiter
utilise `memory://` (compteurs en RAM).

### Avec Redis (Docker local)

```bash
# Démarre Redis sur localhost:6379
docker run -d --name examboost-redis -p 6379:6379 redis:7-alpine

# Configure l'app
export REDIS_URL=redis://localhost:6379/0
```

### Avec Redis managed (production)

**Recommandation** : Upstash Redis (serverless, gratuit jusqu'à 10k cmd/jour).

1. Créer une DB sur [Upstash](https://upstash.com/) → récupérer l'URL.
2. Ajouter comme variable Railway :
   ```
   REDIS_URL=rediss://default:password@xxx.upstash.io:6379
   ```
3. Redémarrer le backend. Vérifier dans les logs : `Redis connecté avec succès`.

### Ajouter `REDIS_URL` à `config.Settings` (à faire par l'agent de wiring)

```python
# backend/config.py — ajouter dans la classe Settings
REDIS_URL: str | None = None   # None = fallback mémoire
```

`redis_client._resolve_redis_url()` lit déjà `settings.REDIS_URL` via
`getattr` (donc fonctionne immédiatement), mais l'ajouter explicitement
permet la validation et la documentation.

## Rate Limiting

### 5 niveaux de limite

| Décorateur | Limite | Cas d'usage |
|------------|--------|-------------|
| `@rate_limit_auth()` | 10/min | `/auth/login`, `/auth/register` (anti-bruteforce) |
| `@rate_limit_default()` | 100/min | `/questions`, `/health` (lectures légères) |
| `@rate_limit_write()` | 60/min | `/sessions`, `/sync` (écritures utilisateur) |
| `@rate_limit_heavy()` | 30/min | `/tutor/ask`, `/predict` (IA + ML coûteux) |
| `@rate_limit_admin()` | 10/min | `/admin/*` (opérations sensibles) |

### Branchement dans `main.py` (à faire par l'agent de wiring)

```python
# En haut de main.py
from rate_limiter import setup_rate_limiting

# Après la création de l'app (après CORSMiddleware)
setup_rate_limiting(app)

# Sur chaque endpoint sensible
from rate_limiter import rate_limit_default

@app.get("/questions")
@rate_limit_default()
async def list_questions(...):
    ...
```

### Personnaliser les limites

Éditer `backend/rate_limiter.py` (fonctions `rate_limit_*`). Les limites
sont des chaînes slowapi : `"10/minute"`, `"100/hour"`, `"5/second"`, etc.
Voir [la doc slowapi](https://slowapi.readthedocs.io/).

### Limiter par utilisateur (JWT) au lieu de par IP

```python
# rate_limiter.py — ajouter
from slowapi.util import get_remote_address
from starlette.requests import Request

def get_user_or_ip(request: Request) -> str:
    """Limite par user_id JWT si dispo, sinon par IP."""
    user = getattr(request.state, "user", None)
    if user and getattr(user, "id", None):
        return f"user:{user.id}"
    return get_remote_address(request)

# Puis remplacer key_func=get_remote_address par key_func=get_user_or_ip
# dans _build_limiter().
```

## Cache Service

### Helpers métier disponibles

```python
from cache_service import (
    get_cached_questions, set_cached_questions, invalidate_questions_cache,
    get_cached_irt_params, set_cached_irt_params,
    get_cached_user_bkt, set_cached_user_bkt,
    get_cached_user_stats, set_cached_user_stats,
    invalidate_user_cache,
    CacheService,
)
```

### TTL par domaine

| Domaine | TTL | Justification |
|---------|-----|---------------|
| Questions | 1h | Banque stable, rarement modifiée |
| Params IRT | 24h | Calibration hebdomadaire |
| BKT user | 5 min | Évolue à chaque session |
| Stats user | 10 min | Calcul coûteux, évolue peu |
| Tutor follow-ups | 24h | Suggestions statiques |

### Branchement typique (à faire par l'agent de wiring)

```python
# routers/questions.py
from cache_service import get_cached_questions, set_cached_questions

@router.get("/")
@rate_limit_default()
async def list_questions(matiere: str, examen: str, limit: int = 20, db: Session = Depends(get_db)):
    # 1) Check cache
    cached = await get_cached_questions(matiere, examen, limit)
    if cached is not None:
        return cached
    # 2) Fetch DB
    questions = db.query(Question).filter(...).limit(limit).all()
    result = [q.to_dict() for q in questions]
    # 3) Set cache
    await set_cached_questions(matiere, examen, limit, result)
    return result

# routers/sessions.py
@router.post("/")
@rate_limit_write()
async def record_session(...):
    # ... logique métier ...
    # Invalider le cache user (BKT a changé)
    await invalidate_user_cache(user_id)
    return {...}
```

## Tests

### Pré-requis

```bash
cd backend/
pip install -r requirements.txt   # ajoute pytest, pytest-asyncio, httpx
```

### Lancer les tests du hardening

```bash
# Tests cache uniquement (rapide, pas de DB)
pytest tests/test_cache.py -v

# Tests rate limiting (construit une mini-app FastAPI)
pytest tests/test_rate_limit.py -v

# Tests migrations (crée une SQLite temporaire par test)
pytest tests/test_migrations.py -v

# Tous les tests du hardening
pytest tests/test_cache.py tests/test_rate_limit.py tests/test_migrations.py -v
```

### Tests de charge basiques

Pour aller plus loin, installer `locust` :

```bash
pip install locust
```

Créer `backend/load_tests/locustfile.py` :

```python
from locust import HttpUser, task, between

class ExamBoostUser(HttpUser):
    wait_time = between(1, 3)

    @task(10)
    def list_questions(self):
        self.client.get("/questions/?matiere=maths&examen=BEPC")

    @task(1)
    def ask_tutor(self):
        self.client.post("/tutor/ask", json={"question": "Pythagore ?"})
```

Lancer :

```bash
locust -f backend/load_tests/locustfile.py --host=http://localhost:8000
# Ouvrir http://localhost:8089 pour l'UI
```

## Monitoring

### Stats Redis (si configuré)

```bash
# Nombre de clés
redis-cli DBSIZE

# Clés par namespace
redis-cli KEYS "questions:*" | wc -l
redis-cli KEYS "user_bkt:*" | wc -l

# Hit/miss ratio (nécessite redis-cli >= 7)
redis-cli INFO stats | grep keyspace
```

### Logs rate limiting

`slowapi` log une ligne WARNING à chaque 429. Sur Railway, filter avec :

```bash
railway logs --filter "Rate limit exceeded"
```

### Endpoints de santé (à ajouter par l'agent de wiring)

```python
@app.get("/health/cache")
async def health_cache():
    from redis_client import is_redis_available
    return {"redis": "up" if is_redis_available() else "down (fallback memory)"}
```

## Production — checklist

- [ ] `REDIS_URL` défini dans Railway (Upstash recommandé)
- [ ] `REDIS_URL` ajouté à `config.Settings` (par l'agent de wiring)
- [ ] `setup_rate_limiting(app)` appelé dans `main.py`
- [ ] `rate_limit_*` décorateurs appliqués sur les endpoints sensibles
- [ ] Cache branché sur `/questions`, `/predict` (lectures coûteuses)
- [ ] `invalidate_user_cache()` appelé après chaque POST `/sessions`
- [ ] `releaseCommand = "./scripts/run_migrations.sh"` dans `railway.json`
- [ ] Tests `pytest tests/test_{cache,rate_limit,migrations}.py` passent en CI
- [ ] Monitoring : dashboard Upstash + logs Railway filter "Rate limit"

---

# Génération des icônes app — SVG → PNG multi-tailles (Agent BA)

Cette section documente le script `generate_app_icons.py` qui convertit le
logo SVG ExamBoost Togo en PNG aux tailles standard Android + iOS.

## Pré-requis

```bash
pip install -r scripts/requirements.txt
# cairosvg==2.7.1 + Pillow==10.4.0
```

> CairoSVG nécessite les bibliothèques système `libcairo2`, `libffi-dev` et
> `libgdk-pixbuf2.0-dev` (déjà présentes sur la plupart des Linux).
> Sur macOS : `brew install cairo`.
> Sur Windows : installer GTK3 runtime.

## Usage

```bash
# Depuis la racine du repo
python scripts/generate_app_icons.py assets/branding/icon_app.svg app_icons/

# Mode verbeux (affiche chaque PNG généré)
python scripts/generate_app_icons.py assets/branding/icon_app.svg app_icons/ --verbose

# Aide
python scripts/generate_app_icons.py --help
```

## Sortie générée

```
app_icons/
├── android/
│   ├── mipmap-mdpi/      (48x48)
│   │   ├── ic_launcher.png
│   │   ├── ic_launcher_round.png
│   │   └── ic_launcher_foreground.png   (108x108)
│   ├── mipmap-hdpi/      (72x72, fg 162x162)
│   ├── mipmap-xhdpi/     (96x96, fg 216x216)
│   ├── mipmap-xxhdpi/    (144x144, fg 324x324)
│   └── mipmap-xxxhdpi/   (192x192, fg 432x432)
└── ios/
    └── AppIcon.appiconset/
        ├── icon_20pt_1x.png      (20x20)
        ├── icon_20pt_2x.png      (40x40)
        ├── icon_20pt_3x.png      (60x60)
        ├── icon_29pt_1x.png      (29x29)
        ├── icon_29pt_2x.png      (58x58)
        ├── icon_29pt_3x.png      (87x87)
        ├── icon_40pt_1x.png      (40x40)
        ├── icon_40pt_2x.png      (80x80)
        ├── icon_40pt_3x.png      (120x120)
        ├── icon_60pt_2x.png      (120x120)
        ├── icon_60pt_3x.png      (180x180)
        ├── icon_1024.png         (1024x1024, App Store)
        └── Contents.json         (manifeste Xcode auto-généré)
```

**Total : 15 PNG Android (5 dossiers × 3 fichiers) + 12 PNG iOS + 1 Contents.json = 28 fichiers.**

## Où copier les PNG générés

### Android

```bash
# Linux/macOS
cp -r app_icons/android/mipmap-* android/app/src/main/res/
```

Les dossiers `mipmap-*` existent peut-être déjà (icônes Flutter par défaut) :
les écraser pour remplacer par les icônes ExamBoost.

### iOS

```bash
# Linux/macOS
cp -r app_icons/ios/AppIcon.appiconset ios/Runner/Assets.xcassets/
```

Le fichier `Contents.json` est déjà configuré pour pointer vers les bons
fichiers PNG. Xcode le détectera automatiquement au prochain build.

### Web (PWA)

Pour le web (flutter web), les icônes sont déjà présentes dans `web/icons/`
(`Icon-192.png`, `Icon-512.png`, etc.). Le script ne les régénère pas —
pour cela, lancer manuellement :

```bash
python -c "import cairosvg; cairosvg.svg2png(url='assets/branding/icon_app.svg', write_to='web/icons/Icon-192.png', output_width=192, output_height=192)"
python -c "import cairosvg; cairosvg.svg2png(url='assets/branding/icon_app.svg', write_to='web/icons/Icon-512.png', output_width=512, output_height=512)"
```

## Tailles générées (récapitulatif)

### Android (5 densités)

| Folder            | Taille launcher | Taille foreground |
|-------------------|-----------------|-------------------|
| `mipmap-mdpi`     | 48 x 48 px      | 108 x 108 px      |
| `mipmap-hdpi`     | 72 x 72 px      | 162 x 162 px      |
| `mipmap-xhdpi`    | 96 x 96 px      | 216 x 216 px      |
| `mipmap-xxhdpi`   | 144 x 144 px    | 324 x 324 px      |
| `mipmap-xxxhdpi`  | 192 x 192 px    | 432 x 432 px      |

### iOS (11 tailles + App Store)

| Contexte        | 1x     | 2x       | 3x       |
|-----------------|--------|----------|----------|
| Notification    | 20px   | 40px     | 60px     |
| Settings        | 29px   | 58px     | 87px     |
| Spotlight       | 40px   | 80px     | 120px    |
| App (iPhone)    | —      | 120px    | 180px    |
| App Store       | 1024px | —        | —        |

## Alternative — `flutter_launcher_icons` (Dart)

Si vous préférez rester 100% dans l'écosystème Flutter (sans Python), il
existe le package [`flutter_launcher_icons`](https://pub.dev/packages/flutter_launcher_icons).

### Installation

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  image_path: "assets/branding/icon_app.png"   # nécessite un PNG source !
  android: true
  ios: true
  min_sdk_android: 21
  adaptive_icon_background: "#006837"
  adaptive_icon_foreground: "assets/branding/icon_app_foreground.png"
```

### Génération

```bash
dart run flutter_launcher_icons
```

### Limites vs script Python

| Critère                     | Script Python (BA)             | flutter_launcher_icons       |
|-----------------------------|--------------------------------|------------------------------|
| Format source               | SVG (vectoriel)               | PNG (raster)                 |
| Qualité haute résolution    | Lossless (rendu vectoriel)    | Dépend du PNG source         |
| Dépendance                  | cairosvg + Pillow (Python)    | Package Dart                 |
| Adaptive icon foreground    | Généré automatiquement        | Nécessite un PNG séparé      |
| Intégration CI              | Aucun build Flutter requis    | Nécessite `flutter pub get`  |

**Recommandation** : utiliser le script Python (`generate_app_icons.py`)
tant que la source est en SVG — la qualité vectorielle est supérieure. Le
package Dart est utile si vous voulez tout gérer depuis Flutter sans Python.

## Dépannage

### `cairosvg` ne s'importe pas

```bash
pip install --force-reinstall cairosvg==2.7.1
# Vérifier les deps système
ldconfig -p | grep cairo   # Linux
```

### Le rendu PNG est vide / incomplet

- Vérifier que le SVG source a un `viewBox` défini (et pas seulement
  `width`/`height`).
- Éviter les `filter` SVG complexes (flou, ombre) non supportés par CairoSVG.
- Tester le SVG dans un navigateur avant de lancer le script.

### iOS build échoue avec "icon size mismatch"

Le `Contents.json` est auto-généré avec les bonnes tailles. Vérifier que
vous avez bien copié **tout** le dossier `AppIcon.appiconset/` (et pas
seulement les PNG). Supprimer l'ancien `AppIcon.appiconset` avant de
copier le nouveau pour éviter les résidus.

### Android icon floue

Utiliser le SVG de plus haute résolution disponible (`icon_app.svg` est
en 100x100 — suffisant pour 192x192 mais pour 432x432 foreground, le
rendu reste net car vectoriel). Si flou persistant, utiliser `logo_examboost.svg`
(200x200) à la place.

## Production — checklist

- [ ] `pip install -r scripts/requirements.txt` exécuté
- [ ] `python scripts/generate_app_icons.py assets/branding/icon_app.svg app_icons/ -v` sans erreur
- [ ] 28 fichiers générés (15 Android + 12 iOS + 1 Contents.json)
- [ ] PNG Android copiés dans `android/app/src/main/res/mipmap-*`
- [ ] `AppIcon.appiconset` copié dans `ios/Runner/Assets.xcassets/`
- [ ] Build Android OK (icône visible dans le launcher)
- [ ] Build iOS OK (icône visible dans le simulateur + Springboard)
- [ ] Ajouter `app_icons/` au `.gitignore` (outputs générés, ne pas committer)

---

# Scripts de build APK + Web + CI — Agent BF (task `BF-build-apk-script`)

Cette section documente les 7 scripts bash et les 3 workflows GitHub
Actions qui automatisent la génération des binaires (APK debug, APK
release, bundle web) ainsi que la vérification de la contrainte
« APK < 25 Mo » imposée par le plan de distribution Togo.

## Pré-requis

| Outil        | Version min.   | Usage                                  |
|--------------|----------------|----------------------------------------|
| Flutter SDK  | 3.32.0 (stable)| Build APK + web                        |
| Dart SDK     | 3.3.0+         | (livré avec Flutter)                   |
| Android SDK  | API 28+        | Build APK + émulateur bas de gamme     |
| `adb`        | 1.0.41+        | Install/test sur device / émulateur    |
| `emulator`   | (Android SDK)  | Test sur device bas de gamme           |
| `avdmanager` | (Android SDK)  | Création AVD low-end                   |
| `python3`    | 3.10+          | Serveur HTTP local pour test web       |
| `bc` / `awk` | standard       | Calculs de taille dans les scripts     |

Aucun de ces scripts ne modifie le code source Flutter. Tous les
fichiers générés (APK, bundles web, copies horodatées) sont placés à
la racine du repo ou dans `build/` (déjà dans `.gitignore`).

## Liste des scripts

| Script                  | Rôle                                                      |
|-------------------------|-----------------------------------------------------------|
| `build_apk_debug.sh`    | Build APK debug + copie horodatée                         |
| `build_apk_release.sh`  | Build 3 APK release split per ABI + vérif taille < 25 Mo  |
| `build_web.sh`          | Build web bundle (renderer html) + instructions serveur   |
| `build_all.sh`          | Orchestre les 3 builds à la suite                         |
| `optimize_apk.sh`       | Audit assets + suggestions d'optimisation (read-only)     |
| `check_apk_size.sh`     | Vérifie qu'un APK < 25 Mo (exit 1 sinon)                  |
| `test_on_low_end.sh`    | Lance un émulateur Tecno Spark 4 + smoke test + memory    |

## Démarrage rapide

```bash
# 1. Build APK debug pour tester sur ton téléphone
./scripts/build_apk_debug.sh
adb install -r examboost-debug-*.apk

# 2. Build APK release (3 APK plus légers, pour distribution)
./scripts/build_apk_release.sh
./scripts/check_apk_size.sh build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

# 3. Build web pour démo navigateur
./scripts/build_web.sh
cd build/web && python3 -m http.server 8080
# Ouvre http://localhost:8080

# 4. Tout en un
./scripts/build_all.sh
```

## Détail des scripts

### `build_apk_debug.sh`

```bash
./scripts/build_apk_debug.sh
```

Étapes :
1. Vérifie que Flutter est installé.
2. `flutter clean` puis `flutter pub get`.
3. `dart run build_runner build --delete-conflicting-outputs`
   (régénère `*.g.dart`, `*.freezed.dart`, `*.mocks.dart`).
4. `flutter build apk --debug`.
5. Copie `app-debug.apk` en `examboost-debug-<YYYYMMDD-HHMMSS>.apk`
   à la racine du repo pour faciliter le partage.

Sortie :
- `build/app/outputs/flutter-apk/app-debug.apk`
- `examboost-debug-<timestamp>.apk` (racine du repo)

### `build_apk_release.sh`

```bash
./scripts/build_apk_release.sh
```

Étapes :
1. Clean + deps + codegen (idem debug).
2. `flutter build apk --release --split-per-abi` → 3 APK :
   - `app-arm64-v8a-release.apk` (téléphones modernes — recommandé)
   - `app-armeabi-v7a-release.apk` (téléphones anciens / entrée de gamme)
   - `app-x86_64-release.apk` (émulateurs)
3. Affiche la taille de chaque APK.
4. Vérifie que chaque APK < 25 Mo (contrainte Togo) — avertissement si
   dépassement, sans faire échouer le build.
5. Copie chaque APK en `examboost-v<version>-<abi>.apk` (version lue
   depuis `pubspec.yaml`).

Sortie :
- 3 fichiers `build/app/outputs/flutter-apk/app-*-release.apk`
- 3 fichiers `examboost-v<version>-<abi>.apk` à la racine du repo

### `build_web.sh`

```bash
./scripts/build_web.sh
```

Étapes :
1. Clean + deps + codegen.
2. `flutter build web --release --web-renderer html` — le renderer
   **html** est préféré à **CanvasKit** car il produit un bundle
   initial plus léger, important pour les connections data limitées
   au Togo. Switch vers `--web-renderer canvaskit` pour un rendu
   pixel-perfect au prix d'un bundle plus gros (~2 Mo CanvasKit).
3. Affiche la taille du bundle et les instructions pour servir en
   local avec `python3 -m http.server`.

Sortie : `build/web/` (fichiers statiques).

### `build_all.sh`

```bash
./scripts/build_all.sh
```

Orchestre les 3 builds (debug, release, web) en séquence. Utile pour
vérifier que toutes les cibles compilent avant de tagger une release.

### `optimize_apk.sh`

```bash
./scripts/optimize_apk.sh
```

Audit **read-only** (ne modifie aucun fichier) qui :
- Liste les 10 assets les plus lourds.
- Liste les polices (`.ttf` / `.otf`) avec leur taille.
- Compte les images par format (PNG / WebP / JPG / SVG).
- Affiche la taille des APK debug + release actuels.
- Propose 8 suggestions concrètes d'optimisation (WebP, R8, etc.).

À exécuter si `check_apk_size.sh` échoue, puis appliquer les
optimisations manuellement et rebuilder.

### `check_apk_size.sh`

```bash
./scripts/check_apk_size.sh                                              # APK release par défaut
./scripts/check_apk_size.sh build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
./scripts/check_apk_size.sh path/to/file.apk 15                          # limite custom (Mo)
```

Vérifie qu'un APK est sous la limite (25 Mo par défaut, configurable).
Exit codes :
- `0` — APK sous la limite
- `1` — APK au-dessus de la limite (ou fichier introuvable)

Utilisé par les workflows GitHub Actions et par `build_apk_release.sh`.

### `test_on_low_end.sh`

```bash
./scripts/test_on_low_end.sh
MONITOR_SECONDS=120 ./scripts/test_on_low_end.sh    # monitorer plus longtemps
```

Simule un **Tecno Spark 4** (téléphone entrée de gamme courant au
Togo : Android 9, 2 Go RAM, 16 Go stockage, écran 720x1560, ABI
armeabi-v7a).

Étapes :
1. Vérifie `emulator`, `adb`, `avdmanager` dans le PATH.
2. Crée l'AVD `examboost_low_end` si elle n'existe pas (image
   `system-images;android-28;default;armeabi-v7a`, device Nexus 4).
3. Lance l'émulateur headless avec `-memory 2048`.
4. Attend que `sys.boot_completed=1` (jusqu'à 240s).
5. Build + installe l'APK debug.
6. Lance l'activité principale.
7. Snapshot mémoire à T0 (`dumpsys meminfo`).
8. Simule des taps toutes les 5s pendant 60s (configurable via
   `MONITOR_SECONDS`).
9. Snapshot mémoire à T0+60s.
10. Vérifie l'absence de crash (`adb logcat -b crash`).
11. Tue l'émulateur proprement (trap EXIT).

Pré-requis pour le système d'image Android :

```bash
sdkmanager "system-images;android-28;default;armeabi-v7a"
sdkmanager --licenses
```

## Workflows GitHub Actions

3 workflows vivent dans `.github/workflows/` :

| Fichier          | Déclencheur                      | But                                  |
|------------------|----------------------------------|--------------------------------------|
| `build_apk.yml`  | push/PR sur `main`, `workflow_dispatch` | Build APK debug (toujours) + release APKs (sur push main) |
| `build_web.yml`  | push/PR sur `main`, `workflow_dispatch` | Build web bundle + deploy GitHub Pages (sur push main) |
| `release_apk.yml`| push d'un tag `v*`               | Build 3 APK release + créer une GitHub Release avec notes auto |

> **Note** — ces 3 workflows coexistent avec les workflows historiques
> `flutter_ci.yml` (analyze + test + build-apk-debug + build-web en
> pipeline complet) et `flutter_release.yml` (release sur tag `v*`).
> Les nouveaux workflows sont plus ciblés et incluent la vérification
> de la contrainte « APK < 25 Mo ». Pour éviter la duplication, vous
> pouvez désactiver `flutter_ci.yml` et `flutter_release.yml` via
> l'onglet Actions du repo GitHub (voir `workflows/README.md`).

### Voir les builds dans GitHub

1. Aller sur https://github.com/djabelo712/ExamBoost-Togo
2. Cliquer l'onglet **Actions**
3. Sélectionner le workflow dans la sidebar gauche :
   - **Build APK** pour les builds debug + release
   - **Build Web** pour les builds web + déploiement Pages
   - **Release APK** pour les releases taggées
4. Cliquer sur un run pour voir les logs de chaque job / step
5. Scroller en bas du run pour télécharger les artifacts (APK, web bundle)

### Télécharger un artifact

1. Ouvrir le run dans l'onglet **Actions**
2. Scroller en bas de la page du run (ou cliquer le job, puis scroller)
3. Sous **Artifacts**, cliquer le nom :
   - `examboost-debug-apk` — APK debug
   - `examboost-release-apks` — 3 APK release (zip)
   - `examboost-web` — bundle web (zip)
   - `examboost-release-v<version>` — APK de la release taggée
4. Le ZIP se télécharge. Pour un APK release, dézipper puis `adb install -r app-arm64-v8a-release.apk`

### Créer une release

```bash
# 1. Mettre à jour la version dans pubspec.yaml
#    version: 0.2.0+1

# 2. Commit + tag
git add pubspec.yaml
git commit -m "chore: bump version to 0.2.0"
git tag v0.2.0
git push origin main --tags

# 3. Le workflow release_apk.yml se déclenche automatiquement
#    → build 3 APK + crée une GitHub Release avec notes auto

# 4. Vérifier sur https://github.com/djabelo712/ExamBoost-Togo/releases
```

### Déployer le web bundle sur GitHub Pages

Le workflow `build_web.yml` déploie automatiquement le bundle web sur
la branche `gh-pages` à chaque push sur `main`. Pour activer GitHub Pages :

1. Aller dans **Settings > Pages** du repo
2. Source : **Deploy from a branch**
3. Branch : `gh-pages` / dossier `/ (root)`
4. Sauvegarder
5. L'app sera disponible sur
   `https://djabelo712.github.io/ExamBoost-Togo/`

> Le `--base-href "/ExamBoost-Togo/"` est déjà configuré dans le
> workflow pour fonctionner avec GitHub Pages sous-subpath.

## Optimisation de la taille APK

Si `check_apk_size.sh` ou le workflow GitHub échoue (APK > 25 Mo) :

1. **Lancer l'audit** :
   ```bash
   ./scripts/optimize_apk.sh
   ```
2. **Compresser les images PNG en WebP** (gain typique 50-70 %) :
   ```bash
   for f in assets/images/*.png; do
     cwebp -q 80 "$f" -o "${f%.png}.webp"
     rm "$f"
   done
   # Mettre à jour les références .png → .webp dans le code Dart
   ```
3. **Activer R8/ProGuard** dans `android/app/build.gradle` :
   ```gradle
   android {
     buildTypes {
       release {
         minifyEnabled true
         shrinkResources true
         proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
       }
     }
   }
   ```
4. **Retirer les assets non utilisés** :
   ```bash
   dart pub global activate dependency_validator
   dart pub global run dependency_validator:unused assets
   ```
5. **Réduire les polices** : préférer Material Symbols à un set
   iconique complet (~1 Mo). Une police typique pèse 200-500 Ko.
6. **Alléger les Lottie** : compresser le JSON avec `jq -c` :
   ```bash
   jq -c . lib/lottie/loading.json > lib/lottie/loading.min.json
   ```
7. **Rebuilder et vérifier** :
   ```bash
   ./scripts/build_apk_release.sh
   ./scripts/check_apk_size.sh build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
   ```

## Créer l'AVD low-end manuellement

Le script `test_on_low_end.sh` crée l'AVD automatiquement si elle
n'existe pas. Pour la créer manuellement :

```bash
# 1. Installer l'image système Android 9 (API 28) armeabi-v7a
sdkmanager "system-images;android-28;default;armeabi-v7a"
sdkmanager --licenses

# 2. Créer l'AVD
avdmanager create avd \
  -n examboost_low_end \
  -k "system-images;android-28;default;armeabi-v7a" \
  -d "Nexus 4"

# 3. Lancer
emulator -avd examboost_low_end -memory 2048 -no-window -no-audio

# 4. Lancer le test
./scripts/test_on_low_end.sh
```

Pour supprimer l'AVD :

```bash
avdmanager delete avd -n examboost_low_end
```

## Conventions

- **Shebang** : `#!/usr/bin/env bash` pour la portabilité.
- **Set options** : `set -euo pipefail` (fail-fast + erreurs sur
  variables non définies + pipeline en échec).
- **Répertoire de travail** : `cd "$(dirname "$0")/.."` au début de
  chaque script pour se placer à la racine du repo, indépendamment du
  répertoire d'où le script est lancé.
- **Aucune modification du code source Flutter** : tous les scripts ne
  font que lire les sources et écrire dans `build/` ou à la racine.
- **Emojis autorisés dans les `echo`** pour la lisibilité (pas dans le
  code source Flutter, conformément à la convention du projet).
- **Idempotence** : `flutter clean` au début de chaque build garantit
  un état reproductible.

## Production — checklist

- [ ] `./scripts/build_apk_release.sh` sans erreur
- [ ] `./scripts/check_apk_size.sh build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` OK
- [ ] `./scripts/check_apk_size.sh build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk` OK
- [ ] `./scripts/check_apk_size.sh build/app/outputs/flutter-apk/app-x86_64-release.apk` OK
- [ ] `./scripts/build_web.sh` sans erreur
- [ ] `./scripts/test_on_low_end.sh` — pas de crash, mémoire < 300 Mo
- [ ] Tag `v<x.y.z>` poussé → workflow `release_apk.yml` déclenché
- [ ] GitHub Release créée avec les 3 APK attachés
- [ ] Web bundle déployé sur `gh-pages` (Pages activé dans Settings)
- [ ] APK installé et testé sur un vrai téléphone Android 9+

