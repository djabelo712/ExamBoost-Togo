// lib/screens/community/leaderboard_tab.dart
// Onglet "Classements" du module Communauté.
//
// 3 vues switchables via SegmentedButton (Material 3) :
//   - National : top 100 élèves du Togo (mock 50 affichés)
//   - Régional : filtre par région (Lomé, Maritime, Plateaux, Centrale, Kara, Savanes)
//   - Établissement : top 50 dans mon lycée
//
// Pour chaque élève affiché :
//   - Avatar circulaire (initiales si pas de photo)
//   - Prénom + initiale nom
//   - Établissement (small text)
//   - Score cette semaine (points SRS + simulations)
//   - Streak (icône flamme + nb jours)
//   - Badge si top 3 (médailles or / argent / bronze)
//
// "Mon propre rang" : encadré en haut (sticky) avec ma position + score.
//
// Données : mock local (50 élèves togolais). Pas d'appel réseau.
// Pour la production : remplacer _generateMockEleves() par un appel
// à un service backend (ex: CommunityService.fetchLeaderboard()).

import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

// ─── Modèle de données local ────────────────────────────────────────

class _Eleve {
  final String id;
  final String prenom;
  final String nom;
  final String etablissement;
  final String region;
  final int scoreSemaine;
  final int streak;

  const _Eleve({
    required this.id,
    required this.prenom,
    required this.nom,
    required this.etablissement,
    required this.region,
    required this.scoreSemaine,
    required this.streak,
  });

  /// Initiales pour l'avatar (max 2 lettres).
  String get initiales {
    final p = prenom.isNotEmpty ? prenom[0].toUpperCase() : '';
    final n = nom.isNotEmpty ? nom[0].toUpperCase() : '';
    return n.isEmpty ? p : '$p$n';
  }

  /// Affichage "Prénom N." (initiale du nom + point).
  String get affichageCourt => '$prenom ${nom.isNotEmpty ? '${nom[0].toUpperCase()}.' : ''}';
}

// ─── Régions du Togo ────────────────────────────────────────────────

const List<String> kTogoRegions = [
  'Lomé',
  'Maritime',
  'Plateaux',
  'Centrale',
  'Kara',
  'Savanes',
];

// ─── Établissements par région (réalistes) ──────────────────────────

const Map<String, List<String>> kLyceesParRegion = {
  'Lomé': [
    'Lycée de Tokoin',
    'Lycée Beyrout',
    'Lycée d\'Adidogomé',
    'Lycée de Bè',
    'Lycée Notre Dame des Siens',
  ],
  'Maritime': [
    'Lycée de Tsévié',
    'Lycée de Vogan',
    'Lycée d\'Aného',
  ],
  'Plateaux': [
    'Lycée d\'Atakpamé',
    'Lycée de Kpalimé',
    'Lycée de Badou',
  ],
  'Centrale': [
    'Lycée de Sokodé',
    'Lycée de Sotouboua',
    'Lycée de Tchamba',
  ],
  'Kara': [
    'Lycée de Kara',
    'Lycée de Bafilo',
    'Lycée de Kandé',
  ],
  'Savanes': [
    'Lycée de Dapaong',
    'Lycée de Mango',
    'Lycée de Cinkassé',
  ],
};

// ─── Prénoms togolais (mix nord/sud, filles/garçons) ───────────────

const List<String> kPrenomsTogolais = [
  // Sud (ewe / mina / watchi)
  'Kossi', 'Komlan', 'Yao', 'Koffi', 'Komi', 'Mawunyo', 'Kossiwa',
  'Aya', 'Adjo', 'Akossiwa', 'Afia', 'Afiwa', 'Dédé', 'Essofa',
  'Senam', 'Ayayi', 'Mawuko', 'Kafui', 'Yawo', 'Kossi',
  // Nord (kabiye / tem / moba)
  'Abdou', 'Issa', 'Bouraïma', 'Ouro', 'Lomou', 'Pitaw', 'Tchaa',
  'Ouréï', 'Pété', 'Lare', 'Nabyan', 'Sambiéni', 'Dialo', 'Tchara',
];

const List<String> kNomsTogolais = [
  'Agbodjan', 'Komi', 'Adjavon', 'Lawson', 'Dupont', 'Agboka',
  'Kpanou', 'Amegble', 'Sambiani', 'Kpatcha', 'Adabra', 'Djanguenabou',
  'N\'guissan', 'Babili', 'Adjonou', 'Eyram', 'Kondoh', 'Gnammi',
  'Tchalla', 'Badjow', 'Sika', 'Afidégnon', 'Mawussi', 'Kossi',
];

// ─── Élève "moi" (mock) ────────────────────────────────────────────
// Sera remplacé en prod par l'utilisateur courant (UserProvider).

const _Eleve _moiMock = _Eleve(
  id: 'me',
  prenom: 'Moi',
  nom: '',
  etablissement: 'Lycée de Tokoin',
  region: 'Lomé',
  scoreSemaine: 920,
  streak: 5,
);

