// lib/utils/screen_reader_utils.dart
// Helpers pour les lecteurs d'écran (TalkBack Android / VoiceOver iOS /
// NVDA/JAWS desktop / Orca Linux).
//
// Conformité WCAG 2.1 :
//   - SC 4.1.2 Name, Role, Value (Level A)
//   - SC 4.1.3 Status Messages (Level AA) : les changements d'état doivent
//     être annoncés sans perdre le focus.
//   - SC 1.3.1 Info and Relationships (Level A)
//
// Trois familles de helpers :
//   1. Annonces ponctuelles via [SemanticsService.announce] (score mis à
//     jour, badge débloqué, temps écoulé).
//   2. Détection du lecteur d'écran actif (pour désactiver certaines
//     animations ou fournir des alternatives).
//   3. Wrappers sémantiques réutilisables (live region, group, header)
//     déjà définis dans lib/widgets/semantic_labels.dart — ici on fournit
//     des utilitaires sans widget.
//
// Utilisation :
//   // Annoncer un changement d'état
//   ScreenReaderUtils.announceScore(14, 20);
//
//   // Annoncer une navigation
//   ScreenReaderUtils.announce('Question 5 sur 20');
//
//   // Détecter le lecteur d'écran (désactiver les animations décoratives)
//   if (ScreenReaderUtils.isScreenReaderEnabled(context)) {
//     return SkeletonStatic();
//   } else {
//     return ShimmerLoading();
//   }
//
// Référence :
//   https://docs.flutter.dev/ui/semantics
//   https://developer.android.com/guide/topics/ui/accessibility/principles
//   https://developer.apple.com/design/human-interface-guidelines/accessibility

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Utilitaires pour interagir avec les lecteurs d'écran.
///
/// Toutes les méthodes sont statiques et sans état.
class ScreenReaderUtils {
  ScreenReaderUtils._();

  // ─── Annonces (SemanticsService.announce) ─────────────────────

  /// Annonce un message au lecteur d'écran sans déplacer le focus.
  ///
  /// L'annonce est "polite" par défaut (attend la fin de la lecture en
  /// cours). Pour une annonce "assertive" (interrompt la lecture), utiliser
  /// [announceAssertive].
  ///
  /// [direction] : direction de lecture du message (LTR par défaut).
  static void announce(
    String message, {
    TextDirection direction = TextDirection.ltr,
  }) {
    SemanticsService.announce(message, direction);
  }

  /// Annonce "polite" (alias de [announce]).
  static void announcePolite(
    String message, {
    TextDirection direction = TextDirection.ltr,
  }) {
    SemanticsService.announce(message, direction);
  }

  /// Annonce "assertive" : interrompt la lecture en cours.
  ///
  /// Note : Flutter ne supporte pas nativement aria-live="assertive" via
  /// [SemanticsService.announce] (seulement "polite"). Cette méthode utilise
  /// le canal "polite" + une [LiveRegion] à majuscules pour signaler
  /// l'urgence. Pour une assertivité fiable multi-plateforme, entourer
  /// l'élément d'un widget `LiveRegion(assertive: true)` de
  /// lib/widgets/semantic_labels.dart.
  static void announceAssertive(
    String message, {
    TextDirection direction = TextDirection.ltr,
  }) {
    // Préfixe "ALERTE" pour signaler l'urgence aux lecteurs d'écran FR.
    final urgentMessage = message.toUpperCase() == message
        ? 'ALERTE : $message'
        : 'ALERTE. $message';
    SemanticsService.announce(urgentMessage, direction);
  }

  /// Annonce un tooltip (info-bulle) au lecteur d'écran.
  /// À utiliser sur les survols (desktop) ou les appuis longs (mobile).
  static void announceTooltip(String tooltip) {
    SemanticsService.tooltip(tooltip);
  }

  // ─── Annonces pré-formatées (domaine ExamBoost) ───────────────

  /// "Question 5 sur 20".
  static void announceQuestion(int index, int total) {
    announcePolite('Question $index sur $total');
  }

  /// "Question 5 sur 20. Progression 25 pour cent."
  static void announceQuestionWithProgress(int index, int total) {
    final percent = total > 0 ? ((index - 1) / total * 100).round() : 0;
    announcePolite(
      'Question $index sur $total. Progression $percent pour cent.',
    );
  }

