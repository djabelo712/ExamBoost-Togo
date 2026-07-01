// lib/screens/classroom/teacher_create_screen.dart
// Ecran enseignant : cree une session classe.
//
// Etapes :
//   1. Selection examen (BEPC / BAC1 / BAC2)
//   2. Selection matiere (filtre)
//   3. Selection multi-question (max 20)
//   4. Toggle mode live / devoir
//   5. Duree par question (default 30s, hidden si devoir)
//   6. Bouton "Lancer la session" -> POST /classroom/create
//   7. Affichage du code a 6 chiffres + bouton "Demarrer"
//
// Apres creation, on instancie ClassroomSocketService en role teacher
// et on navigue vers TeacherLiveScreen.

import 'package:flutter/material.dart';
import 'package:provider/provider';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/question.dart';
import '../../../services/question_service.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/app_logger.dart';
import 'models/classroom_player.dart';
import 'models/classroom_session.dart';
import 'services/classroom_rest_service.dart';
import 'services/classroom_socket_service.dart';
import 'teacher_live_screen.dart';

class TeacherCreateScreen extends StatefulWidget {
  const TeacherCreateScreen({super.key});

  @override
  State<TeacherCreateScreen> createState() => _TeacherCreateScreenState();
}

class _TeacherCreateScreenState extends State<TeacherCreateScreen> {
  final _questionService = QuestionService();

  // Configuration
  String _examen = 'BEPC';
  String? _matiere;
  ClassroomMode _mode = ClassroomMode.live;
  int _timeLimitSeconds = 30;
  int _homeworkDays = 7;

  // Etat UI
  bool _loading = true;
  bool _creating = false;
  List<Question> _allQuestions = const [];
  List<Question> _filteredQuestions = const [];
  final Set<String> _selectedIds = {};

