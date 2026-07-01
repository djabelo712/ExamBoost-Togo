// lib/screens/badges/badges_screen.dart
// Écran "Mes Badges" — collection complète des badges ExamBoost Togo.
//
// Sections :
//   1. Header stats : X / 39 débloqués, XP totale, barre de progression globale
//   2. Filtre statut   : Tous | Débloqués | En cours | Verrouillés
//   3. Filtre catégorie : chips horizontaux (Tous, Streak, Révision, …)
//   4. Grille 3 colonnes de badges (badge_card.dart)
//
// Données : AppUser (Hive "users") + ReviewCard[] (Hive "review_cards")
//           + SrsStats (SrsService) + UserBadge[] (Hive "user_badges" via BadgeService).
// Identité : SharedPreferences "current_user_id" (défaut : "user_demo").

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/badge.dart';
import '../../models/review_card.dart';
import '../../models/user.dart';
import '../../services/badge_service.dart';
import '../../services/srs_service.dart';
import '../../theme/app_theme.dart';
import 'badge_detail_sheet.dart';
import 'widgets/badge_grid.dart';

// ─── Filtres ────────────────────────────────────────────────────

enum BadgeStatusFilter { all, unlocked, inProgress, locked }

extension BadgeStatusFilterLabel on BadgeStatusFilter {
  String get label => switch (this) {
        BadgeStatusFilter.all => 'Tous',
        BadgeStatusFilter.unlocked => 'Débloqués',
        BadgeStatusFilter.inProgress => 'En cours',
        BadgeStatusFilter.locked => 'Verrouillés',
      };
}

