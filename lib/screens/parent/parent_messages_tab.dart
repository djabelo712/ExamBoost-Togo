// lib/screens/parent/parent_messages_tab.dart
// Onglet "Messages" du dashboard parent.
//
// 2 vues :
//   1. Liste des conversations (carte enseignant + matière + enfant +
//      dernier message + badge non lus)
//   2. Vue chat (AppBar avec enseignant, liste des bulles, champ de
//      saisie + bouton envoyer)
//
// Le passage d'une vue à l'autre se fait via setState local (pas de
// Navigator pour garder le TabBar visible en haut — pattern cohérent
// avec l'app élève).
//
// Mock : les réponses enseignant sont simulées via ParentMockData. En
// v2, brancher sur WebSocket (classroom_socket_service.dart réutilisable).

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../theme/adaptive_colors.dart';
import '../../theme/app_theme.dart';
import 'services/parent_service.dart';
import 'widgets/message_bubble.dart';

class MessagesTab extends StatefulWidget {
  final List<Conversation> conversations;

  const MessagesTab({super.key, required this.conversations});

  @override
  State<MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<MessagesTab> {
  Conversation? _openConversation;

  // ─── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_openConversation != null) {
      return _ChatView(
        conversation: _openConversation!,
        onBack: () => setState(() => _openConversation = null),
        onSend: _handleSend,
      );
    }
    return _buildListView();
  }

  // ─── Vue liste des conversations ───────────────────────────────
  Widget _buildListView() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Bandeau info ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AdaptiveColors.primarySurface(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryLight, width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_outline,
                    color: AppColors.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Échangez avec les enseignants de vos enfants. '
                    'Les messages sont privés et confidentiels.',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AdaptiveColors.primary(context), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ─── Liste des conversations ──────────────────────────
          Expanded(
            child: widget.conversations.isEmpty
                ? _buildEmptyState(context)
                : ListView.separated(
                    itemCount: widget.conversations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _conversationCard(
                        context, widget.conversations[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _conversationCard(BuildContext context, Conversation conv) {
    final last = conv.dernier;
    final lastTime = last != null
        ? DateFormat('dd/MM · HH:mm').format(last.envoyeLe)
        : '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _openConversation = conv),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AdaptiveColors.surface(context),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AdaptiveColors.shadowColor(context),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar enseignant
              CircleAvatar(
                radius: 22,
                backgroundColor: AdaptiveColors.accentSurface(context),
                child: Icon(Icons.person,
                    color: AdaptiveColors.adaptiveAccent(context), size: 20),
              ),
              const SizedBox(width: 12),
              // Contenu
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conv.enseignantNom,
                            style: AppTextStyles.h3.copyWith(
                                color: AdaptiveColors.textPrimary(context),
                                fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (conv.nonLus > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${conv.nonLus}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${conv.enseignantMatiere} · ${conv.childName}',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AdaptiveColors.primary(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    if (last != null)
                      Row(
                        children: [
                          Icon(
                            last.fromParent
                                ? Icons.arrow_forward
                                : Icons.arrow_back,
                            size: 12,
                            color: AdaptiveColors.textSecondary(context),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              last.contenu,
                              style: AppTextStyles.bodySmall.copyWith(
                                  color:
                                      AdaptiveColors.textSecondary(context),
                                  fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 4),
                    Text(
                      lastTime,
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AdaptiveColors.textDisabled(context),
                          fontSize: 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right,
                  color: AdaptiveColors.textDisabled(context)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Envoi d'un message ────────────────────────────────────────
  Future<void> _handleSend(String contenu) async {
    if (_openConversation == null) return;
    final conv = _openConversation!;
    final newMsg = await ParentService.sendMessage(
      conversationId: conv.id,
      contenu: contenu,
    );
    if (!mounted) return;

    setState(() {
      // Ajouter le message à la conversation ouverte.
      final updatedMessages = [...conv.messages, newMsg];
      _openConversation = Conversation(
        id: conv.id,
        childId: conv.childId,
        childName: conv.childName,
        enseignantNom: conv.enseignantNom,
        enseignantMatiere: conv.enseignantMatiere,
        messages: updatedMessages,
        nonLus: 0,
      );
    });

    // Simuler une réponse enseignant après 1.5 s (mock v1).
    // En production, la réponse arrivera via WebSocket push.
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    if (_openConversation?.id != conv.id) return;

    final reply = TeacherMessage(
      id: 'm_reply_${DateTime.now().millisecondsSinceEpoch}',
      contenu: _mockReply(contenu),
      envoyeLe: DateTime.now(),
      fromParent: false,
    );
    setState(() {
      final c = _openConversation!;
      _openConversation = Conversation(
        id: c.id,
        childId: c.childId,
        childName: c.childName,
        enseignantNom: c.enseignantNom,
        enseignantMatiere: c.enseignantMatiere,
        messages: [...c.messages, reply],
        nonLus: 0,
      );
    });
  }

  /// Génère une réponse enseignant simulée (mock v1).
  /// En v2 : la réponse viendra via WebSocket du backend.
  String _mockReply(String parentMessage) {
    final lower = parentMessage.toLowerCase();
    if (lower.contains('rendement') || lower.contains('progrès') ||
        lower.contains('progression')) {
      return 'Merci pour votre implication. Votre enfant montre une '
          'bonne progression sur les fondamentaux, je reste confiant pour '
          'l\'examen.';
    }
    if (lower.contains('devoir') || lower.contains('exercice') ||
        lower.contains('révision')) {
      return 'Je vais préparer des exercices supplémentaires à lui donner '
          'en classe. N\'hésitez pas à lui faire réviser sur ExamBoost le soir.';
    }
    if (lower.contains('comportement') || lower.contains('attention')) {
      return 'Votre enfant reste poli et attentif en classe. Quelques '
          'fluctuations de concentration mais rien d\'inquiétant.';
    }
    return 'Merci pour votre message. Je reviens vers vous dès que possible '
        'avec un retour détaillé. Cordialement.';
  }

  // ─── État vide ─────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline,
              size: 56, color: AdaptiveColors.textDisabled(context)),
          const SizedBox(height: 12),
          Text('Aucune conversation',
              style: AppTextStyles.h3
                  .copyWith(color: AdaptiveColors.textPrimary(context))),
          const SizedBox(height: 6),
          Text(
            'Les enseignants de vos enfants peuvent vous contacter ici. '
            'Vous serez notifié à chaque nouveau message.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall
                .copyWith(color: AdaptiveColors.textSecondary(context)),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// VUE CHAT (conversation ouverte)
// ══════════════════════════════════════════════════════════════════

class _ChatView extends StatefulWidget {
  final Conversation conversation;
  final VoidCallback onBack;
  final Future<void> Function(String contenu) onSend;

  const _ChatView({
    required this.conversation,
    required this.onBack,
    required this.onSend,
  });

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _inputCtrl.clear();
    await widget.onSend(text);
    if (!mounted) return;

    // Scroll en bas après envoi.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });

    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final conv = widget.conversation;
    return Column(
      children: [
        // ─── En-tête conversation ─────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          color: AdaptiveColors.surface(context),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              ),
              CircleAvatar(
                radius: 18,
                backgroundColor: AdaptiveColors.accentSurface(context),
                child: Icon(Icons.person,
                    color: AdaptiveColors.adaptiveAccent(context), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conv.enseignantNom,
                      style: AppTextStyles.h3.copyWith(
                          color: AdaptiveColors.textPrimary(context),
                          fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${conv.enseignantMatiere} · ${conv.childName}',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AdaptiveColors.primary(context),
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () => _showInfo(context, conv),
              ),
            ],
          ),
        ),
        Divider(
            height: 1, color: AdaptiveColors.divider(context)),

        // ─── Liste des messages ───────────────────────────────
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            itemCount: conv.messages.length,
            itemBuilder: (_, i) => MessageBubble(message: conv.messages[i]),
          ),
        ),

        // ─── Zone de saisie ───────────────────────────────────
        Container(
          padding: EdgeInsets.only(
            left: 12,
            right: 8,
            top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + 8,
          ),
          decoration: BoxDecoration(
            color: AdaptiveColors.surface(context),
            border: Border(
              top: BorderSide(
                  color: AdaptiveColors.divider(context), width: 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputCtrl,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) {
                    _send();
                  },
                  decoration: InputDecoration(
                    hintText: 'Écrire un message...',
                    hintStyle: AppTextStyles.bodySmall.copyWith(
                        color: AdaptiveColors.textDisabled(context)),
                    filled: true,
                    fillColor: AdaptiveColors.surfaceVariant(context),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send, color: AppColors.primary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showInfo(BuildContext context, Conversation conv) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(conv.enseignantNom),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Matière', conv.enseignantMatiere),
            _infoRow('Enfant concerné', conv.childName),
            _infoRow('Messages échangés', '${conv.messages.length}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
