// lib/services/pdf_export_service.dart
// Service de génération de rapport PDF de progression ExamBoost Togo.
//
// Mission : produire un PDF personnalisé partageable avec les parents et
// enseignants (score global, prédiction BEPC, progression par matière,
// chapitres à travailler, badges, stats SRS, recommandations).
//
// Dépendances à ajouter au pubspec.yaml (ne pas toucher ici — Agent BA gère) :
//   pdf: ^3.11.0           — construction du document PDF
//   printing: ^5.13.3      — rendu PdfPreview + rasterisation
//   share_plus: ^9.0.0     — partage fichier (email, WhatsApp, etc.)
//   path_provider: ^2.1.3  — déjà présent (répertoire cache)
//
// Sources de données (lecture seule, jamais écriture) :
//   - Hive box "users"         -> AppUser (bktMaitrise, scoreGlobal, etc.)
//   - Hive box "review_cards"  -> ReviewCard[] (filtrage par période)
//   - SrsService.getStats()    -> SrsStats (dueToday, mastered, learning)
//   - BadgeService             -> badges débloqués
//   - ScorePredictor           -> ScorePrediction (cache < 1h)
//   - QuestionService          -> matières + chapitres (liaison competenceId)
//
// Usage typique :
//   final options = ExportOptions(...);
//   final data = await PdfExportService.instance.loadData(options, userId);
//   final bytes = await PdfExportService.instance.generatePdf(options, data);
//   await PdfExportService.instance.shareViaEmail(bytes, options, data);

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/badge.dart';
import '../models/review_card.dart';
import '../models/score_prediction.dart';
import '../models/user.dart';
import 'badge_service.dart';
import 'score_predictor.dart';
import 'srs_service.dart';

// ─── Enumérations publiques ──────────────────────────────────────────

/// Période couverte par le rapport PDF.
enum ExportPeriod {
  /// 7 derniers jours.
  sevenDays('7 derniers jours', Duration(days: 7)),

  /// 30 derniers jours.
  thirtyDays('30 derniers jours', Duration(days: 30)),

  /// 90 derniers jours (trimestre).
  ninetyDays('90 derniers jours', Duration(days: 90)),

  /// Toute l'historique disponible.
  all('Toute la période', null);

  const ExportPeriod(this.label, this.duration);
  final String label;
  final Duration? duration;
}

/// Format de page du PDF.
enum ExportFormat {
  /// A4 portrait (par défaut, recommandé pour lecture).
  a4Portrait('A4 portrait'),

  /// A4 paysage (plus large pour tableaux denses).
  a4Landscape('A4 paysage');

  const ExportFormat(this.label);
  final String label;

  /// Conversion vers le format de page du package pdf.
  PdfPageFormat get pageFormat =>
      this == a4Landscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4;
}

/// Destinataire du rapport (personnalisation de l'en-tête).
enum ExportRecipient {
  /// Rapport adressé aux parents (ton鼓励ant + explications).
  parent('Parent', 'À l\'attention des parents'),

  /// Rapport adressé à l'enseignant (ton pédagogique + détails).
  teacher('Enseignant', 'À l\'attention de l\'enseignant'),

  /// Rapport personnel (pour l'élève lui-même).
  self('Moi', 'Note personnelle');

  const ExportRecipient(this.shortLabel, this.headerLine);
  final String shortLabel;
  final String headerLine;
}

// ─── Modèles de configuration & données ──────────────────────────────

/// Sections du rapport que l'utilisateur peut inclure ou exclure.
class ExportContentOptions {
  /// Score global de maîtrise + prédiction BEPC/BAC.
  final bool includeGlobalScore;

  /// Barres horizontales de progression par matière.
  final bool includeSubjectProgress;

  /// Heatmap des chapitres les plus faibles (top 5 P(L) bas).
  final bool includeHeatmap;

  /// Grille des badges débloqués.
  final bool includeBadges;

  /// Cartes dues / maîtrisées / en apprentissage (SRS).
  final bool includeSrsStats;

  /// Recommandations pédagogiques automatiques.
  final bool includeRecommendations;

  const ExportContentOptions({
    this.includeGlobalScore = true,
    this.includeSubjectProgress = true,
    this.includeHeatmap = true,
    this.includeBadges = true,
    this.includeSrsStats = true,
    this.includeRecommendations = true,
  });

  /// True si au moins une section est sélectionnée.
  bool get hasAtLeastOneSection =>
      includeGlobalScore ||
      includeSubjectProgress ||
      includeHeatmap ||
      includeBadges ||
      includeSrsStats ||
      includeRecommendations;

  /// Copie avec valeurs modifiées.
  ExportContentOptions copyWith({
    bool? includeGlobalScore,
    bool? includeSubjectProgress,
    bool? includeHeatmap,
    bool? includeBadges,
    bool? includeSrsStats,
    bool? includeRecommendations,
  }) =>
      ExportContentOptions(
        includeGlobalScore: includeGlobalScore ?? this.includeGlobalScore,
        includeSubjectProgress:
            includeSubjectProgress ?? this.includeSubjectProgress,
        includeHeatmap: includeHeatmap ?? this.includeHeatmap,
        includeBadges: includeBadges ?? this.includeBadges,
        includeSrsStats: includeSrsStats ?? this.includeSrsStats,
        includeRecommendations:
            includeRecommendations ?? this.includeRecommendations,
      );
}

/// Configuration complète de l'export PDF.
class ExportOptions {
  final ExportPeriod period;
  final ExportFormat format;
  final ExportRecipient recipient;
  final ExportContentOptions content;

  const ExportOptions({
    this.period = ExportPeriod.thirtyDays,
    this.format = ExportFormat.a4Portrait,
    this.recipient = ExportRecipient.parent,
    this.content = const ExportContentOptions(),
  });

  ExportOptions copyWith({
    ExportPeriod? period,
    ExportFormat? format,
    ExportRecipient? recipient,
    ExportContentOptions? content,
  }) =>
      ExportOptions(
        period: period ?? this.period,
        format: format ?? this.format,
        recipient: recipient ?? this.recipient,
        content: content ?? this.content,
      );
}

/// Chapitre faible (pour la heatmap).
class WeakChapterInfo {
  final String competenceId;
  final double pL; // 0-1
  final String chapitre;
  final String matiere;

