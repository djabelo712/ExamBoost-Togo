# Guide de contribution — ExamBoost Togo

Ce document regroupe toutes les conventions, regles et procedures a suivre pour contribuer au projet ExamBoost Togo. Il s'adresse aux developpeurs de l'equipe interne (SmartFarm Togo / AIMS Ghana) ainsi qu'aux futurs contributeurs externes (open-source) apres lancement public. L'objectif est de garder un code coherent, testable et lisible malgre la diversite des technologies (Flutter/Dart, Python/FastAPI, scripts OCR).

Avant toute contribution, lire egalement : `docs/ARCHITECTURE.md` (architecture technique complete) et le `README.md` principal (vision produit).

---

## Sommaire

1. Prerequis
2. Setup environnement
3. Structure du projet
4. Conventions de code
5. Workflow Git
6. Avant de committer
7. Ajouter une question
8. Ajouter un ecran
9. Tests
10. Deploiement
11. Communication equipe
12. Roadmap

---

## 1. Prerequis

### 1.1 Materiel et OS

- **OS** : Linux (Ubuntu 22.04+ recommande), macOS 13+, ou Windows 11 avec WSL2.
- **RAM** : 8 Go minimum (16 Go recommande pour le dev Flutter + emulateur Android).
- **Disque** : 20 Go libres (Flutter SDK + Android Studio + caches).
- **CPU** : 4 cœurs minimum (compile Flutter lourde).

### 1.2 Logiciels

