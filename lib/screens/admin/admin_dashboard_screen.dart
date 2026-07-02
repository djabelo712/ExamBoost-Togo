// lib/screens/admin/admin_dashboard_screen.dart
// Dashboard B2B "Directeur d'établissement"
//
// Vue agrégée de l'activité des élèves sur la licence ExamBoost de
// l'établissement (100 000 FCFA/an). Sert au pilotage pédagogique :
//   - identifier les élèves en décrochage,
//   - suivre la progression par trimestre,
//   - déclencher des recommandations automatiques.
//
// Structure :
//   - Header établissement (logo, nom, type, effectif, statut licence)
//   - 4 KPI cards (élèves actifs, temps moyen, maîtrise, amélioration)
//   - TabBar 3 onglets : Élèves / Alertes / Rapports
//
// Données : 100% mock local (voir AdminMockData ci-dessous).
// A brancher plus tard sur GET /admin/dashboard (voir README.md).

import 'package:flutter/material.dart';

import '../../theme/adaptive_colors.dart';
import '../../theme/app_theme.dart';
import 'students_tab.dart';
import 'alerts_tab.dart';
import 'reports_tab.dart';

// ══════════════════════════════════════════════════════════════════
// MODÈLES DE DONNÉES (mock)
// ══════════════════════════════════════════════════════════════════

/// Statut d'activité d'un élève pour le suivi directeurs.
enum StudentStatus { actif, modere, inactif }

/// Élève agrégé tel que vu par un directeur (différent de AppUser
/// qui est l'entité utilisée côté élève).
class AdminStudent {
  final String id;
  final String prenom;
  final String nom;
  final String classe;
  final int scoreGlobal; // 0-100
  final int streakDays;
  final int daysSinceLastActive; // 0 = aujourd'hui
  final StudentStatus status;

  // Détails affichés dans le dialog "Voir profil"
  final List<String> competencesFortes;
  final List<String> competencesFaibles;
  final int simulationsDone;
  final int simulationsAvgScore;

  const AdminStudent({
    required this.id,
    required this.prenom,
    required this.nom,
    required this.classe,
    required this.scoreGlobal,
    required this.streakDays,
    required this.daysSinceLastActive,
    required this.status,
    this.competencesFortes = const [],
    this.competencesFaibles = const [],
    this.simulationsDone = 0,
    this.simulationsAvgScore = 0,
  });

  String get nomComplet => '$prenom $nom';

  String get initiales {
    final i1 = prenom.isNotEmpty ? prenom[0].toUpperCase() : '';
    final i2 = nom.isNotEmpty ? nom[0].toUpperCase() : '';
    return '$i1$i2';
  }

  String get derniereActiviteLabel {
    if (daysSinceLastActive == 0) return 'Aujourd\'hui';
    if (daysSinceLastActive == 1) return 'Hier';
    return 'Il y a $daysSinceLastActive jours';
  }
}

/// Catégorie d'alerte élève.
enum AlertType { decrochage, chuteScore, competenceBloquee }

/// Alerte pédagogique levée pour un élève.
class AdminAlert {
  final String id;
  final String prenom;
  final String nom;
  final String classe;
  final AlertType type;
  final String description;

  const AdminAlert({
    required this.id,
    required this.prenom,
    required this.nom,
    required this.classe,
    required this.type,
    required this.description,
  });

  String get nomComplet => '$prenom $nom';
}

// ══════════════════════════════════════════════════════════════════
// MOCK DATA — 30 élèves + 8 alertes
// ══════════════════════════════════════════════════════════════════

class AdminMockData {
  // ─── Établissement (mock) ──────────────────────────────────────
  static const String etablissementNom = 'Lycée de Tokoin';
  static const String etablissementType = 'Public';
  static const int effectifTotal = 1250;
  static const String licenceStatut = 'Actif jusqu\'au 31/12/2026';

  // ─── KPI (mock) ────────────────────────────────────────────────
  static const int elevesActifsMois = 847;
  static const String tempsMoyenMois = '4h 32min';
  static const int tauxMaitriseMoyen = 54;
  static const int ameliorationNotes = 12; // points

