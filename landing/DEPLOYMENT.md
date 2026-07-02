# Déploiement de la landing — ExamBoost Togo

Guide de déploiement de la landing page Next.js 16 sur Vercel
(preview + production).

## 1. Pré-requis

| Outil       | Version | Installation                  |
|-------------|---------|-------------------------------|
| Node.js     | >= 20.9 | <https://nodejs.org>          |
| npm         | >= 10   | Inclus avec Node              |
| Vercel CLI  | >= 33   | `npm install -g vercel`       |

Vérifier :

```bash
node --version    # >= 20.9
npm --version
vercel --version
```

## 2. Premier déploiement (one-time setup)

### 2.1 Importer le projet dans Vercel

1. Aller sur <https://vercel.com> → **Add New → Project**.
2. Importer le repo `djabelo712/ExamBoost-Togo`.
3. Configurer :
   - **Root Directory** : `landing/`
   - **Framework Preset** : Next.js
   - **Build Command** : `npm run build`
   - **Output Directory** : `.next` (auto-détecté)
   - **Install Command** : `npm ci`
4. Cliquer **Deploy**.

### 2.2 Configurer les variables d'environnement

Dans Vercel > **Settings > Environment Variables**, ajouter (voir
`landing/.env.example`) :

| Variable                 | Valeur                                                | Environnements |
|--------------------------|-------------------------------------------------------|----------------|
| `NEXT_PUBLIC_API_URL`    | `https://examboost-togo.up.railway.app`               | Production     |
| `NEXT_PUBLIC_API_URL`    | `https://examboost-togo-staging.up.railway.app`       | Preview        |
| `NEXT_PUBLIC_API_URL`    | `http://localhost:8000`                               | Development    |
| `NEXT_PUBLIC_GITHUB_URL` | `https://github.com/djabelo712/ExamBoost-Togo`        | Tous           |
| `NEXT_PUBLIC_SITE_URL`   | `https://examboost-togo.vercel.app`                   | Production     |
| `BETA_WEBHOOK_URL`       | (optionnel) Slack/Mailchimp webhook                   | Production     |
| `NEXT_PUBLIC_POSTHOG_KEY`| `phc_...`                                             | Tous           |

> ⚠️ Les variables `NEXT_PUBLIC_*` sont **inlinées au build** : modifier la
> valeur nécessite un **redeploy** pour être prise en compte.

### 2.3 Lier le repo en local

```bash
cd ExamBoost-Togo/landing
vercel login       # one-time, interactive
vercel link        # sélectionne le projet Vercel
```

Cela crée `.vercel/project.json` (à commit, contient juste les IDs).

### 2.4 Premier deploy

```bash
# Depuis la racine du repo :
./scripts/deploy_landing.sh --prod
```

Vérifier :

```bash
curl -I https://examboost-togo.vercel.app
# HTTP/2 200 + headers de sécurité (X-Frame-Options: DENY, etc.)
```

## 3. Déploiements suivants

### Preview (branche `dev` ou PR)

```bash
./scripts/deploy_landing.sh
# ou
cd landing && vercel --yes
```

Vercel crée une URL de preview unique par branche :
`https://examboost-togo-git-<branch>.vercel.app`

### Production (branche `main`)

```bash
./scripts/deploy_landing.sh --prod
# ou
cd landing && vercel --prod --yes
```

## 4. Variables d'environnement (référence)

Voir `landing/.env.example`. Les variables sont séparées en 4 catégories :

1. **API** — `NEXT_PUBLIC_API_URL` (URL backend Railway)
2. **Repository** — `NEXT_PUBLIC_GITHUB_URL`
3. **Site** — `NEXT_PUBLIC_SITE_URL` (canonical + OpenGraph)
4. **Webhook** — `BETA_WEBHOOK_URL` (optionnel, pour forward les inscriptions beta)
5. **Analytics** — `NEXT_PUBLIC_POSTHOG_KEY`, `NEXT_PUBLIC_POSTHOG_HOST`

> ℹ️ Vercel injecte automatiquement les variables selon l'environnement de
> build (Production / Preview / Development). Configurez-les une fois par
> environnement dans le dashboard.

