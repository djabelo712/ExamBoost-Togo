// lib/widgets/exam/scratch_sheet_widget.dart
// Feuille de brouillon tactile pour le mode examen authentique.
//
// - Dialogue plein ecran (90% largeur, 80% hauteur).
// - Canvas tactile (CustomPaint + GestureDetector) ou l'eleve dessine au
//   doigt ou a la souris.
// - Outils : stylo (3 couleurs : noir, bleu, rouge), gomme, effacer tout.
// - Slider epaisseur trait (1-10 px).
// - Bouton undo / redo.
// - Sauvegarde PNG dans Hive (strokes serialises en JSON) - restaure
//   automatiquement le brouillon si l'eleve quitte et revient.
// - Bouton "Effacer tout" avec dialogue de confirmation.
// - Support souris (desktop) + tactile (mobile).
// - Fond blanc casse quadrille (comme une feuille de papier Seyes simplifiee).
//
// OUVERTURE : ScratchSheetWidget.show(context, examId, questionIndex).
// La cle Hive est "scratch_<examId>_q<questionIndex>".

import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_logger.dart';

/// Ouvre le brouillon plein ecran.
/// [examId] : identifiant de l'examen (ex: "BEPC-2026-sim").
/// [questionIndex] : index de la question courante (0-based).
///
/// Retourne true si l'utilisateur a effectivement quitte le brouillon
/// (toujours true actuellement ; reserve pour usage futur).
Future<bool> showScratchSheet(
  BuildContext context, {
  required String examId,
  required int questionIndex,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => ScratchSheetDialog(
      examId: examId,
      questionIndex: questionIndex,
    ),
  );
  return result ?? false;
}

class ScratchSheetDialog extends StatefulWidget {
  const ScratchSheetDialog({
    super.key,
    required this.examId,
    required this.questionIndex,
  });

  final String examId;
  final int questionIndex;

  @override
  State<ScratchSheetDialog> createState() => _ScratchSheetDialogState();
}

class _ScratchSheetDialogState extends State<ScratchSheetDialog> {
  // ─── Outils ──────────────────────────────────────────────────
  _Outil _outilActif = _Outil.stylo;
  Color _couleurStylo = Colors.black;
  double _epaisseur = 3.0;

  // ─── Strokes ─────────────────────────────────────────────────
  final List<Stroke> _strokes = [];
  final List<Stroke> _redoStack = [];

  // ─── Persistence Hive ────────────────────────────────────────
  late final Box<dynamic> _box;
  late final String _cleHive;
  bool _charge = false;

  @override
  void initState() {
    super.initState();
    _cleHive = 'scratch_${widget.examId}_q${widget.questionIndex}';
    _charger();
  }

  Future<void> _charger() async {
    try {
      _box = await Hive.openBox('scratch_sheets');
      final raw = _box.get(_cleHive);
      if (raw != null && raw is String) {
        final List<dynamic> liste = jsonDecode(raw);
        setState(() {
          _strokes.addAll(
            liste.map((s) => Stroke.fromJson(s as Map<String, dynamic>)),
          );
        });
      }
    } catch (e) {
      AppLogger.error('ScratchSheet chargement erreur: $e');
    } finally {
      if (mounted) setState(() => _charge = true);
    }
  }

  Future<void> _sauvegarder() async {
    try {
      final json = jsonEncode(
        _strokes.map((s) => s.toJson()).toList(),
      );
      await _box.put(_cleHive, json);
    } catch (e) {
      AppLogger.error('ScratchSheet sauvegarde erreur: $e');
    }
  }

  // ─── Actions canvas ──────────────────────────────────────────

  void _commencerStroke(Offset position) {
    setState(() {
      _strokes.add(Stroke(
        points: [position],
        couleur: _outilActif == _Outil.gomme ? Colors.white : _couleurStylo,
        epaisseur: _outilActif == _Outil.gomme ? _epaisseur * 3 : _epaisseur,
        estGomme: _outilActif == _Outil.gomme,
      ));
      _redoStack.clear();
    });
  }

