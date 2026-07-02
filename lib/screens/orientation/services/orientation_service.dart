// lib/screens/orientation/services/orientation_service.dart
// Service d'orientation — cœur logique du chatbot conseiller.
//
// Responsabilités :
//   1. Fournir les 12 questions du chat d'orientation.
//   2. Fournir le catalogue des 15 filières togolaises (mock data).
//   3. Fournir 30+ career paths répartis sur les filières.
//   4. Calculer le profil élève (scores 6 axes + archétype) à partir des
//      réponses au chat + des scores P(L) agrégés par matière.
//   5. Calculer le % de match entre le profil et chaque filière, puis
//      renvoyer le top 5 recommandé.
//
// Algorithme de matching :
//   - Vecteur élève = [scientifique, litteraire, creatif, social, business,
//                      leadership] normalisé (L2)
//   - Vecteur filière = poidsAxes normalisé (L2)
//   - Score similarité = similarité cosinus (0..1) entre les 2 vecteurs
//   - Score matières = moyenne des P(L) des matières pivots (défaut 0.5)
//   - % match = (0.70 * similarité + 0.30 * scoreMatieres) * 100
//   - Pénalité si filière sélective et axes faibles (jusqu'à -10 pts)
//
// Aucune dépendance externe (pas de Hive, pas de dio) : pur Dart.
// Le wiring avec AppUser.bktMaitrise se fait au niveau de l'écran.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/career_path.dart';
import '../models/filiere.dart';
import '../models/orientation_profile.dart';

// ════════════════════════════════════════════════════════════════════
// QUESTIONS DU CHAT
// ════════════════════════════════════════════════════════════════════

/// Catégorie de question (pour analytics et affichage d'icône).
enum QuestionCategory { interet, matiere, valeur }

class OrientationOption {
  final String id;
  final String text;
  final Map<String, double> weights;

  const OrientationOption({
    required this.id,
    required this.text,
    required this.weights,
  });
}

class OrientationQuestion {
  final String id;
  final String text;
  final QuestionCategory category;
  final List<OrientationOption> options;

  const OrientationQuestion({
    required this.id,
    required this.text,
    required this.category,
    required this.options,
  });

  /// Libellé de catégorie (pour chip dans le chat).
  String get categoryLabel {
    switch (category) {
      case QuestionCategory.interet:
        return 'Intérêts';
      case QuestionCategory.matiere:
        return 'Matière';
      case QuestionCategory.valeur:
        return 'Valeurs';
    }
  }
}

// ════════════════════════════════════════════════════════════════════
// RECOMMANDATION
// ════════════════════════════════════════════════════════════════════

class FiliereRecommendation {
  final Filiere filiere;
  final double matchPercent;
  final List<CareerPath> careers;

  /// Raisons principales du match (1-3 phrases courtes).
  final List<String> raisons;

  const FiliereRecommendation({
    required this.filiere,
    required this.matchPercent,
    required this.careers,
    required this.raisons,
  });

  /// Vrai si la recommandation est jugée "forte" (>= 75%).
  bool get isForte => matchPercent >= 75.0;

  /// Vrai si la recommandation est "à explorer" (60-74%).
  bool get isAExplorer => matchPercent >= 60.0 && matchPercent < 75.0;
}

// ════════════════════════════════════════════════════════════════════
// SERVICE
// ════════════════════════════════════════════════════════════════════

class OrientationService {
  OrientationService();

  // ─── Pondérations du scoring (ajustables) ────────────────────────
  static const double _poidsSimilarite = 0.70;
  static const double _poidsMatieres = 0.30;
  static const double _penaliteSelective = 10.0;
  static const double _seuilAxesFortsSelectives = 0.55;
  static const double _matriereDefaut = 0.50;

  // ─── 12 questions du chat ─────────────────────────────────────────
  static const List<OrientationQuestion> questions = [
    OrientationQuestion(
      id: 'q1',
      text: "Tu aimes résoudre des problèmes mathématiques ou de logique ?",
      category: QuestionCategory.interet,
      options: [
        OrientationOption(
            id: 'a', text: 'Oui, beaucoup', weights: {OrientationAxes.scientifique: 1.0}),
        OrientationOption(
            id: 'b', text: 'Un peu', weights: {OrientationAxes.scientifique: 0.5}),
        OrientationOption(
            id: 'c', text: 'Pas vraiment', weights: {OrientationAxes.scientifique: 0.0}),
      ],
    ),
    OrientationQuestion(
      id: 'q2',
      text: "Tu aimes lire, écrire, jouer avec les mots ?",
      category: QuestionCategory.interet,
      options: [
        OrientationOption(
            id: 'a', text: 'Oui, beaucoup', weights: {OrientationAxes.litteraire: 1.0}),
        OrientationOption(
            id: 'b', text: 'Un peu', weights: {OrientationAxes.litteraire: 0.5}),
        OrientationOption(
            id: 'c', text: 'Pas vraiment', weights: {OrientationAxes.litteraire: 0.0}),
      ],
    ),
    OrientationQuestion(
      id: 'q3',
      text: "Tu aimes dessiner, bricoler, inventer des choses nouvelles ?",
      category: QuestionCategory.interet,
      options: [
        OrientationOption(
            id: 'a', text: 'Oui, beaucoup', weights: {OrientationAxes.creatif: 1.0}),
        OrientationOption(
            id: 'b', text: 'Un peu', weights: {OrientationAxes.creatif: 0.5}),
        OrientationOption(
            id: 'c', text: 'Pas vraiment', weights: {OrientationAxes.creatif: 0.0}),
      ],
    ),
    OrientationQuestion(
      id: 'q4',
      text: "Tu aimes aider, écouter, accompagner les autres ?",
      category: QuestionCategory.interet,
      options: [
        OrientationOption(
            id: 'a', text: 'Oui, beaucoup', weights: {OrientationAxes.social: 1.0}),
        OrientationOption(
            id: 'b', text: 'Un peu', weights: {OrientationAxes.social: 0.5}),
        OrientationOption(
            id: 'c', text: 'Pas vraiment', weights: {OrientationAxes.social: 0.0}),
      ],
    ),
    OrientationQuestion(
      id: 'q5',
      text: "Tu aimes vendre, négocier, monter des petits business ?",
      category: QuestionCategory.interet,
      options: [
        OrientationOption(
            id: 'a', text: 'Oui, beaucoup', weights: {OrientationAxes.business: 1.0}),
        OrientationOption(
            id: 'b', text: 'Un peu', weights: {OrientationAxes.business: 0.5}),
        OrientationOption(
            id: 'c', text: 'Pas vraiment', weights: {OrientationAxes.business: 0.0}),
      ],
    ),
    OrientationQuestion(
      id: 'q6',
      text: "Tu aimes organiser, décider, diriger une équipe ?",
      category: QuestionCategory.interet,
      options: [
        OrientationOption(
            id: 'a', text: 'Oui, beaucoup', weights: {OrientationAxes.leadership: 1.0}),
        OrientationOption(
            id: 'b', text: 'Un peu', weights: {OrientationAxes.leadership: 0.5}),
        OrientationOption(
            id: 'c', text: 'Pas vraiment', weights: {OrientationAxes.leadership: 0.0}),
      ],
    ),
    OrientationQuestion(
      id: 'q7',
      text: "Quelle matière préfères-tu le plus à l'école ?",
      category: QuestionCategory.matiere,
      options: [
        OrientationOption(
            id: 'a', text: 'Mathématiques', weights: {OrientationAxes.scientifique: 1.0}),
        OrientationOption(
            id: 'b',
            text: 'Sciences (Physique, SVT)',
            weights: {OrientationAxes.scientifique: 0.8, OrientationAxes.social: 0.2}),
        OrientationOption(
            id: 'c', text: 'Français, Philosophie', weights: {OrientationAxes.litteraire: 1.0}),
        OrientationOption(
            id: 'd',
            text: 'Histoire-Géo, Anglais',
            weights: {OrientationAxes.litteraire: 0.6, OrientationAxes.social: 0.4}),
        OrientationOption(
            id: 'e',
            text: 'EPS, Arts, Musique',
            weights: {OrientationAxes.creatif: 0.6, OrientationAxes.leadership: 0.4}),
      ],
    ),
    OrientationQuestion(
      id: 'q8',
      text: "Tu préfères travailler...",
      category: QuestionCategory.interet,
      options: [
        OrientationOption(
            id: 'a',
            text: 'En équipe',
            weights: {OrientationAxes.leadership: 0.6, OrientationAxes.social: 0.6}),
        OrientationOption(
            id: 'b',
            text: 'Seul',
            weights: {OrientationAxes.scientifique: 0.5, OrientationAxes.creatif: 0.5}),
        OrientationOption(
            id: 'c',
            text: 'Les deux selon le moment',
            weights: {
              OrientationAxes.scientifique: 0.3,
              OrientationAxes.litteraire: 0.3,
              OrientationAxes.creatif: 0.3,
              OrientationAxes.social: 0.3,
              OrientationAxes.business: 0.3,
              OrientationAxes.leadership: 0.3,
            }),
      ],
    ),
    OrientationQuestion(
      id: 'q9',
      text: "Qu'est-ce qui compte le plus pour toi dans un futur métier ?",
      category: QuestionCategory.valeur,
      options: [
        OrientationOption(
            id: 'a', text: 'Un bon salaire', weights: {OrientationAxes.business: 1.0}),
        OrientationOption(
            id: 'a2', text: 'Aider la société', weights: {OrientationAxes.social: 1.0}),
        OrientationOption(
            id: 'a3', text: 'Exprimer ma créativité', weights: {OrientationAxes.creatif: 1.0}),
        OrientationOption(
            id: 'a4', text: 'Comprendre comment le monde fonctionne', weights: {OrientationAxes.scientifique: 1.0}),
      ],
    ),
    OrientationQuestion(
      id: 'q10',
      text: "Tu te vois plutôt...",
      category: QuestionCategory.valeur,
      options: [
        OrientationOption(
            id: 'a',
            text: 'Entreprendre mon propre business',
            weights: {OrientationAxes.business: 0.8, OrientationAxes.leadership: 0.4}),
        OrientationOption(
            id: 'b',
            text: 'Faire carrière dans une grande structure',
            weights: {OrientationAxes.leadership: 0.6, OrientationAxes.scientifique: 0.4}),
        OrientationOption(
            id: 'c',
            text: 'Voyager pour mon métier',
            weights: {
              OrientationAxes.litteraire: 0.4,
              OrientationAxes.social: 0.4,
              OrientationAxes.business: 0.4
            }),
        OrientationOption(
            id: 'd',
            text: 'Aider ma communauté localement',
            weights: {OrientationAxes.social: 1.0}),
      ],
    ),
    OrientationQuestion(
      id: 'q11',
      text: "Tu es prêt à faire des études...",
      category: QuestionCategory.valeur,
      options: [
        OrientationOption(
            id: 'a',
            text: 'Courtes (2-3 ans, BTS/DEUG)',
            weights: {OrientationAxes.business: 0.5, OrientationAxes.creatif: 0.3}),
        OrientationOption(
            id: 'b',
            text: 'Moyennes (4-5 ans, Licence + Master)',
            weights: {OrientationAxes.scientifique: 0.5, OrientationAxes.litteraire: 0.5}),
        OrientationOption(
            id: 'c',
            text: 'Longues (6-7+ ans, Médecine, Doctorat)',
            weights: {OrientationAxes.scientifique: 0.8, OrientationAxes.social: 0.6}),
        OrientationOption(
            id: 'd',
            text: 'Peu importe la durée, je veux la meilleure formation',
            weights: {OrientationAxes.leadership: 0.6, OrientationAxes.scientifique: 0.4}),
      ],
    ),
    OrientationQuestion(
      id: 'q12',
      text: "Tu imagines ton futur métier comme...",
      category: QuestionCategory.valeur,
      options: [
        OrientationOption(
            id: 'a',
            text: 'Stable et sécurisé (fonction publique, banque)',
            weights: {OrientationAxes.scientifique: 0.5, OrientationAxes.social: 0.3}),
        OrientationOption(
            id: 'b',
            text: 'Risqué mais enrichissant (entrepreneuriat)',
            weights: {OrientationAxes.business: 0.8, OrientationAxes.leadership: 0.4}),
        OrientationOption(
            id: 'c',
            text: 'Créatif et imprévisible (design, arts, média)',
            weights: {OrientationAxes.creatif: 1.0}),
        OrientationOption(
            id: 'd',
            text: 'Au service des autres (santé, social, éducation)',
            weights: {OrientationAxes.social: 1.0}),
      ],
    ),
  ];

