// lib/screens/level/level_screen.dart
// Écran "Mon Niveau" — progression méta-gamification de l'élève.
//
// Sections :
//   1. Header : niveau actuel (grand) + XP cumulé + barre progression
//   2. Stats hebdo / mensuel : XP gagnée cette semaine, ce mois
//   3. Prochaine récompense à débloquer (carte + niveau requis)
//   4. Sources d'XP : tableau récapitulatif des 8 actions qui donnent de l'XP
//
// Données : UserLevel (Hive "user_level" via LevelService).
// Identité : SharedPreferences "current_user_id" (défaut : "user_demo").
//
// À brancher dans app_router.dart (agent principal) :
//   GoRoute(path: '/level', builder: (_, __) => const LevelScreen()),
// Et dans HomeScreen : un bouton "Mon niveau" qui navigue vers /level.

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/level_reward.dart';
import '../../models/user.dart';
import '../../models/user_level.dart';
import '../../services/level_service.dart';
import '../../theme/app_theme.dart';
import 'rewards_screen.dart';
import 'widgets/level_progress_bar.dart';

class LevelScreen extends StatefulWidget {
  const LevelScreen({super.key});

  @override
  State<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen> {
  UserLevel? _userLevel;
  AppUser? _user;
  bool _loading = true;

  LevelService? _levelService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  // ─── Chargement des données ───────────────────────────────────

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('current_user_id') ?? 'user_demo';

      // AppUser (pour afficher le prénom dans le header).
      final userBox = Hive.isBoxOpen('users')
          ? Hive.box<AppUser>('users')
          : await Hive.openBox<AppUser>('users');
      AppUser? user;
      if (userBox.containsKey(userId)) {
        user = userBox.get(userId);
      }
      user ??= AppUser(
        id: userId,
        nom: 'Élève',
        prenom: 'Élève',
        niveauScolaire: '3eme',
        dateInscription: DateTime.now(),
      );

      // LevelService (lazy init — sera remplacé par un Provider par l'agent principal).
      final levelService = _levelService ??= LevelService();
      if (!levelService.isInitialized) {
        await levelService.init();
      }

      // Rétro-corrige les récompenses manquantes (au cas où).
      await levelService.syncRewards(userId);

      final userLevel = levelService.getOrCreate(userId);

      if (mounted) {
        setState(() {
          _user = user;
          _userLevel = userLevel;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mon Niveau'),
        automaticallyImplyLeading: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.card_giftcard_outlined),
            tooltip: 'Mes récompenses',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const RewardsScreen(),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _buildBody(),
            ),
    );
  }

  // ─── Body ─────────────────────────────────────────────────────

