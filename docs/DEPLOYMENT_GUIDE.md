# Guide de déploiement global — ExamBoost Togo

Document de référence pour l'infrastructure de déploiement complète du
projet ExamBoost Togo : backend FastAPI sur Railway, landing Next.js sur
Vercel, CI/CD GitHub Actions, monitoring, backup, et stratégie de scaling.

---

## 1. Architecture de déploiement

```
                          ┌──────────────────────────────┐
                          │     Utilisateurs (Togo)      │
                          │  App Flutter (mobile/web)    │
                          └──────────────┬───────────────┘
                                         │
                          ┌──────────────┴───────────────┐
                          │   HTTPS (REST + JWT)         │
                          └──────────────┬───────────────┘
                                         │
            ┌────────────────────────────┴────────────────────────────┐
            │                                                          │
            ▼                                                          ▼
┌─────────────────────────┐                          ┌─────────────────────────────┐
│  Vercel (Next.js 16)    │                          │  Railway (FastAPI)          │
│  Landing page beta      │   ─── REST /health ───►  │  + Uvicorn (4 workers)      │
│  + /api/beta-signup     │                          │  + Pydantic + SQLAlchemy    │
│                         │                          │  + IRT/BKT/SM-2 + Claude    │
│  examboost-togo.vercel.app                          │  examboost-togo.up.railway.app │
│  examboost.tg (custom)  │                          │                             │
└─────────────────────────┘                          └──────────────┬──────────────┘
                                                                   │
                                                                   ▼
                                                       ┌──────────────────────┐
                                                       │  Railway Postgres    │
                                                       │  (managed backup)    │
                                                       │  examboost DB        │
                                                       └──────────────────────┘
                                                                   │
                                                                   ▼
                                                       ┌──────────────────────┐
                                                       │  (optionnel)         │
                                                       │  Redis (cache +      │
                                                       │  rate-limit shared)  │
                                                       └──────────────────────┘
```

### Composants

| Composant      | Provider     | Plan             | Usage                           |
|----------------|--------------|------------------|---------------------------------|
| Backend API    | Railway      | Hobby ($5/mois)  | FastAPI + Uvicorn, 4 workers    |
| Postgres       | Railway      | Inclus Hobby     | DB principale (users, questions)|
| Landing        | Vercel       | Free tier        | Next.js 16, preview + prod      |
| DNS du domaine | Cloudflare/registar | gratuit   | `examboost.tg` → Vercel         |
| CI/CD          | GitHub Actions | 2000 min/mois gratuit | Build/test/deploy         |
| Monitoring     | Sentry / PostHog | Free tier    | Erreurs + product analytics     |
| Storage        | AWS S3 (af-south-1) | ~$0.023/Go | PDFs OCR, images questions    |

---

## 2. URLs (prod + staging)

| Service   | Environnement | URL                                                      |
|-----------|---------------|----------------------------------------------------------|
| Landing   | Production    | <https://examboost-togo.vercel.app>                      |
| Landing   | Custom domain | <https://examboost.tg>                                   |
| Landing   | Preview       | <https://examboost-togo-git-<branch>.vercel.app>         |
| Backend   | Production    | <https://examboost-togo.up.railway.app>                  |
| Backend   | Staging       | <https://examboost-togo-staging.up.railway.app>          |
| Backend   | Swagger       | <https://examboost-togo.up.railway.app/docs>             |
| Backend   | Health        | <https://examboost-togo.up.railway.app/health>           |
| Backend   | Stats         | <https://examboost-togo.up.railway.app/health/stats>     |
| Repo      | GitHub        | <https://github.com/djabelo712/ExamBoost-Togo>           |

---

## 3. Secrets management

### 3.1 Locaux (développeurs)

- `.env` (backend, **gitignored**) — copié depuis `.env.example`.
- `.env.local` (landing, **gitignored**) — copié depuis `.env.example`.

Vérifier le `.gitignore` contient :
```
.env
.env.local
.env.*.local
```

### 3.2 GitHub Secrets (CI/CD)

Pour que les workflows GitHub Actions déploient automatiquement, configurer
dans **GitHub repo > Settings > Secrets and variables > Actions** :

