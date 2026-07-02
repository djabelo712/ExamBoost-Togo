# i18n FR/EN — ExamBoost Togo

Ce dossier contient les traductions FR/EN de l'application Flutter ExamBoost Togo.
Le programme DJANTA Tech Hub étant bilingue (CcHub est nigérian), l'app doit pouvoir
switcher entre français (par défaut, langue principale des élèves togolais) et anglais.

## Contenu du dossier

| Fichier | Rôle |
|---|---|
| `app_fr.arb` | Traductions françaises (locale par défaut) — 300 chaînes |
| `app_en.arb` | Traductions anglaises — 300 chaînes (parité parfaite avec FR) |
| `app_ee.arb` | Traductions ewe — 300 chaînes (langues togolaises, sud Togo) |
| `app_kab.arb` | Traductions kabyè — 300 chaînes (langues togolaises, nord Togo) |
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

---

## Langues togolaises (Ewe + Kabyè)

### Objectif : inclusion des élèves des zones rurales

Le français reste la langue d'enseignement officielle au Togo, mais une part
importante des élèves des zones rurales (surtout au nord et dans les
préfectures éloignées de Lomé) sont plus à l'aise dans leur langue maternelle.
L'inclusion de l'Ewe (sud) et du Kabyè (nord) vise à :

- Réduire la **barrière linguistique** lors de l'onboarding et la prise en main
  de l'app par des élèves dont le français est une langue seconde.
- Renforcer la **pertinence culturelle** du produit pour les élèves togolais
  (meilleure identification à l'app, sentiment de "c'est fait pour moi").
- Appuyer le **pitch DJANTA / CcHub** sur l'inclusion numérique et la
  décolonisation des outils éducatifs en Afrique francophone.
- Préparer une future extension à d'autres langues nationales togolaises.

### Couverture

| Locale | Code ISO | Langue | Région principale | Nombre de locuteurs (Togo) |
|---|---|---|---|---|
| `ee` | `ee` | Ewe | Maritime + Plateaux (sud) | ~1,5 million |
| `kab` | `kab` | Kabyè (Cabrais) | Kara + Centrale (nord) | ~1 million |

Les deux fichiers `app_ee.arb` et `app_kab.arb` contiennent **300 chaînes
chacun** (parité parfaite avec `app_fr.arb` et `app_en.arb`). Les métadonnées
`@key` (description + placeholders) sont conservées à l'identique du fichier
template `app_fr.arb`.

### Limites importantes — à valider avec locuteurs natifs

Les traductions ont été produites par l'Agent BZ (LLM) à partir de
connaissances linguistiques générales sur l'Ewe et le Kabyè. Elles sont
**non validées** par des locuteurs natifs. Avant tout déploiement en production
ou test sur le terrain, il est impératif de :

1. Faire valider les deux fichiers `.arb` par **au moins un locuteur natif
   de chaque langue** (Ewe : locuteur du sud, idéalement de Lomé ou Aného ;
   Kabyè : locuteur du nord, idéalement de Kara ou Sokodé).
2. Vérifier l'**orthographe des caractères spéciaux** : Ewe utilise les
   caractères `Ɛ ɛ Ɔ ɔ Ɖ ɖ Ƒ ƒ Ɣ ɣ Ŋ ŋ Ʋ ʋ` ; Kabyè utilise `Ɛ ɛ Ɩ ɩ Ɔ ɔ Ʋ ʊ`.
3. Tester le **rendu typographique** dans l'app (police Flutter Roboto peut ne
   pas couvrir tous les caractères — prévoir une police de secours comme
   NotoSans pour ces locales).
4. Valider la **cohérence terminologique** des concepts pédagogiques
   (BEPC, BAC, série, matière, compétence) — certains sont conservés en
   français par convention scolaire togolaise et ne doivent pas être traduits
   littéralement.

