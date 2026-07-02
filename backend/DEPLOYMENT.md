# Déploiement du backend — ExamBoost Togo

Guide de déploiement du backend FastAPI sur Railway (staging + production).

## 1. Pré-requis

| Outil            | Version  | Installation                          |
|------------------|----------|---------------------------------------|
| Railway CLI      | >= 3.0   | `npm install -g @railway/cli`         |
| Docker (optionnel) | >= 24  | Pour builds locaux                    |
| Python           | 3.11     | Pour tests en local                   |
| `jq`             | >= 1.6   | Parsing JSON des commandes Railway    |

Vérifier :

```bash
railway --version
docker --version
jq --version
```

## 2. Premier déploiement (one-time setup)

### 2.1 Créer le projet Railway

1. Aller sur <https://railway.app> → **New Project** → **Deploy from GitHub repo**.
2. Sélectionner `djabelo712/ExamBoost-Togo`.
3. Railway crée automatiquement un service à partir du `Dockerfile` détecté
   dans `backend/`.

### 2.2 Ajouter une base Postgres

1. Dans le projet Railway → **New → Database → PostgreSQL**.
2. Railway crée une variable `DATABASE_URL` dans le service backend.
3. Vérifier que `backend/railway.json` référence bien `${{Postgres.DATABASE_URL}}`.

### 2.3 Configurer les variables d'environnement

Dans Railway → **Service backend → Variables**, ajouter (voir
`backend/.env.example` pour la liste complète) :

| Variable                  | Valeur exemple                                   |
|---------------------------|--------------------------------------------------|
| `SECRET_KEY`              | `openssl rand -hex 32`                           |
| `ENVIRONMENT`             | `production`                                     |
| `LOG_LEVEL`               | `info`                                           |
| `CORS_ORIGINS`            | `https://examboost-togo.vercel.app`              |
| `ANTHROPIC_API_KEY`       | `sk-ant-...` (optionnel — tutor chat)            |
| `ADMIN_EMAIL`             | `admin@examboost.tg`                             |

### 2.4 Lier le repo en local

```bash
cd ExamBoost-Togo
railway login
railway link   # sélectionne le projet + service + environment
```

### 2.5 Premier deploy

```bash
./scripts/deploy_backend.sh staging
```

Le script :
1. Push le code (`railway up`)
2. Attend la promotion (~2 min)
3. Health check sur `/health`

Vérifier manuellement :

```bash
curl https://<staging-url>/health
curl https://<staging-url>/docs        # Swagger UI
```

### 2.6 Seed de la base

```bash
ADMIN_TOKEN="<jwt-admin>" \
  BACKEND_URL=https://<staging-url> \
  ./scripts/seed_prod_db.sh
```

> Le seed est **idempotent** : re-lancer ne duplique pas les questions.

## 3. Mise à jour (déploiements suivants)

```bash
# Après un commit/push sur main :
./scripts/deploy_backend.sh production
```

Pour un déploiement staging :

```bash
./scripts/deploy_backend.sh staging
```

## 4. Gestion des environnements

Railway gère deux environnements par projet (à activer dans
**Settings > Environments**) :

| Environnement | Usage                          | URL attendue                                  |
|---------------|--------------------------------|-----------------------------------------------|
| `staging`     | Tests pre-prod, branche `dev`  | `https://examboost-togo-staging.up.railway.app` |
| `production`  | Live, branche `main`           | `https://examboost-togo.up.railway.app`       |

Le `railway.json` définit les variables par environnement :
- `staging` : `LOG_LEVEL=debug`, `ENVIRONMENT=staging`, CORS Vercel preview
- `production` : `LOG_LEVEL=info`, `ENVIRONMENT=production`, CORS Vercel prod + domaine personnalisé

## 5. Variables d'environnement (référence complète)

Voir `backend/.env.example` pour la liste exhaustive et les commentaires.
Catégories :