  /// "Score mis à jour : 14 sur 20, 70 pour cent."
  static void announceScore(int score, int total) {
    final percent = total > 0 ? (score / total * 100).round() : 0;
    announcePolite(
      'Score mis à jour : $score sur $total, $percent pour cent.',
    );
  }

  /// "Temps restant : 45 minutes 30 secondes."
  static void announceTimeRemaining(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    announcePolite('Temps restant : $minutes minutes $seconds secondes.');
  }

  /// Annonce les alertes de temps (utilisée par le timer d'examen).
  /// [assertive] = true pour les seuils critiques (5 min, 1 min, 0:00).
  static void announceTimeAlert(Duration remaining, {bool critical = false}) {
    final minutes = remaining.inMinutes;
    final message = remaining.isNegative
        ? 'Temps écoulé. L\'examen est terminé.'
        : 'Plus que $minutes minutes.';
    if (critical) {
      announceAssertive(message);
    } else {
      announcePolite(message);
    }
  }

  /// "Badge débloqué : Maître des mathématiques."
  static void announceBadgeUnlocked(String badgeName) {
    announcePolite('Badge débloqué : $badgeName. Félicitations !');
  }

  /// "Niveau 5 atteint."
  static void announceLevelUp(int newLevel) {
    announcePolite('Niveau $newLevel atteint. Félicitations !');
  }

  /// "Bonne réponse." / "Mauvaise réponse. La bonne réponse était : X."
  static void announceAnswerFeedback({
    required bool correct,
    String? correctAnswer,
  }) {
    if (correct) {
      announcePolite('Bonne réponse.');
    } else {
      final suffix =
          correctAnswer != null ? ' La bonne réponse était : $correctAnswer.' : '';
      announcePolite('Mauvaise réponse.$suffix');
    }
  }

  /// "Série de 7 jours."
  static void announceStreak(int days) {
    announcePolite('Série de $days jours. Continue demain pour ne pas la perdre.');
  }

  /// Annonce la navigation vers un nouvel écran (ex : après tap sur
  /// BottomNavigationBar).
  static void announceScreenChange(String screenName) {
    announcePolite('$screenName. Écran $screenName.');
  }

  /// Annonce un changement d'état d'un toggle (switch, checkbox).
  static void announceToggleState(String elementName, bool newValue) {
    final state = newValue ? 'activé' : 'désactivé';
    announcePolite('$elementName $state.');
  }

  // ─── Détection du lecteur d'écran ─────────────────────────────

  /// True si un lecteur d'écran (TalkBack / VoiceOver / NVDA) est
  /// actuellement actif sur le device.
  ///
  /// Utiliser pour :
  ///   - Désactiver les animations décoratives (shimmer, parallax)
  ///   - Désactiver les vidéos auto-play
  ///   - Remplacer les icônes seules par icône + texte
  ///   - Simplifier les layouts complexes
  ///
  /// Note : cette information peut être undefined sur desktop (renvoie
  /// false par défaut). Sur mobile, elle est fiable.
  static bool isScreenReaderEnabled(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    return mediaQuery?.accessibleNavigation ?? false;
  }

  /// True si l'utilisateur navigue au clavier (desktop/web) ou avec un
  /// switch control (mobile).
  ///
  /// Alias de [isScreenReaderEnabled] avec un nom plus générique.
  static bool isAccessibleNavigation(BuildContext context) {
    return isScreenReaderEnabled(context);
  }

  /// True si l'utilisateur a activé les sous-titres (closed captions)
  /// dans les préférences système. Utiliser pour auto-activer les
  /// sous-titres des vidéos.
  static bool isClosedCaptionEnabled(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    return mediaQuery?.closedCaptionEnabled ?? false;
  }

  // ─── Helpers de génération de descriptions ────────────────────

