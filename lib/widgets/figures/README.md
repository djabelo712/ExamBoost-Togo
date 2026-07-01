# Module `lib/widgets/figures/` — Figures SVG pour questions de géométrie

Ce module fournit une **bibliothèque de figures SVG inline** et un **widget de
rendu** (`SvgFigure`) pour afficher des figures géométriques dans les questions
d'ExamBoost Togo (Pythagore, Thalès, cercles, volumes, trigonométrie, etc.).

Sans figures, il était impossible de tester correctement la géométrie au BEPC
et au BAC — d'où ce module.

## Arborescence

```
lib/widgets/figures/
├── figures_library.dart    # 15 figures SVG prédéfinies (clé -> svg string)
├── svg_figure.dart         # Widget de rendu (wrapper flutter_svg)
└── README.md               # Ce fichier

assets/data/
└── geometry_questions.json # 15 questions de géométrie avec figure_id
```

## Dépendances

| Package       | Version      | Statut                       |
|---------------|--------------|------------------------------|
| flutter_svg   | ^2.0.10+1    | Déjà présent dans pubspec ✓  |

Aucune dépendance à ajouter. Le module est **autonome**.

## Liste des 15 figures disponibles

| Clé                       | Description                                                  | Cas d'usage typique                           |
|---------------------------|--------------------------------------------------------------|-----------------------------------------------|
| `triangle_rectangle_3_4_5`| Triangle ABC rectangle en A (AB=3, AC=4, BC=5)              | Pythagore BEPC                                |
| `cercle_rayon_5`          | Cercle de centre O, rayon r=5 cm                             | Aire / périmètre cercle                       |
| `thales_triangle`         | Triangle CAB avec (DE) // (AB), D et E milieux               | Théorème de Thalès BEPC                       |
| `fonction_parabole`       | Parabole y=x² dans repère orthonormé                         | Étude de fonctions BAC                        |
| `cylindre_3d`             | Cylindre droit 3D (r=3, h=10)                                | Volume cylindre BEPC                          |
| `pyramide`                | Pyramide à base carrée (côté 6, h variable)                  | Volume pyramide BEPC                          |
| `angle_inscrit`           | Cercle avec angle inscrit AMB et arc AB                       | Théorème angle inscrit BAC                    |
| `triangle_quelconque`     | Triangle ABC (7, 5, 6 cm)                                    | Périmètre / angles BEPC                       |
| `parallelogramme`         | ABCD avec base 8 et hauteur 5                                | Aire parallélogramme BEPC                     |
| `trapeze`                 | Trapèze ABCD (B=6, b=10, h=4)                                | Aire trapèze BEPC                             |
| `sinus_cosinus`           | Courbes sin(x) (vert) et cos(x) (orange)                     | Lecture graphique trigo BAC                   |
| `histogramme_stats`       | Histogramme 5 classes, classe modale en orange               | Stats — classe modale BAC                     |
| `cercle_trigonometrique`  | Cercle trigo avec point M à α=π/3                            | Valeurs remarquables cos/sin BAC              |
| `systeme_axes`            | Repère orthonormé avec A, B, C placés                        | Distance analytique BAC                       |
| `losange`                 | Losange ABCD (diagonales 6 et 8)                             | Aire losange + côté BEPC                      |

Toutes les figures respectent la palette ExamBoost :
- Vert Togo **#006837** (traits principaux, axes)
- Orange **#D97700** (éléments mis en valeur, hypoténuse, hauteur, arc, classe modale)
- Texte primaire **#1A1A1A**, secondaire **#757575**, axes **#9E9E9E**

## Usage du widget `SvgFigure`

```dart
import 'package:examboost_togo/widgets/figures/svg_figure.dart';

// Affichage simple
SvgFigure(figureId: 'triangle_rectangle_3_4_5', width: 220)

// Avec teinte (dark mode)
SvgFigure(
  figureId: 'cercle_rayon_5',
  width: 180,
  tint: Theme.of(context).colorScheme.primary,
)

// Gestion figure inconnue : pas de crash, placeholder "Figure introuvable"
SvgFigure(figureId: 'cle_inexistante') // affiche un placeholder discret
```