  const WeakChapterInfo({
    required this.competenceId,
    required this.pL,
    required this.chapitre,
    required this.matiere,
  });
}

/// Activité hebdomadaire (7 derniers jours, lundi → dimanche).
class WeeklyActivityInfo {
  /// Compte de questions répondues par jour [lun, mar, mer, jeu, ven, sam, dim].
  final List<int> counts;

  const WeeklyActivityInfo(this.counts) : assert(counts.length == 7);

  /// Total des questions sur la semaine.
  int get total => counts.fold(0, (a, b) => a + b);
}

/// Données agrégées prêtes à être rendues dans le PDF.
///
/// Cette structure découple le chargement (Hive + services) du rendu (pdf).
/// On peut ainsi tester le rendu avec des données mock sans Hive.
class ExportData {
  final AppUser user;
  final List<ReviewCard> filteredCards;
  final Map<String, double> masteryByMatiere;
  final List<WeakChapterInfo> weakChapters;
  final SrsStats srsStats;
  final List<Badge> unlockedBadges;
  final ScorePrediction? prediction;
  final WeeklyActivityInfo weeklyActivity;
  final int streak;

  const ExportData({
    required this.user,
    required this.filteredCards,
    required this.masteryByMatiere,
    required this.weakChapters,
    required this.srsStats,
    required this.unlockedBadges,
    required this.prediction,
    required this.weeklyActivity,
    required this.streak,
  });
}

// ─── Service principal ───────────────────────────────────────────────

/// Service de génération du rapport PDF.
///
/// Singleton : on évite d'instancier plusieurs fois car les services
/// sous-jacents (ScorePredictor, BadgeService) sont eux-mêmes singletons.
class PdfExportService {
  PdfExportService._();
  static final PdfExportService instance = PdfExportService._();

  // ─── Palette ExamBoost Togo (cohérente avec app_theme.dart) ───────
  // Convertie en PdfColor (espace RGB 0-1, pas 0-255).
  // Déclarées `const` (constructeur const de PdfColor) pour permettre
  // leur usage dans des const expressions (BoxDecoration, Border, etc.).
  static const PdfColor vertTogo = PdfColor(0.0, 0.40784, 0.21569);
  static const PdfColor vertFonce = PdfColor(0.0, 0.29020, 0.14902);
  static const PdfColor vertClair = PdfColor(0.90980, 0.96078, 0.93333);
  static const PdfColor orangeTogo = PdfColor(0.85098, 0.46667, 0.0);
  static const PdfColor orangeClair = PdfColor(1.0, 0.95294, 0.87843);
  static const PdfColor success = PdfColor(0.18039, 0.49020, 0.19608);
  static const PdfColor warning = PdfColor(0.96078, 0.48627, 0.0);
  static const PdfColor error = PdfColor(0.77647, 0.15686, 0.15686);
  static const PdfColor textPrimary = PdfColor(0.10196, 0.10196, 0.10196);
  static const PdfColor textSecondary = PdfColor(0.45882, 0.45882, 0.45882);
  static const PdfColor textDisabled = PdfColor(0.74118, 0.74118, 0.74118);
  static const PdfColor divider = PdfColor(0.87843, 0.87843, 0.87843);
  static const PdfColor surface = PdfColors.white;
  static const PdfColor background = PdfColor(0.97255, 0.97647, 0.98039);

  // ─── Chargement des données ───────────────────────────────────────

  /// Charge toutes les données nécessaires à la génération du PDF.
  ///
  /// Étapes :
  ///   1. Lecture userId depuis SharedPreferences (défaut : user_demo).
  ///   2. Lecture AppUser dans Hive box "users" (fallback démo).
  ///   3. Lecture ReviewCard[] filtrées par [options.period].
  ///   4. Calcul masteryByMatiere + weakChapters depuis bktMaitrise.
  ///   5. SrsStats via [SrsService.getStats] (déjà injecté par Provider).
  ///   6. Badges débloqués via [BadgeService].
  ///   7. ScorePrediction via [ScorePredictor] (cache < 1h).
  ///   8. Activité hebdomadaire + streak (depuis cards).
  ///
  /// [srsService] et [badgeService] sont passés en paramètres car ils sont
  /// fournis par Provider dans le widget tree (déjà initialisés au main()).
  Future<ExportData> loadData(
    ExportOptions options,
    SrsService srsService,
    BadgeService badgeService, {
    String? userIdOverride,
  }) async {
    // ─── 1. Identité élève ─────────────────────────────────────────
    final prefs = await SharedPreferences.getInstance();
    final userId = userIdOverride ??
        prefs.getString('current_user_id') ??
        'user_demo';

    // ─── 2. AppUser ────────────────────────────────────────────────
    final userBox = Hive.isBoxOpen('users')
        ? Hive.box<AppUser>('users')
        : await Hive.openBox<AppUser>('users');
    AppUser user = userBox.get(userId) ??
        AppUser(
          id: userId,
          nom: 'Élève',
          prenom: 'Élève',
          niveauScolaire: '3eme',
          dateInscription: DateTime.now(),
        );

    // ─── 3. ReviewCards filtrées par période ───────────────────────
    final cardBox = Hive.isBoxOpen('review_cards')
        ? Hive.box<ReviewCard>('review_cards')
        : await Hive.openBox<ReviewCard>('review_cards');
    final allCards =
        cardBox.values.where((c) => c.userId == userId).toList();
    final filteredCards = _filterByPeriod(allCards, options.period);

    // ─── 4. Mastery by matière + weak chapters ─────────────────────
    // Calculs identiques au dashboard_screen.dart pour rester cohérent.
    final masteryByMatiere = _computeMasteryByMatiere(user);
    final weakChapters =
        _computeWeakChapters(user, limit: 5);

    // ─── 5. SrsStats ───────────────────────────────────────────────
    final srsStats = srsService.getStats(userId);

    // ─── 6. Badges débloqués ───────────────────────────────────────
    List<Badge> unlockedBadges;
    try {
      unlockedBadges = badgeService.unlockedBadges;
    } catch (_) {
      // BadgeService peut ne pas être initialisé (cas démo) -> liste vide.
      unlockedBadges = const [];
    }

    // ─── 7. ScorePrediction (cache < 1h) ───────────────────────────
    ScorePrediction? prediction;
    try {
      prediction = await ScorePredictor.instance.getLastPrediction(userId);
    } catch (e) {
      debugPrint('PdfExportService: ScorePredictor indisponible — $e');
    }

    // ─── 8. Activité hebdomadaire + streak ─────────────────────────
    final weeklyActivity = _computeWeeklyActivity(filteredCards);
    final streak = _computeStreak(filteredCards);

    return ExportData(
      user: user,
      filteredCards: filteredCards,
      masteryByMatiere: masteryByMatiere,
      weakChapters: weakChapters,
      srsStats: srsStats,
      unlockedBadges: unlockedBadges,
      prediction: prediction,
      weeklyActivity: weeklyActivity,
      streak: streak,
    );
  }

