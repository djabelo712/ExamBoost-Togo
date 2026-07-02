// lib/utils/keyboard_shortcuts.dart
// Raccourcis clavier globaux via Shortcuts + Actions (Flutter desktop/web).
//
// Conformité WCAG 2.1 :
//   - SC 2.1.1 Keyboard (Level A) : toutes les fonctionnalités doivent être
//     accessibles au clavier.
//   - SC 2.1.2 No Keyboard Trap (Level A) : on peut sortir d'un composant
//     avec ESC ou Tab.
//   - SC 2.4.1 Bypass Blocks (Level A) : raccourcis pour aller directement
//     au contenu principal.
//
// Trois familles de raccourcis :
//   1. Navigation principale (chiffres 1-9) : 1=Accueil, 2=Révision,
//      3=Simulation, 4=Dashboard, 5=Recherche, 6=Favoris, 7=Stats,
//      8=Profil, 9=Paramètres.
//   2. Actions contextuelles : Tab (suivant), Shift+Tab (précédent),
//      Enter/Space (activer), Escape (fermer dialog/sheet).
//   3. Navigation dans les listes : Flèches haut/bas/gauche/droite.
//
// Architecture :
//   - Intents : classes décrivant l'intention utilisateur (HomeIntent,
//     CloseIntent, etc.). Sans logique.
//   - Actions : CallbackAction<Intent> qui délègue à un callback fourni
//     par l'écran appelant.
//   - Shortcuts : mappe une touche (SingleActivator) à un Intent.
//   - [AppKeyboardShortcuts] : widget pré-construit avec les 9 raccourcis
//     numériques + Escape, à wrapper en haut de MaterialApp.
//
// Utilisation :
//   MaterialApp(
//     builder: (context, child) => AppKeyboardShortcuts(
//       onNumericShortcut: (index) {
//         // index 0-8 pour chiffres 1-9
//         switch (index) {
//           case 0: _navigateToHome(); break;
//           case 1: _navigateToRevision(); break;
//           ...
//         }
//       },
//       onClose: () => Navigator.of(rootContext).pop(),
//       child: child!,
//     ),
//     home: HomeScreen(),
//   )
//
// Référence :
//   https://docs.flutter.dev/ui/interactivity/actions-and-shortcuts

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── Intents ──────────────────────────────────────────────────

/// Intent : aller à l'écran d'accueil (raccourci : chiffre 1).
class HomeIntent extends Intent {
  const HomeIntent();
}

/// Intent : aller à l'écran de révision (raccourci : chiffre 2).
class RevisionIntent extends Intent {
  const RevisionIntent();
}

/// Intent : démarrer une simulation (raccourci : chiffre 3).
class SimulationIntent extends Intent {
  const SimulationIntent();
}

/// Intent : aller au tableau de bord (raccourci : chiffre 4).
class DashboardIntent extends Intent {
  const DashboardIntent();
}

/// Intent : ouvrir la recherche (raccourci : chiffre 5).
class SearchIntent extends Intent {
  const SearchIntent();
}

/// Intent : ouvrir les favoris (raccourci : chiffre 6).
class FavoritesIntent extends Intent {
  const FavoritesIntent();
}

/// Intent : ouvrir les statistiques (raccourci : chiffre 7).
class StatsIntent extends Intent {
  const StatsIntent();
}

/// Intent : ouvrir le profil (raccourci : chiffre 8).
class ProfileIntent extends Intent {
  const ProfileIntent();
}

/// Intent : ouvrir les paramètres (raccourci : chiffre 9).
class SettingsIntent extends Intent {
  const SettingsIntent();
}

/// Intent générique : raccourci numérique 1-9 (index 0-8).
/// Utilisé par [AppKeyboardShortcuts] pour centraliser le dispatch.
class NumericShortcutIntent extends Intent {
  const NumericShortcutIntent(this.index);
  final int index;
}

/// Intent : fermer la dialog/sheet/menu courant (raccourci : Escape).
class CloseIntent extends Intent {
  const CloseIntent();
}

/// Intent : activer l'élément focusé (raccourci : Enter ou Space).
class ActivateIntent extends Intent {
  const ActivateIntent();
}