- **Flutter SDK** 3.44+ ([flutter.dev](https://flutter.dev)) — verifier avec `flutter --version`.
- **Dart** 3.4+ (inclu avec Flutter).
- **Python** 3.11+ (pour le backend et le pipeline OCR).
- **Git** 2.34+ avec signature GPG/SSH optionnelle.
- **VS Code** (recommande) ou Android Studio Hedgehog+.
- **Android Studio** avec SDK Android 34 + Build Tools 34.0.0 + Platform Tools.
- **Cursor Pro** (recommande pour la productivite IA, editeur base sur VS Code).
- **Docker** 24+ (pour builds backend reproductibles).
- **Tesseract OCR** 5.3+ avec le pack de langue francaise (pour le pipeline OCR).
- **Node.js** 20+ (pour la landing Next.js, optionnel sauf si on touche a `landing/`).

### 1.3 Comptes et acces

- Compte GitHub avec acces au repo `djabelo712/ExamBoost-Togo`.
- Compte Railway (pour test backend staging).
- Compte Vercel (pour preview landing).
- Acces au worklog partage : `/home/z/my-project/worklog.md` (equipe interne) ou clone du repo.

### 1.4 Verification du setup

```bash
flutter doctor -v
python3 --version
git --version
docker --version
```

Les 4 doivent retourner des versions valides sans erreur. Si `flutter doctor` signale un probleme (ex. licence Android non acceptee), le resoudre avant de continuer.

---

## 2. Setup environnement

### 2.1 Clone et script d'initialisation

```bash
git clone https://github.com/djabelo712/ExamBoost-Togo.git
cd ExamBoost-Togo
chmod +x setup.sh && ./setup.sh
```

Le script `setup.sh` execute les etapes suivantes :

1. `flutter pub get` — installe les dependances Flutter.
2. `dart run build_runner build --delete-conflicting-outputs` — genere les adaptateurs Hive (`*.g.dart`).
3. `flutter analyze` — analyse statique, doit passer sans warnings.
4. Propose d'installer et lancer le backend FastAPI (repondre `y` ou `n`).

### 2.2 Setup manuel (si le script echoue)

```bash
# Dependances Flutter
flutter pub get

# Generer les adaptateurs Hive (question.g.dart, review_card.g.dart, user.g.dart)
dart run build_runner build --delete-conflicting-outputs

# Lancer l'app sur Android (ou Chrome pour demo web)
flutter run

# Backend (optionnel)
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python -m scripts.seed_db        # peuple la DB avec 64+ questions
uvicorn main:app --reload        # -> http://localhost:8000/docs

# Pipeline OCR (optionnel)
cd ../data_pipeline
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Landing (optionnel)
cd ../landing
npm install
npm run dev                      # -> http://localhost:3000
```

### 2.3 Variables d'environnement locales

Copier les fichiers `.env.example` en `.env` (backend) et `.env.local` (landing), puis remplir avec les cles API recuperees aupres du lead dev :

```bash
cp backend/.env.example backend/.env
cp landing/.env.example landing/.env.local
```

Verifier que le `.gitignore` contient bien :

```
.env
.env.local
.env.*.local
```

### 2.4 IDE recommande (VS Code)

Extensions a installer :

- **Flutter** (Dart-Code.flutter)
- **Dart** (Dart-Code.dart-code)
- **Python** (ms-python.python)
- **Pylance** (ms-python.vscode-pylance)
- **Markdown All in One** (yzhang.markdown-all-in-one)
- **Mermaid Preview** (bierner.markdown-mermaid)
- **GitLens** (eamodio.gitlens)
- **Error Lens** (usernamehw.errorlens)
- **TODO Highlight** (wayou.vscode-todo-highlight)

Settings VS Code recommandes (`.vscode/settings.json`) :

```json
{
  "dart.lineLength": 100,
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": "explicit"
  },
  "python.formatting.provider": "black",
  "python.linting.enabled": true,
  "python.linting.flake8Enabled": true,
  "[dart]": {
    "editor.defaultFormatter": "Dart-Code.dart-code"
  },
  "[python]": {
    "editor.defaultFormatter": "ms-python.black-formatter"
  }
}
```

---

## 3. Structure du projet

Le projet est organise en 5 composants independants, chacun dans son dossier racine. Cette separation permet a plusieurs developpeurs de travailler en parallele sans conflit (un agent par dossier pendant les sessions de coding sprint).

```
ExamBoost-Togo/
├── lib/                          # App Flutter (mobile + web)
│   ├── main.dart                 # Entry point + MultiProvider
│   ├── providers/                # State management (Provider/Riverpod)
│   ├── models/                   # Modeles Hive (Question, ReviewCard, User, ...)
│   ├── services/                 # Logique metier (SRS, sync, score, ...)
│   ├── screens/                  # UI par feature (home, revision, simulation, ...)
│   ├── widgets/                  # Widgets reusable (cards, buttons, animations, ...)
│   ├── theme/                    # Material 3 + couleurs Togo + dark mode
│   ├── utils/                    # Router, logger, helpers
│   ├── l10n/                     # Internationalisation (fr, en, ewe, kabye)
│   └── lottie/                   # Animations JSON
│
├── backend/                      # API FastAPI
│   ├── main.py                   # App FastAPI + CORS + lifespan
│   ├── config.py                 # Settings Pydantic (env vars)
│   ├── database.py               # Engine SQLAlchemy + session
│   ├── cache_service.py          # Wrapper Redis
│   ├── rate_limiter.py           # Rate limiting in-memory + Redis
│   ├── routers/                  # Endpoints (auth, questions, sessions, predict, tutor, classroom, admin, sync)
│   ├── services/                 # Logique metier (IRT, BKT, SRS, ML, auth, tutor, classroom, sync)
│   ├── models/                   # SQLAlchemy ORM + Pydantic schemas
│   ├── alembic/                  # Migrations DB versionnees
│   ├── scripts/                  # ML training, IRT calibration, clustering, seed
│   ├── tests/                    # pytest (auth, irt, bkt, sessions, predict, cache, rate_limit, migrations)
│   ├── Dockerfile                # Image Docker multi-stage
│   ├── railway.json              # Config Railway
│   ├── requirements.txt
│   └── openapi.yaml              # Schema OpenAPI exporte
│
├── data_pipeline/                # Pipeline OCR annales -> JSON
│   ├── scrape_pdfs.py            # Scraping BeautifulSoup
│   ├── ocr_extract.py            # Tesseract + GPT-4o Vision
│   ├── structure_questions.py    # GPT-4o-mini -> JSON
│   ├── validate_questions.py     # jsonschema
│   ├── deduplicate.py            # SimHash
│   ├── estimate_irt.py           # Heuristique IRT initial
│   ├── run_pipeline.py           # Orchestrateur CLI
│   ├── llm_generation/           # Generation questions par LLM (Mistral, Claude, OpenAI)
│   ├── real_ocr_demo/            # Demo OCR sur PDFs reels
│   ├── tests/                    # pytest (test_ocr, test_structure)
│   └── requirements.txt
│
├── landing/                      # Landing page Next.js 16
│   ├── app/                      # App router Next.js
│   │   ├── api/beta-signup/      # Endpoint beta signup
│   │   ├── page.tsx              # Home page
│   │   └── merci/page.tsx        # Page remerciement
│   ├── components/               # Hero, Pricing, FAQ, BetaCTA, ...
│   ├── lib/                      # Utils + validators
│   ├── DEPLOYMENT.md             # Deploiement Vercel
│   ├── vercel.json
│   └── package.json
│
├── scripts/                      # Scripts deploy/CI/CD
│   ├── deploy_backend.sh
│   ├── deploy_landing.sh
│   ├── deploy_all.sh
│   ├── rollback_backend.sh
│   ├── run_migrations.sh
│   ├── seed_prod_db.sh
│   ├── health_check.sh
│   ├── generate_app_icons.py
│   └── README.md
│
├── assets/                       # Assets Flutter
│   ├── data/                     # questions.json + geometry_questions.json
│   ├── illustrations/            # SVG onboarding + empty states
│   └── branding/                 # Logo, icon, color palette, typography
│
├── docs/                         # Documentation
│   ├── ARCHITECTURE.md           # Architecture technique complete (ce repo)
│   ├── CONTRIBUTING.md           # Ce guide
│   ├── DEPLOYMENT_GUIDE.md       # Guide deploiement detaille
│   ├── Plan_GoToMarket.md        # Strategie go-to-market
│   ├── Pitch_Deck_10_slides.md   # Pitch deck
│   ├── QA_jury_anticipe.md       # Q&A jury
│   ├── Case_Study_Amina.md       # Persona eleve
│   ├── Business_Model_Canvas.md  # BMC
│   ├── One_Pager.md              # Resume 1 page
│   ├── Enquete_Terrain/          # Enquete eleves Lome
│   ├── financial/                # Modele financier Excel
│   ├── manuals/                  # Manuels eleve + enseignant
│   ├── video_explanations/       # Storyboards + scripts videos
│   └── ...
│
├── test/                         # Tests Flutter
│   ├── unit/                     # Tests unitaires (modeles, services, algos)
│   ├── widget/                   # Tests widgets (cards, buttons, ecrans)
│   ├── integration/              # Tests integration (flows complets)
│   ├── golden/                   # Tests golden (screenshots)
│   ├── helpers/                  # Mocks + test_data
│   └── README.md
│
├── .github/workflows/            # CI GitHub Actions
├── setup.sh                      # Script init
├── pubspec.yaml                  # Dependances Flutter
├── analysis_options.yaml         # Linter Dart
├── l10n.yaml                     # Config i18n
├── README.md
└── LICENSE                       # Proprietaire
```

### Regle d'or : un dossier = un domaine

- Un developpeur qui travaille sur l'app Flutter ne touche **que** `lib/` et `test/`.
- Un developpeur backend ne touche **que** `backend/`.
- Un data engineer ne touche **que** `data_pipeline/` et `assets/data/`.
- Un frontend dev landing ne touche **que** `landing/`.
- Les fichiers transverses (`pubspec.yaml`, `setup.sh`, `README.md`, `docs/`) sont modifies par le lead dev ou via PR dediee.

---

## 4. Conventions de code

### 4.1 Dart (Flutter)

- **Style officiel Flutter** : `flutter analyze` doit passer sans warnings.
- **Linter** : `analysis_options.yaml` active `flutter_lints` + regles strictes (`prefer_const_constructors`, `require_trailing_commas`, `avoid_print`).
- **Formatting** : `dart format .` (largeur 100 caracteres).
- **Imports** : ordre alphabetique, packages Flutter en premier, puis packages externes, puis fichiers internes (relatifs).
- **Pas d'emojis** dans le code source (uniquement dans les strings utilisateur si necessaire, jamais dans les noms de variables ou commentaires).
- **Pas de `print()`** : utiliser `AppLogger` (lib/utils/app_logger.dart) qui supporte les niveaux DEBUG/INFO/WARNING/ERROR et se tait en production.
- **Pas de couleurs en dur** : utiliser `Theme.of(context).colorScheme` ou `app_theme.dart`.
- **Pas de strings utilisateur en dur** : utiliser `AppLocalizations.of(context)!.t('cle')` avec les cles definies dans `lib/l10n/app_fr.arb`.

### 4.2 Python (backend + pipeline)

- **Type hints** obligatoires sur toutes les signatures de fonctions publiques.
- **Docstrings** en anglais (Google style) pour les fonctions publiques.
- **Commentaires** en francais pour la logique metier (les algorithmes ML en particulier).
- **PEP 8** strict, verifie avec `flake8` + `black` (largeur 100).
- **Imports** : stdlib en premier, puis packages externes, puis modules internes (tri avec `isort`).
- **Pas d'emojis** dans le code source.
- **Logging** : utiliser `logging` module standard, jamais `print()` en production.
- **Pydantic v2** : utiliser `BaseModel` pour toutes les schemas API, ne pas utiliser de `dict` brut.

Exemple de fonction Python correcte :

```python
def update_bkt(
    p_l: float,
    correct: bool,
    p_t: float = 0.20,
    p_s: float = 0.10,
    p_g: float = 0.20,
) -> float:
    """Update the knowledge probability P(L) after an observation.

    Args:
        p_l: Current P(L) before update.
        correct: Whether the student answered correctly.
        p_t: Transition probability P(T).
        p_s: Slip probability P(S).
        p_g: Guess probability P(G).

    Returns:
        New P(L) clamped to [0, 1].
    """
    # Calcul de vraisemblance selon theoreme de Bayes
    if correct:
        p_c = p_l * (1 - p_s) + (1 - p_l) * p_g
        p_l_given_obs = (p_l * (1 - p_s)) / p_c
    else:
        p_i = p_l * p_s + (1 - p_l) * (1 - p_g)
        p_l_given_obs = (p_l * p_s) / p_i

    # Transition (apprentissage entre deux questions)
    p_l_next = p_l_given_obs + (1 - p_l_given_obs) * p_t
    return max(0.0, min(1.0, p_l_next))
```

### 4.3 Nommage

- **Variables Dart** : camelCase (`easinessFactor`, `nextReviewDate`, `bktMaitrise`).
- **Variables Python** : snake_case (`easiness_factor`, `next_review_date`, `bkt_maitrise`).
- **Fichiers Dart** : snake_case (`review_card.dart`, `srs_service.dart`).
- **Fichiers Python** : snake_case (`srs_service.py`, `irt_service.py`).
- **Classes** : PascalCase des deux cotes (`ReviewCard`, `SrsService`).
- **Constantes** : SCREAMING_SNAKE_CASE des deux cotes (`DEFAULT_P_T`, `kPrimaryColor`).
- **Routes API** : kebab-case ou path simple (`/predict-score/{id}`, `/auth/login`).
- **IDs questions** : `TG-{EXAMEN}-{MAT}-{ANNEE}-Q{NN}` (ex. `TG-BEPC-MATHS-2023-Q01`).
- **IDs competences** : `TG-{MATIERE}-{CHAPITRE}` (ex. `TG-MATHS-ALGEBRE`, `TG-SVT-GENETIQUE`).
- **Branches Git** : `feat/nom-feature`, `fix/nom-bug`, `docs/nom-doc`, `refactor/nom-refactor`.
- **Commits** : format Conventional Commits (voir section 5.2).

### 4.4 Commentaires

- **En francais** pour expliquer la logique metier ou pedagogique (algorithmes ML, choix de design).
- **En anglais** pour les docstrings Python (interop withibilite open-source).
- **TODO** : format `// TODO(nom): description` ou `# TODO(nom): description`. Toujours avec un nom pour savoir a qui demander.
- **Pas de commentaires morts** : si on desactive du code, le supprimer (Git garde l'historique).

### 4.5 Pas d'emojis

Les emojis sont interdits dans :

- Le code source (noms de variables, commentaires).
- Les messages de commit.
- Les noms de branches.
- Les logs.

Ils sont tolere dans :

- Les strings utilisateur affiches a l'UI (modere, jamais dans les boutons principaux).
- La documentation marketing (Pitch_Deck, One_Pager).
- Les README de dossiers (modere, uniquement dans les titres).

---

## 5. Workflow Git

### 5.1 Branches

- `main` : branche de production. Toujours deployable, toujours testee. **Pas de push direct**.
- `develop` : branche d'integration (optionnelle, pas encore active en Session 4).
- `feat/<nom>` : nouvelle fonctionnalite (ex. `feat/tutor-chat`).
- `fix/<nom>` : correction de bug (ex. `fix/srs-bkt-merge`).
- `docs/<nom>` : documentation uniquement (ex. `docs/architecture-consolidation`).
- `refactor/<nom>` : refactoring sans changement de comportement (ex. `refactor/srs-service-split`).
- `hotfix/<nom>` : correctif urgent en production (ex. `hotfix/jwt-secret-leak`).

### 5.2 Format de commits (Conventional Commits)

```
<type>(<scope>): <description>

<corps optionnel>

<footers optionnels>
```

Types autorises :

- `feat` : nouvelle fonctionnalite.
- `fix` : correction de bug.
- `docs` : documentation uniquement.
- `style` : formatting, espaces, virgules (pas de changement de code).
- `refactor` : refactoring sans changement de comportement.
- `test` : ajout ou modification de tests.
- `chore` : taches diverses (dependances, configs).
- `perf` : amelioration de performance.
- `ci` : modification CI/CD.
- `build` : modification build system (Dockerfile, pubspec).

Exemples valides :

```
feat(tutor): ajout chat IA Claude 3.5 Sonnet
fix(bkt): correction clamp P(L) hors [0,1]
docs(architecture): consolidation 3 docs maitres
refactor(srs): extraction methode selectBestQuestion
test(irt): ajout tests MLE theta convergence
chore(deps): upgrade flutter_lints 4.0.0
```

### 5.3 Procedure complete

1. **Creer une branche** depuis `main` :
   ```bash
   git checkout main
   git pull origin main
   git checkout -b feat/nom-feature
   ```

2. **Coder** en faisant des commits petits et frequents (un commit = une idee logique).

3. **Pousser** la branche sur GitHub :
   ```bash
   git push -u origin feat/nom-feature
   ```

4. **Ouvrir une Pull Request** sur GitHub avec :
   - Titre clair (resume en 1 phrase).
   - Description detaillee : contexte, ce qui change, screenshots si UI.
   - Linker les issues concernees (`Closes #123`).
   - Demander une review a au moins 1 membre de l'equipe.

5. **Review** : le reviewer utilise les commentaires GitHub, propose des suggestions, valide ou demande des changements. Pas de merge sans approval.

6. **Corriger** les retours de review en ajoutant des commits (pas de `git rebase -i` pour garder l'historique lisible).

7. **Merge** : preferer **Squash and merge** sur GitHub pour garder `main` propre (un commit par PR). Effacer la branche apres merge.

8. **Verifier** le deploiement auto en staging (Railway + Vercel preview).

### 5.4 Regles de conflit

- Si une PR a des conflits avec `main`, le developpeur responsable les resout :
  ```bash
  git fetch origin
  git rebase origin/main
  # resoudre les conflits dans l'editeur
  git add .
  git rebase --continue
  git push --force-with-lease origin feat/nom-feature
  ```
- **Jamais de `git push -f`** sur `main` ou `develop`.
- **`--force-with-lease`** preferable a `--force` pour eviter d'ecraser le travail d'un autre.

---

## 6. Avant de committer

### 6.1 Checklist Flutter

Avant chaque commit qui touche `lib/` ou `test/`, executer et verifier :

```bash
# Analyse statique (doit passer sans warnings)
flutter analyze

# Formatage automatique
dart format .

# Tests unitaires + widget + integration
flutter test

# Coverage (cible 70 %)
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
# Ouvrir coverage/html/index.html pour voir la couverture
```

Si `flutter analyze` affiche des warnings, les corriger avant de committer. Si un warning est un faux positif, ajouter un commentaire `// ignore: nom_regle` avec justification.

### 6.2 Checklist Python

Avant chaque commit qui touche `backend/` ou `data_pipeline/` :

```bash
cd backend

# Formatage
black . --line-length 100
isort . --profile black

# Linting
flake8 . --max-line-length 100 --extend-ignore=E203,W503

# Type checking (optionnel mais recommande)
mypy . --ignore-missing-imports

# Tests
pytest -v --cov=.

# Coverage report
pytest --cov=. --cov-report=html
# Ouvrir htmlcov/index.html
```

### 6.3 Checklist generale

- [ ] `flutter analyze` sans erreurs ni warnings.
- [ ] `flutter test` passe (cible : 100 % des tests existants en vert, +1 test pour nouvelle feature).
- [ ] `dart format .` applique (pas de diff dans VS Code source control).
- [ ] Pas de `print()` en production (utiliser `AppLogger`).
- [ ] Pas de secrets dans le code (cle API, mot de passe, token).
- [ ] Pas d'emojis dans le code source.
- [ ] Messages utilisateur en francais (via `AppLocalizations`).
- [ ] Pas de fichiers generes committes (`*.g.dart` sont gitignored sauf si mention contraire).
- [ ] Pas de logs en DEBUG en production (utiliser `kReleaseMode`).

---

## 7. Ajouter une question

### 7.1 Format JSON

Les questions sont stockees dans `assets/data/questions.json` (app Flutter) et `backend/data/questions_seed.json` (backend seed). Le schema JSON est le suivant :

```json
{
  "id": "TG-BEPC-MATHS-2023-Q01",
  "enonce": "Calculer la valeur de x dans l'equation 2x + 5 = 11.",
  "reponse": "3",
  "explication": "On soustrait 5 des deux cotes : 2x = 6, puis on divise par 2 : x = 3.",
  "matiere": "MATHEMATIQUES",
  "chapitre": "Equations du premier degre",
  "competenceId": "TG-MATHS-EQUATIONS",
  "examen": "BEPC",
  "serie": null,
  "annee": 2023,
  "type": "QCM",
  "points": 2,
  "choix": ["2", "3", "4", "5"],
  "irtA": null,
  "irtB": -0.5,
  "irtC": null,
  "irtCalibre": false,
  "imagePath": null,
  "latexFormula": null
}
```

### 7.2 Procedure

1. **Identifier la source** : PDF d'annale officielle (provenance traçable, annee, examen, serie).
2. **Generer l'ID** selon la convention `TG-{EXAMEN}-{MAT}-{ANNEE}-Q{NN}` (verifier unicite dans le JSON existant).
3. **Rediger enonce + reponse + explication** en francais clair, adapté au niveau BEPC ou BAC.
4. **Identifier la competence** : reutiliser un `competenceId` existant si possible, sinon en creer un nouveau au format `TG-{MAT}-{CHAPITRE}`.
5. **Estimer `irtB` initial** (heuristique) : facile = -1.5, moyen = 0, difficile = +1.5. Laisser `irtA` et `irtC` a `null` (seront calibres par py-irt apres collecte de reponses).
6. **Ajouter au JSON** dans l'ordre alphabetique des IDs (pour faciliter les diffs Git).
7. **Tester** : lancer l'app, naviguer jusqu'a la question, verifier l'affichage (LaTeX, images SVG si presentes).
8. **Commit** : `feat(questions): ajout 10 questions BEPC maths 2023`.

### 7.3 Validation automatique

Le script `data_pipeline/validate_questions.py` valide le schema JSON :

```bash
python data_pipeline/validate_questions.py assets/data/questions.json
```

Il verifie : presence de tous les champs requis, types corrects, unicite des IDs, coherence examen/serie (BAC serie C vs D), `irtB` dans [-3, +3]. A lancer avant chaque commit qui ajoute des questions.

### 7.4 Pipeline OCR (mode batch)

Pour ajouter un grand volume de questions (> 50), utiliser le pipeline OCR :

```bash
cd data_pipeline
python run_pipeline.py --input raw_pdfs/ --output ../assets/data/questions_new.json
```

Le pipeline genere un JSON valide qu'on peut ensuite merger avec `questions.json` via `merge_questions.py`.

---

## 8. Ajouter un ecran

### 8.1 Pattern standard

Suivre le pattern Modele + Service + Screen + Route + Navigation :

1. **Modele** (si nouvelle entite) dans `lib/models/` avec annotation `@HiveType` si persistance locale necessaire. Ne pas oublier de regenerer les adaptateurs (`dart run build_runner build`).

2. **Service** dans `lib/services/` qui encapsule la logique metier. Injecter les dependances via le constructeur (pas de singletons globaux).

3. **Provider** dans `lib/providers/` si l'etat doit etre global (ex. `TutorProvider` pour le chat IA). Sinon, utiliser `StatefulWidget` local.

4. **Screen** dans `lib/screens/<feature>/<feature>_screen.dart`. Suivre la structure :
   ```dart
   class FeatureScreen extends StatefulWidget {
     const FeatureScreen({super.key});
     @override
     State<FeatureScreen> createState() => _FeatureScreenState();
   }

   class _FeatureScreenState extends State<FeatureScreen> {
     @override
     void initState() {
       super.initState();
       // Chargement initial
     }

     @override
     Widget build(BuildContext context) {
       return Scaffold(
         appBar: AppBar(title: Text(AppLocalizations.of(context)!.featureTitle)),
         body: // contenu
       );
     }
   }
   ```

5. **Route** dans `lib/utils/app_router.dart` : ajouter une `GoRoute` avec path unique, et un `redirect` si auth requise.

6. **Navigation** : utiliser `context.go('/feature')` (remplace la stack) ou `context.push('/feature')` (ajoute a la stack). Ne pas utiliser `Navigator.push` direct.

7. **Tests** : ajouter `test/widget/screens/feature_screen_test.dart` avec au moins 3 tests (rendu initial, interaction utilisateur, gestion d'erreur).

8. **i18n** : ajouter les cles dans `lib/l10n/app_fr.arb` (et `app_en.arb`, `app_ewe.arb`, `app_kabye.arb` si disponibles).

9. **Documentation** : si l'ecran est complexe, ajouter un `README.md` dans le dossier feature (ex. `lib/screens/tutor/README.md`).

### 8.2 Bonnes pratiques UI

- **Material 3** : utiliser les composants Material 3 (`FilledButton`, `Card`, `NavigationBar`).
- **Theme** : ne jamais utiliser de couleurs en dur, toujours `Theme.of(context).colorScheme`.
- **Dark mode** : tester l'ecran en light ET dark mode. Si un widget casse en dark, ajouter une variante dans `app_theme.dart`.
- **Accessibilite** : utiliser `Semantics` pour les widgets custom, tester avec TalkBack/VoiceOver.
- **Responsive** : tester sur petit ecran (320 px large, emulateur Tecno Spark) et grand ecran (tablet 1280 px).
- **Animations** : utiliser `AnimatedSwitcher`, `Hero`, `TweenAnimationBuilder` pour des transitions fluides. Eviter les animations de plus de 300 ms (perçu comme lent).

---

## 9. Tests

### 9.1 Organisation

```
test/
├── unit/                          # Tests unitaires (logique isolee)
│   ├── models/                    # Modeles (Question, ReviewCard, User)
│   ├── algorithms/                # Algorithmes (SM-2, BKT, IRT)
│   ├── services/                  # Services (SrsService, QuestionService)
│   └── question_test.dart         # Tests legacy
├── widget/                        # Tests widgets (UI isolee)
│   ├── screens/                   # Tests ecrans
│   └── widgets/                   # Tests widgets reusable
├── integration/                   # Tests integration (flows complets)
│   ├── onboarding_to_revision_test.dart
│   ├── revision_to_dashboard_test.dart
│   └── full_exam_flow_test.dart
├── golden/                        # Tests golden (screenshots pixel-perfect)
│   ├── home_screen_golden_test.dart
│   └── README.md
└── helpers/                       # Helpers de test
    ├── test_helpers.dart
    ├── test_data.dart
    └── mock_services.dart
```

### 9.2 Backend (pytest)

```
backend/tests/
├── conftest.py                    # Fixtures pytest (client TestClient, DB test)
├── test_auth.py                   # /auth/register, /auth/login, /auth/me
├── test_questions.py              # /questions (list, get, create)
├── test_sessions.py               # /sessions (record, due, stats)
├── test_predict.py                # /predict-score, /predict-dropout
├── test_irt.py                    # IRT service (calibration + MLE theta)
├── test_cache.py                  # Cache Redis
├── test_rate_limit.py             # Rate limiter
└── test_migrations.py             # Alembic migrations
```

### 9.3 Couverture cible

- **Cible globale** : 70 % de couverture de lignes.
- **Modeles + algorithmes ML** : 90 % (logique critique, ne doit pas casser).
- **Services** : 80 %.
- **Screens** : 50 % (UI difficile a tester, focus sur les interactions cles).
- **Widgets reutilisables** : 80 %.

### 9.4 Lancer les tests

```bash
# Flutter : tous les tests
flutter test

# Flutter : un dossier specifique
flutter test test/unit/algorithms/

# Flutter : coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
xdg-open coverage/html/index.html

# Backend : tous les tests
cd backend && pytest -v

# Backend : coverage
cd backend && pytest --cov=. --cov-report=html
xdg-open htmlcov/index.html

# Data pipeline
cd data_pipeline && pytest -v
```

### 9.5 Tests d'integration CI

GitHub Actions lance automatiquement les tests sur chaque PR :

- `backend_ci.yml` : pytest + flake8 + build Docker.
- `flutter_ci.yml` : flutter test + flutter analyze + dart format --set-exit-if-changed.
- `data_pipeline_ci.yml` : pytest data_pipeline.

Une PR qui casse des tests ne peut pas etre mergee.

---

## 10. Deploiement

### 10.1 Environnements

- **Dev** : machine locale (Flutter run + uvicorn + npm dev).
- **Staging** : Railway staging + Vercel preview (branche `staging` ou PR).
- **Production** : Railway prod + Vercel prod (branche `main`).

### 10.2 Flow de deploiement

1. **Dev** : developpeur teste en local.
2. **PR** : ouverture d'une PR declenche CI (tests + lint + build).
3. **Staging** : merge dans `main` deploie automatiquement en staging.
4. **QA** : QA manuelle + smoke tests via `./scripts/health_check.sh`.
5. **Production** : `./scripts/deploy_all.sh --prod` deploie en production.
6. **Verification** : `./scripts/health_check.sh` en prod, verifier `/health` 200 OK.
7. **Rollback si incident** : `./scripts/rollback_backend.sh production`.

### 10.3 Scripts disponibles

| Script | Usage |
|---|---|
| `scripts/deploy_backend.sh [staging\|production]` | Deploie le backend sur Railway |
| `scripts/deploy_landing.sh [--prod]` | Deploie la landing sur Vercel |
| `scripts/deploy_all.sh [--prod]` | Deploie backend + landing |
| `scripts/rollback_backend.sh [staging\|production]` | Rollback backend vers la version precedente |
| `scripts/run_migrations.sh` | Applique les migrations Alembic |
| `scripts/seed_prod_db.sh` | Peuple la DB prod (questions + admin) |
| `scripts/health_check.sh` | Verifie sante backend + landing |
| `scripts/generate_app_icons.py` | Regénère les icones app (Android + iOS) |

### 10.4 Release Flutter (APK)

```bash
# Build APK debug (< 25 Mo cible)
flutter build apk --release --target-platform android-arm,android-arm64

# Build App Bundle pour Play Store
flutter build appbundle --release

# Verifier la taille
ls -lh build/app/outputs/flutter-apk/app-release.apk
# Doit etre < 25 Mo
```

### 10.5 Release backend (Docker)

```bash
# Build image Docker
cd backend
docker build -t examboost/backend:$(git rev-parse --short HEAD) .

# Push vers Docker Hub (si compte configure)
docker push examboost/backend:$(git rev-parse --short HEAD)

# Railway recupere l'image et deploie
```

Pour le detail complet du deploiement, voir `docs/DEPLOYMENT_GUIDE.md` et `docs/ARCHITECTURE.md` (section 10).

---

## 11. Communication equipe

### 11.1 Worklog partage

Le worklog `/home/z/my-project/worklog.md` est le **seul journal de travail partage** entre tous les developpeurs et agents.

- **AVANT** de commencer une tache : lire le worklog pour comprendre ce qui a ete fait.
- **APRES** avoir fini : ajouter une nouvelle section avec `---` comme separateur.
- **Ne PAS ecraser** le contenu existant.
- Pour le repo public (apres lancement), le worklog sera deplace dans `docs/WORKLOG.md` (anonymise).

### 11.2 Canaux de communication

- **GitHub Issues** : bugs, features, tasks techniques. Chaque issue a un label (bug, feature, docs, ...) et un assigne.
- **GitHub PRs** : review de code, discussions techniques.
- **Discord/Telegram equipe** : discussions quotidiennes, stand-up, questions rapides.
- **Stand-up hebdomadaire** : chaque lundi, 30 min, format "ce que j'ai fait / ce que je fais / blocages".
- **Demo mensuelle** : fin de mois, demo des features livrees + retro.

### 11.3 Conventions de communication

- **FR** par defaut dans les issues, PRs, stand-ups (equipe togolaise).
- **EN** pour les docstrings Python et la documentation publique open-source.
- Pas de critiques personnelles, focus sur le code.
- Si desaccord technique, ouvrir une issue "Discussion" et trancher en stand-up.

### 11.4 Onboarding nouveau developpeur

1. Lire ce `CONTRIBUTING.md` en entier.
2. Lire le `README.md` principal.
3. Lire `docs/ARCHITECTURE.md` (focus sur les sections 1-3-7).
4. Lire le worklog (`/home/z/my-project/worklog.md`) Sessions 1-4 pour comprendre l'historique.
5. Faire le setup (section 2 de ce guide).
6. Prendre une issue "good first issue" sur GitHub.
7. Premiere PR dans les 3 jours.

---

## 12. Roadmap

La roadmap detaillee est dans `docs/Plan_GoToMarket.md` et `docs/ExamBoost_DJANTA_Plan_Strategique_2026.pdf`. Resume rapide :

### 12.1 Etat actuel (Session 4, juillet 2026)

- [x] MVP Flutter (5 ecrans + 3 algos ML : SM-2, BKT, IRT 3PL).
- [x] Backend FastAPI minimal (auth, questions, sessions, predict).
- [x] Pipeline OCR (scripts Python operationnels).
- [x] 64+ questions BEPC/BAC en base.
- [x] Landing Next.js sur Vercel.
- [x] Deploiement Railway (backend) + Vercel (landing) en prod.
- [x] Documentation consolidee (ARCHITECTURE + CONTRIBUTING + DEPLOYMENT).

### 12.2 Prochains jalons

- [ ] Pilote 5 etablissements Lome, 300 eleves (M5-M6).
- [ ] Calibration IRT reelle avec donnees pilote (M6-M7).
- [ ] Modele XGBoost entraîne sur vraies donnees (M7-M8).
- [ ] Deploiement Play Store national (M8).
- [ ] Integration Mobile Money Flooz + TMoney (M6-M8).
- [ ] iOS app + App Store (M6-M8).
- [ ] Expansion Benin / Cote d'Ivoire / Burkina Faso (M13+).

### 12.3 Backlog technique (priorise)

1. Refresh tokens JWT (access 1h + refresh 30j).
2. Endpoint `DELETE /auth/me` (droit a l'oubli loi 2019-014).
3. Endpoint `GET /auth/me/export` (portabilite donnees).
4. Migration FSRS (apres 10k revisions collectees).
5. A/B test DKT vs BKT (M9+).
6. Cache Redis partage pour rate limiter (multi-replicas).
7. Read replica PostgreSQL au-dela de 10 000 users.
8. Sentry mobile (Flutter SDK).
9. Feature flags PostHog (rollout progressif).
10. Web app Flutter (compile web) pour demo navigateur.

### 12.4 KPIs techniques (a suivre)

| KPI | Cible M6 | Cible M12 | Cible M18 |
|---|---|---|---|
| Coverage tests | 70 % | 80 % | 85 % |
| Temps reponse API p95 | < 500 ms | < 300 ms | < 200 ms |
| Uptime backend | 99 % | 99,5 % | 99,9 % |
| Taille APK | < 25 Mo | < 25 Mo | < 25 Mo |
| Crash-free users | > 99 % | > 99,5 % | > 99,9 % |
| Cold start app | < 3 s | < 2 s | < 1,5 s |

---

## References

- `README.md` — vue d'ensemble produit.
- `docs/ARCHITECTURE.md` — architecture technique complete (11 sections, 12 diagrammes Mermaid).
- `docs/DEPLOYMENT_GUIDE.md` — guide deploiement detaille (Railway, Vercel, CI/CD, monitoring, backup, disaster recovery).
- `docs/Pitch_Deck_10_slides.md` — pitch DJANTA 24 juillet 2026.
- `docs/Plan_GoToMarket.md` — strategie go-to-market 18 mois.
- `docs/QA_jury_anticipe.md` — 57 questions/reponses jury anticipees.
- `docs/ExamBoost_Togo_Cours_Theorique_2025.pdf` — theorie algorithmes SM-2, BKT, IRT, XGBoost.
- `lib/screens/<feature>/README.md` — README specifique par feature (tutor, classroom, badges, ...).
- `backend/README.md` — README backend.
- `backend/scripts/<feature>/README.md` — README par module ML (ml_training, irt_calibration, dkt_model, student_clustering).

---

*Document maintenu par l'Agent BG (Session 4, Vague 1). Pour toute modification de ce guide, ouvrir une PR avec le label `docs` et tagger `@djabelo712`. Derniere mise a jour : 1er juillet 2026.*
