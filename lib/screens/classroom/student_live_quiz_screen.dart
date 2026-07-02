// lib/screens/classroom/student_live_quiz_screen.dart
// Ecran eleve : participe au quiz en direct.
//
// Etats geres (via ClassroomSocketService) :
//   - Waiting : en attente de l'enseignant + liste joueurs connectes
//   - Question active : timer + enonce + boutons QCM / champ texte
//   - Between questions : "Prepare-toi..." + countdown 3-2-1
//   - Final results : podium + classement + bouton "Revoir mes reponses"
//
// Le service est injecte via ChangeNotifierProvider (cree par JoinClassScreen
// ou TeacherLiveScreen). On ecoute ses changements via context.watch.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_theme.dart';
import 'models/classroom_session.dart';
import 'services/classroom_socket_service.dart';
import 'student_results_screen.dart';
import 'widgets/live_question_display.dart';
import 'widgets/player_list_widget.dart';
import 'widgets/timer_ring.dart';

class StudentLiveQuizScreen extends StatefulWidget {
  final String sessionCode;
  final String playerName;

  const StudentLiveQuizScreen({
    super.key,
    required this.sessionCode,
    required this.playerName,
  });

  @override
  State<StudentLiveQuizScreen> createState() => _StudentLiveQuizScreenState();
}

class _StudentLiveQuizScreenState extends State<StudentLiveQuizScreen> {
  @override
  Widget build(BuildContext context) {
    final service = context.watch<ClassroomSocketService>();
    final session = service.session;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Code : ${widget.sessionCode}'),
        actions: [
          if (service.me != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${service.me!.score} pts',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(child: _buildBody(service, session)),
    );
  }

  Widget _buildBody(
      ClassroomSocketService service, ClassroomSession? session) {
    // 1. Session terminee -> resultats
    if (service.results != null ||
        (session != null && session.isEnded)) {
      return StudentResultsView(
        service: service,
        sessionCode: widget.sessionCode,
        playerName: widget.playerName,
      );
    }

    // 2. Pas encore de session -> connexion en cours
    if (session == null) {
      return _buildConnecting(service);
    }

    // 3. Question active
    if (service.currentQuestion != null && !session.isEnded) {
      return _buildActiveQuestion(service);
    }

    // 4. En attente (avant le demarrage ou entre questions)
    return _buildWaitingRoom(service, session);
  }

  // ─── Connexion en cours ────────────────────────────────────────
  Widget _buildConnecting(ClassroomSocketService service) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            service.connectionState == ClassroomConnectionState.error
                ? (service.errorMessage ?? 'Erreur de connexion')
                : 'Connexion a la session...',
            style: AppTextStyles.body,
            textAlign: TextAlign.center,
          ),
          if (service.connectionState == ClassroomConnectionState.error) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Retour'),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Salle d'attente ───────────────────────────────────────────
  Widget _buildWaitingRoom(
      ClassroomSocketService service, ClassroomSession session) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero : code session + nombre de joueurs
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Text(
                  'Session en attente',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Code : ${widget.sessionCode}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 6,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.people, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '${service.players.length} eleve(s) connecte(s)',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Animation d'attente
          const _WaitingIndicator(),
          const SizedBox(height: 16),
          Text(
            session.isHomework
                ? 'Mode devoir : reponds a ton rythme, sans pression de temps.'
                : 'En attente du demarrage par l\'enseignant...',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Liste joueurs connectes
          Container(
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
                    const Text('Joueurs connectes',
                        style: AppTextStyles.h3),
                  ],
                ),
                const SizedBox(height: 12),
                PlayerListWidget(
                  players: service.players,
                  currentUserId: service.playerId,
                  showStatus: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Question active ───────────────────────────────────────────
  Widget _buildActiveQuestion(ClassroomSocketService service) {
    final q = service.currentQuestion!;
    final isHomework = service.mode == ClassroomMode.homework;

    return Column(
      children: [
        // Header : timer + score
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.surface,
          child: Row(
            children: [
              if (!isHomework)
                TimerRing(
                  timeRemaining: service.timeRemaining,
                  timeLimit: service.timeLimit,
                  size: 80,
                  strokeWidth: 7,
                )
              else
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.accentSurface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.access_time,
                      color: AppColors.accent, size: 32),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isHomework
                          ? 'Mode devoir'
                          : '${service.timeRemaining}s restantes',
                      style: AppTextStyles.h3.copyWith(
                        color: service.timeRemaining <= 5 && !isHomework
                            ? AppColors.error
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ta reponse : ${service.me?.score ?? 0} pts',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Question + boutons
        Expanded(
          child: LiveQuestionDisplay(
            question: q,
            questionNumber: service.currentQuestionNum,
            totalQuestions: service.totalQuestions,
            answered: service.hasAnsweredCurrent,
            lastCorrect: service.lastAnswerResult?.correct,
            onAnswer: (answer) {
              service.sendAnswer(questionId: q.id, answer: answer);
            },
          ),
        ),
        // Bandeau stats (si tous ont repondu)
        if (service.allAnswered && service.lastStats != null)
          _buildAllAnsweredBanner(service),
      ],
    );
  }

  Widget _buildAllAnsweredBanner(ClassroomSocketService service) {
    final stats = service.lastStats!;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.info.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.group, color: AppColors.info),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tous les eleves ont repondu !',
                  style: AppTextStyles.body
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  'Reussite : ${(stats.successRate * 100).toInt()}% '
                  '(${stats.correctCount}/${stats.answeredCount})',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Indicateur d'attente anime ─────────────────────────────────────
class _WaitingIndicator extends StatefulWidget {
  const _WaitingIndicator();

  @override
  State<_WaitingIndicator> createState() => _WaitingIndicatorState();
}

class _WaitingIndicatorState extends State<_WaitingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (_, __) {
            final t = (_controller.value + i * 0.2) % 1.0;
            final scale = 0.6 + 0.4 * (1 - (t * 2 - 1).abs());
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