| Secret               | Usage                                                |
|----------------------|------------------------------------------------------|
| `RAILWAY_TOKEN`      | Service token Railway (Settings > Tokens)            |
| `VERCEL_TOKEN`       | Personal access token Vercel                         |
| `VERCEL_ORG_ID`      | Team ID Vercel                                       |
| `VERCEL_PROJECT_ID`  | Project ID Vercel                                    |
| `ADMIN_TOKEN`        | JWT admin (pour seed prod DB)                        |
| `ANTHROPIC_API_KEY`  | Pour tests d'intégration tutor chat (optionnel)      |

> ⚠️ Ne jamais logger ces secrets. Les scripts bash utilisent
> `set -euo pipefail` et ne les affichent jamais.

### 3.3 Railway variables

Dans Railway > **Service backend > Variables**, par environnement :

**Production :**
- `DATABASE_URL` = `${{Postgres.DATABASE_URL}}`
- `SECRET_KEY` = `<openssl rand -hex 32>`
- `ENVIRONMENT` = `production`
- `CORS_ORIGINS` = `["https://examboost-togo.vercel.app","https://examboost.tg"]`
- `ANTHROPIC_API_KEY` = `sk-ant-...`
- `SENTRY_DSN` = `https://...@sentry.io/...`

**Staging :**
- Idem production sauf :
- `ENVIRONMENT` = `staging`
- `LOG_LEVEL` = `debug`
- `CORS_ORIGINS` = `["https://examboost-togo-git-staging.vercel.app","http://localhost:3000"]`

### 3.4 Vercel variables

Dans Vercel > **Project > Settings > Environment Variables**, par
environnement (Production / Preview / Development) :

| Variable                  | Prod                                          | Preview                                       |
|---------------------------|-----------------------------------------------|-----------------------------------------------|
| `NEXT_PUBLIC_API_URL`     | `https://examboost-togo.up.railway.app`       | `https://examboost-togo-staging.up.railway.app` |
| `NEXT_PUBLIC_SITE_URL`    | `https://examboost-togo.vercel.app`           | `https://examboost-togo-git-<branch>.vercel.app` |
| `NEXT_PUBLIC_GITHUB_URL`  | `https://github.com/djabelo712/ExamBoost-Togo` | idem                                          |
| `NEXT_PUBLIC_POSTHOG_KEY` | `phc_...`                                     | idem (projet PostHog séparé si besoin)         |

### 3.5 Rotation des secrets

- **`SECRET_KEY`** (JWT) : rotation tous les 6 mois. En cas de rotation,
  tous les tokens JWT existants sont invalidés (utilisateurs doivent
  re-se connecter).
- **`RAILWAY_TOKEN`** : rotation annuelle ou après départ d'un membre.
- **`ANTHROPIC_API_KEY`** : rotation si compromission (tracking via
  dashboard Anthropic).
- **`ADMIN_TOKEN`** : généré on-demand via login admin + `python -c ...`.

---

## 4. CI/CD workflow

### 4.1 Workflows GitHub Actions existants

| Workflow                  | Fichier                            | Trigger                   |
|---------------------------|------------------------------------|---------------------------|
| Backend CI (test+lint+docker build) | `.github/workflows/backend_ci.yml` | push/PR sur `main`, paths `backend/**` |
| Flutter CI                | `.github/workflows/flutter_ci.yml` | push/PR sur `main`        |
| Flutter Release (APK)     | `.github/workflows/flutter_release.yml` | tag `v*.*.*`          |
| Data Pipeline CI          | `.github/workflows/data_pipeline_ci.yml` | push/PR, paths `data_pipeline/**` |

### 4.2 Workflow de déploiement recommandé (à ajouter)

