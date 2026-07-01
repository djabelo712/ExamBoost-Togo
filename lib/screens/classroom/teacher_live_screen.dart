// lib/screens/classroom/teacher_live_screen.dart
// Ecran enseignant : controle live d'une session classe.
//
// Affiche :
//   - Code session en grand (pour projection)
//   - Liste joueurs connectes (PlayerListWidget)
//   - Bouton "Demarrer le quiz"
//   - Pendant question :
//     * Question actuelle
//     * Stats temps reel : "X/Y eleves ont repondu"
//     * Bouton "Forcer question suivante"
//   - Between questions : classement live (top 5)
//   - Bouton "Terminer la session" -> TeacherResultsScreen
//
// Le service est injecte via ChangeNotifierProvider (cree par
// TeacherCreateScreen apres creation de la session).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_theme.dart';
import 'models/classroom_player.dart';
import 'models/classroom_session.dart';
import 'services/classroom_socket_service.dart';
import 'teacher_results_screen.dart';
import 'widgets/live_leaderboard.dart';
import 'widgets/player_list_widget.dart';
import 'widgets/timer_ring.dart';

class TeacherLiveScreen extends StatefulWidget {
  final String sessionCode;
  final List<String> questionIds;
  final ClassroomMode mode;

  const TeacherLiveScreen({
    super.key,
    required this.sessionCode,
    required this.questionIds,
    required this.mode,
  });

  @override
  State<TeacherLiveScreen> createState() => _TeacherLiveScreenState();
}

