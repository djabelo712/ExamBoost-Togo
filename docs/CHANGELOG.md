# Changelog — ExamBoost Togo

Historique des versions du projet ExamBoost Togo.
Format inspiré de [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/), versionnement [SemVer](https://semver.org/lang/fr/).

Les versions majeures correspondent aux sessions de développement multi-agents.

---

## [4.0.0] — 2 juillet 2026 (Session 4)

### Added — 32 modules en 3 vagues

**Vague 1 (consolidation)** :
- Wiring master unique : routeur GoRouter (23 routes), `main.dart` (19 adaptateurs Hive), `pubspec.yaml` (dépendances manquantes), `UserProvider`, `home_screen.dart` (11 cartes)
- Tests widget complets (tous écrans) + tests integration E2E (scénarios bout-en-bout)
- Build APK script + workflow GitHub Actions

**Vague 2 (features produit)** :
- Module parent : suivi enfant, alertes décrochage, rapport hebdomadaire
- Reconnaissance vocale réponses (speech_to_text) pour accessibility + vitesse
- Mode concours inter-écoles : compétitions mensuelles, leaderboard national
- Réalité augmentée géométrie : formes 3D AR (cubes, pyramides, cylindres)
- Mode révision flash 5 min : sessions courtes optimisées transport
- Export PDF progression : rapport personnalisé élève + parent + enseignant
- Module devoirs : assignation enseignant + auto-correction + feedback BKT
- Système niveaux XP (1-50) : formule `100 × N × (N+1) / 2`, 8 récompenses débloquables, animation montée de niveau plein écran
- Mode multijoueur d'étude : WebSocket temps réel, lobby + game + results, synchronisation réponses
- Chatbot conseiller orientation : 15 filières togolaises + 35 carrières, scoring cosinus + P(L) matières + pénalité filières sélectives, radar chart 6 axes, 12 archétypes
- Audit sécurité OWASP Top 10 backend : 19 vulnérabilités (3 critiques, 5 hautes, 11 moyennes), rapport + corrections + checklist

**Vague 3 (i18n avancée + prépa pitch)** :
- Demo script live : 7 sections clic-par-clic (90 sec + variantes 60/120 sec), profil démo Amina Kossi, plans B pour 6 risques, checklist matériel
- Documentation finale consolidée : `INDEX.md`, `PROJECT_OVERVIEW.md`, `CHANGELOG.md`

### Changed

- Wiring complet : tous les écrans Session 3 (30 modules non connectés) sont désormais routés dans `app_router.dart`
- Adaptateurs Hive : 19 adaptateurs enregistrés dans `main.dart` (badges, notifications, sync, favoris, TTS, niveau XP, etc.)
- i18n appliquée sur 3 écrans prioritaires (Home, Révision, Dashboard) — `AppLocalizations.of(context)!.xxx`
- Dark mode appliqué sur 3 écrans prioritaires via `AdaptiveColors` + `Theme.of(context).brightness`
- Questions unifiées : 64 (existantes) + 15 (géométrie) + 36 (OCR) = **114 questions** dans `assets/data/questions.json`
- `pubspec.yaml` : ajout de `speech_to_text`, `flutter_tts`, `flutter_math_fork`, `share_plus`, `fl_chart`, `camera`, `ar_flutter_plugin`, etc.
- `home_screen.dart` : 11 cartes d'action (Révision, Simulation, Dashboard, Tuteur, Badges, Score, Recherche, Favoris, Notes, Multijoueur, Orientation)

### Fixed

- Bug critique bouton "Révision Adaptative" : crash à cause d'URL non encodée (`/revision/Mathématiques` → URI encode)
- Bug bouton "Révision" home_screen : navigation vers `/revision` (générique) au lieu de `/revision/{matière}` (corrigé)
- 5 bugs mineurs : imports inutilisés, dead code, variables non nullable, `withOpacity` sur couleur constante
- Vulnérabilités critiques OWASP A01 (Broken Access Control) :
  - POST `/sessions` sans auth ni ownership check → ajout `get_current_user` + vérification `user_id == current_user.id`
  - GET `/sessions/{user_id}/due|stats` sans auth → ajout auth + ownership
  - GET `/predict-score|predict-dropout/{user_id}` sans auth → ajout auth + ownership
- Rate limiting slowapi branché dans `main.py` (était défini mais non activé)

### Documentation

- `README.md` mis à jour (badges, structure docs, 7 PDFs stratégiques, 35+ READMEs modules)
- `docs/ARCHITECTURE.md` créé (11 sections, 12 diagrammes Mermaid, ~7 363 mots)
- `docs/CONTRIBUTING.md` créé (12 sections, ~4 735 mots)
- `docs/INDEX.md` créé (index de toute la documentation)
- `docs/PROJECT_OVERVIEW.md` créé (vue d'ensemble master)
- `docs/CHANGELOG.md` créé (ce fichier)
- `docs/Demo_Script_Live.md` créé (script démo 90 sec)
- `docs/BUG_HUNT_REPORT.md` créé (rapport bug hunt)

---

## [3.0.0] — 1 juillet 2026 (Session 3)

### Added — 30 modules en 3 vagues

**Vague 1 (critique + features produit + qualité)** :
- Tuteur IA conversationnel : chat adaptatif, feedback pédagogique, suggestions de révision
- Badges gamification : 39 badges × 3 niveaux (Bronze / Argent / Or), 5 catégories, animation déblocage
- Notifications smart : rappels basés sur SM-2 (cartes dues) + BKT (compétences en baisse) + streak
- Score officiel BEPC/BAC : prédiction calibrée sur barème officiel (BEPC / 20, BAC / 20)
- Mode examen authentique : durées réelles (BEPC 2h, BAC 4h), barème officiel, cocooning (pas de notifications)
- Animations polish : transitions hero, confettis badges, page transitions, micro-interactions
- Sync cloud offline : `SyncService` + `SyncAction` (file d'attente), CRDT-like, résolution de conflits
- Stats détaillées : heatmap chapitres, radar compétences 6 axes, courbe progression, comparaison classe

**Vague 2 (business + ML + mobile profondeur)** :
- Calibration IRT réelle : `py-irt` MCMC sur données pilote, paramètres a/b/c par question
- XGBoost entraîné : `backend/scripts/ml_training/`, RMSE 1,46/20 sur validation
- DKT LSTM : `backend/scripts/dkt_model/`, trajectoire apprentissage séquentielle
- Clustering K-Means : `backend/scripts/student_clustering/`, 5 personas pédagogiques
- Pipeline LLM questions : génération + validation automatique via GPT-4o-mini
- Mode classe live : WebSocket temps réel, professeur + élèves, questions synchronisées
- Recherche avancée : filtres multi-critères (matière, examen, série, difficulté, chapitre), recherche full-text
- Favoris + notes personnelles : sauvegarde questions + annotations personnelles
- LaTeX mathématique : `flutter_math_fork` pour rendu équations
- TTS audio : `flutter_tts` pour lecture questions/réponses (accessibilité)
- SVG géométrie : figures interactives (triangles, cercles, polygones)

**Vague 3 (contenu + backend + business + polish)** :
- Empty / error / skeleton states : composants réutilisables pour tous les écrans
- Dark mode audit : 126 corrections `AdaptiveColors` référencées
- Modèle financier Excel : 246 400 USD, projections M0 → M18, `docs/financial/`
- OCR réel : Tesseract + GPT-4o Vision sur annales BEPC 2024, 36 questions extraites
- Investor deck 15 slides : format 20 min pour investisseurs
- Admin backend : gestion établissements, élèves, questions, statistiques agrégées
- Vidéos explicatives : catalogue 10 vidéos + scripts + storyboards + guide production
- One pager + BMC : fiche A4 + Business Model Canvas 9 blocs
- Illustrations + icônes : SVG onboarding + empty states
- Manuels PDF : élève 21 pages + enseignant 15 pages (`docs/manuals/`)
- Tests v2 : extension couverture (unit + widget + integration)

### Changed

- `lib/services/question_service.dart` : chargement questions + filtres avancés
- `lib/models/user.dart` : ajout `bktMaitrise` (Map<competenceId, P(L)>)
- `lib/models/review_card.dart` : SM-2 + IRT combinés
- Backend : ajout routers `sync`, `tutor`, `classroom`, `admin` (47 endpoints au total)

### Fixed

- Bug critique bouton "Révision Adaptative" : URL non encodée (corrigé en Session 4 définitivement)
- Crash sur écran Splash non intégré au router
- Hive adapters non générés pour nouveaux modèles

---

## [2.0.0] — 30 juin 2026 (Session 2)

### Added — 12 modules

- Branding complet : logo ExamBoost (SVG + PNG), palette (#006837 vert Togo + #D97700 orange), typographie (Outfit titres + Inter corps)
- Écran splash animé : logo + transitions vers onboarding ou home
- Module communauté : forum élèves + enseignants, leaderboard mensuel, badges communauté
- Module admin B2B : dashboard établissement (stats agrégées, suivi élèves, export)
- Landing page Next.js : `landing/` (Vercel), SEO optimisé, capture email bêta
- i18n FR/EN : 165 clés ARB dans `lib/l10n/`, `flutter_localizations` activé
- CI/CD GitHub Actions : workflow `flutter build + analyze + test` sur push + PR
- Diagrammes d'architecture : 12 diagrammes Mermaid (système, ML, sync, sécu, déploiement)
- Enquête terrain Lomé : questionnaire 30 questions (5 sections), plan échantillonnage 300 élèves / 5 établissements, formulaire consentement, structure Google Forms
- Dossier de candidature DJANTA : dossier officiel Idée-Action Challenge
- Vidéo teaser 2 min : storyboard complet (scènes, voiceover, B-roll)
- Vidéos explicatives : catalogue 10 vidéos + scripts + storyboards + guide production

### Changed

- `pubspec.yaml` : ajout `flutter_localizations`, `intl`, `go_router`, `hive_flutter`
- `lib/main.dart` : initialisation Hive + EasyLocalization + MaterialApp.router
- `lib/theme/app_theme.dart` : Material 3 + dark mode + AppColors + AppTextStyles

---

## [1.0.0] — 30 juin 2026 (Session 1)

### Added — 9 modules (MVP)

- 5 écrans Flutter de base :
  - `OnboardingScreen` : 5 étapes (identité, niveau, série, matières, objectifs)
  - `HomeScreen` : cartes d'action (Révision, Simulation, Dashboard)
  - `RevisionScreen` : flashcard flip 3D animée + boutons SRS (Facile / Correct / Difficile / Oublié)
  - `SimulationScreen` : examen chronométré (BEPC 2h / BAC 4h), tirage aléatoire
  - `DashboardScreen` : BKT + prédiction + heatmap chapitres
- `UserProvider` global : auth + persistance Hive + redirect GoRouter
- Backend FastAPI minimal : 7 endpoints (`/auth/register|login|me`, `/questions`, `/questions/random`, `/sessions`, `/predict-score/{user_id}`)
- Pipeline OCR : 7 scripts Python (`scrape_pdfs.py`, `ocr_extract.py`, `structure_questions.py`, `validate_questions.py`, `deduplicate.py`, `estimate_irt.py`, `run_pipeline.py`)
- 64 questions BEPC/BAC structurées dans `assets/data/questions.json` (40 BEPC + 24 BAC1, 6 matières)
- 3 algorithmes ML implémentés :
  - **SM-2** (répétition espacée) — `lib/models/review_card.dart` méthode `applyReview(int q)`
  - **BKT** (Bayesian Knowledge Tracing) — `lib/models/user.dart` méthode `updateBkt(...)`, seuil P(L) ≥ 0,85
  - **IRT 3PL** (Théorie de la Réponse aux Items) — `lib/services/srs_service.dart` méthode `irtProbability(...)`, sélection adaptative difficulté `b` ≈ niveau `θ`
- Documentation stratégie (5 PDFs) :
  - `ExamBoost_Togo_Etude_Faisabilite_2025.pdf` (architecture + budget 246 400 USD)
  - `ExamBoost_Togo_Cours_Theorique_2025.pdf` (démonstrations SM-2, BKT, IRT, XGBoost)
  - `ExamBoost_Togo_Guide_Outils_IA_2025.pdf` (stack IA par tâche)
  - `IA_Education_Togo_2025.pdf` (diagnostic 5 crises éducation Togo)
  - `ExamBoost_DJANTA_Plan_Strategique_2026.pdf` (plan d'action DJANTA)

### Infrastructure

- `setup.sh` : script d'initialisation (pub get + build_runner + analyze + backend)
- `pubspec.yaml` : Flutter 3.44+, Hive, GoRouter, Provider, fl_chart, google_fonts
- Repository GitHub public : https://github.com/djabelo712/ExamBoost-Togo
- Palette Togo : #006837 (vert) + #D97700 (orange)

---

## Convention de versionnement

- **Majeure** (`X.0.0`) : une session de développement multi-agents (Sessions 1, 2, 3, 4)
- **Mineure** (`X.Y.0`) : vague de modules au sein d'une session (Vague 1, 2, 3)
- **Correctif** (`X.Y.Z`) : bug fixes et corrections isolées

## Liens

- [INDEX de la documentation](INDEX.md)
- [Vue d'ensemble projet](PROJECT_OVERVIEW.md)
- [README principal](../README.md)
- [Architecture technique](ARCHITECTURE.md)
- [Worklog multi-agents](/home/z/my-project/worklog.md) (5 958 lignes, ~70 tasks)
