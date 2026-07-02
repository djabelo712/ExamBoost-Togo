// lib/screens/export/export_preview_screen.dart
// Écran de prévisualisation du rapport PDF généré.
//
// Pipeline :
//   1. Au démarrage, affiche [ExportProgressIndicator] (étape loadingData).
//   2. Appelle [PdfExportService.loadData] pour charger Hive + calculs.
//   3. Appelle [PdfExportService.generatePdf] pour construire le document.
//   4. Affiche le PDF via [PdfPreview] (package printing) — navigateur de
//      pages natif (zoom, swipe).
//   5. Boutons d'action : Partager (email), Partager (WhatsApp),
//      Sauvegarder localement, Refaire.
//
// En cas d'erreur, affiche un message avec bouton « Réessayer ».

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../services/badge_service.dart';
import '../../services/pdf_export_service.dart';
import '../../services/srs_service.dart';
import '../../theme/adaptive_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/export_progress_indicator.dart';
import 'export_share_screen.dart';

class ExportPreviewScreen extends StatefulWidget {
  final ExportOptions options;
  final SrsService srsService;
  final BadgeService badgeService;

  const ExportPreviewScreen({
    super.key,
    required this.options,
    required this.srsService,
    required this.badgeService,
  });

  @override
  State<ExportPreviewScreen> createState() => _ExportPreviewScreenState();
}

class _ExportPreviewScreenState extends State<ExportPreviewScreen> {
  /// Étape courante du pipeline (pour l'indicateur de progression).
  ExportStep _step = ExportStep.loadingData;

  /// 1-indexed, sur 4 (load, compute, build, write).
  int _currentStepNumber = 1;

  /// Message d'erreur si la génération échoue.
  String? _errorMessage;

  /// Données chargées (prêtes pour la génération).
  ExportData? _data;

  /// PDF généré (octets bruts).
  Uint8List? _pdfBytes;

  @override
  void initState() {
    super.initState();
    // Lancement différé hors du build pour éviter les rebuilds pendant
    // l'opération asynchrone.
    WidgetsBinding.instance.addPostFrameCallback((_) => _generate());
  }

  // ─── Pipeline de génération ────────────────────────────────────────

  Future<void> _generate() async {
    setState(() {
      _step = ExportStep.loadingData;
      _currentStepNumber = 1;
      _errorMessage = null;
    });

    try {
      // Étape 1 : chargement des données (Hive + calculs + prédiction).
      final data = await PdfExportService.instance.loadData(
        widget.options,
        widget.srsService,
        widget.badgeService,
      );

      if (!mounted) return;
      setState(() {
        _data = data;
        _step = ExportStep.computingStats;
        _currentStepNumber = 2;
      });

      // Étape 2 : la plupart des calculs sont déjà faits dans loadData
      // (mastery, weak chapters, streak, weekly activity). On garde cette
      // étape pour la lisibilité du pipeline — elle correspond au passage
      // dans ScorePredictor (potentiellement réseau/disque).

      // Étape 3 : construction du document PDF.
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      setState(() {
        _step = ExportStep.buildingPdf;
        _currentStepNumber = 3;
      });

      final bytes = await PdfExportService.instance.generatePdf(
        widget.options,
        data,
      );

      if (!mounted) return;
      setState(() {
        _pdfBytes = bytes;
        _step = ExportStep.done;
        _currentStepNumber = 4;
      });
    } catch (e, stack) {
      debugPrint('ExportPreviewScreen._generate() error: $e\n$stack');
      if (mounted) {
        setState(() {
          _step = ExportStep.error;
          _errorMessage = e.toString();
        });
      }
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isReady = _pdfBytes != null && _data != null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aperçu du rapport'),
        actions: [
          if (isReady) ...[
            IconButton(
              tooltip: 'Partager',
              icon: const Icon(Icons.share),
              onPressed: () => _openShareScreen(context),
            ),
            IconButton(
              tooltip: 'Régénérer',
              icon: const Icon(Icons.refresh),
              onPressed: _regenerate,
            ),
          ],
        ],
      ),
      body: _buildBody(context),
      bottomNavigationBar: isReady ? _buildBottomBar(context) : null,
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_step == ExportStep.error) {
      return _buildErrorView(context);
    }
    if (_pdfBytes == null || _data == null) {
      return _buildLoadingView(context);
    }
    return _buildPdfPreview(context);
  }

  // ─── Vue chargement ────────────────────────────────────────────────

  Widget _buildLoadingView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ExportProgressIndicator(
          step: _step,
          currentStep: _currentStepNumber,
          totalSteps: 4,
        ),
      ),
    );
  }

  // ─── Vue erreur ────────────────────────────────────────────────────

  Widget _buildErrorView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Échec de la génération',
              style: AppTextStyles.h2
                  .copyWith(color: AdaptiveColors.textPrimary(context)),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Une erreur inconnue est survenue.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AdaptiveColors.textSecondary(context)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _regenerate,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Vue aperçu PDF ────────────────────────────────────────────────

  Widget _buildPdfPreview(BuildContext context) {
    // PdfPreview est fourni par le package printing. Il rend le PDF en
    // raster (image) et permet le zoom/swipe natif.
    return PdfPreview(
      build: (format) async => _pdfBytes!,
      initialPageFormat: widget.options.format.pageFormat,
      padding: const EdgeInsets.all(12),
      scrollViewDecoration: BoxDecoration(
        color: AdaptiveColors.surfaceVariant(context),
      ),
      pdfFileName:
          'Rapport_ExamBoost_${_data!.user.nomComplet.replaceAll(RegExp(r"\s+"), "_")}.pdf',
      // Désactive les actions par défaut de PdfPreview (on a notre propre
      // bottom bar avec les boutons de partage).
      actions: const <Widget>[],
      canChangePageFormat: false,
      canDebug: false,
      onError: (error) {
        debugPrint('PdfPreview render error: $error');
        return Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              'Erreur de rendu PDF : $error',
              style: const TextStyle(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }

  // ─── Bottom bar (actions) ──────────────────────────────────────────

  Widget _buildBottomBar(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AdaptiveColors.surface(context),
          boxShadow: [
            BoxShadow(
              color: AdaptiveColors.shadow(context),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _openShareScreen(context, mode: 'email'),
                icon: const Icon(Icons.mail, size: 20),
                label: const Text('Email'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AdaptiveColors.primary(context),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _openShareScreen(context, mode: 'whatsapp'),
                icon: const Icon(Icons.chat, size: 20),
                label: const Text('WhatsApp'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _openShareScreen(context, mode: 'save'),
                icon: const Icon(Icons.save_alt, size: 20),
                label: const Text('Sauver'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdaptiveColors.primary(context),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Navigation ────────────────────────────────────────────────────

  void _openShareScreen(BuildContext context, {String mode = 'share'}) {
    if (_pdfBytes == null || _data == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExportShareScreen(
          pdfBytes: _pdfBytes!,
          data: _data!,
          options: widget.options,
          initialMode: mode,
        ),
      ),
    );
  }

  void _regenerate() {
    setState(() {
      _pdfBytes = null;
      _data = null;
    });
    _generate();
  }
}
