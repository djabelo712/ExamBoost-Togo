// lib/screens/settings/tts_settings_screen.dart
// Ecran de configuration de la lecture audio (Text-To-Speech).
//
// Sections :
//   1. Activation           — Switch "Activer la lecture audio"
//   2. Voix                 — Dropdown langue + Dropdown voix + bouton Tester
//   3. Vitesse et ton       — Slider speechRate + Slider pitch + Slider volume
//   4. Comportement         — Switch autoPlay questions / reponses / surlignage
//   5. Apercu               — Texte echantillon + bouton Ecouter + surlignage
//   6. Zone sensible        — Bouton "Reinitialiser les reglages"
//
// Donnees : TtsSettings (Hive box "tts_settings", cle "settings") via
//           TtsService. Persistance immediate a chaque modification.
//
// L'ecran est consommateur de TtsService (Provider) et met a jour les
// settings via ttsService.updateSettings(newSettings).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/tts_settings.dart';
import '../../services/tts_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/audio_player_bar.dart';
import '../../widgets/audio_player_button.dart';
import '../../widgets/tts_settings_widget.dart';

class TtsSettingsScreen extends StatefulWidget {
  const TtsSettingsScreen({super.key});

  @override
  State<TtsSettingsScreen> createState() => _TtsSettingsScreenState();
}

class _TtsSettingsScreenState extends State<TtsSettingsScreen> {
  /// Liste des voix disponibles (chargee async au demarrage).
  List<Map<String, String>> _voices = const [];

  /// Liste des langues disponibles (chargee async au demarrage).
  List<String> _languages = const ['fr-FR'];

  /// True pendant le chargement des voix/langues.
  bool _loadingVoices = false;

