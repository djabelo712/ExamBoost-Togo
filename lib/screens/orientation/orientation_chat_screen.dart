// lib/screens/orientation/orientation_chat_screen.dart
// Écran principal du chatbot conseiller d'orientation.
//
// Architecture :
//   - StatefulWidget (gère l'état conversationnel sans Provider externe).
//   - OrientationService fournit les 12 questions et le scoring.
//   - Le profil final est calculé à la fin du chat puis passé à
//     OrientationResultsScreen via Navigator.push.
//
// Flow conversationnel :
//   1. Intro du bot ("Bonjour, je vais te poser 12 questions...")
//   2. Pour chaque question : bot pose la question → boutons réponses
//      (chips) → élève tape une réponse → bot passe à la suivante.
//   3. À la fin : bot récapitule l'archétype + bouton "Voir recommandations".
//
// Inputs :
//   - matiereMaitrise : Map<matiere, P(L) 0..1> optionnelle (sinon score
//     matières = défaut 0.5 dans le service).
//   - niveauScolaire / serie : contexte élève (passés au profil).
//   - onComplete : callback optionnel appelé à la fin du chat (utile pour
//     analytics ou wiring custom).

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'models/orientation_profile.dart';
import 'orientation_results_screen.dart';
import 'services/orientation_service.dart';
import 'widgets/chat_bubble_orientation.dart';

// ─── Message interne au chat ────────────────────────────────────────
class _ChatMessage {
  final String text;
  final bool isUser;
  final bool isIntro;
  final DateTime timestamp;

  _ChatMessage({
    required this.text,
    required this.isUser,
    this.isIntro = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class OrientationChatScreen extends StatefulWidget {
  const OrientationChatScreen({
    super.key,
    this.matiereMaitrise = const {},
    this.niveauScolaire = 'Terminale',
    this.serie,
    this.onComplete,
  });

  /// Maîtrise moyenne par matière (matiere -> P(L) 0..1).
  /// Source : agrégation de AppUser.bktMaitrise par matière.
  final Map<String, double> matiereMaitrise;

  /// Niveau scolaire ("3eme", "Terminale", etc.).
  final String niveauScolaire;

  /// Série du BAC si applicable ("C", "D", "A"...).
  final String? serie;

  /// Callback optionnel appelé à la fin du chat avec le profil calculé.
  final void Function(OrientationProfile profile)? onComplete;

  @override
  State<OrientationChatScreen> createState() => _OrientationChatScreenState();
}

class _OrientationChatScreenState extends State<OrientationChatScreen> {
  final OrientationService _service = OrientationService();
  final ScrollController _scrollController = ScrollController();

  final List<_ChatMessage> _messages = [];
  final Map<String, String> _responses = {};

  int _currentQuestionIndex = 0;
  bool _isBotTyping = false;
  bool _isFinished = false;
  OrientationProfile? _finalProfile;

  @override
  void initState() {
    super.initState();
    // ─── Message d'introduction ────────────────────────────────────
    _messages.add(_ChatMessage(
      text:
          "Bonjour ! Je suis ton conseiller d'orientation ExamBoost. "
          "Je vais te poser ${OrientationService.questions.length} questions "
          "sur tes intérêts, tes matières préférées et tes valeurs. "
          "À la fin, je te proposerai les 5 filières togolaises les plus "
          "adaptées à ton profil. C'est parti !",
      isUser: false,
      isIntro: true,
    ));

    // ─── Première question (après court délai pour effet "typing") ─
    _scheduleNextBotMessage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ═════════════════════════════════════════════════════════════════
  // LOGIQUE CONVERSATIONNELLE
  // ═════════════════════════════════════════════════════════════════

  void _scheduleNextBotMessage() {
    setState(() => _isBotTyping = true);
    _scrollToBottom();
    Future.delayed(const Duration(milliseconds: 480), () {
      if (!mounted) return;
      setState(() => _isBotTyping = false);
      _askCurrentQuestion();
    });
  }

  void _askCurrentQuestion() {
    if (_currentQuestionIndex >= OrientationService.questions.length) {
      _finishChat();
      return;
    }
    final q = OrientationService.questions[_currentQuestionIndex];
    final prefix = _currentQuestionIndex == 0
        ? 'Commençons. '
        : _currentQuestionIndex == OrientationService.questions.length - 1
            ? 'Dernière question. '
            : 'Question ${_currentQuestionIndex + 1}/${OrientationService.questions.length}. ';
    setState(() {
      _messages.add(_ChatMessage(
        text: '$prefix${q.text}',
        isUser: false,
      ));
    });
    _scrollToBottom();
  }

  void _onAnswerSelected(OrientationQuestion question, OrientationOption option) {
    setState(() {
      _messages.add(_ChatMessage(
        text: option.text,
        isUser: true,
      ));
      _responses[question.id] = option.id;
      _currentQuestionIndex++;
    });
    _scrollToBottom();

    // Passage à la question suivante (ou fin)
    if (_currentQuestionIndex >= OrientationService.questions.length) {
      _finishChat();
    } else {
      _scheduleNextBotMessage();
    }
  }

  Future<void> _finishChat() async {
    setState(() => _isBotTyping = true);
    _scrollToBottom();
    await Future.delayed(const Duration(milliseconds: 800));

    final profile = _service.calculerProfil(
      reponses: _responses,
      matiereMaitrise: widget.matiereMaitrise,
      niveauScolaire: widget.niveauScolaire,
      serie: widget.serie,
    );

    if (!mounted) return;
    setState(() {
      _isBotTyping = false;
      _finalProfile = profile;
      _isFinished = true;
      _messages.add(_ChatMessage(
        text:
            "Merci pour tes réponses ! Ton profil d'orientation est :\n\n"
            "${profile.archetype}\n\n"
            "${profile.archetypeDescription}\n\n"
            "Tu peux maintenant découvrir les 5 filières togolaises qui te "
            "correspondent le mieux.",
        isUser: false,
      ));
    });
    _scrollToBottom();

    // Callback optionnel
    widget.onComplete?.call(profile);
  }

  void _openResults() {
    final profile = _finalProfile;
    if (profile == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OrientationResultsScreen(profile: profile),
      ),
    );
  }

  void _restartChat() {
    setState(() {
      _messages.clear();
      _responses.clear();
      _currentQuestionIndex = 0;
      _isFinished = false;
      _finalProfile = null;
      _messages.add(_ChatMessage(
        text:
            "On recommence ! Je vais te reposer "
            "${OrientationService.questions.length} questions.",
        isUser: false,
        isIntro: true,
      ));
    });
    _scheduleNextBotMessage();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      _scrollController.animateTo(
        max,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  // ═════════════════════════════════════════════════════════════════
  // BUILD
  // ═════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final progress = (_currentQuestionIndex) /
        OrientationService.questions.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.explore, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Conseiller d'orientation",
                    style: AppTextStyles.h3.copyWith(fontSize: 16),
                  ),
                  Text(
                    _isFinished
                        ? 'Profil prêt'
                        : 'Question ${_currentQuestionIndex + 1}/'
                            '${OrientationService.questions.length}',
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            tooltip: 'Recommencer',
            onPressed: _restartChat,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 4,
            backgroundColor: AppColors.divider,
            color: AppColors.primary,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildConversation()),
          _buildBottomArea(),
        ],
      ),
    );
  }

