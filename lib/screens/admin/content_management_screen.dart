// lib/screens/admin/content_management_screen.dart
// Ecran d'administration du contenu (gestion des questions).
//
// Variante "web du module admin Agent S" : interface destinee a l'equipe
// pedagogique pour gerer la banque de questions ExamBoost Togo depuis
// l'app Flutter (mobile ou web).
//
// Fonctionnalites :
//   - Stats contenu en haut (total, par matiere, calibration IRT)
//   - Liste paginee des questions avec recherche + filtres
//     (matiere, examen, serie, annee)
//   - Bouton "Ajouter une question" (formulaire complet)
//   - Bouton "Modifier" sur chaque question
//   - Bouton "Supprimer" avec confirmation
//   - Bouton "Import JSON" (coller un JSON dans un dialog)
//   - Bouton "Export JSON" (recupere le contenu via l'API)
//   - Logs des actions recentes (20 dernieres)
//
// Branchement :
//   - URL backend configurable via le widget `apiBaseUrl` (defaut
//     `http://10.0.2.2:8000` pour l'emulateur Android).
//   - Token JWT admin requis, passe via le widget `adminToken`.
//   - A connecter dans `lib/utils/app_router.dart` sur la route
//     `/admin/content` (voir README du dossier admin).
//
// Dependances : dio (deja dans pubspec.yaml), flutter Material 3.

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';

// ─── Constantes ─────────────────────────────────────────────────────

/// URL par defaut de l'API backend. `10.0.2.2` correspond a localhost
/// depuis un emulateur Android. Pour le web, utiliser `http://localhost:8000`.
const String _kDefaultApiBaseUrl = 'http://10.0.2.2:8000';

/// Nombre de questions par page.
const int _kPageSize = 20;

/// Nombre de logs affiches dans la section "Actions recentes".
const int _kLogsLimit = 20;

/// Listes de valeurs autorisees (miroir de admin_service.py).
const List<String> _kExamens = ['BEPC', 'BAC1', 'BAC2', 'Probatoire'];
const List<String> _kSeries = ['A', 'B', 'C', 'D', 'F'];
const List<String> _kTypes = ['calcul', 'ouvert', 'qcm', 'vraiFaux', 'redaction'];

// ─── Modeles de donnees ─────────────────────────────────────────────

/// Question admin (miroir de backend/models/admin_schemas.py QuestionOut).
class AdminQuestion {
  final String id;
  final String enonce;
  final String reponse;
  final String? explication;
  final String matiere;
  final String chapitre;
  final String competenceId;
  final String examen;
  final String? serie;
  final int? annee;
  final String type;
  final List<String>? choix;
  final int? points;
  final double? irtA;
  final double? irtB;
  final double? irtC;
  final bool irtCalibrated;

  const AdminQuestion({
    required this.id,
    required this.enonce,
    required this.reponse,
    this.explication,
    required this.matiere,
    required this.chapitre,
    required this.competenceId,
    required this.examen,
    this.serie,
    this.annee,
    required this.type,
    this.choix,
    this.points,
    this.irtA,
    this.irtB,
    this.irtC,
    this.irtCalibrated = false,
  });

