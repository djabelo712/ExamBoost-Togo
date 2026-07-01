// test/helpers/test_data.dart
// 10 sample questions covering all types/examens/series in the dataset.
//
// Used by widget + integration tests to inject predictable data without
// depending on the bundled assets/data/questions.json (which could evolve).

import 'package:examboost_togo/models/question.dart';
import 'package:examboost_togo/models/review_card.dart';
import 'package:examboost_togo/models/user.dart';

/// 10 sample questions covering all combinations in the dataset.
///
/// Distribution:
///   - Examens: BEPC (6), BAC1 (4)
///   - Matières: Mathématiques (3), Français (2), Sciences Physiques (2),
///               Histoire-Géographie (1), Anglais (1), SVT (1)
///   - Series: null (BEPC), C (2), D (2) for BAC1
///   - Types: calcul, ouvert, qcm, vraiFaux, redaction
///   - Difficulties: facile (irtB < -0.5), moyen (-0.5 ≤ b < 0.8),
///                   difficile (b ≥ 0.8)
final List<Question> sampleQuestions = <Question>[
  // 1. BEPC Maths — facile
  Question(
    id: 'TG-BEPC-MATHS-2022-Q01',
    enonce: "Résoudre l'équation : 3x + 7 = 22",
    reponse: 'x = 5',
    explication: '3x = 15 puis x = 5.',
    matiere: 'Mathématiques',
    chapitre: 'Équations du premier degré',
    competenceId: 'TG-MATHS-EQ1D-001',
    examen: 'BEPC',
    annee: 2022,
    type: QuestionType.calcul,
    points: 4,
    irtB: -0.5,
  ),
  // 2. BEPC Maths — moyen
  Question(
    id: 'TG-BEPC-MATHS-2021-Q02',
    enonce: "Calculer l'aire d'un triangle rectangle de côtés 6 cm et 8 cm.",
    reponse: '24 cm²',
    explication: 'Aire = (6 × 8) / 2 = 24 cm².',
    matiere: 'Mathématiques',
    chapitre: 'Géométrie plane — Triangles',
    competenceId: 'TG-MATHS-GEO-001',
    examen: 'BEPC',
    annee: 2021,
    type: QuestionType.calcul,
    points: 3,
    irtB: -0.3,
  ),
  // 3. BEPC Maths — difficile (QCM)
  Question(
    id: 'TG-BEPC-MATHS-2020-Q03',
    enonce: 'Quel est le PGCD de 24 et 36 ?',
    reponse: '12',
    explication: '24 = 2³ × 3, 36 = 2² × 3². PGCD = 2² × 3 = 12.',
    matiere: 'Mathématiques',
    chapitre: 'Nombres premiers — PGCD',
    competenceId: 'TG-MATHS-PGCD-001',
    examen: 'BEPC',
    annee: 2020,
    type: QuestionType.qcm,
    choix: const ['6', '8', '12', '24'],
    points: 2,
    irtB: 0.9,
  ),
  // 4. BEPC Français — moyen
  Question(
    id: 'TG-BEPC-FR-2022-Q01',
    enonce: 'Identifiez la figure de style : "Ses yeux sont deux étoiles."',
    reponse: 'Métaphore',
    explication: 'Comparaison sans mot-outil.',
    matiere: 'Français',
    chapitre: 'Figures de style',
    competenceId: 'TG-FR-STYLE-001',
    examen: 'BEPC',
    annee: 2022,
    type: QuestionType.ouvert,
    points: 3,
    irtB: 0.1,
  ),
  // 5. BEPC Français — facile (vraiFaux)
  Question(
    id: 'TG-BEPC-FR-2021-Q02',
    enonce: 'Le conditionnel présent se forme avec le radical du futur + les terminaisons de l\'imparfait.',
    reponse: 'Vrai',
    explication: 'Radical du futur + -ais/-ais/-ait/-ions/-iez/-aient.',
    matiere: 'Français',
    chapitre: 'Conjugaison',
    competenceId: 'TG-FR-CONJ-001',
    examen: 'BEPC',
    annee: 2021,
    type: QuestionType.vraiFaux,
    points: 2,
    irtB: -0.6,
  ),
  // 6. BEPC Sciences Physiques — moyen
  Question(
    id: 'TG-BEPC-PHYS-2022-Q01',
    enonce: "Énoncer la loi d'Ohm.",
    reponse: 'U = R × I',
    explication: 'Tension = Résistance × Intensité.',
    matiere: 'Sciences Physiques',
    chapitre: 'Électricité',
    competenceId: 'TG-PHYS-OHM-001',
    examen: 'BEPC',
    annee: 2022,
    type: QuestionType.ouvert,
    points: 3,
    irtB: 0.0,
  ),
  // 7. BEPC Histoire-Géo — moyen (rédaction)
  Question(
    id: 'TG-BEPC-HG-2022-Q01',
    enonce: 'Décris les causes de la première guerre mondiale.',
    reponse: 'Voir grille de correction.',
    explication: 'Causes économiques, politiques, nationalistes.',
    matiere: 'Histoire-Géographie',
    chapitre: 'Le monde au XXe siècle',
    competenceId: 'TG-HG-GM1-001',
    examen: 'BEPC',
    annee: 2022,
    type: QuestionType.redaction,
    points: 6,
    irtB: 0.2,
  ),
  // 8. BAC1 Série C Maths — difficile
  Question(
    id: 'TG-BAC1-MATHS-2022-C-Q01',
    enonce: 'Résoudre dans ℂ : z² + 2z + 5 = 0',
    reponse: 'z = -1 ± 2i',
    explication: 'Δ = 4 - 20 = -16, √Δ = 4i, z = (-2 ± 4i)/2 = -1 ± 2i.',
    matiere: 'Mathématiques',
    chapitre: 'Nombres complexes',
    competenceId: 'TG-MATHS-CPLX-001',
    examen: 'BAC1',
    serie: 'C',
    annee: 2022,
    type: QuestionType.calcul,
    points: 5,
    irtB: 1.2,
  ),
  // 9. BAC1 Série C Physique — moyen
  Question(
    id: 'TG-BAC1-PHYS-2022-C-Q01',
    enonce: 'Définir l\'énergie mécanique d\'un système.',
    reponse: 'Em = Ec + Epp',
    explication: 'Somme de l\'énergie cinétique et potentielle.',
    matiere: 'Sciences Physiques',
    chapitre: 'Mécanique',
    competenceId: 'TG-PHYS-MEC-001',
    examen: 'BAC1',
    serie: 'C',
    annee: 2022,
    type: QuestionType.ouvert,
    points: 3,
    irtB: 0.4,
  ),
  // 10. BAC1 Série D SVT — moyen
  Question(
    id: 'TG-BAC1-SVT-2022-D-Q01',
    enonce: 'Quelle est la fonction des globules rouges ?',
    reponse: 'Transport des gaz (O₂, CO₂)',
    explication: 'Hémoglobine fixe l\'O₂ et le CO₂.',
    matiere: 'Sciences de la Vie et de la Terre',
    chapitre: 'Sang et circulation',
    competenceId: 'TG-SVT-SANG-001',
    examen: 'BAC1',
    serie: 'D',
    annee: 2022,
    type: QuestionType.qcm,
    choix: const [
      'Transport des gaz',
      'Coagulation',
      'Immunité',
      'Digestion',
    ],
    points: 2,
    irtB: 0.0,
  ),
];

