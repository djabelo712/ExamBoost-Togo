# Configuration flutter_localizations — ExamBoost Togo

Ce document décrit la configuration exacte à mettre en place pour activer
i18n dans le projet Flutter. Les fichiers ARB (`app_fr.arb`, `app_en.arb`)
sont déjà prêts dans `lib/l10n/`.

## 1. Fichier `l10n.yaml` (à la racine du projet)

Créer `/home/z/my-project/ExamBoost-Togo/l10n.yaml` avec ce contenu :

```yaml
arb-dir: lib/l10n
template-arb-file: app_fr.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
preferred-supported-locales: [fr, en]
synthetic-package: true
nullable-getter: true
```

### Explication des champs

| Champ | Valeur | Rôle |
|---|---|---|
| `arb-dir` | `lib/l10n` | Dossier contenant les `.arb` |
| `template-arb-file` | `app_fr.arb` | Fichier de référence (clés + descriptions) |
| `output-localization-file` | `app_localizations.dart` | Nom du fichier Dart généré |
| `output-class` | `AppLocalizations` | Nom de la classe à utiliser dans le code |
| `preferred-supported-locales` | `[fr, en]` | Ordre de fallback des locales |
| `synthetic-package` | `true` | Les fichiers générés vont dans `.dart_tool/flutter_gen/` (non committés) |
| `nullable-getter` | `true` | `AppLocalizations.of(context)` renvoie `AppLocalizations?` (à unwrap avec `!`) |

Si vous préférez que les fichiers générés soient commités dans le repo
(utile pour relire les diffs en code review), utilisez plutôt :

```yaml
arb-dir: lib/l10n
template-arb-file: app_fr.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
output-dir: lib/l10n/generated
synthetic-package: false
preferred-supported-locales: [fr, en]
nullable-getter: true
```

Et ajoutez `lib/l10n/generated/` au versioning (pas au `.gitignore`).

## 2. Modification du `pubspec.yaml`

### Dépendances

Dans la section `dependencies:` :

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: any
  # ... autres deps existantes (go_router, provider, hive, etc.)
```

### Section `flutter:`

Tout en bas du fichier :

```yaml
flutter:
  generate: true                # <-- OBLIGATOIRE pour activer gen-l10n
  uses-material-design: true
  assets:
    - assets/data/questions.json
    - assets/branding/
  # ...
```

Le flag `generate: true` dit à Flutter d'exécuter `flutter gen-l10n`
automatiquement à chaque `flutter run` / `flutter build`.

## 3. Modification du `MaterialApp` (dans `lib/main.dart`)

Le `MaterialApp.router` actuel doit être augmenté de 3 paramètres :

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

// ... imports existants ...

class ExamBoostApp extends StatelessWidget {
  const ExamBoostApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ExamBoost Togo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: AppRouter.router,
      // ─── i18n : 3 lignes à ajouter ──────────────────────────
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'), // figé en FR pour la démo DJANTA
      // ou via un LocaleProvider si switch runtime nécessaire
    );
  }
}
```

### Avec switch runtime (LocaleProvider)

Si l'utilisateur doit pouvoir changer de langue dans les réglages :

```dart
return MultiProvider(
  providers: [
    // ... providers existants
    ChangeNotifierProvider<LocaleProvider>(
      create: (_) => LocaleProvider(),
    ),
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

## 4. Génération et vérification

Après avoir modifié `pubspec.yaml` et créé `l10n.yaml`, lancer :

```bash
cd /home/z/my-project/ExamBoost-Togo
flutter pub get
flutter gen-l10n
```

Le fichier `AppLocalizations` est généré dans :

- `.dart_tool/flutter_gen/gen_l10n/app_localizations.dart` (mode `synthetic-package: true`)
- `lib/l10n/generated/app_localizations.dart` (mode `synthetic-package: false`)

Vérifier que la génération a réussi :

```bash
flutter pub run flutter_gen_gen_l10n  # ou simplement flutter run
```

Si vous avez l'erreur `AppLocalizations not found`, vérifier :

1. `generate: true` est bien dans la section `flutter:` de `pubspec.yaml`
2. Le fichier `l10n.yaml` est à la racine du projet (pas dans `lib/`)
3. `flutter_localizations` est bien dans `dependencies:`
4. L'import `package:flutter_gen/gen_l10n/app_localizations.dart` correspond
   au mode `synthetic-package` choisi

## 5. Validation des fichiers ARB

Les fichiers `.arb` sont du JSON valide. Pour vérifier :

```bash
python3 -c "import json; fr=json.load(open('lib/l10n/app_fr.arb')); en=json.load(open('lib/l10n/app_en.arb')); print(f'FR: {len(fr)} entrées'); print(f'EN: {len(en)} entrées')"
```

Pour vérifier la parité des clés (FR et EN doivent avoir exactement les mêmes) :

```bash
python3 -c "
import json
fr=json.load(open('lib/l10n/app_fr.arb'))
en=json.load(open('lib/l10n/app_en.arb'))
fr_keys={k for k in fr if not k.startswith('@')}
en_keys={k for k in en if not k.startswith('@')}
assert fr_keys == en_keys, f'Parité cassée : missing in EN={fr_keys-en_keys}, missing in FR={en_keys-fr_keys}'
print(f'OK — {len(fr_keys)} clés traduites en FR et EN')
"
```

## 6. Arborescence finale attendue

```
ExamBoost-Togo/
├── l10n.yaml                              <-- à créer (racine)
├── pubspec.yaml                           <-- à modifier (dependencies + generate)
└── lib/
    ├── main.dart                          <-- à modifier (MaterialApp)
    └── l10n/
        ├── README.md                      <-- ce dossier expliqué
        ├── l10n_config.md                 <-- ce fichier
        ├── app_fr.arb                     <-- 165 clés FR
        ├── app_en.arb                     <-- 165 clés EN
        └── generated/                     <-- uniquement si synthetic-package: false
            ├── app_localizations.dart
            ├── app_localizations_fr.dart
            └── app_localizations_en.dart
```

## 7. Notes pratiques

- **Locale par défaut** : français (`fr`), car c'est la langue d'enseignement
  au Togo et la langue maternelle de la majorité des élèves cibles.
- **Locale secondaire** : anglais (`en`), pour le pitch DJANTA (CcHub
  nigérian) et pour les éventuels élèves anglophones de la CEDEAO.
- **Pas d'autres locales** dans l'immédiat (pas d'Éwé, pas de Kabyè) —
  les contenus pédagogiques (questions, explications) restent en français.
- Les fichiers `.arb` ne contiennent **pas d'emojis** (conforme aux règles
  du projet).
- Les placeholders ICU (`{name}`, `{count, plural, ...}`) sont supportés
  mais on reste sur des `{name}` simples dans cette V1.
