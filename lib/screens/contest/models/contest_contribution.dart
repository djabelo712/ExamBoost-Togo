// lib/screens/contest/models/contest_contribution.dart
// Modele de donnees pour la contribution d'un eleve a son ecole dans le
// concours inter-ecoles mensuel.
//
// Chaque action pertinente de l'eleve (reponse correcte, simulation
// reussie, badge debloque, streak 7 jours) genere une ContestContribution
// qui est creditee a la fois au total de l'eleve et au total de son ecole.
//
// MyContributionSummary agrege les contributions de l'eleve pour le
// concours en cours : total de points, rang dans l'ecole, repartition par
// type, et liste des contributions recentes (pour l'affichage detaille).

import 'contest.dart';

/// Type d'action qui genere des points pour l'ecole.
enum ContributionType {
  /// Reponse correcte a une question de revision (+10 pts).
  question,

  /// Simulation d'examen reussie (note > 10/20, +50 pts).
  simulation,

  /// Badge debloque (+100 pts).
  badge,

  /// Streak de 7 jours consolutifs atteint (+200 pts bonus).
  streakBonus,
}

/// Extension : metadonnees d'affichage pour chaque type de contribution.
extension ContributionTypeMeta on ContributionType {
  /// Nombre de points credites pour ce type de contribution.
  int get points {
    switch (this) {
      case ContributionType.question:
        return 10;
      case ContributionType.simulation:
        return 50;
      case ContributionType.badge:
        return 100;
      case ContributionType.streakBonus:
        return 200;
    }
  }

  /// Libelle humain court affiche dans la liste des contributions.
  String get libelle {
    switch (this) {
      case ContributionType.question:
        return 'Question correcte';
      case ContributionType.simulation:
        return 'Simulation reussie';
      case ContributionType.badge:
        return 'Badge debloque';
      case ContributionType.streakBonus:
        return 'Bonus streak 7 jours';
    }
  }

  /// Libelle long pour les descriptions detaillees.
  String get libelleLong {
    switch (this) {
      case ContributionType.question:
        return 'Reponse correcte en revision';
      case ContributionType.simulation:
        return 'Simulation d\'examen reussie (>10/20)';
      case ContributionType.badge:
        return 'Badge decale debloque';
      case ContributionType.streakBonus:
        return 'Bonus streak 7 jours consecutifs';
    }
  }
}

/// Une contribution individuelle de l'eleve au concours en cours.
class ContestContribution {
  /// Identifiant unique.
  final String id;

  /// Date et heure de la contribution.
  final DateTime date;

  /// Type d'action (question, simulation, badge, streak).
  final ContributionType type;

  /// Nombre de points credites (en general = type.points, mais peut
  /// differer en cas de bonus exceptionnel).
  final int points;

  /// Description libre (ex: "Question : Theoreme de Thales - niveau 3").
  final String description;

  /// Matiere concerne (peut etre null pour les bonus streak).
  final String? matiere;

  const ContestContribution({
    required this.id,
    required this.date,
    required this.type,
    required this.points,
    required this.description,
    this.matiere,
  });

  /// Vrai si la contribution est recente (moins de 24h).
  bool get isRecente =>
      DateTime.now().difference(date).inHours < 24;
}

/// Synthese de la contribution de l'eleve pour le concours en cours.
class MyContributionSummary {
  /// Identifiant de l'eleve.
  final String eleveId;

  /// Nom de l'eleve (pour affichage).
  final String eleveNom;

  /// Nom de l'ecole a laquelle l'eleve contribue.
  final String ecoleNom;

  /// Identifiant de l'ecole.
  final String ecoleId;

  /// Identifiant du concours en cours.
  final String contestId;

  /// Total de points apportes par l'eleve a son ecole ce mois.
  final int pointsTotaux;

  /// Rang de l'eleve parmi les contributeurs de son ecole (1 = 1er).
  final int rangDansEcole;

  /// Nombre total d'eleves contributeurs dans l'ecole.
  final int nbContributeursEcole;

  /// Nombre de questions correctes repondues ce mois.
  final int nbQuestions;

  /// Nombre de simulations reussies ce mois.
  final int nbSimulations;

  /// Nombre de badges debloques ce mois.
  final int nbBadges;

  /// Nombre de bonus streak 7j obtenus ce mois.
  final int nbBonusStreak;

  /// Liste des contributions recentes (max 20, triees par date desc).
  final List<ContestContribution> recentes;

  const MyContributionSummary({
    required this.eleveId,
    required this.eleveNom,
    required this.ecoleNom,
    required this.ecoleId,
    required this.contestId,
    required this.pointsTotaux,
    required this.rangDansEcole,
    required this.nbContributeursEcole,
    required this.nbQuestions,
    required this.nbSimulations,
    required this.nbBadges,
    required this.nbBonusStreak,
    this.recentes = const [],
  });

  /// Points venant uniquement des questions (nb * 10).
  int get pointsQuestions => nbQuestions * ContributionType.question.points;

  /// Points venant uniquement des simulations (nb * 50).
  int get pointsSimulations =>
      nbSimulations * ContributionType.simulation.points;

  /// Points venant uniquement des badges (nb * 100).
  int get pointsBadges => nbBadges * ContributionType.badge.points;

  /// Points venant uniquement des bonus streak (nb * 200).
  int get pointsStreak =>
      nbBonusStreak * ContributionType.streakBonus.points;

  /// Pourcentage de la contribution de l'eleve dans le total de l'ecole
  /// (estimation basee sur le rang et le nombre de contributeurs).
  double get partRelativeContribution {
    if (nbContributeursEcole == 0) return 0.0;
    // Heuristique : le 1er contribue environ 8% du total, decroissance
    // lineaire jusqu'a ~1% pour le dernier. Pour la v1 mock, on retourne
    // une estimation simple basee sur le rang.
    return (1.0 / rangDansEcole).clamp(0.01, 0.20);
  }

  /// Vrai si l'eleve est dans le top 3 des contributeurs de son ecole.
  bool get isTopContributeur => rangDansEcole <= 3;

  /// Cree une copie avec des champs modifies.
  MyContributionSummary copyWith({
    String? eleveId,
    String? eleveNom,
    String? ecoleNom,
    String? ecoleId,
    String? contestId,
    int? pointsTotaux,
    int? rangDansEcole,
    int? nbContributeursEcole,
    int? nbQuestions,
    int? nbSimulations,
    int? nbBadges,
    int? nbBonusStreak,
    List<ContestContribution>? recentes,
  }) {
    return MyContributionSummary(
      eleveId: eleveId ?? this.eleveId,
      eleveNom: eleveNom ?? this.eleveNom,
      ecoleNom: ecoleNom ?? this.ecoleNom,
      ecoleId: ecoleId ?? this.ecoleId,
      contestId: contestId ?? this.contestId,
      pointsTotaux: pointsTotaux ?? this.pointsTotaux,
      rangDansEcole: rangDansEcole ?? this.rangDansEcole,
      nbContributeursEcole: nbContributeursEcole ?? this.nbContributeursEcole,
      nbQuestions: nbQuestions ?? this.nbQuestions,
      nbSimulations: nbSimulations ?? this.nbSimulations,
      nbBadges: nbBadges ?? this.nbBadges,
      nbBonusStreak: nbBonusStreak ?? this.nbBonusStreak,
      recentes: recentes ?? this.recentes,
    );
  }
}
