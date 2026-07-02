# Système de Badges & Gamification — ExamBoost Togo

Système complet de gamification avec **39 badges débloquables** répartis sur 5 catégories, **3 niveaux** par badge (Bronze / Argent / Or), une page collection filtrable et une animation de déblocage mémorable.

## Architecture

```
lib/
├── models/
│   └── badge.dart                          # Badge + UserBadge + Badges (catalogue 39)
├── services/
│   └── badge_service.dart                  # Logique de calcul + débloquage + persistance
└── screens/badges/
    ├── badges_screen.dart                  # Page collection (header + filtres + grille)
    ├── badge_detail_sheet.dart             # Bottom sheet détails d'un badge
    ├── badge_unlock_dialog.dart            # Dialog animation de déblocage
    ├── README.md                           # Ce fichier
    └── widgets/
        ├── badge_card.dart                 # Carte badge (3 états : débloqué/en cours/verrouillé)
        ├── badge_progress_bar.dart         # Barre progression compacte & détaillée
        └── badge_grid.dart                 # GridView 3 colonnes
```

## Les 39 badges

### Catégorie Régularité (9 badges)
| Badge | Bronze | Argent | Or |
|---|---|---|---|
| Régularité | 7 jours | 30 jours | 100 jours |
| Marathonien | 50 sessions | 200 sessions | 500 sessions |
| Lève-tôt | 5 matins | 20 matins | 50 matins |

### Catégorie Révision (9 badges)
| Badge | Bronze | Argent | Or |
|---|---|---|---|
| Curieux | 100 questions | 500 questions | 2000 questions |
| Assidu | 10 matières | 30 chapitres | 60 chapitres |
| Rapide | 20 q / 10 min | 50 q / 20 min | 100 q / 30 min |

### Catégorie Maîtrise (9 badges)
| Badge | Bronze | Argent | Or |
|---|---|---|---|
| Maître Maths | 5 compétences | 15 compétences | 30 compétences |
| Pro Français | 5 compétences | 15 compétences | 30 compétences |
| Polyvalent | 3 matières | 5 matières | 8 matières |

### Catégorie Simulation (9 badges)
| Badge | Bronze | Argent | Or |
|---|---|---|---|
| Prêt pour l'examen | 1 simulation | 5 simulations | 20 simulations |
| Top Score | 10/20 | 14/20 | 18/20 |
| Sans faute | 1 parfaite | 3 parfaites | 10 parfaites |

### Catégorie Spécial (3 badges — niveau Or uniquement)
- **Premier pas** : première révision effectuée
- **Pionnier** : fait partie des 500 premiers inscrits (heuristique : inscrit avant le 31/07/2026)
- **Beta-testeur** : a signalé un bug ou proposé une fonctionnalité

### Récompenses XP
- Bronze : 100 XP
- Argent : 250 XP
- Or : 500 XP

**Total possible** : 39 badges × ~330 XP moyen ≈ 12 875 XP

---

## Intégration au projet (3 étapes obligatoires)

### Étape 1 — Générer les adaptateurs Hive

Le fichier `lib/models/badge.dart` déclare 3 `@HiveType` :
- `BadgeCategory` (typeId: 7)
- `BadgeLevel` (typeId: 8)
- `UserBadge` (typeId: 9)

Lancer le générateur de code :

```bash
cd ExamBoost-Togo
dart run build_runner build --delete-conflicting-outputs
```

> ⚠️ Cela génère `lib/models/badge.g.dart` (avec `BadgeCategoryAdapter`, `BadgeLevelAdapter`, `UserBadgeAdapter`).

### Étape 2 — Enregistrer les adaptateurs + initialiser le BadgeService

Dans `lib/main.dart`, ajouter les imports :

```dart
import 'models/badge.dart';
import 'services/badge_service.dart';
```

Dans `main()`, après `Hive.registerAdapter(QuestionTypeAdapter());` :

```dart
Hive.registerAdapter(BadgeCategoryAdapter());
Hive.registerAdapter(BadgeLevelAdapter());
Hive.registerAdapter(UserBadgeAdapter());
```

Puis, après `await srsService.init();` :

```dart
final badgeService = BadgeService();
await badgeService.init();
```

Et l'ajouter au `MultiProvider` :

```dart
MultiProvider(
  providers: [
    Provider<SrsService>.value(value: srsService),
    Provider<QuestionService>.value(value: questionService),
    Provider<BadgeService>.value(value: badgeService),     // <-- ajouter
    ChangeNotifierProvider<UserProvider>.value(value: userProvider),
  ],
  child: const ExamBoostApp(),
),
```

