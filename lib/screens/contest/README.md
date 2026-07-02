# Module Concours inter-ecoles (Agent BM)

Mode concours mensuel entre etablissements scolaires togolais : classement
national et regional des ecoles, trophees or/argent/bronze, et suivi de la
contribution de chaque eleve au total de son etablissement.

## Arborescence

```
lib/screens/contest/
├── contest_home_screen.dart         # Ecran d'accueil du module
├── contest_leaderboard_screen.dart  # Classement complet (national/regional)
├── contest_details_screen.dart      # Detail d'un concours (en cours ou passe)
├── contest_history_screen.dart      # Historique des 6 derniers concours
├── widgets/
│   ├── school_ranking_card.dart     # Carte d'une ecole classee
│   ├── contest_progress_widget.dart # Barre progression collective
│   ├── trophy_showcase.dart         # Vitrine trophees (or/argent/bronze)
│   └── contribution_card.dart       # Carte "ma contribution"
├── services/
│   └── contest_service.dart         # ChangeNotifier : etat + logique
├── models/
│   ├── contest.dart                 # Contest + ContestTrophy + enums
│   ├── school_ranking.dart          # SchoolRanking
│   └── contest_contribution.dart    # Contribution + MyContributionSummary
└── README.md
```

## Features

1. **Concours mensuel thematique** : chaque mois, une matiere a l'honneur
   ("Maths Mars 2026", "SVT Janvier 2026", etc.). Le concours en cours est
   expose via `ContestService.currentContest`.

2. **Classement des 50 ecoles** : top 50 national (toutes regions confondues)
   et classement regional filtre par region. Les ecoles sont des etablissements
   reels du Togo (Lycee de Tokoin, Lycee Beyrout, Lycee de Kara, etc.),
   repartis sur les 6 regions administratives.

3. **Podium national** : top 3 affiche en style olympique (2e - 1er - 3e)
   sur l'ecran d'accueil, avec couleurs de medaille or/argent/bronze.

4. **Ma contribution** : total des points apportes par l'eleve a son ecole,
   rang dans l'ecole, repartition par type (questions / simulations /
   badges / bonus streak), et liste des contributions recentes.

5. **Trophees ecoles** : medailles mensuelles (or/argent/bronze) gagnees
   lors des concours precedents, affiches dans une "vitrine" horizontale
   (TrophyShowcase) sur l'ecran d'accueil et au survol d'une ecole.

6. **Historique** : 6 derniers concours mensuels termines, avec ecole
   gagnante, points cumules et acces au detail.

## Mecanique des points (cahier des charges)

| Action                       | Points pour l'ecole |
| ---------------------------- | ------------------- |
| Question correcte            | +10                 |
| Simulation reussie (>10/20)  | +50                 |
| Badge debloque               | +100                |
| Streak 7 jours consecutifs   | +200                |

Les valeurs sont definies dans `ContributionType.points` (extension sur
l'enum, ce qui centralise la logique et evite les constantes eparses).

## Architecture

### Provider / ChangeNotifier

`ContestService` est un `ChangeNotifier`. Il est instancie et expose via
`ChangeNotifierProvider` au niveau de `ContestHomeScreen` (pas dans
`main.dart`, conformement a la consigne "NE PAS toucher au router/main.dart/pubspec").

```dart
class ContestHomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ContestService()..load(),
      child: const _HomeView(),
    );
  }
}
```

Les sous-ecans (leaderboard, details, history) sont pousses via
`Navigator.push` et recoivent le service en parametre constructeur, puis
le re-exposent via `ChangeNotifierProvider.value` pour que leurs widgets
puissent utiliser `context.watch<ContestService>()`.

### Donnees mock

Toutes les donnees sont generees de facon deterministe (`Random(seed)`
fixe) pour assurer la stabilite entre les rebuilds :
- `Random(2026)` pour les ecoles (points 500-5000, eleves actifs 20-99).
- `Random(73)` pour les concours passes (points finaux, gagnants).
- `Random(2026)` pour la contribution de l'eleve.

En production, chaque getter sera remplace par un appel a un backend
FastAPI (`/api/contests/current`, `/api/schools/ranking`, etc.).

### Mon ecole

L'ecole de l'eleve courant est mockee comme `Lycée de Tokoin` (id
`lycee-tokoin`, region `Lome`). En production, ce sera recupere depuis
le `UserProvider` (`appUser.ecoleId`).

## Integration (a faire par l'agent principal)

Le module est volontairement isole : aucun fichier externe n'a ete modifie.
Pour l'integrer dans l'app, l'agent principal devra :

1. **Router** : ajouter une route `/contest` dans `app_router.dart`
   pointant vers `ContestHomeScreen()`.
2. **Home** : ajouter une carte d'action dans `home_screen.dart` :
   ```dart
   _ActionCard(
     titre: 'Concours inter-ecoles',
     icone: Icons.emoji_events,
     onTap: () => context.go('/contest'),
   )
   ```
3. **Provider** : aucune modification necessaire dans `main.dart` (le
   `ChangeNotifierProvider` est declare dans `ContestHomeScreen`).

## Conventions respectees

- Flutter 3.44+ / Material 3 (SegmentedButton, ChoiceChip, SliverAppBar).
- Provider pour la gestion d'etat (`ChangeNotifierProvider`).
- Theme centralise (`AppColors`, `AppTextStyles` de `lib/theme/app_theme.dart`).
- Pas d'emojis dans le code ni dans les textes utilisateur.
- Commentaires en francais.
- Pas de modification du router / main.dart / pubspec (consigne respectee).
