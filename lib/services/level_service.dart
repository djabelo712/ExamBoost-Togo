// lib/services/level_service.dart
// Service de méta-gamification — niveaux (1-50) + XP + récompenses.
//
// Responsabilités :
//   1. Calculer le niveau et la progression à partir de l'XP cumulé.
//   2. Ajouter de l'XP après chaque action de l'élève (révision, simulation, badge...).
//   3. Détecter les montées de niveau et le déblocage de récompenses.
//   4. Maintenir des compteurs roulants (XP cette semaine / ce mois).
//   5. Exposer l'état (UserLevel) pour les écrans LevelScreen / RewardsScreen.
//
// Persistance :
//   - Box<UserLevel> "user_level" (clé = userId).
//   - Un seul UserLevel par élève, créé à la volée au premier gain d'XP.
//
// Formule XP (spec) :
//   XP cumulé pour ACHIEVER le niveau N = 100 * N * (N+1) / 2.
//   Exemples : N1 = 100, N5 = 1500, N10 = 5500, N25 = 32500, N50 = 127500.
//   Interprétation retenue : l'élève commence au niveau 1 (0 XP).
//   Le seuil 100 (N=1) correspond à la complétion du niveau 1 (avancée au niveau 2).
//
// Branchement (à faire par l'agent principal dans les écrans existants) :
//   // Après une réponse correcte (revision_screen) :
//   final result = await levelService.addXpQuestionCorrecte(userId);
//   XpGainAnimation.show(context, amount: result.amount, source: result.source);
//   if (result.leveledUp) {
//     await LevelUpDialog.show(context, result: result);
//   }
//
//   // Après une simulation complète (simulation_screen) :
//   final result = await levelService.addXpSimulationCompletee(userId);
//   ...
//
//   // Après le déblocage d'un badge (badge_service) :
//   for (final badge in nouveauxBadges) {
//     switch (badge.level) {
//       case BadgeLevel.bronze: await levelService.addXpBadgeBronze(userId); break;
//       case BadgeLevel.argent: await levelService.addXpBadgeArgent(userId); break;
//       case BadgeLevel.or:     await levelService.addXpBadgeOr(userId); break;
//     }
//   }
//
//   // Pour le bonus streak (à appeler quand le streak franchit 7 ou 30 jours) :
//   if (streak == 7) await levelService.addXpStreak7j(userId);
//   if (streak == 30) await levelService.addXpStreak30j(userId);
//
//   // Pour les devoirs rendus (mode classe, futur) :
//   await levelService.addXpDevoirRendu(userId);
//
//   // Pour les conversations tuteur IA (tutor_screen) :
//   await levelService.addXpConversationTuteur(userId);

import 'package:hive_flutter/hive_flutter.dart';

import '../models/level_reward.dart';
import '../models/user_level.dart';
import '../utils/app_logger.dart';

// ─── Résultat d'un gain d'XP ───────────────────────────────────────

/// Résultat détaillé d'un appel à [LevelService.addXp].
/// Utilisé pour déclencher les animations (+X XP, montée de niveau, récompense).
class XpGainResult {
  /// Identifiant de l'élève concerné.
  final String userId;

  /// Montant d'XP gagné (positif).
  final int amount;

  /// Source du gain (pour l'animation +X XP et l'historique).
  final XpSource source;

  /// Niveau avant le gain d'XP.
  final int previousLevel;

  /// Niveau après le gain d'XP.
  final int newLevel;

  /// XP cumulé avant le gain.
  final int previousTotalXp;

  /// XP cumulé après le gain.
  final int newTotalXp;

  /// Vrai si l'élève a monté d'au moins un niveau.
  final bool leveledUp;

  /// Récompenses débloquées par cette montée de niveau (peut être vide).
  final List<LevelReward> newlyUnlockedRewards;

  const XpGainResult({
    required this.userId,
    required this.amount,
    required this.source,
    required this.previousLevel,
    required this.newLevel,
    required this.previousTotalXp,
    required this.newTotalXp,
    required this.leveledUp,
    required this.newlyUnlockedRewards,
  });

  /// Résultat "vide" utilisé quand le service n'est pas initialisé ou
  /// que le montant est <= 0. L'UI peut l'ignorer silencieusement.
  factory XpGainResult.empty(String userId, int amount, XpSource source) {
    return XpGainResult(
      userId: userId,
      amount: amount,
      source: source,
      previousLevel: 1,
      newLevel: 1,
      previousTotalXp: 0,
      newTotalXp: 0,
      leveledUp: false,
      newlyUnlockedRewards: const [],
    );
  }
}

