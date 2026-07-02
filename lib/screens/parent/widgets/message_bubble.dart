// lib/screens/parent/widgets/message_bubble.dart
// Bulle de message dans la vue chat parent-enseignant.
//
// 2 variantes :
//   - fromParent = true  : bulle à droite, fond vert Togo, texte blanc
//   - fromParent = false : bulle à gauche, fond surface variant,
//                          texte primaire
//
// Affiche le contenu + l'heure (HH:mm). Pas d'avatar (l'identité est
// implicite : à droite = parent, à gauche = enseignant).

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../theme/adaptive_colors.dart';
import '../../../theme/app_theme.dart';
import '../services/parent_service.dart';

class MessageBubble extends StatelessWidget {
  final TeacherMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isParent = message.fromParent;
    final bubbleColor = isParent
        ? AdaptiveColors.primary(context)
        : AdaptiveColors.surfaceVariant(context);
    final textColor = isParent
        ? AdaptiveColors.onPrimary(context)
        : AdaptiveColors.textPrimary(context);

    return Align(
      alignment: isParent ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft:
                  isParent ? const Radius.circular(14) : Radius.zero,
              bottomRight:
                  isParent ? Radius.zero : const Radius.circular(14),
            ),
            boxShadow: [
              BoxShadow(
                color: AdaptiveColors.shadowColor(context),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                message.contenu,
                style: AppTextStyles.body.copyWith(
                    color: textColor, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('HH:mm').format(message.envoyeLe),
                style: TextStyle(
                  color: isParent
                      ? AdaptiveColors.onPrimary(context).withOpacity(0.75)
                      : AdaptiveColors.textSecondary(context),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