```yaml
# .github/workflows/deploy.yml (à créer par l'agent principal)
name: Deploy
on:
  push:
    branches: [main]

jobs:
  deploy-backend:
    runs-on: ubuntu-latest
    if: github.event.commits[0].modified.any(path.startsWith('backend/'))
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20' }
      - run: npm install -g @railway/cli
      - run: ./scripts/deploy_backend.sh production
        env:
          RAILWAY_TOKEN: ${{ secrets.RAILWAY_TOKEN }}

  deploy-landing:
    runs-on: ubuntu-latest
    if: github.event.commits[0].modified.any(path.startsWith('landing/'))
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20' }
      - run: cd landing && npm ci
      - run: ./scripts/deploy_landing.sh --prod
        env:
          VERCEL_TOKEN: ${{ secrets.VERCEL_TOKEN }}
          VERCEL_ORG_ID: ${{ secrets.VERCEL_ORG_ID }}
          VERCEL_PROJECT_ID: ${{ secrets.VERCEL_PROJECT_ID }}

  health-check:
    needs: [deploy-backend, deploy-landing]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: ./scripts/health_check.sh
        env:
          BACKEND_URL: https://examboost-togo.up.railway.app
          LANDING_URL: https://examboost-togo.vercel.app
```

### 4.3 Flow de release (manuel)

1. Développer sur une branche `feat/xxx` ou `fix/xxx`.
2. Ouvrir une PR → CI tourne (tests + lint + build).
3. Merge dans `main` → déploiement auto **staging** + preview Vercel.
4. Tester en staging (QA manuelle + smoke tests via `health_check.sh`).
5. Promouvoir en production : `./scripts/deploy_all.sh --prod`.
6. Vérifier `health_check.sh` en prod.
7. Si incident : `./scripts/rollback_backend.sh production`.

---

## 5. Monitoring

### 5.1 Health endpoints (backend)

| Endpoint              | Fréquence suggérée | Alerte si                  |
|-----------------------|--------------------|----------------------------|
| `/health`             | 30s                | HTTP != 200 pendant > 2 min|
| `/health/ready`       | 1 min              | status != "ready"          |
| `/health/stats`       | 5 min              | `users` < 1 après seed     |
| `/docs`               | 1 h                | HTTP != 200                |

Configurer un ping avec **UptimeRobot** (gratuit) ou **BetterUptime** :

```
URL     : https://examboost-togo.up.railway.app/health
Méthode : GET
Expect  : 200
Timeout : 10s
Fréquence: 5 min
Alerte  : email + Slack webhook
```

### 5.2 Erreurs (Sentry)

1. Créer un projet Sentry (Python pour backend, Next.js pour landing).
2. Backend : `pip install sentry-sdk[fastapi]` + init dans `main.py`.
3. Landing : `npm install @sentry/nextjs` + `sentry.config.ts`.
4. Set `SENTRY_DSN` dans Railway et Vercel.

> ℹ️ L'intégration Sentry n'est pas incluse dans cette tâche (hors
> périmètre). Documentation laissée pour l'agent principal.

### 5.3 Performance (PostHog + Vercel Analytics)

- **Vercel Analytics** : built-in, gratuit. Visible dans
  Vercel > Analytics.
- **PostHog** : product analytics (funnels, retention). SDK à ajouter
  dans `landing/app/layout.tsx`.
- **Railway metrics** : CPU/RAM par service. Visible dans
  Railway > Service > Metrics.

### 5.4 Logs centralisés

- **Backend** : `railway logs --service examboost-backend --environment production`
- **Landing** : Vercel > Project > Logs (runtime + build)
- **CI/CD** : GitHub Actions > Workflow runs

Pour une centralisation, forwarder les logs Railway vers Logtail ou
Loggly (via webhook).

---

## 6. Backup base de données

### 6.1 Backup automatique Railway

Railway effectue des snapshots quotidiens du Postgres (rétention 7 jours
en Hobby plan, 30 jours en Pro). Visible dans :
**Railway > Postgres service > Settings > Backups**.

### 6.2 Backup manuel (scripté)

```bash
# Dump complet de la DB prod
railway connect --service postgres --environment production \
    pg_dump $DATABASE_URL --no-owner --clean > backup_$(date +%Y%m%d).sql
```

À scripter en cron (GitHub Action quotidienne ou Railway cron service) :

```yaml
# .github/workflows/backup_db.yml (à créer)
name: Backup Database
on:
  schedule:
    - cron: '0 3 * * *'   # tous les jours à 03:00 UTC
jobs:
  backup:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: |
          curl -X POST "$RAILWAY_DB_BACKUP_WEBHOOK" \
            -H "Authorization: Bearer $RAILWAY_TOKEN"
        env:
          RAILWAY_TOKEN: ${{ secrets.RAILWAY_TOKEN }}
```

### 6.3 Restore

