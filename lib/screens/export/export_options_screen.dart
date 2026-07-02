// lib/screens/export/export_options_screen.dart
// Écran de configuration du rapport PDF de progression.
//
// L'utilisateur choisit :
//   1. La période couverte (7j, 30j, 90j, tout).
//   2. Le contenu inclus (6 sections toggleable).
//   3. Le format de page (A4 portrait / paysage).
//   4. Le destinataire (parent, enseignant, moi).
//
// Puis navigue vers [ExportPreviewScreen] qui génère et affiche le PDF.
//
// Données : aucune lecture ici — juste capture de la configuration. La
// lecture Hive + calculs a lieu dans [PdfExportService.loadData] appelé
// par l'écran de preview. On évite ainsi tout travail inutile si l'utilisateur
// annule.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/badge_service.dart';
import '../../services/pdf_export_service.dart';
import '../../services/srs_service.dart';
import '../../theme/adaptive_colors.dart';
import '../../theme/app_theme.dart';
import 'export_preview_screen.dart';

class ExportOptionsScreen extends StatefulWidget {
  const ExportOptionsScreen({super.key});

  @override
  State<ExportOptionsScreen> createState() => _ExportOptionsScreenState();
}

class _ExportOptionsScreenState extends State<ExportOptionsScreen> {
  ExportOptions _options = const ExportOptions();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exporter ma progression'),
        automaticallyImplyLeading: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // ─── Intro ────────────────────────────────────────────────
          _buildIntroCard(context),
          const SizedBox(height: 20),

          // ─── 1. Période ───────────────────────────────────────────
          _buildSectionTitle(context, '1. Période couverte'),
          const SizedBox(height: 8),
          _buildPeriodSelector(context),
          const SizedBox(height: 24),

          // ─── 2. Contenu inclus ────────────────────────────────────
          _buildSectionTitle(context, '2. Sections à inclure'),
          const SizedBox(height: 8),
          _buildContentToggles(context),
          const SizedBox(height: 24),

          // ─── 3. Format ────────────────────────────────────────────
          _buildSectionTitle(context, '3. Format de page'),
          const SizedBox(height: 8),
          _buildFormatSelector(context),
          const SizedBox(height: 24),

          // ─── 4. Destinataire ──────────────────────────────────────
          _buildSectionTitle(context, '4. Destinataire'),
          const SizedBox(height: 8),
          _buildRecipientSelector(context),
          const SizedBox(height: 32),

          // ─── Bouton Générer ───────────────────────────────────────
          _buildGenerateButton(context, isDark),
          const SizedBox(height: 12),
          Text(
            'Le PDF sera généré puis prévisualisé avant partage. '
            'Vous pourrez l\'envoyer par email ou WhatsApp.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: AdaptiveColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── Intro ──────────────────────────────────────────────────────────

  Widget _buildIntroCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdaptiveColors.primarySurface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AdaptiveColors.primary(context).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.picture_as_pdf,
              color: AdaptiveColors.primary(context), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rapport de progression personnalisé',
                  style: AppTextStyles.h3.copyWith(
                    color: AdaptiveColors.textPrimary(context),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Générez un PDF partageable avec vos parents, enseignants '
                  'ou pour vous-même. Le rapport inclut votre score, votre '
                  'prédiction BEPC/BAC, vos badges et des recommandations.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AdaptiveColors.textSecondary(context),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Titre de section ───────────────────────────────────────────────

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: AppTextStyles.h3.copyWith(
        color: AdaptiveColors.textPrimary(context),
        fontSize: 16,
      ),
    );
  }

  // ─── 1. Sélecteur de période ────────────────────────────────────────

  Widget _buildPeriodSelector(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ExportPeriod.values.map((p) {
        final selected = _options.period == p;
        return ChoiceChip(
          label: Text(p.label),
          selected: selected,
          onSelected: (_) {
            setState(() => _options = _options.copyWith(period: p));
          },
          selectedColor: AdaptiveColors.primary(context),
          labelStyle: TextStyle(
            color: selected
                ? Colors.white
                : AdaptiveColors.textPrimary(context),
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        );
      }).toList(),
    );
  }

  // ─── 2. Toggles de contenu ──────────────────────────────────────────