// ─── Service principal ─────────────────────────────────────────────

class LevelService {
  static const String _boxName = 'user_level';

  /// Niveau maximum atteignable (plafond).
  static const int maxLevel = 50;

  // ─── Montants d'XP par source (spec) ──────────────────────────
  static const int xpQuestionCorrecte   = 10;
  static const int xpSimulationCompletee = 50;
  static const int xpBadgeBronze         = 100;
  static const int xpBadgeArgent         = 250;
  static const int xpBadgeOr             = 500;
  static const int xpStreak7j            = 200;
  static const int xpStreak30j           = 1000;
  static const int xpDevoirRendu         = 30;
  static const int xpConversationTuteur  = 5;

  late Box<UserLevel> _box;
  bool _initialized = false;

  /// Initialise la Hive box. À appeler dans main.dart après BadgeService.init().
  Future<void> init() async {
    _box = await Hive.openBox<UserLevel>(_boxName);
    _initialized = true;
    AppLogger.info(
      'LevelService initialisé — ${_box.length} UserLevel(s) chargés',
    );
  }

  bool get isInitialized => _initialized;

  // ─── Formules XP / niveau ────────────────────────────────────

  /// XP cumulé requis pour ACHIEVER le niveau N (formule spec).
  /// Pour N=1 : 100 XP. Pour N=5 : 1500 XP. Pour N=10 : 5500 XP.
  /// Pour N=25 : 32500 XP. Pour N=50 : 127500 XP.
  ///
  /// Interprétation : ce seuil correspond à la COMPLÉTION du niveau N
  /// (avancée au niveau N+1). L'élève commence au niveau 1 avec 0 XP.
  static int xpForLevel(int level) {
    if (level <= 0) return 0;
    if (level > maxLevel) return xpForLevel(maxLevel);
    return 100 * level * (level + 1) ~/ 2;
  }

  /// XP cumulé requis pour ATTEINDRE le niveau N (depuis 0).
  /// Niveau 1 = 0 (départ), Niveau 2 = 100, Niveau 5 = 1000,
  /// Niveau 10 = 4500, Niveau 50 = 122500.
  static int xpThresholdForLevel(int level) {
    if (level <= 1) return 0;
    if (level > maxLevel) return xpThresholdForLevel(maxLevel);
    return xpForLevel(level - 1);
  }

  /// Renvoie le niveau atteint pour un montant d'XP cumulé.
  /// L'élève commence au niveau 1 (0 XP). Niveau max = 50.
  ///
  /// Logique : on cherche le plus grand N tel que l'XP cumulé est
  /// strictement inférieur au seuil de complétion du niveau N
  /// (xpForLevel(N)). Si l'XP dépasse le seuil du niveau max, on plafonne.
  static int levelFromXp(int cumulativeXp) {
    if (cumulativeXp <= 0) return 1;
    for (int n = 1; n < maxLevel; n++) {
      if (cumulativeXp < xpForLevel(n)) {
        return n;
      }
    }
    return maxLevel;
  }

  /// XP restant pour atteindre le niveau suivant (0 si niveau max).
  static int xpToNextLevel(int cumulativeXp) {
    final currentLevel = levelFromXp(cumulativeXp);
    if (currentLevel >= maxLevel) return 0;
    final nextLevelThreshold = xpForLevel(currentLevel);
    return nextLevelThreshold - cumulativeXp;
  }

  /// Progression [0.0, 1.0] vers le niveau suivant (1.0 si niveau max).
  static double progressToNextLevel(int cumulativeXp) {
    final currentLevel = levelFromXp(cumulativeXp);
    if (currentLevel >= maxLevel) return 1.0;
    final currentLevelStart = xpThresholdForLevel(currentLevel);
    final nextLevelStart = xpForLevel(currentLevel);
    final span = nextLevelStart - currentLevelStart;
    if (span <= 0) return 0.0;
    return ((cumulativeXp - currentLevelStart) / span).clamp(0.0, 1.0);
  }

  /// XP cumulé depuis le début du niveau actuel.
  static int xpIntoCurrentLevel(int cumulativeXp) {
    final currentLevel = levelFromXp(cumulativeXp);
    final currentLevelStart = xpThresholdForLevel(currentLevel);
    return cumulativeXp - currentLevelStart;
  }

