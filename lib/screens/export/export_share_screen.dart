// lib/screens/export/export_share_screen.dart
// Écran de partage du rapport PDF généré.
//
// Trois actions disponibles :
//   1. Email    — ouvre la feu de partage système pré-remplie (sujet + corps).
//   2. WhatsApp — ouvre la feu de partage système (utilisateur choisit WhatsApp).
//   3. Sauvegarder localement — écrit le PDF dans le répertoire documents de l'app.
//
// Note sur share_plus : le package ne permet pas de forcer une app cible
// de façon fiable cross-platform. On pré-remplit juste le sujet et le corps,
// ce qui oriente naturellement vers les apps mail/messaging. L'utilisateur
// sélectionne ensuite l'application souhaitée dans la feu système.

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../services/pdf_export_service.dart';
import '../../theme/adaptive_colors.dart';
import '../../theme/app_theme.dart';

class ExportShareScreen extends StatefulWidget {
  /// Octets bruts du PDF généré.
  final Uint8List pdfBytes;

  /// Données de l'élève (pour le nom de fichier et le corps email).
  final ExportData data;

  /// Options d'export (destinataire, période, format).
  final ExportOptions options;

  /// Mode de partage à présélectionner à l'ouverture.
  /// Valeurs : 'email', 'whatsapp', 'save', 'share' (générique).
  final String initialMode;

  const ExportShareScreen({
    super.key,
    required this.pdfBytes,
    required this.data,
    required this.options,
    this.initialMode = 'share',
  });

  @override
  State<ExportShareScreen> createState() => _ExportShareScreenState();
}

class _ExportShareScreenState extends State<ExportShareScreen> {
  /// Indique si une opération de partage est en cours.
  bool _busy = false;

  /// Dernier résultat (succès ou message d'erreur).
  String? _statusMessage;
  bool _statusIsError = false;

  /// Chemin du fichier sauvegardé localement (si save a été appelé).
  String? _savedPath;