  // ─── 15 filières togolaises ───────────────────────────────────────
  static const List<Filiere> filieres = [
    Filiere(
      id: 'medecine',
      nom: 'Médecine',
      nomCourt: 'Médecine',
      description:
          "Formation médicale générale de 7 ans débouchant sur le doctorat "
          "en médecine. Combine sciences fondamentales, clinique et stages "
          "en hôpital. Filière la plus sélective du Togo.",
      icon: Icons.medical_services,
      poidsAxes: {
        OrientationAxes.scientifique: 0.45,
        OrientationAxes.social: 0.35,
        OrientationAxes.leadership: 0.10,
        OrientationAxes.litteraire: 0.05,
        OrientationAxes.creatif: 0.05,
        OrientationAxes.business: 0.00,
      },
      matieresPivots: ['SVT', 'Sciences Physiques', 'Mathématiques'],
      universites: ['Université de Lomé (FSS)'],
      universitesCedeao: ['Université Cheikh Anta Diop (Dakar)', 'Université de Cocody (Abidjan)'],
      duree: '7 ans',
      diplome: 'Doctorat en Médecine',
      salaireDebut: 250000,
      salaireSenior: 1500000,
      niveauAcces: 'BAC',
      seriesRecommandees: ['C', 'D'],
      competencesCles: ['Rigueur', 'Mémoire', 'Empathie', 'Résistance au stress'],
      debouches: ['Médecin généraliste', 'Spécialiste', 'Chirurgien', 'Médecin de famille'],
      careerPathIds: ['med_generaliste', 'med_chirurgien', 'pediatre'],
      selective: true,
      difficulteAdmission: 5,
    ),
    Filiere(
      id: 'pharmacie',
      nom: 'Pharmacie',
      nomCourt: 'Pharmacie',
      description:
          "Études pharmaceutiques de 6 ans. Combine chimie, biologie et "
          "gestion d'officine. Mène au diplôme de Docteur en Pharmacie "
          "(officine ou industrie).",
      icon: Icons.local_pharmacy,
      poidsAxes: {
        OrientationAxes.scientifique: 0.55,
        OrientationAxes.business: 0.20,
        OrientationAxes.social: 0.15,
        OrientationAxes.litteraire: 0.05,
        OrientationAxes.creatif: 0.05,
        OrientationAxes.leadership: 0.00,
      },
      matieresPivots: ['SVT', 'Sciences Physiques', 'Mathématiques'],
      universites: ['Université de Lomé (FSS)'],
      universitesCedeao: ['Université de Dakar', 'Université de Ouagadougou'],
      duree: '6 ans',
      diplome: 'Doctorat en Pharmacie',
      salaireDebut: 300000,
      salaireSenior: 2000000,
      niveauAcces: 'BAC',
      seriesRecommandees: ['C', 'D'],
      competencesCles: ['Chimie', 'Biologie', 'Gestion', 'Conseil client'],
      debouches: ['Pharmacien d\'officine', 'Industrie pharma', 'Recherche', 'Importation'],
      careerPathIds: ['pharmacien_officine', 'industrie_pharma'],
      selective: true,
      difficulteAdmission: 5,
    ),
    Filiere(
      id: 'ingenierie',
      nom: 'Ingénierie (Génie Civil, Électrique, Mécanique)',
      nomCourt: 'Ingénierie',
      description:
          "Formation d'ingénieur de conception en 5 ans dans les grandes "
          "écoles togolaises. Spécialités : génie civil, électronique, "
          "télécom, mécanique, hydraulique.",
      icon: Icons.engineering,
      poidsAxes: {
        OrientationAxes.scientifique: 0.60,
        OrientationAxes.creatif: 0.20,
        OrientationAxes.leadership: 0.10,
        OrientationAxes.business: 0.05,
        OrientationAxes.litteraire: 0.05,
        OrientationAxes.social: 0.00,
      },
      matieresPivots: ['Mathématiques', 'Sciences Physiques'],
      universites: ['EUT (Université de Lomé)', 'EPB (Ecole Polytechnique de Bibiyaku)'],
      universitesCedeao: ['2IE (Ouagadougou)', 'Ecole Polytechnique de Thiès'],
      duree: '5 ans',
      diplome: 'Diplôme d\'Ingénieur de Conception',
      salaireDebut: 350000,
      salaireSenior: 1200000,
      niveauAcces: 'BAC',
      seriesRecommandees: ['C', 'D'],
      competencesCles: ['Maths', 'Physique', 'Modélisation', 'Travail en équipe'],
      debouches: ['BTP', 'Énergie', 'Télécoms', 'Industrie', 'Conseil technique'],
      careerPathIds: ['ing_génie_civil', 'ing_energie', 'ing_telecom'],
      selective: true,
      difficulteAdmission: 4,
    ),
    Filiere(
      id: 'informatique',
      nom: 'Informatique & Réseaux',
      nomCourt: 'Informatique',
      description:
          "Formation en 3 à 5 ans (BTS à Ingénieur) couvrant le "
          "développement logiciel, les réseaux, la cybersécurité et "
          "l'intelligence artificielle. Filière en forte croissance au Togo.",
      icon: Icons.computer,
      poidsAxes: {
        OrientationAxes.scientifique: 0.50,
        OrientationAxes.creatif: 0.25,
        OrientationAxes.business: 0.10,
        OrientationAxes.leadership: 0.05,
        OrientationAxes.litteraire: 0.05,
        OrientationAxes.social: 0.05,
      },
      matieresPivots: ['Mathématiques', 'Sciences Physiques'],
      universites: ['IFG (Institut de Formation en Gestion)', 'ENI (Ecole Nationale Informatique)'],
      universitesCedeao: ['ESATIC (Kinshasa)', 'ISTIC (Dakar)'],
      duree: '3-5 ans',
      diplome: 'BTS / Licence / Ingénieur Informatique',
      salaireDebut: 300000,
      salaireSenior: 1500000,
      niveauAcces: 'BAC',
      seriesRecommandees: ['C', 'D'],
      competencesCles: ['Logique', 'Code', 'Résolution de problèmes', 'Veille tech'],
      debouches: ['Développeur', 'Administrateur réseaux', 'Data analyst', 'Freelance'],
      careerPathIds: ['dev_web', 'data_analyst', 'admin_reseaux'],
      selective: false,
      difficulteAdmission: 3,
    ),
    Filiere(
      id: 'droit',
      nom: 'Droit',
      nomCourt: 'Droit',
      description:
          "Études juridiques en 5 ans (Licence + Master). Spécialités : "
          "droit des affaires, droit social, droit pénal, carrières "
          "judiciaires. Débouche sur le barreau ou la magistrature.",
      icon: Icons.gavel,
      poidsAxes: {
        OrientationAxes.litteraire: 0.40,
        OrientationAxes.leadership: 0.30,
        OrientationAxes.social: 0.15,
        OrientationAxes.business: 0.10,
        OrientationAxes.scientifique: 0.05,
        OrientationAxes.creatif: 0.00,
      },
      matieresPivots: ['Français', 'Histoire-Géo', 'Anglais'],
      universites: ['Université de Lomé (FDSJP)', 'Université de Kara'],
      universitesCedeao: ['Université de Ouagadougou', 'Université de Dakar'],
      duree: '5 ans',
      diplome: 'Master en Droit',
      salaireDebut: 200000,
      salaireSenior: 1500000,
      niveauAcces: 'BAC',
      seriesRecommandees: ['A', 'D'],
      competencesCles: ['Argumentation', 'Mémoire', 'Rédaction', 'Éloquence'],
      debouches: ['Avocat', 'Magistrat', 'Notaire', 'Juriste d\'entreprise'],
      careerPathIds: ['avocat', 'juriste_entreprise', 'magistrat'],
      selective: false,
      difficulteAdmission: 3,
    ),
    Filiere(
      id: 'economie_gestion',
      nom: 'Économie & Gestion',
      nomCourt: 'Éco/Gestion',
      description:
          "Formation en 5 ans en économie, comptabilité, finance, "
          "management. Débouche sur les métiers de la banque, de la "
          "finance, de l'audit et du management d'entreprise.",
      icon: Icons.trending_up,
      poidsAxes: {
        OrientationAxes.business: 0.45,
        OrientationAxes.scientifique: 0.25,
        OrientationAxes.leadership: 0.15,
        OrientationAxes.litteraire: 0.10,
        OrientationAxes.social: 0.05,
        OrientationAxes.creatif: 0.00,
      },
      matieresPivots: ['Mathématiques', 'Histoire-Géo', 'Anglais'],
      universites: ['ESAE (Ecole Supérieure d\'Administration et d\'Économie)', 'Université de Lomé (FASEG)'],
      universitesCedeao: ['ENSEA (Abidjan)', 'ISM (Dakar)'],
      duree: '5 ans',
      diplome: 'Master en Économie / Gestion',
      salaireDebut: 250000,
      salaireSenior: 1500000,
      niveauAcces: 'BAC',
      seriesRecommandees: ['D', 'C'],
      competencesCles: ['Analyse', 'Chiffres', 'Stratégie', 'Communication'],
      debouches: ['Banque', 'Audit', 'Finance', 'Consulting', 'Administration'],
      careerPathIds: ['analyste_financier', 'auditeur', 'manager_projet'],
      selective: false,
      difficulteAdmission: 3,
    ),
    Filiere(
      id: 'agronomie',
      nom: 'Agronomie & Sciences Agricoles',
      nomCourt: 'Agronomie',
      description:
          "Formation d'ingénieur agronome en 5 ans. Couvre les cultures, "
          "l'élevage, la gestion de l'eau, l'agroforesterie. Secteur "
          "stratégique au Togo (60% de la population active).",
      icon: Icons.agriculture,
      poidsAxes: {
        OrientationAxes.scientifique: 0.40,
        OrientationAxes.social: 0.20,
        OrientationAxes.business: 0.20,
        OrientationAxes.creatif: 0.10,
        OrientationAxes.leadership: 0.10,
        OrientationAxes.litteraire: 0.00,
      },
      matieresPivots: ['SVT', 'Sciences Physiques', 'Mathématiques'],
      universites: ['ESA (Ecole Supérieure d\'Agronomie, Univ. Lomé)'],
      universitesCedeao: ['Institut Agro (Mali)', 'Université de Bobo-Dioulasso'],
      duree: '5 ans',
      diplome: 'Ingénieur Agronome',
      salaireDebut: 250000,
      salaireSenior: 1000000,
      niveauAcces: 'BAC',
      seriesRecommandees: ['C', 'D'],
      competencesCles: ['Biologie', 'Terrain', 'Gestion de projet', 'Innovation'],
      debouches: ['Coopératives', 'ONG agricoles', 'Ministère Agriculture', 'Entreprise semencière'],
      careerPathIds: ['ing_agra', 'conseiller_agricole'],
      selective: false,
      difficulteAdmission: 3,
    ),
    Filiere(
      id: 'lettres',
      nom: 'Lettres Modernes & Langues',
      nomCourt: 'Lettres',
      description:
          "Études littéraires en 3 à 5 ans. Spécialités : lettres modernes, "
          "linguistique, langues étrangères (anglais, espagnol, allemand). "
          "Mène à l'enseignement, la traduction, l'édition.",
      icon: Icons.menu_book,
      poidsAxes: {
        OrientationAxes.litteraire: 0.60,
        OrientationAxes.social: 0.20,
        OrientationAxes.creatif: 0.10,
        OrientationAxes.leadership: 0.05,
        OrientationAxes.business: 0.05,
        OrientationAxes.scientifique: 0.00,
      },
      matieresPivots: ['Français', 'Anglais', 'Histoire-Géo'],
      universites: ['Université de Lomé (FLE)', 'Université de Kara'],
      universitesCedeao: ['Université de Abidjan', 'Université de Lomé'],
      duree: '3-5 ans',
      diplome: 'Licence / Master Lettres',
      salaireDebut: 150000,
      salaireSenior: 700000,
      niveauAcces: 'BAC',
      seriesRecommandees: ['A'],
      competencesCles: ['Lecture', 'Écriture', 'Langues', 'Analyse de texte'],
      debouches: ['Enseignement', 'Traduction', 'Édition', 'Médiation culturelle'],
      careerPathIds: ['prof_lettres', 'traducteur'],
      selective: false,
      difficulteAdmission: 2,
    ),
    Filiere(
      id: 'sciences',
      nom: 'Sciences Fondamentales (Physique, Chimie, Bio)',
      nomCourt: 'Sciences',
      description:
          "Études scientifiques fondamentales en 5 ans (Licence + Master). "
          "Spécialités : mathématiques, physique, chimie, biologie. Mène "
          "à la recherche, l'enseignement supérieur et l'industrie.",
      icon: Icons.science,
      poidsAxes: {
        OrientationAxes.scientifique: 0.70,
        OrientationAxes.creatif: 0.10,
        OrientationAxes.leadership: 0.10,
        OrientationAxes.litteraire: 0.05,
        OrientationAxes.social: 0.05,
        OrientationAxes.business: 0.00,
      },
      matieresPivots: ['Mathématiques', 'Sciences Physiques', 'SVT'],
      universites: ['Université de Lomé (FDS)'],
      universitesCedeao: ['Université de Cocody', 'Université de Dakar'],
      duree: '5 ans',
      diplome: 'Master en Sciences',
      salaireDebut: 200000,
      salaireSenior: 900000,
      niveauAcces: 'BAC',
      seriesRecommandees: ['C', 'D'],
      competencesCles: ['Logique', 'Méthode expérimentale', 'Mémoire', 'Curiosité'],
      debouches: ['Recherche', 'Enseignement', 'Industrie', 'Statistiques', 'Data'],
      careerPathIds: ['chercheur', 'prof_sciences'],
      selective: false,
      difficulteAdmission: 3,
    ),
    Filiere(
      id: 'architecture',
      nom: 'Architecture',
      nomCourt: 'Architecture',
      description:
          "Formation d'architecte en 6 ans. Combine conception créative, "
          "dessin technique, culture constructive et urbanisme. Filière "
          "rare et demandée au Togo.",
      icon: Icons.architecture,
      poidsAxes: {
        OrientationAxes.creatif: 0.40,
        OrientationAxes.scientifique: 0.35,
        OrientationAxes.leadership: 0.10,
        OrientationAxes.business: 0.10,
        OrientationAxes.litteraire: 0.05,
        OrientationAxes.social: 0.00,
      },
      matieresPivots: ['Mathématiques', 'Sciences Physiques', 'Français'],
      universites: ['Université de Lomé (FSS - option architecture)', 'EUT'],
      universitesCedeao: ['EAMAU (Lomé - panafricaine)', 'École de Dakar'],
      duree: '6 ans',
      diplome: 'Diplôme d\'Architecte (DESA)',
      salaireDebut: 300000,
      salaireSenior: 1500000,
      niveauAcces: 'BAC',
      seriesRecommandees: ['C', 'D'],
      competencesCles: ['Dessin', 'Créativité', 'Vision 3D', 'Technique'],
      debouches: ['Cabinet d\'architecture', 'Urbanisme', 'Maîtrise d\'œuvre', 'BTP'],
      careerPathIds: ['architecte', 'urbaniste'],
      selective: true,
      difficulteAdmission: 4,
    ),
    Filiere(
      id: 'comptabilite_finance',
      nom: 'Comptabilité & Finance',
      nomCourt: 'Compta/Finance',
      description:
          "Formation en 3 à 5 ans (BTS à Master). Spécialités : "
          "comptabilité, finance, contrôle de gestion, audit. Débouche "
          "sur l'expertise comptable (DEC).",
      icon: Icons.account_balance,
      poidsAxes: {
        OrientationAxes.business: 0.50,
        OrientationAxes.scientifique: 0.30,
        OrientationAxes.leadership: 0.10,
        OrientationAxes.litteraire: 0.05,
        OrientationAxes.social: 0.05,
        OrientationAxes.creatif: 0.00,
      },
      matieresPivots: ['Mathématiques', 'Anglais'],
      universites: ['ESAE', 'IFG', 'Université de Lomé (FASEG)'],
      universitesCedeao: ['ENSEA (Abidjan)', 'CESS (Dakar)'],
      duree: '3-5 ans',
      diplome: 'BTS / Master Comptabilité',
      salaireDebut: 250000,
      salaireSenior: 1300000,
      niveauAcces: 'BAC',
      seriesRecommandees: ['D', 'C'],
      competencesCles: ['Rigueur', 'Chiffres', 'Normes IFRS', 'Éthique'],
      debouches: ['Cabinet d\'expertise', 'Banque', 'Entreprise', 'Administration'],
      careerPathIds: ['comptable', 'expert_comptable'],
      selective: false,
      difficulteAdmission: 2,
    ),
    Filiere(
      id: 'marketing_communication',
      nom: 'Marketing & Communication',
      nomCourt: 'Marketing/Com',
      description:
          "Formation en 3 à 5 ans. Spécialités : marketing digital, "
          "communication corporate, publicité, relations publiques. "
          "Filière dynamique avec l'essor des entreprises togolaises.",
      icon: Icons.campaign,
      poidsAxes: {
        OrientationAxes.litteraire: 0.30,
        OrientationAxes.creatif: 0.30,
        OrientationAxes.business: 0.30,
        OrientationAxes.social: 0.05,
        OrientationAxes.leadership: 0.05,
        OrientationAxes.scientifique: 0.00,
      },
      matieresPivots: ['Français', 'Anglais', 'Histoire-Géo'],
      universites: ['IFG', 'ISCOM Lomé', 'Université de Lomé (FASEG)'],
      universitesCedeao: ['ISCOM (Abidjan)', 'Sup de Pub Dakar'],
      duree: '3-5 ans',
      diplome: 'BTS / Master Marketing',
      salaireDebut: 200000,
      salaireSenior: 1000000,
      niveauAcces: 'BAC',
      seriesRecommandees: ['A', 'D'],
      competencesCles: ['Créativité', 'Stratégie', 'Réseaux sociaux', 'Écriture'],
      debouches: ['Agence communication', 'Marketing entreprise', 'Médias', 'Événementiel'],
      careerPathIds: ['chef_produit', 'community_manager'],
      selective: false,
      difficulteAdmission: 2,
    ),
    Filiere(
      id: 'soins_infirmiers',
      nom: 'Soins Infirmiers (IDE)',
      nomCourt: 'Infirmier',
      description:
          "Formation paramédicale en 3 ans. Mène au diplôme d'État "
          "d'Infirmier (IDE). Soins, prévention, éducation à la santé. "
          "Filière sociale et critique pour le système de santé togolais.",
      icon: Icons.health_and_safety,
      poidsAxes: {
        OrientationAxes.social: 0.50,
        OrientationAxes.scientifique: 0.35,
        OrientationAxes.leadership: 0.05,
        OrientationAxes.litteraire: 0.05,
        OrientationAxes.creatif: 0.05,
        OrientationAxes.business: 0.00,
      },
      matieresPivots: ['SVT', 'Sciences Physiques', 'Français'],
      universites: ['Ecole Nationale des Auxiliaires Médicaux (ENAM, Lomé)'],
      universitesCedeao: ['ENAM Abidjan', 'ENAM Dakar'],
      duree: '3 ans',
      diplome: 'Diplôme d\'État Infirmier (IDE)',
      salaireDebut: 150000,
      salaireSenior: 500000,
      niveauAcces: 'BAC',
      seriesRecommandees: ['D', 'C'],
      competencesCles: ['Empathie', 'Rigueur', 'Résistance', 'Soins techniques'],
      debouches: ['Hôpitaux publics', 'Cliniques privées', 'ONG santé', 'Libéral'],
      careerPathIds: ['infirmier_ide', 'infirmier_specialise'],
      selective: true,
      difficulteAdmission: 3,
    ),
    Filiere(
      id: 'enseignement',
      nom: 'Enseignement (ENS)',
      nomCourt: 'Enseignement',
      description:
          "Formation d'enseignant du secondaire en 3 à 5 ans à l'ENS. "
          "Spécialités par matière : maths, physique, SVT, français, "
          "anglais, histoire-géo. Débouche sur le concours d'agrégation.",
      icon: Icons.school,
      poidsAxes: {
        OrientationAxes.litteraire: 0.30,
        OrientationAxes.social: 0.30,
        OrientationAxes.scientifique: 0.20,
        OrientationAxes.leadership: 0.15,
        OrientationAxes.creatif: 0.05,
        OrientationAxes.business: 0.00,
      },
      matieresPivots: ['Français', 'Mathématiques', 'SVT'],
      universites: ['ENS (École Normale Supérieure, Lomé)', 'ENS Kara'],
      universitesCedeao: ['ENS Dakar', 'ENS Abidjan'],
      duree: '3-5 ans',
      diplome: 'CAPE / Agrégation',
      salaireDebut: 180000,
      salaireSenior: 600000,
      niveauAcces: 'BAC',
      seriesRecommandees: ['A', 'C', 'D'],
      competencesCles: ['Pédagogie', 'Maîtrise matière', 'Patience', 'Éloquence'],
      debouches: ['Collèges et lycées publics', 'Enseignement privé', 'Inspection', 'Formateur'],
      careerPathIds: ['prof_lycee', 'inspecteur_educ'],
      selective: true,
      difficulteAdmission: 3,
    ),
    Filiere(
      id: 'journalisme',
      nom: 'Journalisme & Médias',
      nomCourt: 'Journalisme',
      description:
          "Formation en 3 à 5 ans. Spécialités : journalisme multitâche, "
          "radio/TV, presse écrite, multimédia. Débouche sur les rédactions, "
          "la communication politique et le documentaire.",
      icon: Icons.newspaper,
      poidsAxes: {
        OrientationAxes.litteraire: 0.40,
        OrientationAxes.creatif: 0.25,
        OrientationAxes.social: 0.20,
        OrientationAxes.leadership: 0.10,
        OrientationAxes.business: 0.05,
        OrientationAxes.scientifique: 0.00,
      },
      matieresPivots: ['Français', 'Anglais', 'Histoire-Géo'],
      universites: ['ISMP (Institut des Sciences de l\'Information et de la Communication, Lomé)'],
      universitesCedeao: ['CESTI (Dakar)', 'ISIC (Abidjan)'],
      duree: '3-5 ans',
      diplome: 'Licence / Master Journalisme',
      salaireDebut: 150000,
      salaireSenior: 800000,
      niveauAcces: 'BAC',
      seriesRecommandees: ['A', 'D'],
      competencesCles: ['Écriture', 'Curiosité', 'Esprit critique', 'Réseaux'],
      debouches: ['Rédactions presse', 'Radio/TV', 'Communication', 'Documentaire'],
      careerPathIds: ['journaliste', 'reporter'],
      selective: false,
      difficulteAdmission: 3,
    ),
  ];