## 5. Domaine personnalisé

Pour mapper `examboost.tg` sur la landing Vercel :

1. Vercel > **Settings > Domains** → **Add** → `examboost.tg`.
2. Ajouter aussi `www.examboost.tg` (redirige vers `examboost.tg`).
3. Vercel génère les enregistrements DNS à configurer chez le registrar :
   - `A`     `@`     `76.76.21.21`
   - `CNAME` `www`   `cname.vercel-dns.com`
4. Attendre la propagation DNS (5 min - 24 h).
5. Vercel émet automatiquement un certificat SSL (Let's Encrypt).

Après cela, mettre à jour `NEXT_PUBLIC_SITE_URL` et `CORS_ORIGINS` (backend)
pour pointer vers `https://examboost.tg`.

## 6. Analytics

### PostHog (optionnel)

1. Créer un projet sur <https://posthog.com>.
2. Copier la project API key (`phc_...`).
3. L'ajouter dans Vercel : `NEXT_PUBLIC_POSTHOG_KEY`.
4. Ajouter le SDK PostHog dans `landing/app/layout.tsx` (à faire par
   l'agent principal — hors périmètre de cette tâche).

### Vercel Analytics (built-in)

Activable dans Vercel > **Settings > Analytics** (gratuit jusqu'à
un certain volume). Pas de code à ajouter.

### Web Vitals

Vercel capture automatiquement les Core Web Vitals (LCP, FID, CLS) par
déploiement. Visible dans **Analytics > Web Vitals**.

## 7. Sécurité

Le `vercel.json` configure les headers de sécurité suivants sur toutes
les routes :

| Header                   | Valeur                                  |
|--------------------------|-----------------------------------------|
| `X-Content-Type-Options` | `nosniff`                               |
| `X-Frame-Options`        | `DENY` (anti clickjacking)              |
| `X-XSS-Protection`       | `1; mode=block`                         |
| `Referrer-Policy`        | `strict-origin-when-cross-origin`       |
| `Permissions-Policy`     | `camera=(), microphone=(), geolocation=()` |

Cache immuable (1 an) sur les assets statiques sous `/assets/*`.

## 8. Troubleshooting

### Build échoue en local mais passe sur Vercel

- Vérifier la version Node (`>= 20.9`).
- Supprimer `node_modules` et `package-lock.json` :
  ```bash
  cd landing && rm -rf node_modules package-lock.json && npm install
  ```

### Variable d'env non prise en compte

Les `NEXT_PUBLIC_*` sont inlinées au build. Après modification :
1. Vercel > Settings > Environment Variables → modifier.
2. **Redeploy** (deployments > ... > Redeploy).

### Erreur 500 sur `/api/beta-signup`

1. Vérifier `data/signups.json` est writable (Vercel filesystem est
   read-only sauf `/tmp` — le file-based storage peut casser en prod).
2. Si `BETA_WEBHOOK_URL` est set, vérifier qu'il répond 200.

> ⚠️ La persistance dans `data/signups.json` ne marche **pas** en production
> Vercel (filesystem read-only). Pour la prod, brancher un vrai backend
> (KV, Supabase, ou forwarder vers le backend Railway via `NEXT_PUBLIC_API_URL`).

### Domaine personnalisé ne pointe pas

1. Vérifier les DNS : `dig examboost.tg` et `dig www.examboost.tg`.
2. Attendre 24 h max pour la propagation.
3. Vercel > Settings > Domains > "Invalid configuration" → cliquer pour
   voir les enregistrements attendus.

## 9. Bonnes pratiques

- ✅ Toujours tester en **Preview** avant de promouvoir en Production.
- ✅ Activer **Vercel Analytics** (gratuit) pour monitorer les Web Vitals.
- ✅ Configurer les **Deploy Comments** dans GitHub PRs (auto-preview URL).
- ✅ Garder le bundle léger (Next 16 + Tailwind 4 + framer-motion suffisent).
- ❌ Ne pas commit `.env.local` (uniquement `.env.example`).
- ❌ Ne pas activer `output: 'export'` (la route API `/api/beta-signup`
  nécessite le runtime Node serverless).
