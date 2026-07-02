// lib/screens/orientation/orientation_profile_screen.dart
// Écran du profil d'orientation détaillé — décomposition visuelle
// des forces de l'élève.
//
// Sections :
//   1. Header compact (archétype + score global + date).
//   2. Radar grand format (300px) des 6 axes.
//   3. Liste détaillée des 6 axes avec barres de progression, libellé et
//      description de l'axe.
//   4. Top 3 matières maîtrisées (avec P(L) %).
//   5. Footer : rappel niveau scolaire + série + nombre de questions
//      répondues.

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'models/orientation_profile.dart';
import 'widgets/skill_radar_orientation.dart';

class OrientationProfileScreen extends StatelessWidget {
  const OrientationProfileScreen({super.key, required this.profile});

  final OrientationProfile profile;

  @override
  Widget build(BuildContext context) {
    // Tri des axes par score décroissant (pour le listing)
    final sortedAxes = profile.axes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mon profil'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // ─── 1. Header compact ─────────────────────────────────────
          _ProfileHeader(profile: profile),

          // ─── 2. Radar grand format ─────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.radar, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Cartographie des 6 axes',
                      style: AppTextStyles.h3.copyWith(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SkillRadarOrientation(profile: profile, size: 300),
              ],
            ),
          ),

          // ─── 3. Liste détaillée des axes ───────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text(
              'Tes forces en détail',
              style: AppTextStyles.h2.copyWith(fontSize: 18),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: sortedAxes
                  .map((e) => _AxisDetailRow(
                        axe: e.key,
                        value: e.value,
                      ))
                  .toList(),
            ),
          ),

          // ─── 4. Top 3 matières ─────────────────────────────────────
          if (profile.matiereMaitrise.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(
                'Tes matières les plus maîtrisées',
                style: AppTextStyles.h2.copyWith(fontSize: 18),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: profile.topMatieres
                    .asMap()
                    .entries
                    .map((entry) => _MaitriseCard(
                          rank: entry.key + 1,
                          matiere: entry.value.key,
                          maitrise: entry.value.value,
                        ))
                    .toList(),
              ),
            ),
          ],

          // ─── 5. Footer contexte élève ──────────────────────────────
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_outline,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Contexte élève',
                      style: AppTextStyles.h3.copyWith(
                        fontSize: 13,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _ContextLine(
                    label: 'Niveau scolaire', value: profile.niveauScolaire),
                if (profile.serie != null)
                  _ContextLine(
                      label: 'Série BAC', value: profile.serie!),
                _ContextLine(
                  label: 'Profil généré le',
                  value: _formatDate(profile.genereLe),
                ),
                _ContextLine(
                  label: 'Axes évalués',
                  value: '${profile.axes.length}/6',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final j = d.day.toString().padLeft(2, '0');
    final m = d.month.toString().padLeft(2, '0');
    return '$j/$m/${d.year}';
  }
}

// ════════════════════════════════════════════════════════════════════
// Sous-composants
// ════════════════════════════════════════════════════════════════════

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});
  final OrientationProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primarySurface, AppColors.accentSurface],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.psychology, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ton archétype',
                  style: AppTextStyles.label.copyWith(
                    fontSize: 11,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.archetype,
                  style: AppTextStyles.h2.copyWith(fontSize: 19),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.star, size: 14, color: AppColors.accent),
                    const SizedBox(width: 4),
                    Text(
                      'Score global : ${profile.scoreGlobal.toStringAsFixed(0)}/100',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AxisDetailRow extends StatelessWidget {
  const _AxisDetailRow({required this.axe, required this.value});

  final String axe;
  final double value; // 0..1

  @override
  Widget build(BuildContext context) {
    final percent = (value * 100).round();
    final color = _colorFor(value);
    final isDominant = value >= 0.65;
    final label = OrientationAxes.labels[axe] ?? axe;
    final desc = OrientationAxes.descriptions[axe] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDominant
              ? color.withOpacity(0.4)
              : AppColors.divider,
          width: isDominant ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.h3.copyWith(
                    fontSize: 14,
                    color: isDominant ? color : AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.surfaceVariant,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: AppTextStyles.bodySmall.copyWith(fontSize: 11.5),
          ),
        ],
      ),
    );
  }

  Color _colorFor(double v) {
    if (v >= 0.75) return AppColors.success;
    if (v >= 0.50) return AppColors.primary;
    if (v >= 0.30) return AppColors.accent;
    return AppColors.textSecondary;
  }
}

class _MaitriseCard extends StatelessWidget {
  const _MaitriseCard({
    required this.rank,
    required this.matiere,
    required this.maitrise,
  });

  final int rank;
  final String matiere;
  final double maitrise; // 0..1

  @override
  Widget build(BuildContext context) {
    final percent = (maitrise * 100).round();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$rank',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              matiere,
              style: AppTextStyles.h3.copyWith(fontSize: 14),
            ),
          ),
          Text(
            '$percent%',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextLine extends StatelessWidget {
  const _ContextLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