  // ─── 30+ career paths ─────────────────────────────────────────────
  static const List<CareerPath> careerPaths = [
    // ── Médecine ────────────────────────────────────────────────────
    CareerPath(
      id: 'med_generaliste',
      filiereId: 'medecine',
      titre: 'Médecin généraliste',
      description:
          "Consulte, examine et traite les patients pour des affections "
          "courantes. Orienté vers les soins primaires et le suivi "
          "longitudinal des familles.",
      niveauEntree: 'Doctorat en médecine + stage',
      evolution:
          "Médecin de famille → installé en libéral → médecine spécialisée "
          "après DFMS (3-5 ans).",
      salaireDebut: 250000,
      salaireSenior: 1200000,
      competencesCles: ['Diagnostic', 'Écoute', 'Patience', 'Mémoire'],
      secteurs: ['Public', 'Privé', 'Libéral'],
      demandeMarche: 5,
      potentielInternational: 'moyen',
      tendance: 'en croissance',
    ),
    CareerPath(
      id: 'med_chirurgien',
      filiereId: 'medecine',
      titre: 'Chirurgien',
      description:
          "Opère les patients pour traiter traumatismes, tumeurs, "
          "malformations. Spécialité exigeante exigeant 5-7 ans de "
          "formation complémentaire après le doctorat.",
      niveauEntree: 'Doctorat + spécialité chirurgicale (5-7 ans)',
      evolution: "Chef de clinique → chirurgien senior → chef de service.",
      salaireDebut: 600000,
      salaireSenior: 2500000,
      competencesCles: ['Dextérité', 'Concentration', 'Résistance', 'Décision'],
      secteurs: ['Public', 'Privé'],
      demandeMarche: 5,
      potentielInternational: 'fort',
      tendance: 'en croissance',
    ),
    CareerPath(
      id: 'pediatre',
      filiereId: 'medecine',
      titre: 'Pédiatre',
      description:
          "Spécialiste de la santé de l'enfant et de l'adolescent. "
          "Suivi de la croissance, vaccination, traitement des "
          "maladies infantiles.",
      niveauEntree: 'Doctorat + spécialité pédiatrie (4 ans)',
      evolution: "Pédiatre → néonatologue → chef de service pédiatrie.",
      salaireDebut: 500000,
      salaireSenior: 1800000,
      competencesCles: ['Empathie', 'Patience', 'Observation', 'Communication'],
      secteurs: ['Public', 'Privé', 'ONG'],
      demandeMarche: 5,
      potentielInternational: 'moyen',
      tendance: 'en croissance',
    ),
    // ── Pharmacie ───────────────────────────────────────────────────
    CareerPath(
      id: 'pharmacien_officine',
      filiereId: 'pharmacie',
      titre: 'Pharmacien d\'officine',
      description:
          "Tient une pharmacie, délivre les ordonnances, conseille les "
          "clients et gère le stock. Peut ouvrir sa propre officine.",
      niveauEntree: 'Doctorat en pharmacie',
      evolution: "Préparateur → titulaire → propriétaire de pharmacie.",
      salaireDebut: 300000,
      salaireSenior: 2000000,
      competencesCles: ['Conseil', 'Gestion', 'Chimie', 'Éthique'],
      secteurs: ['Privé', 'Libéral'],
      demandeMarche: 4,
      potentielInternational: 'faible',
      tendance: 'stable',
    ),
    CareerPath(
      id: 'industrie_pharma',
      filiereId: 'pharmacie',
      titre: 'Ingénieur industrie pharmaceutique',
      description:
          "Travaille dans la fabrication, le contrôle qualité et la "
          "R&D des médicaments en industrie. Secteur en croissance "
          "en Afrique de l'Ouest.",
      niveauEntree: 'Doctorat en pharmacie + spécialisation',
      evolution: "Technicien → chef de production → directeur industriel.",
      salaireDebut: 400000,
      salaireSenior: 1800000,
      competencesCles: ['Normes BPF', 'Contrôle qualité', 'Procédés', 'Anglais'],
      secteurs: ['Privé', 'Sous-traitance'],
      demandeMarche: 4,
      potentielInternational: 'fort',
      tendance: 'en croissance',
    ),
    // ── Ingénierie ──────────────────────────────────────────────────
    CareerPath(
      id: 'ing_génie_civil',
      filiereId: 'ingenierie',
      titre: 'Ingénieur génie civil',
      description:
          "Conçoit et supervise la construction d'ouvrages : ponts, "
          "immeubles, routes, barrages. Particire à l'aménagement du "
          "territoire.",
      niveauEntree: 'Diplôme d\'ingénieur de conception',
      evolution: "Projeteur → chef de chantier → directeur technique.",
      salaireDebut: 350000,
      salaireSenior: 1200000,
      competencesCles: ['RDM', 'BIM', 'Encadrement', 'Sécurité'],
      secteurs: ['BTP', 'Public', 'Bureaux d\'études'],
      demandeMarche: 5,
      potentielInternational: 'fort',
      tendance: 'en croissance',
    ),
    CareerPath(
      id: 'ing_energie',
      filiereId: 'ingenierie',
      titre: 'Ingénieur énergie',
      description:
          "Conçoit et exploite des centrales électriques, réseaux et "
          "systèmes d'énergie renouvelable (solaire, hydro). Enjeu "
          "stratégique au Togo (accès énergie).",
      niveauEntree: 'Diplôme d\'ingénieur de conception',
      evolution: "Ingénieur projet → chef de service → directeur production.",
      salaireDebut: 400000,
      salaireSenior: 1500000,
      competencesCles: ['Réseaux', 'Systèmes', 'Maintenance', 'Veille'],
      secteurs: ['CEET', 'CEB', 'Privé'],
      demandeMarche: 4,
      potentielInternational: 'fort',
      tendance: 'en croissance',
    ),
    CareerPath(
      id: 'ing_telecom',
      filiereId: 'ingenierie',
      titre: 'Ingénieur télécoms & réseaux',
      description:
          "Conçoit et déploie les infrastructures de télécommunication "
          "(4G/5G, fibre). Travaille chez les opérateurs (Togo Telecom, "
          "Moov, Togocom).",
      niveauEntree: 'Diplôme d\'ingénieur de conception',
      evolution: "Ingénieur réseau → architecte → directeur technique.",
      salaireDebut: 450000,
      salaireSenior: 1500000,
      competencesCles: ['Réseaux IP', 'Fibre', 'Cybersécurité', 'Protocoles'],
      secteurs: ['Opérateurs', 'Banque', 'Consulting'],
      demandeMarche: 5,
      potentielInternational: 'fort',
      tendance: 'en croissance',
    ),
    // ── Informatique ────────────────────────────────────────────────
    CareerPath(
      id: 'dev_web',
      filiereId: 'informatique',
      titre: 'Développeur web & mobile',
      description:
          "Code des applications web et mobiles pour des entreprises "
          "locales ou des clients internationaux (freelance). Secteur "
          "le plus accessible et le plus rémunérateur en début de carrière.",
      niveauEntree: 'BTS / Licence informatique',
      evolution: "Développeur → lead dev → CTO ou freelance international.",
      salaireDebut: 300000,
      salaireSenior: 1500000,
      competencesCles: ['JavaScript', 'Flutter', 'Git', 'API REST'],
      secteurs: ['Privé', 'Freelance', 'Remote international'],
      demandeMarche: 5,
      potentielInternational: 'fort',
      tendance: 'en croissance',
    ),
    CareerPath(
      id: 'data_analyst',
      filiereId: 'informatique',
      titre: 'Data analyst / Data scientist',
      description:
          "Analyse de grosses données pour aider à la décision. "
          "Construit des dashboards, modèles prédictifs et pipelines "
          "data. Métier en plein essor au Togo.",
      niveauEntree: 'Licence + Python + SQL',
      evolution: "Data analyst → data scientist → head of data.",
      salaireDebut: 400000,
      salaireSenior: 2000000,
      competencesCles: ['Python', 'SQL', 'Stats', 'Visualization'],
      secteurs: ['Banque', 'Télécoms', 'Startups', 'ONG'],
      demandeMarche: 5,
      potentielInternational: 'fort',
      tendance: 'en croissance',
    ),
    CareerPath(
      id: 'admin_reseaux',
      filiereId: 'informatique',
      titre: 'Administrateur systèmes & réseaux',
      description:
          "Maintient les serveurs et l'infrastructure IT d'une "
          "organisation. Cybersécurité, sauvegardes, support utilisateur.",
      niveauEntree: 'BTS + certifications (Cisco, Linux)',
      evolution: "Admin → architecte réseau → RSSI (cybersécurité).",
      salaireDebut: 250000,
      salaireSenior: 1200000,
      competencesCles: ['Linux', 'Réseaux', 'Sécurité', 'Scripting'],
      secteurs: ['Banque', 'Administrations', 'Opérateurs'],
      demandeMarche: 4,
      potentielInternational: 'moyen',
      tendance: 'en croissance',
    ),
    // ── Droit ───────────────────────────────────────────────────────
    CareerPath(
      id: 'avocat',
      filiereId: 'droit',
      titre: 'Avocat',
      description:
          "Conseille et défend des clients (particuliers, entreprises) "
          "devant les tribunaux. Inscrit au barreau après stage et CAPA.",
      niveauEntree: 'Master + CAPA + inscription barreau',
      evolution: "Avocat stagiaire → associé → bâtonnier.",
      salaireDebut: 250000,
      salaireSenior: 2000000,
      competencesCles: ['Plaidoirie', 'Stratégie', 'Rédaction', 'Éthique'],
      secteurs: ['Cabinets privés', 'Libéral'],
      demandeMarche: 3,
      potentielInternational: 'faible',
      tendance: 'stable',
    ),
    CareerPath(
      id: 'juriste_entreprise',
      filiereId: 'droit',
      titre: 'Juriste d\'entreprise',
      description:
          "Conseille la direction d'une entreprise sur les contrats, "
          "le droit social, la propriété intellectuelle et la conformité.",
      niveauEntree: 'Master en droit des affaires',
      evolution: "Juriste → juriste senior → directeur juridique.",
      salaireDebut: 300000,
      salaireSenior: 1200000,
      competencesCles: ['Droit des affaires', 'Négociation', 'Rédaction', 'Anglais'],
      secteurs: ['Banque', 'Industrie', 'Télécoms'],
      demandeMarche: 4,
      potentielInternational: 'moyen',
      tendance: 'en croissance',
    ),
    CareerPath(
      id: 'magistrat',
      filiereId: 'droit',
      titre: 'Magistrat (juge ou procureur)',
      description:
          "Rend la justice au nom du peuple togolais. Concours de la "
          "magistrature très sélectif. Juge, procureur ou juge d'instruction.",
      niveauEntree: 'Master + concours magistrature',
      evolution: "Juge suppléant → juge de paix → président tribunal.",
      salaireDebut: 400000,
      salaireSenior: 1500000,
      competencesCles: ['Équité', 'Rigueur', 'Écriture', 'Indépendance'],
      secteurs: ['Public'],
      demandeMarche: 3,
      potentielInternational: 'faible',
      tendance: 'stable',
    ),
    // ── Économie / Gestion ──────────────────────────────────────────
    CareerPath(
      id: 'analyste_financier',
      filiereId: 'economie_gestion',
      titre: 'Analyste financier',
      description:
          "Analyse les performances financières d'entreprises, "
          "évalue les risques et propose des recommandations "
          "d'investissement. Secteur banque en croissance.",
      niveauEntree: 'Master finance + certification (CFA level 1)',
      evolution: "Analyste → senior analyst → directeur financier.",
      salaireDebut: 400000,
      salaireSenior: 1800000,
      competencesCles: ['Excel', 'Modélisation', 'États financiers', 'Anglais'],
      secteurs: ['Banque', 'Bourse', 'Consulting'],
      demandeMarche: 4,
      potentielInternational: 'fort',
      tendance: 'en croissance',
    ),
    CareerPath(
      id: 'auditeur',
      filiereId: 'economie_gestion',
      titre: 'Auditeur / Contrôleur de gestion',
      description:
          "Vérifie la fiabilité des comptes, identifie les risques et "
          "propose des améliorations. Secteur réglementé (BCEAO, OHADA).",
      niveauEntree: 'Master + DECF ou DEC',
      evolution: "Auditeur junior → senior → associé / DAF.",
      salaireDebut: 350000,
      salaireSenior: 1500000,
      competencesCles: ['Normes audit', 'Rigueur', 'Esprit critique', 'Éthique'],
      secteurs: ['Cabinets audit', 'Banque', 'Grandes entreprises'],
      demandeMarche: 4,
      potentielInternational: 'fort',
      tendance: 'en croissance',
    ),
    CareerPath(
      id: 'manager_projet',
      filiereId: 'economie_gestion',
      titre: 'Chef de projet',
      description:
          "Pilote des projets stratégiques (digital, infrastructure, "
          "transformation). Coordonne des équipes pluridisciplinaires.",
      niveauEntree: 'Master + certification PMP (optionnel)',
      evolution: "Chef de projet → program manager → directeur opérations.",
      salaireDebut: 350000,
      salaireSenior: 1500000,
      competencesCles: ['Pilotage', 'Leadership', 'Communication', 'Agilité'],
      secteurs: ['Banque', 'ONG', 'Télécoms', 'Public'],
      demandeMarche: 5,
      potentielInternational: 'fort',
      tendance: 'en croissance',
    ),
    // ── Agronomie ───────────────────────────────────────────────────
    CareerPath(
      id: 'ing_agra',
      filiereId: 'agronomie',
      titre: 'Ingénieur agronome',
      description:
          "Conçoit et met en œuvre des systèmes agricoles productifs "
          "et durables. Travaille avec les coopératives et les ONG.",
      niveauEntree: 'Diplôme d\'ingénieur agronome',
      evolution: "Ingénieur terrain → chef de projet → directeur technique.",
      salaireDebut: 250000,
      salaireSenior: 1000000,
      competencesCles: ['Agronomie', 'Pédologie', 'Gestion', 'Innovation'],
      secteurs: ['Coopératives', 'ONG', 'Public', 'Privé'],
      demandeMarche: 4,
      potentielInternational: 'moyen',
      tendance: 'en croissance',
    ),
    CareerPath(
      id: 'conseiller_agricole',
      filiereId: 'agronomie',
      titre: 'Conseiller agricole / Vulgarisateur',
      description:
          "Accompagne les agriculteurs pour améliorer leurs pratiques : "
          "semences, irrigation, lutte contre les ravageurs, accès au marché.",
      niveauEntree: 'BTS agricole ou ingénieur',
      evolution: "Conseiller → superviseur → directeur régional ICAT.",
      salaireDebut: 180000,
      salaireSenior: 600000,
      competencesCles: ['Pédagogie', 'Écoute', 'Connaissances techniques'],
      secteurs: ['Public (ICAT)', 'ONG', 'Coopératives'],
      demandeMarche: 4,
      potentielInternational: 'faible',
      tendance: 'en croissance',
    ),
    // ── Lettres ─────────────────────────────────────────────────────
    CareerPath(
      id: 'prof_lettres',
      filiereId: 'lettres',
      titre: 'Professeur de lettres',
      description:
          "Enseigne le français, la littérature et les langues en collège "
          "et lycée. Métier stable, accessible via l'ENS ou l'agrégation.",
      niveauEntree: 'Master + CAPES ou CAPE',
      evolution: "Professeur → agrégé → inspecteur pédagogique.",
      salaireDebut: 180000,
      salaireSenior: 600000,
      competencesCles: ['Pédagogie', 'Maîtrise français', 'Culture littéraire'],
      secteurs: ['Public', 'Privé'],
      demandeMarche: 4,
      potentielInternational: 'faible',
      tendance: 'stable',
    ),
    CareerPath(
      id: 'traducteur',
      filiereId: 'lettres',
      titre: 'Traducteur / Interprète',
      description:
          "Traduit documents et interprète lors de conférences. "
          "Anglais-français surtout, avec opportunités à la CEDEAO "
          "et à l'ONU.",
      niveauEntree: 'Master traduction / interprétation',
      evolution: "Traducteur freelance → chef de projet → interprète de conférence.",
      salaireDebut: 200000,
      salaireSenior: 900000,
      competencesCles: ['Bilingue', 'Concentration', 'Culture générale'],
      secteurs: ['International', 'ONG', 'Institutions', 'Freelance'],
      demandeMarche: 3,
      potentielInternational: 'fort',
      tendance: 'en croissance',
    ),
    // ── Sciences ────────────────────────────────────────────────────
    CareerPath(
      id: 'chercheur',
      filiereId: 'sciences',
      titre: 'Chercheur universitaire',
      description:
          "Mène des recherches fondamentales ou appliquées, publie, "
          "enseigne à l'université. Doctorat indispensable.",
      niveauEntree: 'Doctorat (PhD)',
      evolution: "Doctorant → maître de conférences → professeur titulaire.",
      salaireDebut: 250000,
      salaireSenior: 900000,
      competencesCles: ['Méthode scientifique', 'Publication', 'Veille', 'Anglais'],
      secteurs: ['Universités', 'Instituts de recherche', 'International'],
      demandeMarche: 2,
      potentielInternational: 'fort',
      tendance: 'stable',
    ),
    CareerPath(
      id: 'prof_sciences',
      filiereId: 'sciences',
      titre: 'Professeur de sciences',
      description:
          "Enseigne maths, physique-chimie ou SVT en collège et lycée. "
          "Filière ENS recommandée pour carrière publique.",
      niveauEntree: 'Master + CAPES',
      evolution: "Professeur → agrégé → inspecteur.",
      salaireDebut: 200000,
      salaireSenior: 700000,
      competencesCles: ['Pédagogie', 'Maîtrise matière', 'TP', 'Patience'],
      secteurs: ['Public', 'Privé'],
      demandeMarche: 4,
      potentielInternational: 'faible',
      tendance: 'stable',
    ),
    // ── Architecture ────────────────────────────────────────────────
    CareerPath(
      id: 'architecte',
      filiereId: 'architecture',
      titre: 'Architecte',
      description:
          "Conçoit des bâtiments (logements, équipements publics) en "
          "respectant l'esthétique, la fonctionnalité et la réglementation.",
      niveauEntree: 'Diplôme d\'architecte (DESA)',
      evolution: "Dessinateur → architecte associé → architecte en chef.",
      salaireDebut: 300000,
      salaireSenior: 1500000,
      competencesCles: ['Dessin', 'Logiciels 3D', 'Créativité', 'Technique'],
      secteurs: ['Cabinets privés', 'Maîtrise d\'œuvre', 'Libéral'],
      demandeMarche: 4,
      potentielInternational: 'moyen',
      tendance: 'en croissance',
    ),
    CareerPath(
      id: 'urbaniste',
      filiereId: 'architecture',
      titre: 'Urbaniste',
      description:
          "Planifie le développement des villes : zonage, transports, "
          "espaces verts. Travaille avec les collectivités locales.",
      niveauEntree: 'Master urbanisme ou architecte + spécialisation',
      evolution: "Chargé d'études → chef de projet → directeur urbanisme.",
      salaireDebut: 350000,
      salaireSenior: 1200000,
      competencesCles: ['Planification', 'SIG', 'Concertation', 'Vision'],
      secteurs: ['Public', 'Bureaux d\'études', 'ONG'],
      demandeMarche: 3,
      potentielInternational: 'moyen',
      tendance: 'en croissance',
    ),
    // ── Comptabilité / Finance ──────────────────────────────────────
    CareerPath(
      id: 'comptable',
      filiereId: 'comptabilite_finance',
      titre: 'Comptable',
      description:
          "Tient la comptabilité d'une entreprise : saisie, déclarations "
          "fiscales, états financiers. Métier stable et recherché.",
      niveauEntree: 'BTS comptabilité',
      evolution: "Comptable → chef comptable → DAF.",
      salaireDebut: 150000,
      salaireSenior: 700000,
      competencesCles: ['Rigueur', 'SYSCOHADA', 'Excel', 'Éthique'],
      secteurs: ['PME', 'Cabinets', 'ONG', 'Public'],
      demandeMarche: 5,
      potentielInternational: 'moyen',
      tendance: 'stable',
    ),
    CareerPath(
      id: 'expert_comptable',
      filiereId: 'comptabilite_finance',
      titre: 'Expert-comptable (DEC)',
      description:
          "Profession libérale qui certifie les comptes et conseille "
          "les dirigeants. Diplôme d'Expertise Comptable (DEC) requis.",
      niveauEntree: 'DEC (3 ans de stage + examen)',
      evolution: "Stagiaire → associé → président cabinet.",
      salaireDebut: 600000,
      salaireSenior: 2500000,
      competencesCles: ['Audit', 'Fiscalité', 'Conseil', 'Éthique'],
      secteurs: ['Cabinets', 'Libéral'],
      demandeMarche: 4,
      potentielInternational: 'moyen',
      tendance: 'en croissance',
    ),
    // ── Marketing / Communication ───────────────────────────────────
    CareerPath(
      id: 'chef_produit',
      filiereId: 'marketing_communication',
      titre: 'Chef de produit / Marketing manager',
      description:
          "Pilote le lancement et le développement d'un produit : "
          "études marché, positionnement, plan marketing, suivi des ventes.",
      niveauEntree: 'Bac+4/5 marketing',
      evolution: "Assistant marketing → chef de produit → directeur marketing.",
      salaireDebut: 250000,
      salaireSenior: 1500000,
      competencesCles: ['Stratégie', 'Analyse marché', 'Créativité', 'Agilité'],
      secteurs: ['FMCG', 'Banque', 'Télécoms'],
      demandeMarche: 4,
      potentielInternational: 'moyen',
      tendance: 'en croissance',
    ),
    CareerPath(
      id: 'community_manager',
      filiereId: 'marketing_communication',
      titre: 'Community manager / Social media manager',
      description:
          "Gère la présence d'une marque sur les réseaux sociaux : "
          "contenu, modération, campagnes payantes. Métier jeune et accessible.",
      niveauEntree: 'BTS communication / autodidacte + portfolio',
      evolution: "CM → social media manager → directeur digital.",
      salaireDebut: 150000,
      salaireSenior: 800000,
      competencesCles: ['Créativité', 'Réseaux sociaux', 'Analytics', 'Écriture'],
      secteurs: ['Agences', 'Entreprises', 'Freelance'],
      demandeMarche: 5,
      potentielInternational: 'fort',
      tendance: 'en croissance',
    ),
    // ── Soins infirmiers ────────────────────────────────────────────
    CareerPath(
      id: 'infirmier_ide',
      filiereId: 'soins_infirmiers',
      titre: 'Infirmier diplômé d\'État (IDE)',
      description:
          "Dispense des soins aux patients à l'hôpital, en clinique "
          "ou à domicile. Administration des traitements, éducation "
          "à la santé.",
      niveauEntree: 'Diplôme d\'État Infirmier (3 ans)',
      evolution: "Infirmier → surveillant → directeur soins.",
      salaireDebut: 150000,
      salaireSenior: 500000,
      competencesCles: ['Soins techniques', 'Empathie', 'Rigueur', 'Résistance'],
      secteurs: ['Public', 'Privé', 'ONG', 'Libéral'],
      demandeMarche: 5,
      potentielInternational: 'fort',
      tendance: 'en croissance',
    ),
    CareerPath(
      id: 'infirmier_specialise',
      filiereId: 'soins_infirmiers',
      titre: 'Infirmier spécialisé (IBODE, puériculture)',
      description:
          "Spécialité bloc opératoire (IBODE), pédiatrie ou santé "
          "communautaire. Formation complémentaire de 1-2 ans après l'IDE.",
      niveauEntree: 'IDE + spécialisation (1-2 ans)',
      evolution: "Infirmier spécialisé → cadre de santé → formateur.",
      salaireDebut: 250000,
      salaireSenior: 700000,
      competencesCles: ['Spécialité', 'Encadrement', 'Évaluation'],
      secteurs: ['Public', 'Privé'],
      demandeMarche: 4,
      potentielInternational: 'moyen',
      tendance: 'en croissance',
    ),
    // ── Enseignement ────────────────────────────────────────────────
    CareerPath(
      id: 'prof_lycee',
      filiereId: 'enseignement',
      titre: 'Professeur de lycée',
      description:
          "Enseigne sa matière de spécialité en lycée. Passe par l'ENS "
          "puis le concours du CAPES. Carrière stable dans la fonction publique.",
      niveauEntree: 'ENS ou Master + CAPES',
      evolution: "Professeur → agrégé → chef d\'établissement.",
      salaireDebut: 180000,
      salaireSenior: 700000,
      competencesCles: ['Pédagogie', 'Maîtrise matière', 'Autorité', 'Patience'],
      secteurs: ['Public', 'Privé'],
      demandeMarche: 4,
      potentielInternational: 'faible',
      tendance: 'stable',
    ),
    CareerPath(
      id: 'inspecteur_educ',
      filiereId: 'enseignement',
      titre: 'Inspecteur pédagogique',
      description:
          "Contrôle et accompagne les enseignants d'une discipline "
          "dans une région. Carrière confirmée après 15+ ans d'enseignement.",
      niveauEntree: 'Agrégation + expérience',
      evolution: "Enseignant → conseiller pédagogique → inspecteur.",
      salaireDebut: 400000,
      salaireSenior: 900000,
      competencesCles: ['Expertise pédagogique', 'Évaluation', 'Conseil'],
      secteurs: ['Public'],
      demandeMarche: 2,
      potentielInternational: 'faible',
      tendance: 'stable',
    ),
    // ── Journalisme ─────────────────────────────────────────────────
    CareerPath(
      id: 'journaliste',
      filiereId: 'journalisme',
      titre: 'Journaliste',
      description:
          "Informe le public sur l'actualité : politique, économie, "
          "société. Travaille en rédaction (presse, radio, TV, web).",
      niveauEntree: 'Licence / Master journalisme',
      evolution: "Stagiaire → rédacteur → rédacteur en chef.",
      salaireDebut: 150000,
      salaireSenior: 800000,
      competencesCles: ['Écriture', 'Curiosité', 'Esprit critique', 'Réseaux'],
      secteurs: ['Presse', 'Radio/TV', 'Web', 'Communication'],
      demandeMarche: 3,
      potentielInternational: 'moyen',
      tendance: 'en mutation',
    ),
    CareerPath(
      id: 'reporter',
      filiereId: 'journalisme',
      titre: 'Grand reporter / Correspondant',
      description:
          "Couvre l'actualité sur le terrain, parfois à l'étranger. "
          "Spécialité exigeante (zones de conflit, enquêtes).",
      niveauEntree: 'Master + spécialisation terrain',
      evolution: "Reporter → grand reporter → correspondant international.",
      salaireDebut: 250000,
      salaireSenior: 1200000,
      competencesCles: ['Enquête', 'Mobilité', 'Résistance', 'Langues'],
      secteurs: ['International', 'Agences', 'TV'],
      demandeMarche: 2,
      potentielInternational: 'fort',
      tendance: 'en mutation',
    ),
  ];