  // ─── 30 élèves ─────────────────────────────────────────────────
  static List<AdminStudent> get students => const [
        // 3e A (8)
        AdminStudent(
          id: 's01', prenom: 'Kossi', nom: 'Mensah', classe: '3e A',
          scoreGlobal: 78, streakDays: 12, daysSinceLastActive: 0,
          status: StudentStatus.actif,
          competencesFortes: ['Calcul fractionnaire', 'Théorème de Pythagore'],
          competencesFaibles: ['Statistiques'],
          simulationsDone: 4, simulationsAvgScore: 76,
        ),
        AdminStudent(
          id: 's02', prenom: 'Aya', nom: 'Agbodjan', classe: '3e A',
          scoreGlobal: 65, streakDays: 5, daysSinceLastActive: 1,
          status: StudentStatus.actif,
          competencesFortes: ['Calcul littéral'],
          competencesFaibles: ['Théorème de Thalès'],
          simulationsDone: 2, simulationsAvgScore: 62,
        ),
        AdminStudent(
          id: 's03', prenom: 'Komlan', nom: 'Kpedetor', classe: '3e A',
          scoreGlobal: 52, streakDays: 3, daysSinceLastActive: 2,
          status: StudentStatus.actif,
          competencesFortes: [],
          competencesFaibles: ['Équations 1er degré', 'Thalès'],
          simulationsDone: 1, simulationsAvgScore: 48,
        ),
        AdminStudent(
          id: 's04', prenom: 'Adjo', nom: 'Aziabou', classe: '3e A',
          scoreGlobal: 81, streakDays: 18, daysSinceLastActive: 0,
          status: StudentStatus.actif,
          competencesFortes: ['Pythagore', 'Thalès', 'Calcul littéral'],
          competencesFaibles: [],
          simulationsDone: 6, simulationsAvgScore: 82,
        ),
        AdminStudent(
          id: 's05', prenom: 'Yao', nom: 'Ameganvi', classe: '3e A',
          scoreGlobal: 45, streakDays: 0, daysSinceLastActive: 4,
          status: StudentStatus.modere,
          competencesFortes: [],
          competencesFaibles: ['Théorème de Thalès', 'Statistiques'],
          simulationsDone: 1, simulationsAvgScore: 42,
        ),
        AdminStudent(
          id: 's06', prenom: 'Akossiwa', nom: 'Lawson', classe: '3e A',
          scoreGlobal: 70, streakDays: 7, daysSinceLastActive: 1,
          status: StudentStatus.actif,
          competencesFortes: ['Pythagore'],
          competencesFaibles: ['Statistiques'],
          simulationsDone: 3, simulationsAvgScore: 68,
        ),
        AdminStudent(
          id: 's07', prenom: 'Kofi', nom: 'Agbo', classe: '3e A',
          scoreGlobal: 58, streakDays: 2, daysSinceLastActive: 3,
          status: StudentStatus.modere,
          competencesFortes: ['Calcul fractionnaire'],
          competencesFaibles: ['Équations 1er degré'],
          simulationsDone: 2, simulationsAvgScore: 55,
        ),
        AdminStudent(
          id: 's08', prenom: 'Afi', nom: 'Adjovi', classe: '3e A',
          scoreGlobal: 35, streakDays: 0, daysSinceLastActive: 9,
          status: StudentStatus.inactif,
          competencesFortes: [],
          competencesFaibles: ['Thalès', 'Équations 1er degré', 'Statistiques'],
          simulationsDone: 0, simulationsAvgScore: 0,
        ),

        // 3e B (8)
        AdminStudent(
          id: 's09', prenom: 'Mawunyo', nom: 'd\'Almeida', classe: '3e B',
          scoreGlobal: 62, streakDays: 8, daysSinceLastActive: 1,
          status: StudentStatus.actif,
          competencesFortes: ['Calcul littéral'],
          competencesFaibles: ['Thalès'],
          simulationsDone: 2, simulationsAvgScore: 60,
        ),
        AdminStudent(
          id: 's10', prenom: 'Edem', nom: 'Dosseh', classe: '3e B',
          scoreGlobal: 75, streakDays: 14, daysSinceLastActive: 0,
          status: StudentStatus.actif,
          competencesFortes: ['Pythagore', 'Thalès'],
          competencesFaibles: ['Statistiques'],
          simulationsDone: 5, simulationsAvgScore: 74,
        ),
        AdminStudent(
          id: 's11', prenom: 'Sena', nom: 'Akolly', classe: '3e B',
          scoreGlobal: 48, streakDays: 1, daysSinceLastActive: 5,
          status: StudentStatus.modere,
          competencesFortes: [],
          competencesFaibles: ['Équations 1er degré', 'Statistiques'],
          simulationsDone: 1, simulationsAvgScore: 45,
        ),
        AdminStudent(
          id: 's12', prenom: 'Delali', nom: 'Sewa', classe: '3e B',
          scoreGlobal: 80, streakDays: 20, daysSinceLastActive: 0,
          status: StudentStatus.actif,
          competencesFortes: ['Pythagore', 'Thalès', 'Statistiques'],
          competencesFaibles: [],
          simulationsDone: 6, simulationsAvgScore: 79,
        ),
        AdminStudent(
          id: 's13', prenom: 'Kossiwa', nom: 'Tetey', classe: '3e B',
          scoreGlobal: 33, streakDays: 0, daysSinceLastActive: 12,
          status: StudentStatus.inactif,
          competencesFortes: [],
          competencesFaibles: ['Équations 1er degré', 'Thalès'],
          simulationsDone: 0, simulationsAvgScore: 0,
        ),
        AdminStudent(
          id: 's14', prenom: 'Mawuko', nom: 'Ayeva', classe: '3e B',
          scoreGlobal: 56, streakDays: 4, daysSinceLastActive: 2,
          status: StudentStatus.actif,
          competencesFortes: ['Calcul fractionnaire'],
          competencesFaibles: ['Équations 1er degré'],
          simulationsDone: 2, simulationsAvgScore: 54,
        ),
        AdminStudent(
          id: 's15', prenom: 'Ama', nom: 'Komi', classe: '3e B',
          scoreGlobal: 68, streakDays: 6, daysSinceLastActive: 1,
          status: StudentStatus.actif,
          competencesFortes: ['Thalès'],
          competencesFaibles: ['Statistiques'],
          simulationsDone: 3, simulationsAvgScore: 65,
        ),
        AdminStudent(
          id: 's16', prenom: 'Aya', nom: 'Koffi', classe: '3e B',
          scoreGlobal: 42, streakDays: 0, daysSinceLastActive: 8,
          status: StudentStatus.inactif,
          competencesFortes: [],
          competencesFaibles: ['Équations 1er degré', 'Statistiques'],
          simulationsDone: 1, simulationsAvgScore: 38,
        ),

        // Terminale C (8)
        AdminStudent(
          id: 's17', prenom: 'Kossi', nom: 'Agbodjan', classe: 'Terminale C',
          scoreGlobal: 84, streakDays: 21, daysSinceLastActive: 0,
          status: StudentStatus.actif,
          competencesFortes: ['Limites', 'Dérivées', 'Intégrales', 'Suites'],
          competencesFaibles: [],
          simulationsDone: 8, simulationsAvgScore: 83,
        ),
        AdminStudent(
          id: 's18', prenom: 'Komlan', nom: 'Mensah', classe: 'Terminale C',
          scoreGlobal: 72, streakDays: 10, daysSinceLastActive: 1,
          status: StudentStatus.actif,
          competencesFortes: ['Suites', 'Dérivées'],
          competencesFaibles: ['Intégrales'],
          simulationsDone: 5, simulationsAvgScore: 70,
        ),
        AdminStudent(
          id: 's19', prenom: 'Adjo', nom: 'Lawson', classe: 'Terminale C',
          scoreGlobal: 60, streakDays: 5, daysSinceLastActive: 2,
          status: StudentStatus.actif,
          competencesFortes: ['Dérivées'],
          competencesFaibles: ['Intégrales', 'Limites'],
          simulationsDone: 3, simulationsAvgScore: 58,
        ),
        AdminStudent(
          id: 's20', prenom: 'Yao', nom: 'Kpedetor', classe: 'Terminale C',
          scoreGlobal: 50, streakDays: 2, daysSinceLastActive: 4,
          status: StudentStatus.modere,
          competencesFortes: [],
          competencesFaibles: ['Limites', 'Intégrales'],
          simulationsDone: 2, simulationsAvgScore: 47,
        ),
        AdminStudent(
          id: 's21', prenom: 'Akossiwa', nom: 'Aziabou', classe: 'Terminale C',
          scoreGlobal: 38, streakDays: 0, daysSinceLastActive: 11,
          status: StudentStatus.inactif,
          competencesFortes: [],
          competencesFaibles: ['Limites', 'Dérivées', 'Intégrales', 'Suites'],
          simulationsDone: 0, simulationsAvgScore: 0,
        ),
        AdminStudent(
          id: 's22', prenom: 'Kofi', nom: 'Ameganvi', classe: 'Terminale C',
          scoreGlobal: 67, streakDays: 7, daysSinceLastActive: 1,
          status: StudentStatus.actif,
          competencesFortes: ['Suites'],
          competencesFaibles: ['Intégrales'],
          simulationsDone: 3, simulationsAvgScore: 64,
        ),
        AdminStudent(
          id: 's23', prenom: 'Afi', nom: 'd\'Almeida', classe: 'Terminale C',
          scoreGlobal: 55, streakDays: 3, daysSinceLastActive: 3,
          status: StudentStatus.modere,
          competencesFortes: [],
          competencesFaibles: ['Limites'],
          simulationsDone: 2, simulationsAvgScore: 52,
        ),
        AdminStudent(
          id: 's24', prenom: 'Mawunyo', nom: 'Dosseh', classe: 'Terminale C',
          scoreGlobal: 73, streakDays: 9, daysSinceLastActive: 0,
          status: StudentStatus.actif,
          competencesFortes: ['Limites', 'Dérivées'],
          competencesFaibles: ['Suites'],
          simulationsDone: 4, simulationsAvgScore: 71,
        ),

        // Terminale D (6)
        AdminStudent(
          id: 's25', prenom: 'Edem', nom: 'Akolly', classe: 'Terminale D',
          scoreGlobal: 79, streakDays: 15, daysSinceLastActive: 0,
          status: StudentStatus.actif,
          competencesFortes: ['Genétique', 'Immunologie'],
          competencesFaibles: [],
          simulationsDone: 6, simulationsAvgScore: 78,
        ),
        AdminStudent(
          id: 's26', prenom: 'Sena', nom: 'Sewa', classe: 'Terminale D',
          scoreGlobal: 64, streakDays: 6, daysSinceLastActive: 1,
          status: StudentStatus.actif,
          competencesFortes: ['Géologie'],
          competencesFaibles: ['Immunologie'],
          simulationsDone: 3, simulationsAvgScore: 62,
        ),
        AdminStudent(
          id: 's27', prenom: 'Delali', nom: 'Tetey', classe: 'Terminale D',
          scoreGlobal: 47, streakDays: 1, daysSinceLastActive: 6,
          status: StudentStatus.modere,
          competencesFortes: [],
          competencesFaibles: ['Genétique', 'Immunologie'],
          simulationsDone: 1, simulationsAvgScore: 44,
        ),
        AdminStudent(
          id: 's28', prenom: 'Kossiwa', nom: 'Ayeva', classe: 'Terminale D',
          scoreGlobal: 28, streakDays: 0, daysSinceLastActive: 10,
          status: StudentStatus.inactif,
          competencesFortes: [],
          competencesFaibles: ['Équations 1er degré', 'Genétique', 'Immunologie'],
          simulationsDone: 0, simulationsAvgScore: 0,
        ),
        AdminStudent(
          id: 's29', prenom: 'Mawuko', nom: 'Komi', classe: 'Terminale D',
          scoreGlobal: 71, streakDays: 11, daysSinceLastActive: 1,
          status: StudentStatus.actif,
          competencesFortes: ['Genétique'],
          competencesFaibles: ['Géologie'],
          simulationsDone: 4, simulationsAvgScore: 69,
        ),
        AdminStudent(
          id: 's30', prenom: 'Ama', nom: 'Koffi', classe: 'Terminale D',
          scoreGlobal: 53, streakDays: 4, daysSinceLastActive: 2,
          status: StudentStatus.actif,
          competencesFortes: [],
          competencesFaibles: ['Immunologie'],
          simulationsDone: 2, simulationsAvgScore: 50,
        ),
      ];