/// Intent : passer à l'élément suivant dans une liste (raccourci : Flèche bas).
class NextItemIntent extends Intent {
  const NextItemIntent();
}

/// Intent : passer à l'élément précédent dans une liste (raccourci : Flèche haut).
class PreviousItemIntent extends Intent {
  const PreviousItemIntent();
}

/// Intent : passer à la question suivante (raccourci : Flèche droite).
class NextQuestionIntent extends Intent {
  const NextQuestionIntent();
}

/// Intent : passer à la question précédente (raccourci : Flèche gauche).
class PreviousQuestionIntent extends Intent {
  const PreviousQuestionIntent();
}

// ─── Catalogue des raccourcis clavier ─────────────────────────

/// Catalogue central des raccourcis clavier ExamBoost.
///
/// Exposé publiquement pour permettre aux écrans de définir leurs propres
/// Shortcuts+Actions sans réécrire les SingleActivator.
class AppShortcuts {
  AppShortcuts._();

  /// Mappe les touches aux intents pour la navigation principale (chiffres
  /// 1-9) + actions globales (Escape, Enter, Space, flèches).
  ///
  /// À passer à `Shortcuts(shortcuts: AppShortcuts.defaultShortcuts, ...)`.
  static const Map<ShortcutActivator, Intent> defaultShortcuts =
      <ShortcutActivator, Intent>{
    // Chiffres 1-9 : navigation principale
    SingleActivator(LogicalKeyboardKey.digit1): NumericShortcutIntent(0),
    SingleActivator(LogicalKeyboardKey.digit2): NumericShortcutIntent(1),
    SingleActivator(LogicalKeyboardKey.digit3): NumericShortcutIntent(2),
    SingleActivator(LogicalKeyboardKey.digit4): NumericShortcutIntent(3),
    SingleActivator(LogicalKeyboardKey.digit5): NumericShortcutIntent(4),
    SingleActivator(LogicalKeyboardKey.digit6): NumericShortcutIntent(5),
    SingleActivator(LogicalKeyboardKey.digit7): NumericShortcutIntent(6),
    SingleActivator(LogicalKeyboardKey.digit8): NumericShortcutIntent(7),
    SingleActivator(LogicalKeyboardKey.digit9): NumericShortcutIntent(8),
    // Pavé numérique 1-9 : mêmes raccourcis
    SingleActivator(LogicalKeyboardKey.numpad1): NumericShortcutIntent(0),
    SingleActivator(LogicalKeyboardKey.numpad2): NumericShortcutIntent(1),
    SingleActivator(LogicalKeyboardKey.numpad3): NumericShortcutIntent(2),
    SingleActivator(LogicalKeyboardKey.numpad4): NumericShortcutIntent(3),
    SingleActivator(LogicalKeyboardKey.numpad5): NumericShortcutIntent(4),
    SingleActivator(LogicalKeyboardKey.numpad6): NumericShortcutIntent(5),
    SingleActivator(LogicalKeyboardKey.numpad7): NumericShortcutIntent(6),
    SingleActivator(LogicalKeyboardKey.numpad8): NumericShortcutIntent(7),
    SingleActivator(LogicalKeyboardKey.numpad9): NumericShortcutIntent(8),
    // Escape : fermer dialog/sheet
    SingleActivator(LogicalKeyboardKey.escape): CloseIntent(),
    // Enter / Space : activer l'élément focusé
    SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
    // Flèches : navigation dans les listes / questions
    SingleActivator(LogicalKeyboardKey.arrowDown): NextItemIntent(),
    SingleActivator(LogicalKeyboardKey.arrowUp): PreviousItemIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight): NextQuestionIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft): PreviousQuestionIntent(),
  };

  /// Labels humains pour les raccourcis (affichables dans une aide F1).
  static const Map<Type, String> humanReadable = <Type, String>{
    NumericShortcutIntent: 'Chiffre 1-9 : naviguer entre les écrans',
    CloseIntent: 'Échap : fermer la boîte de dialogue',
    ActivateIntent: 'Entrée / Espace : activer l\'élément focus',
    NextItemIntent: 'Flèche bas : élément suivant',
    PreviousItemIntent: 'Flèche haut : élément précédent',
    NextQuestionIntent: 'Flèche droite : question suivante',
    PreviousQuestionIntent: 'Flèche gauche : question précédente',
  };

  /// Libellés des 9 raccourcis numériques (index 0 = chiffre 1 = Accueil).
  static const List<String> numericLabels = <String>[
    '1 : Accueil',
    '2 : Révision',
    '3 : Simulation',
    '4 : Tableau de bord',
    '5 : Recherche',
    '6 : Favoris',
    '7 : Statistiques',
    '8 : Profil',
    '9 : Paramètres',
  ];
}

