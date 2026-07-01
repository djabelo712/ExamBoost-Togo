# i18n FR/EN — ExamBoost Togo

Ce dossier contient les traductions FR/EN de l'application Flutter ExamBoost Togo.
Le programme DJANTA Tech Hub étant bilingue (CcHub est nigérian), l'app doit pouvoir
switcher entre français (par défaut, langue principale des élèves togolais) et anglais.

## Contenu du dossier

| Fichier | Rôle |
|---|---|
| `app_fr.arb` | Traductions françaises (locale par défaut) — 165 chaînes |
| `app_en.arb` | Traductions anglaises — 165 chaînes (parité parfaite avec FR) |
| `README.md` | Ce fichier — guide d'activation |
| `l10n_config.md` | Configuration `l10n.yaml` + `pubspec.yaml` + `MaterialApp` |

## Étapes d'activation (à réaliser par l'agent principal lors du wiring final)

### 1. Ajouter les dépendances dans `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations: # <-- ajouter
    sdk: flutter           # <-- ajouter
  intl: any                # <-- ajouter (requis par AppLocalizations)
```

Et dans la section `flutter:` tout en bas du `pubspec.yaml` :

```yaml
flutter:
  generate: true          # <-- active la génération automatique
  uses-material-design: true
  assets:
    - assets/data/questions.json
    # ...
```

### 2. Créer le fichier `l10n.yaml` à la racine du projet

Voir `l10n_config.md` pour le contenu exact. Ce fichier indique à Flutter
où trouver les `.arb` et quel package utiliser pour la génération.

### 3. Générer les fichiers Dart `AppLocalizations`

Deux options :

- **Automatique** (recommandée) : si `generate: true` est dans `pubspec.yaml`,
  la commande `flutter pub get` ou `flutter run` régénère les fichiers à chaque
  modification des `.arb`. Les fichiers générés vont dans
  `.dart_tool/flutter_gen/gen_l10n/` (ne pas committer).

- **Manuelle** : lancer la commande
  ```bash
  flutter gen-l10n
  ```
  depuis la racine du projet. Cela crée les fichiers dans
  `lib/l10n/` à côté des `.arb` (ou ailleurs selon la config `output-dir`
  du `l10n.yaml`).

### 4. Brancher `MaterialApp.router` (dans `lib/main.dart`)

```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// OU si output-dir personnalisé :
// import 'l10n/app_localizations.dart';

class ExamBoostApp extends StatelessWidget {
  const ExamBoostApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ExamBoost Togo', // titre natif (Android recents)
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: AppRouter.router,
      // ─── i18n ───────────────────────────────────────────────
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // locale: Locale('fr'),  // fige la locale (utile en démo)
      // ou dynamique via un LocaleProvider (voir §5)
    );
  }
}
```

### 5. Switcher de langue au runtime (optionnel)

Ajouter un `LocaleProvider` (ChangeNotifier) pour basculer FR/EN depuis
les réglages :

```dart
class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('fr');
  Locale get locale => _locale;

  void setLocale(Locale newLocale) {
    if (_locale == newLocale) return;
    _locale = newLocale;
    notifyListeners();
  }

  void toggleFrEn() {
    setLocale(_locale.languageCode == 'fr' ? const Locale('en') : const Locale('fr'));
  }
}
```

Dans `main.dart` :

```dart
return MultiProvider(
  providers: [
    // ... providers existants
    ChangeNotifierProvider<LocaleProvider>(create: (_) => LocaleProvider()),
  ],
  child: Consumer<LocaleProvider>(
    builder: (context, localeProvider, _) => MaterialApp.router(
      // ... config existante
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: localeProvider.locale,
    ),
  ),
);
```

Et dans n'importe quel widget :

```dart
final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
localeProvider.toggleFrEn();
```

## Utiliser les traductions dans un widget

```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Column(
        children: [
          Text(l10n.appTitle),
          Text(l10n.welcomeGreeting('Kofi')),           // "Bonjour, Kofi !"
          Text(l10n.homeWhatDoYouWant),
          Text(l10n.simulationQuestion(5, 20)),         // "Question 5 / 20"
          Text(l10n.dashboardBasedOnXSkills(12)),       // "Basé sur 12 compétences suivies"
        ],
      ),
    );
  }
}
```

### Règles de nommage des clés

- Préfixe par écran : `home*`, `onboarding*`, `revision*`, `simulation*`, `dashboard*`.
- Préfixe transverse : `common*` (boutons génériques), `subject*` (matières),
  `niveau*` (niveaux scolaires).
- CamelCase : `homeRevisionAdaptiveSubtitle`.
- Métadonnée : clé préfixée `@` pour la `description` et les `placeholders`.

### Placeholders ICU

Les chaînes avec variables utilisent la syntaxe `{name}` dans l'ARB, et
déclarent le type dans `@key.placeholders` :

```json
"welcomeGreeting": "Bonjour, {name} !",
"@welcomeGreeting": {
  "placeholders": {
    "name": {"type": "String"}
  }
}
```

Le générateur produit alors `String welcomeGreeting(String name)`.
Types supportés : `String`, `int`, `double`, `num`, `DateTime`.

## Inventaire des chaînes

165 clés de traduction réparties ainsi (parités FR/EN parfaites) :

| Préfixe | Nombre | Description |
|---|---|---|
| `appTitle`, `welcome*` | 3 | Titre app + salutations (avec/sans niveau) |
| `home*` | 15 | Écran Home + dialog profil (8 champs profil) |
| `onboarding*` | 39 | 5 étapes : bienvenue, identité, niveau, série, matières |
| `revision*` | 22 | Écran Révision + fin de session + dialog quitter |
| `simulation*` | 45 | Config + examen en cours + rapport + corrections |
| `dashboard*` | 19 | 7 sections : score, matières, chapitres, SRS, activité, actions |
| `common*` | 10 | Boutons et messages génériques (Loading, Retry, Cancel...) |
| `subject*` | 8 | Noms de matières (Maths, FR, Sciences Physiques, SVT...) |
| `niveau*` | 4 | Niveaux scolaires abrégés (3e, 2nde, 1ère, Term) |

Total : 3 + 15 + 39 + 22 + 45 + 19 + 10 + 8 + 4 = 165 clés.

## Notes importantes

- Le **wiring réel** dans les écrans (`Text(l10n.homeWhatDoYouWant)` au lieu de
  `Text('Que veux-tu faire ?')`) sera fait par l'agent principal lors du wiring
  final — ne PAS modifier les écrans existants depuis ce dossier.
- Les `.arb` sont du JSON valide, vérifiable avec
  `python3 -c "import json; json.load(open('app_fr.arb'))"`.
- Le français est la locale par défaut (langue maternelle des élèves togolais).
  L'anglais sert pour le pitch CcHub et pour les éventuels élèves anglophones
  de la CEDEAO.
- Aucune chaîne codée en dur ne devrait subsister dans les écrans après le
  wiring. L'agent principal peut faire un grep `Text('` dans `lib/screens/`
  pour traquer les chaînes non traduites.