  factory AdminQuestion.fromJson(Map<String, dynamic> json) {
    return AdminQuestion(
      id: json['id'] as String? ?? '',
      enonce: json['enonce'] as String? ?? '',
      reponse: json['reponse'] as String? ?? '',
      explication: json['explication'] as String?,
      matiere: json['matiere'] as String? ?? '',
      chapitre: json['chapitre'] as String? ?? '',
      competenceId: json['competence_id'] as String? ?? '',
      examen: json['examen'] as String? ?? 'BEPC',
      serie: json['serie'] as String?,
      annee: json['annee'] is int ? json['annee'] as int : int.tryParse('${json['annee']}'),
      type: json['type'] as String? ?? 'ouvert',
      choix: (json['choix'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      points: json['points'] is int ? json['points'] as int : int.tryParse('${json['points']}'),
      irtA: (json['irt_a'] as num?)?.toDouble(),
      irtB: (json['irt_b'] as num?)?.toDouble(),
      irtC: (json['irt_c'] as num?)?.toDouble(),
      irtCalibrated: json['irt_calibrated'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'enonce': enonce,
        'reponse': reponse,
        'explication': explication,
        'matiere': matiere,
        'chapitre': chapitre,
        'competence_id': competenceId,
        'examen': examen,
        'serie': serie,
        'annee': annee,
        'type': type,
        'choix': choix,
        'points': points,
        'irt_a': irtA,
        'irt_b': irtB,
        'irt_c': irtC,
      };
}

/// Stats contenu (miroir de backend/models/admin_schemas.py AdminStats).
class AdminStatsData {
  final int totalQuestions;
  final Map<String, int> byMatiere;
  final Map<String, int> byExamen;
  final int irtCalibratedCount;
  final double irtCalibratedPercent;
  final int questionsWithoutExplanation;
  final int duplicateWarningsCount;

  const AdminStatsData({
    this.totalQuestions = 0,
    this.byMatiere = const {},
    this.byExamen = const {},
    this.irtCalibratedCount = 0,
    this.irtCalibratedPercent = 0.0,
    this.questionsWithoutExplanation = 0,
    this.duplicateWarningsCount = 0,
  });

  factory AdminStatsData.fromJson(Map<String, dynamic> json) {
    final byMat = <String, int>{};
    (json['by_matiere'] as Map<String, dynamic>?).forEach((k, v) {
      byMat[k] = v is int ? v : int.tryParse('$v') ?? 0;
    });
    final byEx = <String, int>{};
    (json['by_examen'] as Map<String, dynamic>?).forEach((k, v) {
      byEx[k] = v is int ? v : int.tryParse('$v') ?? 0;
    });
    return AdminStatsData(
      totalQuestions: json['total_questions'] as int? ?? 0,
      byMatiere: byMat,
      byExamen: byEx,
      irtCalibratedCount: json['irt_calibrated_count'] as int? ?? 0,
      irtCalibratedPercent:
          (json['irt_calibrated_percent'] as num?)?.toDouble() ?? 0.0,
      questionsWithoutExplanation:
          json['questions_without_explanation'] as int? ?? 0,
      duplicateWarningsCount:
          (json['duplicate_warnings'] as List<dynamic>?)?.length ?? 0,
    );
  }
}

/// Log d'action admin (miroir de backend/models/admin_schemas.py AdminActionLog).
class AdminActionLogEntry {
  final String id;
  final String adminId;
  final String action;
  final String? questionId;
  final DateTime timestamp;
  final Map<String, dynamic>? details;

  const AdminActionLogEntry({
    required this.id,
    required this.adminId,
    required this.action,
    this.questionId,
    required this.timestamp,
    this.details,
  });

  factory AdminActionLogEntry.fromJson(Map<String, dynamic> json) {
    return AdminActionLogEntry(
      id: json['id'] as String? ?? '',
      adminId: json['admin_id'] as String? ?? '',
      action: json['action'] as String? ?? '',
      questionId: json['question_id'] as String?,
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      details: json['details'] as Map<String, dynamic>?,
    );
  }
}

// ─── Service API ────────────────────────────────────────────────────

/// Client HTTP pour les endpoints /admin/*.
///
/// Encapsule Dio avec le header Authorization. Toutes les methodes
/// retournent le JSON decode ou lèvent une exception en cas d'erreur
/// (status code != 200 ou 201).
class AdminApiClient {
  final Dio _dio;
  final String baseUrl;

  AdminApiClient({
    required this.baseUrl,
    required String token,
  }) : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          responseType: ResponseType.json,
        ));

  // GET /admin/stats
  Future<AdminStatsData> fetchStats() async {
    final resp = await _dio.get('/admin/stats');
    return AdminStatsData.fromJson(resp.data as Map<String, dynamic>);
  }

  // GET /admin/questions?...
  Future<({List<AdminQuestion> items, int total})> listQuestions({
    String? matiere,
    String? examen,
    String? serie,
    int? annee,
    String? recherche,
    int limit = _kPageSize,
    int offset = 0,
  }) async {
    final resp = await _dio.get('/admin/questions', queryParameters: {
      if (matiere != null && matiere.isNotEmpty) 'matiere': matiere,
      if (examen != null && examen.isNotEmpty) 'examen': examen,
      if (serie != null && serie.isNotEmpty) 'serie': serie,
      if (annee != null) 'annee': annee,
      if (recherche != null && recherche.isNotEmpty) 'recherche': recherche,
      'limit': limit,
      'offset': offset,
    });
    final data = resp.data as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>)
        .map((e) => AdminQuestion.fromJson(e as Map<String, dynamic>))
        .toList();
    return (items: items, total: data['total'] as int? ?? 0);
  }

  // POST /admin/questions
  Future<AdminQuestion> createQuestion(AdminQuestion q) async {
    final resp = await _dio.post(
      '/admin/questions',
      data: q.toJson(),
    );
    return AdminQuestion.fromJson(resp.data as Map<String, dynamic>);
  }

  // PUT /admin/questions/{id}
  Future<AdminQuestion> updateQuestion(
      String id, Map<String, dynamic> patch) async {
    final resp = await _dio.put('/admin/questions/$id', data: patch);
    return AdminQuestion.fromJson(resp.data as Map<String, dynamic>);
  }

  // DELETE /admin/questions/{id}
  Future<void> deleteQuestion(String id) async {
    await _dio.delete('/admin/questions/$id');
  }

  // POST /admin/questions/batch-import
  Future<Map<String, dynamic>> batchImport(
      List<Map<String, dynamic>> questions,
      {bool overwrite = false}) async {
    final resp = await _dio.post('/admin/questions/batch-import', data: {
      'questions': questions,
      'overwrite_existing': overwrite,
    });
    return resp.data as Map<String, dynamic>;
  }

  // POST /admin/questions/batch-export
  Future<({String content, String format, int count})> batchExport({
    String format = 'json',
    Map<String, dynamic>? filters,
  }) async {
    final resp = await _dio.post('/admin/questions/batch-export', data: {
      'format': format,
      'filters': filters,
    });
    final data = resp.data as Map<String, dynamic>;
    return (
      content: data['content'] as String? ?? '',
      format: data['format'] as String? ?? format,
      count: data['count'] as int? ?? 0,
    );
  }

  // GET /admin/logs
  Future<List<AdminActionLogEntry>> fetchLogs({int limit = _kLogsLimit}) async {
    final resp = await _dio.get('/admin/logs', queryParameters: {'limit': limit});
    final list = resp.data as List<dynamic>;
    return list
        .map((e) => AdminActionLogEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

// ─── Widget principal ───────────────────────────────────────────────

/// Ecran de gestion du contenu (questions).
///
/// Doit etre instancie avec un `adminToken` JWT valide (compte `is_admin`).
class ContentManagementScreen extends StatefulWidget {
  final String adminToken;
  final String apiBaseUrl;

  const ContentManagementScreen({
    super.key,
    required this.adminToken,
    this.apiBaseUrl = _kDefaultApiBaseUrl,
  });

  @override
  State<ContentManagementScreen> createState() =>
      _ContentManagementScreenState();
}

class _ContentManagementScreenState extends State<ContentManagementScreen> {
  late final AdminApiClient _api;
  late final TextEditingController _rechercheCtrl;
  late final ScrollController _scrollCtrl;

  // Etat des filtres
  String? _filterMatiere;
  String? _filterExamen;
  String? _filterSerie;
  int? _filterAnnee;

  // Etat des donnees
  AdminStatsData? _stats;
  List<AdminQuestion> _questions = [];
  int _totalQuestions = 0;
  int _offset = 0;
  bool _loadingQuestions = false;
  bool _loadingStats = false;
  String? _error;

  // Logs
  List<AdminActionLogEntry> _logs = [];

  @override
  void initState() {
    super.initState();
    _api = AdminApiClient(
      baseUrl: widget.apiBaseUrl,
      token: widget.adminToken,
    );
    _rechercheCtrl = TextEditingController();
    _scrollCtrl = ScrollController();
    _scrollCtrl.addListener(_onScroll);
    // Premier chargement differe pour laisser le build se faire
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshAll());
  }

  @override
  void dispose() {
    _rechercheCtrl.dispose();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 200 &&
        !_loadingQuestions &&
        _questions.length < _totalQuestions) {
      _loadMoreQuestions();
    }
  }

  // ─── Chargement des donnees ───────────────────────────────────
  Future<void> _refreshAll() async {
    await Future.wait([
      _loadStats(),
      _loadLogs(),
      _reloadQuestions(),
    ]);
  }

  Future<void> _loadStats() async {
    setState(() {
      _loadingStats = true;
      _error = null;
    });
    try {
      final s = await _api.fetchStats();
      if (!mounted) return;
      setState(() {
        _stats = s;
        _loadingStats = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingStats = false;
        _error = 'Erreur stats: ${_dioError(e)}';
      });
    }
  }

  Future<void> _loadLogs() async {
    try {
      final logs = await _api.fetchLogs(limit: _kLogsLimit);
      if (!mounted) return;
      setState(() => _logs = logs);
    } on DioException {
      // Les logs sont non bloquants
    }
  }

  Future<void> _reloadQuestions() async {
    setState(() {
      _offset = 0;
      _loadingQuestions = true;
      _error = null;
    });
    try {
      final result = await _api.listQuestions(
        matiere: _filterMatiere,
        examen: _filterExamen,
        serie: _filterSerie,
        annee: _filterAnnee,
        recherche: _rechercheCtrl.text.trim().isEmpty
            ? null
            : _rechercheCtrl.text.trim(),
        limit: _kPageSize,
        offset: 0,
      );
      if (!mounted) return;
      setState(() {
        _questions = result.items;
        _totalQuestions = result.total;
        _offset = result.items.length;
        _loadingQuestions = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingQuestions = false;
        _error = 'Erreur liste: ${_dioError(e)}';
      });
    }
  }

  Future<void> _loadMoreQuestions() async {
    if (_loadingQuestions) return;
    setState(() => _loadingQuestions = true);
    try {
      final result = await _api.listQuestions(
        matiere: _filterMatiere,
        examen: _filterExamen,
        serie: _filterSerie,
        annee: _filterAnnee,
        recherche: _rechercheCtrl.text.trim().isEmpty
            ? null
            : _rechercheCtrl.text.trim(),
        limit: _kPageSize,
        offset: _offset,
      );
      if (!mounted) return;
      setState(() {
        _questions.addAll(result.items);
        _offset += result.items.length;
        _loadingQuestions = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _loadingQuestions = false);
      _showSnack('Erreur pagination: ${_dioError(e)}', isError: true);
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────
  String _dioError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['detail'] != null) {
      return '${data['detail']}';
    }
    return e.message ?? e.type.name;
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── Actions ──────────────────────────────────────────────────
  Future<void> _onSearch() async {
    await _reloadQuestions();
  }

  Future<void> _onClearFilters() async {
    _rechercheCtrl.clear();
    setState(() {
      _filterMatiere = null;
      _filterExamen = null;
      _filterSerie = null;
      _filterAnnee = null;
    });
    await _reloadQuestions();
  }

  Future<void> _onAddQuestion() async {
    final created = await showDialog<AdminQuestion>(
      context: context,
      builder: (_) => _QuestionFormDialog(
        api: _api,
        mode: _FormMode.create,
      ),
    );
    if (created != null) {
      _showSnack('Question ${created.id} creee');
      await _refreshAll();
    }
  }

  Future<void> _onEditQuestion(AdminQuestion q) async {
    final updated = await showDialog<AdminQuestion>(
      context: context,
      builder: (_) => _QuestionFormDialog(
        api: _api,
        mode: _FormMode.edit,
        initial: q,
      ),
    );
    if (updated != null) {
      _showSnack('Question ${updated.id} mise a jour');
      await _refreshAll();
    }
  }

  Future<void> _onDeleteQuestion(AdminQuestion q) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la question ?'),
        content: Text(
          'Cette action est irreversible.\n\n'
          'ID : ${q.id}\n'
          'Examen : ${q.examen}\n'
          'Matiere : ${q.matiere}\n'
          'Enonce : ${q.enonce.length > 80 ? '${q.enonce.substring(0, 80)}...' : q.enonce}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _api.deleteQuestion(q.id);
      _showSnack('Question ${q.id} supprimee');
      await _refreshAll();
    } on DioException catch (e) {
      _showSnack('Erreur suppression: ${_dioError(e)}', isError: true);
    }
  }

  Future<void> _onImportJson() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _ImportJsonDialog(api: _api),
    );
    if (result != null) {
      final created = result['created'] as int? ?? 0;
      final updated = result['updated'] as int? ?? 0;
      final skipped = result['skipped'] as int? ?? 0;
      final errors = (result['errors'] as List?)?.length ?? 0;
      _showSnack(
        'Import: $created creees, $updated modifiees, $skipped ignorees, $errors erreurs',
        isError: errors > 0 && created == 0 && updated == 0,
      );
      await _refreshAll();
    }
  }

  Future<void> _onExportJson() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _ExportDialog(api: _api),
    );
    if (result != null) {
      _showSnack('Export termine ($result)');
    }
  }

  // ─── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion du contenu'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraichir',
            onPressed: _refreshAll,
          ),
        ],
      ),
      body: _error != null && _stats == null
          ? _ErrorView(message: _error!, onRetry: _refreshAll)
          : RefreshIndicator(
              onRefresh: _refreshAll,
              child: CustomScrollView(
                controller: _scrollCtrl,
                slivers: [
                  // ─── Stats ────────────────────────────────────
                  SliverToBoxAdapter(child: _buildStatsSection()),
                  // ─── Barre filtres ────────────────────────────
                  SliverToBoxAdapter(child: _buildFiltersBar()),
                  // ─── Liste questions ──────────────────────────
                  if (_questions.isEmpty && !_loadingQuestions)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(
                        icon: Icons.inbox,
                        message: _error != null
                            ? _error!
                            : 'Aucune question. Cliquez sur "+" pour en ajouter.',
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          if (i < _questions.length) {
                            return _QuestionCard(
                              question: _questions[i],
                              onEdit: () => _onEditQuestion(_questions[i]),
                              onDelete: () => _onDeleteQuestion(_questions[i]),
                            );
                          }
                          // Indicateur de chargement en bas
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: _questions.length < _totalQuestions
                                  ? const CircularProgressIndicator()
                                  : Text(
                                      'Fin de la liste (${_questions.length}/$_totalQuestions)',
                                      style: AppTextStyles.bodySmall,
                                    ),
                            ),
                          );
                        },
                        childCount: _questions.length + 1,
                      ),
                    ),
                  // ─── Logs ────────────────────────────────────
                  SliverToBoxAdapter(child: _buildLogsSection()),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'export',
            onPressed: _onExportJson,
            tooltip: 'Export JSON',
            child: const Icon(Icons.download),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'import',
            onPressed: _onImportJson,
            tooltip: 'Import JSON',
            child: const Icon(Icons.upload),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: _onAddQuestion,
            tooltip: 'Ajouter une question',
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  // ─── Sous-widgets ─────────────────────────────────────────────
  Widget _buildStatsSection() {
    if (_loadingStats && _stats == null) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final s = _stats ?? const AdminStatsData();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Statistiques contenu', style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatChip(
                label: 'Total',
                value: '${s.totalQuestions}',
                color: AppColors.primary,
                icon: Icons.question_answer,
              ),
              _StatChip(
                label: 'Calibrees IRT',
                value:
                    '${s.irtCalibratedCount} (${s.irtCalibratedPercent.toStringAsFixed(1)}%)',
                color: AppColors.info,
                icon: Icons.tune,
              ),
              _StatChip(
                label: 'Sans explication',
                value: '${s.questionsWithoutExplanation}',
                color: s.questionsWithoutExplanation > 0
                    ? AppColors.warning
                    : AppColors.success,
                icon: Icons.info_outline,
              ),
              _StatChip(
                label: 'Doublons potentiels',
                value: '${s.duplicateWarningsCount}',
                color: s.duplicateWarningsCount > 0
                    ? AppColors.error
                    : AppColors.success,
                icon: Icons.warning_amber,
              ),
            ],
          ),
          if (s.byMatiere.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Par matiere :', style: AppTextStyles.label),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: s.byMatiere.entries.map((e) {
                return Chip(
                  label: Text('${e.key}: ${e.value}'),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFiltersBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          TextField(
            controller: _rechercheCtrl,
            decoration: InputDecoration(
              hintText: 'Rechercher dans l\'enonce...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _rechercheCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _rechercheCtrl.clear();
                        _onSearch();
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onSubmitted: (_) => _onSearch(),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterDropdown(
                  label: 'Examen',
                  value: _filterExamen,
                  items: _kExamens,
                  onChanged: (v) {
                    setState(() => _filterExamen = v);
                    _onSearch();
                  },
                ),
                const SizedBox(width: 8),
                _FilterDropdown(
                  label: 'Serie',
                  value: _filterSerie,
                  items: _kSeries,
                  onChanged: (v) {
                    setState(() => _filterSerie = v);
                    _onSearch();
                  },
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 110,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Annee',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) {
                      final n = int.tryParse(v);
                      _filterAnnee = n;
                    },
                    onSubmitted: (_) => _onSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                if (_filterExamen != null ||
                    _filterSerie != null ||
                    _filterAnnee != null ||
                    _rechercheCtrl.text.isNotEmpty)
                  TextButton.icon(
                    onPressed: _onClearFilters,
                    icon: const Icon(Icons.filter_alt_off, size: 18),
                    label: const Text('Effacer'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_totalQuestions question(s) au total',
                style: AppTextStyles.bodySmall,
              ),
              if (_loadingQuestions)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildLogsSection() {
    if (_logs.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text('Actions recentes (${_logs.length})',
                  style: AppTextStyles.label),
            ],
          ),
          const SizedBox(height: 8),
          ...(_logs.take(10).map((log) => _LogTile(log: log))),
        ],
      ),
    );
  }
}