  // ─── 8 alertes ─────────────────────────────────────────────────
  static List<AdminAlert> get alerts => const [
        // 3 rouges : décrochage (non connexion 7+ jours)
        AdminAlert(
          id: 'a01', prenom: 'Afi', nom: 'Adjovi', classe: '3e A',
          type: AlertType.decrochage,
          description: 'Aucune connexion depuis 9 jours. Risque de '
              'décrochage scolaire élevé.',
        ),
        AdminAlert(
          id: 'a02', prenom: 'Kossiwa', nom: 'Tetey', classe: '3e B',
          type: AlertType.decrochage,
          description: 'Aucune connexion depuis 12 jours. Aucune simulation '
              'réalisée ce trimestre.',
        ),
        AdminAlert(
          id: 'a03', prenom: 'Akossiwa', nom: 'Aziabou',
          classe: 'Terminale C',
          type: AlertType.decrochage,
          description: 'Aucune connexion depuis 11 jours. Période critique '
              'à 4 mois du BAC.',
        ),

        // 3 oranges : chute de score
        AdminAlert(
          id: 'a04', prenom: 'Sena', nom: 'Akolly', classe: '3e B',
          type: AlertType.chuteScore,
          description: 'Chute de -14 points sur les 30 derniers jours '
              '(62% -> 48%).',
        ),
        AdminAlert(
          id: 'a05', prenom: 'Aya', nom: 'Koffi', classe: '3e B',
          type: AlertType.chuteScore,
          description: 'Chute de -12 points sur les 30 derniers jours '
              '(54% -> 42%).',
        ),
        AdminAlert(
          id: 'a06', prenom: 'Mawuko', nom: 'Ayeva', classe: '3e B',
          type: AlertType.chuteScore,
          description: 'Chute de -11 points sur les 30 derniers jours '
              '(67% -> 56%).',
        ),

        // 2 jaunes : compétences bloquées
        AdminAlert(
          id: 'a07', prenom: 'Kossiwa', nom: 'Ayeva', classe: 'Terminale D',
          type: AlertType.competenceBloquee,
          description: 'Compétence « Équations 1er degré » bloquée à 22% '
              'depuis 3 semaines.',
        ),
        AdminAlert(
          id: 'a08', prenom: 'Yao', nom: 'Ameganvi', classe: '3e A',
          type: AlertType.competenceBloquee,
          description: 'Compétence « Théorème de Thalès » bloquée à 27% '
              'depuis 2 semaines.',
        ),
      ];

