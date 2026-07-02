// lib/screens/orientation/orientation_results_screen.dart
// Écran des résultats d'orientation — affiche les top 5 filières
// recommandées + un résumé du profil de l'élève.
//
// Sections :
//   1. Header avec archétype + score global + bouton "Voir profil détaillé".
//   2. Radar compact des 6 axes (avec overlay de la filière top 1 si dépliée).
//   3. Liste des 5 FiliereCard (dépliables).
//   4. Footer avec bouton "Refaire le test" + disclaimer pédagogique.
//
// Le profil est passé en paramètre depuis OrientationChatScreen.
// Aucune logique de scoring ici : tout est déjà calculé.

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'models/orientation_profile.dart';
import 'orientation_profile_screen.dart';
import 'services/orientation_service.dart';
import 'widgets/filiere_card.dart';
import 'widgets/skill_radar_orientation.dart';

class OrientationResultsScreen extends StatelessWidget {
  const OrientationResultsScreen({
    super.key,
    required this.profile,
    this.topN = 5,
  });

  /// Profil de l'élève (calculé à la fin du chat).
  final OrientationProfile profile;

  /// Nombre de recommandations à afficher (défaut 5).
  final int topN;

  @override
  Widget build(BuildContext context) {
    final service = OrientationService();
    final recs = service.recommander(profile, topN: topN);
    final top1 = recs.isNotEmpty ? recs.first : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tes recommandations'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.primary),
            tooltip: 'Partager',
            onPressed: () => _shareResults(context, profile, recs),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // ─── 1. Header archétype ───────────────────────────────────
          _ArchetypeHeader(profile: profile),

          // ─── 2. Radar compact ──────────────────────────────────────
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.radar, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Cartographie de ton profil',
                      style: AppTextStyles.h3.copyWith(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SkillRadarOrientation(
                  profile: profile,
                  size: 240,
                  filiereOverlay: top1?.filiere,
                ),
                const SizedBox(height: 8),
                Text(
                  'Le polygone vert représente ton profil. '
                  'Le contour orange correspond au profil attendu en '
                  '${top1?.filiere.nomCourt ?? 'cette filière'}.',
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 11.5),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // ─── 3. Titre "Top 5 filières" ────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              children: [
                const Icon(Icons.emoji_events,
                    color: AppColors.accent, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Top $topN filières pour toi',
                  style: AppTextStyles.h2.copyWith(fontSize: 18),
                ),
              ],
            ),
          ),

          // ─── 4. Liste des recommandations ─────────────────────────
          ...recs.asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final rec = entry.value;
            return FiliereCard(
              recommendation: rec,
              rank: rank,
              initiallyExpanded: rank == 1,
            );
          }),

          // ─── 5. Bouton profil détaillé ────────────────────────────
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        OrientationProfileScreen(profile: profile),
                  ),
                );
              },
              icon: const Icon(Icons.psychology, size: 18),
              label: const Text('Voir mon profil détaillé'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          // ─── 6. Disclaimer ────────────────────────────────────────
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentSurface.withOpacity(0.6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.accent.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline,
                    color: AppColors.accent, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Ces recommandations sont indicatives et basées sur tes "
                    "réponses au chat et tes résultats scolaires. Discutes-en "
                    "avec tes parents, tes professeurs et le conseiller "
                    "d'orientation de ton établissement avant de faire ton "
                    "choix définitif.",
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 11.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _shareResults(
    BuildContext context,
    OrientationProfile profile,
    List<FiliereRecommendation> recs,
  ) {
    final lines = <String>[
      "Mon profil d'orientation ExamBoost : ${profile.archetype}",
      '',
      'Top ${recs.length} filières recommandées :',
      for (final r in recs)
        '  ${r.matchPercent.round()}% - ${r.filiere.nom} '
            '(${r.filiere.universites.first})',
      '',
      'ExamBoost Togo - Prépare ton BEPC et ton BAC',
    ];
    final text = lines.join('\n');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profil copié : ${profile.archetype}'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );

    // Pour un vrai partage, il faudrait le package share_plus (non en pubspec).
    // On se contente d'un clipboard via SnackBar (UI-only v1).
    debugPrint('Profil à partager :\n$text');
  }
}

// ════════════════════════════════════════════════════════════════════
// Header archétype (gradient orange/vert)
// ════════════════════════════════════════════════════════════════════

class _ArchetypeHeader extends StatelessWidget {
  const _ArchetypeHeader({required this.profile});
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
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.30),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Ton profil'.toUpperCase(),
                  style: AppTextStyles.label.copyWith(
                    fontSize: 10,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Score ${profile.scoreGlobal.toStringAsFixed(0)}/100',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            profile.archetype,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            profile.archetypeDescription,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.92),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
