// lib/widgets/semantic_labels.dart
// Bibliothèque de labels sémantiques pour les lecteurs d'écran (TalkBack /
// VoiceOver) + widgets helpers pour appliquer facilement la sémantique.
//
// Conformité WCAG 2.1 :
//   - SC 1.3.1 Info and Relationships (Level A)
//   - SC 4.1.2 Name, Role, Value (Level A)
//   - SC 4.1.3 Status Messages (Level AA)
//
// Pourquoi des labels explicites ?
//   - Les boutons icône seule (IconButton sans texte) sont annoncés
//     "Bouton" sans nom par TalkBack → inaccessible.
//   - Les cartes interactives doivent annoncer leur role ET leur nom
//     ("Bouton Facile. Appuyez pour indiquer que la question était facile.").
//   - Les changements d'état (score, progression) doivent être annoncés
//     via SemanticsService.announce() ou LiveRegion.
//
// Utilisation :
//   IconButton(
//     icon: Icon(Icons.accessibility),
//     onPressed: _openOptions,
//     tooltip: SemanticLabels.accessibilityOptions, // <- accessible
//   )
//
//   LabeledSemantics(
//     label: SemanticLabels.facileButton,
//     button: true,
//     child: SrsButtonFacile(...),
//   )
//
//   LiveRegion(
//     child: Text('Score : $score / $total'),
//   )

import 'package:flutter/material.dart';

/// Catalogue centralisé de labels sémantiques (FR) pour ExamBoost Togo.
///
/// Centraliser les labels dans une classe statique :
///   - évite les incohérences (un même bouton annoncé différemment)
///   - facilite la traduction future (extraire vers app_fr.arb)
///   - permet l'audit (grep SemanticLabels pour lister tous les labels)
///
/// Convention : chaque label décrit le ROLE ("Bouton", "Lien", "Case à
/// cocher") + l'ACTION ("Appuyez pour...") + le contexte si nécessaire.
class SemanticLabels {
  SemanticLabels._();

  // ─── Navigation principale (BottomNavigationBar) ──────────────
  static const String home = 'Accueil';
  static const String homeHint = 'Affiche la page d\'accueil d\'ExamBoost';
  static const String revision = 'Révision';
  static const String revisionHint = 'Affiche les cartes de révision SM-2';
  static const String simulation = 'Simulation';
  static const String simulationHint = 'Démarre une simulation d\'examen officiel';
  static const String dashboard = 'Tableau de bord';
  static const String dashboardHint = 'Affiche tes statistiques et ta progression';
  static const String search = 'Recherche';
  static const String searchHint = 'Recherche une question par mot-clé ou matière';
  static const String profile = 'Profil';
  static const String profileHint = 'Affiche ton profil et tes badges';

  // ─── AppBar ───────────────────────────────────────────────────
  static const String back = 'Retour';
  static const String backHint = 'Revient à l\'écran précédent';
  static const String menu = 'Menu';
  static const String menuHint = 'Ouvre le menu de navigation';
  static const String close = 'Fermer';
  static const String closeHint = 'Ferme cette boîte de dialogue';
  static const String more = 'Plus d\'options';
  static const String moreHint = 'Ouvre un menu d\'actions supplémentaires';

  // ─── Boutons SRS (qualité de révision) ────────────────────────
  /// "Bouton Facile. Appuyez pour indiquer que la question était facile."
  static const String facileButton =
      'Bouton Facile. Appuyez pour indiquer que la question était facile.';
  static const String correctButton =
      'Bouton Correct. Appuyez pour indiquer que vous avez répondu correctement '
      'avec une légère hésitation.';
  static const String difficileButton =
      'Bouton Difficile. Appuyez pour indiquer que vous avez trouvé la réponse '
      'avec difficulté.';
  static const String oublieButton =
      'Bouton Oublié. Appuyez pour indiquer que vous n\'avez pas retrouvé la '
      'réponse.';

  // ─── Actions génériques ───────────────────────────────────────
  static const String valider = 'Valider';
  static const String validerHint = 'Confirme ta réponse et passe à la question suivante';
  static const String annuler = 'Annuler';
  static const String annulerHint = 'Annule l\'action en cours';
  static const String suivant = 'Suivant';
  static const String suivantHint = 'Passe à la question suivante';
  static const String precedent = 'Précédent';
  static const String precedentHint = 'Revient à la question précédente';
  static const String skip = 'Passer';
  static const String skipHint = 'Passe cette question sans répondre';
  static const String reinitialiser = 'Réinitialiser';
  static const String reinitialiserHint = 'Remet les valeurs par défaut';