  @override
  void initState() {
    super.initState();
    // Si un mode initial est fourni, on déclenche automatiquement l'action.
    if (widget.initialMode != 'share') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleAction(widget.initialMode);
      });
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partager le rapport'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(context),
            const SizedBox(height: 24),
            Text(
              'Choisir une option de partage',
              style: AppTextStyles.h3.copyWith(
                color: AdaptiveColors.textPrimary(context),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            _buildShareOption(
              context,
              icon: Icons.mail_outline,
              color: AppColors.primary,
              title: 'Envoyer par email',
              subtitle:
                  'Ouvre votre application mail avec le rapport en pièce jointe',
              onTap: () => _handleAction('email'),
            ),
            const SizedBox(height: 10),
            _buildShareOption(
              context,
              icon: Icons.chat_outlined,
              color: AppColors.success,
              title: 'Partager via WhatsApp',
              subtitle:
                  'Ouvre la feu de partage — sélectionnez WhatsApp dans la liste',
              onTap: () => _handleAction('whatsapp'),
            ),
            const SizedBox(height: 10),
            _buildShareOption(
              context,
              icon: Icons.save_alt,
              color: AppColors.accent,
              title: 'Sauvegarder localement',
              subtitle:
                  'Enregistre le PDF dans le dossier documents de l\'application',
              onTap: () => _handleAction('save'),
            ),
            const SizedBox(height: 10),
            _buildShareOption(
              context,
              icon: Icons.share_outlined,
              color: AdaptiveColors.textSecondary(context),
              title: 'Autres applications',
              subtitle: 'Feu de partage système générique (Drive, Telegram, etc.)',
              onTap: () => _handleAction('share'),
            ),
            const SizedBox(height: 24),

            if (_statusMessage != null) ...[
              _buildStatusBanner(context),
              const SizedBox(height: 16),
            ],
            if (_savedPath != null) ...[
              _buildSavedPathCard(context),
              const SizedBox(height: 16),
            ],
            if (_busy)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ─── Carte résumé ──────────────────────────────────────────────────

  Widget _buildSummaryCard(BuildContext context) {
    final user = widget.data.user;
    final score = user.scoreGlobal.round();
    final bepc = (widget.data.prediction?.scoreGlobal ?? 0.0)
        .toStringAsFixed(1);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdaptiveColors.primarySurface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AdaptiveColors.primary(context).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.picture_as_pdf,
                  color: AdaptiveColors.primary(context), size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Rapport prêt à partager',
                  style: AppTextStyles.h3.copyWith(
                    color: AdaptiveColors.textPrimary(context),
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildInfoRow(context, 'Élève', user.nomComplet),
          _buildInfoRow(context, 'Destinataire', widget.options.recipient.shortLabel),
          _buildInfoRow(context, 'Période', widget.options.period.label),
          _buildInfoRow(context, 'Format', widget.options.format.label),
          _buildInfoRow(context, 'Score global', '$score %'),
          _buildInfoRow(context, 'Prédiction examen', '$bepc / 20'),
          _buildInfoRow(
              context, 'Taille du fichier', _formatBytes(widget.pdfBytes.length)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.bodySmall.copyWith(
                  color: AdaptiveColors.textSecondary(context), fontSize: 12)),
          Text(value,
              style: AppTextStyles.body.copyWith(
                color: AdaptiveColors.textPrimary(context),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              )),
        ],
      ),
    );
  }

  // ─── Option de partage ─────────────────────────────────────────────

  Widget _buildShareOption(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AdaptiveColors.surface(context),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _busy ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AdaptiveColors.divider(context),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.body.copyWith(
                        color: AdaptiveColors.textPrimary(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 11,
                        color: AdaptiveColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: AdaptiveColors.textDisabled(context), size: 22),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Bannière de statut ────────────────────────────────────────────

  Widget _buildStatusBanner(BuildContext context) {
    final color = _statusIsError ? AppColors.error : AppColors.success;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(
            _statusIsError ? Icons.error_outline : Icons.check_circle,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _statusMessage!,
              style: AppTextStyles.bodySmall.copyWith(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedPathCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdaptiveColors.accentSurface(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accent.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder_open, color: AppColors.accent, size: 18),
              const SizedBox(width: 8),
              Text(
                'Fichier sauvegardé',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _savedPath!,
            style: AppTextStyles.bodySmall.copyWith(
              color: AdaptiveColors.textSecondary(context),
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  // ─── Dispatch des actions ──────────────────────────────────────────

  Future<void> _handleAction(String mode) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _statusMessage = null;
      _statusIsError = false;
    });

    try {
      switch (mode) {
        case 'email':
          await PdfExportService.instance.shareViaEmail(
            widget.pdfBytes,
            widget.data,
            widget.options,
          );
          if (mounted) {
            setState(() {
              _statusMessage =
                  'Feuille de partage ouverte. Sélectionnez votre application '
                  'email pour envoyer le rapport en pièce jointe.';
            });
          }
          break;

        case 'whatsapp':
          await PdfExportService.instance.shareViaWhatsApp(
            widget.pdfBytes,
            widget.data,
            widget.options,
          );
          if (mounted) {
            setState(() {
              _statusMessage =
                  'Feuille de partage ouverte. Sélectionnez WhatsApp dans la '
                  'liste des applications pour transmettre le fichier PDF.';
            });
          }
          break;

        case 'save':
          final file = await PdfExportService.instance.saveToFile(
            widget.pdfBytes,
            widget.data,
          );
          if (mounted) {
            setState(() {
              _savedPath = file.path;
              _statusMessage =
                  'Rapport sauvegardé avec succès dans le dossier documents '
                  'de l\'application.';
            });
          }
          break;

        case 'share':
        default:
          await PdfExportService.instance.shareGeneric(
            widget.pdfBytes,
            widget.data,
            widget.options,
          );
          if (mounted) {
            setState(() {
              _statusMessage = 'Feuille de partage système ouverte.';
            });
          }
          break;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusIsError = true;
          _statusMessage = 'Erreur : ${e.toString()}';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes o';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} Ko';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }
}