Propriétés du widget :
- `figureId` (String, requis) — clé dans `FiguresLibrary`
- `width` / `height` (double?) — taille d'affichage (null = taille naturelle du viewBox)
- `tint` (Color?) — teinte optionnelle (ColorFilter srcIn)
- `semanticLabel` (String?) — pour lecteurs d'écran
- `padding` (EdgeInsetsGeometry) — marge interne (défaut : aucune)
- `alignment` (AlignmentGeometry) — alignement (défaut : `center`)
- `clipToSize` (bool) — empêche la figure de dépasser (défaut : `false`)

## Intégration avec le modèle `Question`

### Étape 1 — Ajouter le champ `figureId` au modèle

Dans `lib/models/question.dart`, ajouter un nouveau `@HiveField` (le prochain
numéro libre est 17) :

```dart
@HiveField(17)
final String? figureId; // Identifiant de figure SVG (ex: "triangle_rectangle_3_4_5")
```

Puis l'ajouter au constructeur :

```dart
Question({
  // ... champs existants ...
  this.figureId,
});
```

### Étape 2 — Brancher `fromJson` / `toJson`

```dart
factory Question.fromJson(Map<String, dynamic> json) {
  return Question(
    // ... champs existants ...
    figureId: json['figure_id'], // peut être null (question sans figure)
  );
}

Map<String, dynamic> toJson() => {
  // ... champs existants ...
  'figure_id': figureId,
};
```

### Étape 3 — Régénérer les adaptateurs Hive

Après modification du modèle, lancer :

```bash
cd /home/z/my-project/ExamBoost-Togo
dart run build_runner build --delete-conflicting-outputs
```

Cela régénère `lib/models/question.g.dart` avec le nouveau champ `figureId`
(important : sans ça, Hive ne saura pas lire le champ au runtime).

### Étape 4 — Charger le fichier `geometry_questions.json`

Dans `lib/services/question_service.dart`, charger le nouveau fichier JSON en
parallèle de `questions.json` et fusionner :

```dart
Future<List<Question>> loadAll() async {
  final manifest = await rootBundle.loadString('assets/data/questions.json');
  final geometry = await rootBundle.loadString('assets/data/geometry_questions.json');
  final list1 = (jsonDecode(manifest) as List).map((e) => Question.fromJson(e)).toList();
  final list2 = (jsonDecode(geometry) as List).map((e) => Question.fromJson(e)).toList();
  return [...list1, ...list2];
}
```

Et déclarer le fichier dans `pubspec.yaml` :

```yaml
flutter:
  assets:
    - assets/data/questions.json
    - assets/data/geometry_questions.json  # à ajouter
```

## Intégration dans `QuestionCard`

Le widget `lib/widgets/cards/question_card.dart` affiche l'énoncé. Pour
afficher la figure avant l'énoncé quand elle existe, modifier la méthode
`_buildQuestion()` :

```dart
// AVANT (existant)
Expanded(
  child: SingleChildScrollView(
    child: Text(question.enonce, style: AppTextStyles.questionText),
  ),
),

// APRÈS (proposition de patch)
Expanded(
  child: SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Figure SVG si présente
        if (question.figureId != null) ...[
          Center(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                ),
              ),
              child: SvgFigure(
                figureId: question.figureId!,
                width: 240,
                semanticLabel: 'Figure : ${question.figureId}',
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        // Énoncé
        Text(question.enonce, style: AppTextStyles.questionText),
      ],
    ),
  ),
),
```

Et ne pas oublier l'import en haut du fichier :

```dart
import '../figures/svg_figure.dart';
```

## Créer une nouvelle figure SVG

### 1. Choisir une clé explicite

Format snake_case, idéalement avec les dimensions : `triangle_isocele_5_5_6`,
`cercle_rayon_3`, `cone_3d_r4_h12`.

### 2. Dessiner le SVG

Contraintes :
- `xmlns="http://www.w3.org/2000/svg"` **obligatoire**.
- `viewBox="0 0 W H"` **obligatoire** (sinon flutter_svg peut refuser).
- Palette : `#006837` (vert), `#D97700` (orange), `#1A1A1A` (texte),
  `#757575` (texte secondaire), `#9E9E9E` (axes), `#E8F5ED` (fond vert clair).
- **Éléments supportés par flutter_svg 2.x** : `svg`, `g`, `polygon`,
  `polyline`, `line`, `rect`, `circle`, `ellipse`, `path`, `text`.
- **Éléments NON supportés** : `defs`, `linearGradient`, `radialGradient`,
  `filter`, `marker`, `use`, `clipPath`, `tspan`, `foreignObject`. Si vous avez
  besoin de dégradés, préférez des polygones avec couleurs unies.