// ─── Écran ──────────────────────────────────────────────────────

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  // ─── État ──────────────────────────────────────────────────────
  AppUser? _user;
  List<ReviewCard> _cards = const [];
  Map<String, UserBadge> _userBadges = {};
  bool _loading = true;

  // Filtres actifs
  BadgeStatusFilter _statusFilter = BadgeStatusFilter.all;
  BadgeCategory? _categoryFilter; // null = "Toutes catégories"

  // Service de badges (initialisé à la demande si pas déjà fait)
  BadgeService? _badgeService;

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

      // AppUser
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

      // ReviewCards
      final cardBox = Hive.isBoxOpen('review_cards')
          ? Hive.box<ReviewCard>('review_cards')
          : await Hive.openBox<ReviewCard>('review_cards');
      final cards = cardBox.values.where((c) => c.userId == userId).toList();

      // BadgeService (lazy init)
      final badgeService = _badgeService ??= BadgeService();
      if (!badgeService.isInitialized) {
        await badgeService.init();
      }

      // Déclencher une vérification des badges (au cas où de nouveaux seraient débloquables)
      // On ne l'affiche pas ici (pas de dialog) — l'élève est déjà sur la page collection.
      final srsService = Provider.of<SrsService>(context, listen: false);
      final srsStats = srsService.getStats(userId);
      await badgeService.checkAndUnlock(
        user: user,
        reviewCards: cards,
        srsStats: srsStats,
      );

      // Construire la map badgeId -> UserBadge
      final ubMap = <String, UserBadge>{};
      for (final ub in badgeService.allUserBadges) {
        ubMap[ub.badgeId] = ub;
      }

      if (mounted) {
        setState(() {
          _user = user;
          _cards = cards;
          _userBadges = ubMap;
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
        title: const Text('Mes Badges'),
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
    final badgeService = _badgeService;
    if (badgeService == null || _user == null) {
      // Échec du chargement : on propose un retry.
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: AppColors.textDisabled),
            const SizedBox(height: 12),
            const Text(
              'Impossible de charger tes badges.',
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
    final unlockedCount = badgeService.unlockedCount;
    final totalCount = badgeService.totalCount;
    final totalXp = badgeService.totalXp;
    final globalProgress = badgeService.globalProgress;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header stats
          _HeaderStats(
            unlockedCount: unlockedCount,
            totalCount: totalCount,
            totalXp: totalXp,
            globalProgress: globalProgress,
          ),
          const SizedBox(height: 16),

          // 2. Filtre statut (SegmentedButton)
          _buildStatusFilter(),
          const SizedBox(height: 12),

          // 3. Filtre catégorie (chips horizontaux)
          _buildCategoryChips(),
          const SizedBox(height: 8),

          // 4. Grille filtrée
          _buildFilteredGrid(),
        ],
      ),
    );
  }

  // ─── Filtre statut ────────────────────────────────────────────

  Widget _buildStatusFilter() {
    return SegmentedButton<BadgeStatusFilter>(
      segments: BadgeStatusFilter.values
          .map((s) => ButtonSegment(
                value: s,
                label: Text(
                  s.label,
                  style: const TextStyle(fontSize: 12),
                ),
              ))
          .toList(),
      selected: {_statusFilter},
      onSelectionChanged: (selection) {
        setState(() => _statusFilter = selection.first);
      },
      style: const ButtonStyle(
        visualDensity: VisualDensity(horizontal: -3, vertical: -2),
      ),
    );
  }

  // ─── Filtre catégorie ─────────────────────────────────────────

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _CategoryChip(
            label: 'Toutes',
            icon: Icons.grid_view,
            selected: _categoryFilter == null,
            onTap: () => setState(() => _categoryFilter = null),
          ),
          ...BadgeCategory.displayOrder.map((cat) => _CategoryChip(
                label: cat.label,
                icon: cat.icon,
                selected: _categoryFilter == cat,
                onTap: () => setState(() => _categoryFilter = cat),
              )),
        ],
      ),
    );
  }

  // ─── Grille filtrée ───────────────────────────────────────────

  Widget _buildFilteredGrid() {
    final filtered = <Badge>[];

    for (final badge in Badges.all) {
      // Filtre catégorie
      if (_categoryFilter != null && badge.category != _categoryFilter) {
        continue;
      }

      // Filtre statut
      final ub = _userBadges[badge.id];
      final isUnlocked = badge.isUnlocked(ub);
      final isInProgress = !isUnlocked && (ub?.progress ?? 0) > 0;

      switch (_statusFilter) {
        case BadgeStatusFilter.all:
          break;
        case BadgeStatusFilter.unlocked:
          if (!isUnlocked) continue;
          break;
        case BadgeStatusFilter.inProgress:
          if (!isInProgress) continue;
          break;
        case BadgeStatusFilter.locked:
          if (isUnlocked || isInProgress) continue;
          break;
      }

      filtered.add(badge);
    }

    if (filtered.isEmpty) {
      return _buildEmptyFilter();
    }

    return BadgeGrid(
      badges: filtered,
      userBadges: _userBadges,
      onBadgeTap: (badge, ub) {
        if (badge.isUnlocked(ub) || (ub?.progress ?? 0) > 0) {
          // Débloqué ou en cours → bottom sheet détail
          BadgeDetailSheet.show(
            context,
            badge: badge,
            userBadge: ub,
            allUserBadges: _userBadges,
          );
        } else {
          // Verrouillé → snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Continue à utiliser ExamBoost pour découvrir ce badge !',
              ),
              backgroundColor: AppColors.textSecondary,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }

  Widget _buildEmptyFilter() {
    return Container(
      padding: const EdgeInsets.all(48),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: AppColors.textDisabled,
          ),
          const SizedBox(height: 12),
          Text(
            'Aucun badge ne correspond à ce filtre.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Essaie un autre filtre ou continue à réviser !',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textDisabled,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Header stats ───────────────────────────────────────────────

class _HeaderStats extends StatelessWidget {
  const _HeaderStats({
    required this.unlockedCount,
    required this.totalCount,
    required this.totalXp,
    required this.globalProgress,
  });

  final int unlockedCount;
  final int totalCount;
  final int totalXp;
  final double globalProgress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
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
              const Icon(Icons.emoji_events,
                  color: Color(0xFFFFB300), size: 28),
              const SizedBox(width: 10),
              Text(
                'Ma collection',
                style: AppTextStyles.h3.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),

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
            'badges débloqués',
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
              value: globalProgress,
              minHeight: 10,
              backgroundColor: Colors.white24,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFFFB300)),
            ),
          ),
          const SizedBox(height: 14),

          // XP totale
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.stars,
                      color: Color(0xFFFFB300), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '$totalXp XP',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Text(
                '${(globalProgress * 100).round()} %',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Chip de catégorie ──────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.surface,
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.divider,
        ),
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.textPrimary,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 12,
        ),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