  void _etendreStroke(Offset position) {
    if (_strokes.isEmpty) return;
    setState(() {
      _strokes.last.points.add(position);
    });
  }

  void _terminerStroke() {
    _sauvegarder();
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    setState(() {
      _redoStack.add(_strokes.removeLast());
    });
    _sauvegarder();
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    setState(() {
      _strokes.add(_redoStack.removeLast());
    });
    _sauvegarder();
  }

  Future<void> _effacerTout() async {
    final confirmer = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Effacer le brouillon ?'),
        content: const Text(
          'Tous les traits seront definitivement supprimes. '
          'Cette action est irreversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Effacer'),
          ),
        ],
      ),
    );
    if (confirmer == true) {
      setState(() {
        _strokes.clear();
        _redoStack.clear();
      });
      await _sauvegarder();
    }
  }

  void _fermer() {
    _sauvegarder();
    Navigator.of(context).pop(true);
  }

  // ─── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: size.width * 0.90,
        height: size.height * 0.80,
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildBarreOutils(),
            const SizedBox(height: 8),
            Expanded(child: _buildCanvas()),
            const SizedBox(height: 8),
            _buildBarreBas(),
          ],
        ),
      ),
    );
  }

  Widget _buildBarreOutils() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: 6,
        runSpacing: 6,
        children: [
          // Section outils
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _outilBtn(
                icon: Icons.create,
                label: 'Stylo',
                actif: _outilActif == _Outil.stylo,
                onTap: () => setState(() => _outilActif = _Outil.stylo),
              ),
              const SizedBox(width: 4),
              _outilBtn(
                icon: Icons.auto_fix_high,
                label: 'Gomme',
                actif: _outilActif == _Outil.gomme,
                onTap: () => setState(() => _outilActif = _Outil.gomme),
              ),
            ],
          ),
          // Section couleurs (actives seulement en mode stylo)
          if (_outilActif == _Outil.stylo)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _couleurBtn(Colors.black,
                    actif: _couleurStylo == Colors.black),
                _couleurBtn(const Color(0xFF1565C0),
                    actif: _couleurStylo == const Color(0xFF1565C0)),
                _couleurBtn(const Color(0xFFC62828),
                    actif: _couleurStylo == const Color(0xFFC62828)),
              ],
            ),
          // Slider epaisseur
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.line_weight, size: 16),
              SizedBox(
                width: 110,
                child: Slider(
                  value: _epaisseur,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: _epaisseur.toStringAsFixed(0),
                  onChanged: (v) => setState(() => _epaisseur = v),
                ),
              ),
            ],
          ),
          // Undo / Redo
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _iconBtn(
                icon: Icons.undo,
                actif: _strokes.isNotEmpty,
                onTap: _undo,
              ),
              _iconBtn(
                icon: Icons.redo,
                actif: _redoStack.isNotEmpty,
                onTap: _redo,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _outilBtn({
    required IconData icon,
    required String label,
    required bool actif,
    required VoidCallback onTap,
  }) {
    return Material(
      color: actif ? AppColors.primary : AppColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: actif ? Colors.white : AppColors.textPrimary),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTextStyles.label.copyWith(
                  color: actif ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _couleurBtn(Color couleur, {required bool actif}) {
    return GestureDetector(
      onTap: () => setState(() => _couleurStylo = couleur),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: couleur,
          shape: BoxShape.circle,
          border: Border.all(
            color: actif ? AppColors.primary : AppColors.divider,
            width: actif ? 3 : 1,
          ),
        ),
      ),
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required bool actif,
    required VoidCallback onTap,
  }) {
    return IconButton(
      onPressed: actif ? onTap : null,
      icon: Icon(icon, size: 20),
      color: AppColors.primary,
      disabledColor: AppColors.textDisabled,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      padding: EdgeInsets.zero,
    );
  }

  Widget _buildCanvas() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFDFCF7), // blanc casse
          border: Border.all(color: AppColors.divider, width: 1),
        ),
        child: _charge
            ? RawGestureDetector(
                behavior: HitTestBehavior.opaque,
                gestures: <Type, GestureRecognizerFactory>{
                  PanGestureRecognizer:
                      GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
                    () => PanGestureRecognizer(),
                    (PanGestureRecognizer instance) {
                      instance.onStart = (details) {
                        _commencerStroke(details.localPosition);
                      };
                      instance.onUpdate = (details) {
                        _etendreStroke(details.localPosition);
                      };
                      instance.onEnd = (_) {
                        _terminerStroke();
                      };
                    },
                  ),
                },
                child: CustomPaint(
                  painter: _ScratchPainter(_strokes),
                  child: Container(),
                ),
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildBarreBas() {
    return Row(
      children: [
        TextButton.icon(
          onPressed: _effacerTout,
          icon: const Icon(Icons.delete_sweep, size: 18, color: AppColors.error),
          label: const Text('Effacer tout',
              style: TextStyle(color: AppColors.error)),
        ),
        const Spacer(),
        Text(
          '${_strokes.length} trait${_strokes.length > 1 ? 's' : ''}',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _fermer,
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Fermer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

// ─── Modele de stroke (serialisable JSON) ─────────────────────

class Stroke {
  final List<Offset> points;
  final Color couleur;
  final double epaisseur;
  final bool estGomme;

  const Stroke({
    required this.points,
    required this.couleur,
    required this.epaisseur,
    this.estGomme = false,
  });

  Map<String, dynamic> toJson() => {
        'points': points
            .map((p) => {'x': p.dx, 'y': p.dy})
            .toList(),
        'r': couleur.red,
        'g': couleur.green,
        'b': couleur.blue,
        'e': epaisseur,
        'gomm': estGomme ? 1 : 0,
      };

  factory Stroke.fromJson(Map<String, dynamic> j) {
    final points = (j['points'] as List<dynamic>)
        .map((p) => Offset(
              (p as Map<String, dynamic>)['x'] as double,
              p['y'] as double,
            ))
        .toList();
    return Stroke(
      points: points,
      couleur: Color.fromARGB(
        255,
        (j['r'] as num).toInt(),
        (j['g'] as num).toInt(),
        (j['b'] as num).toInt(),
      ),
      epaisseur: (j['e'] as num).toDouble(),
      estGomme: (j['gomm'] as num).toInt() == 1,
    );
  }
}

// ─── CustomPainter pour le canvas quadrille + strokes ─────────

class _ScratchPainter extends CustomPainter {
  final List<Stroke> strokes;
  _ScratchPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    // 1) Fond blanc casse.
    final fond = Paint()..color = const Color(0xFFFDFCF7);
    canvas.drawRect(Offset.zero & size, fond);

    // 2) Quadrillage style papier (grille 24x24 px, gris tres pale).
    final grille = Paint()
      ..color = const Color(0xFFE8E4DA)
      ..strokeWidth = 0.6;
    const pas = 24.0;
    for (double x = 0; x < size.width; x += pas) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grille);
    }
    for (double y = 0; y < size.height; y += pas) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grille);
    }

    // 3) Ligne rouge marge a gauche (comme un cahier francais).
    final marge = Paint()
      ..color = const Color(0xFFE0B0B0)
      ..strokeWidth = 1.0;
    canvas.drawLine(const Offset(48, 0), Offset(48, size.height), marge);

    // 4) Strokes de l'eleve.
    for (final s in strokes) {
      if (s.points.length < 2) {
        // Point unique : on dessine un cercle.
        if (s.points.isNotEmpty) {
          canvas.drawCircle(
            s.points.first,
            s.epaisseur / 2,
            Paint()..color = s.couleur,
          );
        }
        continue;
      }
      final paint = Paint()
        ..color = s.couleur
        ..strokeWidth = s.epaisseur
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        // Pour la gomme, on dessine en blanc opaque (eface par dessus).
        ..blendMode = s.estGomme ? BlendMode.src : BlendMode.srcOver;

      final path = Path()..moveTo(s.points.first.dx, s.points.first.dy);
      for (var i = 1; i < s.points.length; i++) {
        path.lineTo(s.points[i].dx, s.points[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScratchPainter old) =>
      old.strokes != strokes;
}

enum _Outil { stylo, gomme }
