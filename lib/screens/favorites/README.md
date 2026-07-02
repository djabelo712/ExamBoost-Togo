# Favoris & Notes personnelles — ExamBoost Togo

Module permettant a l'eleve de :
1. Marquer des questions comme **favorites** (bouton coeur, toggle).
2. Ajouter une **note personnelle** par question ("revoir cette methode",
   "astuce : factoriser d'abord") avec categorie visuelle.
3. Consulter ses favoris dans une page dediee avec **filtres + tri**.
4. Consulter ses notes dans une page dediee avec **filtres + export**.

> Task ID : **AN-favoris-notes** (Session 3, Vague 2)
> Conforme aux regles globales : pas d'emojis, commentaires FR,
> Provider pour la gestion d'etat, Material 3 + palette AppColors.

---

## Structure du dossier

```
lib/screens/favorites/
├── favorites_screen.dart              # Page "Mes favoris"
├── notes_screen.dart                  # Page "Mes notes"
├── README.md                          # Ce fichier
├── models/
│   ├── favorite_question.dart         # Hive model (typeId 15)
│   ├── favorite_question.g.dart       # Genere par build_runner
│   ├── question_note.dart             # Hive model (typeId 16) + NoteCategory helper
│   └── question_note.g.dart           # Genere par build_runner
├── services/
│   └── favorites_service.dart         # ChangeNotifier (Hive boxes + API)
└── widgets/
    ├── favorite_button.dart           # Bouton coeur reutilisable (bounce anim)
    ├── note_editor_sheet.dart         # Bottom sheet creer/editer note
    ├── favorite_question_card.dart    # Carte question favorite
    └── note_card.dart                 # Carte note personnelle
```

Aucune dependance externe supplementaire par rapport au `pubspec.yaml`
existant : on reutilise `hive`, `provider`, `uuid` (deja presents).

---

## Integration (a realiser par l'agent principal / wiring)

Les 6 etapes ci-dessous doivent etre effectuees dans les fichiers
"interdits" pour cet agent. Les snippets sont prets a copier-coller.

### 1. `lib/main.dart` — Enregistrer les adaptateurs Hive + ouvrir le service

Apres `Hive.registerAdapter(QuestionTypeAdapter());` (ligne ~51) :

```dart
// ─── Adapteres favoris + notes (Agent AN) ───────────────────────
import 'screens/favorites/models/favorite_question.dart';
import 'screens/favorites/models/question_note.dart';
import 'screens/favorites/services/favorites_service.dart';

// Apres les autres registerAdapter :
Hive.registerAdapter(FavoriteQuestionAdapter());
Hive.registerAdapter(QuestionNoteAdapter());

// Apres SrsService.init() / QuestionService.loadQuestions() :
final favoritesService = FavoritesService();
await favoritesService.init();
```

Puis dans le `MultiProvider`, ajouter :

```dart
ChangeNotifierProvider<FavoritesService>.value(value: favoritesService),
```

### 2. Generer les fichiers `*.g.dart`

Le module depend de `favorite_question.g.dart` et `question_note.g.dart`
(adaptateurs Hive). Les generer avec :

```bash
dart run build_runner build --delete-conflicting-outputs
```

(cette commande regenere egalement les autres `.g.dart` du projet :
`question.g.dart`, `review_card.g.dart`, `user.g.dart`, etc.)

### 3. `lib/utils/app_router.dart` — Ajouter les routes `/favorites` et `/notes`

Ajouter les imports :

```dart
import '../screens/favorites/favorites_screen.dart';
import '../screens/favorites/notes_screen.dart';
```

Dans le tableau `routes`, ajouter (avant `errorBuilder`) :

```dart
// ─── Favoris : slideRight (Agent AN) ─────────────────────────────
GoRoute(
  path: '/favorites',
  name: 'favorites',
  pageBuilder: (context, state) => buildPageWithTransition(
    child: const FavoritesScreen(),
    type: TransitionType.slideRight,
  ),
),

// ─── Notes : slideRight (Agent AN) ───────────────────────────────
GoRoute(
  path: '/notes',
  name: 'notes',
  pageBuilder: (context, state) => buildPageWithTransition(
    child: const NotesScreen(),
    type: TransitionType.slideRight,
  ),
),
```

