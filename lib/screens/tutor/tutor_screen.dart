// lib/screens/tutor/tutor_screen.dart
// Écran principal du tuteur IA — chat conversationnel avec l'élève.
//
// Architecture :
//   - TutorController (ChangeNotifier) gère l'état (messages, loading, error)
//   - TutorService appelle le backend FastAPI /tutor/ask via dio
//   - Persistance Hive box "tutor_conversations" (dernière conversation)
//
// Le controller est créé via ChangeNotifierProvider.value dans le
// constructeur de l'écran, et récupéré via context.watch<TutorController>().
//
// Pour intégration dans le router et home_screen.dart, voir README.md.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import 'tutor_controller.dart';
import 'services/tutor_service.dart';
import 'widgets/message_bubble.dart';
import 'widgets/suggestion_chips.dart';
import 'widgets/typing_indicator.dart';
import 'widgets/voice_input_button.dart';

class TutorScreen extends StatelessWidget {
  const TutorScreen({
    super.key,
    this.matiere,
    this.chapitre,
    this.competenceId,
    this.authToken,
    this.baseUrl,
  });

  /// Contexte pédagogique optionnel (si l'élève arrive depuis une matière).
  final String? matiere;
  final String? chapitre;
  final String? competenceId;

  /// Token JWT pour authentification backend.
  final String? authToken;

