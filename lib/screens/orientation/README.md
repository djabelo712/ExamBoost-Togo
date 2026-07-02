# Module Orientation — Chatbot Conseiller d'Orientation

Module Session 4 — Agent **BS-orientation-chatbot**.

Chatbot conversationnel qui aide les élèves togolais à choisir leur filière
post-BEPC / post-BAC, basé sur leurs intérêts, leurs valeurs et leurs résultats
scolaires réels (P(L) BKT par matière).

## Objectifs pédagogiques

Après BEPC (orientation vers 2nde A/C/D) ou après BAC (choix filière supérieur),
l'élève ne sait pas toujours quelle filière choisir. Ce module :

1. **Pose 12 questions** conversationnelles (intérêts + matières + valeurs).
2. **Analyse le profil** de l'élève sur 6 axes (Scientifique, Littéraire,
   Créatif, Social, Business, Leadership) + récupère les P(L) par matière
   (issus de `AppUser.bktMaitrise`).
3. **Génère un archétype** ("Scientifique pur", "Littéraire créatif",
   "Polyvalent leader", etc.).
4. **Recommande le top 5 des filières** togolaises avec un % de match, les
   raisons du match, les universités, le salaire moyen et les carrières
   possibles.

## Architecture

```
lib/screens/orientation/
├── orientation_chat_screen.dart      # Chat 12 questions + intro + résultats
├── orientation_results_screen.dart   # Top 5 filières + radar + détails
├── orientation_profile_screen.dart   # Profil détaillé (6 axes + matières)
├── widgets/
│   ├── chat_bubble_orientation.dart  # Bulle message (élève/bot/intro)
│   ├── filiere_card.dart             # Carte filière (dépliable, raisons)
│   ├── skill_radar_orientation.dart  # Radar fl_chart (6 axes + overlay)
│   └── career_path_card.dart         # Carte métier (salaire, secteurs)
├── services/
│   └── orientation_service.dart      # 12 questions + 15 filières + 33 careers + scoring
├── models/
│   ├── filiere.dart                  # Filiere (poids axes + matieres pivots)
│   ├── career_path.dart              # CareerPath (titre, salaire, secteurs)
│   └── orientation_profile.dart      # OrientationProfile + ArchetypeResolver
└── README.md
```

## Données mock

### 6 axes de compétences
- Scientifique, Littéraire, Créatif, Social, Business, Leadership

### 12 questions
- 6 questions d'intérêts (Q1-Q6) — échelle Oui beaucoup / Un peu / Pas vraiment
- 1 question matière préférée (Q7) — 5 options (Maths, Sciences, Français, Histoire, EPS)
- 1 question mode de travail (Q8) — Équipe / Seul / Les deux
- 4 questions de valeurs (Q9-Q12) — salaire vs impact, durée études, etc.

### 15 filières togolaises
Médecine (UN Lomé FSS), Pharmacie, Ingénierie (EUT/EPB), Informatique (IFG/ENI),
Droit (UN Lomé FDSJP), Économie/Gestion (ESAE), Agronomie (ESA), Lettres (UN Lomé FLE),
Sciences (UN Lomé FDS), Architecture, Comptabilité/Finance (ESAE), Marketing/Communication,
Soins Infirmiers (ENAM), Enseignement (ENS), Journalisme (ISMP).

Chaque filière contient :
- Vecteur de poids sur 6 axes (somme = 1.0, calibré manuellement)
- Matières pivots (ex: Médecine → SVT, Physique, Maths)
- Universités togolaises + CEDEAO
- Durée, diplôme, salaire début/senior (FCFA/mois marché Togo)
- Séries BAC recommandées, compétences clés, débouchés
- IDs des career paths associées

### 33 career paths réparties sur les 15 filières (2-3 par filière)
Chaque career path contient : titre, description, niveau d'entrée, évolution,
salaire début/senior, secteurs d'emploi, demande marché (1-5 étoiles),
potentiel international (fort/moyen/faible), compétences clés.

## Algorithme de scoring

Pour chaque filière :

1. **Similarité cosinus** entre le vecteur élève (6 axes normalisés 0-1) et le
   vecteur filière (6 poids normalisés 0-1). Renvoie 0-1 (vecteurs positifs).
2. **Score matières** : moyenne des P(L) des matières pivots de la filière.
   Défaut 0.50 si l'élève n'a pas encore de données BKT.