### Étape 3 — Ajouter la route `/badges`

Dans `lib/utils/app_router.dart` :

1. Ajouter l'import :
   ```dart
   import '../screens/badges/badges_screen.dart';
   ```

2. Ajouter la constante dans `AppRoutes` :
   ```dart
   static const String badges = '/badges';
   ```

3. Ajouter la route dans `routes: [...]` :
   ```dart
   GoRoute(
     path: AppRoutes.badges,
     name: 'badges',
     builder: (context, state) => const BadgesScreen(),
   ),
   ```

---

## Intégration optionnelle (recommandée)

### Bouton "Mes Badges" dans le Dashboard ou Home

Dans `lib/screens/dashboard/dashboard_screen.dart` (ou `home_screen.dart`), ajouter un bouton dans la section actions rapides :

```dart
ElevatedButton.icon(
  onPressed: () => context.go('/badges'),
  icon: const Icon(Icons.emoji_events),
  label: const Text('Mes Badges'),
),
```

### Déclencher la vérification après une révision

Dans `lib/screens/revision/revision_screen.dart`, après chaque `srsService.recordAnswer(...)` :

```dart
final badgeService = Provider.of<BadgeService>(context, listen: false);
final srsStats = srsService.getStats(userId);
final nouveauxBadges = await badgeService.checkAndUnlock(
  user: user,
  reviewCards: srsService.getDueCards(userId), // ou toutes les cartes
  srsStats: srsStats,
);

if (nouveauxBadges.isNotEmpty && mounted) {
  // Afficher l'animation de déblocage
  await BadgeUnlockDialog.show(context, badge: nouveauxBadges.last);
  // Rafraîchir l'utilisateur (XP totale a peut-être changé)
  await Provider.of<UserProvider>(context, listen: false).refresh();
}
```

### Déclencher la vérification après une simulation

Dans `lib/screens/simulation/simulation_screen.dart`, à la fin de la phase "rapport" :

```dart
// 1. Enregistrer la simulation dans les métriques de badges
final badgeService = Provider.of<BadgeService>(context, listen: false);
await badgeService.recordSimulationComplete(
  scoreOver20: scoreFinal,
  allQcmCorrect: toutesLesQcmJustes,
);

// 2. Déclencher la vérification
final nouveauxBadges = await badgeService.checkAndUnlock(
  user: user,
  reviewCards: cards,
  srsStats: srsStats,
);

if (nouveauxBadges.isNotEmpty && mounted) {
  await BadgeUnlockDialog.show(context, badge: nouveauxBadges.last);
}
```

### Enregistrer une révision matinale (avant 8h)

Dans `revision_screen.dart`, dans le handler de réponse, vérifier l'heure :

```dart
if (DateTime.now().hour < 8) {
  await badgeService.recordEarlyRevision();
}
```

### Enregistrer un "burst" de vitesse

Si l'élève répond à N questions en moins de M minutes, enregistrer :

```dart
await badgeService.recordSpeedBurst(
  questionsAnswered: nbQuestions,
  durationMinutes: dureeMinutes,
);
```

### Marquer un bug signalé (bouton "Signaler un bug")

```dart
await badgeService.markBugReported();
```

---

## API du BadgeService

| Méthode | Description |
|---|---|
| `init()` | Ouvre les Hive boxes `user_badges` et `badge_metrics`. À appeler dans `main.dart`. |
| `checkAndUnlock({user, reviewCards, srsStats})` | Vérifie tous les badges, met à jour les progressions, débloque ceux dont le seuil est atteint. Retourne la liste des nouveaux badges débloqués. **À appeler après chaque action métier.** |
| `recordEarlyRevision()` | Incrémente le compteur de révisions matinales (avant 8h). |
| `recordSimulationComplete({scoreOver20, allQcmCorrect})` | Enregistre une simulation terminée. |
| `recordSpeedBurst({questionsAnswered, durationMinutes})` | Enregistre un burst de questions rapides. |
| `markBugReported()` | Marque l'élève comme beta-testeur. |
| `allUserBadges` | Liste tous les UserBadge persistés. |
| `unlockedBadges` | Liste des Badge débloqués (catalogue). |
| `unlockedCount` | Nombre de badges débloqués. |
| `totalCount` | Nombre total de badges (39). |
| `totalXp` | Somme des XP des badges débloqués. |
| `globalProgress` | Pourcentage global (0.0–1.0). |
| `userBadgeFor(badgeId)` | Récupère l'UserBadge pour un badge donné. |

---

## Décisions de design

