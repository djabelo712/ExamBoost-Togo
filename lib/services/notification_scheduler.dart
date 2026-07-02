// lib/services/notification_scheduler.dart
// Logique intelligente de programmation des notifications ExamBoost.
//
// 4 types de notifications :
//   1. Rappel quotidien     — a l'heure preferee de l'utilisateur
//   2. Alerte streak        — si l'utilisateur risque de casser son streak
//   3. Cartes dues          — si l'utilisateur a beaucoup de cartes en retard
//   4. Encouragement social — mock hebdomadaire (backend futur)
//
// Usage (a brancher par l'agent principal) :
//   - Au lancement de l'app (apres UserProvider.initialize())
//   - Apres chaque fin de session de revision (pour re-planifier le rappel)
//   - Au changement de settings (heure preferee, switches on/off)

import 'dart:math';

import '../models/notification_settings.dart';
import '../models/review_card.dart';
import '../models/user.dart';
import '../utils/app_logger.dart';
import 'notification_service.dart';
import 'notification_templates.dart';
import 'srs_service.dart' show SrsStats;

/// Identifiants fixes des notifications planifiees (pour pouvoir les annuler).
class _NotifIds {
  static const int dailyReminder = 1;
  static const int socialNudge = 2;
}

class NotificationScheduler {
  NotificationScheduler({
    required NotificationService service,
    required NotificationSettings settings,
  })  : _service = service,
        _settings = settings;

  final NotificationService _service;
  final NotificationSettings _settings;

  // Donnees mock pour la comparaison sociale (en production : viendrait du
  // backend). On garde une liste limitee de prenoms togolais typiques.
  static const List<String> _friendNames = [
    'Aya',
    'Kofi',
    'Amina',
    'Yaw',
    'Ama',
    'Kossi',
    'Afia',
  ];

  /// Orchestre la (re-)planification de toutes les notifications.
  ///
  /// [user] — l'utilisateur courant (pour streak, lastActive).
  /// [srsStats] — stats SRS (cartes dues, etc.).
  /// [cards] — liste des ReviewCard (optionnel, pour calculer le streak
  ///   precisement comme dans dashboard_screen.dart). Si null, on utilise
  ///   `user.lastActiveDate` comme approximation.
  Future<void> scheduleAllReminders({
    required AppUser user,
    required SrsStats srsStats,
    List<ReviewCard>? cards,
  }) async {
    // Toujours annuler les rappels precedents pour eviter les doublons
    // (notamment le rappel quotidien si l'heure a change).
    await _service.cancel(_NotifIds.dailyReminder);
    await _service.cancel(_NotifIds.socialNudge);

    // 1. Rappel quotidien
    if (_settings.dailyReminderEnabled) {
      await _scheduleDailyReminder(srsStats);
    }

    // 2. Alerte streak (immediate si risque)
    if (_settings.streakAlertsEnabled) {
      await _scheduleStreakAlert(user, cards);
    }

    // 3. Alerte cartes dues (immediate si beaucoup en retard)
    await _scheduleDueCardsAlert(srsStats);

    // 4. Encouragement social (mock hebdo)
    if (_settings.socialNudgesEnabled) {
      await _scheduleSocialNudge(user, srsStats);
    }
  }

  // ─── 1. Rappel quotidien ──────────────────────────────────────
  Future<void> _scheduleDailyReminder(SrsStats stats) async {
    final heure = _settings.preferredReminderTime;
    final template = NotificationTemplates.dailyReminder(stats);

    await _service.scheduleDaily(
      time: heure,
      title: template.title,
      body: template.body,
      category: NotificationCategory.reminders,
      id: _NotifIds.dailyReminder,
      payload: const {'action': 'open_revision'},
    );
  }

  // ─── 2. Alerte streak ─────────────────────────────────────────
  /// Si l'utilisateur a un streak >= 3 jours et n'a pas revise aujourd'hui
  /// apres 20h, on l'alerte immediatement.
  Future<void> _scheduleStreakAlert(
    AppUser user,
    List<ReviewCard>? cards,
  ) async {
    final streak = _computeCurrentStreak(user, cards);
    if (streak < 3) return;

    final now = DateTime.now();
    if (now.hour < 20) return; // Trop tot pour alerter (avant 20h)

    final today = DateTime(now.year, now.month, now.day);
    final lastReview = _getLastReviewDate(user, cards);
    if (lastReview != null && lastReview.isAfter(today)) {
      // A deja revise aujourd'hui, pas besoin d'alerter
      return;
    }

    final template = NotificationTemplates.streakAlert(streak);
    final hoursLeft = 23 - now.hour;

    await _service.showNow(
      title: template.title,
      body: hoursLeft > 0
          ? '${template.body} Il te reste ~${hoursLeft}h.'
          : template.body,
      category: NotificationCategory.streak,
      payload: const {'action': 'open_revision'},
    );
  }

  // ─── 3. Alerte cartes dues ────────────────────────────────────
  /// Notifie si l'utilisateur a >= 5 cartes dues (sinon pas assez pour
  /// alerter — pas de spam pour 1-2 cartes en retard).
  Future<void> _scheduleDueCardsAlert(SrsStats stats) async {
    if (stats.dueToday < 5) return;

    final template = NotificationTemplates.dueCardsAlert(stats.dueToday);

    await _service.showNow(
      title: template.title,
      body: template.body,
      category: NotificationCategory.reminders,
      payload: const {'action': 'open_revision'},
    );
  }