### 3. Vérifier la cohérence sommet/label

Règle d'or : un label `A` doit être **collé au sommet A**, pas au milieu du
dessin. Sinon l'élève ne sait pas quel sommet est quel sommet.

### 4. Ajouter à `_figures` dans `figures_library.dart`

```dart
'ma_nouvelle_figure': '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200">
<polygon points="..." fill="none" stroke="#006837" stroke-width="2"/>
<text x="..." y="..." font-size="14" fill="#1A1A1A">A</text>
</svg>''',
```

### 5. Tester le rendu

```dart
SvgFigure(figureId: 'ma_nouvelle_figure', width: 220)
```

### 6. Référencer dans une question

```json
{
  "id": "TG-BEPC-MATHS-GEO-2024-Q10",
  "figure_id": "ma_nouvelle_figure",
  ...
}
```

## Conventions de code

- **Flutter 3.44+**, Material 3, Provider.
- **Pas d'emojis** dans le code ou les SVG.
- **Commentaires en français**.
- Les SVG sont stockés en `'''triple quotes'''` pour permettre le multiligne
  propre sans escaping.
- Les chaînes SVG ne contiennent **aucun commentaire XML** `<!-- ... -->` :
  flutter_svg 2.x les accepte mais c'est plus sûr de les éviter (et la
  bibliothèque reste lisible).
- Aucune logique métier dans `FiguresLibrary` : c'est un **catalogue pur**
  (static const Map), l'instance n'est jamais créée (constructeur privé).
- `SvgFigure` est **stateless** : pas de StatefulWidget inutile.

## Tests rapides (manuels)

1. Afficher chaque figure une par une et vérifier le rendu :
   ```dart
   Column(
     children: FiguresLibrary.availableFigures
         .map((id) => Padding(
               padding: const EdgeInsets.all(8),
               child: Column(children: [
                 Text(id),
                 SvgFigure(figureId: id, width: 200),
                 const Divider(),
               ]),
             ))
         .toList(),
   )
   ```
2. Vérifier qu'une `figureId` inconnue affiche bien le placeholder (pas de crash).
3. Charger `geometry_questions.json` via `Question.fromJson` et vérifier que
   `figureId` est correctement lu pour chaque question.
4. Vérifier le rendu en dark mode avec `tint: Colors.white` (les figures
   s'affichent en silhouette blanche).
5. Vérifier l'accessibilité : le `semanticsLabel` est exposé aux lecteurs
   d'écran (TalkBack / VoiceOver).

## Limites connues

- **flutter_svg 2.x** ne supporte pas les dégradés ni les filtres complexes.
  Les figures sont volontairement simples (traits pleins, fonds unis).
- Les chaînes SVG sont inline dans le code Dart (pas de fichiers `.svg`
  séparés) : cela évite une déclaration `assets/` supplémentaire et permet
  l'autocomplétion sur les clés. En contrepartie, la taille du bundle APK/AAB
  augmente légèrement (~12 Ko pour les 15 figures).
- Les coordonnées sont en pixels SVG (viewBox), pas en centimètres réels.
  Les labels "cm" sont indicatifs et ne doivent pas servir de référence
  physique.
- Aucune animation : les figures sont statiques. Pour des animations
  (ex: point M qui se déplace sur le cercle trigo), utiliser CustomPaint ou
  un widget Animé séparé — hors périmètre de ce module.

## Décisions de design

- **Catalogue static const** plutôt que Factory ou Provider : les figures sont
  immuables et connues à la compilation, inutile d'ajouter de l'indirection.
- **Placeholder plutôt qu'exception** si `figureId` inconnu : un crash écran
  noir pendant un examen est pire qu'une figure manquante. L'élève peut
  continuer.
- **Triple quotes `'''`** pour les SVG : permet le multiligne sans escaping
  des `'` et `"` internes aux attributs SVG.
- **Pas de cache** : `SvgPicture.string` reconstruit le DOM SVG à chaque
  build, mais flutter_svg a son propre cache interne (PictureProvider). Sur
  des figures de 200-1000 caractères, l'overhead est négligeable.
- **Clés en snake_case** plutôt qu'en `camelCase` : ce sont des identifiants
  stables partagés entre Dart et JSON, le snake_case est plus naturel en JSON
  et évite la confusion avec les noms de variables Dart.