  /// XP total à gagner dans le niveau actuel (pour afficher "120 / 500 XP").
  /// Retourne 0 si l'élève est au niveau maximum.
  static int xpForCurrentLevelSpan(int cumulativeXp) {
    final currentLevel = levelFromXp(cumulativeXp);
    if (currentLevel >= maxLevel) return 0;
    final currentLevelStart = xpThresholdForLevel(currentLevel);
    final nextLevelStart = xpForLevel(currentLevel);
    return nextLevelStart - currentLevelStart;
  }

  /// Vrai si l'élève est au niveau maximum.
  static bool isMaxLevel(int cumulativeXp) =>
      levelFromXp(cumulativeXp) >= maxLevel;

  // ─── Accès à l'état ──────────────────────────────────────────

  /// Récupère le UserLevel pour un userId, ou crée un nouveau si absent.
  /// Le nouveau UserLevel est persisté (HiveObject.save() implicite via put).
  UserLevel getOrCreate(String userId) {
    if (!_initialized) {
      AppLogger.warn(
        'LevelService pas initialisé — getOrCreate retourne un UserLevel '
        'non persisté',
      );
      return UserLevel(userId: userId);
    }
    final existing = _box.get(userId);
    if (existing != null) return existing;
    final newLevel = UserLevel(userId: userId);
    _box.put(userId, newLevel);
    return newLevel;
  }

  /// Niveau actuel d'un élève.
  int currentLevelOf(String userId) {
    final ul = getOrCreate(userId);
    return levelFromXp(ul.totalXp);
  }

  /// XP cumulé total d'un élève.
  int totalXpOf(String userId) => getOrCreate(userId).totalXp;

  /// Rétro-corrige les récompenses manquantes (au cas où l'élève aurait
  /// atteint un niveau avant que la récompense ne soit introduite).
  /// Idempotent. À appeler au démarrage de l'app (optionnel).
  Future<void> syncRewards(String userId) async {
    if (!_initialized) return;
    final ul = getOrCreate(userId);
    final level = levelFromXp(ul.totalXp);
    var changed = false;
    for (final reward in LevelRewards.all) {
      if (reward.requiredLevel <= level && !ul.hasReward(reward.id)) {
        ul.markRewardUnlocked(reward.id);
        changed = true;
      }
    }
    if (changed) {
      await ul.save();
      AppLogger.info('syncRewards($userId) — récompenses rétro-corrigées');
    }
  }

  // ─── API principale : ajout d'XP ─────────────────────────────

  /// Ajoute de l'XP à l'élève. Retourne le résultat détaillé du gain.
  ///
  /// À appeler après chaque action qui donne de l'XP. L'UI peut utiliser
  /// le résultat pour afficher l'animation +X XP, puis le dialog de montée
  /// de niveau si [XpGainResult.leveledUp] est vrai.
  Future<XpGainResult> addXp({
    required String userId,
    required int amount,
    required XpSource source,
  }) async {
    if (!_initialized) {
      AppLogger.warn('LevelService pas initialisé — addXp ignoré');
      return XpGainResult.empty(userId, amount, source);
    }
    if (amount <= 0) {
      return XpGainResult.empty(userId, 0, source);
    }

    final userLevel = getOrCreate(userId);
    final previousLevel = levelFromXp(userLevel.totalXp);
    final previousTotalXp = userLevel.totalXp;

    // Met à jour l'XP cumulé et l'horodatage du dernier gain.
    userLevel.totalXp += amount;
    userLevel.lastXpGainAt = DateTime.now();

    // Met à jour les compteurs roulants (avec reset si frontière franchie).
    _updateRollingStats(userLevel, amount);

    // Détecte la montée de niveau.
    final newLevel = levelFromXp(userLevel.totalXp);
    final leveledUp = newLevel > previousLevel;

    // Détecte le déblocage de récompenses (peut en débloquer plusieurs
    // si l'élève a gagné assez d'XP pour franchir 2+ niveaux d'un coup).
    final newlyUnlockedRewards = <LevelReward>[];
    if (leveledUp) {
      userLevel.lastLevelUpAt = DateTime.now();
      for (final reward in LevelRewards.all) {
        if (reward.requiredLevel > previousLevel &&
            reward.requiredLevel <= newLevel &&
            !userLevel.hasReward(reward.id)) {
          userLevel.markRewardUnlocked(reward.id);
          newlyUnlockedRewards.add(reward);
        }
      }
    }

    await userLevel.save();

    AppLogger.info(
      'XP +$amount (${source.label}) pour $userId — '
      'total: ${userLevel.totalXp} XP, '
      'niveau $previousLevel → $newLevel'
      '${leveledUp ? ' (montée !)' : ''}',
    );

    return XpGainResult(
      userId: userId,
      amount: amount,
      source: source,
      previousLevel: previousLevel,
      newLevel: newLevel,
      previousTotalXp: previousTotalXp,
      newTotalXp: userLevel.totalXp,
      leveledUp: leveledUp,
      newlyUnlockedRewards: newlyUnlockedRewards,
    );
  }

