# ExamBoost Togo — Landing page Next.js 16

Landing page standalone pour la campagne de beta testeurs d'ExamBoost Togo.
Objectif : capturer les e-mails de 500 premiers beta testeurs (élèves,
enseignants, directeurs) avant le pilote Lomé 2026.

> Stack : **Next.js 16** (App Router) + **TypeScript** + **Tailwind CSS 4** +
> **shadcn/ui** codés manuellement + **React Hook Form + Zod** +
> **Framer Motion** + **next/font** (Outfit + Inter).

---

## Démarrage rapide

### Prérequis

- **Node.js** ≥ 20.9.0 (Next.js 16 requires Node 20+)
- **npm** ≥ 10 (ou pnpm / yarn — adapt commands accordingly)

### Installation

```bash
cd landing
npm install
npm run dev
```

L'app tourne sur **http://localhost:3000**.

### Scripts disponibles

| Script              | Description                              |
| ------------------- | ---------------------------------------- |
| `npm run dev`       | Démarre Next.js en mode développement    |
| `npm run build`     | Build de production                      |
| `npm run start`     | Lance le serveur de production           |
| `npm run lint`      | ESLint via `next lint`                   |
| `npm run typecheck` | Vérification TypeScript stricte (`tsc`)  |

---

## Structure du dossier

```
landing/
├── app/
│   ├── layout.tsx                  # Layout racine + fonts Outfit/Inter + SEO metadata
│   ├── page.tsx                    # Landing page (compose les 11 sections)
│   ├── globals.css                 # Tailwind 4 + tokens theme @theme
│   ├── api/beta-signup/route.ts    # POST {email, role} → JSON
│   └── merci/page.tsx              # Page de remerciement après inscription
├── components/
│   ├── ui/                         # shadcn/ui manuels (button, input, card, badge)
│   ├── Navbar.tsx                  # Sticky + blur + logo EB inline
│   ├── Hero.tsx                    # H1 + sous-titre + EmailForm + trust badges
│   ├── ProblemSection.tsx          # 3 stats animées (44 %, 86 %, 0)
│   ├── SolutionSection.tsx         # 3 piliers (Adaptatif, Localisé, Hors-ligne)
│   ├── FeaturesSection.tsx         # 5 features + carte stats
│   ├── HowItWorks.tsx              # 3 étapes
│   ├── TestimonialsSection.tsx     # 2 citations élèves
│   ├── PricingSection.tsx          # 2 cartes (Élève gratuit, École 100k FCFA)
│   ├── FAQSection.tsx              # 8 questions accordéon accessible
│   ├── BetaCTA.tsx                 # Section finale email capture + compteur
│   ├── Footer.tsx                  # 4 colonnes + GitHub + © 2026
│   └── EmailForm.tsx               # Formulaire réutilisable (idle/loading/success/error)
├── lib/
│   ├── utils.ts                    # cn() helper (clsx + tailwind-merge)
│   └── validators.ts               # Zod schemas (email + rôle)
├── data/signups.json               # Stockage local des inscriptions (init [])
├── public/
│   ├── favicon.svg                 # Favicon vert Togo + "EB"
│   └── og-image.svg                # Open Graph image 1200×630
├── next.config.ts
├── tsconfig.json
├── tailwind.config.ts              # Compat — Tailwind 4 lit surtout @theme
├── postcss.config.mjs              # Plugin @tailwindcss/postcss
├── .env.example
├── .gitignore
├── package.json
└── README.md (ce fichier)
```

---

## API endpoint — `POST /api/beta-signup`

### Requête

```http
POST /api/beta-signup
Content-Type: application/json

{
  "email": "amina@example.tg",
  "role": "eleve"
}
```

`role` doit être l'une de ces valeurs : `eleve`, `enseignant`, `directeur`, `autre`.

### Réponses

| Status | Body                                           | Cas                            |
| ------ | ---------------------------------------------- | ------------------------------ |
| 200    | `{ "ok": true, "message": "Merci !" }`         | Inscription réussie            |
| 400    | `{ "error": "Email invalide" }`                | Body JSON invalide ou email mal formé |
| 409    | `{ "error": "Email déjà inscrit" }`            | E-mail déjà présent            |
| 500    | `{ "error": "Erreur serveur" }`                | Problème de persistance        |

### Stockage

Les inscriptions sont sauvegardées dans `data/signups.json` sous la forme :