  // ═════════════════════════════════════════════════════════════════
  // MÉTHODES PUBLIQUES
  // ═════════════════════════════════════════════════════════════════

  /// Récupère une filière par ID.
  Filiere? getFiliereById(String id) {
    for (final f in filieres) {
      if (f.id == id) return f;
    }
    return null;
  }

  /// Récupère les career paths d'une filière.
  List<CareerPath> getCareersForFiliere(String filiereId) {
    return careerPaths.where((c) => c.filiereId == filiereId).toList();
  }

  /// Calcule le profil élève à partir des réponses au chat.
  ///
  /// [reponses] : Map<questionId, optionId>
  /// [matiereMaitrise] : Map<matiere, P(L) 0..1> (peut être vide)
  /// [niveauScolaire] : "3eme", "Terminale", etc.
  /// [serie] : "C", "D", "A", null pour BEPC
  OrientationProfile calculerProfil({
    required Map<String, String> reponses,
    Map<String, double> matiereMaitrise = const {},
    String niveauScolaire = 'Terminale',
    String? serie,
  }) {
    // ─── 1. Scores cumulés par axe ──────────────────────────────────
    final cumul = <String, double>{
      for (final a in OrientationAxes.all) a: 0.0,
    };
    final maxCumul = <String, double>{
      for (final a in OrientationAxes.all) a: 0.0,
    };

    for (final q in questions) {
      // Trouver l'option choisie
      final optionId = reponses[q.id];
      if (optionId == null) continue;
      final chosen = q.options.where((o) => o.id == optionId).firstOrNull;

      // Pour chaque axe : ajouter le poids choisi et le poids max possible
      for (final axe in OrientationAxes.all) {
        cumul[axe] = (cumul[axe] ?? 0) + (chosen?.weights[axe] ?? 0.0);
        // Max = max des poids de cet axe parmi toutes les options
        double maxOption = 0;
        for (final o in q.options) {
          final w = o.weights[axe] ?? 0.0;
          if (w > maxOption) maxOption = w;
        }
        maxCumul[axe] = (maxCumul[axe] ?? 0) + maxOption;
      }
    }

    // ─── 2. Normaliser 0..1 par axe (cumul / maxCumul) ──────────────
    final axes = <String, double>{};
    for (final axe in OrientationAxes.all) {
      final max = maxCumul[axe] ?? 1.0;
      if (max <= 0) {
        axes[axe] = 0.0;
      } else {
        axes[axe] = ((cumul[axe] ?? 0) / max).clamp(0.0, 1.0);
      }
    }

    // ─── 3. Archétype ───────────────────────────────────────────────
    final archetype = ArchetypeResolver.resolve(axes);

    return OrientationProfile(
      axes: axes,
      matiereMaitrise: Map<String, double>.from(matiereMaitrise),
      archetype: archetype.nom,
      archetypeDescription: archetype.description,
      niveauScolaire: niveauScolaire,
      serie: serie,
      genereLe: DateTime.now(),
    );
  }

