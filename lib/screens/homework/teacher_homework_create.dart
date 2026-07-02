// lib/screens/homework/teacher_homework_create.dart
// Écran enseignant : créer un nouveau devoir.
//
// Formulaire multi-sections :
//   1. Infos générales : titre, description, matière,
//   2. Cible : classes (multi-sélection), deadline (date picker), durée,
//   3. Questions : sélection depuis banque mock + ajout manuel (QCM).
//
// À la soumission, le devoir est créé via HomeworkService.creerDevoir et
// l'utilisateur revient à la liste enseignant.
//
// Pour cette démo, la banque de questions est limitée à un petit set
// mock (3 questions par matière). L'ajout manuel crée un QCM simple.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/adaptive_colors.dart';
import '../../theme/app_theme.dart';
import '../models/homework.dart';
import '../services/homework_service.dart';

class TeacherHomeworkCreate extends StatefulWidget {
  const TeacherHomeworkCreate({super.key});

  @override
  State<TeacherHomeworkCreate> createState() => _TeacherHomeworkCreateState();
}

class _TeacherHomeworkCreateState extends State<TeacherHomeworkCreate> {
  // ─── Controllers ─────────────────────────────────────────────
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // ─── État formulaire ────────────────────────────────────────
  String _matiere = 'Mathématiques';
  final Set<String> _selectedClasses = {'3e A'};
  DateTime _dateLimit = DateTime.now().add(const Duration(days: 7));
  int _dureeMinutes = 30;
  final List<HomeworkQuestion> _selectedQuestions = [];

  // ─── Banque de questions mock (par matière) ─────────────────
  static const _banqueQuestions = <String, List<HomeworkQuestion>>{
    'Mathématiques': [
      HomeworkQuestion(
        id: 'bq_math_1',
        enonce: 'Résoudre : 3x - 7 = 14. Que vaut x ?',
        choix: ['x = 5', 'x = 7', 'x = 9', 'x = 21'],
        bonIndex: 1,
        points: 2,
        explication: '3x = 14 + 7 = 21, donc x = 7.',
      ),
      HomeworkQuestion(
        id: 'bq_math_2',
        enonce: 'Aire d\'un disque de rayon 5 cm (π ≈ 3,14) ?',
        choix: ['15,7 cm²', '31,4 cm²', '78,5 cm²', '157 cm²'],
        bonIndex: 2,
        points: 2,
        explication: 'A = π × r² = 3,14 × 25 = 78,5 cm².',
      ),
      HomeworkQuestion(
        id: 'bq_math_3',
        enonce: 'PGCD de 24 et 36 ?',
        choix: ['6', '8', '12', '24'],
        bonIndex: 2,
        points: 1,
        explication: '24 = 2³×3, 36 = 2²×3². PGCD = 2²×3 = 12.',
      ),
    ],
    'Français': [
      HomeworkQuestion(
        id: 'bq_fr_1',
        enonce: '"Les montagnes dorment." Quelle figure de style ?',
        choix: ['Personnification', 'Métaphore', 'Comparaison', 'Hyperbole'],
        bonIndex: 0,
        points: 2,
        explication: 'On prête une action humaine aux montagnes.',
      ),
      HomeworkQuestion(
        id: 'bq_fr_2',
        enonce: 'Quelle est la nature du mot "rapidement" ?',
        choix: ['Nom', 'Adjectif', 'Adverbe', 'Verbe'],
        bonIndex: 2,
        points: 1,
        explication: 'Le suffixe -ment indique un adverbe.',
      ),
    ],
    'Sciences Physiques': [
      HomeworkQuestion(
        id: 'bq_sci_1',
        enonce: 'Unité de la résistance électrique ?',
        choix: ['Volt', 'Ampère', 'Ohm', 'Watt'],
        bonIndex: 2,
        points: 1,
        explication: 'La résistance se mesure en Ohm (Ω).',
      ),
      HomeworkQuestion(
        id: 'bq_sci_2',
        enonce: 'Loi d\'Ohm : U = ?',
        choix: ['R + I', 'R - I', 'R × I', 'R / I'],
        bonIndex: 2,
        points: 2,
        explication: 'U (V) = R (Ω) × I (A).',
      ),
    ],
    'SVT': [
      HomeworkQuestion(
        id: 'bq_svt_1',
        enonce: 'Où a lieu la photosynthèse ?',
        choix: ['Racines', 'Feuilles', 'Tige', 'Fleurs'],
        bonIndex: 1,
        points: 1,
        explication: 'La chlorophylle des feuilles capte la lumière.',
      ),
      HomeworkQuestion(
        id: 'bq_svt_2',
        enonce: 'Quel gaz est absorbé par les plantes ?',
        choix: ['Oxygène', 'Azote', 'Dioxyde de carbone', 'Hydrogène'],
        bonIndex: 2,
        points: 1,
        explication: 'Les plantes absorbent CO₂ et rejettent O₂.',
      ),
    ],
    'Histoire-Géographie': [
      HomeworkQuestion(
        id: 'bq_hist_1',
        enonce: 'Capitale du Togo ?',
        choix: ['Sokodé', 'Kara', 'Lomé', 'Atakpamé'],
        bonIndex: 2,
        points: 1,
        explication: 'Lomé est la capitale politique et économique.',
      ),
      HomeworkQuestion(
        id: 'bq_hist_2',
        enonce: 'Indépendance du Togo en quelle année ?',
        choix: ['1958', '1960', '1962', '1965'],
        bonIndex: 1,
        points: 2,
        explication: 'Le 27 avril 1960.',
      ),
    ],
  };