```json
[
  {
    "email": "amina@example.tg",
    "role": "eleve",
    "date": "2026-07-01T14:32:00.000Z"
  }
]
```

> **Note production** : ce stockage fichier convient pour la bêta. Pour passer à
> l'échelle, branchez Postgres (Neon, Supabase) ou une table Vercel KV en
> remplaçant les fonctions `readSignups` / `writeSignups` du fichier
> `app/api/beta-signup/route.ts`.

### GET /api/beta-signup

Endpoint utilitaire pour débogage — retourne `{ "count": N }` (le nombre
d'inscrits). À supprimer ou sécuriser en production.

### Exemple cURL

```bash
curl -X POST http://localhost:3000/api/beta-signup \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.tg","role":"eleve"}'
```

---

## Déploiement sur Vercel (3 étapes)

1. **Push le dossier `landing/` sur GitHub** — le repo `djabelo712/ExamBoost-Togo`
   contient déjà ce dossier.

2. **Importer le projet sur Vercel** :
   - Va sur <https://vercel.com/new>
   - Sélectionne le repo `ExamBoost-Togo`
   - **Root Directory** : `landing` (important — Vercel doit savoir que le
     projet Next.js est dans ce sous-dossier)
   - Framework Preset : Next.js (auto-détecté)
   - Build Command / Output : laisser par défaut (`next build`)
   - Cliquer **Deploy**

3. **Configurer les variables d'environnement** (optionnel) :
   - `NEXT_PUBLIC_SITE_URL` = `https://examboost-landing.vercel.app`
     (utilisée pour les métadonnées SEO canoniques et Open Graph)
   - Le déploiement fonctionne sans aucune variable d'environnement.

Le site est live en moins de 2 minutes sur un sous-domaine `*.vercel.app`.
Pour un domaine personnalisé (`examboost.tg`), ajoute-le dans
**Settings → Domains** sur le dashboard Vercel.

---

## Personnalisation

### Couleurs

Toutes les couleurs de marque sont définies dans `app/globals.css` sous le
bloc `@theme`. Modifier une couleur ici la propage partout (boutons, badges,
sections, etc.) :

```css
@theme {
  --color-togo-green: #006837;
  --color-togo-orange: #d97700;
  /* ... */
}
```

Le fichier `tailwind.config.ts` (racine du dossier `landing/`) est conservé
pour le tooling IDE mais Tailwind 4 lit prioritairement `@theme`.

### Sections

Chaque section est un composant isolé dans `components/`. Pour réordonner,
édite `app/page.tsx`. Pour retirer une section, commente-la simplement.

### Textes de contenu

Tous les textes sont en dur dans les composants (FR pour le contenu, EN pour
les commentaires / le code). Aucun système i18n pour la bêta — si tu veux
ajouter une locale EN, branche `next-intl`.

### Compteur d'inscrits (BetaCTA)

Le compteur affiche actuellement `INSCRITS_BASE = 234` inscrits (valeur
statique dans `components/BetaCTA.tsx`). Pour le rendre dynamique :

1. Crée une route `GET /api/beta-signup/count` qui renvoie `{ count: N }`.
2. Hydrate le composant `BetaCTA` côté client via `useEffect` + `fetch`.

---

## Accessibilité

- Skip-link « Aller au contenu » (clavier).
- Tous les champs ont un `<label>` (visible ou `sr-only`).
- Le formulaire d'e-mail expose `aria-invalid` et un message `role="alert"`.
- L'accordéon FAQ utilise `aria-expanded`, `aria-controls`, `role="region"`.
- Le compteur bêta expose `role="progressbar"` avec `aria-valuenow/min/max`.
- Focus visible (vert Togo) sur tous les éléments interactifs.
- `prefers-reduced-motion` désactive les animations Framer Motion.
- Hiérarchie de titres `<h1>` → `<h2>` → `<h3>` respectée.

## Performance

- **next/font** pour Outfit + Inter (self-hosted, `display: swap`).
- SVG inline pour favicon + OG image (zéro image raster).
- Aucune lib graphique lourde (pas de recharts/d3 côté client).
- `experimental.optimizePackageImports` sur `lucide-react` et `framer-motion`.
- Les composants qui n'ont pas besoin de JS client sont des Server Components.

---

## Licence

Propriétaire — © 2026 ExamBoost Togo (SmartFarm Togo / AIMS Ghana).
Tous droits réservés.