  /// URL de base du backend (défaut : localhost:8000 ou 10.0.2.2:8000).
  final String? baseUrl;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TutorController>(
      create: (_) {
        final service = TutorService(baseUrl: baseUrl);
        if (authToken != null) service.authToken = authToken;
        final controller = TutorController(service: service);
        // Chargement différé de la dernière conversation
        controller.init();
        return controller;
      },
      child: _TutorScaffold(
        matiere: matiere,
        chapitre: chapitre,
        competenceId: competenceId,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Scaffold interne (stateful pour gérer le TextField + scroll)
// ════════════════════════════════════════════════════════════════════
class _TutorScaffold extends StatefulWidget {
  const _TutorScaffold({
    this.matiere,
    this.chapitre,
    this.competenceId,
  });

  final String? matiere;
  final String? chapitre;
  final String? competenceId;

  @override
  State<_TutorScaffold> createState() => _TutorScaffoldState();
}

class _TutorScaffoldState extends State<_TutorScaffold> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _sendEnabled = false;
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    // Scroll initial en bas (si conversation chargée depuis Hive)
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollToBottom(animate: false),
    );
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final enabled = _textController.text.trim().isNotEmpty;
    if (enabled != _sendEnabled) {
      setState(() => _sendEnabled = enabled);
    }
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      if (animate) {
        _scrollController.animateTo(
          max,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(max);
      }
    });
  }

  Future<void> _sendMessage(TutorController controller, String text) async {
    if (text.trim().isEmpty) return;
    _textController.clear();
    setState(() => _sendEnabled = false);
    await controller.ask(
      question: text,
      matiere: widget.matiere,
      chapitre: widget.chapitre,
      competenceId: widget.competenceId,
    );
    _scrollToBottom();
  }

  Future<void> _confirmClear(TutorController controller) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Effacer la conversation ?'),
        content: const Text(
          'Cette action efface tous les messages de la conversation '
          'courante. Elle ne peut pas être annulée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Effacer'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.clearConversation();
      _scrollToBottom(animate: false);
    }
  }

  void _pickPhoto() {
    // UI seulement pour v1 — le package image_picker n'est pas dans pubspec.
    // Voir README.md pour l'activation.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Joindre une photo sera disponible dans une prochaine version.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _onVoiceTranscription(String text) {
    if (text.isEmpty) return;
    final current = _textController.text;
    final separator =
        current.isEmpty || current.endsWith(' ') ? '' : ' ';
    _textController.text = current + separator + text;
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: _textController.text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TutorController>();

    // Auto-scroll quand le nombre de messages change
    final msgCount = controller.messages.length +
        (controller.isLoading ? 1 : 0);
    if (msgCount != _lastMessageCount) {
      _lastMessageCount = msgCount;
      _scrollToBottom();
    }

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
              child: const Icon(Icons.smart_toy,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tuteur ExamBoost',
                    style:
                        AppTextStyles.h3.copyWith(fontSize: 16),
                  ),
                  Text(
                    widget.matiere != null
                        ? 'Pose-moi tes questions sur ${widget.matiere}'
                        : "Pose-moi n'importe quelle question",
                    style: AppTextStyles.bodySmall
                        .copyWith(fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined,
                color: AppColors.primary),
            tooltip: 'Nouvelle conversation',
            onPressed: () async {
              await controller.startNewConversation();
              _scrollToBottom(animate: false);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppColors.error),
            tooltip: 'Effacer la conversation',
            onPressed: () => _confirmClear(controller),
          ),
        ],
      ),
      body: Column(
        children: [
          // Bandeau hors-ligne
          if (controller.isOffline) _buildOfflineBanner(),
          // Liste des messages (ou suggestions au démarrage)
          Expanded(child: _buildConversation(controller)),
          // Zone de saisie sticky
          _buildInputArea(controller),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.warning.withOpacity(0.12),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, size: 18, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Le tuteur nécessite Internet. Connecte-toi pour poser des questions.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversation(TutorController controller) {
    final messages = controller.messages;
    if (messages.isEmpty) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            _buildWelcomeCard(),
            SuggestionChips(
              onSelected: (s) => _sendMessage(controller, s),
              customSuggestions: controller.suggestedFollowups.isNotEmpty
                  ? controller.suggestedFollowups
                  : null,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: messages.length + (controller.isLoading ? 1 : 0),
      itemBuilder: (context, idx) {
        if (idx == messages.length) {
          // Typing indicator en bas pendant le chargement
          return const TypingIndicator();
        }
        final msg = messages[idx];
        return MessageBubble(
          message: msg,
          onRetry: msg.isError ? () => controller.retryLast() : null,
        );
      },
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primarySurface, AppColors.accentSurface],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour ! Je suis ton tuteur IA.',
                  style:
                      AppTextStyles.h3.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.matiere != null
                      ? "Je peux t'aider en ${widget.matiere}. "
                          'Pose-moi une question ou choisis une suggestion ci-dessous.'
                      : "Je peux t'aider en maths, français, sciences, etc. "
                          'Pose-moi une question ou choisis une suggestion ci-dessous.',
                  style: AppTextStyles.bodySmall
                      .copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(TutorController controller) {
    final isLoading = controller.isLoading;
    final canSend = _sendEnabled && !isLoading;

    return SafeArea(
      top: false,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.divider, width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Bouton "Joindre une photo" (UI seulement v1)
            IconButton(
              onPressed: _pickPhoto,
              icon: const Icon(Icons.add_a_photo_outlined,
                  color: AppColors.textSecondary),
              tooltip: 'Joindre une photo',
              splashRadius: 22,
            ),
            // Bouton micro (masqué sur desktop/web)
            VoiceInputButton(
              onTranscription: _onVoiceTranscription,
              enabled: !isLoading,
            ),
            // TextField multiligne auto-expand
            Expanded(
              child: TextField(
                controller: _textController,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                enabled: !isLoading,
                onSubmitted: (text) {
                  if (text.trim().isNotEmpty && !isLoading) {
                    _sendMessage(controller, text);
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Pose ta question...',
                  hintStyle:
                      const TextStyle(color: AppColors.textDisabled),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Bouton envoyer (Material circle pour contrôle précis du style)
            _SendButton(
              enabled: canSend,
              onPressed: canSend
                  ? () => _sendMessage(controller, _textController.text)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bouton envoyer (cercle vert) ────────────────────────────────────
class _SendButton extends StatelessWidget {
  const _SendButton({required this.enabled, this.onPressed});

  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled
          ? AppColors.primary
          : AppColors.primary.withOpacity(0.4),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Icon(Icons.send, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