  // ─── Génération du PDF ────────────────────────────────────────────

  /// Construit le document PDF et renvoie les octets bruts.
  ///
  /// [options] contrôle le format, le destinataire et les sections incluses.
  /// [data] doit être chargé au préalable via [loadData].
  Future<Uint8List> generatePdf(
    ExportOptions options,
    ExportData data,
  ) async {
    // Le thème par défaut du package pdf utilise Helvetica (standard PDF,
    // pas d'embedding requis). On ne personnalise que ce qui est nécessaire.
    final doc = pw.Document();

    // Construction des sections sélectionnées (chaque section renvoie
    // une liste de widgets pdf, éventuellement vide).
    final sections = <pw.Widget>[];

    // En-tête élève (toujours présent, juste après le header de page).
    sections.add(_buildStudentHeader(options, data));
    sections.add(pw.SizedBox(height: 16));

    if (options.content.includeGlobalScore) {
      sections.add(_buildGlobalScoreSection(data));
      sections.add(pw.SizedBox(height: 16));
    }
    if (options.content.includeSubjectProgress) {
      sections.add(_buildSubjectProgressSection(data));
      sections.add(pw.SizedBox(height: 16));
    }
    if (options.content.includeHeatmap) {
      sections.add(_buildHeatmapSection(data));
      sections.add(pw.SizedBox(height: 16));
    }
    if (options.content.includeBadges) {
      sections.add(_buildBadgesSection(data));
      sections.add(pw.SizedBox(height: 16));
    }
    if (options.content.includeSrsStats) {
      sections.add(_buildSrsStatsSection(data));
      sections.add(pw.SizedBox(height: 16));
    }
    if (options.content.includeRecommendations) {
      sections.add(_buildRecommendationsSection(options, data));
      sections.add(pw.SizedBox(height: 16));
    }

    // Cas dégénéré : aucune section sélectionnée.
    if (sections.length <= 2) {
      sections.add(pw.Container(
        padding: const pw.EdgeInsets.all(20),
        decoration: pw.BoxDecoration(
          color: orangeClair,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Text(
          'Aucune section sélectionnée pour ce rapport.',
          style: pw.TextStyle(color: orangeTogo),
        ),
      ));
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: options.format.pageFormat,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => _buildPageHeader(options, data, ctx),
        footer: (ctx) => _buildPageFooter(ctx),
        build: (ctx) => sections,
      ),
    );

    return doc.save();
  }

  // ─── Thème PDF (police + couleurs) ────────────────────────────────
  // Le package pdf utilise par défaut Helvetica (police standard PDF, sans
  // embedding de fichier). Chaque widget spécifie son propre pw.TextStyle
  // avec les couleurs ExamBoost Togo — aucun thème global n'est requis.

  // ─── En-tête de page (logo + titre + date) ────────────────────────

