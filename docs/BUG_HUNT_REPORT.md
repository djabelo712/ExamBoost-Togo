# Bug Hunt Report v2 — ExamBoost Togo (Session 4, Vague 2)

**Task ID** : BE-bug-hunt-v2
**Agent** : Agent BE2 (general-purpose)
**Date** : Session 4 — Vague 2
**Périmètre** : `lib/services/`, `lib/models/`, `lib/widgets/` (sauf `question_card.dart` et `srs_buttons.dart`)
**Pré-requis** : Ce rapport fait suite au rapport BE-bug-hunt-fix (Agent BE) qui avait corrigé 5 bugs (AppLogger.warning, import SrsStats, conflits typeId 7 et 8, inventaire typeId). Cette 2e passe se concentre sur les bugs résiduels non couverts par le 1er audit.

---

## Méthodologie

Le SDK Flutter n'étant pas installé dans le sandbox, l'audit a été réalisé manuellement :

1. **Lecture intégrale** des 15 fichiers services + 13 fichiers models + ~40 fichiers widgets du périmètre.
2. **Recherche par pattern** via ripgrep :
   - `CardTheme(` (déprécié Flutter 3.27+) → 0 occurrence
   - `tooltipBgColor` (déprécié fl_chart 0.65+) → 0 occurrence
   - `FlatButton|RaisedButton|OutlineButton` (dépréciés) → 0 occurrence
   - `AppLogger.warning` (méthode inexistante) → 0 occurrence (déjà corrigé par BE v1)
   - `withOpacity(` → ~50 occurrences (warning non bloquant, hors périmètre — Agent BC)
   - `@HiveType(typeId:` → 21 déclarations, **aucun conflit** (vérifié manuellement)
   - `as num?` → 30+ occurrences, toutes suivies de `?.toInt()` ou `?.toDouble()` (défensif correct)
   - `TODO|FIXME|XXX|HACK` → 1 occurrence (TODO BE v1 dans `sync_action.dart`, attendu)
3. **Lecture ciblée** des widgets peu audités par BE v1 :
   - `widgets/exam/*` (6 fichiers)
   - `widgets/animations/*` (10 fichiers)
   - `widgets/states/*` (16 fichiers incluant sous-dossiers `empty_states/`, `error_states/`, `skeletons/`)
   - `widgets/math/*` (4 fichiers)
   - `widgets/figures/*` (2 fichiers)
   - `widgets/audio_player_bar.dart`, `widgets/audio_player_button.dart`
   - `widgets/sync_indicator.dart`, `widgets/sync_status_banner.dart`
   - `widgets/tts_settings_widget.dart`, `widgets/notification_permission_dialog.dart`
4. **Vérification variables non utilisées** : identification de 2 champs privés jamais lus et 3 imports inutilisés.

---

## Bugs trouvés

### 1. Imports inutilisés dans `scratch_sheet_widget.dart` (warnings analyzer)

- **Fichier** : `lib/widgets/exam/scratch_sheet_widget.dart`
- **Lignes** : 20, 21, 23 (avant correctif)
- **Description** : Trois imports étaient déclarés mais aucun symbole associé n'était référencé dans le corps du fichier :
  - `import 'dart:ui' as ui;` — la référence `ui.` n'apparaît nulle part (le `Paint`, `Canvas`, `Path` utilisés proviennent de `flutter/material.dart` qui les ré-exporte).
  - `import 'package:flutter/foundation.dart' show kIsWeb;` — `kIsWeb` n'est jamais utilisé (la logique desktop/web n'est pas branchée dans ce widget).
  - `import 'package:flutter/services.dart';` — aucune utilisation de `HapticFeedback`, `SystemSound`, `Clipboard`, `MethodChannel`, etc.
- **Sévérité** : FAIBLE (warnings analyzer `unused_import`, non bloquant)
- **Statut** : CORRIGÉ (suppression des 3 imports + commentaire BE2 expliquant la suppression)

### 2. Variable privée `_isDown` jamais lue dans `bounce_button.dart` (warning analyzer)

