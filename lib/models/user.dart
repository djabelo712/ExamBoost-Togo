// lib/models/user.dart
// Profil élève avec suivi BKT par compétence

import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 3)
class AppUser extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String nom;

  @HiveField(2)
  String prenom;

  @HiveField(3)
  String? email;

  @HiveField(4)
  String niveauScolaire; // "3eme", "2nde", "1ere", "Terminale"

  @HiveField(5)
  String? serie; // "A", "C", "D", "B", "F" — null pour BEPC

  @HiveField(6)
  String? etablissement;

  @HiveField(7)
  String? ville;

  @HiveField(8)
  final DateTime dateInscription;

  @HiveField(9)
  Map<String, double> bktMaitrise; // competenceId -> P(L) entre 0 et 1

  @HiveField(10)
  int totalSessionsCount;

  @HiveField(11)
  int totalQuestionsAnswered;

  @HiveField(12)
  double? thetaIrt; // Niveau IRT global estimé

  @HiveField(13)
  DateTime? lastActiveDate;

  AppUser({
    required this.id,
    required this.nom,
    required this.prenom,
    this.email,
    required this.niveauScolaire,
    this.serie,
    this.etablissement,
    this.ville,
    required this.dateInscription,
    Map<String, double>? bktMaitrise,
    this.totalSessionsCount = 0,
    this.totalQuestionsAnswered = 0,
    this.thetaIrt,
    this.lastActiveDate,
  }) : bktMaitrise = bktMaitrise ?? {};

  String get nomComplet => '$prenom $nom';

  /// Niveau de maîtrise pour une compétence donnée
  double getMaitrise(String competenceId) =>
      bktMaitrise[competenceId] ?? 0.0;

  /// Met à jour P(L) pour une compétence selon l'algorithme BKT
  /// [correct] : true si réponse correcte
  void updateBkt({
    required String competenceId,
    required bool correct,
    // Paramètres BKT (valeurs par défaut si non calibrés)
    double pLearn = 0.20,   // P(T) : probabilité d'apprendre
    double pSlip = 0.10,    // P(S) : probabilité d'erreur malgré maîtrise
    double pGuess = 0.20,   // P(G) : probabilité de deviner
  }) {
    final pL = bktMaitrise[competenceId] ?? 0.10;

    double pLGivenObs;

    if (correct) {
      // ─── Réponse correcte ─────────────────────────────────────
      final pCorrect = pL * (1 - pSlip) + (1 - pL) * pGuess;
      pLGivenObs = (pL * (1 - pSlip)) / pCorrect;
    } else {
      // ─── Réponse incorrecte ───────────────────────────────────
      final pIncorrect = pL * pSlip + (1 - pL) * (1 - pGuess);
      pLGivenObs = (pL * pSlip) / pIncorrect;
    }

    // ─── Transition vers la prochaine opportunité ─────────────
    final pLNext = pLGivenObs + (1 - pLGivenObs) * pLearn;

    // Contraindre entre 0 et 1
    bktMaitrise[competenceId] = pLNext.clamp(0.0, 1.0);
    save();
  }

  /// Liste des compétences maîtrisées (P(L) >= 0.85)
  List<String> get competencesMaitrisees => bktMaitrise.entries
      .where((e) => e.value >= 0.85)
      .map((e) => e.key)
      .toList();

  /// Score global de maîtrise (0-100)
  double get scoreGlobal {
    if (bktMaitrise.isEmpty) return 0;
    final total = bktMaitrise.values.fold(0.0, (a, b) => a + b);
    return (total / bktMaitrise.length * 100).clamp(0, 100);
  }
}