// ─── Sous-widgets statiques ─────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.bodySmall),
              Text(value,
                  style: AppTextStyles.label
                      .copyWith(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
        items: [
          const DropdownMenuItem<String>(child: Text('Tous')),
          ...items.map((e) => DropdownMenuItem(value: e, child: Text(e))),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final AdminQuestion question;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _QuestionCard({
    required this.question,
    required this.onEdit,
    required this.onDelete,
  });

  Color _typeColor(String type) {
    switch (type) {
      case 'qcm':
        return AppColors.info;
      case 'calcul':
        return AppColors.primary;
      case 'redaction':
        return AppColors.accent;
      case 'vraiFaux':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ligne 1 : ID + badges
            Row(
              children: [
                Expanded(
                  child: Text(
                    question.id,
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (question.irtCalibrated)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.verified, size: 14, color: AppColors.info),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            // Ligne 2 : meta chips
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _MetaChip(question.examen, AppColors.primary),
                if (question.serie != null)
                  _MetaChip('Serie ${question.serie}', AppColors.accent),
                _MetaChip(question.matiere, AppColors.info),
                if (question.annee != null)
                  _MetaChip('${question.annee}', AppColors.textSecondary),
                _MetaChip(question.type, _typeColor(question.type)),
                if (question.points != null)
                  _MetaChip('${question.points} pts', AppColors.warning),
              ],
            ),
            const SizedBox(height: 8),
            // Ligne 3 : enonce
            Text(
              question.enonce,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 4),
            // Ligne 4 : reponse
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.08),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Reponse : ${question.reponse}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (question.explication == null ||
                question.explication!.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 12, color: AppColors.warning),
                    const SizedBox(width: 4),
                    Text('Sans explication',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.warning)),
                  ],
                ),
              ),
            // Ligne 5 : actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Modifier'),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: Icon(Icons.delete,
                      size: 16, color: AppColors.error),
                  label: Text('Supprimer',
                      style: TextStyle(color: AppColors.error)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final Color color;
  const _MetaChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(color: color),
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final AdminActionLogEntry log;
  const _LogTile({required this.log});

  Color _actionColor(String action) {
    switch (action) {
      case 'create':
        return AppColors.success;
      case 'update':
        return AppColors.info;
      case 'delete':
        return AppColors.error;
      case 'import':
        return AppColors.accent;
      case 'export':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatTime(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.day)}/${two(t.month)} ${two(t.hour)}:${two(t.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final color = _actionColor(log.action);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(_formatTime(log.timestamp), style: AppTextStyles.bodySmall),
          const SizedBox(width: 8),
          Text(log.action.toUpperCase(),
              style: AppTextStyles.label.copyWith(color: color)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              log.questionId ?? '-',
              style: AppTextStyles.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Erreur de chargement', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.textDisabled),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center, style: AppTextStyles.body),
          ],
        ),
      ),
    );
  }
}