  // ─── 4. Encouragement social (mock) ───────────────────────────
  /// 1 fois par semaine max. Compare l'utilisateur a un ami fictif (en
  /// production : viendrait du backend, base sur les vrais camarades de
  /// classe / amis ajoutes).
  Future<void> _scheduleSocialNudge(AppUser user, SrsStats stats) async {
    // Anti-spam : skip si dernier nudge < 7 jours
    final lastSocialNudge = _settings.lastSocialNudgeDate;
    if (lastSocialNudge != null &&
        DateTime.now().difference(lastSocialNudge).inDays < 7) {
      return;
    }

    // Donnees mock : on prend un ami au hasard et on le met "legerement
    // devant" l'utilisateur pour rester motivant.
    final rng = Random();
    final friendName = _friendNames[rng.nextInt(_friendNames.length)];

    final myScore = (stats.totalCards > 0)
        ? stats.totalCards
        : user.totalQuestionsAnswered;
    // L'ami a entre 5 et 20 questions de plus que moi
    final theirScore = myScore + 5 + rng.nextInt(16);

    final template = NotificationTemplates.socialNudge(
      friendName,
      theirScore,
      myScore,
    );

    // Planifie dans 2h (pas immediatement pour ne pas spammer au lancement)
    await _service.scheduleAt(
      scheduledTime: DateTime.now().add(const Duration(hours: 2)),
      title: template.title,
      body: template.body,
      category: NotificationCategory.social,
      id: _NotifIds.socialNudge,
      payload: const {'action': 'open_dashboard'},
    );

    // Marque la date d'envoi (anti-spam)
    _settings.markSocialNudgeSent();
  }

  // ─── Helpers : streak & derniere revision ─────────────────────
  /// Calcule le streak courant (jours consecutifs de revision).
  /// Algorithme identique a dashboard_screen.dart (avec tolerance :
  /// si pas revise aujourd'hui, on remonte a hier).
  int _computeCurrentStreak(AppUser user, List<ReviewCard>? cards) {
    if (cards == null || cards.isEmpty) {
      // Fallback : comparer user.lastActiveDate a aujourd'hui
      final last = user.lastActiveDate;
      if (last == null) return 0;
      final today = _dateOnly(DateTime.now());
      final lastDay = _dateOnly(last);
      final diff = today.difference(lastDay).inDays;
      // Si last = aujourd'hui ou hier, streak = 1 minimum
      if (diff <= 1) return 1;
      return 0;
    }

    final days = cards
        .where((c) => c.lastReviewDate != null)
        .map((c) => _dateOnly(c.lastReviewDate!))
        .toSet();

    if (days.isEmpty) return 0;

    var cursor = _dateOnly(DateTime.now());
    // Tolerance : si pas revise aujourd'hui, on remonte a hier
    if (!days.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    int streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Renvoie la date (jour uniquement) de la derniere revision.
  DateTime? _getLastReviewDate(AppUser user, List<ReviewCard>? cards) {
    if (cards != null && cards.isNotEmpty) {
      DateTime? latest;
      for (final c in cards) {
        if (c.lastReviewDate == null) continue;
        if (latest == null || c.lastReviewDate!.isAfter(latest)) {
          latest = c.lastReviewDate;
        }
      }
      if (latest != null) return latest;
    }
    return user.lastActiveDate;
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  // ─── Hooks optionnels pour evenements specifiques ─────────────
  /// A appeler quand de nouvelles questions sont ajoutees a la banque.
  /// [count] = nombre de nouvelles questions. Skip si settings desactive.
  Future<void> onNewQuestionsAvailable(int count) async {
    if (!_settings.newQuestionsAlertsEnabled) return;
    if (count < 5) return; // pas assez pour alerter

    final template = NotificationTemplates.newQuestions(count);
    await _service.showNow(
      title: template.title,
      body: template.body,
      category: NotificationCategory.updates,
      payload: const {'action': 'open_home'},
    );
  }

  /// A appeler quand l'utilisateur termine une session de revision.
  /// Re-planifie le rappel quotidien avec un message frais + re-evalue
  /// le streak.
  Future<void> onReviewSessionCompleted({
    required AppUser user,
    required SrsStats srsStats,
    List<ReviewCard>? cards,
  }) async {
    // Re-planifie tout (le template du daily change grace au RNG, le streak
    // est recalcule, etc.)
    await scheduleAllReminders(
      user: user,
      srsStats: srsStats,
      cards: cards,
    );
    AppLogger.info('Notifications re-planifiees apres session');
  }

  /// A appeler quand l'utilisateur change ses preferences (switch on/off,
  /// heure preferee). Annule puis re-planifie tout.
  Future<void> onSettingsChanged({
    required AppUser user,
    required SrsStats srsStats,
    List<ReviewCard>? cards,
  }) async {
    await scheduleAllReminders(
      user: user,
      srsStats: srsStats,
      cards: cards,
    );
  }

  /// Coupe TOUTES les notifications (bouton "Desactiver toutes" du settings).
  Future<void> disableAll() async {
    await _service.cancelAll();
    AppLogger.info('Toutes les notifications desactivees par l\'utilisateur');
  }
}
