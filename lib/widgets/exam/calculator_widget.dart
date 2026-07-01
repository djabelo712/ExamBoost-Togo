// lib/widgets/exam/calculator_widget.dart
// Calculatrice scientifique integree pour le mode examen authentique.
//
// - Affichage LCD (texte monospace, fond noir, chiffres verts).
// - Boutons standards : 0-9, +, -, x, /, =, C, +/-, %, racine, x^2, 1/x, pi, (, )
// - Boutons scientifiques : sin, cos, tan, log, ln, e^x, x^y, factorielle
// - Memoire : M+, M-, MR, MC
// - Historique scrollable des derniers calculs
// - Clavier physique supporte (LogicalKeyboardKey)
// - PAS d'eval() : parser maison securise (shunting-yard + evaluation RPN)
//   qui n'accepte que les operateurs et fonctions reconnus.
//
// OUVERTURE : utiliser CalculatorWidget.show(context) depuis un bouton AppBar.
// Retourne le dernier resultat calcule (ou null) si l'utilisateur veut le
// reinjecter dans sa reponse.

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_logger.dart';

/// Boite de dialogue plein ecran contenant la calculatrice scientifique.
/// Ouverte via [CalculatorWidget.show] depuis un bouton AppBar.
class CalculatorWidget extends StatefulWidget {
  const CalculatorWidget({super.key});

  /// Ouvre la calculatrice en bas d'ecran (BottomSheet large).
  /// Retourne le dernier resultat calcule si l'utilisateur appuie sur
  /// "Inserer dans ma reponse" (sinon null).
  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const CalculatorWidget(),
    );
  }

  @override
  State<CalculatorWidget> createState() => _CalculatorWidgetState();
}

class _CalculatorWidgetState extends State<CalculatorWidget> {
  // ─── Etat de la calculatrice ──────────────────────────────────
  String _expression = '';
  String _resultat = '0';
  String _erreur = '';
  double _memoire = 0;
  bool _modeScientifique = false;

  // Historique des derniers calculs (limit a 50 entrees).
  final List<_HistoriqueEntree> _historique = [];

  // Focus pour le clavier physique.
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  // ─── Actions boutons ──────────────────────────────────────────

  void _ajouter(String token) {
    setState(() {
      _erreur = '';
      _expression += token;
    });
  }

  void _effacerTout() {
    setState(() {
      _expression = '';
      _resultat = '0';
      _erreur = '';
    });
  }

  void _effacerDernier() {
    setState(() {
      if (_expression.isEmpty) return;
      _expression = _expression.substring(0, _expression.length - 1);
      _erreur = '';
    });
  }

  void _calculer() {
    if (_expression.trim().isEmpty) return;
    try {
      final parser = _MathParser();
      final valeur = parser.evaluer(_expression);
      // Formattage : si entier, pas de decimal ; sinon 8 decimales max.
      String formate;
      if (valeur.isNaN) {
        setState(() => _erreur = 'Valeur non definie (NaN)');
        return;
      } else if (valeur.isInfinite) {
        setState(() => _erreur = 'Division par zero');
        return;
      } else if (valeur == valeur.roundToDouble()) {
        formate = valeur.roundToDouble().toStringAsFixed(0);
      } else {
        // 10 decimales, on supprime les zeros de fin.
        formate = valeur.toStringAsFixed(10).replaceAll(RegExp(r'0+$'), '');
        if (formate.endsWith('.')) formate += '0';
      }
      setState(() {
        _resultat = formate;
        _historique.insert(0, _HistoriqueEntree(_expression, formate));
        if (_historique.length > 50) _historique.removeLast();
        _expression = '';
        _erreur = '';
      });
    } on _MathErreur catch (e) {
      setState(() => _erreur = e.message);
    } catch (e) {
      AppLogger.error('Calculator erreur: $e');
      setState(() => _erreur = 'Expression invalide');
    }
  }

  void _memoireAdd() {
    final v = double.tryParse(_resultat) ?? 0;
    setState(() => _memoire += v);
  }

