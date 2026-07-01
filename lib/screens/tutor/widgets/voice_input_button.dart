// lib/screens/tutor/widgets/voice_input_button.dart
// Bouton micro pour saisie vocale (speech-to-text).
//
// IMPORTANT : Ce widget est livré avec une implémentation STUB (sans
// reconnaissance vocale réelle) pour ne pas casser la compilation tant
// que le package `speech_to_text` n'a pas été ajouté au pubspec.yaml.
//
// Pour activer la vraie saisie vocale :
//   1. Ajouter `speech_to_text: ^7.0.0` au pubspec.yaml (voir README.md)
//   2. Remplacer le corps de _toggleListening() par l'implémentation réelle
//      (code complet fourni en commentaire ci-dessous)
//
// Sur desktop/web, le bouton est masqué (speech_to_text non supporté).
// Sur mobile, le bouton s'affiche avec une animation pulsée rouge quand
// "l'écoute" est active (stub : affiche un snackbar explicatif).

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class VoiceInputButton extends StatefulWidget {
  const VoiceInputButton({
    super.key,
    required this.onTranscription,
    this.enabled = true,
  });

  /// Callback appelé avec la transcription finale.
  final ValueChanged<String> onTranscription;

  /// Désactivé si l'envoi est en cours.
  final bool enabled;

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with SingleTickerProviderStateMixin {
  bool _listening = false;
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ─── Stub : pas de reconnaissance vocale réelle ─────────────────
  // Voir README.md pour activer `speech_to_text` et remplacer par le code
  // réel fourni en commentaire plus bas.
  Future<void> _toggleListening() async {
    if (!widget.enabled) return;

    if (_listening) {
      setState(() => _listening = false);
      _animController.stop();
      return;
    }
    setState(() => _listening = true);
    _animController.repeat(reverse: true);
    // Laisse le temps de voir l'animation avant le message d'aide
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _listening = false);
    _animController.stop();
    _showEnableVoiceSnackbar();
  }

  void _showEnableVoiceSnackbar() {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: const Text(
          "La saisie vocale nécessite l'ajout du package speech_to_text "
          '(vois le README du dossier tutor).',
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // RÉFÉRENCE — implémentation réelle à activer après ajout du package.
  // Décommenter ce bloc ET remplacer _toggleListening par _realToggle.
  // Étapes :
  //   1. Ajouter `speech_to_text: ^7.0.0` au pubspec.yaml
  //   2. Ajouter les permissions micro :
  //      - Android : AndroidManifest.xml → <uses-permission android:name="android.permission.RECORD_AUDIO"/>
  //      - iOS : Info.plist → NSMicrophoneUsageDescription
  //   3. Renommer _realToggle en _toggleListening (et supprimer le stub)
  // ════════════════════════════════════════════════════════════════
  //
  // final SpeechToText _speech = SpeechToText();
  // bool _speechAvailable = false;
  // String _partial = '';
  //
  // Future<void> _realToggle() async {
  //   if (!widget.enabled) return;
  //   if (!_speechAvailable) {
  //     _speechAvailable = await _speech.initialize(
  //       onError: (err) => debugPrint('Speech error: $err.errorMsg'),
  //       onStatus: (status) {
  //         if (status == 'done' || status == 'notListening') {
  //           if (mounted) {
  //             setState(() => _listening = false);
  //             _animController.stop();
  //           }
  //           if (_partial.isNotEmpty) {
  //             widget.onTranscription(_partial);
  //             _partial = '';
  //           }
  //         }
  //       },
  //     );
  //     if (!_speechAvailable) {
  //       _showPermissionDeniedSnackbar();
  //       return;
  //     }
  //   }
  //   if (_listening) {
  //     await _speech.stop();
  //     return;
  //   }
  //   setState(() => _listening = true);
  //   _animController.repeat(reverse: true);
  //   await _speech.listen(
  //     localeId: 'fr_FR',
  //     partialResults: true,
  //     onResult: (result) {
  //       _partial = result.recognizedWords;
  //       if (result.finalResult) {
  //         widget.onTranscription(result.recognizedWords);
  //         _partial = '';
  //       }
  //     },
  //   );
  // }
  //
  // void _showPermissionDeniedSnackbar() {
  //   final messenger = ScaffoldMessenger.maybeOf(context);
  //   if (messenger == null) return;
  //   messenger.showSnackBar(
  //     const SnackBar(
  //       content: Text('Active le micro dans les paramètres pour utiliser la saisie vocale.'),
  //       duration: Duration(seconds: 4),
  //       behavior: SnackBarBehavior.floating,
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    // speech_to_text n'est supporté que sur Android/iOS.
    // Sur web/desktop, on masque le bouton.
    // On utilise defaultTargetPlatform (pas dart:io) pour rester compatible
    // avec les builds web.
    final isMobile = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    if (!isMobile) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, _) {
        final scale = 1.0 + 0.15 * (_listening ? _animController.value : 0);
        return Transform.scale(
          scale: scale,
          child: IconButton(
            onPressed: widget.enabled ? _toggleListening : null,
            icon: Icon(
              _listening ? Icons.mic : Icons.mic_none,
              color: _listening
                  ? AppColors.error
                  : (widget.enabled
                      ? AppColors.primary
                      : AppColors.textDisabled),
              size: 24,
            ),
            tooltip:
                _listening ? 'Arrêter la saisie vocale' : 'Saisie vocale',
            splashRadius: 22,
          ),
        );
      },
    );
  }
}