// ─── Widgets helpers ──────────────────────────────────────────

/// Widget pré-construit qui wrappe l'enfant avec les raccourcis clavier
/// globaux (chiffres 1-9 + Escape + Enter/Space + flèches).
///
/// À placer en haut de l'arbre (via `MaterialApp.builder` ou en wrap du
/// `MaterialApp` lui-même) pour activer les raccourcis sur tous les écrans.
///
/// Les callbacks [onNumericShortcut], [onClose], [onActivate],
/// [onNextItem], [onPreviousItem], [onNextQuestion], [onPreviousQuestion]
/// sont optionnels : si null, le raccourci est ignoré (pas d'erreur).
///
/// Exemple :
///   AppKeyboardShortcuts(
///     onNumericShortcut: (i) => _navigateToTabIndex(i),
///     onClose: () => Navigator.of(context).pop(),
///     child: HomeScreen(),
///   )
class AppKeyboardShortcuts extends StatelessWidget {
  final Widget child;

  /// Callback pour les raccourcis numériques (index 0-8 pour chiffres 1-9).
  /// L'appelant est responsable de la navigation (ex : go_router.go).
  final void Function(int index)? onNumericShortcut;

  /// Callback pour Escape (fermer dialog/sheet/menu).
  final VoidCallback? onClose;

  /// Callback pour Enter/Space (activer l'élément focusé).
  /// Par défaut, délègue à `Actions.invoke(context, ActivateIntent())`
  /// qui active l'élément actuellement focusé. Ne surcharger que pour
  /// logique custom.
  final VoidCallback? onActivate;

  /// Callback pour Flèche bas (élément suivant dans une liste).
  final VoidCallback? onNextItem;

  /// Callback pour Flèche haut (élément précédent dans une liste).
  final VoidCallback? onPreviousItem;

  /// Callback pour Flèche droite (question suivante).
  final VoidCallback? onNextQuestion;

  /// Callback pour Flèche gauche (question précédente).
  final VoidCallback? onPreviousQuestion;

  /// Si true (defaut), le widget wrappe l'enfant dans un Focus autofocussé
  /// pour capter les frappes dès le démarrage.
  final bool autofocus;

  const AppKeyboardShortcuts({
    super.key,
    required this.child,
    this.onNumericShortcut,
    this.onClose,
    this.onActivate,
    this.onNextItem,
    this.onPreviousItem,
    this.onNextQuestion,
    this.onPreviousQuestion,
    this.autofocus = true,
  });

  @override
  Widget build(BuildContext context) {
    final actions = <Type, Action<Intent>>{
      if (onNumericShortcut != null)
        NumericShortcutIntent: CallbackAction<NumericShortcutIntent>(
          onInvoke: (intent) => onNumericShortcut!(intent.index),
        ),
      if (onClose != null)
        CloseIntent: CallbackAction<CloseIntent>(
          onInvoke: (_) => onClose!(),
        ),
      if (onActivate != null)
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) => onActivate!(),
        ),
      if (onNextItem != null)
        NextItemIntent: CallbackAction<NextItemIntent>(
          onInvoke: (_) => onNextItem!(),
        ),
      if (onPreviousItem != null)
        PreviousItemIntent: CallbackAction<PreviousItemIntent>(
          onInvoke: (_) => onPreviousItem!(),
        ),
      if (onNextQuestion != null)
        NextQuestionIntent: CallbackAction<NextQuestionIntent>(
          onInvoke: (_) => onNextQuestion!(),
        ),
      if (onPreviousQuestion != null)
        PreviousQuestionIntent: CallbackAction<PreviousQuestionIntent>(
          onInvoke: (_) => onPreviousQuestion!(),
        ),
    };

    // Si aucun callback n'est défini, on ne wrappe pas (évite l'overhead).
    if (actions.isEmpty) return child;

    return Shortcuts(
      shortcuts: AppShortcuts.defaultShortcuts,
      child: Actions(
        actions: actions,
        child: Focus(
          autofocus: autofocus,
          child: child,
        ),
      ),
    );
  }
}

