// lib/services/notification_templates.dart
// Banque de messages de notification varies pour eviter la lassitude.
//
// Chaque methode renvoie un record ({title, body}) tire aleatoirement parmi
// 5-7 variantes. Le choix depend des statistiques SRS (cartes dues) ou du
// streak de l'utilisateur.
//
// Conventions :
//   - Pas d'emojis dans le code source (commentaires inclus).
//   - Ton bienveillant, motivant, tutoiement, references au contexte togolais
//     (BEPC, BAC, eleves typiques comme Amina/Aya/Kofi).
//   - Francais simple, court (max ~80 caracteres par body pour lisibilite).

import 'dart:math';

import '../models/notification_history.dart' show NotificationCategory;
import 'srs_service.dart' show SrsStats;

/// Resultat d'un template : un titre + un corps.
typedef NotificationMessage = ({String title, String body});

class NotificationTemplates {
  NotificationTemplates._();

  static final Random _rng = Random();

  // ─── Rappel quotidien ──────────────────────────────────────────
  /// Message de rappel quotidien — depend du nombre de cartes dues.
  /// Si `stats` est null, on suppose 0 carte due (nouvel utilisateur).
  static NotificationMessage dailyReminder(SrsStats? stats) {
    final due = stats?.dueToday ?? 0;

    final variants = <NotificationMessage>[
      (
        title: 'C\'est l\'heure de reviser !',
        body: due > 0
            ? '$due questions t\'attendent. Lance-toi !'
            : 'Une petite session de 10 min ?',
      ),
      (
        title: 'Un jour de plus vers la reussite',
        body: 'Chaque question te rapproche de ton BEPC.',
      ),
      (
        title: 'Tes futures notes te remercieront',
        body: 'Revise 15 min maintenant, respire tranquille apres.',
      ),
      (
        title: 'Le savoir s\'oublie sans pratique',
        body: due > 0 ? '$due cartes sont dues aujourd\'hui.' : 'Maintiens ton rythme !',
      ),
      (
        title: 'Tu peux le faire !',
        body: 'Meme 5 questions comptent. Lance-toi maintenant.',
      ),
      (
        title: 'Profite de ce moment calme',
        body: '10 min de revision maintenant = moins de stress avant l\'examen.',
      ),
      (
        title: 'Amina l\'a fait, toi aussi tu peux',
        body: due > 0
            ? 'Attaque tes $due questions dues.'
            : 'Continue sur ta lancee !',
      ),
    ];

    return variants[_rng.nextInt(variants.length)];
  }

  // ─── Alerte streak en danger ───────────────────────────────────
  /// Alerte "ton streak de X jours est en danger, depesche-toi".
  static NotificationMessage streakAlert(int streakDays) {
    final safeDays = streakDays < 1 ? 1 : streakDays;

    final variants = <NotificationMessage>[
      (
        title: 'Ton streak de $safeDays jours est en danger !',
        body: 'Une seule question suffit a le sauver. Vas-y !',
      ),
      (
        title: 'Ne perds pas ta serie de $safeDays jours',
        body: 'Il te reste peu de temps avant minuit. Reviser maintenant !',
      ),
      (
        title: '$safeDays jours d\'efforts, c\'est precieux',
        body: 'Une petite question et ton streak reste vivant.',
      ),
      (
        title: 'Ton streak de $safeDays jours vacille',
        body: 'Maintiens ta discipline — tu vas etre fier(e) demain.',
      ),
      (
        title: 'Derniere ligne droite pour ton streak',
        body: 'Tu as tenu $safeDays jours. Ne lache rien maintenant.',
      ),
      (
        title: 'Attention, ta serie de $safeDays jours risque de casser',
        body: '5 minutes suffisent. Tu peux le faire.',
      ),
      (
        title: 'Ton streak te demande 1 question',
        body: '$safeDays jours de regularite, c\'est dommage de perdre ca.',
      ),
    ];

    return variants[_rng.nextInt(variants.length)];
  }

  // ─── Nouvelles questions disponibles ───────────────────────────
  /// Notification "X nouvelles questions sont dispo".
  static NotificationMessage newQuestions(int count) {
    final safeCount = count < 1 ? 1 : count;

    final variants = <NotificationMessage>[
      (
        title: '$safeCount nouvelles questions a decouvrir',
        body: 'Fraichement ajoutees pour ta preparation BEPC/BAC.',
      ),
      (
        title: 'Du nouveau dans ta banque',
        body: '$safeCount questions inedites t\'attendent.',
      ),
      (
        title: 'On a ajoute du contenu pour toi',
        body: '$safeCount nouvelles questions. Veux-tu les tester ?',
      ),
      (
        title: 'Des annales recentes sont arrivees',
        body: '$safeCount questions ajoutees. Bonne revision !',
      ),
      (
        title: 'Ta banque s\'agrandit',
        body: '$safeCount questions supplementaires pour progresser.',
      ),
      (
        title: 'Aucun retard sur le programme',
        body: '$safeCount nouvelles questions sont dispo maintenant.',
      ),
    ];

    return variants[_rng.nextInt(variants.length)];
  }