  // ─── Liste des classes distinctes ──────────────────────────────
  static List<String> get classes => const [
        '3e A', '3e B', 'Terminale C', 'Terminale D',
      ];
}

// ══════════════════════════════════════════════════════════════════
// ÉCRAN PRINCIPAL
// ══════════════════════════════════════════════════════════════════

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
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
        title: const Text('Espace Directeur'),
        backgroundColor: AdaptiveColors.surface(context),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_none_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('12 nouvelles alertes élèves en attente.'),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Déconnexion',
            icon: const Icon(Icons.logout_outlined),
            onPressed: () => _confirmLogout(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _buildTabBar(),
        ),
      ),
      body: Column(
        children: [
          // ─── Header + KPI (scroll horizontal si étroit) ─────────
          _buildHeaderSection(),
          // ─── Contenu des onglets ───────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                StudentsTab(),
                AlertsTab(),
                ReportsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── TabBar ────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: AdaptiveColors.surface(context),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AdaptiveColors.textSecondary(context),
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        tabs: const [
          Tab(text: 'Élèves'),
          Tab(text: 'Alertes'),
          Tab(text: 'Rapports'),
        ],
      ),
    );
  }

  // ─── Header établissement + 4 KPI ──────────────────────────────
  Widget _buildHeaderSection() {
    return Container(
      color: AdaptiveColors.surface(context),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSchoolHeader(),
          const SizedBox(height: 16),
          _buildKpiGrid(),
        ],
      ),
    );
  }

  Widget _buildSchoolHeader() {
    return Row(
      children: [
        // Logo établissement
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AdaptiveColors.primarySurface(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primaryLight, width: 1),
          ),
          child: const Icon(Icons.school, color: AppColors.primary, size: 32),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AdminMockData.etablissementNom,
                style: AppTextStyles.h2.copyWith(
                    color: AdaptiveColors.textPrimary(context)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _buildChip(
                    AdminMockData.etablissementType,
                    AdaptiveColors.primarySurface(context),
                    AdaptiveColors.primary(context),
                  ),
                  _buildChip(
                    '${AdminMockData.effectifTotal} élèves',
                    AdaptiveColors.surfaceVariant(context),
                    AdaptiveColors.textSecondary(context),
                  ),
                  _buildChip(
                    AdminMockData.licenceStatut,
                    AdaptiveColors.primarySurface(context),
                    AppColors.success,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Bouton renouveler (UI seulement)
        OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Redirection vers la page de renouvellement de licence '
                  '(à brancher sur /billing/renew).',
                ),
              ),
            );
          },
          icon: const Icon(Icons.autorenew, size: 18),
          label: const Text('Renouveler'),
        ),
      ],
    );
  }

  Widget _buildChip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ─── 4 KPI cards en row (responsive 4 / 2 colonnes) ───────────
  Widget _buildKpiGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Largeur ≥ 720 : 4 colonnes ; sinon 2 colonnes
        final crossCount = constraints.maxWidth >= 720 ? 4 : 2;
        final spacing = 12.0;
        final width = (constraints.maxWidth -
                spacing * (crossCount - 1)) /
            crossCount;

        final kpis = <_KpiCardData>[
          _KpiCardData(
            title: 'Élèves actifs / mois',
            value: '${AdminMockData.elevesActifsMois}',
            subtitle:
                '/ ${AdminMockData.effectifTotal} (${(AdminMockData.elevesActifsMois * 100 / AdminMockData.effectifTotal).round()}%)',
            icon: Icons.group_outlined,
            color: AppColors.primary,
          ),
          _KpiCardData(
            title: 'Temps moyen / élève',
            value: AdminMockData.tempsMoyenMois,
            subtitle: 'par mois',
            icon: Icons.schedule_outlined,
            color: AppColors.info,
          ),
          _KpiCardData(
            title: 'Taux de maîtrise moyen',
            value: '${AdminMockData.tauxMaitriseMoyen}%',
            subtitle: 'toutes classes',
            icon: Icons.trending_up_outlined,
            color: AppColors.accent,
          ),
          _KpiCardData(
            title: 'Amélioration notes',
            value: '+${AdminMockData.ameliorationNotes} pts',
            subtitle: 'vs trimestre précédent',
            icon: Icons.arrow_upward_outlined,
            color: AppColors.success,
          ),
        ];

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: kpis
              .map((kpi) => SizedBox(
                    width: width,
                    child: _buildKpiCard(kpi),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildKpiCard(_KpiCardData data) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdaptiveColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdaptiveColors.divider(context), width: 1),
        boxShadow: [
          BoxShadow(
            color: AdaptiveColors.shadow(context),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(data.icon, size: 18, color: data.color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  data.title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AdaptiveColors.textSecondary(context),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            data.value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AdaptiveColors.textPrimary(context),
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.subtitle,
            style: TextStyle(
              fontSize: 11,
              color: AdaptiveColors.textSecondary(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ─── Confirmation déconnexion ──────────────────────────────────
  void _confirmLogout() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text(
            'Voulez-vous vraiment vous déconnecter de l\'espace directeur ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // Retour à l'écran de login directeur
              // (l'agent principal câblera la route /admin/login)
              Navigator.of(context).maybePop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }
}

// ─── DTO interne pour les KPI cards ──────────────────────────────
class _KpiCardData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _KpiCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}
