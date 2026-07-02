// lib/screens/contest/models/school_ranking.dart
// Modele de donnees pour le classement d'une ecole dans le concours
// inter-ecoles mensuel.
//
// Une SchoolRanking represente l'etat d'un etablissement scolaire a un
// instant donne dans le concours en cours : points cumules par ses eleves,
// rang national, rang regional, nombre d'eleves actifs, trophees gagnes
// dans les concours precedents, et variation de rang par rapport au
// classement precedent.
//
// Les donnees sont immuables ; on utilise copyWith() pour mettre a jour
// le rang ou les points apres une action de l'eleve.

import 'contest.dart';

/// Classement d'une ecole dans le concours inter-ecoles.
class SchoolRanking {
  /// Identifiant unique (ex: "lycee-tokoin").
  final String id;

  /// Nom complet de l'etablissement (ex: "Lycee de Tokoin").
  final String nom;

  /// Region du Togo (Lome, Maritime, Plateaux, Centrale, Kara, Savanes).
  final String region;

  /// Points cumules par les eleves de l'ecole pendant le concours en cours.
  final int points;

  /// Position dans le classement national (1 = premier, >= 1).
  final int rangNational;

  /// Position dans le classement regional (1 = premier, >= 1).
  final int rangRegional;

  /// Nombre d'eleves de l'ecole ayant contribue au moins 1 point ce mois.
  final int nbElevesActifs;

  /// Contribution moyenne par eleve actif (points / nbElevesActifs).
  final int contributionMoyenne;

  /// Variation de rang national par rapport au classement de la veille
  /// (positif = a grimpe, negatif = a descendu, 0 = stable).
  final int variationRang;

  /// Trophees (or/argent/bronze) gagnes lors des concours precedents.
  /// Sert a afficher la "vitrine" de l'ecole (TrophyShowcase).
  final List<ContestTrophy> trophees;

  const SchoolRanking({
    required this.id,
    required this.nom,
    required this.region,
    required this.points,
    required this.rangNational,
    required this.rangRegional,
    required this.nbElevesActifs,
    required this.contributionMoyenne,
    this.variationRang = 0,
    this.trophees = const [],
  });

  /// Vrai si l'ecole est sur le podium national (top 3).
  bool get isPodiumNational => rangNational <= 3;

  /// Vrai si l'ecole est sur le podium regional (top 3).
  bool get isPodiumRegional => rangRegional <= 3;

  /// Nombre total de trophees d'or gagnes par l'ecole.
  int get nbOr => trophees.where((t) => t.isOr).length;

  /// Nombre total de trophees (tous tiers confondus).
  int get nbTrophees => trophees.length;

  /// Cree une copie avec des champs modifies.
  SchoolRanking copyWith({
    String? id,
    String? nom,
    String? region,
    int? points,
    int? rangNational,
    int? rangRegional,
    int? nbElevesActifs,
    int? contributionMoyenne,
    int? variationRang,
    List<ContestTrophy>? trophees,
  }) {
    return SchoolRanking(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      region: region ?? this.region,
      points: points ?? this.points,
      rangNational: rangNational ?? this.rangNational,
      rangRegional: rangRegional ?? this.rangRegional,
      nbElevesActifs: nbElevesActifs ?? this.nbElevesActifs,
      contributionMoyenne: contributionMoyenne ?? this.contributionMoyenne,
      variationRang: variationRang ?? this.variationRang,
      trophees: trophees ?? this.trophees,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SchoolRanking &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          points == other.points &&
          rangNational == other.rangNational;

  @override
  int get hashCode => Object.hash(id, points, rangNational);
}