  /// Texte d'apercu par defaut (un extrait d'enonce BEPC type).
  static const String _previewText =
      "Resous le systeme d'equations suivant : "
      "2x + 3y = 12 et x - y = 1. "
      "Deduis-en la valeur de x + y.";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadVoicesAndLanguages());
  }

  // ─── Chargement voix/langues ─────────────────────────────────

  Future<void> _loadVoicesAndLanguages() async {
    setState(() => _loadingVoices = true);
    try {
      final tts = context.read<TtsService>();
      final langs = await tts.getAvailableLanguages();
      final voices = await tts.getAvailableVoices();
      if (mounted) {
        setState(() {
          _languages = langs;
          _voices = voices;
          _loadingVoices = false;
        });
      }
    } catch (e) {
      debugPrint('TtsSettings: erreur chargement voix: $e');
      if (mounted) setState(() => _loadingVoices = false);
    }
  }

  /// Recharge les voix quand la langue change (car les voix dependent de la
  /// locale).
  Future<void> _reloadVoicesForLanguage(String language) async {
    setState(() => _loadingVoices = true);
    try {
      final tts = context.read<TtsService>();
      final code = language.split('-').first.toLowerCase();
      final voices = await tts.getAvailableVoices(languageFilter: code);
      if (mounted) {
        setState(() {
          _voices = voices;
          _loadingVoices = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingVoices = false);
    }
  }

  // ─── Handlers de mise a jour ─────────────────────────────────

  Future<void> _update(TtsSettings Function(TtsSettings) mutator) async {
    final tts = context.read<TtsService>();
    final next = mutator(tts.settings.copyWith());
    await tts.updateSettings(next);
  }

  Future<void> _onLanguageChanged(String? lang) async {
    if (lang == null) return;
    await _update((s) => s.copyWith(language: lang, preferredVoice: null));
    await _reloadVoicesForLanguage(lang);
  }

  Future<void> _onVoiceChanged(String? voice) async {
    await _update((s) => s.copyWith(
      preferredVoice: voice,
      clearVoice: voice == null,
    ));
  }

  Future<void> _testVoice() async {
    final tts = context.read<TtsService>();
    await tts.stop();
    await tts.speak(_previewText);
  }

  Future<void> _resetAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reinitialiser les reglages audio ?'),
        content: const Text(
          'Toutes tes preferences de lecture audio seront remises aux '
          'valeurs par defaut (francais, vitesse normale, pas de lecture '
          'automatique).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reinitialiser'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final tts = context.read<TtsService>();
    final fresh = TtsSettings();
    fresh.reset(); // marque l'objet Hive
    await tts.updateSettings(fresh);
    await _loadVoicesAndLanguages();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reglages reinitialises.')),
      );
    }
  }

  // ─── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lecture audio'),
      ),
      body: Consumer<TtsService>(
        builder: (context, tts, _) {
          final s = tts.settings;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIntroCard(),
                const SizedBox(height: 20),

                // 1. Activation
                const TtsSectionTitle(text: 'Activation', icon: Icons.power_settings_new),
                _buildActivationCard(s),
                const SizedBox(height: 16),

                // 2. Voix
                const TtsSectionTitle(text: 'Voix', icon: Icons.record_voice_over),
                _buildVoiceCard(s),
                const SizedBox(height: 16),

                // 3. Vitesse et ton
                const TtsSectionTitle(text: 'Vitesse et ton', icon: Icons.speed),
                _buildSpeedCard(s),
                const SizedBox(height: 16),

                // 4. Comportement
                const TtsSectionTitle(text: 'Comportement', icon: Icons.tune),
                _buildBehaviorCard(s),
                const SizedBox(height: 16),

                // 5. Apercu
                const TtsSectionTitle(text: 'Apercu', icon: Icons.preview),
                _buildPreviewCard(s),
                const SizedBox(height: 24),

                // 6. Zone sensible
                _buildDangerCard(),
                const SizedBox(height: 32),

                // Barre lecteur (visible seulement si lecture en cours)
                // NB: l'agent wiring peut aussi l'ajouter en bottomSheet global.
              ],
            ),
          );
        },
      ),
      // AudioPlayerBar se masque automatiquement si aucune lecture en cours.
      bottomSheet: const AudioPlayerBar(),
    );
  }

  // ─── Composants UI ───────────────────────────────────────────

  Widget _buildIntroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.hearing, color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Configure la lecture audio des questions pour ecouter tes '
              'enonces a voix haute. Utile pour les eleves dyslexiques, '
              'malvoyants, ou pour reviser en marchant.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivationCard(TtsSettings s) {
    return TtsSettingsCard(
      child: TtsSwitchRow(
        icon: s.enabled ? Icons.volume_up : Icons.volume_off,
        iconColor: s.enabled ? AppColors.primary : AppColors.textSecondary,
        title: 'Activer la lecture audio',
        subtitle: 'Affiche un bouton "Ecouter" a cote de chaque question. '
            'Desactivee, aucun son ne sera emis meme si tu appuies sur les boutons.',
        value: s.enabled,
        onChanged: (v) => _update((x) => x.copyWith(enabled: v)),
      ),
    );
  }

  Widget _buildVoiceCard(TtsSettings s) {
    return TtsSettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dropdown langue
          Text('Langue', style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w500,
          )),
          const SizedBox(height: 4),
          Text(
            'Choisis la langue de synthese vocale. Le francais (fr-FR) est '
            'recommande pour les examens togolais.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _languages.contains(s.language) ? s.language : null,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            items: _languages
                .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                .toList(),
            onChanged: s.enabled ? _onLanguageChanged : null,
          ),
          const SizedBox(height: 16),

          // Dropdown voix
          Text('Voix', style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w500,
          )),
          const SizedBox(height: 4),
          Text(
            'Selectionne une voix specifique (homme/femme) si plusieurs sont '
            'installees sur ton appareil. Par defaut, le moteur systeme choisit.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 8),
          _loadingVoices
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : DropdownButtonFormField<String>(
                  value: s.preferredVoice != null &&
                          _voices.any((v) => v['name'] == s.preferredVoice)
                      ? s.preferredVoice
                      : null,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    hintText: 'Voix par defaut',
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Voix par defaut'),
                    ),
                    ..._voices.map(
                      (v) => DropdownMenuItem<String>(
                        value: v['name'],
                        child: Text(
                          v['name'] ?? 'voix',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: s.enabled ? _onVoiceChanged : null,
                ),
          const SizedBox(height: 16),

          // Bouton tester
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: s.enabled ? _testVoice : null,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Tester la voix'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedCard(TtsSettings s) {
    return TtsSettingsCard(
      child: Column(
        children: [
          TtsSliderRow(
            label: 'Vitesse de lecture',
            valueLabel: '${s.speechRate.toStringAsFixed(1)}x',
            value: s.speechRate,
            min: 0.5,
            max: 2.0,
            divisions: 15, // pas de 0.1
            onChanged: s.enabled
                ? (v) => _update((x) => x.copyWith(speechRate: v))
                : null,
            helper: '1.0x = normale | 0.5x = tres lent | 2.0x = rapide',
          ),
          const Divider(height: 28),
          TtsSliderRow(
            label: 'Ton (pitch)',
            valueLabel: s.pitch.toStringAsFixed(1),
            value: s.pitch,
            min: 0.5,
            max: 2.0,
            divisions: 15,
            onChanged: s.enabled
                ? (v) => _update((x) => x.copyWith(pitch: v))
                : null,
            helper: 'Plus bas = voix grave | Plus haut = voix aigue',
          ),
          const Divider(height: 28),
          TtsSliderRow(
            label: 'Volume',
            valueLabel: '${(s.volume * 100).round()}%',
            value: s.volume,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            onChanged: s.enabled
                ? (v) => _update((x) => x.copyWith(volume: v))
                : null,
            helper: '100% = volume max de ton appareil',
          ),
        ],
      ),
    );
  }

  Widget _buildBehaviorCard(TtsSettings s) {
    return TtsSettingsCard(
      child: Column(
        children: [
          TtsSwitchRow(
            icon: Icons.auto_awesome,
            iconColor: AppColors.accent,
            title: 'Lire automatiquement les questions',
            subtitle: 'Lance la lecture des qu\'une question s\'ouvre dans la '
                'revision. Pratique en transport, surprend en classe.',
            value: s.autoPlayOnQuestionOpen,
            onChanged: s.enabled
                ? (v) => _update((x) => x.copyWith(autoPlayOnQuestionOpen: v))
                : null,
          ),
          const Divider(height: 24),
          TtsSwitchRow(
            icon: Icons.lightbulb_outline,
            iconColor: AppColors.info,
            title: 'Lire aussi les reponses',
            subtitle: 'Apres avoir tape "Voir la reponse", lit la reponse et '
                'l\'explication a voix haute. Permet la revision auditive pure.',
            value: s.autoPlayAnswers,
            onChanged: s.enabled
                ? (v) => _update((x) => x.copyWith(autoPlayAnswers: v))
                : null,
          ),
          const Divider(height: 24),
          TtsSwitchRow(
            icon: Icons.highlight,
            iconColor: AppColors.warning,
            title: 'Surligner le texte en cours de lecture',
            subtitle: 'Met en jaune le mot en cours de prononciation. Aide la '
                'comprehension (lecture + ecoute simultanees).',
            value: s.highlightTextAsSpoken,
            onChanged: s.enabled
                ? (v) => _update((x) => x.copyWith(highlightTextAsSpoken: v))
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(TtsSettings s) {
    return TtsSettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.format_quote, color: AppColors.primary, size: 20),
              const SizedBox(width: 6),
              Text('Echantillon', style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w500,
              )),
              const Spacer(),
              const TtsNowPlayingBadge(),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: s.highlightTextAsSpoken
                ? HighlightedTextPreview(text: _previewText)
                : Text(_previewText, style: AppTextStyles.questionText),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              AudioPlayerButton(text: _previewText, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Appuie sur le bouton pour ecouter cet echantillon avec '
                  'tes reglages actuels.',
                  style: AppTextStyles.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDangerCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning, color: AppColors.error),
              const SizedBox(width: 8),
              Text('Zone sensible',
                  style: AppTextStyles.h3.copyWith(color: AppColors.error)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Remet tous les reglages audio a leurs valeurs par defaut.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
              onPressed: _resetAll,
              icon: const Icon(Icons.restart_alt),
              label: const Text('Reinitialiser les reglages audio'),
            ),
          ),
        ],
      ),
    );
  }
}
