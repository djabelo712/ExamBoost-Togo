// lib/screens/homework/homework_list_screen.dart
// Liste des devoirs de l'élève (3 onglets : À faire / Terminés / Manqués).
//
// Affiche les devoirs assignés à l'élève courant (mock : "élève_moi" en 3e A).
// Pour chaque devoir, on lit sa soumission dans HomeworkService pour
// déterminer le statut et l'afficher dans le bon onglet.
//
// Tap sur une carte → navigue vers HomeworkDetailScreen (sauf pour les
// manqués où l'on peut toujours visualiser le devoir même si on ne peut
// plus le soumettre).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/adaptive_colors.dart';
import '../../theme/app_theme.dart';
import '../models/homework.dart';
import '../models/homework_submission.dart';
import '../services/homework_service.dart';
import 'homework_detail_screen.dart';
import 'widgets/homework_card.dart';

class HomeworkListScreen extends StatefulWidget {
  const HomeworkListScreen({super.key});

  @override
  State<HomeworkListScreen> createState() => _HomeworkListScreenState();
}

class _HomeworkListScreenState extends State<HomeworkListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes devoirs'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _buildTabBar(context),
        ),
      ),
      body: Consumer<HomeworkService>(
        builder: (context, service, _) {
          final homeworks = service.getHomeworksForCurrentEleve();

          // Partition par statut
          final aFaire = <_HomeworkWithSoumission>[];
          final termines = <_HomeworkWithSoumission>[];
          final manques = <_HomeworkWithSoumission>[];

          for (final hw in homeworks) {
            final sub = service.getSoumissionForCurrentEleve(hw.id);
            final statut = hw.statutPourEleve(
              aRendu: sub?.termine ?? false,
              enCours: sub?.enCours ?? false,
            );
            final entry = _HomeworkWithSoumission(homework: hw, soumission: sub);
            switch (statut) {
              case HomeworkStatus.aFaire:
                aFaire.add(entry);
                break;
              case HomeworkStatus.enCours:
                aFaire.add(entry); // en cours = à continuer
                break;
              case HomeworkStatus.rendu:
                termines.add(entry);
                break;
              case HomeworkStatus.manque:
                manques.add(entry);
                break;
            }
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(context, aFaire, 'à faire', isAFaire: true),
              _buildList(context, termines, 'terminé'),
              _buildList(context, manques, 'manqué'),
            ],
          );
        },
      ),
    );
  }

  // ─── TabBar ────────────────────────────────────────────────────
  Widget _buildTabBar(BuildContext context) {
    return Container(
      color: AdaptiveColors.surface(context),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AdaptiveColors.textSecondary(context),
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        tabs: const [
          Tab(text: 'À faire'),
          Tab(text: 'Terminés'),
          Tab(text: 'Manqués'),
        ],
      ),
    );
  }

  // ─── Liste filtrée ────────────────────────────────────────────
  Widget _buildList(
    BuildContext context,
    List<_HomeworkWithSoumission> items,
    String label, {
    bool isAFaire = false,
  }) {
    if (items.isEmpty) {
      return _buildEmptyState(context, label);
    }

    // Pour "À faire" : trie par deadline la plus proche en premier
    if (isAFaire) {
      items.sort((a, b) => a.homework.dateLimit.compareTo(b.homework.dateLimit));
    } else {
      // Pour terminés et manqués : plus récent en premier
      items.sort((a, b) => b.homework.dateLimit.compareTo(a.homework.dateLimit));
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Re-déclenche le rebuild via le Consumer
        context.read<HomeworkService>().notifyListeners();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final entry = items[index];
          return HomeworkCard(
            homework: entry.homework,
            soumission: entry.soumission,
            onTap: () => _ouvrirDetail(context, entry.homework.id),
          );
        },
      ),
    );
  }

  // ─── État vide ────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context, String label) {
    IconData icon;
    String message;
    switch (label) {
      case 'à faire':
        icon = Icons.check_circle_outline;
        message = 'Aucun devoir à faire. Profite-en pour réviser !';
        break;
      case 'terminé':
        icon = Icons.history;
        message = 'Tu n\'as pas encore rendu de devoir. Lance-toi !';
        break;
      case 'manqué':
        icon = Icons.check_circle;
        message = 'Aucun devoir manqué. Bravo !';
        break;
      default:
        icon = Icons.inbox;
        message = 'Aucun devoir.';
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AdaptiveColors.textSecondary(context)),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTextStyles.body.copyWith(
                color: AdaptiveColors.textSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _ouvrirDetail(BuildContext context, String homeworkId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HomeworkDetailScreen(homeworkId: homeworkId),
      ),
    );
  }
}

/// Tuple interne : homework + sa soumission par l'élève courant.
class _HomeworkWithSoumission {
  final Homework homework;
  final HomeworkSubmission? soumission;
  const _HomeworkWithSoumission({required this.homework, this.soumission});
}