  // ─── Méthodes pratiques par source ───────────────────────────
  //
  // Ces wrappers évitent aux appelants de connaître les montants exacts.
  // L'agent principal n'a qu'à appeler la méthode correspondant à l'action.

  /// +10 XP — à appeler après chaque réponse correcte en révision.
  Future<XpGainResult> addXpQuestionCorrecte(String userId) =>
      addXp(userId: userId, amount: xpQuestionCorrecte, source: XpSource.questionCorrecte);

  /// +50 XP — à appeler après chaque simulation d'examen complétée.
  Future<XpGainResult> addXpSimulationCompletee(String userId) =>
      addXp(userId: userId, amount: xpSimulationCompletee, source: XpSource.simulationCompletee);

  /// +100 XP — à appeler quand un badge Bronze est débloqué.
  Future<XpGainResult> addXpBadgeBronze(String userId) =>
      addXp(userId: userId, amount: xpBadgeBronze, source: XpSource.badgeBronze);

  /// +250 XP — à appeler quand un badge Argent est débloqué.
  Future<XpGainResult> addXpBadgeArgent(String userId) =>
      addXp(userId: userId, amount: xpBadgeArgent, source: XpSource.badgeArgent);

  /// +500 XP — à appeler quand un badge Or est débloqué.
  Future<XpGainResult> addXpBadgeOr(String userId) =>
      addXp(userId: userId, amount: xpBadgeOr, source: XpSource.badgeOr);

  /// +200 XP — à appeler quand le streak atteint 7 jours (bonus unique).
  Future<XpGainResult> addXpStreak7j(String userId) =>
      addXp(userId: userId, amount: xpStreak7j, source: XpSource.streak7j);

  /// +1000 XP — à appeler quand le streak atteint 30 jours (bonus unique).
  Future<XpGainResult> addXpStreak30j(String userId) =>
      addXp(userId: userId, amount: xpStreak30j, source: XpSource.streak30j);

  /// +30 XP — à appeler quand un devoir est rendu (mode classe).
  Future<XpGainResult> addXpDevoirRendu(String userId) =>
      addXp(userId: userId, amount: xpDevoirRendu, source: XpSource.devoirRendu);

  /// +5 XP — à appeler après chaque échange concluant avec le tuteur IA.
  Future<XpGainResult> addXpConversationTuteur(String userId) =>
      addXp(userId: userId, amount: xpConversationTuteur, source: XpSource.conversationTuteur);

  // ─── Helpers internes ────────────────────────────────────────

  /// Met à jour les compteurs roulants (semaine / mois) avec reset
  /// automatique si la frontière de semaine ou de mois a été franchie
  /// depuis le dernier gain d'XP.
  void _updateRollingStats(UserLevel userLevel, int amount) {
    final now = DateTime.now();
    final currentWeekStart = _startOfWeek(now);
    final currentMonthStart = _startOfMonth(now);

    // Reset hebdo si on a changé de semaine.
    if (userLevel.weekStart == null ||
        !userLevel.weekStart!.isAtSameMomentAs(currentWeekStart)) {
      userLevel.xpThisWeek = 0;
      userLevel.weekStart = currentWeekStart;
    }
    userLevel.xpThisWeek += amount;

    // Reset mensuel si on a changé de mois.
    if (userLevel.monthStart == null ||
        !userLevel.monthStart!.isAtSameMomentAs(currentMonthStart)) {
      userLevel.xpThisMonth = 0;
      userLevel.monthStart = currentMonthStart;
    }
    userLevel.xpThisMonth += amount;
  }

  /// Lundi 00:00 de la semaine contenant [date].
  /// (weekday : 1 = lundi, 7 = dimanche selon DateTime.)
  static DateTime _startOfWeek(DateTime date) {
    final daysToSubtract = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - daysToSubtract);
  }

  /// 1er du mois à 00:00 pour [date].
  static DateTime _startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }
}