  Widget _buildContentToggles(BuildContext context) {
    final c = _options.content;
    return Container(
      decoration: BoxDecoration(
        color: AdaptiveColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AdaptiveColors.divider(context),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildToggle(
            context,
            icon: Icons.insights,
            title: 'Score global + prédiction BEPC',
            subtitle: 'Score de maîtrise et note estimée à l\'examen officiel',
            value: c.includeGlobalScore,
            onChanged: (v) => setState(() => _options = _options.copyWith(
                content: c.copyWith(includeGlobalScore: v))),
          ),
          _divider(context),
          _buildToggle(
            context,
            icon: Icons.bar_chart,
            title: 'Progression par matière',
            subtitle: 'Barres horizontales de maîtrise par matière',
            value: c.includeSubjectProgress,
            onChanged: (v) => setState(() => _options = _options.copyWith(
                content: c.copyWith(includeSubjectProgress: v))),
          ),
          _divider(context),
          _buildToggle(
            context,
            icon: Icons.grid_on,
            title: 'Chapitres à travailler',
            subtitle: 'Heatmap des 5 compétences les plus faibles',
            value: c.includeHeatmap,
            onChanged: (v) => setState(() => _options = _options.copyWith(
                content: c.copyWith(includeHeatmap: v))),
          ),
          _divider(context),
          _buildToggle(
            context,
            icon: Icons.emoji_events,
            title: 'Badges débloqués',
            subtitle: 'Grille des badges avec niveau et XP',
            value: c.includeBadges,
            onChanged: (v) => setState(() => _options = _options.copyWith(
                content: c.copyWith(includeBadges: v))),
          ),
          _divider(context),
          _buildToggle(
            context,
            icon: Icons.repeat,
            title: 'Statistiques SRS',
            subtitle: 'Cartes dues, maîtrisées, en apprentissage',
            value: c.includeSrsStats,
            onChanged: (v) => setState(() => _options = _options.copyWith(
                content: c.copyWith(includeSrsStats: v))),
          ),
          _divider(context),
          _buildToggle(
            context,
            icon: Icons.tips_and_updates,
            title: 'Recommandations',
            subtitle: 'Suggestions pédagogiques automatiques',
            value: c.includeRecommendations,
            onChanged: (v) => setState(() => _options = _options.copyWith(
                content: c.copyWith(includeRecommendations: v))),
          ),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) => Divider(
        height: 1,
        thickness: 0.5,
        color: AdaptiveColors.divider(context),
      );

  Widget _buildToggle(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      secondary: Icon(icon,
          color: value
              ? AdaptiveColors.primary(context)
              : AdaptiveColors.textDisabled(context),
          size: 24),
      title: Text(
        title,
        style: AppTextStyles.body.copyWith(
          color: AdaptiveColors.textPrimary(context),
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(
          fontSize: 11,
          color: AdaptiveColors.textSecondary(context),
        ),
      ),
      activeColor: AdaptiveColors.primary(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  // ─── 3. Sélecteur de format ─────────────────────────────────────────

  Widget _buildFormatSelector(BuildContext context) {
    return SegmentedButton<ExportFormat>(
      segments: ExportFormat.values
          .map((f) => ButtonSegment(
                value: f,
                icon: Icon(f == ExportFormat.a4Portrait
                    ? Icons.stay_current_portrait
                    : Icons.stay_current_landscape),
                label: Text(f.label),
              ))
          .toList(),
      selected: {_options.format},
      onSelectionChanged: (set) {
        setState(() => _options = _options.copyWith(format: set.first));
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.comfortable,
        backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return AdaptiveColors.primary(context);
          }
          return AdaptiveColors.surface(context);
        }),
        foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return AdaptiveColors.textPrimary(context);
        }),
      ),
    );
  }

  // ─── 4. Sélecteur de destinataire ───────────────────────────────────

  Widget _buildRecipientSelector(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AdaptiveColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AdaptiveColors.divider(context),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: ExportRecipient.values.map((r) {
          final selected = _options.recipient == r;
          return RadioListTile<ExportRecipient>(
            value: r,
            groupValue: _options.recipient,
            onChanged: (v) {
              if (v != null) {
                setState(() => _options = _options.copyWith(recipient: v));
              }
            },
            activeColor: AdaptiveColors.primary(context),
            title: Text(
              r.shortLabel,
              style: AppTextStyles.body.copyWith(
                color: AdaptiveColors.textPrimary(context),
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            subtitle: Text(
              _recipientHint(r),
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 11,
                color: AdaptiveColors.textSecondary(context),
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            dense: true,
          );
        }).toList(),
      ),
    );
  }

  String _recipientHint(ExportRecipient r) {
    switch (r) {
      case ExportRecipient.parent:
        return 'Ton encourageant, explications des indicateurs pédagogiques.';
      case ExportRecipient.teacher:
        return 'Ton pédagogique, détails BKT/SRS pour suivi en classe.';
      case ExportRecipient.self:
        return 'Pour vous-même — suivi personnel de progression.';
    }
  }

  // ─── Bouton Générer ─────────────────────────────────────────────────

  Widget _buildGenerateButton(BuildContext context, bool isDark) {
    final canGenerate = _options.content.hasAtLeastOneSection;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canGenerate ? _goToPreview : null,
        icon: const Icon(Icons.picture_as_pdf, size: 22),
        label: const Text('Générer le rapport PDF'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AdaptiveColors.primary(context),
          foregroundColor: Colors.white,
          disabledBackgroundColor: AdaptiveColors.surfaceVariant(context),
          disabledForegroundColor: AdaptiveColors.textDisabled(context),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _goToPreview() {
    // Récupération des services via Provider (déjà initialisés au main()).
    final srsService = Provider.of<SrsService>(context, listen: false);
    final badgeService = Provider.of<BadgeService>(context, listen: false);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExportPreviewScreen(
          options: _options,
          srsService: srsService,
          badgeService: badgeService,
        ),
      ),
    );
  }
}