/// Convenience: a single user with 3 competences at varied mastery levels.
final Map<String, double> sampleBktMaitrise = <String, double>{
  'TG-MATHS-EQ1D-001': 0.10, // Not mastered
  'TG-MATHS-GEO-001': 0.50, // In progress
  'TG-FR-STYLE-001': 0.90, // Mastered
  'TG-PHYS-OHM-001': 0.85, // Just mastered (threshold)
};

/// Convenience: 5 questions all in 'Mathématiques' for revision screen tests.
List<Question> get mathsQuestions => sampleQuestions
    .where((q) => q.matiere == 'Mathématiques')
    .toList(growable: false);

// ─── Mock review cards (SM-2 state samples) ─────────────────────────
//
// Three ReviewCard instances at different SM-2 states, useful for testing
// SRS sorting / due-list logic without running through a full applyReview
// sequence. Each card belongs to a different question to avoid key clashes.

/// A brand new card — never reviewed, due immediately.
ReviewCard get sampleNewCard => ReviewCard(
      userId: 'test-user',
      questionId: sampleQuestions[0].id,
    );

/// A card the student has answered correctly twice — interval = 6 days,
/// not due yet.
ReviewCard get sampleLearningCard => ReviewCard(
      userId: 'test-user',
      questionId: sampleQuestions[1].id,
      repetitions: 2,
      easinessFactor: 2.6,
      intervalDays: 6,
      nextReviewDate: DateTime.now().add(const Duration(days: 6)),
      lastReviewDate: DateTime.now().subtract(const Duration(days: 1)),
      totalAttempts: 2,
      correctAttempts: 2,
      isLearning: false,
    );

/// A card the student failed — back to learning state, due immediately.
ReviewCard get sampleFailedCard => ReviewCard(
      userId: 'test-user',
      questionId: sampleQuestions[2].id,
      repetitions: 0,
      easinessFactor: 2.2,
      intervalDays: 1,
      nextReviewDate: DateTime.now().subtract(const Duration(hours: 2)),
      lastReviewDate: DateTime.now().subtract(const Duration(hours: 2)),
      totalAttempts: 4,
      correctAttempts: 2,
      isLearning: true,
    );

/// All three sample cards together.
List<ReviewCard> get sampleReviewCards => <ReviewCard>[
      sampleNewCard,
      sampleLearningCard,
      sampleFailedCard,
    ];

// ─── Mock AppUser (BKT state samples) ───────────────────────────────

/// Build a mock AppUser whose `bktMaitrise` map matches [sampleBktMaitrise].
///
/// Tests that need a fresh user (e.g. BKT algorithm tests) should call
/// this rather than mutating a shared instance.
AppUser createMockUser({
  String id = 'test-user',
  String nom = 'Doe',
  String prenom = 'Jane',
  String niveauScolaire = '3eme',
  String? serie,
  Map<String, double>? bktMaitrise,
  double? thetaIrt,
}) {
  return AppUser(
    id: id,
    nom: nom,
    prenom: prenom,
    niveauScolaire: niveauScolaire,
    serie: serie,
    dateInscription: DateTime(2026, 1, 1),
    bktMaitrise: bktMaitrise ?? Map<String, double>.from(sampleBktMaitrise),
    thetaIrt: thetaIrt,
  );
}

/// A single ready-to-use mock user with the 4-competence BKT state.
AppUser get sampleUser => createMockUser();
