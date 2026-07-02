// lib/screens/orientation/widgets/chat_bubble_orientation.dart
// Bulle de message pour le chat d'orientation.
//
// Deux types de bulles :
//   - Bot (conseiller) : à gauche, fond AppColors.primarySurface, icône
//     compass_or_calculate en avatar, texte AppColors.textPrimary
//   - Élève (réponse) : à droite, fond AppColors.primary, texte blanc
//
// Pas de markdown complexe (contrairement au tutor) : les questions sont
// courtes et les réponses aussi. On garde un rendu simple + multi-lignes.
//
// Une variante "intro" permet d'afficher un en-tête de bienvenue avec
// un fond dégradé vert/orange (cf. _TutorScaffold._buildWelcomeCard).

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class ChatBubbleOrientation extends StatelessWidget {
  const ChatBubbleOrientation({
    super.key,
    required this.text,
    required this.isUser,
    this.isIntro = false,
    this.timestamp,
  });

  /// Texte affiché dans la bulle.
  final String text;

  /// Vrai si c'est une réponse de l'élève (bulle à droite, fond vert).
  final bool isUser;

  /// Vrai pour le message d'introduction (carte dégradée pleine largeur).
  final bool isIntro;

  /// Horodatage optionnel (format HH:mm).
  final DateTime? timestamp;

  @override
  Widget build(BuildContext context) {
    if (isIntro) return _buildIntroCard();

    final bubbleColor =
        isUser ? AppColors.primary : AppColors.primarySurface;
    final textColor =
        isUser ? Colors.white : AppColors.textPrimary;
    final timeColor = isUser
        ? Colors.white.withOpacity(0.85)
        : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildBotAvatar(),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.80,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                  ),
                  child: Text(
                    text,
                    style: AppTextStyles.body.copyWith(
                      color: textColor,
                      height: 1.45,
                    ),
                  ),
                ),
                if (timestamp != null) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      _formatTime(timestamp!),
                      style: TextStyle(fontSize: 11, color: timeColor),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser) _buildUserAvatar(),
        ],
      ),
    );
  }

  // ─── Avatars ─────────────────────────────────────────────────────
  Widget _buildBotAvatar() {
    return CircleAvatar(
      radius: 14,
      backgroundColor: AppColors.primarySurface,
      child: const Icon(
        Icons.explore,
        size: 16,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildUserAvatar() {
    return const CircleAvatar(
      radius: 14,
      backgroundColor: AppColors.primaryDark,
      child: Icon(
        Icons.person,
        size: 16,
        color: Colors.white,
      ),
    );
  }

  // ─── Carte d'introduction (dégradée) ─────────────────────────────
  Widget _buildIntroCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primarySurface, AppColors.accentSurface],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.explore, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conseiller ExamBoost',
                  style: AppTextStyles.h3.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: AppTextStyles.body.copyWith(fontSize: 13.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
