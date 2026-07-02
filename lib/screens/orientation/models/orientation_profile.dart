// lib/screens/orientation/models/orientation_profile.dart
// Profil d'orientation de l'élève — utilisé par le chatbot conseiller.
//
// Le profil est construit à partir de 2 sources :
//   1. Les scores P(L) par matière (issus de BKT dans AppUser.bktMaitrise)
//      agrégés en maîtrise moyenne par matière (ex: "Mathématiques" -> 0.72).
//   2. Les réponses au chat d'orientation (12 questions) traduites en scores
//      sur 6 axes de compétences.
//
// Les 6 axes (constants ci-dessous) sont les dimensions sur lesquelles on
// projette à la fois le profil élève et chaque filière : la similarité
// cosinus entre ces 2 vecteurs donne le % de match.
//
// Archétypes générés à partir de l'axe dominant + combinatoire simple.

import 'filiere.dart';

/// Les 6 axes de compétences utilisés pour le matching filières.
/// L'ordre est important : c'est l'ordre utilisé dans les vecteurs.
class OrientationAxes {
  static const String scientifique = 'scientifique';
  static const String litteraire = 'litteraire';
  static const String creatif = 'creatif';
  static const String social = 'social';
  static const String business = 'business';
  static const String leadership = 'leadership';

  /// Liste ordonnée (servant à la sérialisation vectorielle).
  static const List<String> all = [
    scientifique,
    litteraire,
    creatif,
    social,
    business,
    leadership,
  ];

  /// Libellés FR courts pour l'affichage radar.
  static const Map<String, String> labels = {
    scientifique: 'Scientifique',
    litteraire: 'Littéraire',
    creatif: 'Créatif',
    social: 'Social',
    business: 'Business',
    leadership: 'Leadership',
  };

  /// Courte description de chaque axe (pour l'écran profil).
  static const Map<String, String> descriptions = {
    scientifique: 'Logique, calcul, raisonnement abstrait',
    litteraire: 'Lecture, écriture, langues, argumentation',
    creatif: 'Imagination, design, innovation, sens artistique',
    social: 'Empathie, contact humain, envie d\'aider',
    business: 'Gestion, argent, négociation, esprit entrepreneurial',
    leadership: 'Organisation, décision, encadrement d\'équipes',
  };
}

class OrientationProfile {
  /// Scores par axe (0.0 - 1.0).
  final Map<String, double> axes;

  /// Maîtrise moyenne par matière (matiere -> P(L) moyen, 0.0 - 1.0).
  /// Source : agrégation de AppUser.bktMaitrise par matière.
  final Map<String, double> matiereMaitrise;

  /// Archétype calculé (ex: "Scientifique pur").
  final String archetype;

  /// Description courte de l'archétype.
  final String archetypeDescription;

  /// Niveau scolaire de l'élève ("3eme", "Terminale", etc.).
  final String niveauScolaire;

  /// Série du BAC si applicable ("C", "D", "A"...).
  final String? serie;

  /// Date à laquelle le profil a été généré.
  final DateTime genereLe;

  OrientationProfile({
    required this.axes,
    required this.matiereMaitrise,
    required this.archetype,
    required this.archetypeDescription,
    required this.niveauScolaire,
    this.serie,
    required this.genereLe,
  });

  /// Crée un profil vide (scores à 0) — utilisé avant le chat.
  factory OrientationProfile.empty({
    String niveauScolaire = 'Terminale',
    String? serie,
  }) {
    return OrientationProfile(
      axes: {for (final a in OrientationAxes.all) a: 0.0},
      matiereMaitrise: const {},
      archetype: 'Profil à déterminer',
      archetypeDescription:
          'Réponds aux questions du chat pour révéler ton profil.',
      niveauScolaire: niveauScolaire,
      serie: serie,
      genereLe: DateTime.now(),
    );
  }

  /// Vecteur ordonné des scores d'axes (utilisé pour le scoring).
  List<double> get axesVector =>
      OrientationAxes.all.map((a) => axes[a] ?? 0.0).toList();

  /// Axe dominant (celui avec le score le plus élevé).
  /// Retourne null si tous les scores sont à 0.
  String? get axeDominant {
    String? best;
    double bestVal = 0.0;
    axes.forEach((axe, val) {
      if (val > bestVal) {
        bestVal = val;
        best = axe;
      }
    });
    return best;
  }