- **Fichier** : `lib/widgets/animations/bounce_button.dart`
- **Lignes** : 62 (déclaration), 78 (assignation dans `_onTapDown`), 93 (assignation dans `_reset`)
- **Description** : Le champ `bool _isDown = false;` était mis à jour via `setState(() => _isDown = true/false)` dans deux méthodes (`_onTapDown`, `_reset`) mais n'était **jamais lu** nulle part dans la classe. La logique d'animation (scale + fade) repose entièrement sur `_scaleAnimation.value` via `AnimatedBuilder`, qui se rebuild automatiquement quand `_controller.forward()` / `_controller.reverse()` est appelé. Les `setState` étaient donc superflus (pas de rebuild utile) en plus d'alimenter un champ fantôme.
- **Sévérité** : FAIBLE (warning analyzer `unused_field`, non bloquant ; impact perf mineur : 2 setState inutiles par tap)
- **Statut** : CORRIGÉ (suppression du champ `_isDown` + des 2 `setState` superflus + commentaire BE2)

### 3. Variable privée `_currentLength` jamais lue dans `typewriter_text.dart` (warning analyzer)

- **Fichier** : `lib/widgets/animations/typewriter_text.dart`
- **Lignes** : 61 (déclaration), 76 (assignation dans `_startTyping`)
- **Description** : Le champ `int _currentLength = 0;` était assigné dans `_startTyping` (`_currentLength = i;`) juste avant `_charCount.value = i;`, mais seul `_charCount` (un `ValueNotifier<int>`) est lu par le `ValueListenableBuilder` dans `build()`. `_currentLength` était donc redondant et jamais lu.
- **Sévérité** : FAIBLE (warning analyzer `unused_field`, non bloquant)
- **Statut** : CORRIGÉ (suppression du champ `_currentLength` + de l'assignation superflue + commentaire BE2)

### 4. Dead code dans `sync_status_banner.dart` — `autoDismissOnSuccess` non implémenté (bug fonctionnel)

- **Fichier** : `lib/widgets/sync_status_banner.dart`
- **Lignes** : 53-60 (bloc `if (status == SyncStatus.success && autoDismissOnSuccess)`)
- **Description** : Le widget expose un paramètre `autoDismissOnSuccess` (défaut `true`) qui est censé accélérer l'auto-masquage du bandeau "Synchronisé avec succès" à 3 s (au lieu des 5 s du `SyncService`). Le code actuel contient un `Future.delayed(const Duration(seconds: 3), () { /* Rien à faire */ });` — c'est-à-dire un `Future` fire-and-forget avec un callback vide. Aucun état n'est changé, aucune méthode n'est appelée. Le drapeau `autoDismissOnSuccess` est donc **silencieusement ignoré** à l'exécution.
  Le commentaire du développeur dit "Le SyncService reset deja a idle apres 5s ; on accelere ici" mais l'accélération n'est pas implémentée. Le bandeau reste affiché 5 s dans tous les cas.
- **Sévérité** : MOYEN (bug fonctionnel : flag public documenté mais sans effet, UX incohérente avec la doc)
- **Statut** : NON CORRIGÉ (voir section "Bugs non corrigés" — nécessite décision architecture)

### 5. Paramètre de type `<T>` inutilisé dans `StateWrapper<T>` (warning analyzer)

- **Fichier** : `lib/widgets/states/state_wrapper.dart`
- **Lignes** : 52 (déclaration `class StateWrapper<T> extends StatelessWidget`)
- **Description** : La classe `StateWrapper<T>` déclare un paramètre de type générique `<T>` qui n'est **jamais référencé** dans le corps de la classe (ni dans les types de champs `state`, `loaded`, `loading`, `empty`, `error`, `errorMessage`, `onRetry`, ni dans le constructeur, ni dans `build()`). Le warning analyzer `unused_type_parameter` est déclenché. Le développeur a probablement prévu une extension future (typage du `loaded` ou d'un callback data) qui n'a jamais été implémentée.
- **Sévérité** : FAIBLE (warning analyzer, non bloquant ; API publique inchangée)
- **Statut** : NON CORRIGÉ (voir section "Bugs non corrigeés" — modification API publique, décision architecture)

---

## Bugs NON corrigés (nécessitent décision architecture)

### A. `sync_status_banner.dart` — `autoDismissOnSuccess` non implémenté

