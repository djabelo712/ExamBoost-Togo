// lib/screens/contest/widgets/school_ranking_card.dart
// Carte affichant une ecole classee dans le concours inter-ecoles.
//
// Affiche :
//   - Rang (medaille si top 3, sinon numero) avec couleur contextuelle.
//   - Avatar circulaire avec initiales de l'ecole (2-3 lettres).
//   - Nom de l'ecole + region (en sous-titre).
//   - Points cumules + nombre d'eleves actifs.
//   - Variation de rang (fleche montee/descente/stable).
//   - Nombre de trophees (or/argent/bronze) si l'ecole en a.
//
// La carte est mise en evidence si isMySchool = true (fond vert clair +
// bordure verte), pour identifier "mon etablissement" dans la liste.

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../models/school_ranking.dart';
import '../models/contest.dart';

class SchoolRankingCard extends StatelessWidget {
  final SchoolRanking ecole;
  final bool isMySchool;
  final int? rangForce; // surcharge du rang affiche (ex: rang regional)
  final VoidCallback? onTap;

  const SchoolRankingCard({
    super.key,
    required this.ecole,
    this.isMySchool = false,
    this.rangForce,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rang = rangForce ?? ecole.rangNational;
    final isTop3 = rang <= 3;
    final medalColor = _medalColor(rang);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isMySchool ? AppColors.primarySurface : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border:
                isMySchool
                    ? Border.all(
                      color: AppColors.primary.withOpacity(0.5),
                      width: 1.5,
                    )
                    : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // ─── Rang / Medaille ──────────────────────────────
              SizedBox(
                width: 36,
                child:
                    isTop3
                        ? Center(
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: medalColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.emoji_events,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        )
                        : Text(
                          '$rang',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.h3.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
              ),
              const SizedBox(width: 8),

              // ─── Avatar ecole ─────────────────────────────────
              CircleAvatar(
                radius: 18,
                backgroundColor:
                    isMySchool
                        ? AppColors.primary
                        : _avatarColor(ecole.id),
                child: Text(
                  _initiales(ecole.nom),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // ─── Nom + region ─────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isMySchool ? '${ecole.nom} (mon ecole)' : ecole.nom,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color:
                            isMySchool
                                ? AppColors.primary
                                : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.place_outlined,
                          size: 11,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          ecole.region,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.group_outlined,
                          size: 11,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${ecole.nbElevesActifs} eleves',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ─── Variation de rang ────────────────────────────
              if (ecole.variationRang != 0) ...[
                _VariationBadge(variation: ecole.variationRang),
                const SizedBox(width: 6),
              ],

              // ─── Points + trophees ────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${ecole.points} pts',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      fontSize: 14,
                    ),
                  ),
                  if (ecole.nbTrophees > 0) ...[
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.emoji_events_outlined,
                          size: 12,
                          color: _medalColor(1),
                        ),
                        Text(
                          ' ${ecole.nbOr}',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _medalColor(1),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.emoji_events_outlined,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        Text(
                          ' ${ecole.nbTrophees}',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Couleur de medaille selon le rang (or/argent/bronze).
  static Color _medalColor(int rang) {
    switch (rang) {
      case 1:
        return const Color(0xFFFFB300); // or
      case 2:
        return const Color(0xFF9E9E9E); // argent
      case 3:
        return const Color(0xFFB8693B); // bronze
      default:
        return AppColors.textSecondary;
    }
  }

  /// Initiales d'une ecole (3 lettres max, espaces ignores).
  /// Ex: "Lycee de Tokoin" -> "LT", "Lycée Notre Dame des Siens" -> "LN".
  static String _initiales(String nom) {
    final mots = nom
        .replaceAll('Lycée', '')
        .replaceAll('Lycée ', '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((m) => m.isNotEmpty && !['de', 'des', 'du', 'd\''].contains(m.toLowerCase()))
        .take(2)
        .toList();
    if (mots.isEmpty) {
      // Fallback : 2 premieres lettres du nom complet.
      return nom.replaceAll(' ', '').substring(0, 2).toUpperCase();
    }
    return mots.map((m) => m[0].toUpperCase()).join();
  }

  /// Couleur d'avatar deterministe (palette soft) basee sur l'id.
  static Color _avatarColor(String id) {
    const palette = [
      Color(0xFF1565C0), // bleu
      Color(0xFF6A1B9A), // violet
      Color(0xFF00838F), // teal
      Color(0xFFAD1457), // rose
      Color(0xFF2E7D32), // vert
      Color(0xFFEF6C00), // orange fonce
      Color(0xFF37474F), // bleu-gris
      Color(0xFF5D4037), // brun
    ];
    final h = id.hashCode.abs();
    return palette[h % palette.length];
  }
}

// ─── Badge de variation de rang (fleche + nombre) ────────────────────

class _VariationBadge extends StatelessWidget {
  final int variation; // positif = monte, negatif = descend

  const _VariationBadge({required this.variation});

  @override
  Widget build(BuildContext context) {
    final isUp = variation > 0;
    final isDown = variation < 0;
    final color =
        isUp
            ? AppColors.success
            : isDown
            ? AppColors.error
            : AppColors.textSecondary;
    final icon =
        isUp
            ? Icons.arrow_upward
            : isDown
            ? Icons.arrow_downward
            : Icons.remove;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            '${variation.abs()}',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