Et dans la classe `AppRoutes`, ajouter les constantes :

```dart
static const String favorites = '/favorites';
static const String notes      = '/notes';
```

### 4. `lib/screens/home/home_screen.dart` — Ajouter les entrees "Mes favoris" et "Mes notes"

Apres la carte "Mon Tableau de Bord" (vers ligne 100), ajouter deux
`_ActionCard` :

```dart
const SizedBox(height: 12),
_ActionCard(
  icon: Icons.favorite_outline,
  title: 'Mes favoris',
  subtitle: 'Questions marquees pour revision rapide',
  color: AppColors.error,
  onTap: () => context.go(AppRoutes.favorites),
),
const SizedBox(height: 12),
_ActionCard(
  icon: Icons.sticky_note_2_outlined,
  title: 'Mes notes',
  subtitle: 'Mes astuces et remarques sur les questions',
  color: AppColors.accent,
  onTap: () => context.go(AppRoutes.notes),
),
```

### 5. Integrer `FavoriteButton` dans `QuestionCard` (revision + simulation)

Le bouton est concu pour etre place dans le coin haut-droit d'une
carte question. Deux options :

#### Option A — dans `lib/widgets/cards/question_card.dart`

Dans le `Row` du header de `_buildQuestion()` (ligne ~48), remplacer le
`Spacer()` par :

```dart
const Spacer(),
FavoriteButton(
  questionId: question.id,
  userId: userId, // ⚠️ passer userId au constructeur de QuestionCard
),
```

(`QuestionCard` doit donc recevoir un parametre `final String userId;`.)

#### Option B — wrapper local dans revision_screen / simulation_screen

Si l'agent principal prefere ne pas modifier `QuestionCard`, il peut
placer le `FavoriteButton` en `Stack` au-dessus de la `QuestionCard` :

```dart
Stack(
  alignment: Alignment.topRight,
  children: [
    QuestionCard(question: q, reponseVisible: ..., flipAnimation: ...),
    Padding(
      padding: const EdgeInsets.only(top: 8, right: 8),
      child: FavoriteButton(
        questionId: q.id,
        userId: userProvider.currentUserId,
      ),
    ),
  ],
)
```

### 6. Integrer un bouton "Ajouter une note" dans QuestionCard

Importer :

```dart
import 'screens/favorites/widgets/note_editor_sheet.dart';
import 'screens/favorites/services/favorites_service.dart';
import 'package:provider/provider.dart';
```

Et ajouter (par exemple dans le header, juste apres `FavoriteButton`) :

```dart
Consumer<FavoritesService>(
  builder: (context, service, _) {
    final existing = service.getNote(userId, question.id);
    return IconButton(
      icon: Icon(
        existing == null ? Icons.note_add_outlined : Icons.sticky_note_2,
        color: existing == null ? AppColors.textSecondary : AppColors.info,
      ),
      tooltip: existing == null ? 'Ajouter une note' : 'Modifier la note',
      onPressed: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => NoteEditorSheet(
          questionId: question.id,
          userId: userId,
          existingNote: existing,
        ),
      ),
    );
  },
)
```

> Note : `FavoritesService` etant un `ChangeNotifier`, `Consumer<FavoritesService>`
> (package `provider`) rebuild le widget quand le service notifie. Alternativement
> on peut utiliser `ListenableBuilder(listenable: service, builder: ...)` (Flutter
> 3.16+ natif).

---

## Categories de notes

Les 4 categories disponibles (cf. `NoteCategory` dans
`models/question_note.dart`) :

| id       | label                   | couleur            | icone                       |
|----------|-------------------------|--------------------|-----------------------------|
| `yellow` | A revoir                | Orange `#F57C00`   | `visibility_outlined`       |
| `green`  | Compris                 | Vert `#2E7D32`     | `check_circle_outline`      |
| `blue`   | Astuce                  | Bleu `#1565C0`     | `lightbulb_outline`         |
| `pink`   | Question pour le prof   | Rose `#D81B60`     | `help_outline`              |

Ces categories sont affichees dans `NoteEditorSheet` (selection via
ChoiceChip colores), dans `NoteCard` (bande de couleur a gauche) et
dans `NotesScreen` (filtre horizontal).