// ─── Onglet Classement ──────────────────────────────────────────────

enum _LeaderboardVue { national, regional, etablissement }

class LeaderboardTab extends StatefulWidget {
  const LeaderboardTab({super.key});

  @override
  State<LeaderboardTab> createState() => _LeaderboardTabState();

  /// Génère une liste déterministe de 50 élèves mock.
  /// (Static pour permettre à d'autres écrans de réutiliser les données
  /// si besoin — ex: badge rang sur le dashboard.)
  static List<_Eleve> generateMockEleves() => _generateMockEleves();
}

class _LeaderboardTabState extends State<LeaderboardTab> {
  late final List<_Eleve> _allEleves;

  _LeaderboardVue _vue = _LeaderboardVue.national;
  String _regionSelectionnee = 'Lomé';

  @override
  void initState() {
    super.initState();
    _allEleves = _generateMockEleves();
  }

  // ─── Filtrage selon la vue active ──────────────────────────────

  List<_Eleve> get _elevesAffiches {
    switch (_vue) {
      case _LeaderboardVue.national:
        // Top 50 national (toutes régions confondues)
        return List.of(_allEleves)
          ..sort((a, b) => b.scoreSemaine.compareTo(a.scoreSemaine));
      case _LeaderboardVue.regional:
        return _allEleves
            .where((e) => e.region == _regionSelectionnee)
            .toList()
          ..sort((a, b) => b.scoreSemaine.compareTo(a.scoreSemaine));
      case _LeaderboardVue.etablissement:
        // Top 50 dans mon établissement (mock : Lycée de Tokoin)
        final filtered = _allEleves
            .where((e) => e.etablissement == _moiMock.etablissement)
            .toList()
          ..sort((a, b) => b.scoreSemaine.compareTo(a.scoreSemaine));
        // On injecte "moi" pour figurer dans mon propre lycée
        if (!filtered.any((e) => e.id == _moiMock.id)) {
          filtered.insert(0, _moiMock);
          filtered.sort((a, b) => b.scoreSemaine.compareTo(a.scoreSemaine));
        }
        return filtered;
    }
  }

  /// Position de "moi" dans la vue active (1-indexed).
  int get _monRang {
    final liste = _elevesAffiches;
    final idx = liste.indexWhere((e) => e.id == _moiMock.id);
    if (idx >= 0) return idx + 1;
    // Si je ne suis pas dans la liste filtrée (ex: région ≠ Lomé),
    // on calcule mon rang national estimé par rapport au score.
    final monScore = _moiMock.scoreSemaine;
    final better = _allEleves.where((e) => e.scoreSemaine > monScore).length;
    return better + 1;
  }

  // ─── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final eleves = _elevesAffiches;
    final monRang = _monRang;