  void _memoireSub() {
    final v = double.tryParse(_resultat) ?? 0;
    setState(() => _memoire -= v);
  }

  void _memoireRecall() {
    _ajouter(_formatNombre(_memoire));
  }

  void _memoireClear() {
    setState(() => _memoire = 0);
  }

  String _formatNombre(double v) {
    if (v == v.roundToDouble()) return v.roundToDouble().toString();
    return v.toString();
  }

  void _insererDansReponse() {
    Navigator.of(context).pop(_resultat);
  }

  // ─── Clavier physique ─────────────────────────────────────────

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;

    // Chiffres
    if (key >= LogicalKeyboardKey.digit0 &&
        key <= LogicalKeyboardKey.digit9) {
      final chiffre = key.keyId - LogicalKeyboardKey.digit0.keyId;
      _ajouter(chiffre.toString());
      return KeyEventResult.handled;
    }
    // Numpad
    if (key >= LogicalKeyboardKey.numpad0 &&
        key <= LogicalKeyboardKey.numpad9) {
      final chiffre = key.keyId - LogicalKeyboardKey.numpad0.keyId;
      _ajouter(chiffre.toString());
      return KeyEventResult.handled;
    }

    // Operateurs
    if (key == LogicalKeyboardKey.add || key == LogicalKeyboardKey.numpadAdd) {
      _ajouter('+');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.minus ||
        key == LogicalKeyboardKey.numpadSubtract) {
      _ajouter('-');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.asterisk ||
        key == LogicalKeyboardKey.numpadMultiply) {
      _ajouter('*');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.slash ||
        key == LogicalKeyboardKey.numpadDivide) {
      _ajouter('/');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.period ||
        key == LogicalKeyboardKey.numpadDecimal) {
      _ajouter('.');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      _calculer();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.backspace) {
      _effacerDernier();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      _effacerTout();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyP) {
      _ajouter('pi');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyE) {
      _ajouter('e');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.parenthesisLeft) {
      _ajouter('(');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.parenthesisRight) {
      _ajouter(')');
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // ─── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Focus(
        focusNode: _focusNode,
        onKeyEvent: _onKeyEvent,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildEnTete(),
              const SizedBox(height: 8),
              _buildLcd(),
              const SizedBox(height: 6),
              if (_erreur.isNotEmpty) _buildErreur(),
              if (_erreur.isNotEmpty) const SizedBox(height: 6),
              _buildMemoireBar(),
              const SizedBox(height: 8),
              Flexible(
                child: _modeScientifique
                    ? _buildPaveScientifique()
                    : _buildPaveStandard(),
              ),
              const SizedBox(height: 8),
              _buildBasActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnTete() {
    return Row(
      children: [
        Icon(Icons.calculate, color: AppColors.primary, size: 22),
        const SizedBox(width: 8),
        Text('Calculatrice', style: AppTextStyles.h3),
        const Spacer(),
        IconButton(
          tooltip: _modeScientifique
              ? 'Mode standard'
              : 'Mode scientifique',
          icon: Icon(
            _modeScientifique
                ? Icons.calculate_outlined
                : Icons.science_outlined,
            color: AppColors.primary,
          ),
          onPressed: () => setState(
            () => _modeScientifique = !_modeScientifique,
          ),
        ),
        IconButton(
          tooltip: 'Fermer',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildLcd() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Expression en cours (petite, jaune)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Text(
              _expression.isEmpty ? ' ' : _expression,
              style: TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: 16,
                color: const Color(0xFFFFD54F),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 4),
          // Resultat (grand, vert)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Text(
              _resultat,
              style: TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF66BB6A),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErreur() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _erreur,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
      ),
    );
  }

  Widget _buildMemoireBar() {
    return Row(
      children: [
        Text(
          'M: ${_formatNombre(_memoire)}',
          style: AppTextStyles.bodySmall.copyWith(
            fontFamily: 'RobotoMono',
            color: _memoire != 0 ? AppColors.accent : AppColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        _memoBtn('MC', _memoireClear),
        const SizedBox(width: 4),
        _memoBtn('MR', _memoireRecall),
        const SizedBox(width: 4),
        _memoBtn('M-', _memoireSub),
        const SizedBox(width: 4),
        _memoBtn('M+', _memoireAdd),
      ],
    );
  }

  Widget _memoBtn(String label, VoidCallback onTap) {
    return SizedBox(
      width: 44,
      height: 32,
      child: Material(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.label.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Pave standard (5 colonnes) ──────────────────────────────

  Widget _buildPaveStandard() {
    final boutons = <List<_CalcBtn>>[
      [
        _CalcBtn('C', _effacerTout, _BtnType.effacer),
        _CalcBtn('(', () => _ajouter('('), _BtnType.parenthese),
        _CalcBtn(')', () => _ajouter(')'), _BtnType.parenthese),
        _CalcBtn('<', _effacerDernier, _BtnType.effacer),
        _CalcBtn('%', () => _ajouter('%'), _BtnType.operateur),
      ],
      [
        _CalcBtn('7', () => _ajouter('7'), _BtnType.chiffre),
        _CalcBtn('8', () => _ajouter('8'), _BtnType.chiffre),
        _CalcBtn('9', () => _ajouter('9'), _BtnType.chiffre),
        _CalcBtn('/', () => _ajouter('/'), _BtnType.operateur),
        _CalcBtn('sqrt', () => _ajouter('sqrt('), _BtnType.fonction),
      ],
      [
        _CalcBtn('4', () => _ajouter('4'), _BtnType.chiffre),
        _CalcBtn('5', () => _ajouter('5'), _BtnType.chiffre),
        _CalcBtn('6', () => _ajouter('6'), _BtnType.chiffre),
        _CalcBtn('*', () => _ajouter('*'), _BtnType.operateur),
        _CalcBtn('^', () => _ajouter('^'), _BtnType.operateur),
      ],
      [
        _CalcBtn('1', () => _ajouter('1'), _BtnType.chiffre),
        _CalcBtn('2', () => _ajouter('2'), _BtnType.chiffre),
        _CalcBtn('3', () => _ajouter('3'), _BtnType.chiffre),
        _CalcBtn('-', () => _ajouter('-'), _BtnType.operateur),
        _CalcBtn('1/x', () => _ajouter('1/('), _BtnType.fonction),
      ],
      [
        _CalcBtn('+/-', _basculeSigne, _BtnType.fonction),
        _CalcBtn('0', () => _ajouter('0'), _BtnType.chiffre),
        _CalcBtn('.', () => _ajouter('.'), _BtnType.chiffre),
        _CalcBtn('+', () => _ajouter('+'), _BtnType.operateur),
        _CalcBtn('=', _calculer, _BtnType.egal),
      ],
    ];
    return Column(
      children: boutons
          .map((ligne) => Expanded(
                child: Row(
                  children: ligne
                      .map((b) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: _buildBouton(b),
                            ),
                          ))
                      .toList(),
                ),
              ))
          .toList(),
    );
  }

  // ─── Pave scientifique (sections repliables) ─────────────────

  Widget _buildPaveScientifique() {
    final scientifique = <List<_CalcBtn>>[
      [
        _CalcBtn('sin', () => _ajouter('sin('), _BtnType.fonction),
        _CalcBtn('cos', () => _ajouter('cos('), _BtnType.fonction),
        _CalcBtn('tan', () => _ajouter('tan('), _BtnType.fonction),
        _CalcBtn('pi', () => _ajouter('pi'), _BtnType.constante),
        _CalcBtn('e', () => _ajouter('e'), _BtnType.constante),
      ],
      [
        _CalcBtn('log', () => _ajouter('log('), _BtnType.fonction),
        _CalcBtn('ln', () => _ajouter('ln('), _BtnType.fonction),
        _CalcBtn('e^x', () => _ajouter('e^('), _BtnType.fonction),
        _CalcBtn('x^2', () => _ajouter('^2'), _BtnType.fonction),
        _CalcBtn('!', () => _ajouter('!'), _BtnType.operateur),
      ],
    ];
    final standard = <List<_CalcBtn>>[
      [
        _CalcBtn('C', _effacerTout, _BtnType.effacer),
        _CalcBtn('(', () => _ajouter('('), _BtnType.parenthese),
        _CalcBtn(')', () => _ajouter(')'), _BtnType.parenthese),
        _CalcBtn('<', _effacerDernier, _BtnType.effacer),
        _CalcBtn('%', () => _ajouter('%'), _BtnType.operateur),
      ],
      [
        _CalcBtn('7', () => _ajouter('7'), _BtnType.chiffre),
        _CalcBtn('8', () => _ajouter('8'), _BtnType.chiffre),
        _CalcBtn('9', () => _ajouter('9'), _BtnType.chiffre),
        _CalcBtn('/', () => _ajouter('/'), _BtnType.operateur),
        _CalcBtn('sqrt', () => _ajouter('sqrt('), _BtnType.fonction),
      ],
      [
        _CalcBtn('4', () => _ajouter('4'), _BtnType.chiffre),
        _CalcBtn('5', () => _ajouter('5'), _BtnType.chiffre),
        _CalcBtn('6', () => _ajouter('6'), _BtnType.chiffre),
        _CalcBtn('*', () => _ajouter('*'), _BtnType.operateur),
        _CalcBtn('^', () => _ajouter('^'), _BtnType.operateur),
      ],
      [
        _CalcBtn('1', () => _ajouter('1'), _BtnType.chiffre),
        _CalcBtn('2', () => _ajouter('2'), _BtnType.chiffre),
        _CalcBtn('3', () => _ajouter('3'), _BtnType.chiffre),
        _CalcBtn('-', () => _ajouter('-'), _BtnType.operateur),
        _CalcBtn('1/x', () => _ajouter('1/('), _BtnType.fonction),
      ],
      [
        _CalcBtn('+/-', _basculeSigne, _BtnType.fonction),
        _CalcBtn('0', () => _ajouter('0'), _BtnType.chiffre),
        _CalcBtn('.', () => _ajouter('.'), _BtnType.chiffre),
        _CalcBtn('+', () => _ajouter('+'), _BtnType.operateur),
        _CalcBtn('=', _calculer, _BtnType.egal),
      ],
    ];

    return Column(
      children: [
        // Section scientifique (en haut, plus petite)
        ...scientifique.map((ligne) => SizedBox(
              height: 44,
              child: Row(
                children: ligne
                    .map((b) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: _buildBouton(b),
                          ),
                        ))
                    .toList(),
              ),
            )),
        const SizedBox(height: 4),
        // Section standard (prend le reste)
        Expanded(
          child: Column(
            children: standard
                .map((ligne) => Expanded(
                      child: Row(
                        children: ligne
                            .map((b) => Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(3),
                                    child: _buildBouton(b),
                                  ),
                                ))
                            .toList(),
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  void _basculeSigne() {
    if (_expression.isEmpty) return;
    setState(() {
      // Si l'expression commence par '-', on le supprime ; sinon on l'ajoute.
      if (_expression.startsWith('-')) {
        _expression = _expression.substring(1);
      } else {
        _expression = '-$_expression';
      }
    });
  }

  Widget _buildBouton(_CalcBtn b) {
    Color bg;
    Color fg;
    switch (b.type) {
      case _BtnType.chiffre:
        bg = const Color(0xFFECEFF1);
        fg = AppColors.textPrimary;
        break;
      case _BtnType.operateur:
        bg = AppColors.accent;
        fg = Colors.white;
        break;
      case _BtnType.fonction:
        bg = AppColors.info;
        fg = Colors.white;
        break;
      case _BtnType.constante:
        bg = const Color(0xFFB39DDB);
        fg = Colors.white;
        break;
      case _BtnType.parenthese:
        bg = const Color(0xFFE0E0E0);
        fg = AppColors.textPrimary;
        break;
      case _BtnType.effacer:
        bg = AppColors.error;
        fg = Colors.white;
        break;
      case _BtnType.egal:
        bg = AppColors.primary;
        fg = Colors.white;
        break;
    }
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: b.onTap,
        child: Center(
          child: Text(
            b.label,
            style: TextStyle(
              fontSize: b.label.length > 3 ? 14 : 18,
              fontWeight: FontWeight.bold,
              color: fg,
              fontFamily: 'RobotoMono',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasActions() {
    return Row(
      children: [
        Expanded(
          child: TextButton.icon(
            onPressed: _historique.isEmpty
                ? null
                : () => _showHistorique(),
            icon: const Icon(Icons.history, size: 18),
            label: const Text('Historique'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _insererDansReponse,
            icon: const Icon(Icons.input, size: 18),
            label: const Text('Inserer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ],
    );
  }

  void _showHistorique() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text('Historique', style: AppTextStyles.h3),
                  const Spacer(),
                  if (_historique.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() => _historique.clear());
                        Navigator.pop(ctx);
                      },
                      child: const Text('Vider'),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            SizedBox(
              height: 280,
              child: _historique.isEmpty
                  ? const Center(child: Text('Aucun calcul dans l\'historique'))
                  : ListView.builder(
                      itemCount: _historique.length,
                      itemBuilder: (c, i) {
                        final h = _historique[i];
                        return ListTile(
                          dense: true,
                          title: Text(
                            h.expression,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontFamily: 'RobotoMono',
                            ),
                          ),
                          subtitle: Text(
                            '= ${h.resultat}',
                            style: TextStyle(
                              fontFamily: 'RobotoMono',
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(ctx);
                            _ajouter(h.resultat);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Types internes ───────────────────────────────────────────

enum _BtnType { chiffre, operateur, fonction, constante, parenthese, effacer, egal }

class _CalcBtn {
  final String label;
  final VoidCallback onTap;
  final _BtnType type;
  const _CalcBtn(this.label, this.onTap, this.type);
}

class _HistoriqueEntree {
  final String expression;
  final String resultat;
  const _HistoriqueEntree(this.expression, this.resultat);
}

// ─── Parser mathematique securise (shunting-yard + RPN) ────────
//
// Aucune dependance externe (pas de package math_expressions). Le parser
// implemente l'algorithme shunting-yard de Dijkstra pour convertir
// l'expression infixee en notation polonaise inverse (RPN), puis evalue
// la RPN. Les uniques operateurs/fonctions reconnus sont listes ci-dessous.
// Toute entree non reconnue leve une _MathErreur.

class _MathErreur implements Exception {
  final String message;
  _MathErreur(this.message);
  @override
  String toString() => message;
}

class _MathParser {
  // Operateurs binaires avec precedence et associative.
  static const Map<String, _Op> _operateurs = {
    '+': _Op(2, true),
    '-': _Op(2, true),
    '*': _Op(3, true),
    '/': _Op(3, true),
    '%': _Op(3, true),
    '^': _Op(4, false), // associatif a droite
  };

  // Fonctions a 1 argument.
  static const Set<String> _fonctions = {
    'sin', 'cos', 'tan', 'log', 'ln', 'sqrt', 'asin', 'acos', 'atan',
  };

  // Fonctions a 2 arguments.
  static const Set<String> _fonctions2 = {'log_'};

  late String _src;
  int _pos = 0;

  double evaluer(String expression) {
    _src = expression.replaceAll(' ', '');
    _pos = 0;
    final rpn = _shuntingYard();
    return _evaluerRpn(rpn);
  }

  // ─── Tokenisation + shunting-yard ────────────────────────────

  List<_Token> _shuntingYard() {
    final sortie = <_Token>[];
    final pile = <_Token>[];
    _Token? dernier;

    while (_pos < _src.length) {
      final c = _src[_pos];
      if (c == ' ') {
        _pos++;
        continue;
      }

      // Nombre
      if (_estChiffre(c) || c == '.') {
        final nombre = _lireNombre();
        sortie.add(_Token.nombre(nombre));
        dernier = sortie.last;
        continue;
      }

      // Identifiant (fonction ou constante)
      if (_estLettre(c)) {
        final ident = _lireIdent();
        if (ident == 'pi') {
          sortie.add(_Token.nombre(math.pi));
        } else if (ident == 'e') {
          sortie.add(_Token.nombre(math.e));
        } else if (_fonctions.contains(ident) || _fonctions2.contains(ident)) {
          pile.add(_Token.fonction(ident));
        } else {
          throw _MathErreur('Symbole inconnu : "$ident"');
        }
        dernier = sortie.isNotEmpty ? sortie.last : (pile.isNotEmpty ? pile.last : null);
        continue;
      }

      // Operateur unaire : si '-' ou '+' en debut d'expression ou apres un
      // operateur / parenthese ouvrante, c'est un signe.
      if (c == '-' || c == '+') {
        final estUnaire = dernier == null ||
            dernier.type == _TokenType.operateur ||
            dernier.type == _TokenType.parentheseOuvrante ||
            dernier.type == _TokenType.fonction;
        if (estUnaire) {
          // On insere un 0 devant pour simuler l'operateur unaire.
          sortie.add(_Token.nombre(0));
        }
      }

      // Operateur binaire
      if (_operateurs.containsKey(c)) {
        final op1 = _operateurs[c]!;
        while (pile.isNotEmpty) {
          final top = pile.last;
          if (top.type == _TokenType.fonction) {
            sortie.add(pile.removeLast());
          } else if (top.type == _TokenType.operateur) {
            final op2 = _operateurs[top.valeur]!;
            if ((op1.gaucheVersDroite && op1.precedence <= op2.precedence) ||
                (!op1.gaucheVersDroite && op1.precedence < op2.precedence)) {
              sortie.add(pile.removeLast());
            } else {
              break;
            }
          } else {
            break;
          }
        }
        pile.add(_Token.operateur(c));
        _pos++;
        dernier = pile.last;
        continue;
      }

      // Parenthese ouvrante
      if (c == '(') {
        pile.add(_Token.parentheseOuvrante());
        _pos++;
        dernier = pile.last;
        continue;
      }

      // Parenthese fermante
      if (c == ')') {
        bool trouve = false;
        while (pile.isNotEmpty) {
          final top = pile.removeLast();
          if (top.type == _TokenType.parentheseOuvrante) {
            trouve = true;
            break;
          }
          sortie.add(top);
        }
        if (!trouve) {
          throw _MathErreur('Parenthese fermante sans ouvrante');
        }
        // Si une fonction est au-dessus de la parenthese, on la depile aussi.
        if (pile.isNotEmpty && pile.last.type == _TokenType.fonction) {
          sortie.add(pile.removeLast());
        }
        // Factorielle : si le caractere suivant est '!'
        if (_pos + 1 < _src.length && _src[_pos + 1] == '!') {
          sortie.add(_Token.fonction('!'));
          _pos++;
        }
        _pos++;
        dernier = sortie.isNotEmpty ? sortie.last : null;
        continue;
      }

      // Factorielle postfixee
      if (c == '!') {
        sortie.add(_Token.fonction('!'));
        _pos++;
        dernier = sortie.last;
        continue;
      }

      throw _MathErreur('Caractere non reconnu : "$c"');
    }

    while (pile.isNotEmpty) {
      final top = pile.removeLast();
      if (top.type == _TokenType.parentheseOuvrante) {
        throw _MathErreur('Parenthese ouvrante sans fermante');
      }
      sortie.add(top);
    }

    return sortie;
  }

  // ─── Evaluation RPN ──────────────────────────────────────────

  double _evaluerRpn(List<_Token> rpn) {
    final pile = <double>[];
    for (final t in rpn) {
      switch (t.type) {
        case _TokenType.nombre:
          pile.add(t.valeurNumerique);
          break;
        case _TokenType.operateur:
          if (pile.length < 2) {
            throw _MathErreur('Operateur "${t.valeur}" sans operandes');
          }
          final b = pile.removeLast();
          final a = pile.removeLast();
          pile.add(_appliquerOperateur(t.valeur, a, b));
          break;
        case _TokenType.fonction:
          if (t.valeur == '!') {
            if (pile.isEmpty) throw _MathErreur('Factorielle sans operande');
            final x = pile.removeLast();
            pile.add(_factorielle(x));
          } else {
            if (pile.isEmpty) throw _MathErreur('Fonction "${t.valeur}" sans argument');
            final x = pile.removeLast();
            pile.add(_appliquerFonction(t.valeur, x));
          }
          break;
        case _TokenType.parentheseOuvrante:
          throw _MathErreur('Erreur interne : parenthese dans la RPN');
      }
    }
    if (pile.length != 1) {
      throw _MathErreur('Expression incomplete');
    }
    return pile.single;
  }

  double _appliquerOperateur(String op, double a, double b) {
    switch (op) {
      case '+':
        return a + b;
      case '-':
        return a - b;
      case '*':
        return a * b;
      case '/':
        if (b == 0) return double.infinity;
        return a / b;
      case '%':
        return a % b;
      case '^':
        return math.pow(a, b).toDouble();
      default:
        throw _MathErreur('Operateur inconnu : $op');
    }
  }

  double _appliquerFonction(String f, double x) {
    switch (f) {
      case 'sin':
        return math.sin(x);
      case 'cos':
        return math.cos(x);
      case 'tan':
        return math.tan(x);
      case 'asin':
        return math.asin(x);
      case 'acos':
        return math.acos(x);
      case 'atan':
        return math.atan(x);
      case 'log':
        return math.log(x) / math.ln10;
      case 'ln':
        return math.log(x);
      case 'sqrt':
        if (x < 0) return double.nan;
        return math.sqrt(x);
      default:
        throw _MathErreur('Fonction inconnue : $f');
    }
  }

  double _factorielle(double x) {
    if (x < 0 || x != x.roundToDouble()) {
      throw _MathErreur('Factorielle definie seulement pour les entiers positifs');
    }
    var n = x.round();
    var r = 1.0;
    for (var i = 2; i <= n; i++) {
      r *= i;
    }
    return r;
  }

  // ─── Helpers de lecture ──────────────────────────────────────

  bool _estChiffre(String c) =>
      c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;

  bool _estLettre(String c) {
    final code = c.codeUnitAt(0);
    return (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
  }

  double _lireNombre() {
    final debut = _pos;
    var aVirgule = false;
    while (_pos < _src.length) {
      final c = _src[_pos];
      if (_estChiffre(c)) {
        _pos++;
      } else if (c == '.' && !aVirgule) {
        aVirgule = true;
        _pos++;
      } else {
        break;
      }
    }
    final str = _src.substring(debut, _pos);
    final v = double.tryParse(str);
    if (v == null) throw _MathErreur('Nombre invalide : $str');
    return v;
  }

  String _lireIdent() {
    final debut = _pos;
    while (_pos < _src.length && _estLettre(_src[_pos])) {
      _pos++;
    }
    // Cas special : on accepte aussi '_' pour les identifiants composes.
    while (_pos < _src.length && (_estLettre(_src[_pos]) || _src[_pos] == '_')) {
      _pos++;
    }
    return _src.substring(debut, _pos);
  }
}

// ─── Tokens du parser ─────────────────────────────────────────

enum _TokenType { nombre, operateur, fonction, parentheseOuvrante }

class _Token {
  final _TokenType type;
  final String valeur;
  final double valeurNumerique;

  const _Token._(this.type, this.valeur, this.valeurNumerique);

  factory _Token.nombre(double v) => _Token._(_TokenType.nombre, '', v);
  factory _Token.operateur(String s) => _Token._(_TokenType.operateur, s, 0);
  factory _Token.fonction(String s) => _Token._(_TokenType.fonction, s, 0);
  factory _Token.parentheseOuvrante() =>
      _Token._(_TokenType.parentheseOuvrante, '(', 0);
}

class _Op {
  final int precedence;
  final bool gaucheVersDroite;
  const _Op(this.precedence, this.gaucheVersDroite);
}