---

## API du service

```dart
class FavoritesService extends ChangeNotifier {
  Future<void> init();

  // Favoris
  bool isFavorite(String userId, String questionId);
  Future<bool> toggleFavorite(String userId, String questionId); // true = desormais fav
  List<String> getFavoriteIds(String userId);
  List<FavoriteQuestion> getFavorites(String userId); // triees par addedAt desc
  int favoritesCount(String userId);

  // Notes
  QuestionNote? getNote(String userId, String questionId);
  Future<void> saveNote({required String userId, required String questionId,
                         required String content, String color = 'yellow'});
  Future<void> deleteNote(String userId, String questionId);
  List<QuestionNote> getAllNotes(String userId); // triees par updatedAt desc
  int notesCount(String userId);

  // Export
  String exportNotesAsText(String userId, {String Function(String?)? questionLabelResolver});
}
```

Le service appelle `notifyListeners()` apres chaque modification
(`toggleFavorite`, `saveNote`, `deleteNote`), ce qui declenche le
rebuild de tous les widgets qui l'ecoutent via `Provider.of(context)`
ou `ValueListenableBuilder`.

---

## UX notable

- **FavoriteButton** : animation bounce (scale 1.0 -> 1.3 -> 1.0) au tap,
  avec `SnackBar` flottant de confirmation + bouton "Annuler" (snackbar
  action) pour permettre un retrait immediat si ajout par erreur.
- **NoteEditorSheet** : `autofocus` en mode creation (pas en edition,
  pour eviter que le clavier ne masque le contenu existant). Compteur
  de caracteres (max 500). Sauvegarde desactivee si texte vide.
- **FavoritesScreen** : `RefreshIndicator` (pull-to-refresh) meme sur
  l'etat vide (ListView au lieu de Center) pour permetttre le rechargement.
- **NotesScreen** : double etat vide — "aucune note creee" (CTA reviser)
  vs "aucune note ne correspond aux filtres" (CTA reinitialiser filtres).
- **Export** : texte ASCII avec `#Categorie` en prefix de chaque note,
  date au format JJ/MM/AAAA HH:MM, et enonce de la question associee
  (recupere via `QuestionService.getById`). Copie dans le presse-papier
  via `Clipboard.setData`.
- **Long press** sur `FavoriteQuestionCard` et `NoteCard` : menu
  contextuel (BottomSheet) avec actions (Retirer/Modifier/Supprimer/
  Voir details). Conforme au standard mobile (long press = actions).
- **Tri par difficulte** : utilise `Question.difficulte` (enum
  `DifficulteNiveau` defini dans `models/question.dart`), ordre
  facile < moyen < difficile.

---

## Limitations connues

1. **Pas de synchronisation cloud** : les favoris et notes sont stockes
   uniquement en local (Hive). Une V2 pourrait integrer la sync queue
   existante (`lib/services/sync_queue.dart`) pour pousser les notes
   vers le backend FastAPI quand le reseau est disponible.
2. **Pas de partage natif** : l'export ne fait que copier dans le
   presse-papier. Pour utiliser `share_plus` (partage natif Android),
   il faudrait ajouter le package au `pubspec.yaml` (sort du perimetre
   de cet agent).
3. **Une seule note par question** : par design (voir `getNote` +
   `saveNote`), on ne peut avoir qu'une note par couple
   (userId, questionId). Si l'eleve veut plusieurs notes sur une meme
   question, il faudra modifier le modele pour autoriser plusieurs
   entrees et adapter l'UI.
4. **`FavoriteButton` ne supporte pas le dark mode explicite** : il
   utilise `AppColors.error` et `AppColors.textDisabled` qui sont des
   constantes (les memes en clair et sombre). Si on veut differencier,
   il faudra utiliser `Theme.of(context).colorScheme` a la place.
5. **Generation `.g.dart` obligatoire** : sans `dart run build_runner
   build --delete-conflicting-outputs`, le code ne compilera pas (les
   adaptateurs `FavoriteQuestionAdapter` et `QuestionNoteAdapter` ne
   seront pas generes). Cette contrainte est commune a tous les
   HiveType du projet.