/// Widget de commodité pour définir des raccourcis clavier LOCAUX à un
/// écran (ex : raccourcis spécifiques à l'écran de simulation).
///
/// Contrairement à [AppKeyboardShortcuts] (global), ce widget accepte une
/// map `shortcuts` et une map `actions` personnalisées.
///
/// Exemple :
///   LocalKeyboardShortcuts(
///     shortcuts: {
///       const SingleActivator(LogicalKeyboardKey.keyS, control: true):
///           const SaveIntent(),
///     },
///     actions: {
///       SaveIntent: CallbackAction<SaveIntent>(
///         onInvoke: (_) => _saveDraft(),
///       ),
///     },
///     child: ExamEditor(),
///   )
class LocalKeyboardShortcuts extends StatelessWidget {
  /// Mappe touche -> Intent (locale à cet écran).
  final Map<ShortcutActivator, Intent> shortcuts;

  /// Mappe Type d'Intent -> Action (locale à cet écran).
  final Map<Type, Action<Intent>> actions;

  /// Enfant.
  final Widget child;

  /// Si true (defaut), autofocus sur le focus node interne.
  final bool autofocus;

  const LocalKeyboardShortcuts({
    super.key,
    required this.shortcuts,
    required this.actions,
    required this.child,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(
        actions: actions,
        child: Focus(
          autofocus: autofocus,
          child: child,
        ),
      ),
    );
  }
}

/// Widget qui ajoute un écouteur clavier pour Escape seulement, destiné à
/// fermer les dialogs/sheets/menus. À wrapper autour du contenu d'un Dialog
/// ou d'un BottomSheet.
///
/// Plus léger que [AppKeyboardShortcuts] quand on n'a besoin que de Escape.
///
/// Exemple :
///   showDialog(
///     context: context,
///     builder: (_) => EscapeCloseHandler(
///       onClose: () => Navigator.of(context).pop(),
///       child: MyDialog(),
///     ),
///   );
///
/// Implémente [StatefulWidget] pour gérer proprement un [FocusNode] interne
/// (évite la fuite mémoire d'un FocusNode créé à chaque build).
class EscapeCloseHandler extends StatefulWidget {
  final Widget child;
  final VoidCallback onClose;

  const EscapeCloseHandler({
    super.key,
    required this.child,
    required this.onClose,
  });

  @override
  State<EscapeCloseHandler> createState() => _EscapeCloseHandlerState();
}

class _EscapeCloseHandlerState extends State<EscapeCloseHandler> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          widget.onClose();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: widget.child,
    );
  }
}

/// Helper : active l'élément actuellement focusé par programmation
/// (équivalent clavier Enter). Utile pour les tests d'intégration.
///
/// Exemple :
///   await tester.tap(find.byType(MyButton));
///   // equivalent a
///   KeyboardActions.activate(tester.element(find.byType(MyButton)));
class KeyboardActions {
  KeyboardActions._();

  /// Invoque ActivateIntent sur le contexte donné (active l'élément focusé).
  static void activate(BuildContext context) {
    Actions.invoke(context, const ActivateIntent());
  }

  /// Invoque CloseIntent (ferme la dialog/sheet courant).
  static void close(BuildContext context) {
    Actions.invoke(context, const CloseIntent());
  }

  /// Invoque NextItemIntent (élément suivant).
  static void nextItem(BuildContext context) {
    Actions.invoke(context, const NextItemIntent());
  }

  /// Invoque PreviousItemIntent (élément précédent).
  static void previousItem(BuildContext context) {
    Actions.invoke(context, const PreviousItemIntent());
  }
}