// ─── Dialog formulaire create / edit ────────────────────────────────

enum _FormMode { create, edit }

class _QuestionFormDialog extends StatefulWidget {
  final AdminApiClient api;
  final _FormMode mode;
  final AdminQuestion? initial;

  const _QuestionFormDialog({
    required this.api,
    required this.mode,
    this.initial,
  });

  @override
  State<_QuestionFormDialog> createState() => _QuestionFormDialogState();
}

class _QuestionFormDialogState extends State<_QuestionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _idCtrl;
  late final TextEditingController _enonceCtrl;
  late final TextEditingController _reponseCtrl;
  late final TextEditingController _explicationCtrl;
  late final TextEditingController _matiereCtrl;
  late final TextEditingController _chapitreCtrl;
  late final TextEditingController _competenceCtrl;
  late final TextEditingController _anneeCtrl;
  late final TextEditingController _pointsCtrl;
  late final TextEditingController _irtACtrl;
  late final TextEditingController _irtBCtrl;
  late final TextEditingController _irtCCtrl;

  String _examen = 'BEPC';
  String? _serie;
  String _type = 'ouvert';
  List<String> _choix = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final q = widget.initial;
    _idCtrl = TextEditingController(text: q?.id ?? '');
    _enonceCtrl = TextEditingController(text: q?.enonce ?? '');
    _reponseCtrl = TextEditingController(text: q?.reponse ?? '');
    _explicationCtrl = TextEditingController(text: q?.explication ?? '');
    _matiereCtrl = TextEditingController(text: q?.matiere ?? 'Mathematiques');
    _chapitreCtrl = TextEditingController(text: q?.chapitre ?? '');
    _competenceCtrl = TextEditingController(text: q?.competenceId ?? '');
    _anneeCtrl = TextEditingController(text: q?.annee?.toString() ?? '');
    _pointsCtrl = TextEditingController(text: q?.points?.toString() ?? '');
    _irtACtrl = TextEditingController(text: q?.irtA?.toString() ?? '');
    _irtBCtrl = TextEditingController(text: q?.irtB?.toString() ?? '');
    _irtCCtrl = TextEditingController(text: q?.irtC?.toString() ?? '');
    _examen = q?.examen ?? 'BEPC';
    _serie = q?.serie;
    _type = q?.type ?? 'ouvert';
    _choix = q?.choix != null ? List<String>.from(q!.choix!) : [];
    // Pour le QCM : on s'assure d'avoir 4 champs
    while (_choix.length < 4) {
      _choix.add('');
    }
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _enonceCtrl.dispose();
    _reponseCtrl.dispose();
    _explicationCtrl.dispose();
    _matiereCtrl.dispose();
    _chapitreCtrl.dispose();
    _competenceCtrl.dispose();
    _anneeCtrl.dispose();
    _pointsCtrl.dispose();
    _irtACtrl.dispose();
    _irtBCtrl.dispose();
    _irtCCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final choix = _type == 'qcm'
        ? _choix.where((c) => c.trim().isNotEmpty).toList()
        : null;
    if (_type == 'qcm' && (choix == null || choix.length != 4)) {
      setState(() => _saving = false);
      _showError('Le QCM doit comporter exactement 4 choix.');
      return;
    }
    if (_type == 'qcm' && !_choix.contains(_reponseCtrl.text.trim())) {
      setState(() => _saving = false);
      _showError('La reponse doit etre un des 4 choix.');
      return;
    }

    final payload = <String, dynamic>{
      'id': _idCtrl.text.trim(),
      'enonce': _enonceCtrl.text.trim(),
      'reponse': _reponseCtrl.text.trim(),
      'explication': _explicationCtrl.text.trim().isEmpty
          ? null
          : _explicationCtrl.text.trim(),
      'matiere': _matiereCtrl.text.trim(),
      'chapitre': _chapitreCtrl.text.trim(),
      'competence_id': _competenceCtrl.text.trim(),
      'examen': _examen,
      'serie': _examen == 'BEPC' ? null : _serie,
      'annee': int.tryParse(_anneeCtrl.text.trim()),
      'type': _type,
      'choix': choix,
      'points': int.tryParse(_pointsCtrl.text.trim()),
      'irt_a': double.tryParse(_irtACtrl.text.trim()),
      'irt_b': double.tryParse(_irtBCtrl.text.trim()),
      'irt_c': double.tryParse(_irtCCtrl.text.trim()),
    };

    try {
      AdminQuestion result;
      if (widget.mode == _FormMode.create) {
        result = await widget.api.createQuestion(
          AdminQuestion.fromJson(payload),
        );
      } else {
        // Update : on retire id / matiere (non modifiables via PUT)
        final patch = Map<String, dynamic>.from(payload)
          ..remove('id')
          ..remove('matiere');
        result = await widget.api.updateQuestion(
          widget.initial!.id,
          patch,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      final data = e.response?.data;
      final msg = data is Map && data['detail'] != null
          ? '${data['detail']}'
          : e.message ?? 'Erreur inconnue';
      _showError(msg);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCreate = widget.mode == _FormMode.create;
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      isCreate ? Icons.add_circle : Icons.edit,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isCreate
                          ? 'Nouvelle question'
                          : 'Modifier ${widget.initial!.id}',
                      style: AppTextStyles.h3,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ID (uniquement en creation)
                if (isCreate)
                  TextFormField(
                    controller: _idCtrl,
                    decoration: const InputDecoration(
                      labelText: 'ID *',
                      hintText: 'TG-BEPC-MATHS-2024-Q01',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Requis';
                      if (v.trim().length < 3) return 'Min 3 caracteres';
                      return null;
                    },
                  ),
                if (isCreate) const SizedBox(height: 12),

                // Examen + Serie
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _examen,
                        decoration: const InputDecoration(
                          labelText: 'Examen *',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: _kExamens
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() {
                            _examen = v;
                            if (v == 'BEPC') _serie = null;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _serie,
                        decoration: InputDecoration(
                          labelText: 'Serie',
                          border: const OutlineInputBorder(),
                          isDense: true,
                          enabled: _examen != 'BEPC',
                        ),
                        items: _kSeries
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e),
                                ))
                            .toList(),
                        onChanged: _examen == 'BEPC'
                            ? null
                            : (v) => setState(() => _serie = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Matiere + Type
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _matiereCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Matiere *',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Requis' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _type,
                        decoration: const InputDecoration(
                          labelText: 'Type *',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: _kTypes
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _type = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Chapitre + Competence
                TextFormField(
                  controller: _chapitreCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Chapitre *',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _competenceCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Competence ID *',
                    hintText: 'TG-MATHS-EQ1D-001',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requis' : null,
                ),
                const SizedBox(height: 12),

                // Annee + Points
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _anneeCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Annee',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _pointsCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Points (1-5)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Enonce
                TextFormField(
                  controller: _enonceCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Enonce *',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requis';
                    if (v.trim().length < 10) return 'Min 10 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Choix QCM (conditionnel)
                if (_type == 'qcm') ...[
                  Text('Choix (4 requis) :', style: AppTextStyles.label),
                  const SizedBox(height: 4),
                  for (int i = 0; i < 4; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: TextFormField(
                        initialValue: _choix[i],
                        decoration: InputDecoration(
                          labelText: 'Choix ${i + 1}',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (v) => _choix[i] = v,
                      ),
                    ),
                  const SizedBox(height: 8),
                ],

                // Reponse
                TextFormField(
                  controller: _reponseCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Reponse *',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requis' : null,
                ),
                const SizedBox(height: 12),

                // Explication
                TextFormField(
                  controller: _explicationCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Explication (optionnel)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),

                // IRT (avance)
                ExpansionTile(
                  title: Text('Parametres IRT (avance)',
                      style: AppTextStyles.label),
                  childrenPadding:
                      const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _irtACtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                signed: true, decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'a (discrimination)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _irtBCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                signed: true, decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'b (difficulte)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _irtCCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                signed: true, decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'c (chance)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Boutons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _saving ? null : () => Navigator.of(context).pop(),
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _saving ? null : _submit,
                      child: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(isCreate ? 'Creer' : 'Enregistrer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Dialog import JSON ─────────────────────────────────────────────

class _ImportJsonDialog extends StatefulWidget {
  final AdminApiClient api;
  const _ImportJsonDialog({required this.api});

  @override
  State<_ImportJsonDialog> createState() => _ImportJsonDialogState();
}

class _ImportJsonDialogState extends State<_ImportJsonDialog> {
  final _ctrl = TextEditingController();
  bool _overwrite = false;
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) {
      _showError('Collez un JSON valide.');
      return;
    }
    List<dynamic> parsed;
    try {
      parsed = _parseJsonArray(text);
    } catch (e) {
      _showError('JSON invalide : $e');
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await widget.api.batchImport(
        parsed.cast<Map<String, dynamic>>(),
        overwrite: _overwrite,
      );
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final data = e.response?.data;
      final msg = data is Map && data['detail'] != null
          ? '${data['detail']}'
          : e.message ?? 'Erreur inconnue';
      _showError(msg);
    }
  }

  List<dynamic> _parseJsonArray(String text) {
    final decoded = jsonDecode(text);
    if (decoded is! List) {
      throw FormatException('Le JSON doit etre un tableau.');
    }
    return decoded;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      _ctrl.text = data!.text!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.maxFinite,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.upload, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('Import JSON', style: AppTextStyles.h3),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Collez un tableau JSON de questions (format QuestionCreate).',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _pasteFromClipboard,
                  icon: const Icon(Icons.content_paste, size: 16),
                  label: const Text('Coller depuis le presse-papier'),
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: TextFormField(
                  controller: _ctrl,
                  maxLines: 12,
                  decoration: const InputDecoration(
                    hintText: '[\n  { "id": "TG-...", "enonce": "...", ... }\n]',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Ecraser les questions existantes'),
                value: _overwrite,
                onChanged: (v) => setState(() => _overwrite = v),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _loading ? null : () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Importer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Dialog export JSON ─────────────────────────────────────────────

class _ExportDialog extends StatefulWidget {
  final AdminApiClient api;
  const _ExportDialog({required this.api});

  @override
  State<_ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<_ExportDialog> {
  String _format = 'json';
  bool _loading = false;
  String? _content;
  int? _count;

  Future<void> _doExport() async {
    setState(() {
      _loading = true;
      _content = null;
      _count = null;
    });
    try {
      final result = await widget.api.batchExport(format: _format);
      if (!mounted) return;
      setState(() {
        _content = result.content;
        _count = result.count;
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final data = e.response?.data;
      final msg = data is Map && data['detail'] != null
          ? '${data['detail']}'
          : e.message ?? 'Erreur';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _copyToClipboard() async {
    if (_content == null) return;
    await Clipboard.setData(ClipboardData(text: _content!));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contenu copie dans le presse-papier')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.maxFinite,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.download, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('Export contenu', style: AppTextStyles.h3),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Format : '),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('JSON'),
                    selected: _format == 'json',
                    onSelected: (_) => setState(() => _format = 'json'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('CSV'),
                    selected: _format == 'csv',
                    onSelected: (_) => setState(() => _format = 'csv'),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _loading ? null : _doExport,
                    icon: _loading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.download, size: 18),
                    label: const Text('Exporter'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_content != null) ...[
                Row(
                  children: [
                    Text('$_count question(s) exportees',
                        style: AppTextStyles.bodySmall),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _copyToClipboard,
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copier'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      _content!.length > 5000
                          ? '${_content!.substring(0, 5000)}\n... (tronque, ${_content!.length} caracteres au total)'
                          : _content!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Astuce : pour des volumes importants, utilisez plutot le '
                  'script CLI scripts/export_questions.py.',
                  style: AppTextStyles.bodySmall,
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    _loading
                        ? 'Export en cours...'
                        : 'Cliquez sur "Exporter" pour recuperer le contenu.',
                    style: AppTextStyles.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context)
                        .pop(_count != null ? '$_count questions' : null);
                  },
                  child: const Text('Fermer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