3. **Combinaison** : `match = (0.70 × similarité + 0.30 × score_matières) × 100`
4. **Pénalité filières sélectives** : -10 pts si l'élève a un score moyen < 0.55
   sur les axes forts de la filière (ex: Médecine demande Scientifique+Social
   forts ; si l'élève est faible, on pénalise pour éviter de recommander
   Médecine à un élève qui n'a pas le profil).
5. **Clamp 0-100**.

Les 5 filières avec le plus haut % sont recommandées (tri décroissant).

## Flow utilisateur

```
┌──────────────────────────────────────────────────────────────┐
│  OrientationChatScreen                                       │
│  ─────────────────────────                                   │
│  Intro bot → Q1 → réponse élève → Q2 → ... → Q12 → résumé   │
│  → bouton "Voir mes recommandations"                         │
└────────────────────────────┬─────────────────────────────────┘
                             │
                             ▼ push
┌──────────────────────────────────────────────────────────────┐
│  OrientationResultsScreen                                    │
│  ────────────────────────                                    │
│  Header archétype (gradient vert) + score global             │
│  Radar compact + overlay top 1                               │
│  Top 5 FiliereCard (dépliables, rang 1 auto-déplié)          │
│  Bouton "Voir mon profil détaillé"                           │
│  Disclaimer pédagogique                                      │
└────────────────────────────┬─────────────────────────────────┘
                             │
                             ▼ push (optionnel)
┌──────────────────────────────────────────────────────────────┐
│  OrientationProfileScreen                                    │
│  ────────────────────────                                    │
│  Header archétype (gradient pastel) + score                  │
│  Radar grand format (300px)                                  │
│  Liste 6 axes avec barres de progression colorées            │
│  Top 3 matières maîtrisées                                   │
│  Footer contexte (niveau, série, date, axes)                 │
└──────────────────────────────────────────────────────────────┘
```

## Intégration dans l'app (à faire par l'agent wiring BA)

### 1. Ajouter la route dans `lib/utils/app_router.dart`

```dart
GoRoute(
  path: '/orientation',
  builder: (context, state) => const OrientationChatScreen(),
),
```

### 2. Ajouter un bouton dans `lib/screens/home/home_screen.dart`

```dart
ListTile(
  leading: const Icon(Icons.explore),
  title: const Text("Conseiller d'orientation"),
  subtitle: const Text('Découvre les filières qui te correspondent'),
  onTap: () => context.go('/orientation'),
),
```

### 3. Pré-agréger `matiereMaitrise` depuis `AppUser.bktMaitrise`

`AppUser.bktMaitrise` est un `Map<String, double>` (competenceId → P(L)).
Pour le passer au module orientation, il faut agréger par matière. Idéalement
via un helper `subject_stats_service.dart` (déjà existant dans
`lib/screens/stats/services/subject_stats_service.dart`) qui expose
`Map<String, double> getMaitriseByMatiere(AppUser user)`.

Exemple d'appel :

```dart
final user = context.read<UserProvider>().currentUser;
final matieres = SubjectStatsService().getMaitriseByMatiere(user);
Navigator.push(
  context,
  MaterialPageRoute<void>(
    builder: (_) => OrientationChatScreen(
      matiereMaitrise: matieres,
      niveauScolaire: user.niveauScolaire,
      serie: user.serie,
    ),
  ),
);
```

### 4. (Optionnel) Persister le profil

Pour l'instant, le profil est volatile (recalculé à chaque session). Si on
veut le conserver entre les sessions, on peut :

- Soit l'ajouter à `AppUser` comme champ `OrientationProfile? profilOrientation`
  (avec un adapter Hive).
- Soit utiliser une box Hive dédiée `orientation_profile` (typeId à allouer par
  l'agent Hive master, BA).

## Conventions de code

- Flutter 3.44+ / Material 3 / Provider (mais ce module utilise StatefulWidget
  pour l'état du chat — suffisant pour 12 questions séquentielles).
- Pas d'emojis. Commentaires en français.
- Couleurs via `AppColors` (vert Togo #006837 + orange #D97700).
- Textes via `AppTextStyles`.
- Pas de dépendance externe supplémentaire (utilise uniquement `fl_chart`
  déjà dans pubspec, `provider` déjà dans pubspec).

## Limitations v1

- Pas de persistance du profil (recalculé à chaque session).
- Pas de partage natif (utilise `share_plus` non en pubspec — placeholder
  SnackBar "Profil copié" + debugPrint).
- Pas d'export PDF du profil (le module BP s'en occupe).
- Pas d'historique des recommandations (à chaque session, on écrase).
- Les 12 questions sont fixes (pas de branchement conditionnel). Pour une v2,
  on pourrait skiper Q11-Q12 si l'élève a déjà indiqué vouloir des études
  courtes en Q9, etc.

## Tests recommandés (post-wiring)

- Widget test : `OrientationChatScreen` répond aux 12 questions → vérifie
  `_isFinished == true` et `_finalProfile != null`.
- Unit test : `OrientationService.calculerProfil` avec réponses toutes "a" →
  vérifie axe scientifique dominant.
- Unit test : `OrientationService.recommander` avec profil "Scientifique pur"
  → vérifie que Médecine/Ingénierie sont dans le top 5.
- Widget test : `FiliereCard` expand/collapse → vérifie `initiallyExpanded`.

## Auteur

- Agent BS (general-purpose) — Session 4, Vague 2 — 2 juillet 2026.