  // URL backend par defaut
  static const _defaultBaseUrl = 'http://10.0.2.2:8000';
  static const _defaultWsUrl = 'ws://10.0.2.2:8000';

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      await _questionService.loadQuestions();
      // Recupere toutes les questions via un filtre "toutes" : on demande
      // chaque examen a tour de role puis on deduplique.
      final all = <Question>[];
      for (final exam in ['BEPC', 'BAC1', 'BAC2']) {
        all.addAll(_questionService.getByExamen(exam));
      }
      // Dedoublonne par id
      final seen = <String>{};
      _allQuestions =
          all.where((q) => seen.add(q.id)).toList(growable: false);
      _applyFilters();
    } catch (e) {
      AppLogger.error('Erreur chargement questions: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<String> get _availableMatieres {
    final matieres = _allQuestions
        .where((q) => q.examen == _examen)
        .map((q) => q.matiere)
        .toSet()
        .toList()
      ..sort();
    return matieres;
  }

  void _applyFilters() {
    _filteredQuestions = _allQuestions.where((q) {
      if (q.examen != _examen) return false;
      if (_matiere != null && q.matiere != _matiere) return false;
      return true;
    }).toList();
    // Nettoie la selection
    _selectedIds.removeWhere(
        (id) => !_filteredQuestions.any((q) => q.id == id));
  }

  void _toggleQuestion(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        if (_selectedIds.length >= 20) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Maximum 20 questions par session'),
              backgroundColor: AppColors.warning,
            ),
          );
          return;
        }
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _createSession() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selectionne au moins une question'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _creating = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final teacherId = prefs.getString('current_user_id') ?? 'teacher_demo';
      final teacherName =
          prefs.getString('classroom_teacher_name') ?? 'Enseignant';

      final rest = ClassroomRestService();
      final resp = await rest.createSession(
        baseUrl: _defaultBaseUrl,
        teacherId: teacherId,
        teacherName: teacherName,
        exam: _examen,
        matiere: _matiere,
        questionIds: _selectedIds.toList(),
        mode: _mode,
        timeLimitSeconds: _timeLimitSeconds,
        homeworkDays: _homeworkDays,
      );

      if (!mounted) return;

      // Connecte la WebSocket en role teacher
      final service = ClassroomSocketService();
      await service.connect(
        baseUrl: _defaultWsUrl,
        sessionCode: resp.sessionCode,
        playerName: teacherName,
        role: PlayerRole.teacher,
      );

      if (!mounted) {
        service.dispose();
        return;
      }

      // Attend confirmation joined
      await Future.delayed(const Duration(milliseconds: 1200));

      if (!mounted) {
        service.dispose();
        return;
      }

      setState(() => _creating = false);

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: service,
            child: TeacherLiveScreen(
              sessionCode: resp.sessionCode,
              questionIds: _selectedIds.toList(),
              mode: resp.mode,
            ),
          ),
        ),
      );
    } catch (e) {
      AppLogger.error('Erreur creation session: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Créer une session')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildModeToggle(),
                  const SizedBox(height: 20),
                  _buildExamSelector(),
                  const SizedBox(height: 16),
                  _buildMatiereSelector(),
                  const SizedBox(height: 16),
                  if (_mode == ClassroomMode.live) ...[
                    _buildTimeLimitSlider(),
                    const SizedBox(height: 16),
                  ] else ...[
                    _buildHomeworkDaysSlider(),
                    const SizedBox(height: 16),
                  ],
                  _buildQuestionSelection(),
                  const SizedBox(height: 16),
                  _buildSelectionSummary(),
                  const SizedBox(height: 24),
                  _buildLaunchButton(),
                ],
              ),
            ),
    );
  }

  // ─── Toggle mode live / devoir ─────────────────────────────────
  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mode de session', style: AppTextStyles.h3),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ModeChip(
                  label: 'Live (Kahoot)',
                  icon: Icons.bolt,
                  color: AppColors.primary,
                  isSelected: _mode == ClassroomMode.live,
                  description: 'Diffusion en direct\ntimer 30s',
                  onTap: () => setState(() => _mode = ClassroomMode.live),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ModeChip(
                  label: 'Devoir (asynchrone)',
                  icon: Icons.home_work,
                  color: AppColors.accent,
                  isSelected: _mode == ClassroomMode.homework,
                  description: 'Eleves rejoignent\nquand ils veulent',
                  onTap: () => setState(() => _mode = ClassroomMode.homework),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Selection examen ──────────────────────────────────────────
  Widget _buildExamSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Examen', style: AppTextStyles.h3),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ['BEPC', 'BAC1', 'BAC2'].map((e) {
              return ChoiceChip(
                label: Text(e),
                selected: _examen == e,
                onSelected: (_) {
                  setState(() {
                    _examen = e;
                    _matiere = null;
                    _applyFilters();
                  });
                },
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: _examen == e ? Colors.white : AppColors.textPrimary,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Selection matiere ─────────────────────────────────────────
  Widget _buildMatiereSelector() {
    final matieres = _availableMatieres;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Matiere (optionnel)', style: AppTextStyles.h3),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ChoiceChip(
                label: const Text('Toutes'),
                selected: _matiere == null,
                onSelected: (_) {
                  setState(() {
                    _matiere = null;
                    _applyFilters();
                  });
                },
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: _matiere == null
                      ? Colors.white
                      : AppColors.textPrimary,
                ),
              ),
              ...matieres.map((m) {
                return ChoiceChip(
                  label: Text(m),
                  selected: _matiere == m,
                  onSelected: (_) {
                    setState(() {
                      _matiere = m;
                      _applyFilters();
                    });
                  },
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: _matiere == m
                        ? Colors.white
                        : AppColors.textPrimary,
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Slider duree par question ─────────────────────────────────
  Widget _buildTimeLimitSlider() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Duree par question', style: AppTextStyles.h3),
              const Spacer(),
              Text(
                '$_timeLimitSeconds s',
                style: AppTextStyles.h3.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          Slider(
            value: _timeLimitSeconds.toDouble(),
            min: 10,
            max: 90,
            divisions: 8,
            activeColor: AppColors.primary,
            onChanged: (v) =>
                setState(() => _timeLimitSeconds = v.round()),
          ),
        ],
      ),
    );
  }

  // ─── Slider duree du devoir (jours) ────────────────────────────
  Widget _buildHomeworkDaysSlider() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Duree du devoir', style: AppTextStyles.h3),
              const Spacer(),
              Text(
                '$_homeworkDays j',
                style: AppTextStyles.h3.copyWith(color: AppColors.accent),
              ),
            ],
          ),
          Slider(
            value: _homeworkDays.toDouble(),
            min: 1,
            max: 14,
            divisions: 13,
            activeColor: AppColors.accent,
            onChanged: (v) => setState(() => _homeworkDays = v.round()),
          ),
          Text(
            'Les eleves pourront rejoindre cette session pendant '
            '$_homeworkDays jour(s) apres sa creation.',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  // ─── Selection des questions ───────────────────────────────────
  Widget _buildQuestionSelection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Questions', style: AppTextStyles.h3),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_selectedIds.length} / 20',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_filteredQuestions.length} question(s) disponible(s)',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 8),
          if (_filteredQuestions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.search_off,
                      size: 40, color: AppColors.textDisabled),
                  const SizedBox(height: 8),
                  Text(
                    'Aucune question pour ce filtre. Verifie que le fichier '
                    'assets/data/questions.json contient des questions pour '
                    'l\'examen $_examen.',
                    style: AppTextStyles.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredQuestions.length,
                itemBuilder: (context, i) {
                  final q = _filteredQuestions[i];
                  final isSelected = _selectedIds.contains(q.id);
                  return _QuestionPickTile(
                    question: q,
                    isSelected: isSelected,
                    onTap: () => _toggleQuestion(q.id),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ─── Resume selection ──────────────────────────────────────────
  Widget _buildSelectionSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _mode == ClassroomMode.live
                  ? '${_selectedIds.length} question(s), '
                      '$_timeLimitSeconds s par question en direct.'
                  : '${_selectedIds.length} question(s), '
                      'accessibles pendant $_homeworkDays jour(s).',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bouton lancer ─────────────────────────────────────────────
  Widget _buildLaunchButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _creating || _selectedIds.isEmpty ? null : _createSession,
        icon: _creating
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.play_arrow),
        label: Text(_creating ? 'Création...' : 'Lancer la session'),
      ),
    );
  }
}