    return Column(
      children: [
        // ─── SegmentedButton + filtre région ────────────────────
        _buildSegmentedControl(),
        if (_vue == _LeaderboardVue.regional) _buildRegionFilter(),

        // ─── Mon rang (sticky) ──────────────────────────────────
        _buildMonRangCard(monRang),

        // ─── Liste des élèves ───────────────────────────────────
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              // Mock : on attend 800ms pour simuler un rechargement.
              await Future.delayed(const Duration(milliseconds: 800));
              if (mounted) setState(() {});
            },
            child: eleves.isEmpty
                ? _buildEmptyState('Aucun élève dans cette zone pour le moment.')
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: eleves.length,
                    itemBuilder: (context, i) {
                      final e = eleves[i];
                      final isMe = e.id == _moiMock.id;
                      return _EleveTile(
                        eleve: e,
                        rang: i + 1,
                        isMe: isMe,
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  // ─── SegmentedButton (3 vues) ─────────────────────────────────

  Widget _buildSegmentedControl() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: SegmentedButton<_LeaderboardVue>(
        segments: const [
          ButtonSegment(
            value: _LeaderboardVue.national,
            icon: Icon(Icons.public, size: 16),
            label: Text('National'),
          ),
          ButtonSegment(
            value: _LeaderboardVue.regional,
            icon: Icon(Icons.map_outlined, size: 16),
            label: Text('Régional'),
          ),
          ButtonSegment(
            value: _LeaderboardVue.etablissement,
            icon: Icon(Icons.school_outlined, size: 16),
            label: Text('Mon lycée'),
          ),
        ],
        selected: {_vue},
        onSelectionChanged: (s) => setState(() => _vue = s.first),
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primary.withOpacity(0.12);
            }
            return null;
          }),
          foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primary;
            }
            return AppColors.textSecondary;
          }),
          side: WidgetStateProperty.all(
            BorderSide(color: AppColors.divider, width: 1),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          visualDensity: VisualDensity.compact,
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  // ─── Filtre par région (chips horizontaux) ────────────────────

  Widget _buildRegionFilter() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: kTogoRegions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final r = kTogoRegions[i];
          final selected = r == _regionSelectionnee;
          return ChoiceChip(
            label: Text(r),
            selected: selected,
            onSelected: (_) => setState(() => _regionSelectionnee = r),
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            backgroundColor: AppColors.surface,
            side: BorderSide(
              color: selected ? AppColors.primary : AppColors.divider,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          );
        },
      ),
    );
  }

  // ─── Carte "Mon rang" (sticky en haut de l'onglet) ────────────

  Widget _buildMonRangCard(int rang) {
    final labelVue = switch (_vue) {
      _LeaderboardVue.national => 'au niveau national',
      _LeaderboardVue.regional => 'dans la région $_regionSelectionnee',
      _LeaderboardVue.etablissement => 'dans mon établissement',
    };

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: const Icon(Icons.person, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          // Identité + vue
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Toi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Classé $rangᵉ $labelVue',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Score + streak
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_moiMock.scoreSemaine} pts',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: AppColors.accentLight,
                    size: 14,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${_moiMock.streak} j',
                    style: const TextStyle(
                      color: AppColors.accentLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── État vide ─────────────────────────────────────────────────

  Widget _buildEmptyState(String message) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Icon(Icons.groups_outlined,
            size: 64, color: AppColors.textDisabled),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// ─── Tuile "élève" (une ligne du classement) ────────────────────────

class _EleveTile extends StatelessWidget {
  final _Eleve eleve;
  final int rang;
  final bool isMe;

  const _EleveTile({
    required this.eleve,
    required this.rang,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final isTop3 = rang <= 3;
    final medalColor = switch (rang) {
      1 => const Color(0xFFFFB300), // or
      2 => const Color(0xFF9E9E9E), // argent
      3 => const Color(0xFFB8693B), // bronze
      _ => AppColors.textSecondary,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primarySurface : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: isMe
            ? Border.all(color: AppColors.primary.withOpacity(0.5), width: 1.5)
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
          // ─── Rang / Médaille ───────────────────────────────
          SizedBox(
            width: 34,
            child: isTop3
                ? Container(
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

          // ─── Avatar ────────────────────────────────────────
          CircleAvatar(
            radius: 18,
            backgroundColor:
                isMe ? AppColors.primary : _avatarColor(eleve.id),
            child: Text(
              eleve.initiales,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // ─── Identité + établissement ─────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isMe ? 'Toi (${eleve.affichageCourt})' : eleve.affichageCourt,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isMe ? AppColors.primary : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  eleve.etablissement,
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // ─── Score + streak ────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${eleve.scoreSemaine} pts',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: eleve.streak >= 3
                        ? AppColors.accent
                        : AppColors.textSecondary,
                    size: 13,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${eleve.streak} j',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 11,
                      color: eleve.streak >= 3
                          ? AppColors.accent
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Couleur d'avatar déterministe basée sur l'id (palette soft).
  Color _avatarColor(String id) {
    const palette = [
      Color(0xFF1565C0), // bleu
      Color(0xFF6A1B9A), // violet
      Color(0xFF00838F), // teal
      Color(0xFFAD1457), // rose
      Color(0xFF2E7D32), // vert
      Color(0xFFEF6C00), // orange foncé
      Color(0xFF37474F), // bleu-gris
    ];
    final h = id.hashCode.abs();
    return palette[h % palette.length];
  }
}

// ─── Génération déterministe des 50 élèves mock ─────────────────────

List<_Eleve> _generateMockEleves() {
  // Seed fixe pour avoir des données stables entre les rebuilds.
  final rand = Random(42);
  final eleves = <_Eleve>[];

  for (int i = 0; i < 50; i++) {
    final region = kTogoRegions[rand.nextInt(kTogoRegions.length)];
    final lyceesRegion = kLyceesParRegion[region]!;
    final lycee = lyceesRegion[rand.nextInt(lyceesRegion.length)];

    eleves.add(_Eleve(
      id: 'eleve_$i',
      prenom: kPrenomsTogolais[rand.nextInt(kPrenomsTogolais.length)],
      nom: kNomsTogolais[rand.nextInt(kNomsTogolais.length)],
      etablissement: lycee,
      region: region,
      scoreSemaine: 200 + rand.nextInt(1801), // 200 à 2000 pts
      streak: rand.nextInt(15), // 0 à 14 jours
    ));
  }

  // On s'assure qu'il y a au moins quelques élèves du Lycée de Tokoin
  // (pour que la vue "Mon lycée" soit peuplée même si le hasard ne tombe pas
  // dessus).
  final countTokoin =
      eleves.where((e) => e.etablissement == _moiMock.etablissement).length;
  if (countTokoin < 8) {
    for (int i = 0; i < 8 - countTokoin; i++) {
      final e = eleves[i];
      eleves[i] = _Eleve(
        id: e.id,
        prenom: e.prenom,
        nom: e.nom,
        etablissement: _moiMock.etablissement,
        region: 'Lomé',
        scoreSemaine: e.scoreSemaine,
        streak: e.streak,
      );
    }
  }

  return eleves;
}
