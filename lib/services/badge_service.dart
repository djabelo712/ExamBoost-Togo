// lib/services/badge_service.dart
// Service de gamification — vérification, débloquage et persistance des badges.
//
// Responsabilités :
//   1. Calculer la progression de chaque badge depuis (AppUser, ReviewCard[], SrsStats)
//      + des compteurs d'événements stockés dans la Hive box "badge_metrics".
//   2. Débloquer automatiquement les badges dont le seuil est atteint.
//   3. Exposer l'état (badges débloqués, XP totale, progression par badge).
//   4. Recevoir les événements métier (recordEarlyRevision, recordSimulationComplete,
//      recordSpeedBurst, markBugReported) pour les métriques non dérivables
//      des modèles existants.
//
// Persistance :
//   - Box<UserBadge> "user_badges" : progression + date de déblocage par badgeId.
//   - Box<dynamic> "badge_metrics"  : compteurs d'événements (simulations, best score, etc.).
//
// À appeler après chaque action de l'élève :
//   final nouveauxBadges = await badgeService.checkAndUnlock(
//     user: user, reviewCards: cards, srsStats: srsStats,
//   );
//   if (nouveauxBadges.isNotEmpty) {
//     BadgeUnlockDialog.show(context, nouveauxBadges.last);
//   }

import 'package:hive_flutter/hive_flutter.dart';

import '../models/badge.dart';
import '../models/review_card.dart';
import '../models/user.dart';
import '../services/srs_service.dart';
import '../utils/app_logger.dart';

class BadgeService {
  static const String _badgesBoxName = 'user_badges';
  static const String _metricsBoxName = 'badge_metrics';

  late Box<UserBadge> _box;
  late Box _metrics;

  bool _initialized = false;

  /// Initialise les deux Hive boxes. À appeler dans main.dart après SrsService.init().
  Future<void> init() async {
    _box = await Hive.openBox<UserBadge>(_badgesBoxName);
    _metrics = await Hive.openBox(_metricsBoxName);
    _initialized = true;
    AppLogger.info(
      'BadgeService initialisé — ${_box.length} UserBadge(s) chargés, '
      '${_metrics.length} métrique(s)',
    );
  }

  bool get isInitialized => _initialized;

  // ─── API principale ────────────────────────────────────────────

  /// Vérifie tous les badges, met à jour les progressions, débloque ceux
  /// dont le seuil est atteint. Retourne la liste des badges nouvellement
  /// débloqués (pour affichage du dialog d'animation).
  ///
  /// À appeler après chaque révision, simulation ou action significative.
  Future<List<Badge>> checkAndUnlock({
    required AppUser user,
    required List<ReviewCard> reviewCards,
    required SrsStats srsStats,
  }) async {
    if (!_initialized) {
      AppLogger.warning('BadgeService pas initialisé — checkAndUnlock ignoré');
      return const [];
    }

    final newlyUnlocked = <Badge>[];

    for (final badge in Badges.all) {
      final userBadge = _getOrCreate(badge.id);
      final newProgress = _computeProgress(
        badge,
        user,
        reviewCards,
        srsStats,
      );

      // La progression ne peut que croître (max).
      if (newProgress > userBadge.progress) {
        userBadge.progress = newProgress;

        // Débloquer si seuil atteint ET pas encore débloqué.
        if (newProgress >= badge.requiredValue &&
            !userBadge.isUnlocked) {
          userBadge.unlockedAt = DateTime.now();
          newlyUnlocked.add(badge);
          AppLogger.info('Badge débloqué : ${badge.id} (+${badge.xpReward} XP)');
        }
        await userBadge.save();
      }
    }

    return newlyUnlocked;
  }

  // ─── Enregistrement d'événements métriques ─────────────────────

  /// Enregistre une révision matinale (avant 8h).
  /// À appeler depuis revision_screen quand une révision a lieu avant 8h.
  Future<void> recordEarlyRevision() async {
    final count = _metric('early_revisions_count', 0);
    await _metrics.put('early_revisions_count', count + 1);
  }

  /// Enregistre une simulation d'examen terminée.
  /// [scoreOver20] : score final /20.
  /// [allQcmCorrect] : vrai si toutes les questions QCM sont correctes.
  Future<void> recordSimulationComplete({
    required int scoreOver20,
    required bool allQcmCorrect,
  }) async {
    // Compteur de simulations complétées
    final count = _metric('simulations_completed', 0);
    await _metrics.put('simulations_completed', count + 1);

    // Meilleur score
    final best = _metric('best_simulation_score', 0);
    if (scoreOver20 > best) {
      await _metrics.put('best_simulation_score', scoreOver20);
    }

    // Compteur de simulations QCM parfaites
    if (allQcmCorrect) {
      final perfect = _metric('perfect_qcm_simulations', 0);
      await _metrics.put('perfect_qcm_simulations', perfect + 1);
    }
  }

