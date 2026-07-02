// lib/widgets/voice_answer_button.dart
// Bouton micro animé pour déclencher la saisie vocale d'une réponse.
//
// Comportement :
//   - Tap : démarre l'écoute (si service disponible et prêt)
//   - Tap pendant l'écoute : arrête l'écoute (et déclenche onTranscription)
//   - Animation : scale pulsé + halo coloré quand le micro écoute
//   - Couleurs : vert Togo au repos, rouge error en écoute (signal d'alerte)
//   - Masqué sur web/desktop (speech_to_text non supporté)
//   - Désactivé (gris) si widget.enabled = false
//
// Le bouton ne gère PAS la comparaison avec la bonne réponse : il se contente
// de capturer la transcription et de la passer via onTranscription. C'est
// l'écran appelant (voice_answer_mode.dart) qui compare via
// VoiceComparisonService.
//
// Affiche aussi une [VoiceAnswerIndicator] (vague animée) au-dessus du bouton
// pendant l'écoute, et la transcription partielle (live) en dessous.

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/voice_input_service.dart';
import '../theme/adaptive_colors.dart';
import '../theme/app_theme.dart';
import 'voice_answer_indicator.dart';

/// Bouton micro pour saisie vocale d'une réponse.
///
/// Ce widget est consommateur du [VoiceInputService] (via Provider). Il
/// s'abonne aux changements d'état (listening/ready/error) pour mettre à
/// jour son apparence en temps réel.
class VoiceAnswerButton extends StatefulWidget {
  const VoiceAnswerButton({
    super.key,
    required this.onTranscription,
    this.enabled = true,
    this.label,
    this.size = 72.0,
  });

  /// Callback appelé avec la transcription finale quand l'écoute se termine
  /// (soit par silence détecté, soit par tap de l'élève pour arrêter).
  final ValueChanged<String> onTranscription;

  /// False pour désactiver le bouton (gris, non cliquable).
  final bool enabled;

  /// Libellé optionnel affiché sous le bouton. Si null, un libellé par
  /// défaut est utilisé ("Parler ma réponse" / "Écoute en cours...").
  final String? label;

  /// Diamètre du bouton micro (en dp). 72 par défaut.
  final double size;

  @override
  State<VoiceAnswerButton> createState() => _VoiceAnswerButtonState();
}

class _VoiceAnswerButtonState extends State<VoiceAnswerButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  // Transcription partielle live (affichée sous le bouton pendant l'écoute)
  String _partialText = '';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ─── Action : toggle écoute ──────────────────────────────────

  Future<void> _toggleListening() async {
    if (!widget.enabled) return;

    final voice = context.read<VoiceInputService>();

    if (voice.isListening) {
      // Arrêt manuel : déclenche onFinal avec la transcription accumulée
      await voice.stopListening();
      return;
    }

    if (voice.state == VoiceInputState.unsupported) {
      _showUnsupportedSnackBar();
      return;
    }

    if (!voice.speechAvailable && voice.state == VoiceInputState.notInitialized) {
      // Première initialisation : elle se fait dans startListening
    }

    setState(() => _partialText = '');
    final ok = await voice.startListening(
      onPartial: (partial) {
        if (mounted) setState(() => _partialText = partial);
      },
      onFinal: (finalText) {
        if (mounted) setState(() => _partialText = '');
        widget.onTranscription(finalText);
      },
      onError: (error) {
        if (mounted) {
          setState(() => _partialText = '');
          _showErrorSnackBar(error);
        }
      },
    );

    if (!ok && mounted) {
      _showErrorSnackBar(voice.lastError ?? 'Micro indisponible');
    }
  }

  // ─── Snackbars d'information ─────────────────────────────────

  void _showUnsupportedSnackBar() {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          "La saisie vocale n'est disponible que sur Android et iOS.",
        ),
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String error) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text('Erreur micro : $error'),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // speech_to_text n'est supporté que sur Android/iOS natifs.
    final isMobile = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    if (!isMobile) {
      return const SizedBox.shrink();
    }

    return Consumer<VoiceInputService>(
      builder: (context, voice, _) {
        final isListening = voice.isListening;
        final isReady =
            voice.state == VoiceInputState.ready || isListening;
        final isError = voice.state == VoiceInputState.error;

        // Synchronise l'animation de pulsation avec l'état d'écoute
        if (isListening && !_pulseController.isAnimating) {
          _pulseController.repeat(reverse: true);
        } else if (!isListening && _pulseController.isAnimating) {
          _pulseController.stop();
          _pulseController.reset();
        }

        final color = _buttonColor(
          isListening: isListening,
          isReady: isReady,
          isError: isError,
          enabled: widget.enabled,
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicateur de vague animée (visible seulement en écoute)
            if (isListening)
              VoiceAnswerIndicator(
                color: color,
                height: 36,
              )
            else
              SizedBox(height: 36),

            const SizedBox(height: 8),

            // Le bouton micro avec halo pulsé
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final pulseValue =
                    isListening ? _pulseController.value : 0.0;
                final haloOpacity = 0.25 * pulseValue;
                final scale = 1.0 + 0.08 * pulseValue;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Halo pulsé
                    if (isListening)
                      Container(
                        width: widget.size * (1.0 + 0.4 * pulseValue),
                        height: widget.size * (1.0 + 0.4 * pulseValue),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withOpacity(haloOpacity),
                        ),
                      ),
                    // Bouton principal
                    Transform.scale(
                      scale: scale,
                      child: Container(
                        width: widget.size,
                        height: widget.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.30),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed:
                              widget.enabled ? _toggleListening : null,
                          icon: Icon(
                            isListening
                                ? Icons.stop_rounded
                                : Icons.mic_rounded,
                            color: Colors.white,
                            size: widget.size * 0.45,
                          ),
                          tooltip: isListening
                              ? 'Arrêter la saisie vocale'
                              : 'Dicter ma réponse',
                          splashRadius: widget.size * 0.45,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 12),

            // Libellé sous le bouton
            Text(
              widget.label ??
                  (isListening ? 'Écoute en cours...' : 'Dicter ma réponse'),
              style: AppTextStyles.label.copyWith(
                color: isListening
                    ? AppColors.error
                    : AdaptiveColors.textSecondary(context),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),

            // Transcription partielle live
            if (_partialText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AdaptiveColors.primarySurface(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                constraints: const BoxConstraints(maxWidth: 280),
                child: Text(
                  _partialText,
                  style: AppTextStyles.body.copyWith(
                    color: AdaptiveColors.primary(context),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  /// Couleur du bouton selon l'état.
  Color _buttonColor({
    required bool isListening,
    required bool isReady,
    required bool isError,
    required bool enabled,
  }) {
    if (!enabled) return AppColors.textDisabled;
    if (isListening) return AppColors.error;
    if (isError) return AppColors.warning;
    if (isReady) return AppColors.primary;
    return AppColors.textDisabled;
  }
}