```bash
# Restore sur staging (test)
railway connect --service postgres --environment staging \
    psql $DATABASE_URL < backup_20260101.sql
```

---

## 7. Disaster recovery

### 7.1 Plan de reprise

| Scénario                | RTO   | RPO   | Action                                  |
|-------------------------|-------|-------|-----------------------------------------|
| Backend down            | 5 min | 0     | Railway auto-restart (ON_FAILURE, 3x)   |
| Backend déployé cassé   | 5 min | 0     | `./scripts/rollback_backend.sh`         |
| DB corrompue            | 30 min | 24 h | Restore depuis snapshot Railway         |
| Region Railway down     | 1 h   | 24 h | Redéployer sur autre region (manuelle)  |
| Vercel down             | 30 min | 0   | Basculer DNS vers backup (Netlify)      |
| GitHub down             | 2 h   | 0    | Railway peut redéployer depuis cache    |

### 7.2 Procédure de rollback complète

1. **Identifier** le problème (Sentry / alerte UptimeRobot / log).
2. **Rollback backend** :
   ```bash
   ./scripts/rollback_backend.sh production
   ```
3. **Rollback landing** : Vercel > Deployments > sélectionner le précédent >
   **Promote to Production**.
4. **Rollback DB** (si data loss) : Railway > Postgres > Backups > Restore.
5. **Communiquer** : notification Slack/WhatsApp à l'équipe.
6. **Post-mortem** : documenter dans `docs/INCIDENTS.md` (à créer).

### 7.3 Tests de reprise (quarterly)

- Restaurer un backup sur un environment de test, vérifier l'app.
- Simuler un déploiement cassé (commit une erreur syntaxique) → tester le
  rollback.
- Vérifier que `health_check.sh` détecte bien le problème.

---

## 8. Estimation des coûts

### 8.1 Coûts récurrents (mensuels)

| Service         | Plan              | Coût      | Notes                            |
|-----------------|-------------------|-----------|----------------------------------|
| Railway         | Hobby             | $5        | 500h CPU, 1 GB RAM               |
| Railway Postgres| Inclus Hobby      | $0        | 1 GB stockage                    |
| Vercel          | Hobby (free)      | $0        | 100 GB bandwidth, 100h build     |
| GitHub Actions  | Free              | $0        | 2000 min/mois                    |
| Domaine `.tg`   | Annuel            | ~$50/an = $4/mois | via registar togolais      |
| Sentry          | Developer (free)  | $0        | 5000 errors/mois                 |
| PostHog         | Open-source (free)| $0        | Self-hosted OU Cloud free tier   |
| Anthropic Claude| Pay-as-you-go     | $5-30     | Selon usage tutor chat           |
| AWS S3          | Free tier +       | $1-5      | 20 Go à $0.023/Go + requests     |
| Cloudflare DNS  | Free              | $0        |                                  |
| **Total estimé**|                   | **~$15-50/mois** |                          |

### 8.2 Scaling (cost projection)

| Utilisateurs  | Backend | DB      | Claude API | Total        |
|---------------|---------|---------|------------|--------------|
| 100 beta      | $5      | inclus  | $5         | ~$15/mois    |
| 1 000 actifs  | $20     | $5      | $30        | ~$60/mois    |
| 10 000 actifs | $50     | $20     | $200       | ~$280/mois   |
| 50 000 actifs | $200    | $50     | $1 000     | ~$1 300/mois |

> Claude API est le poste qui scale le plus vite. Envisager un cache Redis
> + un quota par utilisateur (déjà 30 questions/heure/user).

---

## 9. Stratégie de scaling

### 9.1 Vertical ( Railway)

Augmenter les ressources du service backend :
- CPU : 0.5 vCPU → 2 vCPU → 8 vCPU
- RAM : 512 MB → 2 GB → 8 GB
- Workers Uvicorn : `--workers 4` → `--workers 8` (1 worker / vCPU)

Modifier dans Railway > Service > Settings > Resources.

### 9.2 Horizontal (Railway)

Augmenter `numReplicas` dans `railway.json` :
```json
"deploy": {
    "numReplicas": 2,
    ...
}
```
⚠️ Avec plusieurs replicas, le rate limiting in-memory ne marche plus →
activer Redis (`REDIS_URL`) pour partager le state entre workers.