class _TeacherLiveScreenState extends State<TeacherLiveScreen> {
  @override
  Widget build(BuildContext context) {
    final service = context.watch<ClassroomSocketService>();
    final session = service.session;
    final isEnded = session?.isEnded == true || service.results != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Session en direct'),
        automaticallyImplyLeading: false,
        actions: [
          if (!isEnded)
            TextButton.icon(
              onPressed: () => _confirmEndSession(context),
              icon: const Icon(Icons.stop_circle, color: AppColors.error),
              label: const Text('Terminer',
                  style: TextStyle(color: AppColors.error)),
            ),
        ],
      ),
      body: SafeArea(
        child: isEnded
            ? _buildEndedView(context, service)
            : _buildLiveView(context, service, session),
      ),
    );
  }

  // ─── Vue live ──────────────────────────────────────────────────
  Widget _buildLiveView(
    BuildContext context,
    ClassroomSocketService service,
    ClassroomSession? session,
  ) {
    final isLive = session?.isLive == true;
    final hasCurrentQuestion = service.currentQuestion != null;
    final answeredCount = service.players
        .where((p) =>
            p.role == PlayerRole.student &&
            p.status == PlayerStatus.answered)
        .length;
    final totalStudents = service.players
        .where((p) => p.role == PlayerRole.student)
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Code session en grand
          _buildCodeHeader(service),
          const SizedBox(height: 16),

          // Statut joueurs
          _buildPlayersCount(service),
          const SizedBox(height: 16),

          if (!isLive) ...[
            // Salle d'attente : liste joueurs + bouton demarrer
            _buildWaitingSection(service),
            const SizedBox(height: 16),
            if (widget.mode == ClassroomMode.live)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: service.players
                          .where((p) =>
                              p.role == PlayerRole.student)
                          .isEmpty
                      ? null
                      : () => service.startQuiz(),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Demarrer le quiz'),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Mode devoir : les eleves peuvent rejoindre et '
                        'repondre a leur rythme. Le code reste valide '
                        'jusqu\'a expiration du devoir.',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.accent),
                      ),
                    ),
                  ],
                ),
              ),
          ] else if (hasCurrentQuestion) ...[
            // Question en cours
            _buildCurrentQuestionCard(
              service,
              answeredCount,
              totalStudents,
            ),
            const SizedBox(height: 16),
            // Bouton forcer next
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => service.forceNext(),
                icon: const Icon(Icons.skip_next),
                label: const Text('Forcer la question suivante'),
              ),
            ),
            const SizedBox(height: 16),
            // Classement live top 5
            _buildLiveLeaderboard(service),
          ] else ...[
            // Entre questions : classement
            _buildLiveLeaderboard(service),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () => service.nextQuestion(),
                icon: const Icon(Icons.navigate_next),
                label: const Text('Question suivante'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Header code session ───────────────────────────────────────
  Widget _buildCodeHeader(ClassroomSocketService service) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            'CODE DE SESSION',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.sessionCode,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w800,
              letterSpacing: 8,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              service.session?.isLive == true
                  ? 'En direct'
                  : service.session?.isWaiting == true
                      ? 'En attente'
                      : 'Terminee',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Compteur joueurs ──────────────────────────────────────────
  Widget _buildPlayersCount(ClassroomSocketService service) {
    final count = service.players
        .where((p) => p.role == PlayerRole.student)
        .length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count eleve(s) connecte(s)',
                  style: AppTextStyles.h3,
                ),
                Text(
                  'Partage le code ci-dessus pour inviter d\'autres eleves',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section salle d'attente ───────────────────────────────────
  Widget _buildWaitingSection(ClassroomSocketService service) {
    final students = service.players
        .where((p) => p.role == PlayerRole.student)
        .toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.group, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text('Eleves connectes', style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 12),
          if (students.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.hourglass_empty,
                      size: 40, color: AppColors.textDisabled),
                  const SizedBox(height: 8),
                  Text(
                    'En attente du 1er eleve...',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            )
          else
            PlayerListWidget(
              players: students,
              currentUserId: service.playerId,
              showStatus: false,
            ),
        ],
      ),
    );
  }

  // ─── Carte question courante ───────────────────────────────────
  Widget _buildCurrentQuestionCard(
    ClassroomSocketService service,
    int answeredCount,
    int totalStudents,
  ) {
    final q = service.currentQuestion!;
    final stats = service.lastStats;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Question ${service.currentQuestionNum}'
                  ' / ${service.totalQuestions}',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              if (widget.mode == ClassroomMode.live)
                TimerRing(
                  timeRemaining: service.timeRemaining,
                  timeLimit: service.timeLimit,
                  size: 56,
                  strokeWidth: 5,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            q.enonce,
            style: AppTextStyles.h3.copyWith(height: 1.4),
          ),
          if (q.choix != null && q.choix!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: q.choix!.asMap().entries.map((e) {
                final letters = ['A', 'B', 'C', 'D', 'E', 'F'];
                return Chip(
                  label: Text('${letters[e.key]}. ${e.value}'),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 16),
          // Stats temps reel
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.how_to_vote, color: AppColors.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$answeredCount / $totalStudents eleves ont repondu',
                        style: AppTextStyles.body
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (stats != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Reussite : '
                          '${(stats.successRate * 100).toInt()}% - '
                          'Temps moyen : '
                          '${stats.averageTimeSeconds.toStringAsFixed(1)}s',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                // Barre de progression
                SizedBox(
                  width: 60,
                  height: 60,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: totalStudents == 0
                            ? 0
                            : answeredCount / totalStudents,
                        strokeWidth: 5,
                        backgroundColor:
                            AppColors.accent.withOpacity(0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.accent,
                        ),
                      ),
                      Text(
                        '${totalStudents == 0 ? 0 : ((answeredCount / totalStudents) * 100).round()}%',
                        style: AppTextStyles.label.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Classement live ───────────────────────────────────────────
  Widget _buildLiveLeaderboard(ClassroomSocketService service) {
    final students = service.players
        .where((p) => p.role == PlayerRole.student)
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LiveLeaderboard(
        players: students.take(10).toList(),
        currentUserId: service.playerId,
        title: 'Classement en direct',
      ),
    );
  }

  // ─── Vue terminee ──────────────────────────────────────────────
  Widget _buildEndedView(BuildContext context, ClassroomSocketService service) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events,
                size: 80, color: AppColors.accent),
            const SizedBox(height: 16),
            const Text('Session terminee !',
                style: AppTextStyles.h2, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Consulte le classement final et les statistiques '
              'detaillees.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider.value(
                        value: service,
                        child: TeacherResultsScreen(
                          sessionCode: widget.sessionCode,
                        ),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.analytics),
                label: const Text('Voir les resultats'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                service.disconnect();
                Navigator.of(context)
                    .popUntil((route) => route.isFirst);
              },
              icon: const Icon(Icons.home),
              label: const Text('Retour a l\'accueil'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Confirmation terminer ─────────────────────────────────────
  void _confirmEndSession(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Terminer la session ?'),
        content: const Text(
          'Tous les eleves vont etre deconnectes et la session '
          'passera en statut "terminee". Les resultats seront '
          'disponibles immediatement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              context.read<ClassroomSocketService>().endSession();
            },
            child: const Text('Terminer'),
          ),
        ],
      ),
    );
  }
}
