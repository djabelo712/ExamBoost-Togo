// lib/screens/contest/services/contest_service.dart
// Service central du module Concours inter-ecoles.
//
// Responsabilites :
//   - Construire et exposer le concours mensuel en cours (Contest).
//   - Maintenir le classement des 50 ecoles togolaises participantes,
//     triable par scope (national / regional).
//   - Exposer le classement de "mon ecole" (mock : Lycee de Tokoin).
//   - Exposer la synthese de la contribution de l'eleve courant.
//   - Fournir l'historique des concours passes (6 derniers mois).
//   - Calculer les rangs nationaux et regionaux a partir des points.
//
// Le service est un ChangeNotifier : il notifie ses listeners apres
// load(), refresh() ou addContribution(). Il est concu pour etre branche
// sur un ChangeNotifierProvider (au niveau du ContestHomeScreen, sans
// toucher a main.dart).
//
// Toutes les donnees sont generees de facon deterministe (Random(seed)
// fixe) pour assurer la stabilite entre les rebuilds. En production,
// chaque getter sera remplace par un appel a un backend FastAPI
// (/api/contests/current, /api/schools/ranking, etc.).
//
// Mecanique des points (cahier des charges) :
//   - Question correcte        : +10  pts pour l'ecole
//   - Simulation reussie (>10/20) : +50  pts
//   - Badge debloque           : +100 pts
//   - Streak 7 jours           : +200 pts bonus

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/contest.dart';
import '../models/contest_contribution.dart';
import '../models/school_ranking.dart';

/// Scope du classement demande.
enum RankingScope {
  /// Classement toutes regions confondues.
  national,

  /// Classement filtre sur une region.
  regional,
}

/// Service du module Concours inter-ecoles.
///
/// ChangeNotifier pour etre consomme via Provider dans l'arbre de widgets.
class ContestService extends ChangeNotifier {
  ContestService();

  // ─── Etat interne ──────────────────────────────────────────────────

  bool _isLoading = false;
  DateTime? _lastRefresh;

  Contest? _currentContest;
  List<SchoolRanking> _allSchools = const [];
  MyContributionSummary? _myContribution;
  List<Contest> _pastContests = const [];

  // Identifiant de "mon ecole" (mock). En production, recupere depuis
  // le UserProvider (appUser.ecoleId).
  static const String _monEcoleId = 'lycee-tokoin';
  static const String _monEcoleNom = 'Lycee de Tokoin';
  static const String _maRegion = 'Lome';

  // ─── Getters publics ───────────────────────────────────────────────

  /// Vrai si un chargement (initial ou refresh) est en cours.
  bool get isLoading => _isLoading;

  /// Date/heure du dernier refresh reussi (null si jamais charge).
  DateTime? get lastRefresh => _lastRefresh;

  /// Le concours en cours (null si jamais charge).
  Contest? get currentContest => _currentContest;

  /// Mon ecole (null si jamais charge).
  SchoolRanking? get mySchool =>
      _allSchools.where((s) => s.id == _monEcoleId).firstOrNull;

  /// Synthese de ma contribution (null si jamais charge).
  MyContributionSummary? get myContribution => _myContribution;

  /// Liste des concours passes (6 derniers), triee par date desc.
  List<Contest> get pastContests => List.unmodifiable(_pastContests);

  // ─── Methodes publiques ────────────────────────────────────────────

  /// Charge les donnees initiales (mock). Idempotent.
  /// En production, cette methode fera les appels reseau necessaires.
  Future<void> load() async {
    if (_currentContest != null) return; // deja charge
    _isLoading = true;
    notifyListeners();

    // Simule un delai reseau court.
    await Future.delayed(const Duration(milliseconds: 350));

    _allSchools = _generateAllSchools();
    _currentContest = _generateCurrentContest(_allSchools);
    _pastContests = _generatePastContests();
    _myContribution = _generateMyContribution();

    _isLoading = false;
    _lastRefresh = DateTime.now();
    notifyListeners();
  }