1. **Base de données** — `DATABASE_URL`
2. **Auth / JWT** — `SECRET_KEY`, `ALGORITHM`, `ACCESS_TOKEN_EXPIRE_MINUTES`
3. **CORS** — `CORS_ORIGINS` (JSON array OU CSV)
4. **BKT / IRT** — `BKT_P_LEARN`, `BKT_P_SLIP`, `BKT_P_GUESS`, `BKT_MASTERY_THRESHOLD`
5. **APIs externes** — `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `AFRICASTALKING_*`
6. **Redis** — `REDIS_URL` (optionnel)
7. **Storage** — `S3_*` (optionnel, pour OCR)
8. **Monitoring** — `POSTHOG_API_KEY`, `SENTRY_DSN`
9. **Runtime** — `ENVIRONMENT`, `LOG_LEVEL`, `PORT`

> ⚠️ Ne jamais committer le vrai `.env`. Le fichier `.env.example` est la
> source de vérité publique.

## 6. Health checks

Le backend expose plusieurs endpoints de santé (définis dans
`backend/healthcheck.py`) :

| Endpoint            | Description                                   | Code retour     |
|---------------------|-----------------------------------------------|-----------------|
| `GET /health`       | Healthcheck simple (déjà dans `main.py`)      | 200 + JSON      |
| `GET /health/live`  | Liveness : process vivant ?                   | 200 toujours    |
| `GET /health/ready` | Readiness : DB joignable ?                    | 200 ou 503      |
| `GET /health/detailed` | DB + Redis + config (sans secrets)         | 200 + JSON      |
| `GET /health/stats` | Comptes questions/users/responses/simulations | 200 + JSON      |

> ℹ️ Les routes `/health/*` sont exposées par `health_router` dans
> `healthcheck.py`. Pour les activer, ajouter dans `main.py` :
> ```python
> from healthcheck import health_router
> app.include_router(health_router, tags=["meta"])
> ```
> (intégration à faire par l'agent principal — hors périmètre de cette tâche)

Railway utilise `/health` (`healthcheckPath` dans `railway.json`) avec un
timeout de 30s et `restartPolicyType: ON_FAILURE` (3 retries max).

Le `Dockerfile` inclut aussi un `HEALTHCHECK` Docker natif qui sonde
`/health` toutes les 30s.

## 7. Logs et monitoring

### Logs Railway

```bash
railway logs --service examboost-backend --environment staging
railway logs --service examboost-backend --environment production
```

### Métriques Railway (dashboard)

- CPU / RAM / Disk
- Request count
- Deployment history
- Build duration

### Monitoring externe (optionnel)

- **Sentry** : erreur tracking (set `SENTRY_DSN`)
- **PostHog** : product analytics (set `POSTHOG_API_KEY`)
- **UptimeRobot / BetterUptime** : ping `/health` toutes les 5 min

## 8. Rollback

### Via CLI

```bash
./scripts/rollback_backend.sh staging
./scripts/rollback_backend.sh production
```

### Via dashboard

1. Railway > Service > **Deployments**
2. Sélectionner le déploiement précédent (✅ Healthy)
3. Menu `...` → **Redeploy** ou **Rollback**

Railway conserve l'historique complet des builds : un rollback est
instantané (pas de rebuild).

## 9. Troubleshooting

### Le déploiement échoue pendant le build Docker

```bash
# Build local pour reproduire
docker build -t examboost-backend:debug ./backend
docker run --rm -p 8000:8000 examboost-backend:debug
```

Causes fréquentes :
- `requirements.txt` : version de package incompatible → fixer une version.
- `apt-get` : paquet système manquant → l'ajouter dans le stage `dependencies`.
- `pip` : cache corrompu → ajouter `--no-cache-dir`.

### Le conteneur démarre mais `/health` répond 503 / timeout

1. Vérifier la DB : `DATABASE_URL` correcte ? Postgres Railway démarré ?
2. Logs : `railway logs --service examboost-backend --environment <env>`
3. Test direct : `curl https://<url>/health/detailed` pour voir l'erreur DB.

### `railway up` reste bloqué

- Vérifier `RAILWAY_TOKEN` valide (Settings > Tokens > service token).
- Vérifier le quota Railway (free tier = 500h/mois, 1 GB RAM).

### Erreur CORS depuis le frontend Vercel

1. Vérifier `CORS_ORIGINS` dans Railway (doit inclure l'URL Vercel exacte).
2. Format accepté : `["https://examboost-togo.vercel.app"]` (JSON)
   ou `https://examboost-togo.vercel.app` (CSV).
3. Après modif, **redeploy** le service pour que la variable soit prise en compte.

### Le seed ne fonctionne pas

1. Vérifier que `ADMIN_TOKEN` est un JWT valide pour un user admin
   (`is_admin=true` dans la table `users`).
2. Si l'endpoint `/admin/seed` n'existe pas encore, fallback :
   ```bash
   DATABASE_URL='<postgres-url>' python backend/scripts/seed_db.py
   ```
3. Vérifier le JSON de seed : `backend/data/questions_seed.json` présent ?

## 10. Bonnes pratiques

- ✅ Toujours déployer en `staging` d'abord, tester, puis `production`.
- ✅ Garder le `requirements.txt` minimal (pas de dev deps en prod).
- ✅ Surveiller les logs après chaque déploiement (5-10 min).
- ✅ Mettre à jour `.env.example` quand une nouvelle variable est ajoutée.
- ❌ Ne jamais commit de `.env` avec de vraies valeurs.
- ❌ Ne jamais déployer en prod sans health check (`./scripts/health_check.sh`).