// ─── Chip de mode ───────────────────────────────────────────────────
class _ModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final String description;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? color : AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon,
                  color: isSelected ? Colors.white : color, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white.withOpacity(0.85)
                      : AppColors.textSecondary,
                  fontSize: 11,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Tuile question (multi-select) ──────────────────────────────────
class _QuestionPickTile extends StatelessWidget {
  final Question question;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuestionPickTile({
    required this.question,
    required this.isSelected,
    required this.onTap,
  });

  Color _typeColor() {
    switch (question.type) {
      case QuestionType.qcm:
        return AppColors.info;
      case QuestionType.vraiFaux:
        return AppColors.success;
      case QuestionType.calcul:
        return AppColors.accent;
      case QuestionType.redaction:
        return Colors.purple;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primarySurface : null,
        borderRadius: BorderRadius.circular(10),
        border: isSelected
            ? Border.all(color: AppColors.primary, width: 1.5)
            : Border.all(color: AppColors.divider, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textDisabled,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check,
                        color: Colors.white, size: 16)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question.enonce,
                      style: AppTextStyles.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _typeColor().withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            question.type.name,
                            style: TextStyle(
                              color: _typeColor(),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (question.chapitre.isNotEmpty)
                          Expanded(
                            child: Text(
                              question.chapitre,
                              style: AppTextStyles.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