  /// Simule un refresh (re-tirage des variations de rang, maj des points).
  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));

    // On regenere les variations de rang et on ajoute quelques points
    // aleatoires au total actuel du concours pour simuler l'activite.
    final rand = Random(DateTime.now().millisecondsSinceEpoch % 100000);
    _allSchools =
        _allSchools.map((s) {
          // Variation de rang entre -3 et +3.
          final variation = rand.nextInt(7) - 3;
          // Petite variation de points (+0 a +80).
          final deltaPts = rand.nextInt(80);
          return s.copyWith(
            points: s.points + deltaPts,
            variationRang: variation,
          );
        }).toList();
    // Recalcul des rangs apres maj des points.
    _allSchools = _recalculerRangs(_allSchools);

    // Maj du concours courant (points collectifs legerement augmentes).
    if (_currentContest != null) {
      final gain = 200 + rand.nextInt(800);
      _currentContest = _currentContest!.copyWith(
        pointsActuels: _currentContest!.pointsActuels + gain,
      );
    }

    _lastRefresh = DateTime.now();
    _isLoading = false;
    notifyListeners();
  }

  /// Retourne le classement demande, trie par points decroissants.
  ///
  /// [scope] = national : toutes regions confondues, limite a [limit]
  ///   resultats (defaut 50).
  /// [scope] = regional : filtre sur [region], limite a [limit] resultats.
  ///
  /// [region] est ignore si scope == national.
  List<SchoolRanking> getRanking({
    RankingScope scope = RankingScope.national,
    String? region,
    int limit = 50,
  }) {
    final liste =
        scope == RankingScope.regional
            ? _allSchools.where((s) => s.region == region).toList()
            : List<SchoolRanking>.of(_allSchools);
    liste.sort((a, b) => b.points.compareTo(a.points));
    return liste.take(limit).toList(growable: false);
  }

  /// Retourne le top 3 national (podium).
  List<SchoolRanking> getPodiumNational() => getRanking(limit: 3);

  /// Retourne le top 3 regional pour une region donnee.
  List<SchoolRanking> getPodiumRegional(String region) =>
      getRanking(scope: RankingScope.regional, region: region, limit: 3);

  /// Retourne les ecoles d'une region donnee, triees par points desc.
  List<SchoolRanking> getSchoolsByRegion(String region) =>
      getRanking(scope: RankingScope.regional, region: region, limit: 50);

  /// Retourne les regions qui ont au moins une ecole participante.
  /// (Toujours les 6 regions du Togo en mock, mais la methode reste
  /// utile pour filtrer dynamiquement en production.)
  List<String> getRegionsParticipants() {
    final set = <String>{};
    for (final s in _allSchools) {
      set.add(s.region);
    }
    return set.toList()..sort();
  }

  /// Retourne un concours passe par son id (null si introuvable).
  Contest? getPastContestById(String contestId) {
    for (final c in _pastContests) {
      if (c.id == contestId) return c;
    }
    return null;
  }

  /// Ajoute une contribution a ma synthese (mock : met a jour l'etat
  /// local sans persistance). Notifie les listeners.
  void addContribution(ContestContribution contribution) {
    if (_myContribution == null) return;

    final nouveauTotal = _myContribution!.pointsTotaux + contribution.points;
    final nouvellesRecentes = [
      contribution,
      ..._myContribution!.recentes,
    ].take(20).toList(growable: false);

    // Maj des compteurs selon le type.
    int nbQ = _myContribution!.nbQuestions;
    int nbS = _myContribution!.nbSimulations;
    int nbB = _myContribution!.nbBadges;
    int nbSt = _myContribution!.nbBonusStreak;
    switch (contribution.type) {
      case ContributionType.question:
        nbQ += 1;
        break;
      case ContributionType.simulation:
        nbS += 1;
        break;
      case ContributionType.badge:
        nbB += 1;
        break;
      case ContributionType.streakBonus:
        nbSt += 1;
        break;
    }

    _myContribution = _myContribution!.copyWith(
      pointsTotaux: nouveauTotal,
      nbQuestions: nbQ,
      nbSimulations: nbS,
      nbBadges: nbB,
      nbBonusStreak: nbSt,
      recentes: nouvellesRecentes,
    );

    // Maj du concours courant (points collectifs).
    if (_currentContest != null) {
      _currentContest = _currentContest!.copyWith(
        pointsActuels: _currentContest!.pointsActuels + contribution.points,
      );
    }

    // Maj de mon ecole (points + recap rangs).
    final monEcole = mySchool;
    if (monEcole != null) {
      final updated = monEcole.copyWith(points: monEcole.points + contribution.points);
      _allSchools = _allSchools.map((s) => s.id == updated.id ? updated : s).toList();
      _allSchools = _recalculerRangs(_allSchools);
    }

    notifyListeners();
  }

  // ─── Generation des donnees mock ──────────────────────────────────

  /// Genere la liste des 50 ecoles togolaises avec points aleatoires
  /// et trophees tires des 6 derniers mois.
  ///
  /// Les points sont tires entre 500 et 5000 (cahier des charges).
  /// Les trophees sont distribues sur les concours passes : seules les
  /// 3 meilleures ecoles de chaque mois recoivent un trophee.
  static List<SchoolRanking> _generateAllSchools() {
    final rand = Random(2026);
    final ecoles = <SchoolRanking>[];

    // Generation des trophees par concours passe (3 tiers par concours).
    // On tire 3 ecoles differentes par concours comme gagnantes.
    final pastContestIds = [
      'contest-2025-09',
      'contest-2025-10',
      'contest-2025-11',
      'contest-2025-12',
      'contest-2026-01',
      'contest-2026-02',
    ];
    final pastContestTitres = [
      'Rentree Sciences 2025',
      'Histoire-Geo Octobre 2025',
      'Philo Novembre 2025',
      'Anglais Decembre 2025',
      'SVT Janvier 2026',
      'Physique Fevrier 2026',
    ];
    final pastContestDates = [
      DateTime(2025, 9, 30),
      DateTime(2025, 10, 31),
      DateTime(2025, 11, 30),
      DateTime(2025, 12, 31),
      DateTime(2026, 1, 31),
      DateTime(2026, 2, 28),
    ];

    // Map ecoleId -> liste trophees
    final tropheesParEcole = <String, List<ContestTrophy>>{};

    for (int i = 0; i < pastContestIds.length; i++) {
      // On tire 3 indices d'ecoles distinctes.
      final gagnants = <int>{};
      while (gagnants.length < 3) {
        gagnants.add(rand.nextInt(kLyceesTogo.length));
      }
      final gagnantsList = gagnants.toList();
      for (int tier = 0; tier < 3; tier++) {
        final idx = gagnantsList[tier];
        final ecoleId = 'ecole_$idx';
        tropheesParEcole.putIfAbsent(ecoleId, () => []);
        tropheesParEcole[ecoleId]!.add(
          ContestTrophy(
            contestId: pastContestIds[i],
            contestTitre: pastContestTitres[i],
            tier: TrophyTier.values[tier],
            date: pastContestDates[i],
            pointsEcole: 3000 + rand.nextInt(2000),
          ),
        );
      }
    }

    // On force le Lycee de Tokoin (idx 0) a avoir au moins 2 trophees
    // pour rendre la "vitrine" interessante (mock).
    if (!tropheesParEcole.containsKey('ecole_0') ||
        tropheesParEcole['ecole_0']!.length < 2) {
      tropheesParEcole['ecole_0'] = [
        ContestTrophy(
          contestId: 'contest-2025-12',
          contestTitre: 'Anglais Decembre 2025',
          tier: TrophyTier.or,
          date: DateTime(2025, 12, 31),
          pointsEcole: 4820,
        ),
        ContestTrophy(
          contestId: 'contest-2026-01',
          contestTitre: 'SVT Janvier 2026',
          tier: TrophyTier.argent,
          date: DateTime(2026, 1, 31),
          pointsEcole: 4100,
        ),
        ContestTrophy(
          contestId: 'contest-2025-10',
          contestTitre: 'Histoire-Geo Octobre 2025',
          tier: TrophyTier.bronze,
          date: DateTime(2025, 10, 31),
          pointsEcole: 3850,
        ),
      ];
    }

    // Construction des 50 ecoles.
    for (int i = 0; i < kLyceesTogo.length; i++) {
      final entry = kLyceesTogo[i];
      final id = 'ecole_$i';
      final points = 500 + rand.nextInt(4501); // 500 a 5000
      final nbEleves = 20 + rand.nextInt(80); // 20 a 99 eleves actifs
      final contribution = (points / nbEleves).round();
      final variation = rand.nextInt(7) - 3; // -3 a +3

      ecoles.add(
        SchoolRanking(
          id: id,
          nom: entry.nom,
          region: entry.region,
          points: points,
          rangNational: 0, // calcule plus tard
          rangRegional: 0, // calcule plus tard
          nbElevesActifs: nbEleves,
          contributionMoyenne: contribution,
          variationRang: variation,
          trophees: tropheesParEcole[id] ?? const [],
        ),
      );
    }

    // On s'assure que le Lycee de Tokoin (idx 0) est dans le top 5
    // national pour rendre l'experience demo plus engageante.
    final tokoin = ecoles[0];
    final maxPoints = ecoles.map((e) => e.points).reduce(max);
    if (tokoin.points < maxPoints - 200) {
      ecoles[0] = tokoin.copyWith(points: maxPoints - 80 + rand.nextInt(160));
    }

    // Recalcul des rangs.
    return _recalculerRangs(ecoles);
  }

  /// Recalcule les rangs nationaux et regionaux a partir des points.
  static List<SchoolRanking> _recalculerRangs(List<SchoolRanking> ecoles) {
    // Rangs nationaux : tri par points desc, puis assignation 1..N.
    final parNational = List<SchoolRanking>.of(ecoles)
      ..sort((a, b) => b.points.compareTo(a.points));
    final rangNationalMap = <String, int>{};
    for (int i = 0; i < parNational.length; i++) {
      rangNationalMap[parNational[i].id] = i + 1;
    }

    // Rangs regionaux : groupement par region puis tri.
    final rangRegionalMap = <String, int>{};
    final parRegion = <String, List<SchoolRanking>>{};
    for (final e in ecoles) {
      parRegion.putIfAbsent(e.region, () => []).add(e);
    }
    for (final entry in parRegion.entries) {
      entry.value.sort((a, b) => b.points.compareTo(a.points));
      for (int i = 0; i < entry.value.length; i++) {
        rangRegionalMap[entry.value[i].id] = i + 1;
      }
    }

    return ecoles
        .map(
          (e) => e.copyWith(
            rangNational: rangNationalMap[e.id] ?? 0,
            rangRegional: rangRegionalMap[e.id] ?? 0,
          ),
        )
        .toList(growable: false);
  }

  /// Genere le concours mensuel en cours (Mars 2026 : Maths Mars).
  static Contest _generateCurrentContest(List<SchoolRanking> ecoles) {
    final now = DateTime(2026, 3, 15); // date de reference mock
    final debut = DateTime(2026, 3, 1);
    final fin = DateTime(2026, 3, 31, 23, 59, 59);

    final totalPoints =
        ecoles.map((e) => e.points).fold<int>(0, (a, b) => a + b);
    final totalEleves =
        ecoles.map((e) => e.nbElevesActifs).fold<int>(0, (a, b) => a + b);
    final objectif = 150000; // objectif collectif national

    return Contest(
      id: 'contest-2026-03',
      titre: 'Maths Mars 2026',
      matiere: 'Mathematiques',
      description:
          'Ce mois-ci, le concours met a l\'honneur les mathematiques. '
          'Chaque question de revision, simulation et badge debloque '
          'rapporte des points a ton etablissement. L\'ecole gagnante '
          'remportera la medaille d\'or et un trophee affiche dans sa '
          'vitrine pendant tout le mois d\'avril.',
      dateDebut: debut,
      dateFin: fin,
      status: ContestStatus.enCours,
      objectifCollectif: objectif,
      pointsActuels: totalPoints,
      nbEcolesParticipantes: ecoles.length,
      nbElevesActifs: totalEleves,
      recompenses: const [
        'Medaille d\'or pour l\'ecole 1ere (affichee en vitrine)',
        'Bonus de 500 pts pour tous les eleves de l\'ecole gagnante',
        'Badge collectif "Champion Maths Mars" pour les top 10 eleves',
        'Trophee permanent dans la vitrine de l\'ecole',
      ],
    );
  }

  /// Genere l'historique des 6 derniers concours (Sept 2025 a Fev 2026).
  /// Chaque concours passe est marque termine et a un gagnant.
  static List<Contest> _generatePastContests() {
    final rand = Random(73);
    return [
      _buildPastContest(
        id: 'contest-2026-02',
        titre: 'Physique Fevrier 2026',
        matiere: 'Physique-Chimie',
        annee: 2026,
        mois: 2,
        ecoleGagnanteId: 'ecole_3',
        ecoleGagnanteNom: 'Lycée de Bè',
        rand: rand,
      ),
      _buildPastContest(
        id: 'contest-2026-01',
        titre: 'SVT Janvier 2026',
        matiere: 'Sciences de la Vie et de la Terre',
        annee: 2026,
        mois: 1,
        ecoleGagnanteId: 'ecole_5',
        ecoleGagnanteNom: 'Lycée Notre Dame des Siens',
        rand: rand,
      ),
      _buildPastContest(
        id: 'contest-2025-12',
        titre: 'Anglais Decembre 2025',
        matiere: 'Anglais',
        annee: 2025,
        mois: 12,
        ecoleGagnanteId: 'ecole_0',
        ecoleGagnanteNom: 'Lycée de Tokoin',
        rand: rand,
      ),
      _buildPastContest(
        id: 'contest-2025-11',
        titre: 'Philo Novembre 2025',
        matiere: 'Philosophie',
        annee: 2025,
        mois: 11,
        ecoleGagnanteId: 'ecole_8',
        ecoleGagnanteNom: 'Lycée d\'Atakpamé',
        rand: rand,
      ),
      _buildPastContest(
        id: 'contest-2025-10',
        titre: 'Histoire-Geo Octobre 2025',
        matiere: 'Histoire-Geographie',
        annee: 2025,
        mois: 10,
        ecoleGagnanteId: 'ecole_12',
        ecoleGagnanteNom: 'Lycée de Sokodé',
        rand: rand,
      ),
      _buildPastContest(
        id: 'contest-2025-09',
        titre: 'Rentree Sciences 2025',
        matiere: 'Sciences (transversal)',
        annee: 2025,
        mois: 9,
        ecoleGagnanteId: 'ecole_0',
        ecoleGagnanteNom: 'Lycée de Tokoin',
        rand: rand,
      ),
    ];
  }

  /// Construit un concours passe avec trophees or/argent/bronze.
  static Contest _buildPastContest({
    required String id,
    required String titre,
    required String matiere,
    required int annee,
    required int mois,
    required String ecoleGagnanteId,
    required String ecoleGagnanteNom,
    required Random rand,
  }) {
    final debut = DateTime(annee, mois, 1);
    final fin = DateTime(annee, mois, _daysInMonth(annee, mois), 23, 59, 59);

    final objectif = 120000 + rand.nextInt(40000);
    final pointsFinaux = objectif - rand.nextInt(20000); // objectif atteint
    final nbEcoles = 45 + rand.nextInt(6);
    final nbEleves = 1800 + rand.nextInt(500);

    // Trophees : on prend l'ecole gagnante en or, et on en tire 2 autres
    // pour argent et bronze. Les noms sont approximatifs (mock).
    final trophees = <ContestTrophy>[];
    trophees.add(
      ContestTrophy(
        contestId: id,
        contestTitre: titre,
        tier: TrophyTier.or,
        date: fin,
        pointsEcole: 4500 + rand.nextInt(800),
      ),
    );
    trophees.add(
      ContestTrophy(
        contestId: id,
        contestTitre: titre,
        tier: TrophyTier.argent,
        date: fin,
        pointsEcole: 3800 + rand.nextInt(700),
      ),
    );
    trophees.add(
      ContestTrophy(
        contestId: id,
        contestTitre: titre,
        tier: TrophyTier.bronze,
        date: fin,
        pointsEcole: 3200 + rand.nextInt(600),
      ),
    );

    return Contest(
      id: id,
      titre: titre,
      matiere: matiere,
      description:
          'Concours thematique sur la matiere "$matiere". Ce concours '
          'est termine : l\'ecole gagnante a remporte la medaille d\'or '
          'et un trophee dans sa vitrine.',
      dateDebut: debut,
      dateFin: fin,
      status: ContestStatus.termine,
      objectifCollectif: objectif,
      pointsActuels: pointsFinaux,
      nbEcolesParticipantes: nbEcoles,
      nbElevesActifs: nbEleves,
      recompenses: const [
        'Medaille d\'or pour l\'ecole 1ere',
        'Bonus de 500 pts pour les eleves de l\'ecole gagnante',
        'Badge collectif pour les top 10 eleves contributeurs',
      ],
      trophees: trophees,
      ecoleGagnanteId: ecoleGagnanteId,
      ecoleGagnanteNom: ecoleGagnanteNom,
    );
  }

  /// Genere la synthese de la contribution de l'eleve courant (mock).
  /// Eleve : "Moi", ecole : Lycée de Tokoin, contest : Maths Mars 2026.
  static MyContributionSummary _generateMyContribution() {
    final rand = Random(2026);
    final maintenant = DateTime(2026, 3, 15, 14, 30);

    final nbQuestions = 42 + rand.nextInt(20); // 42 a 61
    final nbSimulations = 3 + rand.nextInt(4); // 3 a 6
    final nbBadges = 1 + rand.nextInt(3); // 1 a 3
    final nbBonusStreak = 2; // 2 bonus streak 7j ce mois-ci

    final pointsQuestions = nbQuestions * ContributionType.question.points;
    final pointsSimulations = nbSimulations * ContributionType.simulation.points;
    final pointsBadges = nbBadges * ContributionType.badge.points;
    final pointsStreak = nbBonusStreak * ContributionType.streakBonus.points;
    final total = pointsQuestions + pointsSimulations + pointsBadges + pointsStreak;

    // Contributions recentes (10 entrees).
    final recentes = <ContestContribution>[];
    final matieres = ['Algebre', 'Geometrie', 'Analyse', 'Probabilites', 'Suites'];
    for (int i = 0; i < 10; i++) {
      final type =
          i == 0
              ? ContributionType.streakBonus
              : (i == 3
                  ? ContributionType.simulation
                  : (i == 7
                      ? ContributionType.badge
                      : ContributionType.question));
      final matiere = matieres[rand.nextInt(matieres.length)];
      final date = maintenant.subtract(Duration(hours: i * 5 + rand.nextInt(3)));
      recentes.add(
        ContestContribution(
          id: 'contrib_$i',
          date: date,
          type: type,
          points: type.points,
          description:
              type == ContributionType.question
                  ? 'Question : $matiere - niveau ${1 + rand.nextInt(3)}'
                  : type == ContributionType.simulation
                  ? 'Simulation BAC - $matiere (${12 + rand.nextInt(8)}/20)'
                  : type == ContributionType.badge
                  ? 'Badge : Maitre $matiere'
                  : '7 jours consecutifs de revision',
          matiere: matiere,
        ),
      );
    }

    return MyContributionSummary(
      eleveId: 'me',
      eleveNom: 'Moi',
      ecoleNom: _monEcoleNom,
      ecoleId: _monEcoleId,
      contestId: 'contest-2026-03',
      pointsTotaux: total,
      rangDansEcole: 4, // 4e contributeur de Tokoin
      nbContributeursEcole: 87,
      nbQuestions: nbQuestions,
      nbSimulations: nbSimulations,
      nbBadges: nbBadges,
      nbBonusStreak: nbBonusStreak,
      recentes: recentes,
    );
  }

  /// Nombre de jours dans un mois donne (annee, mois 1-12).
  static int _daysInMonth(int annee, int mois) {
    // Premier jour du mois suivant, moins 1 jour.
    final firstOfNext = mois == 12
        ? DateTime(annee + 1, 1, 1)
        : DateTime(annee, mois + 1, 1);
    return firstOfNext.subtract(const Duration(days: 1)).day;
  }
}

