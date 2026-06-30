// lib/screens/dashboard/dashboard_screen.dart
// Tableau de bord élève — visualisation de la progression (BKT + IRT + SRS)
//
// Sections affichées (SingleChildScrollView) :
//   1. Header personnalisé (avatar + prénom + date + streak)
//   2. Score global de maîtrise (CircularPercentIndicator + prédiction BEPC)
//   3. Progression par matière (LinearPercentIndicator, tap -> révision)
//   4. Heatmap des chapitres faibles (top 5 P(L) les plus bas)
//   5. Statistiques SRS (dueToday / mastered / learning)
//   6. Activité des 7 derniers jours (LineChart fl_chart)
//   7. Actions rapides (Réviser / Examen blanc)
//
// Données : AppUser (Hive box "users") + ReviewCard (Hive box "review_cards")
// Identité : SharedPreferences "current_user_id" (défaut : "user_demo")

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/question.dart';
import '../../models/review_card.dart';
import '../../models/user.dart';
import '../../services/question_service.dart';
import '../../services/srs_service.dart';
import '../../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ─── État ──────────────────────────────────────────────────────
  AppUser? _user;
  List<ReviewCard> _cards = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // Chargement différé hors du build
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUserData());
  }

  // ─── Chargement AppUser + ReviewCards ──────────────────────────
  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('current_user_id') ?? 'user_demo';

      // Lecture (ou ouverture) de la Hive box "users"
      final userBox = Hive.isBoxOpen('users')
          ? Hive.box<AppUser>('users')
          : await Hive.openBox<AppUser>('users');

      AppUser? user;
      if (userBox.containsKey(userId)) {
        user = userBox.get(userId);
      }
      // Fallback : user démo vide si l'élève n'existe pas encore
      user ??= AppUser(
        id: userId,
        nom: 'Élève',
        prenom: 'Élève',
        niveauScolaire: '3eme',
        dateInscription: DateTime.now(),
      );

      // Lecture (ou ouverture) de la Hive box "review_cards"
      final cardBox = Hive.isBoxOpen('review_cards')
          ? Hive.box<ReviewCard>('review_cards')
          : await Hive.openBox<ReviewCard>('review_cards');
      final cards =
          cardBox.values.where((c) => c.userId == userId).toList();

      if (mounted) {
        setState(() {
          _user = user;
          _cards = cards;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        automaticallyImplyLeading: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final user = _user!;
    final hasData =
        user.bktMaitrise.isNotEmpty || _cards.isNotEmpty;
    if (!hasData) return _buildEmptyState(context);

    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header personnalisé + streak
            _buildHeader(user),
            const SizedBox(height: 20),

            // 2. Score global de maîtrise + prédiction BEPC
            _buildScoreCard(user),
            const SizedBox(height: 20),

            // 3. Progression par matière
            _buildMatiereProgress(context, user),
            const SizedBox(height: 20),

            // 4. Heatmap des chapitres faibles
            _buildWeakChapters(context, user),
            const SizedBox(height: 20),

            // 5. Statistiques SRS (3 cartes en row)
            _buildSrsStats(context, user.id),
            const SizedBox(height: 20),

            // 6. Activité des 7 derniers jours (LineChart fl_chart)
            _buildWeeklyActivity(),
            const SizedBox(height: 20),

            // 7. Actions rapides
            _buildQuickActions(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ─── 1. Header personnalisé + streak ───────────────────────────
  Widget _buildHeader(AppUser user) {
    final prenom =
        (user.prenom.isNotEmpty ? user.prenom : 'Élève').trim();
    final init1 = prenom.isNotEmpty ? prenom[0].toUpperCase() : 'E';
    final init2 =
        user.nom.isNotEmpty ? user.nom[0].toUpperCase() : '';
    final initials = init2.isEmpty ? init1 : '$init1$init2';

    final streak = _computeStreak(_cards);
    final streakColor =
        streak >= 3 ? AppColors.accent : AppColors.textSecondary;

    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.primary,
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 20,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bonjour, $prenom !',
                style: AppTextStyles.h2,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                _formatToday(),
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
        // Badge streak (jours consécutifs de révision)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: streakColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_fire_department,
                  color: streakColor, size: 18),
              const SizedBox(width: 4),
              Text(
                '$streak j',
                style: AppTextStyles.label.copyWith(
                  color: streakColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── 2. Carte Score global + prédiction BEPC ──────────────────
  Widget _buildScoreCard(AppUser user) {
    final score = user.scoreGlobal; // 0-100
    final scoreColor = _scoreColor(score);
    final competencesCount = user.bktMaitrise.length;
    final bepcScore = _predictedBepcScore(user);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Text(
            'Score global de maîtrise',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textSecondary,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          CircularPercentIndicator(
            radius: 70,
            lineWidth: 12,
            percent: (score / 100).clamp(0.0, 1.0),
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${score.round()}%',
                  style: AppTextStyles.h1.copyWith(color: scoreColor),
                ),
                Text(
                  'maîtrise',
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                ),
              ],
            ),
            progressColor: scoreColor,
            backgroundColor: scoreColor.withOpacity(0.12),
            circularStrokeCap: CircularStrokeCap.round,
            animation: true,
            animationDuration: 800,
          ),
          const SizedBox(height: 14),
          Text(
            'Basé sur $competencesCount compétence${competencesCount > 1 ? "s" : ""} '
            'suivie${competencesCount > 1 ? "s" : ""}',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 10),
          // Prédiction score BEPC (mock : moyenne des P(L) × 20)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accentSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.school, color: AppColors.accent, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Prédiction score BEPC : ~${bepcScore.toStringAsFixed(1)}/20',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 3. Progression par matière ────────────────────────────────
  Widget _buildMatiereProgress(BuildContext context, AppUser user) {
    final qs = Provider.of<QuestionService>(context, listen: false);
    final matieres = qs.matieres;
    final maitrise = _maitriseByMatiere(user, qs);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Progression par matière', style: AppTextStyles.h3),
          const SizedBox(height: 14),
          if (maitrise.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Commence à réviser pour voir ta progression par matière.',
                style: AppTextStyles.bodySmall,
              ),
            )
          else
            ...maitrise.entries.map((e) {
              final percent = (e.value * 100).clamp(0, 100);
              final color = _scoreColor(percent);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => context.go(
                      '/revision/${Uri.encodeComponent(e.key)}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              e.key,
                              style: AppTextStyles.body,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${percent.round()}%',
                            style: AppTextStyles.label.copyWith(
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LinearPercentIndicator(
                        padding: EdgeInsets.zero,
                        lineHeight: 8,
                        percent: e.value.clamp(0.0, 1.0),
                        progressColor: color,
                        backgroundColor: color.withOpacity(0.12),
                        barRadius: const Radius.circular(6),
                        animation: true,
                        animationDuration: 700,
                      ),
                    ],
                  ),
                ),
              );
            }),
          // Matières disponibles non encore suivies
          if (matieres.where((m) => !maitrise.containsKey(m)).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Matières disponibles : ${matieres.join(", ")}',
                style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  // ─── 4. Carte de chaleur : chapitres faibles ──────────────────
  Widget _buildWeakChapters(BuildContext context, AppUser user) {
    final qs = Provider.of<QuestionService>(context, listen: false);
    final weak = _weakestChapters(user, qs, limit: 5);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.priority_high,
                  color: AppColors.error, size: 20),
              const SizedBox(width: 6),
              Text('Chapitres à travailler', style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 14),
          if (weak.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Continue à réviser pour voir tes points faibles !',
                style: AppTextStyles.bodySmall,
              ),
            )
          else
            ...weak.map((w) => _buildWeakChapterRow(context, w)),
        ],
      ),
    );
  }

  Widget _buildWeakChapterRow(BuildContext context, _WeakChapter w) {
    final percent = (w.pL * 100).clamp(0, 100);
    final color = _scoreColor(percent);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  w.chapitre,
                  style: AppTextStyles.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                LinearPercentIndicator(
                  padding: EdgeInsets.zero,
                  lineHeight: 5,
                  percent: w.pL.clamp(0.0, 1.0),
                  progressColor: color,
                  backgroundColor: color.withOpacity(0.15),
                  barRadius: const Radius.circular(4),
                  animation: true,
                  animationDuration: 700,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 84,
            child: TextButton(
              onPressed: () => context.go(
                  '/revision/${Uri.encodeComponent(w.matiere)}'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Réviser', style: AppTextStyles.button),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 5. Statistiques SRS (3 cartes en row) ────────────────────
  Widget _buildSrsStats(BuildContext context, String userId) {
    final srs = Provider.of<SrsService>(context, listen: false);
    final stats = srs.getStats(userId);

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.calendar_today,
            value: stats.dueToday,
            label: 'À réviser\naujourd\'hui',
            color: stats.dueToday > 0
                ? AppColors.error
                : AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            icon: Icons.check_circle,
            value: stats.mastered,
            label: 'Cartes\nmaîtrisées',
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            icon: Icons.school,
            value: stats.learning,
            label: 'En\napprentissage',
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required int value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: AppTextStyles.h2.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall
                .copyWith(fontSize: 11, height: 1.2),
          ),
        ],
      ),
    );
  }

  // ─── 6. Activité des 7 derniers jours (LineChart fl_chart) ────
  Widget _buildWeeklyActivity() {
    final counts = _computeWeeklyActivity(_cards);
    final maxVal = counts.fold<int>(0, (a, b) => a > b ? a : b);
    final hasActivity = counts.any((v) => v > 0);
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

    // Intervalle adaptatif pour l'axe Y (toujours des entiers lisibles)
    final yInterval = maxVal <= 5 ? 1.0 : (maxVal / 4).ceilToDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Activité de la semaine', style: AppTextStyles.h3),
          const SizedBox(height: 4),
          Text(
            'Questions répondues ces 7 derniers jours',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 16),
          if (!hasActivity)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.show_chart,
                        color: AppColors.textDisabled, size: 36),
                    const SizedBox(height: 8),
                    Text(
                      'Pas encore d\'activité cette semaine.\nCommence aujourd\'hui !',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 170,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: yInterval,
                    getDrawingHorizontalLine: (v) => FlLine(
                      color: AppColors.divider,
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: yInterval,
                        getTitlesWidget: (v, meta) {
                          // N'afficher que les entiers
                          if (v != v.floorToDouble()) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Text(
                              v.toInt().toString(),
                              style: AppTextStyles.bodySmall
                                  .copyWith(fontSize: 10),
                              textAlign: TextAlign.right,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        interval: 1,
                        getTitlesWidget: (v, meta) {
                          final i = v.toInt();
                          if (i < 0 || i >= days.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              days[i],
                              style: AppTextStyles.bodySmall
                                  .copyWith(fontSize: 11),
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  minY: 0,
                  maxY: (maxVal + 1).toDouble(),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (int i = 0; i < 7; i++)
                          FlSpot(i.toDouble(), counts[i].toDouble()),
                      ],
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, _, __, ___) =>
                            FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.primary,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withOpacity(0.12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── 7. Actions rapides ────────────────────────────────────────
  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => context.go(
                '/revision/${Uri.encodeComponent("Mathématiques")}'),
            icon: const Icon(Icons.menu_book, size: 20),
            label: const Text('Réviser'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => context.go('/simulation',
                extra: {'examen': 'BEPC', 'serie': null}),
            icon: const Icon(Icons.timer, size: 20),
            label: const Text('Examen blanc'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  // ─── État vide (nouvel utilisateur sans donnée) ────────────────
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.waving_hand,
                size: 72, color: AppColors.primary),
            const SizedBox(height: 24),
            Text('Bienvenue !', style: AppTextStyles.h1),
            const SizedBox(height: 8),
            Text(
              'Commence ta première révision pour voir tes statistiques '
              'apparaître ici.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.go(
                    '/revision/${Uri.encodeComponent("Mathématiques")}'),
                icon: const Icon(Icons.play_arrow, size: 22),
                label: const Text('Démarrer ma première révision'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers : calculs ML / SRS ────────────────────────────────

  /// Streak : nombre de jours consécutifs de révision.
  /// (Si pas révisé aujourd'hui, on remonte à hier pour ne pas casser
  /// une série en cours.)
  int _computeStreak(List<ReviewCard> cards) {
    final days = cards
        .where((c) => c.lastReviewDate != null)
        .map((c) => _dateOnly(c.lastReviewDate!))
        .toSet();
    if (days.isEmpty) return 0;

    var cursor = _dateOnly(DateTime.now());
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

  /// Activité hebdomadaire : nombre de questions répondues par jour
  /// (lundi→dimanche de la semaine en cours).
  List<int> _computeWeeklyActivity(List<ReviewCard> cards) {
    final today = _dateOnly(DateTime.now());
    // weekday : 1 = lundi, 7 = dimanche
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final counts = List<int>.filled(7, 0);
    for (final c in cards) {
      if (c.lastReviewDate == null) continue;
      final d = _dateOnly(c.lastReviewDate!);
      final diff = d.difference(monday).inDays;
      if (diff >= 0 && diff < 7) counts[diff]++;
    }
    return counts;
  }

  /// Moyenne de P(L) par matière (groupé via questionService).
  Map<String, double> _maitriseByMatiere(
      AppUser user, QuestionService qs) {
    final byMatiere = <String, List<double>>{};
    for (final entry in user.bktMaitrise.entries) {
      final questions = qs.getByCompetence(entry.key);
      if (questions.isEmpty) continue;
      final matiere = questions.first.matiere;
      byMatiere.putIfAbsent(matiere, () => []).add(entry.value);
    }
    final result = <String, double>{};
    byMatiere.forEach((m, vals) {
      result[m] = vals.reduce((a, b) => a + b) / vals.length;
    });
    return result;
  }

  /// Top N compétences avec P(L) le plus bas (avec chapitre + matière).
  List<_WeakChapter> _weakestChapters(
      AppUser user, QuestionService qs,
      {int limit = 5}) {
    final entries = user.bktMaitrise.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final result = <_WeakChapter>[];
    for (final e in entries.take(limit)) {
      final questions = qs.getByCompetence(e.key);
      if (questions.isEmpty) continue;
      final q = questions.first;
      result.add(_WeakChapter(
        competenceId: e.key,
        pL: e.value,
        chapitre: q.chapitre,
        matiere: q.matiere,
      ));
    }
    return result;
  }

  /// Prédiction mock du score BEPC : moyenne des P(L) × 20.
  double _predictedBepcScore(AppUser user) {
    if (user.bktMaitrise.isEmpty) return 0;
    final avg = user.bktMaitrise.values.reduce((a, b) => a + b) /
        user.bktMaitrise.length;
    return avg * 20;
  }

  // ─── Helpers : UI ──────────────────────────────────────────────

  /// Couleur sémantique selon le pourcentage de maîtrise (0-100).
  Color _scoreColor(double score) {
    if (score < 40) return AppColors.error;
    if (score <= 70) return AppColors.warning;
    return AppColors.success;
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Date du jour en français, formatée manuellement (sans dépendance intl).
  String _formatToday() {
    const days = [
      'lundi', 'mardi', 'mercredi', 'jeudi',
      'vendredi', 'samedi', 'dimanche',
    ];
    const months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
    ];
    final now = DateTime.now();
    return '${days[now.weekday - 1]} ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );
}

/// Modèle interne pour une ligne "chapitre faible" dans la heatmap.
class _WeakChapter {
  final String competenceId;
  final double pL;
  final String chapitre;
  final String matiere;
  const _WeakChapter({
    required this.competenceId,
    required this.pL,
    required this.chapitre,
    required this.matiere,
  });
}
