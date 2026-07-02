// lib/screens/level/rewards_screen.dart
// Écran "Mes Récompenses" — collection complète des récompenses de niveau.
//
// Sections :
//   1. Header stats : X / 8 débloquées, barre de progression globale
//   2. Récompenses débloquées (liste verte, triée par niveau croissant)
//   3. Récompenses à débloquer (liste grise + niveau requis)
//
// Données : UserLevel (Hive "user_level" via LevelService).
// Identité : SharedPreferences "current_user_id" (défaut : "user_demo").
//
// À brancher dans app_router.dart (agent principal) :
//   GoRoute(path: '/rewards', builder: (_, __) => const RewardsScreen()),

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/level_reward.dart';
import '../../models/user_level.dart';
import '../../services/level_service.dart';
import '../../theme/app_theme.dart';
import 'widgets/reward_unlock_card.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  UserLevel? _userLevel;
  bool _loading = true;
  LevelService? _levelService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  // ─── Chargement ───────────────────────────────────────────────

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('current_user_id') ?? 'user_demo';

      final levelService = _levelService ??= LevelService();
      if (!levelService.isInitialized) {
        await levelService.init();
      }
      await levelService.syncRewards(userId);
      final userLevel = levelService.getOrCreate(userId);

      if (mounted) {
        setState(() {
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
        title: const Text('Mes Récompenses'),
        automaticallyImplyLeading: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _buildBody(),
            ),
    );
  }

  Widget _buildBody() {
    final userLevel = _userLevel;
    if (userLevel == null) {
      return _buildErrorState();
    }

    final currentLevel = LevelService.levelFromXp(userLevel.totalXp);
    final unlocked = <LevelReward>[];
    final locked = <LevelReward>[];

    for (final reward in LevelRewards.all) {
      if (userLevel.hasReward(reward.id) ||
          reward.requiredLevel <= currentLevel) {
        unlocked.add(reward);
      } else {
        locked.add(reward);
      }
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header stats
          _HeaderStats(
            unlockedCount: unlocked.length,
            totalCount: LevelRewards.all.length,
            currentLevel: currentLevel,
          ),
          const SizedBox(height: 20),

          // 2. Récompenses débloquées
          if (unlocked.isNotEmpty) ...[
            _SectionHeader(
              icon: Icons.lock_open_outlined,
              iconColor: AppColors.success,
              title: 'Débloquées',
              subtitle: '${unlocked.length} récompense(s)',
            ),
            const SizedBox(height: 10),
            ...unlocked.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: RewardUnlockCard(
                    reward: r,
                    unlocked: true,
                    showLevelRequirement: false,
                  ),
                )),
            const SizedBox(height: 12),
          ],

          // 3. Récompenses à débloquer
          if (locked.isNotEmpty) ...[
            _SectionHeader(
              icon: Icons.lock_outline,
              iconColor: AppColors.accent,
              title: 'À débloquer',
              subtitle: '${locked.length} récompense(s)',
            ),
            const SizedBox(height: 10),
            ...locked.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: RewardUnlockCard(
                    reward: r,
                    unlocked: false,
                    showLevelRequirement: true,
                  ),
                )),
          ],

          // Si tout est débloqué
          if (locked.isEmpty && unlocked.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.workspace_premium,
                      color: Colors.white, size: 40),
                  const SizedBox(height: 10),
                  const Text(
                    'Toutes les récompenses sont débloquées !',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tu as atteint le niveau $currentLevel — '
                    'tu fais partie de l\'élite ExamBoost Togo.',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
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
            'Impossible de charger tes récompenses.',
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

// ─── Header stats ──────────────────────────────────────────────────

class _HeaderStats extends StatelessWidget {
  const _HeaderStats({
    required this.unlockedCount,
    required this.totalCount,
    required this.currentLevel,
  });

  final int unlockedCount;
  final int totalCount;
  final int currentLevel;

  @override
  Widget build(BuildContext context) {
    final progress = totalCount == 0 ? 0.0 : unlockedCount / totalCount;
    final nextReward = LevelRewards.nextFor(currentLevel);
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
          Row(
            children: [
              const Icon(Icons.card_giftcard,
                  color: Colors.white, size: 22),
              const SizedBox(width: 8),
              const Text(
                'Ma collection',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Compteur principal
          RichText(
            text: TextSpan(
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
              children: [
                TextSpan(text: '$unlockedCount'),
                TextSpan(
                  text: ' / $totalCount',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Text(
            'récompenses débloquées',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),

          // Barre progression globale
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white24,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFFFB300)),
            ),
          ),
          const SizedBox(height: 14),

          // Niveau actuel + prochaine récompense
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.star_rounded,
                      color: Color(0xFFFFB300), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Niveau $currentLevel',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (nextReward != null)
                Flexible(
                  child: Text(
                    'Prochaine : ${nextReward.title} (niv. ${nextReward.requiredLevel})',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else
                const Text(
                  'Collection complète !',
                  style: TextStyle(
                    color: Color(0xFFFFB300),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${(progress * 100).round()} % de complétion',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers couleurs (identiques à LevelProgressBar / LevelScreen) ──

  static Color _colorForLevel(int level) {
    if (level <= 10) return AppColors.primary;
    if (level <= 25) return AppColors.accent;
    if (level <= 40) return const Color(0xFF7B1FA2);
    return const Color(0xFFFFB300);
  }

  static Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }
}

// ─── En-tête de section ────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.h3.copyWith(fontSize: 16),
              ),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