  /// Calcule le % de match entre un profil et une filière.
  double calculerMatch(OrientationProfile profile, Filiere filiere) {
    // ─── Similarité cosinus entre vecteur axes ──────────────────────
    final studentVec = profile.axesVector;
    final filiereVec = filiere.poidsVector;

    final sim = _cosineSimilarity(studentVec, filiereVec);
    // Cosinus 0..1 (vecteurs positifs) — on le garde tel quel.

    // ─── Score matières ─────────────────────────────────────────────
    double scoreMatieres = _matriereDefaut;
    if (filiere.matieresPivots.isNotEmpty && profile.matiereMaitrise.isNotEmpty) {
      final valeurs = <double>[];
      for (final m in filiere.matieresPivots) {
        final p = profile.matiereMaitrise[m];
        if (p != null) valeurs.add(p);
      }
      if (valeurs.isNotEmpty) {
        scoreMatieres =
            valeurs.reduce((a, b) => a + b) / valeurs.length;
      }
    }

    // ─── Combinaison pondérée ──────────────────────────────────────
    double match = (_poidsSimilarite * sim + _poidsMatieres * scoreMatieres) * 100;

    // ─── Pénalité filières sélectives si axes faibles ───────────────
    if (filiere.selective) {
      final axesForts = filiere.poidsAxes.entries
          .where((e) => e.value >= 0.20)
          .map((e) => e.key)
          .toList();
      final avgStudent = axesForts.isEmpty
          ? 0.0
          : axesForts
              .map((a) => profile.axes[a] ?? 0.0)
              .reduce((a, b) => a + b) /
              axesForts.length;
      if (avgStudent < _seuilAxesFortsSelectives) {
        final penalty = _penaliteSelective *
            (1 - avgStudent / _seuilAxesFortsSelectives);
        match -= penalty;
      }
    }

    return match.clamp(0, 100);
  }