  /// Construit une description complète pour une question d'examen.
  ///
  /// Exemple :
  ///   "Question 5 sur 20. Théorème de Pythagore. Question à choix
  ///    unique. 4 réponses possibles."
  static String buildQuestionDescription({
    required int index,
    required int total,
    required String subject,
    required bool multipleChoice,
    int? optionsCount,
  }) {
    final type = multipleChoice ? 'choix multiple' : 'choix unique';
    final count = optionsCount != null
        ? ' $optionsCount réponses possibles.'
        : '';
    return 'Question $index sur $total. $subject. Question à $type.$count';
  }

  /// Construit une description pour une carte de révision (SRS).
  ///
  /// Exemple :
  ///   "Carte 3 sur 12 : Théorème de Pythagore. Difficulté moyen.
  ///    Dernière révision il y a 4 jours. Prochaine révision demain."
  static String buildFlashcardDescription({
    required int index,
    required int total,
    required String title,
    required String difficulty,
    int? daysSinceLastReview,
    int? daysUntilNextReview,
  }) {
    final last = daysSinceLastReview != null
        ? ' Dernière révision il y a $daysSinceLastReview jour'
        : '';
    final lastPlural = (daysSinceLastReview ?? 0) > 1 ? 's' : '';
    final next = daysUntilNextReview != null
        ? ' Prochaine révision dans $daysUntilNextReview jour'
        : '';
    final nextPlural = (daysUntilNextReview ?? 0) > 1 ? 's' : '';
    return 'Carte $index sur $total : $title. Difficulté $difficulty.'
        '$last$lastPlural.$next$nextPlural.';
  }

  /// Construit une description pour une tuile de statistique.
  ///
  /// Exemple :
  ///   "Taux de réussite : 75 pour cent. En hausse de 5 points."
  static String buildStatTileDescription({
    required String label,
    required String value,
    String? trend,
  }) {
    final trendSuffix = trend != null ? ' $trend' : '';
    return '$label : $value.$trendSuffix';
  }

  // ─── Validation ───────────────────────────────────────────────

  /// Vérifie qu'un label sémantique est valide :
  ///   - non vide
  ///   - sans emojis (les lecteurs d'écran les annoncent mal)
  ///   - longueur <= 150 caractères (sinon le découper)
  ///
  /// Renvoie null si valide, sinon un message d'erreur.
  /// À utiliser dans les tests unitaires.
  static String? validateLabel(String label) {
    if (label.isEmpty) return 'Label vide';
    if (label.length > 150) {
      return 'Label trop long (${label.length} > 150). Découper en hint.';
    }
    // Regex approximative pour emojis (plages Unicode des emoji).
    final emojiRegex = RegExp(
      r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{1F1E6}-\u{1F1FF}]',
      unicode: true,
    );
    if (emojiRegex.hasMatch(label)) {
      return 'Label contient des emojis (interdit pour lecteurs d\'écran)';
    }
    return null;
  }
}

// ─── Helpers de tooltips accessibles ───────────────────────────

/// Extension sur [IconButton] pour faciliter l'ajout de tooltips
/// accessibles (rôle + label).
///
/// Utilisation :
///   IconButton(
///     icon: const Icon(Icons.accessibility),
///     onPressed: _openOptions,
///   ).withAccessibleTooltip(
///     label: SemanticLabels.accessibilityOptions,
///     hint: SemanticLabels.accessibilityOptionsHint,
///   )
extension AccessibleIconButton on IconButton {
  /// Renvoie un IconButton wrappé dans un Semantics avec label complet.
  Widget withAccessibleTooltip({
    required String label,
    String? hint,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: true,
      child: this,
    );
  }
}

/// Extension sur [Icon] pour ajouter un label sémantique (les icônes
/// décoratives doivent être masquées avec `excludeSemantics: true` ou
/// annoncées avec un label).
///
/// Utilisation :
///   Icon(Icons.check, color: AppColors.success)
///     .withLabel('Réponse correcte')
///
///   // Icône décorative (ne pas annoncer) :
///   Icon(Icons.arrow_forward).asDecorative()
extension AccessibleIcon on Icon {
  /// Renvoie l'icône avec un label sémantique.
  Widget withLabel(String label) {
    return Semantics(label: label, child: this);
  }

  /// Renvoie l'icône marquée comme décorative (non annoncée par le
  /// lecteur d'écran — le label doit être porté par le parent).
  Widget asDecorative() {
    return ExcludeSemantics(child: this);
  }
}
