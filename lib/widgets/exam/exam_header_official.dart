// lib/widgets/exam/exam_header_official.dart
// En-tete officiel BEPC / BAC reproduisant le format des sujets togolais.
//
// Format reproduit :
//   REPUBLIQUE TOGOLAISE
//   Travail - Liberte - Patrie
//
//   MINISTERE DE L'ENSEIGNEMENT SUPERIEUR, DE LA RECHERCHE
//   ET DE L'INNOVATION
//                          -----
//   EXAMEN : [BEPC / BAC]     SERIE : [C]
//   SESSION : 2026
//   EPREUVE : [Mathematiques]
//   Duree : [2h / 4h]          Coef : [4 / 6]
//
// - Style sobre, texte noir sur fond blanc, police serif.
// - Filets de separation entre sections.
// - Logo Republique Togolaise placeholder (icon Icons.account_balance).
// - Peut etre masque via l'option "Mode sobre" d'AccessibilitySettings.

import 'package:flutter/material.dart';
import '../../services/accessibility_service.dart';
import '../../theme/app_theme.dart';

/// En-tete officiel pour un sujet d'examen togolais.
class ExamHeaderOfficial extends StatelessWidget {
  const ExamHeaderOfficial({
    super.key,
    required this.examen,
    this.serie,
    required this.session,
    required this.epreuve,
    required this.duree,
    required this.coefficient,
  });

  /// 'BEPC', 'BAC1', 'BAC2', 'Probatoire'
  final String examen;
  /// 'A', 'B', 'C', 'D', 'F' (null pour BEPC)
  final String? serie;
  /// Annee (ex: 2026)
  final int session;
  /// Matiere (ex: 'Mathematiques')
  final String epreuve;
  /// Duree formatee (ex: '2h', '4h')
  final String duree;
  /// Coefficient (ex: '4', '6')
  final String coefficient;

  @override
  Widget build(BuildContext context) {
    // Si le mode sobre est active, on masque completement l'en-tete officiel.
    if (AccessibilityService.soberModeEnabled) {
      return _buildHeaderSober();
    }

    final styleTitre = AccessibilityService.adjustTextStyle(
      const TextStyle(
        fontFamily: 'serif',
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Colors.black,
        letterSpacing: 0.5,
      ),
    );
    final styleNormal = AccessibilityService.adjustTextStyle(
      const TextStyle(
        fontFamily: 'serif',
        fontSize: 12,
        color: Colors.black,
        height: 1.4,
      ),
    );
    final styleDevise = AccessibilityService.adjustTextStyle(
      const TextStyle(
        fontFamily: 'serif',
        fontSize: 11,
        fontStyle: FontStyle.italic,
        color: Colors.black87,
        letterSpacing: 0.4,
      ),
    );
    final styleField = AccessibilityService.adjustTextStyle(
      const TextStyle(
        fontFamily: 'serif',
        fontSize: 12,
        color: Colors.black,
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AccessibilityService.backgroundColor(Colors.white),
        border: Border.all(color: Colors.black54, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo + Republique + Devise
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance,
                size: 22,
                color: Colors.black87,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('REPUBLIQUE TOGOLAISE', style: styleTitre),
                  Text('Travail - Liberte - Patrie', style: styleDevise),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'MINISTERE DE L\'ENSEIGNEMENT SUPERIEUR, DE LA RECHERCHE\n'
            'ET DE L\'INNOVATION',
            textAlign: TextAlign.center,
            style: styleNormal,
          ),
          const SizedBox(height: 6),
          // Filet de separation
          Container(
            width: 60,
            height: 1,
            color: Colors.black54,
          ),
          const SizedBox(height: 10),

          // Bloc Examen / Serie / Session
          _buildRowDeuxColonnes(
            gauche: _buildField('EXAMEN :', examen, styleField),
            droite: serie != null
                ? _buildField('SERIE :', serie!, styleField)
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 4),
          _buildRowDeuxColonnes(
            gauche: _buildField('SESSION :', session.toString(), styleField),
            droite: const SizedBox.shrink(),
          ),
          const SizedBox(height: 4),
          _buildRowDeuxColonnes(
            gauche: _buildField('EPREUVE :', epreuve.toUpperCase(), styleField),
            droite: const SizedBox.shrink(),
          ),
          const SizedBox(height: 4),
          _buildRowDeuxColonnes(
            gauche: _buildField('Duree :', duree, styleField),
            droite: _buildField('Coef :', coefficient, styleField),
          ),

          const SizedBox(height: 8),
          // Filet final
          Container(
            height: 1,
            color: Colors.black54,
          ),
        ],
      ),
    );
  }

  /// Version sobre : une simple ligne "Examen BEPC - Session 2026".
  Widget _buildHeaderSober() {
    final style = AccessibilityService.adjustTextStyle(
      TextStyle(
        fontFamily: 'serif',
        fontSize: 13,
        color: AppColors.textSecondary,
        fontStyle: FontStyle.italic,
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Center(
        child: Text(
          'Examen $examen${serie != null ? ' - Serie $serie' : ''} '
          '- Session $session - $epreuve',
          style: style,
        ),
      ),
    );
  }

  Widget _buildField(String label, String valeur, TextStyle base) {
    return RichText(
      text: TextSpan(
        style: base,
        children: [
          TextSpan(
            text: '$label ',
            style: base.copyWith(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: valeur),
        ],
      ),
    );
  }

  Widget _buildRowDeuxColonnes({
    required Widget gauche,
    required Widget droite,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Expanded(child: gauche),
          Expanded(child: droite),
        ],
      ),
    );
  }
}