  Widget _buildBody() {
    final userLevel = _userLevel;
    if (userLevel == null) {
      return _buildErrorState();
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header niveau + XP + barre progression
          _HeaderCard(
            user: _user,
            userLevel: userLevel,
          ),
          const SizedBox(height: 16),

          // 2. Stats hebdo / mensuel
          _buildStatsRow(userLevel),
          const SizedBox(height: 20),

          // 3. Prochaine récompense à débloquer
          _buildNextReward(userLevel),
          const SizedBox(height: 20),

          // 4. Sources d'XP (récapitulatif)
          _buildXpSourcesCard(),
          const SizedBox(height: 16),

          // 5. Bouton "Voir toutes mes récompenses"
          _buildViewRewardsButton(),
        ],
      ),
    );
  }

  // ─── Stats hebdo / mensuel ────────────────────────────────────

  Widget _buildStatsRow(UserLevel userLevel) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.calendar_view_week_outlined,
            iconColor: AppColors.primary,
            label: 'Cette semaine',
            value: '${userLevel.xpThisWeek} XP',
            sublabel: _weekRangeLabel(userLevel.weekStart),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.calendar_today_outlined,
            iconColor: AppColors.accent,
            label: 'Ce mois-ci',
            value: '${userLevel.xpThisMonth} XP',
            sublabel: _monthLabel(userLevel.monthStart),
          ),
        ),
      ],
    );
  }

  /// Libellé "du 12 au 18 oct." pour la semaine en cours.
  String _weekRangeLabel(DateTime? weekStart) {
    if (weekStart == null) return 'Cette semaine';
    final end = weekStart.add(const Duration(days: 6));
    final months = [
      'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
      'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'
    ];
    return 'du ${weekStart.day} au ${end.day} ${months[end.month - 1]}';
  }

  /// Libellé "oct. 2026" pour le mois en cours.
  String _monthLabel(DateTime? monthStart) {
    if (monthStart == null) return 'Ce mois';
    final months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return '${months[monthStart.month - 1]} ${monthStart.year}';
  }

  // ─── Prochaine récompense ─────────────────────────────────────

  Widget _buildNextReward(UserLevel userLevel) {
    final currentLevel =
        LevelService.levelFromXp(userLevel.totalXp);
    final nextReward = LevelRewards.nextFor(currentLevel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.lock_open_outlined,
                size: 18, color: AppColors.accent),
            const SizedBox(width: 6),
            Text(
              'Prochaine récompense',
              style: AppTextStyles.h3.copyWith(fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (nextReward != null)
          _NextRewardCard(reward: nextReward, currentLevel: currentLevel)
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Icon(Icons.workspace_premium,
                    color: Colors.white, size: 36),
                SizedBox(height: 8),
                Text(
                  'Toutes les récompenses sont débloquées !',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text(
                  'Tu fais partie de l\'élite ExamBoost Togo.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ─── Sources d'XP (récap) ─────────────────────────────────────

  Widget _buildXpSourcesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stars_outlined,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'Comment gagner de l\'XP ?',
                style: AppTextStyles.h3.copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          ..._xpSourceRows(),
        ],
      ),
    );
  }

  List<Widget> _xpSourceRows() {
    final sources = <(XpSource, int)>[
      (XpSource.questionCorrecte, LevelService.xpQuestionCorrecte),
      (XpSource.simulationCompletee, LevelService.xpSimulationCompletee),
      (XpSource.devoirRendu, LevelService.xpDevoirRendu),
      (XpSource.conversationTuteur, LevelService.xpConversationTuteur),
      (XpSource.badgeBronze, LevelService.xpBadgeBronze),
      (XpSource.badgeArgent, LevelService.xpBadgeArgent),
      (XpSource.badgeOr, LevelService.xpBadgeOr),
      (XpSource.streak7j, LevelService.xpStreak7j),
      (XpSource.streak30j, LevelService.xpStreak30j),
    ];

    return sources.map((s) {
      final source = s.$1;
      final amount = s.$2;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(source.icon, size: 18, color: source.color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                source.label,
                style: AppTextStyles.body,
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: source.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '+$amount XP',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: source.color,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  // ─── Bouton "Voir toutes mes récompenses" ─────────────────────

  Widget _buildViewRewardsButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RewardsScreen()),
        ),
        icon: const Icon(Icons.card_giftcard_outlined),
        label: const Text('Voir toutes mes récompenses'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  // ─── État d'erreur ────────────────────────────────────────────

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 48, color: AppColors.textDisabled),
          const SizedBox(height: 12),
          const Text(
            'Impossible de charger ton niveau.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              setState(() => _loading = true);
              _loadData();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}

// ─── Header card (gradient + niveau + XP + progression) ───────────

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.user, required this.userLevel});

  final AppUser? user;
  final UserLevel userLevel;

  @override
  Widget build(BuildContext context) {
    final currentLevel = LevelService.levelFromXp(userLevel.totalXp);
    final isMax = currentLevel >= LevelService.maxLevel;
    final color = _colorForLevel(currentLevel);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, _darken(color, 0.2)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ligne du haut : prénom + badge niveau max
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  user != null
                      ? 'Bravo ${user!.prenom} !'
                      : 'Continue ton parcours !',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isMax)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.workspace_premium,
                          color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'MAX',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Numéro de niveau géant
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'NIVEAU',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$currentLevel',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  shadows: [
                    Shadow(
                      color: Colors.black38,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '/ ${LevelService.maxLevel}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // XP cumulé total
          Row(
            children: [
              const Icon(Icons.stars, color: Color(0xFFFFB300), size: 18),
              const SizedBox(width: 6),
              Text(
                '${userLevel.totalXp} XP cumulé',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Barre de progression (par-dessus le gradient, on garde
          // les couleurs Material 3 standards pour la lisibilité).
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: LevelProgressBar(
              cumulativeXp: userLevel.totalXp,
              showLevelNumbers: false,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers couleurs ────────────────────────────────────────

  static Color _colorForLevel(int level) {
    if (level <= 10) return AppColors.primary;
    if (level <= 25) return AppColors.accent;
    if (level <= 40) return const Color(0xFF7B1FA2);
    return const Color(0xFFFFB300);
  }

  /// Assombrit une couleur d'un facteur [amount] (0.0 → 1.0).
  static Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }
}

// ─── Carte "prochaine récompense" ──────────────────────────────────

class _NextRewardCard extends StatelessWidget {
  const _NextRewardCard({
    required this.reward,
    required this.currentLevel,
  });

  final LevelReward reward;
  final int currentLevel;

  @override
  Widget build(BuildContext context) {
    final levelsToGo = reward.requiredLevel - currentLevel;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: reward.color.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: reward.color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: reward.color.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: reward.color.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: Icon(
              reward.iconData,
              color: reward.color,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Débloque au niveau ${reward.requiredLevel}',
                  style: TextStyle(
                    fontSize: 12,
                    color: reward.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  levelsToGo == 1
                      ? 'Plus que 1 niveau !'
                      : 'Plus que $levelsToGo niveaux.',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Carte stat ────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.sublabel,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String sublabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sublabel,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textDisabled,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

