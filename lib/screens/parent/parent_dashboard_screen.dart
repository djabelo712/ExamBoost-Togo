// lib/screens/parent/parent_dashboard_screen.dart
// Dashboard principal du module Parent.
//
// Structure :
//   - Header parent (avatar initiales + nom + email + badge premium +
//     bouton "Passer premium" si non premium)
//   - 4 KPI cards globaux (enfants liés, moyenne globale, alertes non
//     lues, messages non lus)
//   - TabBar 4 onglets : Enfants / Progression / Alertes / Messages
//   - L'onglet "Premium" n'existe pas — l'écran de paiement est séparé
//     (parent_payment_screen.dart) accessible via le bouton header.
//
// Données : ParentMockData (mock local). A brancher sur le backend
// FastAPI via ParentService.fetchChildren / fetchAlerts /
// fetchConversations (voir services/parent_service.dart).
//
// État : StatefulWidget local. Pour une v2, encapsuler dans un
// ChangeNotifier ParentProvider consommé par les 4 onglets.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/adaptive_colors.dart';
import '../../theme/app_theme.dart';
import 'parent_alerts_tab.dart';
import 'parent_children_tab.dart';
import 'parent_messages_tab.dart';
import 'parent_progress_tab.dart';
import 'services/parent_service.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // ─── État ──────────────────────────────────────────────────────
  ParentAccount _parent = ParentMockData.defaultParent;
  List<Child> _children = ParentMockData.children;
  List<ParentAlert> _alerts = ParentMockData.alerts;
  List<Conversation> _conversations = ParentMockData.conversations;

  // ID de l'enfant sélectionné dans l'onglet Progression. Permet à
  // l'onglet Enfants de pré-sélectionner un enfant quand on tap sur
  // sa carte.
  String? _selectedChildId;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _selectedChildId = _children.isNotEmpty ? _children.first.id : null;
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── Chargement initial (mock) ─────────────────────────────────
  Future<void> _loadData() async {
    final children = await ParentService.fetchChildren(_parent.id);
    final alerts = await ParentService.fetchAlerts(_parent.id);
    final conversations = await ParentService.fetchConversations(_parent.id);
    if (!mounted) return;
    setState(() {
      _children = children;
      _alerts = alerts;
      _conversations = conversations;
      _selectedChildId =
          children.isNotEmpty ? children.first.id : null;
      _loading = false;
    });
  }

  // ─── Sélection d'un enfant (depuis l'onglet Enfants) ───────────
  void _selectChild(String childId) {
    setState(() => _selectedChildId = childId);
    _tabController.animateTo(1); // bascule vers l'onglet Progression
  }

  // ─── Marquer une alerte comme lue ──────────────────────────────
  Future<void> _markAlertRead(String alertId) async {
    await ParentService.markAlertRead(alertId);
    if (!mounted) return;
    setState(() {
      _alerts = _alerts
          .map((a) => a.id == alertId ? ParentAlert(
            id: a.id,
            type: a.type,
            childId: a.childId,
            childName: a.childName,
            titre: a.titre,
            description: a.description,
            date: a.date,
            lue: true,
          ) : a)
          .toList();
    });
  }

  // ─── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header parent ────────────────────────────────
            _buildHeader(),

            // ─── KPI globaux ──────────────────────────────────
            _buildKpiRow(),

            // ─── TabBar ───────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: AdaptiveColors.surface(context),
                border: Border(
                  bottom: BorderSide(
                      color: AdaptiveColors.divider(context), width: 1),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: AdaptiveColors.primary(context),
                unselectedLabelColor: AdaptiveColors.textSecondary(context),
                indicatorColor: AdaptiveColors.primary(context),
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: AppTextStyles.label.copyWith(fontSize: 13),
                tabs: const [
                  Tab(icon: Icon(Icons.family_restroom_outlined), text: 'Enfants'),
                  Tab(icon: Icon(Icons.trending_up), text: 'Progression'),
                  Tab(icon: Icon(Icons.notifications_active_outlined), text: 'Alertes'),
                  Tab(icon: Icon(Icons.chat_bubble_outline), text: 'Messages'),
                ],
              ),
            ),

            // ─── Contenu des onglets ──────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        ChildrenTab(
                          children: _children,
                          parent: _parent,
                          onChildTap: _selectChild,
                        ),
                        ProgressTab(
                          children: _children,
                          selectedChildId: _selectedChildId,
                          onChildChanged: (id) =>
                              setState(() => _selectedChildId = id),
                        ),
                        AlertsTab(
                          alerts: _alerts,
                          onMarkRead: _markAlertRead,
                        ),
                        MessagesTab(conversations: _conversations),
                      ],
                    ),
            ),
          ],
        ),
      ),
      // ─── FAB : accès rapide paiement premium ────────────────
      floatingActionButton: !_parent.isPremium
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/parent/payment'),
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.workspace_premium_outlined),
              label: const Text('Passer premium'),
            )
          : null,
    );
  }

  // ─── Header parent ─────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      color: AdaptiveColors.surface(context),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 26,
            backgroundColor: AdaptiveColors.primary(context),
            child: Text(
              _parent.initiales,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Nom + email + statut
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour, ${_parent.prenom}',
                  style: AppTextStyles.h3.copyWith(
                      color: AdaptiveColors.textPrimary(context)),
                ),
                const SizedBox(height: 2),
                Text(
                  _parent.email,
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AdaptiveColors.textSecondary(context)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Badge premium
          if (_parent.isPremium)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accent, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.workspace_premium,
                      size: 14, color: AppColors.accent),
                  const SizedBox(width: 4),
                  Text(
                    'Premium',
                    style: AppTextStyles.label
                        .copyWith(color: AppColors.accent),
                  ),
                ],
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: () => context.go('/parent/payment'),
              icon: const Icon(Icons.workspace_premium_outlined, size: 16),
              label: const Text('Premium'),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                textStyle: AppTextStyles.label,
              ),
            ),
        ],
      ),
    );
  }

  // ─── KPI row (4 cartes) ────────────────────────────────────────
  Widget _buildKpiRow() {
    final moyenneGlobale = _children.isEmpty
        ? 0
        : (_children.map((c) => c.scoreGlobal).reduce((a, b) => a + b) ~/
            _children.length);
    final alertesNonLues = _alerts.where((a) => !a.lue).length;
    final messagesNonLus =
        _conversations.fold<int>(0, (a, c) => a + c.nonLus);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: _kpiCard(
              icon: Icons.child_care,
              iconColor: AppColors.primary,
              value: '${_children.length}',
              label: 'Enfant(s) lié(s)',
            ),
          ),
          Expanded(
            child: _kpiCard(
              icon: Icons.insights,
              iconColor: AppColors.info,
              value: '$moyenneGlobale%',
              label: 'Moyenne globale',
            ),
          ),
          Expanded(
            child: _kpiCard(
              icon: Icons.warning_amber_rounded,
              iconColor: alertesNonLues > 0
                  ? AppColors.warning
                  : AppColors.success,
              value: '$alertesNonLues',
              label: 'Alerte(s)',
            ),
          ),
          Expanded(
            child: _kpiCard(
              icon: Icons.mark_chat_unread_outlined,
              iconColor: messagesNonLus > 0
                  ? AppColors.accent
                  : AppColors.textSecondary,
              value: '$messagesNonLus',
              label: 'Message(s)',
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AdaptiveColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AdaptiveColors.shadowColor(context),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: AppTextStyles.h3.copyWith(
                  color: AdaptiveColors.textPrimary(context),
                  fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
                color: AdaptiveColors.textSecondary(context), fontSize: 11),
          ),
        ],
      ),
    );
  }
}