### 9.3 Database

- Activer le **connection pooler** Railway (PgBouncer) si > 100
  connections simultanées.
- Ajouter des **indexes** sur les colonnes souvent filtrées
  (`user_id`, `question_id`, `matiere`).
- Envisager un **read replica** au-delà de 10 000 utilisateurs actifs.

### 9.4 Cache (Redis)

Pour réduire la charge DB :
- Cache des questions par matière (TTL 1 h)
- Cache des stats BKT par user (TTL 5 min)
- Cache des prédictions XGBoost (TTL 24 h)

### 9.5 CDN

Vercel fait office de CDN pour la landing. Pour le backend :
- Cloudflare en front de Railway (cache des réponses GET)
- Activer `Cache-Control` sur `/openapi.json`, `/health/*` (court TTL)

---

## 10. Checklist pré-pitch (24 juillet 2026)

Avant le pitch DJANTA Tech Hub, vérifier :

- [ ] Backend déployé en prod : `https://examboost-togo.up.railway.app/health` 200 OK
- [ ] Landing déployée en prod : `https://examboost-togo.vercel.app` 200 OK
- [ ] Domaine `examboost.tg` pointe vers Vercel + SSL actif
- [ ] Base seeded : `/health/stats` retourne > 0 questions
- [ ] CORS configuré pour `https://examboost.tg` et `https://examboost-togo.vercel.app`
- [ ] `SECRET_KEY` en prod différent de dev
- [ ] Sentry + PostHog branchés (optionnel mais recommandé)
- [ ] Backup DB automatique actif
- [ ] `health_check.sh` en cron UptimeRobot (5 min)
- [ ] Démo Flutter connectée au backend prod (variable `API_URL` dans
      `lib/services/api_service.dart` ou équivalent)
- [ ] Test end-to-end : register → login → répondre à une question →
      voir stats → tutor chat
- [ ] Plan B : APK Flutter fonctionnel offline (en cas de panne réseau
      pendant le pitch)

---

## 11. Liens utiles

| Ressource                    | URL                                                            |
|------------------------------|----------------------------------------------------------------|
| Railway dashboard            | <https://railway.app/dashboard>                                |
| Vercel dashboard             | <https://vercel.com/dashboard>                                 |
| GitHub repo                  | <https://github.com/djabelo712/ExamBoost-Togo>                 |
| Anthropic console            | <https://console.anthropic.com>                                |
| Sentry dashboard             | <https://sentry.io>                                            |
| PostHog Cloud                | <https://app.posthog.com>                                      |
| UptimeRobot                  | <https://uptimerobot.com>                                      |
| Domaine `.tg` (Cafenet)      | <https://www.nic.tg>                                           |
| Dockerfile reference         | `backend/Dockerfile`                                           |
| railway.json reference       | `backend/railway.json`                                         |
| vercel.json reference        | `landing/vercel.json`                                          |
| Scripts de déploiement       | `scripts/README.md`                                            |
| Backend DEPLOYMENT           | `backend/DEPLOYMENT.md`                                        |
| Landing DEPLOYMENT           | `landing/DEPLOYMENT.md`                                        |

---

## 12. Glossaire

- **RTO** (Recovery Time Objective) : temps max pour restaurer un service.
- **RPO** (Recovery Point Objective) : perte de données max acceptable.
- **Healthcheck** : endpoint qui confirme qu'un service est vivant/sain.
- **Liveness probe** : le process est-il vivant ? (peut redémarrer si non)
- **Readiness probe** : le service peut-il recevoir du trafic ? (peut
  enlever du trafic si non)
- **Multi-stage build** : Dockerfile avec plusieurs `FROM` pour réduire
  la taille de l'image finale.
- **Non-root user** : utilisateur Linux sans privilèges, pour limiter
  l'impact d'une vulnérabilité.
- **Preview deployment** : déploiement temporaire (Vercel) par branche/PR.
- **Staging environment** : environment Railway miroir de la prod pour
  tester avant de promouvoir.
- **Rollback** : restaurer la version précédente d'un déploiement.

---

*Document maintenu par l'Agent AF — Session 3, Vague 1.*
*Pour toute modification, ouvrir une PR et tagger `@djabelo712`.*