Chaque fichier `.arb` contient une métadonnée `@@translatorNotes` qui
documente ces limites et signale les chaînes approximatives avec un marqueur
`// TODO: validate with native speaker`.

### Stratégie de bascule de langue au runtime

L'utilisateur peut choisir sa langue depuis `SettingsScreen` → section
`settingsLangueTitle`. Le `LocaleProvider` (décrit plus haut) doit être étendu
pour supporter les 4 locales :

```dart
class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('fr');
  Locale get locale => _locale;

  void setLocale(Locale newLocale) {
    if (_locale == newLocale) return;
    // Supported: fr, en, ee, kab
    final supported = const ['fr', 'en', 'ee', 'kab'];
    if (!supported.contains(newLocale.languageCode)) return;
    _locale = newLocale;
    notifyListeners();
  }
}
```

Le fichier `l10n.yaml` à la racine déclare `preferred-supported-locales: [fr, en, ee, kab]`
pour que Flutter génère automatiquement les 4 `AppLocalizations` delegates.

### Stratégie de fallback

Flutter gère automatiquement le fallback : si une clé manque dans la locale
active (par exemple `ee`), il récupère la valeur de la locale template
(`app_fr.arb`). Les 4 fichiers ayant une **parité parfaite de 300 clés**,
ce cas ne devrait pas se produire en production, mais le mécanisme protège
contre les régressions futures (clé ajoutée en FR mais oubliée en EE/KAB).

### Expansion future (hors scope de cette vague)

Les langues nationales togolaises suivantes pourraient être ajoutées dans des
vagues ultérieures, en fonction du terrain et des enquêtes utilisateurs :

| Langue | Code ISO | Région | Locuteurs (Togo) | Priorité |
|---|---|---|---|---|
| Tem (Temba) | `kdh` | Centrale (Sokodé, Tchamba) | ~300 000 | Haute (3ème langue nationale) |
| Mina (Gen) | `gej` | Maritime (Lomé, Aného) | ~400 000 | Moyenne (zones côtières) |
| Gourma (Gurma) | `gux` | Plateaux (Niamtougou, Mango) | ~200 000 | Basse (zones rurales isolées) |
| Watchi | `wci` | Plateaux (Vogan, Anfoin) | ~100 000 | Basse |
| Moba | `mfq` | Savanes (Dapaong, Mango) | ~300 000 | Moyenne (nord extrême) |

L'ajout d'une nouvelle langue suit ce protocole :

1. Copier `app_fr.arb` → `app_<code>.arb` et changer `@@locale`.
2. Traduire les 300 valeurs (idempotent : on peut le faire en plusieurs passes).
3. Ajouter le code dans `preferred-supported-locales` du `l10n.yaml`.
4. Ajouter un bouton dans `SettingsScreen` pour la nouvelle langue.
5. Faire valider par un locuteur natif avant merge.

### Exemples de traductions

| Clé | FR | EE (Ewe) | KAB (Kabyè) |
|---|---|---|---|
| `welcomeGreeting` | Bonjour, {name} ! | Ŋdi, {name}! | Pɛɛrɛ, {name}! |
| `homeWhatDoYouWant` | Que veux-tu faire ? | Nùka gbɔna wò dzi? | Wɛɛ nʊʊ kɩpɔkɔ? |
| `homeRevisionAdaptive` | Révision Adaptative | Xexexe me ƒe nɔnɔme | Pɩsɩyɛ kʊnʊŋ |
| `revisionEasy` | Facile | Bɔbɔe | Lɛɛtʊ |
| `revisionHard` | Difficile | Dzɔe | Cɩcɩm |
| `commonLoading` | Chargement... | Wole wɔm... | Kɩtɩ-yɛ... |
| `commonCancel` | Annuler | Tsi tre | Hɩɩ-yɛ |
| `commonYes` | Oui | Ɛ | Ɛɛɛ |
| `commonNo` | Non | Ao | Aoo |