  // ─── Encouragement social (mock) ───────────────────────────────
  /// Notification sociale — comparison avec un ami fictif (mock backend).
  static NotificationMessage socialNudge(
    String friendName,
    int theirScore,
    int myScore,
  ) {
    final delta = (theirScore - myScore).abs();
    final ahead = theirScore > myScore;

    final aheadVariants = <NotificationMessage>[
      (
        title: '$friendName a revise $theirScore questions cette semaine',
        body: 'Tu es a $myScore. Veux-tu la rattraper ?',
      ),
      (
        title: '$friendName te devance de $delta questions',
        body: 'Encore $delta et tu la rattrapes. A toi de jouer !',
      ),
      (
        title: '$friendName a pris une longueur d\'avance',
        body: 'Tu es a $myScore, elle a $theirScore. Tu peux combler l\'ecart.',
      ),
      (
        title: 'Classement de la semaine',
        body: '$friendName : $theirScore. Toi : $myScore. Tu fais quoi ?',
      ),
      (
        title: '$friendName est en feu cette semaine',
        body: '$theirScore questions revisees. Tu peux faire pareil !',
      ),
      (
        title: 'Petit rappel amical',
        body: '$friendName a $theirScore questions, tu en as $myScore. Motive !',
      ),
    ];

    final behindVariants = <NotificationMessage>[
      (
        title: 'Tu menes le classement devant $friendName',
        body: 'Tu as $myScore questions, elle $theirScore. Maintiens le cap !',
      ),
      (
        title: 'Tu es devant $friendName cette semaine',
        body: '$myScore vs $theirScore. Belle avance, ne te relache pas.',
      ),
      (
        title: 'Bravo, tu surclass $friendName',
        body: 'Tu as $myScore questions revisees. Continue !',
      ),
      (
        title: 'Tu gardes ta premiere place',
        body: '$friendName te suit de $delta questions. Continue !',
      ),
      (
        title: 'Tu es le/la meilleur(e) cette semaine',
        body: 'Score de $myScore contre $theirScore pour $friendName. Bravo !',
      ),
    ];

    final pool = ahead ? aheadVariants : behindVariants;
    return pool[_rng.nextInt(pool.length)];
  }

  // ─── Cartes dues nombreuses ────────────────────────────────────
  /// Notification "tu as X cartes dues" — distincte du rappel quotidien.
  static NotificationMessage dueCardsAlert(int dueCount) {
    final safeCount = dueCount < 1 ? 1 : dueCount;

    final variants = <NotificationMessage>[
      (
        title: 'Tu as $safeCount questions a reviser',
        body: 'Prends 10 min maintenant pour reduire ta pile.',
      ),
      (
        title: 'Ta pile grossit : $safeCount questions dues',
        body: 'C\'est le bon moment pour la reduire.',
      ),
      (
        title: 'Ne laisse pas ta pile s\'accumuler',
        body: '$safeCount questions t\'attendent. 5 min suffisent pour avancer.',
      ),
      (
        title: '$safeCount questions en retard',
        body: 'Plus tu attends, plus elles seront difficiles. Attaque !',
      ),
      (
        title: 'Ta memoire te reclame $safeCount questions',
        body: 'Chaque carte revisee renforce ton cerveau. Go !',
      ),
      (
        title: 'Petit retard, grand rattrapage',
        body: '$safeCount questions dues. C\'est faisable en 15 min.',
      ),
    ];

    return variants[_rng.nextInt(variants.length)];
  }

  // ─── Helpers de selection par categorie ────────────────────────
  /// Genere un message test (bouton "Envoyer une notification test").
  static NotificationMessage testMessage() {
    return (
      title: 'Notification test ExamBoost',
      body: 'Si tu vois ce message, tes notifications fonctionnent. Bravo !',
    );
  }

  /// Renvoie une description lisible de la categorie (pour UI debug).
  static String categoryLabel(NotificationCategory cat) {
    switch (cat) {
      case NotificationCategory.reminders:
        return 'Rappel quotidien';
      case NotificationCategory.streak:
        return 'Alerte streak';
      case NotificationCategory.social:
        return 'Notification sociale';
      case NotificationCategory.updates:
        return 'Nouveautes';
    }
  }
}
