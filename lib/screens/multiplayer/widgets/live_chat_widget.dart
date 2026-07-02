// lib/screens/multiplayer/widgets/live_chat_widget.dart
// Chat live intégré au lobby et à la partie multijoueur.
//
// Affiche une liste scrollable de messages + un champ de saisie en bas.
// Les messages système (isSystem = true) sont affichés centrés et grisés.
// Les messages de l'utilisateur local sont à droite (vert Togo).
// Les messages des autres joueurs sont à gauche (gris clair).
//
// Pendant la partie, le chat peut être désactivé (enabled = false) :
// pendant qu'un joueur répond à une question, il ne peut pas écrire.
//
// Usage :
//   LiveChatWidget(
//     messages: service.chatMessages,
//     localPlayerId: service.playerId,
//     enabled: true,
//     onSend: (text) => service.sendChatMessage(text: text),
//   )

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../models/multiplayer_room.dart';

class LiveChatWidget extends StatefulWidget {
  final List<MultiplayerChatMessage> messages;
  final String localPlayerId;
  final bool enabled;
  final ValueChanged<String> onSend;
  final String? title;

  const LiveChatWidget({
    super.key,
    required this.messages,
    required this.localPlayerId,
    required this.onSend,
    this.enabled = true,
    this.title = 'Chat live',
  });

  @override
  State<LiveChatWidget> createState() => _LiveChatWidgetState();
}

class _LiveChatWidgetState extends State<LiveChatWidget> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant LiveChatWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Scroll en bas quand nouveau message.
    if (oldWidget.messages.length != widget.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final canSend = _controller.text.trim().isNotEmpty;
    if (canSend != _canSend) {
      setState(() => _canSend = canSend);
    }
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
    setState(() => _canSend = false);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              color: AppColors.primarySurface,
              child: Row(
                children: [
                  const Icon(Icons.chat_bubble_outline,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    widget.title,
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.enabled
                          ? AppColors.success.withOpacity(0.15)
                          : AppColors.textDisabled.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 6,
                          color: widget.enabled
                              ? AppColors.success
                              : AppColors.textDisabled,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.enabled ? 'Live' : 'Suspendu',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: widget.enabled
                                ? AppColors.success
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Liste des messages
            Expanded(
              child: widget.messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.forum_outlined,
                                size: 36,
                                color: AppColors.textDisabled),
                            const SizedBox(height: 8),
                            Text(
                              'Aucun message pour l\'instant',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      itemCount: widget.messages.length,
                      itemBuilder: (context, i) {
                        final msg = widget.messages[i];
                        if (msg.isSystem) {
                          return _SystemMessage(msg: msg);
                        }
                        return _UserMessage(
                          msg: msg,
                          isLocal: msg.playerId == widget.localPlayerId,
                        );
                      },
                    ),
            ),
            // Champ de saisie
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.divider, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: widget.enabled,
                      minLines: 1,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: widget.enabled
                            ? 'Écris un message...'
                            : 'Chat suspendu pendant la réponse',
                        hintStyle:
                            TextStyle(color: AppColors.textDisabled),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        filled: true,
                        fillColor: widget.enabled
                            ? AppColors.surfaceVariant
                            : AppColors.surfaceVariant.withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: widget.enabled ? (_) => _send() : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: (widget.enabled && _canSend) ? _send : null,
                    icon: const Icon(Icons.send, size: 18),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.textDisabled.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Message utilisateur (gauche ou droite) ─────────────────────────
class _UserMessage extends StatelessWidget {
  final MultiplayerChatMessage msg;
  final bool isLocal;

  const _UserMessage({required this.msg, required this.isLocal});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isLocal ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isLocal
              ? AppColors.primary
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft:
                isLocal ? const Radius.circular(12) : Radius.zero,
            bottomRight:
                isLocal ? Radius.zero : const Radius.circular(12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isLocal) ...[
              Text(
                msg.playerName,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 2),
            ],
            Text(
              msg.text,
              style: TextStyle(
                fontSize: 13,
                color: isLocal ? Colors.white : AppColors.textPrimary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _formatTime(msg.sentAt),
              style: TextStyle(
                fontSize: 9,
                color: isLocal
                    ? Colors.white70
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ─── Message système (centré, gris) ─────────────────────────────────
class _SystemMessage extends StatelessWidget {
  final MultiplayerChatMessage msg;

  const _SystemMessage({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.accentSurface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            msg.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.accent,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
