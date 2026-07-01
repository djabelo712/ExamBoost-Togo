// lib/widgets/audio_player_bar.dart
// Barre lecteur sticky avec progression, duree et controles.
//
// Affichee en bas de l'ecran (via Scaffold.bottomSheet ou Stack) quand TTS
// est en lecture. Disparait automatiquement a la fin ou au stop.
//
// Layout :
//   [bouton play/pause] [progress bar] [00:05 / 00:12] [X stop]
//
// Limites TTS :
//   - flutter_tts ne donne pas la duree totale a l'avance. On approxime avec
//     le ratio mot courant / nombre total de mots.
//   - La duree affichee (00:12) estimee = nbMots * (60000 / motsParMinute).
//     Mots par minute ~ 150 * speechRate. Donc 1.0x = 150 wpm, 2.0x = 300 wpm.
//
// Usage :
//   Scaffold(
//     body: ...,
//     bottomSheet: AudioPlayerBar(),  // se masque tout seul si inactif
//   )

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/audio_playback_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';

class AudioPlayerBar extends StatelessWidget {
  /// True pour compacter la barre (mode mobile etroit). Defaut false.
  final bool compact;

  const AudioPlayerBar({super.key, this.compact = false});

  /// Estimation mots par minute en fonction du speechRate.
  /// Reference : un lecteur humain moyen = 150 wpm ; TTS a 1.0x = ~150-180 wpm.
  static const double _baseWordsPerMinute = 150.0;

  @override
  Widget build(BuildContext context) {
    return Consumer2<TtsService, AudioPlaybackService>(
      builder: (context, tts, playback, _) {
        if (!playback.isActive) {
          return const SizedBox.shrink();
        }

        final text = playback.currentText;
        if (text.isEmpty) return const SizedBox.shrink();

        final totalWords = _countWords(text);
        final currentWordIndex = _estimateCurrentWordIndex(text, tts);
        final progress = totalWords == 0
            ? 0.0
            : (currentWordIndex / totalWords).clamp(0.0, 1.0);

        final totalMs = _estimateTotalMs(totalWords, tts.settings.speechRate);
        final elapsedMs = (progress * totalMs).toInt();

        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 14,
              vertical: compact ? 6 : 10,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, -2),
                ),
              ],
              border: Border.all(
                color: AppColors.primary.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                _buildPlayPauseButton(playback),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Apercu du texte en cours (1 ligne tronquee)
                      Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Progress bar + compteur temps
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 5,
                                backgroundColor:
                                    AppColors.primarySurface,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  playback.isPaused
                                      ? AppColors.textSecondary
                                      : AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_formatMs(elapsedMs)} / ${_formatMs(totalMs)}',
                            style: AppTextStyles.label.copyWith(
                              fontFeatures: const [FontFeature.tabularFigures()],
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildReplayButton(playback),
                _buildStopButton(playback),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Sous-composants ─────────────────────────────────────────

  Widget _buildPlayPauseButton(AudioPlaybackService playback) {
    final isPaused = playback.isPaused;
    return Material(
      color: AppColors.primary,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => playback.togglePlayPause(),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(
            isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildReplayButton(AudioPlaybackService playback) {
    return IconButton(
      onPressed: () => playback.replay(),
      icon: const Icon(Icons.replay_rounded),
      color: AppColors.textSecondary,
      iconSize: 20,
      tooltip: 'Relire depuis le debut',
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      padding: EdgeInsets.zero,
    );
  }

  Widget _buildStopButton(AudioPlaybackService playback) {
    return IconButton(
      onPressed: () => playback.stop(),
      icon: const Icon(Icons.close_rounded),
      color: AppColors.error,
      iconSize: 20,
      tooltip: 'Arreter la lecture',
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      padding: EdgeInsets.zero,
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────

  int _countWords(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(RegExp(r'\s+')).length;
  }

  /// Estime l'index du mot en cours (0-based) a partir de l'offset character
  /// du TTS. Compte le nombre d'espaces avant [_currentWordStartOffset].
  int _estimateCurrentWordIndex(String text, TtsService tts) {
    final offset = tts.currentWordStartOffset;
    if (offset <= 0) return 0;
    if (offset >= text.length) return _countWords(text);
    final sub = text.substring(0, offset);
    return sub.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  /// Duree totale estimee en millisecondes.
  int _estimateTotalMs(int totalWords, double speechRate) {
    if (totalWords == 0) return 0;
    final wpm = _baseWordsPerMinute * speechRate;
    final minutes = totalWords / wpm;
    return (minutes * 60 * 1000).round();
  }

  String _formatMs(int ms) {
    if (ms <= 0) return '00:00';
    final totalSeconds = (ms / 1000).round();
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