- **Pourquoi non corrigé** : L'implémentation correcte nécessiterait d'ajouter une méthode publique `forceIdle()` ou `resetStatus()` au `SyncService` (qui est dans le périmètre BE2) pour permettre au widget de forcer le passage à `SyncStatus.idle` après 3 s. Cette méthode n'existe pas actuellement. Ajouter une telle méthode modifierait l'API publique du `SyncService` et pourrait interagir avec la logique de retry/backoff (`_retryTimer`, `_statusResetTimer`) — ce qui nécessite une décision d'architecture (le `SyncService` doit-il exposer un reset manuel, ou bien le `SyncStatusBanner` doit-il gérer son propre état local masqué ?).
- **Solutions possibles** :
  1. **Option A** (minimale) : supprimer le bloc dead code et le paramètre `autoDismissOnSuccess` (la doc du widget dit "5 s auto-dismiss" par défaut, comportement déjà correct). Décision API : retirer un paramètre public (cassure mineure).
  2. **Option B** (correcte) : ajouter `SyncService.forceResetToIdle()` qui annule `_statusResetTimer` et force `_state = _state.copyWith(status: SyncStatus.idle)` + `notifyListeners()`. Puis appeler cette méthode dans le `Future.delayed(3s)` du banner. Décision API : ajout d'une méthode publique sur `SyncService`.
  3. **Option C** (locale) : le widget gère un état local `_forceHidden` qui masque visuellement le banner après 3 s sans toucher au `SyncService`. Plus isolé mais duplique la logique de timer.
- **Recommandation BE2** : Option A (suppression du flag et du dead code) car le comportement actuel (5 s via `SyncService`) est cohérent et documenté. L'Option B est tentante mais ajoute de la surface API au `SyncService`. L'agent wiring (BA) ou un futur agent "API review" peut trancher.

### B. `state_wrapper.dart` — Paramètre de type `<T>` inutilisé

- **Pourquoi non corrigé** : Supprimer `<T>` modifierait l'API publique du widget. Tout consommateur qui aurait écrit `StateWrapper<MyType>(...)` casserait à la compilation. Bien que le paramètre soit inutilisé aujourd'hui, il peut être intentionnel (extension future prévue). Décision d'architecture : garder `<T>` (avec warning) ou supprimer (avec risque de casser des consommateurs futurs). Comme le projet n'est pas encore en production et qu'un `grep` ne montre aucun consommateur utilisant `<T>` explicitement, la suppression serait sûre — mais elle relève d'une décision "API publique" plutôt que "bug hunt".
- **Recommandation BE2** : Laisser en l'état (warning non bloquant). Un futur agent "code quality" peut décider.

---

## Patterns vérifiés SANS bug détecté

Pour mémoire, les patterns suivants ont été vérifiés et sont corrects dans tout le périmètre audité :

