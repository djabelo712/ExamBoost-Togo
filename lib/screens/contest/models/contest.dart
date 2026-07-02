// lib/screens/contest/models/contest.dart
// Modele de donnees pour un concours inter-ecoles mensuel.
//
// Chaque concours est thematique ("Maths Mars", "Francais Avril"...) et
// oppose pendant un mois les etablissements scolaires du Togo. Les eleves
// marquent des points pour leur ecole en repondant a des questions, en
// reussissant des simulations et en debloquant des badges.
//
// Le modele est immuable (tous les champs final). Une copie modifiable
// est obtenue via copyWith().
//
// Note : ContestTrophy est defini ici (et non dans school_ranking.dart)
// car il represente le resultat d'un concours du point de vue du concours
// lui-meme. La classe SchoolRanking importe ce fichier pour exposer la
// liste des trophees gagnes par une ecole donnee.

/// Statut d'un concours dans son cycle de vie mensuel.
enum ContestStatus {
  /// Concours planifie mais pas encore demarre (avant dateDebut).
  aVenir,

  /// Concours actuellement en cours (entre dateDebut et dateFin).
  enCours,

  /// Concours termine (apres dateFin) -- resultats figes.
  termine,
}

/// Type de trophée decerne en fin de concours (top 3 ecoles).
enum TrophyTier {
  /// 1er -- medaille d'or.
  or,

  /// 2e -- medaille d'argent.
  argent,

  /// 3e -- medaille de bronze.
  bronze,
}

/// Trophée gagne par une ecole lors d'un concours passe.
class ContestTrophy {
  /// Identifiant du concours remporte.
  final String contestId;

  /// Titre humain du concours (ex: "Maths Mars 2026").
  final String contestTitre;

  /// Rang de l'ecole (1, 2 ou 3).
  final TrophyTier tier;

  /// Date de fin du concours (jour de la remise).
  final DateTime date;

  /// Points cumules par l'ecole pendant ce concours.
  final int pointsEcole;

  const ContestTrophy({
    required this.contestId,
    required this.contestTitre,
    required this.tier,
    required this.date,
    required this.pointsEcole,
  });

  /// Raccourci pour savoir si c'est une victoire (or).
  bool get isOr => tier == TrophyTier.or;
}

/// Concours mensuel inter-ecoles.
class Contest {
  /// Identifiant unique (ex: "contest-2026-03").
  final String id;

  /// Titre affiche (ex: "Maths Mars 2026").
  final String titre;

  /// Matiere principale du concours (ex: "Mathematiques").
  final String matiere;

  /// Description courte du theme et des enjeux.
  final String description;

  /// Date de debut (1er du mois a 00:00).
  final DateTime dateDebut;

  /// Date de fin (dernier jour du mois a 23:59).
  final DateTime dateFin;

  /// Statut calcule a partir des dates.
  final ContestStatus status;

  /// Objectif collectif national (ex: 50000 points cumules par toutes les
  /// ecoles participantes). Si atteint, bonus pour tous les participants.
  final int objectifCollectif;

  /// Points actuellement cumules par l'ensemble des ecoles.
  final int pointsActuels;

  /// Nombre d'ecoles inscrites/participantes.
  final int nbEcolesParticipantes;

  /// Nombre total d'eleves actifs dans le concours.
  final int nbElevesActifs;

  /// Liste des recompenses individuelles et collectives possibles.
  final List<String> recompenses;

  /// Trophées decernes (uniquement si status == termine).
  final List<ContestTrophy> trophees;

  /// Identifiant de l'ecole gagnante (uniquement si termine).
  final String? ecoleGagnanteId;

  /// Nom de l'ecole gagnante (uniquement si termine).
  final String? ecoleGagnanteNom;

  const Contest({
    required this.id,
    required this.titre,
    required this.matiere,
    required this.description,
    required this.dateDebut,
    required this.dateFin,
    required this.status,
    required this.objectifCollectif,
    required this.pointsActuels,
    required this.nbEcolesParticipantes,
    required this.nbElevesActifs,
    this.recompenses = const [],
    this.trophees = const [],
    this.ecoleGagnanteId,
    this.ecoleGagnanteNom,
  });

  /// Ratio de progression vers l'objectif collectif (0.0 - 1.0).
  double get ratioCollectif =>
      objectifCollectif == 0
          ? 0.0
          : (pointsActuels / objectifCollectif).clamp(0.0, 1.0);

  /// Nombre de jours restants avant la fin du concours (>= 0).
  int get joursRestants {
    if (status != ContestStatus.enCours) return 0;
    final delta = dateFin.difference(DateTime.now());
    return delta.isNegative ? 0 : delta.inDays + 1;
  }

  /// Nombre de jours ecoules depuis le debut (plafonne a la duree totale).
  int get joursEcoules {
    final delta = DateTime.now().difference(dateDebut);
    if (delta.isNegative) return 0;
    final total = dateFin.difference(dateDebut).inDays + 1;
    return delta.inDays.clamp(0, total);
  }

  /// Cree une copie avec des champs modifies.
  Contest copyWith({
    String? id,
    String? titre,
    String? matiere,
    String? description,
    DateTime? dateDebut,
    DateTime? dateFin,
    ContestStatus? status,
    int? objectifCollectif,
    int? pointsActuels,
    int? nbEcolesParticipantes,
    int? nbElevesActifs,
    List<String>? recompenses,
    List<ContestTrophy>? trophees,
    String? ecoleGagnanteId,
    String? ecoleGagnanteNom,
  }) {
    return Contest(
      id: id ?? this.id,
      titre: titre ?? this.titre,
      matiere: matiere ?? this.matiere,
      description: description ?? this.description,
      dateDebut: dateDebut ?? this.dateDebut,
      dateFin: dateFin ?? this.dateFin,
      status: status ?? this.status,
      objectifCollectif: objectifCollectif ?? this.objectifCollectif,
      pointsActuels: pointsActuels ?? this.pointsActuels,
      nbEcolesParticipantes: nbEcolesParticipantes ?? this.nbEcolesParticipantes,
      nbElevesActifs: nbElevesActifs ?? this.nbElevesActifs,
      recompenses: recompenses ?? this.recompenses,
      trophees: trophees ?? this.trophees,
      ecoleGagnanteId: ecoleGagnanteId ?? this.ecoleGagnanteId,
      ecoleGagnanteNom: ecoleGagnanteNom ?? this.ecoleGagnanteNom,
    );
  }

  /// Egalite structurelle (utile pour les tests et les diffs d'etat).
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Contest &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          pointsActuels == other.pointsActuels &&
          status == other.status;

  @override
  int get hashCode => Object.hash(id, pointsActuels, status);
}