  /// Génère les raisons principales du match (max 3).
  List<String> _genereRaisons(OrientationProfile profile, Filiere filiere) {
    final raisons = <String>[];
    final axeDominant = profile.axeDominant;
    if (axeDominant != null && filiere.isAxeFort(axeDominant)) {
      raisons.add(
          'Ton profil "${OrientationAxes.labels[axeDominant]}" correspond aux '
          'forces attendues en ${filiere.nomCourt}.');
    }

    // Matières maîtrisées alignées avec les matières pivots
    if (profile.matiereMaitrise.isNotEmpty) {
      final matieresAlignees = <String>[];
      for (final m in filiere.matieresPivots) {
        final p = profile.matiereMaitrise[m];
        if (p != null && p >= 0.65) {
          matieresAlignees.add(m);
        }
      }
      if (matieresAlignees.isNotEmpty) {
        raisons.add(
            'Tu maîtrises bien ${matieresAlignees.take(2).join(' et ')}, '
            'matières clés de cette filière.');
      }
    }

    // Série BAC alignée
    if (profile.serie != null && filiere.seriesRecommandees.isNotEmpty) {
      if (filiere.seriesRecommandees.contains(profile.serie)) {
        raisons.add(
            'Ta série ${profile.serie} est recommandée pour ${filiere.nomCourt}.');
      }
    }

    if (raisons.isEmpty) {
      raisons.add('Cette filière offre un débouché naturel à ton profil.');
    }
    return raisons.take(3).toList();
  }

  /// Génère le top 5 des filières recommandées pour le profil.
  ///
  /// Tri décroissant par % match. Chaque recommandation inclut les
  /// career paths associées (résolues via [getCareersForFiliere]).
  List<FiliereRecommendation> recommander(
    OrientationProfile profile, {
    int topN = 5,
  }) {
    final all = <FiliereRecommendation>[];
    for (final f in filieres) {
      final match = calculerMatch(profile, f);
      all.add(FiliereRecommendation(
        filiere: f,
        matchPercent: match,
        careers: getCareersForFiliere(f.id),
        raisons: _genereRaisons(profile, f),
      ));
    }
    all.sort((a, b) => b.matchPercent.compareTo(a.matchPercent));
    return all.take(topN).toList();
  }

  // ─── Helpers mathématiques ────────────────────────────────────────

  static double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length || a.isEmpty) return 0.0;
    double dot = 0;
    double normA = 0;
    double normB = 0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    if (normA == 0 || normB == 0) return 0.0;
    return dot / (math.sqrt(normA) * math.sqrt(normB));
  }
}
