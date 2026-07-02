// lib/screens/flash/flash_intro_screen.dart
// Écran d'introduction au mode Révision Flash 5 min.
//
// Présente le concept ("5 questions en 5 min") et un bouton "C'est parti"
// qui lance la session.
//
// Usage : cet écran est conçu pour être poussé via Navigator.push depuis
// une carte d'action (ex : home_screen à brancher par l'agent principal).
// Il reçoit le userId en paramètre (par convention avec les autres écrans
// du projet) et se charge de construire le FlashService à partir des
// QuestionService et SrsService disponibles via Provider.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/user_provider.dart';
import '../../services/question_service.dart';
import '../../services/srs_service.dart';
import '../../theme/adaptive_colors.dart';
import '../../theme/app_theme.dart';
import 'flash_session_screen.dart';
import 'services/flash_service.dart';

class FlashIntroScreen extends StatelessWidget {
  /// ID de l'utilisateur courant. Si null, on lit UserProvider.
  final String? userId;

  const FlashIntroScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mode Flash 5 min'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),

              // ─── Icône principale (éclair) ────────────────────────────
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.accent
                        .withOpacity(context.isDark ? 0.22 : 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.flash_on,
                    size: 52,
                    color: AppColors.accent,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ─── Titre ────────────────────────────────────────────────
              Text(
                '5 questions en 5 min',
                style: AppTextStyles.h1.copyWith(
                  color: AdaptiveColors.textPrimary(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Une session courte et intense, parfaite pour réviser '
                'dans les transports.',
                style: AppTextStyles.body.copyWith(
                  color: AdaptiveColors.textSecondary(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // ─── Cartes "comment ça marche" ──────────────────────────
              _InfoCard(
                icon: Icons.psychology,
                color: AppColors.primary,
                titre: 'Questions ciblées',
                description:
                    'On sélectionne 5 questions dans tes matières faibles '
                    '(compétences avec P(L) le plus bas), avec un mix de '
                    'matières pour éviter 5 maths d\'affilée.',
              ),
              const SizedBox(height: 12),
              _InfoCard(
                icon: Icons.timer,
                color: AppColors.accent,
                titre: '5 minutes chrono',
                description:
                    'Un timer de 5:00 est visible en haut. Si tu dépasses '
                    '60 s sur une question, on passe à la suivante '
                    'automatiquement.',
              ),
              const SizedBox(height: 12),
              _InfoCard(
                icon: Icons.touch_app,
                color: AppColors.info,
                titre: 'Auto-évaluation',
                description:
                    'Tu vois la réponse, puis tu indiques si tu as eu '
                    'bon ou faux. Gros boutons, facile en marchant.',
              ),
              const SizedBox(height: 32),

              // ─── Bouton "C'est parti" ────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _demarrerSession(context),
                  icon: const Icon(Icons.play_arrow, size: 26),
                  label: const Text('C\'est parti'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    textStyle:
                        AppTextStyles.button.copyWith(fontSize: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Lien "Révision complète" (alternative)
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Préférer une révision complète',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AdaptiveColors.textSecondary(context),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Démarrage de la session ────────────────────────────────────
  void _demarrerSession(BuildContext context) {
    // Résolution du userId : paramètre explicite > UserProvider > fallback.
    final userProvider =
        Provider.of<UserProvider>(context, listen: false);
    final effectiveUserId = userId ?? userProvider.currentUserId;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FlashSessionScreen(
          userId: effectiveUserId,
          user: userProvider.currentUser,
          flashService: FlashService(
            questionService:
                Provider.of<QuestionService>(context, listen: false),
          ),
          srsService: Provider.of<SrsService>(context, listen: false),
          questionService:
              Provider.of<QuestionService>(context, listen: false),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Carte d'information (icône + titre + description)
// ════════════════════════════════════════════════════════════════════

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String titre;
  final String description;

  const _InfoCard({
    required this.icon,
    required this.color,
    required this.titre,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdaptiveColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdaptiveColors.divider(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color:
                  color.withOpacity(context.isDark ? 0.22 : 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titre,
                  style: AppTextStyles.h3.copyWith(
                    fontSize: 16,
                    color: AdaptiveColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AdaptiveColors.textSecondary(context),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