### Badge = classe constante (non persistée)
Les `Badge` sont des **constantes** (catalogue statique) — pas besoin d'adaptateur Hive pour les persister. Seul `UserBadge` (état par élève) est persisté. Cela évite de stocker 39 entrées statiques dans Hive.

### Métriques d'événements (box `badge_metrics`)
Certains badges ne sont pas dérivables des modèles existants (AppUser, ReviewCard, SrsStats) :
- **Lève-tôt** : compteur de révisions matinales (peut aussi être dérivé des `lastReviewDate.hour < 8` des cartes, mais le compteur est plus précis)
- **Rapide** : meilleur burst de questions en 10/20/30 min
- **Simulation complète / Top Score / Sans faute** : métriques spécifiques aux simulations
- **Beta-testeur** : booléen "a signalé un bug"

Ces métriques sont stockées dans une `Box<dynamic>` nommée `badge_metrics`. Les méthodes `recordEarlyRevision`, `recordSimulationComplete`, `recordSpeedBurst`, `markBugReported` permettent aux écrans d'enregistrer ces événements.

### Streak : tolérance "hier ou aujourd'hui"
La logique de streak accepte que l'élève ait révisé **aujourd'hui** ou **hier** (grâce au curseur qui recule d'un jour si aujourd'hui n'a pas encore de révision). Cela évite qu'un streak se "casse" à minuit si l'élève révise le soir.

### Pionnier : heuristique beta
Sans backend, on ne peut pas connaître le rang d'inscription. Heuristique : tout élève inscrit avant le **31 juillet 2026** est considéré comme pionnier. À remplacer par un appel backend `GET /users/{id}/rank` quand le backend FastAPI sera branché.

### Polyvalent : 3 matières maîtrisées
"Maîtrise" = au moins une compétence avec P(L) BKT ≥ 0,85 dans la matière. Le code parse les clés `competenceId` au format `TG-MATHS-EQ1D-001` pour extraire la matière (parts[1]).

### Animation de déblocage
Le dialog `BadgeUnlockDialog` utilise deux `AnimationController` :
- Principal (1,8 s) : explosion de particules + scale du badge (easeOutBack) + apparition en cascade du texte
- Glow (1,2 s, boucle infinie) : pulsation du BoxShadow doré

Les particules sont dessinées via un `CustomPainter` (`_ParticlePainter`) avec 24 particules réparties sur 360°, qui s'étendent depuis le centre et s'estompent. Un anneau de choc (cercle qui s'élargit) renforce l'effet "explosion".

### Partage (UI only)
Le bouton "Partager" affiche pour l'instant un `SnackBar` avec le texte de partage. Pour une vraie intégration :
1. Ajouter le package `share_plus` au `pubspec.yaml`
2. Utiliser `RepaintBoundary` pour capturer le badge en PNG
3. Appeler `Share.shareXFiles([XFile(pngPath)], text: '...')`

---

## Dépannage

### "type 'Null' is not a subtype of type 'int'" au lancement
→ Vous avez oublié d'enregistrer `UserBadgeAdapter` (ou `BadgeCategoryAdapter` / `BadgeLevelAdapter`) dans `main.dart`. Voir Étape 2.

### La grille affiche tous les badges verrouillés
→ Le `BadgeService` n'a pas encore tourné. La page `BadgesScreen` appelle `checkAndUnlock` au chargement, donc les badges devraient se débloquer après le premier `setState`. Si non, vérifiez que les `ReviewCard` ont bien un `lastReviewDate` non-null (c'est lui qui alimente le streak).

### Les badges de simulation ne se débloquent pas
→ Vous n'avez pas appelé `badgeService.recordSimulationComplete(...)` à la fin de la simulation. Voir "Déclencher la vérification après une simulation" ci-dessus.

### L'animation de déblocage ne s'affiche pas
→ Vérifiez que vous appelez `BadgeUnlockDialog.show(context, badge: ...)` après `checkAndUnlock`, et que la liste `nouveauxBadges` n'est pas vide.

---

## Tests rapides (sans révision)

Pour tester rapidement le système, dans un terminal Dart :

```dart
// 1. Marquer l'utilisateur comme beta-testeur
await badgeService.markBugReported();

// 2. Forcer une simulation parfaite
await badgeService.recordSimulationComplete(scoreOver20: 18, allQcmCorrect: true);

// 3. Recharger la page Badges — 3 badges devraient se débloquer :
//    - pret_examen_bronze
//    - top_score_or (18/20)
//    - sans_faute_bronze
//    - beta_testeur_or
```