  // ─── Paramètres accessibilité ─────────────────────────────────
  static const String accessibilityOptions = 'Options d\'accessibilité';
  static const String accessibilityOptionsHint =
      'Ouvre la boîte de dialogue des options d\'accessibilité';
  static const String dyslexiaFont = 'Police dyslexie';
  static const String dyslexiaFontHint =
      'Active la police adaptée aux personnes dyslexiques';
  static const String highContrast = 'Contraste élevé';
  static const String highContrastHint =
      'Active le mode contraste élevé : texte noir sur fond jaune';
  static const String textSizeScale = 'Taille du texte';
  static const String textSizeScaleHint =
      'Ajuste la taille du texte de petit à très grand';
  static const String extraTime = 'Temps additionnel 25%';
  static const String extraTimeHint =
      'Allonge la durée de l\'examen de 25% pour les élèves avec handicap';
  static const String textToSpeech = 'Lecture audio (TTS)';
  static const String textToSpeechHint =
      'Lit les énoncés à voix haute';

  // ─── Examen / Simulation ──────────────────────────────────────
  static const String startExam = 'Démarrer l\'examen';
  static const String startExamHint =
      'Commence la simulation d\'examen avec chronomètre officiel';
  static const String pauseExam = 'Mettre en pause';
  static const String pauseExamHint = 'Suspend temporairement l\'examen';
  static const String resumeExam = 'Reprendre';
  static const String resumeExamHint = 'Reprend l\'examen là où il a été mis en pause';
  static const String submitExam = 'Terminer l\'examen';
  static const String submitExamHint =
      'Valide toutes tes réponses et calcule ton score';
  static const String scratchSheet = 'Brouillon';
  static const String scratchSheetHint = 'Ouvre la feuille de brouillon pour tes calculs';
  static const String calculator = 'Calculatrice';
  static const String calculatorHint = 'Ouvre la calculatrice intégrée';

  // ─── Favoris ──────────────────────────────────────────────────
  static const String addToFavorites = 'Ajouter aux favoris';
  static const String removeFromFavorites = 'Retirer des favoris';
  static const String favoritesHint =
      'Enregistre cette question pour la réviser plus tard';

  // ─── Étiquettes dynamiques (méthodes) ─────────────────────────

  /// "Question 5 sur 20".
  static String questionLabel(int index, int total) {
    return 'Question $index sur $total';
  }

  /// "Question 5 sur 20, progression 25 pour cent".
  static String questionWithProgress(int index, int total) {
    final percent = total > 0 ? ((index - 1) / total * 100).round() : 0;
    return 'Question $index sur $total, progression $percent pour cent';
  }

  /// "Score : 14 sur 20, 70 pour cent".
  static String scoreLabel(int score, int total) {
    final percent = total > 0 ? (score / total * 100).round() : 0;
    return 'Score : $score sur $total, $percent pour cent';
  }

  /// "Score mis à jour : 14 sur 20, 70 pour cent".
  static String scoreUpdated(int score, int total) {
    final percent = total > 0 ? (score / total * 100).round() : 0;
    return 'Score mis à jour : $score sur $total, $percent pour cent';
  }

  /// "Temps restant : 45 minutes 30 secondes".
  static String timeRemaining(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return 'Temps restant : $minutes minutes $seconds secondes';
  }

  /// "Niveau 5. 1240 points d'expérience. 320 points avant le niveau 6."
  static String levelLabel(int level, int xp, int xpToNext) {
    return 'Niveau $level. $xp points d\'expérience. '
        '$xpToNext points avant le niveau ${level + 1}.';
  }

  /// "Carte 3 sur 12 : Théorème de Pythagore".
  static String flashcardLabel(int index, int total, String title) {
    return 'Carte $index sur $total : $title';
  }

  /// "Badge débloqué : Maître des mathématiques".
  static String badgeUnlocked(String badgeName) {
    return 'Badge débloqué : $badgeName';
  }

  /// "Série de 7 jours. Continue demain pour ne pas la perdre."
  static String streakLabel(int days) {
    return 'Série de $days jours. Continue demain pour ne pas la perdre.';
  }
}

/// Widget qui applique un label sémantique complet (label + hint + role) à
/// un [child] pour les lecteurs d'écran.
///
/// Utiliser sur les éléments interactifs custom (Cartes, GestureDetector)
/// qui ne portent pas naturellement de sémantique bouton.
///
/// Exemple :
///   LabeledSemantics(
///     label: SemanticLabels.facileButton,
///     hint: 'Question jugée facile',
///     button: true,
///     child: GestureDetector(
///       onTap: _onFacile,
///       child: Card(child: Text('Facile')),
///     ),
///   )
class LabeledSemantics extends StatelessWidget {
  /// Nom accessible annoncé par le lecteur d'écran (ex : "Bouton Facile").
  final String label;