  /// Score global du profil (moyenne des 6 axes, 0-100).
  double get scoreGlobal {
    if (axes.isEmpty) return 0.0;
    final total = axes.values.fold(0.0, (a, b) => a + b);
    return (total / axes.length * 100).clamp(0, 100);
  }

  /// Top 3 matières les plus maîtrisées (>= 0.50).
  List<MapEntry<String, double>> get topMatieres {
    final entries = matiereMaitrise.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(3).toList();
  }

  Map<String, dynamic> toJson() => {
        'axes': axes,
        'matiere_maitrise': matiereMaitrise,
        'archetype': archetype,
        'archetype_description': archetypeDescription,
        'niveau_scolaire': niveauScolaire,
        'serie': serie,
        'genere_le': genereLe.toIso8601String(),
      };

  factory OrientationProfile.fromJson(Map<String, dynamic> json) {
    return OrientationProfile(
      axes: Map<String, double>.from(json['axes'] as Map? ?? {}),
      matiereMaitrise:
          Map<String, double>.from(json['matiere_maitrise'] as Map? ?? {}),
      archetype: json['archetype'] as String? ?? 'Profil à déterminer',
      archetypeDescription: json['archetype_description'] as String? ?? '',
      niveauScolaire: json['niveau_scolaire'] as String? ?? 'Terminale',
      serie: json['serie'] as String?,
      genereLe: json['genere_le'] != null
          ? DateTime.parse(json['genere_le'] as String)
          : DateTime.now(),
    );
  }

  @override
  String toString() =>
      'OrientationProfile(archetype=$archetype, scoreGlobal=${scoreGlobal.toStringAsFixed(1)})';
}