  // ─── Liste des messages ──────────────────────────────────────────
  Widget _buildConversation() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: _messages.length + (_isBotTyping ? 1 : 0),
      itemBuilder: (context, idx) {
        if (idx == _messages.length) {
          return _TypingBubble();
        }
        final msg = _messages[idx];
        return ChatBubbleOrientation(
          text: msg.text,
          isUser: msg.isUser,
          isIntro: msg.isIntro,
          timestamp: msg.timestamp,
        );
      },
    );
  }

  // ─── Zone inférieure (options / CTA final) ───────────────────────
  Widget _buildBottomArea() {
    if (_isFinished) {
      return _buildFinalCTA();
    }
    if (_isBotTyping || _currentQuestionIndex >= OrientationService.questions.length) {
      return const SizedBox.shrink();
    }
    return _buildAnswerOptions();
  }

  Widget _buildAnswerOptions() {
    final q = OrientationService.questions[_currentQuestionIndex];
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.divider, width: 1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chip catégorie
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.accentSurface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                q.categoryLabel,
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 10.5,
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: q.options
                  .map((opt) => _AnswerChip(
                        label: opt.text,
                        onTap: () => _onAnswerSelected(q, opt),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinalCTA() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.divider, width: 1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _restartChat,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refaire le test'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _openResults,
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('Mes recommandations'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Sous-composants
// ════════════════════════════════════════════════════════════════════

class _AnswerChip extends StatelessWidget {
  const _AnswerChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primarySurface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.arrow_forward,
                size: 14,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primarySurface,
            child: const Icon(Icons.explore,
                size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Dot(delay: 0),
                const SizedBox(width: 4),
                _Dot(delay: 200),
                const SizedBox(width: 4),
                _Dot(delay: 400),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  const _Dot({required this.delay});
  final int delay;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