  /// Enregistre un "burst" de questions répondues rapidement.
  /// Met à jour les compteurs best_burst_10/20/30min si la durée correspond.
  Future<void> recordSpeedBurst({
    required int questionsAnswered,
    required int durationMinutes,
  }) async {
    if (durationMinutes <= 10) {
      final best = _metric('best_burst_10min', 0);
      if (questionsAnswered > best) {
        await _metrics.put('best_burst_10min', questionsAnswered);
      }
    }
    if (durationMinutes <= 20) {
      final best = _metric('best_burst_20min', 0);
      if (questionsAnswered > best) {
        await _metrics.put('best_burst_20min', questionsAnswered);
      }
    }
    if (durationMinutes <= 30) {
      final best = _metric('best_burst_30min', 0);
      if (questionsAnswered > best) {
        await _metrics.put('best_burst_30min', questionsAnswered);
      }
    }
  }

  /// Marque l'utilisateur comme beta-testeur (a signalé un bug / suggéré une feature).
  /// À appeler depuis un écran "Signaler un bug" ou "Suggérer une amélioration".
  Future<void> markBugReported() async {
    await _metrics.put('bug_reported', 1);
  }

  // ─── Calcul de progression par badge ───────────────────────────

  int _computeProgress(
    Badge badge,
    AppUser user,
    List<ReviewCard> cards,
    SrsStats srs,
  ) {
    switch (badge.id) {
      // ── Streak ─────────────────────────────────────────────────
      case 'streak_7j_bronze':
      case 'streak_7j_argent':
      case 'streak_7j_or':
        return _computeStreak(cards);

      case 'marathonien_bronze':
      case 'marathonien_argent':
      case 'marathonien_or':
        return user.totalSessionsCount;

      case 'leve_tot_bronze':
      case 'leve_tot_argent':
      case 'leve_tot_or':
        return _max(
          _metric('early_revisions_count', 0),
          _countEarlyRevisionsFromCards(cards),
        );

      // ── Révision ───────────────────────────────────────────────
      case 'curieux_bronze':
      case 'curieux_argent':
      case 'curieux_or':
        return user.totalQuestionsAnswered;

      case 'assidu_bronze':
        return _countDistinctMatieres(user);
      case 'assidu_argent':
      case 'assidu_or':
        return _countDistinctChapitres(user);

      case 'rapide_bronze':
        return _metric('best_burst_10min', 0);
      case 'rapide_argent':
        return _metric('best_burst_20min', 0);
      case 'rapide_or':
        return _metric('best_burst_30min', 0);

      // ── Maîtrise (BKT) ─────────────────────────────────────────
      case 'maitre_maths_bronze':
      case 'maitre_maths_argent':
      case 'maitre_maths_or':
        return _countMasteredInMatiere(user, 'MATH');

      case 'pro_francais_bronze':
      case 'pro_francais_argent':
      case 'pro_francais_or':
        return _countMasteredInMatiere(user, 'FRANC');

      case 'polyvalent_bronze':
      case 'polyvalent_argent':
      case 'polyvalent_or':
        return _countMatiereWithMastery(user);

      // ── Simulation ─────────────────────────────────────────────
      case 'pret_examen_bronze':
      case 'pret_examen_argent':
      case 'pret_examen_or':
        return _metric('simulations_completed', 0);

      case 'top_score_bronze':
      case 'top_score_argent':
      case 'top_score_or':
        return _metric('best_simulation_score', 0);

      case 'sans_faute_bronze':
      case 'sans_faute_argent':
      case 'sans_faute_or':
        return _metric('perfect_qcm_simulations', 0);

      // ── Spécial ────────────────────────────────────────────────
      case 'premier_pas_or':
        // Premier pas = au moins une carte a été révisée.
        return cards.any((c) => c.totalAttempts > 0) ? 1 : 0;

      case 'pionnier_or':
        // Heuristique beta : inscrit avant le 31 juillet 2026 (à branches
        // avec un vrai backend qui retournerait le rang d'inscription).
        return _isPioneer(user) ? 1 : 0;

      case 'beta_testeur_or':
        return _metric('bug_reported', 0);

      default:
        AppLogger.warning('Badge inconnu dans _computeProgress : ${badge.id}');
        return 0;
    }
  }

  // ─── Helpers de calcul ─────────────────────────────────────────

