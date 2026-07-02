// lib/widgets/audio_player_button.dart
// Bouton play/pause reutilisable pour la lecture audio des questions.
//
// Etats visuels :
//   - Idle (texte pas en lecture)     -> icone volume_up (vert Togo)
//   - En lecture (pas en pause)        -> icone pause + animation pulse
//   - En pause                         -> icone play_arrow (vert Togo)
//   - TTS desactive                    -> icone volume_off (gris)
//
// Comportement au tap :
//   - Si TTS desactive : snackbar "Active la lecture audio dans les reglages".
//   - Sinon : appelle AudioPlaybackService.play(text) qui joue le role de
//     toggle (speak / pause / resume selon contexte).
//
// Usage :
//   AudioPlayerButton(text: question.enonce, size: 40)
//
// A placer dans question_card.dart a cote de l'enonce (Row apres l'icone
// help_outline, par exemple).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/audio_playback_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';

class AudioPlayerButton extends StatefulWidget {
  /// Texte a lire a voix haute quand on appuie sur le bouton.
  final String text;

  /// Taille du bouton (diametre).valeurs typiques : 32, 40, 48.
  final double size;

  /// Couleur d'accent (defaut = vert Togo). Mettre a AppColors.accent pour
  /// un variant orange.
  final Color? color;

  /// Tooltip personnalise. Si null, genere automatiquement selon l'etat.
  final String? tooltip;

  /// True pour masquer le bouton si TTS est desactive dans les settings.
  /// Defaut false (on garde le bouton visible mais gris, pour inviter
  /// l'eleve a activer la fonctionnalite).
  final bool hideWhenDisabled;

  const AudioPlayerButton({
    super.key,
    required this.text,
    this.size = 40,
    this.color,
    this.tooltip,
    this.hideWhenDisabled = false,
  });

  @override
  State<AudioPlayerButton> createState() => _AudioPlayerButtonState();
}

class _AudioPlayerButtonState extends State<AudioPlayerButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Met a jour l'animation pulse en fonction de l'etat TTS.
  void _syncAnimation(bool isPlaying) {
    if (isPlaying && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!isPlaying && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<TtsService, AudioPlaybackService>(
      builder: (context, tts, playback, _) {
        final enabled = tts.settings.enabled;
        if (!enabled && widget.hideWhenDisabled) {
          return const SizedBox.shrink();
        }

        final isCurrent = playback.isPlayingText(widget.text);
        final isCurrentPaused = playback.isPausedText(widget.text);

        // Synchronise l'animation pulse.
        _syncAnimation(isCurrent && !isCurrentPaused);

        final accent = widget.color ?? AppColors.primary;

        final tooltip = widget.tooltip ??
            (isCurrent
                ? (isCurrentPaused ? 'Reprendre la lecture' : 'Mettre en pause')
                : (enabled ? 'Ecouter la question' : 'Lecture audio desactivee'));

        return Tooltip(
          message: tooltip,
          child: _AnimatedTapButton(
            size: widget.size,
            color: enabled ? accent : AppColors.textDisabled,
            background: enabled
                ? accent.withOpacity(0.10)
                : AppColors.surfaceVariant,
            isPlaying: isCurrent && !isCurrentPaused,
            isPaused: isCurrentPaused,
            pulseAnimation: _pulseAnimation,
            onPressed: enabled
                ? () => playback.play(widget.text)
                : () => _showDisabledHint(context),
          ),
        );
      },
    );
  }

  void _showDisabledHint(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Lecture audio desactivee. Active-la dans Reglages > Lecture audio.',
        ),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Ouvrir',
          onPressed: () {
            // Navigation deleguee a l'agent wiring (route /settings/tts).
            // On evite ici d'importer go_router pour garder le widget pur.
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}

/// Bouton circulaire avec animation de tap (scale down) + pulse optionnel.
class _AnimatedTapButton extends StatefulWidget {
  final double size;
  final Color color;
  final Color background;
  final bool isPlaying;
  final bool isPaused;
  final Animation<double> pulseAnimation;
  final VoidCallback onPressed;

  const _AnimatedTapButton({
    required this.size,
    required this.color,
    required this.background,
    required this.isPlaying,
    required this.isPaused,
    required this.pulseAnimation,
    required this.onPressed,
  });

  @override
  State<_AnimatedTapButton> createState() => _AnimatedTapButtonState();
}

class _AnimatedTapButtonState extends State<_AnimatedTapButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tapController;
  late final Animation<double> _tapScale;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _tapScale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  IconData _iconForState() {
    if (widget.isPlaying) return Icons.pause_rounded;
    if (widget.isPaused) return Icons.play_arrow_rounded;
    return Icons.volume_up_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _tapController.forward(),
      onTapUp: (_) {
        _tapController.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _tapController.reverse(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_tapController, widget.pulseAnimation]),
        builder: (context, child) {
          // Combine scale tap + scale pulse (uniquement si en lecture).
          final scale =
              _tapScale.value * (widget.isPlaying ? widget.pulseAnimation.value : 1.0);
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.background,
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.color.withOpacity(widget.isPlaying ? 0.6 : 0.25),
              width: widget.isPlaying ? 1.6 : 1.2,
            ),
          ),
          child: Icon(
            _iconForState(),
            color: widget.color,
            size: widget.size * 0.55,
          ),
        ),
      ),
    );
  }
}
