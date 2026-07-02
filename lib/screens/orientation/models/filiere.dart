// lib/screens/orientation/models/filiere.dart
// Filière togolaise — étude supérieure après BEPC ou BAC.
//
// Chaque filière est associée à :
//   - un vecteur de poids sur les 6 axes (somme = 1.0 idéalement)
//     utilisé pour calculer le % de match avec le profil élève
//   - une liste de matières "pivots" (matières clés attendues) qui
//     font intervenir le P(L) réel de l'élève
//   - les universités togolaises / CEDEAO qui la proposent
//   - la durée et le diplôme délivré
//   - le salaire moyen en début et fin de carrière (FCFA/mois, marché Togo)
//   - les IDs des career paths associées (résolues via OrientationService)
//
// Le vecteur de poids et les matières pivots sont calibrés manuellement
// à partir des programmes officiels de l'Université de Lomé et des
// grandes écoles togolaises (EUT, EPB, ESAE, ESA, IFG, ENI).

import 'orientation_profile.dart';

class Filiere {
  /// Identifiant unique stable (ex: "medecine", "ingenierie").
  final String id;

  /// Nom affiché (ex: "Médecine").
  final String nom;

  /// Nom court pour les listes compactes (ex: "Médecine").
  final String nomCourt;

  /// Description 2-3 phrases.
  final String description;

  /// Icône Material (code point) pour la carte.
  final IconData icon;

  /// Poids par axe (somme = 1.0). Voir OrientationAxes.all.
  final Map<String, double> poidsAxes;

  /// Matières pivots (clés utilisées dans AppUser.bktMaitrise agrégé).
  /// Ex: ["Mathématiques", "Sciences Physiques", "SVT"].
  final List<String> matieresPivots;

  /// Universités togolaises qui proposent cette filière.
  final List<String> universites;

  /// Universités de la sous-région CEDEAO (optionnel).
  final List<String> universitesCedeao;

  /// Durée des études (ex: "7 ans", "5 ans").
  final String duree;

  /// Diplôme délivré (ex: "Doctorat en médecine", "Ingénieur de conception").
  final String diplome;

  /// Salaire mensuel moyen en début de carrière (FCFA).
  final int salaireDebut;

  /// Salaire mensuel moyen en fin de carrière (FCFA).
  final int salaireSenior;

  /// Niveau d'accès : "BAC" ou "BEPC" (orientations post-BEPC = CAP/BEP).
  final String niveauAcces;

  /// Séries BAC recommandées (ex: ["C", "D"] pour médecine).
  final List<String> seriesRecommandees;

  /// Compétences clés attendues (texte libre, pour la carte).
  final List<String> competencesCles;

  /// Débouchés principaux (texte court, pour la carte).
  final List<String> debouches;

  /// IDs des career paths associées (voir CareerPath.filiereId).
  final List<String> careerPathIds;

  /// Booléen : filière sélective / concours d'entrée.
  final bool selective;

  /// Indice de difficulté d'admission (1 = accessible, 5 = très sélectif).
  final int difficulteAdmission;

  const Filiere({
    required this.id,
    required this.nom,
    required this.nomCourt,
    required this.description,
    required this.icon,
    required this.poidsAxes,
    required this.matieresPivots,
    required this.universites,
    this.universitesCedeao = const [],
    required this.duree,
    required this.diplome,
    required this.salaireDebut,
    required this.salaireSenior,
    required this.niveauAcces,
    this.seriesRecommandees = const [],
    required this.competencesCles,
    required this.debouches,
    required this.careerPathIds,
    this.selective = false,
    this.difficulteAdmission = 3,
  });

  /// Vecteur ordonné des poids (aligné sur OrientationAxes.all).
  List<double> get poidsVector =>
      OrientationAxes.all.map((a) => poidsAxes[a] ?? 0.0).toList();

  /// Vrai si l'axe donné est un axe fort de cette filière (poids >= 0.20).
  bool isAxeFort(String axe) => (poidsAxes[axe] ?? 0.0) >= 0.20;

  /// Renvoie le libellé du salaire formaté (ex: "150 000 - 800 000 FCFA").
  String get salaireLabel {
    final debut = _formatFcfa(salaireDebut);
    final senior = _formatFcfa(salaireSenior);
    return '$debut - $senior FCFA/mois';
  }

  /// Renvoie un libellé court du salaire de début (pour chips).
  String get salaireDebutCourt => '${_formatK(salaireDebut)} FCFA/mois';

  static String _formatFcfa(int amount) {
    // Formate avec séparateur de milliers (espace insécable).
    final str = amount.toString();
    final buf = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write(' ');
      buf.write(str[i]);
    }
    return buf.toString();
  }

  static String _formatK(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).round()}k';
    }
    return amount.toString();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'nom_court': nomCourt,
        'description': description,
        'icon_code_point': icon.codePoint,
        'poids_axes': poidsAxes,
        'matieres_pivots': matieresPivots,
        'universites': universites,
        'universites_cedeao': universitesCedeao,
        'duree': duree,
        'diplome': diplome,
        'salaire_debut': salaireDebut,
        'salaire_senior': salaireSenior,
        'niveau_acces': niveauAcces,
        'series_recommandees': seriesRecommandees,
        'competences_cles': competencesCles,
        'debouches': debouches,
        'career_path_ids': careerPathIds,
        'selective': selective,
        'difficulte_admission': difficulteAdmission,
      };

  factory Filiere.fromJson(Map<String, dynamic> json) {
    return Filiere(
      id: json['id'] as String,
      nom: json['nom'] as String,
      nomCourt: json['nom_court'] as String? ?? json['nom'] as String,
      description: json['description'] as String,
      icon: IconData(json['icon_code_point'] as int,
          fontFamily: 'MaterialIcons'),
      poidsAxes: Map<String, double>.from(json['poids_axes'] as Map? ?? {}),
      matieresPivots: List<String>.from(json['matieres_pivots'] as List? ?? []),
      universites: List<String>.from(json['universites'] as List? ?? []),
      universitesCedeao:
          List<String>.from(json['universites_cedeao'] as List? ?? []),
      duree: json['duree'] as String,
      diplome: json['diplome'] as String,
      salaireDebut: json['salaire_debut'] as int,
      salaireSenior: json['salaire_senior'] as int,
      niveauAcces: json['niveau_acces'] as String? ?? 'BAC',
      seriesRecommandees:
          List<String>.from(json['series_recommandees'] as List? ?? []),
      competencesCles:
          List<String>.from(json['competences_cles'] as List? ?? []),
      debouches: List<String>.from(json['debouches'] as List? ?? []),
      careerPathIds: List<String>.from(json['career_path_ids'] as List? ?? []),
      selective: json['selective'] as bool? ?? false,
      difficulteAdmission: json['difficulte_admission'] as int? ?? 3,
    );
  }
}