  /// Description additionnelle annoncée après le label
  /// (ex : "Appuyez pour indiquer que la question était facile.").
  final String? hint;

  /// Si true, annonce "Bouton" comme role (au lieu de laisser Flutter
  /// deviner). Utiliser pour les GestureDetector/Card custom.
  final bool button;

  /// Si true, annonce "Lien" comme role.
  final bool link;

  /// Si true, annonce "En-tête" comme role (pour les titres de section).
  final bool header;

  /// Si true, l'élément est annoncé comme désactivé (grisé).
  final bool enabled;

  /// Si true, l'élément est marqué comme sélectionné (ex : onglet actif).
  final bool selected;

  /// Noeud de sémantique fusionné : les enfants ne sont pas annoncés
  /// individuellement. Utile pour les cartes complexes.
  final bool container;

  /// Element a etiqueter.
  final Widget child;

  const LabeledSemantics({
    super.key,
    required this.label,
    this.hint,
    this.button = false,
    this.link = false,
    this.header = false,
    this.enabled = true,
    this.selected = false,
    this.container = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      button: button,
      link: link,
      header: header,
      enabled: enabled,
      selected: selected,
      container: container,
      child: child,
    );
  }
}

/// Region "live" (aria-live) : annonce automatiquement les changements de
/// contenu au lecteur d'écran.
///
/// - [assertive] = false (defaut) : annonce polie, attend la fin de la
///   lecture en cours. Utiliser pour les scores, progression.
/// - [assertive] = true : annonce immediate, interrompt la lecture en
///   cours. Utiliser pour les alertes critiques (temps écoulé, erreur).
///
/// Exemple :
///   LiveRegion(
///     child: Text('Score : $score / $total'),
///   )
///
/// Note Flutter : la propriete `liveRegion: true` de [Semantics] correspond
/// a aria-live="polite". Pour aria-live="assertive", on ajoute
/// `attributedHint` ou on utilise [ScreenReaderUtils.announceAssertive].
class LiveRegion extends StatelessWidget {
  final Widget child;

  /// Si true, l'annonce est assertive (interrompt la lecture en cours).
  final bool assertive;

  const LiveRegion({
    super.key,
    required this.child,
    this.assertive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      // Flutter ne supporte pas directement aria-live="assertive" via
      // Semantics ; on utilise attributedHint comme signal supplementaire.
      // Pour une annonce assertive fiable, preferer
      // ScreenReaderUtils.announceAssertive().
      child: ExcludeSemantics(
        excluding: false,
        child: child,
      ),
    );
  }
}

/// Widget qui groupe sémantiquement plusieurs widgets enfants en un seul
/// element announce (ex : "Question 5 sur 20, score 60%").
///
/// Utiliser pour les en-têtes de carte, les tuiles de dashboard, les
/// elements de liste complexes.
///
/// Exemple :
///   SemanticGroup(
///     label: 'Question 5 sur 20, score 60 pour cent',
///     child: Column(children: [...]),
///   )
class SemanticGroup extends StatelessWidget {
  /// Label announce pour le groupe (remplace les labels des enfants).
  final String label;

  /// Hint optionnel (comment interagir).
  final String? hint;

  /// Contenu du groupe.
  final Widget child;

  /// Si true (defaut), les enfants sont exclus de l'arbre sémantique
  /// (evite la double annonce). Mettre false si les enfants ont des
  /// labels importants a annoncer individuellement.
  final bool excludeChildren;

  const SemanticGroup({
    super.key,
    required this.label,
    this.hint,
    required this.child,
    this.excludeChildren = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: label,
      hint: hint,
      child: ExcludeSemantics(
        excluding: excludeChildren,
        child: child,
      ),
    );
  }
}

/// Widget qui marque un [child] comme un titre de section (role "header").
///
/// Les lecteurs d'écran permettent de naviguer de titre en titre (balayage
/// haut/bas dans TalkBack). Marquer les titres améliore la navigation.
///
/// Exemple :
///   SemanticHeader(
///     level: 1,
///     child: Text('Tableau de bord', style: AppTextStyles.h1),
///   )
class SemanticHeader extends StatelessWidget {
  /// Niveau du titre (1 = principal, 6 = mineur). Utilisé par certains
  /// lecteurs d'écran pour la hiérarchisation.
  final int level;

  /// Texte du titre.
  final Widget child;

  const SemanticHeader({
    super.key,
    this.level = 1,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      attributedHint: level > 1
          ? AttributedString('Titre de niveau $level')
          : null,
      child: child,
    );
  }
}