  /// Nombre de jours consécutifs (en remontant depuis aujourd'hui)
  /// où au moins une carte a été révisée.
  int _computeStreak(List<ReviewCard> cards) {
    if (cards.isEmpty) return 0;

    final reviewDates = <DateTime>{
      for (final c in cards)
        if (c.lastReviewDate != null) _dateOnly(c.lastReviewDate!),
    };
    if (reviewDates.isEmpty) return 0;

    int streak = 0;
    DateTime cursor = _dateOnly(DateTime.now());

    // Permettre d'avoir révisé hier si aujourd'hui pas encore fait
    // (streak "en cours" plutôt que cassé à minuit).
    if (!reviewDates.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!reviewDates.contains(cursor)) return 0;
    }

    while (reviewDates.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Compte les cartes dont la dernière révision a eu lieu avant 8h du matin.
  /// Heuristique "best-effort" (peut sous-compter si la carte a aussi été
  /// révisée plus tard dans la même journée).
  int _countEarlyRevisionsFromCards(List<ReviewCard> cards) {
    return cards
        .where((c) =>
            c.lastReviewDate != null && c.lastReviewDate!.hour < 8)
        .length;
  }

  /// Compte les matières distinctes touchées (selon les clés de bktMaitrise).
  /// Format clé attendu : "TG-MATHS-EQ1D-001" → matière = "MATHS".
  int _countDistinctMatieres(AppUser user) {
    final set = <String>{};
    for (final key in user.bktMaitrise.keys) {
      final parts = key.split('-');
      if (parts.length >= 2) set.add(parts[1].toUpperCase());
    }
    return set.length;
  }

  /// Compte les chapitres distincts touchés.
  /// Format clé attendu : "TG-MATHS-EQ1D-001" → chapitre = "MATHS-EQ1D".
  int _countDistinctChapitres(AppUser user) {
    final set = <String>{};
    for (final key in user.bktMaitrise.keys) {
      final parts = key.split('-');
      if (parts.length >= 3) {
        set.add('${parts[1]}-${parts[2]}'.toUpperCase());
      }
    }
    return set.length;
  }

  /// Compte les compétences maîtrisées (P(L) ≥ 0,85) dans une matière.
  /// [matiereCode] est recherché dans la clé BKT (ex: "MATH", "FRANC").
  int _countMasteredInMatiere(AppUser user, String matiereCode) {
    final upper = matiereCode.toUpperCase();
    return user.bktMaitrise.entries
        .where((e) =>
            e.key.toUpperCase().contains(upper) && e.value >= 0.85)
        .length;
  }

  /// Compte le nombre de matières ayant au moins une compétence maîtrisée.
  int _countMatiereWithMastery(AppUser user) {
    final matieres = <String>{};
    for (final e in user.bktMaitrise.entries) {
      if (e.value >= 0.85) {
        final parts = e.key.split('-');
        if (parts.length >= 2) matieres.add(parts[1].toUpperCase());
      }
    }
    return matieres.length;
  }

  /// Heuristique beta : considère l'utilisateur comme pionnier s'il s'est
  /// inscrit avant le 31 juillet 2026 (date de la bêta publique).
  /// Remplaçable par un appel backend retournant le rang d'inscription.
  bool _isPioneer(AppUser user) {
    return user.dateInscription.isBefore(DateTime(2026, 7, 31));
  }

  // ─── Accès à l'état ────────────────────────────────────────────

  /// Tous les UserBadge persistés (peut être vide si l'élève est nouveau).
  List<UserBadge> get allUserBadges => _box.values.toList();

  /// Liste des badges débloqués (Badge constants, ordre du catalogue).
  List<Badge> get unlockedBadges => Badges.all
      .where((b) => _box.get(b.id)?.isUnlocked ?? false)
      .toList();

  /// Nombre de badges débloqués.
  int get unlockedCount => unlockedBadges.length;

  /// Nombre total de badges disponibles.
  int get totalCount => Badges.all.length;

  /// Somme des XP des badges débloqués.
  int get totalXp =>
      unlockedBadges.fold(0, (sum, b) => sum + b.xpReward);

  /// Récupère l'UserBadge pour un badgeId, ou null si l'élève n'a jamais
  /// eu de progression sur ce badge.
  UserBadge? userBadgeFor(String badgeId) => _box.get(badgeId);

  /// Pourcentage global de progression (badges débloqués / total).
  double get globalProgress => totalCount == 0
      ? 0.0
      : unlockedCount / totalCount;

  // ─── Helpers internes ──────────────────────────────────────────

  UserBadge _getOrCreate(String badgeId) {
    final existing = _box.get(badgeId);
    if (existing != null) return existing;
    final ub = UserBadge(badgeId: badgeId);
    _box.put(badgeId, ub);
    return ub;
  }

  int _metric(String key, int defaultValue) {
    final v = _metrics.get(key, defaultValue: defaultValue);
    return v is int ? v : defaultValue;
  }

  int _max(int a, int b) => a > b ? a : b;

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