  pw.Widget _buildPageHeader(
    ExportOptions options,
    ExportData data,
    pw.Context ctx,
  ) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: vertTogo, width: 1.5),
        ),
      ),
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Logo "EB" stylisé (carré vert + texte blanc).
          pw.Container(
            width: 36,
            height: 36,
            decoration: pw.BoxDecoration(
              color: vertTogo,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            alignment: pw.Alignment.center,
            child: pw.Text(
              'EB',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'ExamBoost Togo',
                  style: pw.TextStyle(
                    color: vertTogo,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Rapport de progression',
                  style: pw.TextStyle(
                    color: textSecondary,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                _formatDate(DateTime.now()),
                style: pw.TextStyle(
                  color: textSecondary,
                  fontSize: 9,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                options.recipient.headerLine,
                style: pw.TextStyle(
                  color: orangeTogo,
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Pied de page ─────────────────────────────────────────────────

  pw.Widget _buildPageFooter(pw.Context ctx) {
    final pageCount = ctx.pageCount;
    final pageNumber = ctx.pageNumber;
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: divider, width: 0.5),
        ),
      ),
      padding: const pw.EdgeInsets.only(top: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Généré par ExamBoost Togo le ${_formatDate(DateTime.now())}',
            style: pw.TextStyle(color: textSecondary, fontSize: 8),
          ),
          pw.Text(
            'Page $pageNumber / $pageCount',
            style: pw.TextStyle(color: textSecondary, fontSize: 8),
          ),
        ],
      ),
    );
  }

  // ─── En-tête élève (nom, niveau, établissement) ───────────────────

  pw.Widget _buildStudentHeader(ExportOptions options, ExportData data) {
    final user = data.user;
    final niveauLabel = _niveauLabel(user.niveauScolaire, user.serie);
    final etablissement =
        user.etablissement?.isNotEmpty == true ? user.etablissement! : '—';
    final ville = user.ville?.isNotEmpty == true ? user.ville! : '—';
    final streak = data.streak;
    final totalQuestions = data.filteredCards
        .fold<int>(0, (sum, c) => sum + c.totalAttempts);

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: vertClair,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: vertTogo, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Avatar initiales.
              pw.Container(
                width: 44,
                height: 44,
                decoration: pw.BoxDecoration(
                  color: vertTogo,
                  borderRadius: pw.BorderRadius.circular(22),
                ),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  _initials(user),
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      user.nomComplet,
                      style: pw.TextStyle(
                        color: vertFonce,
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      '$niveauLabel  ·  Établissement : $etablissement  ·  $ville',
                      style: pw.TextStyle(
                        color: textSecondary,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Période',
                    style: pw.TextStyle(color: textSecondary, fontSize: 8),
                  ),
                  pw.Text(
                    options.period.label,
                    style: pw.TextStyle(
                      color: vertTogo,
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Divider(color: vertTogo, thickness: 0.3),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildMiniStat('Questions répondues', '$totalQuestions'),
              _buildMiniStat('Jours consécutifs', '$streak j'),
              _buildMiniStat(
                'Cartes SRS',
                '${data.srsStats.totalCards}',
              ),
              _buildMiniStat(
                'Badges',
                '${data.unlockedBadges.length}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildMiniStat(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            color: orangeTogo,
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          label,
          style: pw.TextStyle(color: textSecondary, fontSize: 8),
        ),
      ],
    );
  }

  // ─── Section 1 : Score global + prédiction BEPC ───────────────────

  pw.Widget _buildGlobalScoreSection(ExportData data) {
    final score = data.user.scoreGlobal; // 0-100
    final scoreColor = _scorePdfColor(score);
    final competencesCount = data.user.bktMaitrise.length;
    final mastered = data.user.competencesMaitrisees.length;

    // Prédiction : priorité au ScorePredictor (coefficients officiels),
    // fallback sur l'heuristique (moyenne P(L) × 20) du dashboard.
    final bepcScore = data.prediction?.scoreGlobal ??
        _predictedScoreHeuristic(data.user);
    final bepcConfidenceLabel = data.prediction?.confidenceLabel ?? 'Estimée';
    final isPassing = bepcScore >= 10.0;

    final List<pw.Widget> children = [];

    children.add(_buildSectionTitle('1. Score global de maîtrise'));
    children.add(pw.SizedBox(height: 8));

    // Barre de progression horizontale (0-100%).
    children.add(_buildHorizontalBar(
      percent: score / 100,
      color: scoreColor,
      label: '${score.round()} %',
    ));
    children.add(pw.SizedBox(height: 6));
    children.add(pw.Text(
      'Basé sur $competencesCount compétence(s) suivie(s) — $mastered maîtrisée(s) '
      '(P(L) ≥ 0,85).',
      style: pw.TextStyle(color: textSecondary, fontSize: 9),
    ));

    children.add(pw.SizedBox(height: 14));

    // Encadré prédiction BEPC.
    children.add(pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: orangeClair,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: orangeTogo, width: 0.5),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            width: 56,
            height: 56,
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              shape: pw.BoxShape.circle,
              border: pw.Border.all(color: orangeTogo, width: 2),
            ),
            alignment: pw.Alignment.center,
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  bepcScore.toStringAsFixed(1),
                  style: pw.TextStyle(
                    color: orangeTogo,
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  '/ 20',
                  style: pw.TextStyle(color: textSecondary, fontSize: 7),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Prédiction score ${data.prediction?.examen ?? "BEPC"}',
                  style: pw.TextStyle(
                    color: vertFonce,
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  'Confiance : $bepcConfidenceLabel'
                  '${data.prediction != null ? "  ·  Couverture ${((data.prediction!.coverageRate) * 100).round()} %" : ""}',
                  style: pw.TextStyle(color: textSecondary, fontSize: 9),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  isPassing
                      ? 'Élève estimé admis (≥ 10/20).'
                      : '${(10.0 - bepcScore).toStringAsFixed(1)} point(s) manquant(s) pour la moyenne.',
                  style: pw.TextStyle(
                    color: isPassing ? success : error,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: children,
    );
  }

  // ─── Section 2 : Progression par matière ──────────────────────────

  pw.Widget _buildSubjectProgressSection(ExportData data) {
    final entries = data.masteryByMatiere.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final List<pw.Widget> children = [];
    children.add(_buildSectionTitle('2. Progression par matière'));
    children.add(pw.SizedBox(height: 8));

    if (entries.isEmpty) {
      children.add(_buildEmptyBox(
        'Aucune donnée de progression par matière pour cette période. '
        'L\'élève doit commencer à réviser pour alimenter ces statistiques.',
      ));
    } else {
      for (final e in entries) {
        final percent = (e.value * 100).clamp(0, 100);
        final color = _scorePdfColor(percent);
        children.add(_buildMatiereBar(e.key, percent / 100, color, percent));
        children.add(pw.SizedBox(height: 8));
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: children,
    );
  }

  pw.Widget _buildMatiereBar(
    String matiere,
    double fraction,
    PdfColor color,
    double percent,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Text(
                matiere,
                style: pw.TextStyle(
                  color: textPrimary,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Text(
              '${percent.round()} %',
              style: pw.TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        _buildHorizontalBar(percent: fraction, color: color, label: ''),
      ],
    );
  }

  // ─── Section 3 : Heatmap des chapitres à travailler ───────────────

  pw.Widget _buildHeatmapSection(ExportData data) {
    final weak = data.weakChapters;

    final List<pw.Widget> children = [];
    children.add(_buildSectionTitle('3. Chapitres à travailler en priorité'));
    children.add(pw.SizedBox(height: 4));
    children.add(pw.Text(
      'Top ${weak.length} compétences avec le niveau de maîtrise P(L) le plus bas. '
      'Plus la barre est courte et rouge, plus le chapitre demande d\'effort.',
      style: pw.TextStyle(color: textSecondary, fontSize: 9),
    ));
    children.add(pw.SizedBox(height: 10));

    if (weak.isEmpty) {
      children.add(_buildEmptyBox(
        'Aucun chapitre faible identifié — l\'élève n\'a pas encore assez de '
        'données BKT pour calculer un classement.',
      ));
    } else {
      // Tableau structuré : Matière | Chapitre | P(L) | Barre
      final rows = <pw.TableRow>[];
      // En-tête.
      rows.add(pw.TableRow(
        decoration: const pw.BoxDecoration(color: vertClair),
        children: [
          _tableHeaderCell('Matière'),
          _tableHeaderCell('Chapitre'),
          _tableHeaderCell('P(L)'),
          _tableHeaderCell('Niveau'),
        ],
      ));
      for (final w in weak) {
        final percent = (w.pL * 100).clamp(0, 100);
        final color = _scorePdfColor(percent);
        rows.add(pw.TableRow(
          children: [
            _tableCell(w.matiere,
                style: pw.TextStyle(
                    color: textPrimary, fontWeight: pw.FontWeight.bold)),
            _tableCell(w.chapitre),
            _tableCell('${(w.pL * 100).round()} %',
                align: pw.Alignment.centerRight,
                style: pw.TextStyle(
                    color: color, fontWeight: pw.FontWeight.bold)),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 6, vertical: 6),
              child: _buildHorizontalBar(
                  percent: w.pL.clamp(0.0, 1.0), color: color, label: ''),
            ),
          ],
        ));
      }
      children.add(pw.Table(
        border: pw.TableBorder.all(color: divider, width: 0.5),
        defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
        columnWidths: const {
          0: pw.FlexColumnWidth(2),
          1: pw.FlexColumnWidth(3),
          2: pw.FlexColumnWidth(1),
          3: pw.FlexColumnWidth(3),
        },
        children: rows,
      ));
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: children,
    );
  }

  // ─── Section 4 : Badges débloqués ─────────────────────────────────

  pw.Widget _buildBadgesSection(ExportData data) {
    final badges = data.unlockedBadges;
    final totalXp =
        badges.fold<int>(0, (sum, b) => sum + b.xpReward);

    final List<pw.Widget> children = [];
    children.add(_buildSectionTitle('4. Badges débloqués'));
    children.add(pw.SizedBox(height: 4));
    children.add(pw.Text(
      '${badges.length} badge(s) débloqué(s) sur ${Badges.all.length} — '
      'XP cumulée : $totalXp points.',
      style: pw.TextStyle(color: textSecondary, fontSize: 9),
    ));
    children.add(pw.SizedBox(height: 10));

    if (badges.isEmpty) {
      children.add(_buildEmptyBox(
        'Aucun badge débloqué pour l\'instant. Les badges récompensent la '
        'régularité, la curiosité et la maîtrise — encouragez l\'élève à '
        'réviser quotidiennement.',
      ));
    } else {
      // Grille 3 colonnes, chaque cellule = carte badge (carré couleur + titre + niveau).
      final cells = badges
          .map((b) => _buildBadgeCell(b))
          .toList();
      // Découpage en lignes de 3.
      final rows = <pw.TableRow>[];
      for (int i = 0; i < cells.length; i += 3) {
        final slice = cells.sublist(
            i, i + 3 > cells.length ? cells.length : i + 3);
        // Compléter la dernière ligne avec des cellules vides.
        while (slice.length < 3) {
          slice.add(pw.SizedBox());
        }
        rows.add(pw.TableRow(children: slice));
      }
      children.add(pw.Table(
        defaultVerticalAlignment: pw.TableCellVerticalAlignment.top,
        columnWidths: const {
          0: pw.FlexColumnWidth(1),
          1: pw.FlexColumnWidth(1),
          2: pw.FlexColumnWidth(1),
        },
        children: rows,
      ));
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: children,
    );
  }

  pw.Widget _buildBadgeCell(Badge badge) {
    return pw.Container(
      margin: const pw.EdgeInsets.all(4),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: vertClair,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: vertTogo, width: 0.4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 22,
                height: 22,
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(badge.color.value),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
              ),
              pw.SizedBox(width: 6),
              pw.Expanded(
                child: pw.Text(
                  badge.title,
                  style: pw.TextStyle(
                    color: vertFonce,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Niveau ${badge.level.label}',
            style: pw.TextStyle(
              color: PdfColor.fromInt(badge.level.color.value),
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'Catégorie : ${badge.category.label}',
            style: pw.TextStyle(color: textSecondary, fontSize: 8),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            '+${badge.xpReward} XP',
            style: pw.TextStyle(
              color: orangeTogo,
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section 5 : Statistiques SRS ─────────────────────────────────

  pw.Widget _buildSrsStatsSection(ExportData data) {
    final srs = data.srsStats;
    // Calcul du taux de réussite sur les cartes filtrées par période
    // (cohérent avec l'affichage des autres sections).
    final totalAttempts =
        data.filteredCards.fold<int>(0, (sum, c) => sum + c.totalAttempts);
    final totalCorrect =
        data.filteredCards.fold<int>(0, (sum, c) => sum + c.correctAttempts);
    final successRate =
        totalAttempts == 0 ? 0.0 : totalCorrect / totalAttempts;

    final List<pw.Widget> children = [];
    children.add(_buildSectionTitle('5. Statistiques de révision (SRS)'));
    children.add(pw.SizedBox(height: 4));
    children.add(pw.Text(
      'Algorithme SM-2 — répétition espacée pour ancrer les connaissances '
      'dans la durée.',
      style: pw.TextStyle(color: textSecondary, fontSize: 9),
    ));
    children.add(pw.SizedBox(height: 10));

    // 4 cartes côte à côte.
    children.add(pw.Row(
      children: [
        pw.Expanded(
            child: _buildStatCard(
                'À réviser aujourd\'hui', '${srs.dueToday}',
                color: srs.dueToday > 0 ? error : textSecondary)),
        pw.Expanded(
            child: _buildStatCard('Maîtrisées', '${srs.mastered}',
                color: success)),
        pw.Expanded(
            child: _buildStatCard('En apprentissage', '${srs.learning}',
                color: orangeTogo)),
        pw.Expanded(
            child: _buildStatCard('Nouvelles', '${srs.newCards}',
                color: vertTogo)),
      ],
    ));

    children.add(pw.SizedBox(height: 10));

    // Ligne d'infos complémentaires.
    children.add(pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: background,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: divider, width: 0.4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildInfoLine('Cartes totales', '${srs.totalCards}'),
          _buildInfoLine('À venir dans 7 jours', '${srs.dueIn7Days}'),
          _buildInfoLine(
              'Taux de réussite',
              totalAttempts == 0
                  ? '—'
                  : '${(successRate * 100).toStringAsFixed(1)} %'),
        ],
      ),
    ));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: children,
    );
  }

  pw.Widget _buildStatCard(String label, String value, {required PdfColor color}) {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(horizontal: 3),
      padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: pw.BoxDecoration(
        color: background,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: divider, width: 0.4),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            label,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(color: textSecondary, fontSize: 8),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInfoLine(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(color: textSecondary, fontSize: 9)),
          pw.Text(value,
              style: pw.TextStyle(
                  color: textPrimary,
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  // ─── Section 6 : Recommandations automatiques ─────────────────────

  pw.Widget _buildRecommendationsSection(
      ExportOptions options, ExportData data) {
    final recos = _buildRecommendations(options, data);

    final List<pw.Widget> children = [];
    children.add(_buildSectionTitle('6. Recommandations pédagogiques'));
    children.add(pw.SizedBox(height: 4));
    children.add(pw.Text(
      'Suggestions automatiques calculées à partir des données de progression '
      'de l\'élève sur la période sélectionnée.',
      style: pw.TextStyle(color: textSecondary, fontSize: 9),
    ));
    children.add(pw.SizedBox(height: 10));

    if (recos.isEmpty) {
      children.add(_buildEmptyBox(
        'Aucune recommandation prioritaire — l\'élève progresse bien. '
        'Encouragez-le à maintenir la régularité.',
      ));
    } else {
      for (int i = 0; i < recos.length; i++) {
        final r = recos[i];
        children.add(_buildRecoItem(i + 1, r));
        children.add(pw.SizedBox(height: 8));
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: children,
    );
  }

  pw.Widget _buildRecoItem(int index, _Recommendation reco) {
    final color = _priorityColor(reco.priority);
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: background,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border(
          left: pw.BorderSide(color: color, width: 3),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 20,
            height: 20,
            decoration: pw.BoxDecoration(
              color: color,
              shape: pw.BoxShape.circle,
            ),
            alignment: pw.Alignment.center,
            child: pw.Text(
              '$index',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        reco.title,
                        style: pw.TextStyle(
                          color: vertFonce,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Text(
                      reco.priority.label,
                      style: pw.TextStyle(
                          color: color,
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  reco.detail,
                  style: pw.TextStyle(color: textPrimary, fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Moteur de recommandations automatiques basé sur les données de l'élève.
  ///
  /// Règles (priorité décroissante) :
  ///   1. P(L) très bas sur un chapitre -> priorité haute.
  ///   2. Cartes SRS en retard (dueToday > 0) -> priorité haute.
  ///   3. Streak cassé (streak == 0 alors qu'il y a des cartes) -> moyenne.
  ///   4. Couverture du programme faible -> moyenne.
  ///   5. Score global faible (< 50) -> moyenne.
  ///   6. Aucun badge débloqué -> basse.
  ///   7. Bonne progression (score >= 75) -> positive (encouragement).
  List<_Recommendation> _buildRecommendations(
      ExportOptions options, ExportData data) {
    final recos = <_Recommendation>[];
    final user = data.user;
    final score = user.scoreGlobal;

    // 1. Chapitres faibles.
    if (data.weakChapters.isNotEmpty) {
      final weakest = data.weakChapters.first;
      if (weakest.pL < 0.4) {
        recos.add(_Recommendation(
          title: 'Travailler en priorité : ${weakest.chapitre} (${weakest.matiere})',
          detail: 'Niveau de maîtrise estimé à ${(weakest.pL * 100).round()} %. '
              'Planifier 3 sessions courtes de 15 min cette semaine sur ce chapitre '
              'pour remonter P(L) au-dessus de 0,6.',
          priority: _RecoPriority.haute,
        ));
      } else if (weakest.pL < 0.6) {
        recos.add(_Recommendation(
          title: 'Consolider : ${weakest.chapitre} (${weakest.matiere})',
          detail: 'Niveau intermédiaire (${(weakest.pL * 100).round()} %). '
              'Continuer les révisions espacées pour ancrer la compétence.',
          priority: _RecoPriority.moyenne,
        ));
      }
    }

    // 2. Cartes SRS dues.
    if (data.srsStats.dueToday > 0) {
      recos.add(_Recommendation(
        title: '${data.srsStats.dueToday} carte(s) à réviser aujourd\'hui',
        detail: 'La répétition espacée est plus efficace quand les révisions '
            'sont faites à temps. Une session de 10 min permet de vider la file.',
        priority: _RecoPriority.haute,
      ));
    }

    // 3. Streak cassé.
    if (data.streak == 0 && data.srsStats.totalCards > 0) {
      recos.add(_Recommendation(
        title: 'Reprendre la série quotidienne',
        detail: 'Aucune révision récente détectée. Réviser aujourd\'hui, '
            'même 5 min, relance le streak et l\'ancrage mémoriel.',
        priority: _RecoPriority.moyenne,
      ));
    }

    // 4. Couverture du programme.
    final coverage = data.prediction?.coverageRate;
    if (coverage != null && coverage < 0.5) {
      recos.add(_Recommendation(
        title: 'Élargir la couverture du programme',
        detail: 'Seulement ${(coverage * 100).round()} % du programme couvert '
            'par des compétences mesurées. Explorer de nouvelles matières '
            'pour fiabiliser la prédiction du score officiel.',
        priority: _RecoPriority.moyenne,
      ));
    }

    // 5. Score global faible.
    if (score < 50 && user.bktMaitrise.isNotEmpty) {
      recos.add(_Recommendation(
        title: 'Visez des sessions courtes et régulières',
        detail: 'Score global de ${score.round()} %. Privilégier 3 à 4 sessions '
            'de 15 min par jour plutôt qu\'une longue session hebdomadaire. '
            'L\'algorithme SM-2 optimise l\'ancrage mémoriel sur la durée.',
        priority: _RecoPriority.moyenne,
      ));
    }

    // 6. Aucun badge.
    if (data.unlockedBadges.isEmpty && data.srsStats.totalCards > 0) {
      recos.add(_Recommendation(
        title: 'Débloquer les premiers badges',
        detail: 'Aucun badge débloqué. Atteindre 7 jours consécutifs de '
            'révision débloque le badge « Régularité » (Bronze).',
        priority: _RecoPriority.basse,
      ));
    }

    // 7. Encouragement si bonne progression.
    if (score >= 75 && recos.length < 3) {
      recos.add(_Recommendation(
        title: 'Progression solide — viser l\'excellence',
        detail: 'Score global de ${score.round()} %. L\'élève peut maintenant '
            'se concentrer sur les simulations d\'examen pour tester ses '
            'réflexes en conditions réelles (timing, stress).',
        priority: _RecoPriority.basse,
      ));
    }

    // Trier par priorité décroissante (haute -> basse).
    // L'enum _RecoPriority est déclaré haute(0) -> basse(2), donc on trie
    // par index croissant pour avoir la priorité haute en premier.
    recos.sort((a, b) => a.priority.index.compareTo(b.priority.index));
    return recos;
  }

  PdfColor _priorityColor(_RecoPriority p) {
    switch (p) {
      case _RecoPriority.haute:
        return error;
      case _RecoPriority.moyenne:
        return orangeTogo;
      case _RecoPriority.basse:
        return vertTogo;
    }
  }

  // ─── Helpers de rendu PDF réutilisables ────────────────────────────

  pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: vertTogo,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  /// Barre de progression horizontale (style LinearPercentIndicator).
  ///
  /// On utilise deux [pw.Expanded] dont les flex sont proportionnels au
  /// pourcentage rempli/vide. Les flex sont clampés à min 1 pour garantir
  /// que le [pw.Row] ait toujours au moins un enfant flexible valide
  /// (le package pdf nécessite flex > 0 sur les Expanded).
  pw.Widget _buildHorizontalBar({
    required double percent,
    required PdfColor color,
    required String label,
  }) {
    final clamped = percent.clamp(0.0, 1.0);
    final filledFlex = (clamped * 1000).round().clamp(1, 1000);
    final emptyFlex = ((1 - clamped) * 1000).round().clamp(1, 1000);
    return pw.ClipRRect(
      horizontalRadius: 4,
      verticalRadius: 4,
      child: pw.Container(
        height: 8,
        decoration: pw.BoxDecoration(
          color: color.withOpacity(0.15),
        ),
        child: pw.Row(
          children: [
            pw.Expanded(
              flex: filledFlex,
              child: pw.Container(
                decoration: pw.BoxDecoration(color: color),
              ),
            ),
            pw.Expanded(
              flex: emptyFlex,
              child: pw.SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildEmptyBox(String message) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: background,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: divider, width: 0.4),
      ),
      child: pw.Text(
        message,
        style: pw.TextStyle(
            color: textSecondary,
            fontSize: 9,
            fontStyle: pw.FontStyle.italic),
      ),
    );
  }

  pw.Widget _tableHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: vertFonce,
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _tableCell(
    String text, {
    pw.Alignment align = pw.Alignment.centerLeft,
    pw.TextStyle? style,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Align(
        alignment: align,
        child: pw.Text(
          text,
          style: style ??
              pw.TextStyle(color: textPrimary, fontSize: 9),
          maxLines: 2,
        ),
      ),
    );
  }

  // ─── Partage & sauvegarde ─────────────────────────────────────────

  /// Sauvegarde le PDF dans le répertoire documents de l'app.
  ///
  /// Retourne le [File] créé. Le nom inclut la date + nom élève pour
  /// faciliter le classement côté parent/enseignant.
  Future<File> saveToFile(Uint8List bytes, ExportData data) async {
    final dir = await getApplicationDocumentsDirectory();
    final safeName = data.user.nomComplet
        .replaceAll(RegExp(r'[^A-Za-zÀ-ÿ0-9 ]'), '')
        .replaceAll(' ', '_');
    final dateStamp =
        DateTime.now().toIso8601String().substring(0, 10);
    final path =
        '${dir.path}/Rapport_ExamBoost_${safeName}_$dateStamp.pdf';
    final file = File(path);
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Partage générique via la feu système Android/iOS.
  ///
  /// L'utilisateur choisit l'application cible (WhatsApp, Gmail, Drive, etc.).
  Future<void> shareGeneric(
    Uint8List bytes,
    ExportData data,
    ExportOptions options,
  ) async {
    final file = await _writeTempFile(bytes, data);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: _emailSubject(data, options),
      text: _emailBody(data, options),
    );
  }

  /// Partage orienté email : ouvre la feu de partage avec un sujet/body
  /// pré-remplis. L'utilisateur choisit son app mail (Gmail, Outlook, etc.).
  ///
  /// Note : share_plus ne permet pas de forcer une app spécifique de façon
  /// fiable cross-platform. On pré-remplit juste le sujet et le corps, ce qui
  /// oriente naturellement vers les apps mail.
  Future<void> shareViaEmail(
    Uint8List bytes,
    ExportData data,
    ExportOptions options,
  ) async {
    final file = await _writeTempFile(bytes, data);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: _emailSubject(data, options),
      text: _emailBody(data, options),
    );
  }

  /// Partage orienté WhatsApp : ouvre la feu de partage système.
  ///
  /// WhatsApp Desktop/Mobile ne supporte pas les fichiers PDF via URL
  /// wa.me — on passe donc par la feu système qui laisse l'utilisateur
  /// sélectionner WhatsApp explicitement.
  Future<void> shareViaWhatsApp(
    Uint8List bytes,
    ExportData data,
    ExportOptions options,
  ) async {
    final file = await _writeTempFile(bytes, data);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: _emailSubject(data, options),
      text: _emailBody(data, options),
    );
  }

  /// Écrit le PDF dans le répertoire temporaire (cache système).
  ///
  /// Utilisé par les méthodes de partage : share_plus a besoin d'un chemin
  /// fichier réel, pas d'octets en mémoire.
  Future<File> _writeTempFile(Uint8List bytes, ExportData data) async {
    final dir = await getTemporaryDirectory();
    final safeName = data.user.nomComplet
        .replaceAll(RegExp(r'[^A-Za-zÀ-ÿ0-9 ]'), '')
        .replaceAll(' ', '_');
    final dateStamp =
        DateTime.now().toIso8601String().substring(0, 10);
    final path = '${dir.path}/Rapport_ExamBoost_${safeName}_$dateStamp.pdf';
    final file = File(path);
    await file.writeAsBytes(bytes);
    return file;
  }

  String _emailSubject(ExportData data, ExportOptions options) {
    final nom = data.user.nomComplet;
    final periode = options.period.label;
    return 'Rapport de progression ExamBoost Togo — $nom ($periode)';
  }

  String _emailBody(ExportData data, ExportOptions options) {
    final nom = data.user.nomComplet;
    final score = data.user.scoreGlobal.round();
    final bepc = (data.prediction?.scoreGlobal ??
            _predictedScoreHeuristic(data.user))
        .toStringAsFixed(1);
    final badges = data.unlockedBadges.length;
    final destinataire = options.recipient.shortLabel;
    final date = _formatDate(DateTime.now());

    return 'Bonjour,\n\n'
        'Veuillez trouver ci-joint le rapport de progression de $nom '
        '(destinataire : $destinataire), généré par ExamBoost Togo le $date.\n\n'
        'Résumé :\n'
        '- Score global de maîtrise : $score %\n'
        '- Score prédit à l\'examen : $bepc / 20\n'
        '- Badges débloqués : $badges\n'
        '- Période couverte : ${options.period.label}\n\n'
        'Cordialement,\n'
        'L\'application ExamBoost Togo';
  }

  // ─── Helpers de calcul (cohérents avec dashboard_screen.dart) ──────

  List<ReviewCard> _filterByPeriod(
      List<ReviewCard> cards, ExportPeriod period) {
    if (period.duration == null) return cards; // tout
    final cutoff = DateTime.now().subtract(period.duration!);
    return cards.where((c) {
      // On garde la carte si sa dernière révision est dans la période
      // OU si elle est encore active (nextReviewDate future).
      final last = c.lastReviewDate;
      if (last != null && last.isAfter(cutoff)) return true;
      // Cartes jamais révisées mais dues dans la période.
      if (c.totalAttempts == 0 && c.nextReviewDate.isAfter(cutoff)) {
        return true;
      }
      return false;
    }).toList();
  }

  /// Moyenne de P(L) par matière (regroupement via competenceId).
  /// Format clé attendu : "TG-MATHS-EQ1D-001" -> matière = "MATHS".
  ///
  /// Note : on n'a pas accès au QuestionService ici (pour éviter la dépendance
  /// circulaire), on extrait donc la matière directement depuis la clé BKT.
  /// C'est cohérent avec BadgeService._countDistinctMatieres.
  Map<String, double> _computeMasteryByMatiere(AppUser user) {
    final byMatiere = <String, List<double>>{};
    for (final entry in user.bktMaitrise.entries) {
      final matiere = _extractMatiereFromKey(entry.key);
      if (matiere == null) continue;
      byMatiere.putIfAbsent(matiere, () => []).add(entry.value);
    }
    final result = <String, double>{};
    byMatiere.forEach((m, vals) {
      result[m] =
          vals.reduce((a, b) => a + b) / vals.length;
    });
    return result;
  }

  /// Extrait le code matière d'une clé competenceId "TG-MATHS-EQ1D-001".
  String? _extractMatiereFromKey(String key) {
    final parts = key.split('-');
    if (parts.length < 2) return null;
    return parts[1];
  }

  /// Top N compétences avec P(L) le plus bas, avec matière + chapitre.
  /// Format clé attendu : "TG-MATHS-EQ1D-001" -> chapitre = "MATHS-EQ1D".
  List<WeakChapterInfo> _computeWeakChapters(
    AppUser user, {
    int limit = 5,
  }) {
    final entries = user.bktMaitrise.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final result = <WeakChapterInfo>[];
    for (final e in entries.take(limit)) {
      final parts = e.key.split('-');
      if (parts.length < 3) continue;
      final matiere = parts[1];
      final chapitre = '${parts[1]}-${parts[2]}';
      result.add(WeakChapterInfo(
        competenceId: e.key,
        pL: e.value,
        chapitre: chapitre,
        matiere: matiere,
      ));
    }
    return result;
  }

  /// Activité hebdomadaire (lundi → dimanche de la semaine courante).
  WeeklyActivityInfo _computeWeeklyActivity(List<ReviewCard> cards) {
    final today = _dateOnly(DateTime.now());
    // weekday : 1 = lundi, 7 = dimanche.
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final counts = List<int>.filled(7, 0);
    for (final c in cards) {
      if (c.lastReviewDate == null) continue;
      final d = _dateOnly(c.lastReviewDate!);
      final diff = d.difference(monday).inDays;
      if (diff >= 0 && diff < 7) counts[diff]++;
    }
    return WeeklyActivityInfo(counts);
  }

  /// Streak : nombre de jours consécutifs de révision.
  int _computeStreak(List<ReviewCard> cards) {
    final days = cards
        .where((c) => c.lastReviewDate != null)
        .map((c) => _dateOnly(c.lastReviewDate!))
        .toSet();
    if (days.isEmpty) return 0;
    var cursor = _dateOnly(DateTime.now());
    if (!days.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    int streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Heuristique de prédiction du score (fallback si ScorePredicteur vide).
  double _predictedScoreHeuristic(AppUser user) {
    if (user.bktMaitrise.isEmpty) return 0;
    final avg = user.bktMaitrise.values.reduce((a, b) => a + b) /
        user.bktMaitrise.length;
    return avg * 20;
  }

  /// Couleur sémantique selon le score (0-100).
  PdfColor _scorePdfColor(double score) {
    if (score < 40) return error;
    if (score <= 70) return warning;
    return success;
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  String _initials(AppUser user) {
    final init1 =
        user.prenom.isNotEmpty ? user.prenom[0].toUpperCase() : 'E';
    final init2 = user.nom.isNotEmpty ? user.nom[0].toUpperCase() : '';
    return init2.isEmpty ? init1 : '$init1$init2';
  }

  String _niveauLabel(String niveau, String? serie) {
    final map = <String, String>{
      '3eme': '3e (BEPC)',
      '2nde': '2nde',
      '1ere': '1ère',
      'Terminale': 'Terminale',
      'Tle': 'Terminale',
    };
    final base = map[niveau] ?? niveau;
    if (serie != null && serie.isNotEmpty) {
      return '$base série $serie (BAC)';
    }
    return base;
  }

  /// Date formatée en français (sans dépendance intl).
  String _formatDate(DateTime d) {
    const days = [
      'lundi', 'mardi', 'mercredi', 'jeudi',
      'vendredi', 'samedi', 'dimanche',
    ];
    const months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
    ];
    return '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

// ─── Modèles internes ────────────────────────────────────────────────

/// Recommandation pédagogique générée automatiquement.
class _Recommendation {
  final String title;
  final String detail;
  final _RecoPriority priority;

  const _Recommendation({
    required this.title,
    required this.detail,
    required this.priority,
  });
}

/// Niveau de priorité d'une recommandation (pour le code couleur).
enum _RecoPriority {
  haute('Haute'),
  moyenne('Moyenne'),
  basse('Basse');

  const _RecoPriority(this.label);
  final String label;
}
