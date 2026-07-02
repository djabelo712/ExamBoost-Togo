// lib/screens/orientation/models/career_path.dart
// Career path (métier / carrière) associé à une filière.
//
// Chaque filière a 3-5 career paths. L'élève peut explorer les carrières
// pour comprendre concrètement ce qu'il fera après ses études.

class CareerPath {
  /// Identifiant unique stable (ex: "medecin_generaliste").
  final String id;

  /// ID de la filière parent (voir Filiere.id).
  final String filiereId;

  /// Titre affiché (ex: "Médecin généraliste").
  final String titre;

  /// Description 2-3 phrases (le quotidien du métier).
  final String description;

  /// Niveau d'entrée (ex: "Diplôme en poche", "3-5 ans d'expérience").
  final String niveauEntree;

  /// Évolution de carrière typique (texte court).
  final String evolution;

  /// Salaire mensuel début (FCFA).
  final int salaireDebut;

  /// Salaire mensuel senior (FCFA).
  final int salaireSenior;

  /// Compétences clés attendues dans ce métier.
  final List<String> competencesCles;

  /// Secteurs d'emploi (ex: ["Public", "Privé", "ONG"]).
  final List<String> secteurs;

  /// Demande sur le marché togolais (1 = faible, 5 = très forte).
  final int demandeMarche;

  /// Potentiel d'évolution à l'international (faible/moyen/fort).
  final String potentielInternational;

  /// Tendance du métier ("en croissance", "stable", "en mutation").
  final String tendance;

  const CareerPath({
    required this.id,
    required this.filiereId,
    required this.titre,
    required this.description,
    required this.niveauEntree,
    required this.evolution,
    required this.salaireDebut,
    required this.salaireSenior,
    required this.competencesCles,
    required this.secteurs,
    this.demandeMarche = 3,
    this.potentielInternational = 'moyen',
    this.tendance = 'stable',
  });

  /// Libellé salaire formaté.
  String get salaireLabel {
    final debut = _formatFcfa(salaireDebut);
    final senior = _formatFcfa(salaireSenior);
    return '$debut - $senior FCFA/mois';
  }

  /// Renvoie le libellé court du potentiel international.
  String get potentielInternationalLabel {
    switch (potentielInternational) {
      case 'fort':
        return 'Élevé';
      case 'faible':
        return 'Limité';
      default:
        return 'Moyen';
    }
  }

  /// Renvoie les étoiles (1-5) pour la demande marché (pour affichage).
  int get demandeStars => demandeMarche.clamp(1, 5);

  static String _formatFcfa(int amount) {
    final str = amount.toString();
    final buf = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write(' ');
      buf.write(str[i]);
    }
    return buf.toString();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'filiere_id': filiereId,
        'titre': titre,
        'description': description,
        'niveau_entree': niveauEntree,
        'evolution': evolution,
        'salaire_debut': salaireDebut,
        'salaire_senior': salaireSenior,
        'competences_cles': competencesCles,
        'secteurs': secteurs,
        'demande_marche': demandeMarche,
        'potentiel_international': potentielInternational,
        'tendance': tendance,
      };

  factory CareerPath.fromJson(Map<String, dynamic> json) {
    return CareerPath(
      id: json['id'] as String,
      filiereId: json['filiere_id'] as String,
      titre: json['titre'] as String,
      description: json['description'] as String,
      niveauEntree: json['niveau_entree'] as String? ?? 'Diplôme obtenu',
      evolution: json['evolution'] as String? ?? '',
      salaireDebut: json['salaire_debut'] as int,
      salaireSenior: json['salaire_senior'] as int,
      competencesCles:
          List<String>.from(json['competences_cles'] as List? ?? []),
      secteurs: List<String>.from(json['secteurs'] as List? ?? []),
      demandeMarche: json['demande_marche'] as int? ?? 3,
      potentielInternational:
          json['potentiel_international'] as String? ?? 'moyen',
      tendance: json['tendance'] as String? ?? 'stable',
    );
  }
}