| Pattern | Résultat |
|---|---|
| `CardTheme(` (déprécié Flutter 3.27+) | Aucune occurrence — `CardThemeData` utilisé partout (OK) |
| `tooltipBgColor` (déprécié fl_chart 0.65+) | Aucune occurrence — `getTooltipColor` utilisé (OK) |
| `FlatButton`, `RaisedButton`, `OutlineButton` (dépréciés) | Aucune occurrence (OK) |
| `AppLogger.warning` (méthode inexistante) | Aucune occurrence (déjà corrigé par BE v1) |
| `print(` en code Dart (pas de logging) | Aucune occurrence dans services/models/widgets (OK — README Python n'est pas du Dart) |
| `TODO`/`FIXME`/`XXX`/`HACK` | 1 occurrence (TODO BE v1 dans `sync_action.dart` ligne 180 — attendu, action wiring BA) |
| Conflits `@HiveType(typeId: N)` | Aucun — 21 déclarations uniques (typeIds 0-20, vérifié manuellement) |
| `as num?` sans `?.toInt()` / `?.toDouble()` | Aucun — toutes les 30+ occurrences chainent correctement vers `int` ou `double` (OK) |
| `clamp(0, 100)` retournant `num` au lieu de `double` | Vérifié sur `user.dart:117`, `score_prediction.dart:73,128,187` — tous les receivers sont statiquement `double`, donc `clamp` retourne `double` (OK) |
| Variables locales non utilisées | Aucune détectée dans le périmètre (OK) |
| Méthodes manquantes (appel à une méthode non définie) | Aucune — toutes les méthodes appelées existent (vérifié sur `SrsStats`, `NotificationHistory.markTapped`, `AudioCacheEntry.markAccessed`, `NotificationTemplates.*`, `AppLogger.{info,debug,warn,error}`, `Badges.all/byId/byCategory/levelsOf`, etc.) |
| Imports manquants pour symboles utilisés | Aucun — tous les fichiers importent ce qu'ils utilisent (vérifié particulièrement pour `SrsStats` ré-importé dans `notification_scheduler.dart` après BE v1) |
| `withOpacity()` (déprécié 3.27+ mais supporté) | ~50 occurrences — laissé tel quel (encore supporté, hors périmètre couleurs — Agent BC) |
| `Connectivity().checkConnectivity()` API 6.0+ (retourne `List<ConnectivityResult>`) | Vérifié sur `sync_service.dart` — utilise bien `result.any(...)` et `result.contains(...)` (OK) |

---

## Statistiques

- **Fichiers audités** : ~68 (15 services + 13 models + ~40 widgets du périmètre)
- **Fichiers lus en détail** : ~50 (tous les services, tous les models, la majorité des widgets)
- **Bugs trouvés** : 5
  - 3 FAIBLES (warnings analyzer) — imports inutilisés, variables privées jamais lues
  - 1 MOYEN (bug fonctionnel) — `autoDismissOnSuccess` non implémenté
  - 1 FAIBLE (warning analyzer) — paramètre de type `<T>` inutilisé
- **Bugs corrigés** : 3 (les 3 warnings analyzer `unused_import` / `unused_field`)
- **Bugs non corrigés** : 2 (voir section "Bugs NON corrigés" ci-dessus — 1 bug fonctionnel + 1 warning API publique)

---

## Détail des corrections appliquées

### Correction 1 — Suppression de 3 imports inutilisés dans `scratch_sheet_widget.dart`

**Fichier** : `lib/widgets/exam/scratch_sheet_widget.dart`

```diff
  import 'dart:convert';
- import 'dart:ui' as ui;
- import 'package:flutter/foundation.dart' show kIsWeb;
  import 'package:flutter/material.dart';
- import 'package:flutter/services.dart';
  import 'package:hive/hive.dart';
  import '../../theme/app_theme.dart';
  import '../../utils/app_logger.dart';
+ // Note BE2 : imports precedents 'dart:ui as ui', 'package:flutter/foundation.dart'
+ // (kIsWeb) et 'package:flutter/services.dart' etaient inutilises (aucune
+ // reference a ui., kIsWeb, HapticFeedback, SystemSound, etc. dans le fichier).
+ // Supprimes pour eviter les warnings analyzer 'unused_import'.
```

### Correction 2 — Suppression de `_isDown` dans `bounce_button.dart`

**Fichier** : `lib/widgets/animations/bounce_button.dart`

```diff
  class _BounceButtonState extends State<BounceButton>
      with SingleTickerProviderStateMixin {
    late final AnimationController _controller;
    late final Animation<double> _scaleAnimation;
-   bool _isDown = false;
+   // Note BE2 : l'ancien champ `bool _isDown` etait declare et mis a jour dans
+   // _onTapDown / _reset mais jamais lu. Supprime pour eviter le warning
+   // analyzer 'unused_field' (la logique d'animation repose sur _controller).

    ...

    void _onTapDown(TapDownDetails _) {
      if (widget.onPressed == null) return;
-     setState(() => _isDown = true);
      _controller.duration = widget.downDuration;
      _controller.forward();
    }

    ...

    void _reset() {
-     setState(() => _isDown = false);
      _controller.duration = widget.upDuration;
      // On joue l'animation inverse avec une courbe spring pour l'effet bounce.
      _controller.reverse();
    }
```

### Correction 3 — Suppression de `_currentLength` dans `typewriter_text.dart`

**Fichier** : `lib/widgets/animations/typewriter_text.dart`

```diff
  class _TypewriterTextState extends State<TypewriterText> {
    late final ValueNotifier<int> _charCount;
    late final ValueNotifier<bool> _cursorVisible;
-   int _currentLength = 0;
+   // Note BE2 : l'ancien champ `int _currentLength = 0` etait declare et mis a
+   // jour dans _startTyping mais jamais lu (le rendu utilise _charCount.value).
+   // Supprime pour eviter le warning analyzer 'unused_field'.

    ...

    void _startTyping() async {
      for (int i = 1; i <= widget.text.length; i++) {
        await Future.delayed(widget.speed);
        if (!mounted) return;
-       _currentLength = i;
        _charCount.value = i;
      }
      if (mounted) widget.onComplete?.call();
    }
```

---

## Décisions clés

1. **Périmètre strictement respecté** : seuls les fichiers `lib/services/`, `lib/models/`, `lib/widgets/` (sauf `question_card.dart` et `srs_buttons.dart`) ont été audités et modifiés. Aucun fichier `lib/screens/`, `lib/providers/`, `lib/utils/`, `lib/theme/`, `main.dart`, `app_router.dart`, `pubspec.yaml` n'a été touché.

2. **Pas de toucher aux couleurs / Text()** : les ~50 occurrences de `withOpacity()` et les 4 occurrences de `ColorScheme.surfaceVariant` / `dividerColor` dans `svg_figure.dart` n'ont pas été migrées vers `withValues(alpha:)` / `surfaceContainerHighest` / `outline` car cela relève de l'Agent BC (couleurs). Warnings non bloquants.

3. **Pas de toucher à `question_card.dart` et `srs_buttons.dart`** : ces deux widgets sont explicitement hors périmètre (probablement gérés par d'autres agents BB/BC).

4. **Commentaires FR, pas d'emojis** : les 3 commentaires ajoutés pour expliquer les suppressions sont en français et sans emojis, conformément aux conventions BE.

5. **Conservation du diff minimal** : pour chaque suppression, un commentaire BE2 explique la raison (au cas où un futur développeur se demanderait pourquoi le code a été retiré). Les commentaires sont placés juste après la suppression pour préserver l'historique de la décision.

6. **Choix de NE PAS corriger `autoDismissOnSuccess`** : 3 options possibles (A : suppression du flag, B : ajout d'une méthode `SyncService.forceResetToIdle()`, C : état local au widget). L'option A est la plus propre mais modifie l'API publique du widget. L'option B ajoute de la surface API au service. L'option C duplique la logique de timer. Aucune option n'est clairement gagnante sans décision d'architecture — d'où le statut "non corrigé" avec recommandation.

7. **Choix de NE PAS corriger `StateWrapper<T>`** : supprimer `<T>` est techniquement sûr (aucun consommateur ne l'utilise explicitement, vérifié via `grep`) mais modifie l'API publique. Un warning analyzer `unused_type_parameter` non bloquant ne justifie pas une modification d'API. Laissé en l'état avec recommandation pour un futur agent "code quality".

---

## Recommandations pour les prochains agents

1. **Agent BA (wiring)** : aucune action requise — les correctifs BE2 ne touchent pas au wiring.

2. **Agent BC (dark mode / couleurs)** :
   - Poursuivre la migration `withOpacity(x)` → `withValues(alpha: x)` (~50 occurrences dans `theme/`, `widgets/`, `screens/`).
   - Migrer `ColorScheme.surfaceVariant` → `surfaceContainerHighest` dans `svg_figure.dart` (4 occurrences).
   - Migrer `Theme.dividerColor` → `colorScheme.outline` dans `svg_figure.dart` (1 occurrence).

3. **Agent BB (i18n / Text())** : aucune action requise — les correctifs BE2 ne touchent aucun `Text()`.

4. **Futur agent "API review"** :
   - Décider pour `StateWrapper<T>` : supprimer `<T>` ou le conserver ?
   - Décider pour `SyncStatusBanner.autoDismissOnSuccess` : Option A (suppression) / B (méthode `SyncService.forceResetToIdle()`) / C (état local) ?

5. **Build / CI** : après `flutter pub get`, lancer `dart run build_runner build --delete-conflicting-outputs` pour générer les `*.g.dart` manquants. Les modifications BE2 n'ajoutent pas de nouveaux `@HiveType` donc aucun impact sur la génération.

---

## Conclusion

Le bug hunt v2 a identifié **5 bugs résiduels** dans le périmètre services + models + widgets, tous mineurs (warnings analyzer ou bug fonctionnel d'UI non bloquant). Aucun bug bloquant à la compilation n'a été trouvé — l'audit BE v1 avait déjà corrigé les 2 bugs bloquants (`AppLogger.warning`, import `SrsStats` manquant) et les 2 conflits typeId Hive.

Les **3 bugs corrigés** dans cette passe sont des nettoyages de code (imports inutilisés, variables privées fantômes) qui éliminent 3 warnings analyzer. Les **2 bugs non corrigés** nécessitent une décision d'architecture (API publique) et sont documentés avec 3 options pour chacun.

Le projet devrait compiler sans nouveaux warnings dans le périmètre audité, à condition qu'aucun autre agent n'introduise de régression.