  static const _toutesClasses = ['3e A', '3e B', 'Terminale C'];
  static const _toutesMatieres = [
    'Mathématiques',
    'Français',
    'Sciences Physiques',
    'SVT',
    'Histoire-Géographie',
  ];

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau devoir'),
        actions: [
          TextButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text(
              'Publier',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle(context, '1. Informations générales',
                  icon: Icons.info_outline),
              const SizedBox(height: 12),
              _buildGeneralInfoSection(),
              const SizedBox(height: 24),
              _buildSectionTitle(context, '2. Cible & deadline',
                  icon: Icons.group_outlined),
              const SizedBox(height: 12),
              _buildCibleSection(context),
              const SizedBox(height: 24),
              _buildSectionTitle(context, '3. Questions',
                  icon: Icons.quiz_outlined),
              const SizedBox(height: 4),
              Text(
                'Sélectionne des questions depuis la banque ou crée-en '
                'une nouvelle. Total actuel : ${_selectedQuestions.length} '
                'question(s) / ${_totalPoints()} pts.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AdaptiveColors.textSecondary(context),
                ),
              ),
              const SizedBox(height: 12),
              _buildQuestionsSection(context),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.publish_outlined),
                label: const Text('Publier le devoir'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Section title ───────────────────────────────────────────
  Widget _buildSectionTitle(BuildContext context, String title,
      {required IconData icon}) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(title, style: AppTextStyles.h3.copyWith(fontSize: 16)),
      ],
    );
  }

  // ─── Section 1 : Infos générales ────────────────────────────
  Widget _buildGeneralInfoSection() {
    return Column(
      children: [
        TextFormField(
          controller: _titreController,
          decoration: const InputDecoration(
            labelText: 'Titre du devoir *',
            hintText: 'Ex: Devoir BEPC — Calcul littéral',
          ),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Titre requis' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description / consignes',
            hintText: 'Ex: Révisions sur les équations. 30 min conseillées.',
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _matiere,
          decoration: const InputDecoration(labelText: 'Matière *'),
          items: _toutesMatieres
              .map((m) => DropdownMenuItem(value: m, child: Text(m)))
              .toList(),
          onChanged: (v) {
            if (v != null) {
              setState(() {
                _matiere = v;
                // Nettoie les questions sélectionnées qui ne sont plus
                // dans la nouvelle matière.
                _selectedQuestions.removeWhere((q) {
                  final banque = _banqueQuestions[v] ?? [];
                  return !banque.any((b) => b.id == q.id);
                });
              });
            }
          },
        ),
      ],
    );
  }

  // ─── Section 2 : Cible & deadline ───────────────────────────
  Widget _buildCibleSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Classe(s) assignée(s) *',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _toutesClasses.map((c) {
            final isSelected = _selectedClasses.contains(c);
            return FilterChip(
              label: Text(c),
              selected: isSelected,
              onSelected: (sel) {
                setState(() {
                  if (sel) {
                    _selectedClasses.add(c);
                  } else {
                    _selectedClasses.remove(c);
                  }
                });
              },
              selectedColor: AppColors.primary.withOpacity(0.15),
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected
                    ? AppColors.primary
                    : AdaptiveColors.textPrimary(context),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            );
          }).toList(),
        ),
        if (_selectedClasses.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Sélectionne au moins une classe.',
              style: TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _pickDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date limite',
                    suffixIcon: Icon(Icons.event_outlined),
                  ),
                  child: Text(_formatDate(_dateLimit)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 120,
              child: DropdownButtonFormField<int>(
                value: _dureeMinutes,
                decoration: const InputDecoration(labelText: 'Durée'),
                items: [15, 20, 30, 45, 60, 90]
                    .map((d) => DropdownMenuItem(
                          value: d,
                          child: Text('$d min'),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _dureeMinutes = v ?? 30),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateLimit,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dateLimit),
      );
      setState(() {
        _dateLimit = DateTime(
          picked.year,
          picked.month,
          picked.day,
          time?.hour ?? 23,
          time?.minute ?? 59,
        );
      });
    }
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year} à ${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  // ─── Section 3 : Questions ──────────────────────────────────
  Widget _buildQuestionsSection(BuildContext context) {
    final banque = _banqueQuestions[_matiere] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Banque de questions
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AdaptiveColors.surface(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AdaptiveColors.divider(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.library_books_outlined,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Banque $_matiere (${banque.length})',
                    style: AppTextStyles.label
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...banque.map((q) {
                final isSelected =
                    _selectedQuestions.any((s) => s.id == q.id);
                return CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: isSelected,
                  onChanged: (sel) {
                    setState(() {
                      if (sel == true) {
                        _selectedQuestions.add(q);
                      } else {
                        _selectedQuestions.removeWhere((s) => s.id == q.id);
                      }
                    });
                  },
                  title: Text(
                    q.enonce,
                    style: AppTextStyles.body.copyWith(fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${q.points} pt${q.points > 1 ? 's' : ''} • '
                    '${q.isQcm ? 'QCM' : 'Question ouverte'}',
                    style: TextStyle(
                      color: AdaptiveColors.textSecondary(context),
                      fontSize: 11,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Bouton : créer une nouvelle question
        OutlinedButton.icon(
          onPressed: _addCustomQuestion,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Créer une nouvelle question'),
        ),
        const SizedBox(height: 12),

        // Récap des questions sélectionnées
        if (_selectedQuestions.isNotEmpty) ...[
          Text(
            'Questions sélectionnées (${_selectedQuestions.length})',
            style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ..._selectedQuestions.asMap().entries.map((entry) {
            final i = entry.key;
            final q = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primary.withOpacity(0.12),
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                title: Text(
                  q.enonce,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
                subtitle: Text(
                  '${q.points} pt${q.points > 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () {
                    setState(() {
                      _selectedQuestions.removeWhere((s) => s.id == q.id);
                    });
                  },
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  int _totalPoints() {
    return _selectedQuestions.fold(0, (s, q) => s + q.points);
  }

  // ─── Ajouter une question personnalisée ─────────────────────
  void _addCustomQuestion() {
    final enonceCtrl = TextEditingController();
    final choixCtrls = [
      TextEditingController(),
      TextEditingController(),
      TextEditingController(),
      TextEditingController(),
    ];
    int bonIndex = 0;
    int points = 1;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Nouvelle question (QCM)'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: enonceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Énoncé *',
                      hintText: 'Ex: Résoudre 2x + 3 = 11',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(4, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Radio<int>(
                            value: i,
                            groupValue: bonIndex,
                            onChanged: (v) => setDialogState(() => bonIndex = v!),
                          ),
                          Expanded(
                            child: TextField(
                              controller: choixCtrls[i],
                              decoration: InputDecoration(
                                labelText: 'Proposition ${String.fromCharCode(65 + i)}',
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: points,
                    decoration: const InputDecoration(labelText: 'Points'),
                    items: [1, 2, 3, 4]
                        .map((p) =>
                            DropdownMenuItem(value: p, child: Text('$p pts')))
                        .toList(),
                    onChanged: (v) => setDialogState(() => points = v ?? 1),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (enonceCtrl.text.trim().isEmpty) return;
                if (choixCtrls.any((c) => c.text.trim().isEmpty)) return;
                setState(() {
                  _selectedQuestions.add(HomeworkQuestion(
                    id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                    enonce: enonceCtrl.text.trim(),
                    choix: choixCtrls.map((c) => c.text.trim()).toList(),
                    bonIndex: bonIndex,
                    points: points,
                  ));
                });
                Navigator.of(ctx).pop();
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Soumission ──────────────────────────────────────────────
  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClasses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionne au moins une classe.')),
      );
      return;
    }
    if (_selectedQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoute au moins une question.')),
      );
      return;
    }

    final service = context.read<HomeworkService>();
    service.creerDevoir(
      titre: _titreController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? 'Aucune consigne spécifique.'
          : _descriptionController.text.trim(),
      matiere: _matiere,
      classes: _selectedClasses.toList(),
      dateLimit: _dateLimit,
      questions: List.unmodifiable(_selectedQuestions),
      dureeMinutes: _dureeMinutes,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Devoir "${_titreController.text.trim()}" publié !'),
        backgroundColor: AppColors.success,
      ),
    );
    Navigator.of(context).pop();
  }
}