// ─── Catalogue des 50 ecoles togolaises ──────────────────────────────
// Repartition : 12 a Lome, 8 Maritime, 10 Plateaux, 6 Centrale,
// 8 Kara, 6 Savanes (total 50).

class _LyceeEntry {
  final String nom;
  final String region;
  const _LyceeEntry(this.nom, this.region);
}

const List<_LyceeEntry> kLyceesTogo = [
  // Lome (12)
  _LyceeEntry('Lycée de Tokoin', 'Lome'),
  _LyceeEntry('Lycée Beyrout', 'Lome'),
  _LyceeEntry('Lycée d\'Adidogomé', 'Lome'),
  _LyceeEntry('Lycée de Bè', 'Lome'),
  _LyceeEntry('Lycée Notre Dame des Siens', 'Lome'),
  _LyceeEntry('Lycée d\'Agoè', 'Lome'),
  _LyceeEntry('Lycée d\'Agbalépédogan', 'Lome'),
  _LyceeEntry('Lycée de Nyékonakpoè', 'Lome'),
  _LyceeEntry('Lycée Protestant de Lomé', 'Lome'),
  _LyceeEntry('Collège Evéle de Lomé', 'Lome'),
  _LyceeEntry('Lycée de Hedzranawoé', 'Lome'),
  _LyceeEntry('Lycée d\'Aflao', 'Lome'),
  // Maritime (8)
  _LyceeEntry('Lycée de Tsévié', 'Maritime'),
  _LyceeEntry('Lycée de Vogan', 'Maritime'),
  _LyceeEntry('Lycée d\'Aného', 'Maritime'),
  _LyceeEntry('Lycée de Tabligbo', 'Maritime'),
  _LyceeEntry('Lycée de Vo', 'Maritime'),
  _LyceeEntry('Lycée d\'Agbodrafo', 'Maritime'),
  _LyceeEntry('Lycée d\'Ahépé', 'Maritime'),
  _LyceeEntry('Lycée de Vogan-Haho', 'Maritime'),
  // Plateaux (10)
  _LyceeEntry('Lycée d\'Atakpamé', 'Plateaux'),
  _LyceeEntry('Lycée de Kpalimé', 'Plateaux'),
  _LyceeEntry('Lycée de Badou', 'Plateaux'),
  _LyceeEntry('Lycée de Notsé', 'Plateaux'),
  _LyceeEntry('Lycée d\'Amlamé', 'Plateaux'),
  _LyceeEntry('Lycée d\'Anié', 'Plateaux'),
  _LyceeEntry('Lycée de Kpélé-Elé', 'Plateaux'),
  _LyceeEntry('Lycée de Danyi', 'Plateaux'),
  _LyceeEntry('Lycée d\'Akoumapé', 'Plateaux'),
  _LyceeEntry('Lycée de Pélél', 'Plateaux'),
  // Centrale (6)
  _LyceeEntry('Lycée de Sokodé', 'Centrale'),
  _LyceeEntry('Lycée de Sotouboua', 'Centrale'),
  _LyceeEntry('Lycée de Tchamba', 'Centrale'),
  _LyceeEntry('Lycée de Blitta', 'Centrale'),
  _LyceeEntry('Lycée d\'Adjengré', 'Centrale'),
  _LyceeEntry('Lycée de Tchétchi', 'Centrale'),
  // Kara (8)
  _LyceeEntry('Lycée de Kara', 'Kara'),
  _LyceeEntry('Lycée de Bafilo', 'Kara'),
  _LyceeEntry('Lycée de Kandé', 'Kara'),
  _LyceeEntry('Lycée de Bassar', 'Kara'),
  _LyceeEntry('Lycée de Guérin-Kouka', 'Kara'),
  _LyceeEntry('Lycée de Pagouda', 'Kara'),
  _LyceeEntry('Lycée de Niamtougou', 'Kara'),
  _LyceeEntry('Lycée de Pya', 'Kara'),
  // Savanes (6)
  _LyceeEntry('Lycée de Dapaong', 'Savanes'),
  _LyceeEntry('Lycée de Mango', 'Savanes'),
  _LyceeEntry('Lycée de Cinkassé', 'Savanes'),
  _LyceeEntry('Lycée de Tandjouaré', 'Savanes'),
  _LyceeEntry('Lycée de Takpamba', 'Savanes'),
  _LyceeEntry('Lycée de Barkoisi', 'Savanes'),
];

/// Regions officielles du Togo (utilisees pour le filtre regional).
const List<String> kTogoRegions = [
  'Lome',
  'Maritime',
  'Plateaux',
  'Centrale',
  'Kara',
  'Savanes',
];