/// Détermine l'archétype à partir des scores d'axes.
/// Logique simple basée sur l'axe dominant + combinaison avec un second axe
/// significatif (> 60% du dominant).
class ArchetypeResolver {
  /// Retourne (nom, description) de l'archétype.
  static ({String nom, String description}) resolve(
      Map<String, double> axes) {
    // ─── Cas spécial : profil vide ─────────────────────────────────────
    final total = axes.values.fold(0.0, (a, b) => a + b);
    if (total < 0.01) {
      return (
        nom: 'Profil à déterminer',
        description:
            'Réponds aux questions du chat pour révéler ton profil '
            'et obtenir des recommandations personnalisées.',
      );
    }

    // ─── Trier les axes par score décroissant ──────────────────────────
    final sorted = axes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final dominant = sorted[0].key;
    final dominantVal = sorted[0].value;
    final second = sorted.length > 1 ? sorted[1].key : null;
    final secondVal = sorted.length > 1 ? sorted[1].value : 0.0;

    final isPolyvalent = second != null && secondVal >= dominantVal * 0.60;

    // ─── Cartographie archétypes (dominant seul) ──────────────────────
    const soloArchetypes = <String, (String, String)>{
      OrientationAxes.scientifique: (
        'Scientifique pur',
        'Tu excelles dans le raisonnement logique et abstrait. '
            'Les chiffres, les formules et les démonstrations te parlent. '
            'Tu es fait pour les carrières techniques et médicales.'
      ),
      OrientationAxes.litteraire: (
        'Littéraire affirmé',
        'Tu as un don pour les mots, l\'argumentation et l\'analyse de texte. '
            'Les langues et la communication sont ton terrain de jeu.'
      ),
      OrientationAxes.creatif: (
        'Créatif visionary',
        'Tu imagines des solutions nouvelles et tu as un sens esthétique '
            'développé. Tu t\'épanouis dans le design, l\'art et l\'innovation.'
      ),
      OrientationAxes.social: (
        'Humaniste engagé',
        'Tu as besoin de sens et de contact humain. Aider, soigner, '
            'accompagner les autres est au cœur de ta motivation.'
      ),
      OrientationAxes.business: (
        'Entrepreneur dans l\'âme',
        'Tu as le sens des affaires, de la négociation et de la gestion. '
            'Tu vises l\'indépendance financière et le pilotage de projets.'
      ),
      OrientationAxes.leadership: (
        'Leader naturel',
        'Tu sais organiser, décider et fédérer. Tu es à l\'aise avec '
            'la responsabilité et l\'encadrement d\'équipes.'
      ),
    };

    // ─── Cartographie combinaisons (dominant + second) ────────────────
    final comboKey = '${dominant}_$second';
    const comboArchetypes = <String, (String, String)>{
      // Scientifique combos
      '${OrientationAxes.scientifique}_${OrientationAxes.social}': (
        'Scientifique soignant',
        'Tu combines rigueur scientifique et envie d\'aider. '
            'Les carrières médicales et paramédicales sont ta voie.'
      ),
      '${OrientationAxes.scientifique}_${OrientationAxes.creatif}': (
        'Ingénieur créatif',
        'Tu allies logique et imagination. Tu brilleras en architecture, '
            'design industriel ou R&D.'
      ),
      '${OrientationAxes.scientifique}_${OrientationAxes.leadership}': (
        'Ingénieur manager',
        'Scientifique avec fibre managériale. Tu peux devenir chef de projet '
            'technique ou directeur technique.'
      ),
      '${OrientationAxes.scientifique}_${OrientationAxes.business}': (
        'Tech entrepreneur',
        'Science + business : tu peux monter une startup tech ou '
            'faire du conseil stratégique.'
      ),
      // Littéraire combos
      '${OrientationAxes.litteraire}_${OrientationAxes.social}': (
        'Humaniste lettré',
        'Mots + empathie : enseignement, journalisme social, '
            'travail communautaire.'
      ),
      '${OrientationAxes.litteraire}_${OrientationAxes.leadership}': (
        'Littéraire leader',
        'Plaidoyer, politique, diplomatie, barreau : '
            'tu sais convaincre et diriger.'
      ),
      '${OrientationAxes.litteraire}_${OrientationAxes.business}': (
        'Communicant stratège',
        'Marketing, relations publiques, journalisme d\'affaire : '
            'les mots au service de l\'impact.'
      ),
      // Créatif combos
      '${OrientationAxes.creatif}_${OrientationAxes.business}': (
        'Créatif entrepreneur',
        'Design + business : branding, agence créative, '
            'production audiovisuelle.'
      ),
      '${OrientationAxes.creatif}_${OrientationAxes.scientifique}': (
        'Designer technique',
        'Architecture, design industriel, UX design : '
            'esthétique au service de la fonction.'
      ),
      // Social combos
      '${OrientationAxes.social}_${OrientationAxes.leadership}': (
        'Animateur de communauté',
        'Tu peux diriger des ONG, des services sociaux, '
            'être chef d\'établissement.'
      ),
      '${OrientationAxes.social}_${OrientationAxes.business}': (
        'Social entrepreneur',
        'Entreprise sociale, économie solidaire, microfinance : '
            'impact positif + viabilité.'
      ),
      // Business combos
      '${OrientationAxes.business}_${OrientationAxes.leadership}': (
        'Manager stratège',
        'Direction d\'entreprise, consulting, finance : '
            'tu piloteras des organisations.'
      ),
      // Leadership combos
      '${OrientationAxes.leadership}_${OrientationAxes.business}': (
        'Polyvalent leader',
        'Management de transition, entrepreneuriat, '
            'administration publique.'
      ),
    };

    if (isPolyvalent && comboArchetypes.containsKey(comboKey)) {
      final (nom, desc) = comboArchetypes[comboKey]!;
      return (nom: nom, description: desc);
    }

    // ─── Cas polyvalent sans combo spécifique ─────────────────────────
    if (isPolyvalent) {
      return (
        nom: 'Polyvalent équilibré',
        description: 'Ton profil est équilibré entre "${OrientationAxes.labels[dominant]}" '
            'et "${OrientationAxes.labels[second]}". Cette polyvalence est un atout : '
            'elle t\'ouvre des carrières hybrides.',
      );
    }

    // ─── Cas dominant seul ────────────────────────────────────────────
    final (nom, desc) = soloArchetypes[dominant] ?? (
      'Profil à déterminer',
      'Réponds à davantage de questions pour affiner ton profil.'
    );
    return (nom: nom, description: desc);
  }
}
