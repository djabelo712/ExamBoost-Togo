// lib/models/badge.dart
// Système de badges & gamification ExamBoost Togo
//
// 39 badges débloquables répartis sur 5 catégories :
//   - Streak     : 9 badges (3 types x 3 niveaux)
//   - Révision   : 9 badges (3 types x 3 niveaux)
//   - Maîtrise   : 9 badges (3 types x 3 niveaux)
//   - Simulation : 9 badges (3 types x 3 niveaux)
//   - Spécial    : 3 badges (1 niveau Or uniquement)
//
// Persistance Hive :
//   - Seul UserBadge est persisté (état de progression par élève).
//   - Les Badge sont des constantes (catalogue statique), non persistées.
//
// Pour générer l'adaptateur Hive :
//   dart run build_runner build --delete-conflicting-outputs
// Puis enregistrer UserBadgeAdapter dans main.dart.

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'badge.g.dart';

// ─── Énumérations ─────────────────────────────────────────────────

/// Catégories de badges (regroupement thématique pour la collection).
@HiveType(typeId: 7)
enum BadgeCategory {
  @HiveField(0)
  revision,

  @HiveField(1)
  streak,

  @HiveField(2)
  mastery,

  @HiveField(3)
  simulation,

  @HiveField(4)
  social,

  @HiveField(5)
  special;

  /// Libellé affiché dans l'UI (chips de filtre, headers).
  String get label => switch (this) {
        revision => 'Révision',
        streak => 'Régularité',
        mastery => 'Maîtrise',
        simulation => 'Simulation',
        social => 'Social',
        special => 'Spécial',
      };

  /// Icône Material représentant la catégorie (chip de filtre).
  IconData get icon => switch (this) {
        revision => Icons.library_books,
        streak => Icons.local_fire_department,
        mastery => Icons.school,
        simulation => Icons.timer,
        social => Icons.groups,
        special => Icons.emoji_events,
      };

  /// Ordre d'affichage dans la collection (chips + sections).
  static List<BadgeCategory> get displayOrder => const [
        streak,
        revision,
        mastery,
        simulation,
        special,
        social,
      ];
}

/// Niveaux de badges (métallique). Tous les badges non-spéciaux ont 3 niveaux.
@HiveType(typeId: 8)
enum BadgeLevel {
  @HiveField(0)
  bronze,

  @HiveField(1)
  argent,

  @HiveField(2)
  or;

  /// Couleur métallique associée au niveau.
  Color get color => switch (this) {
        bronze => const Color(0xFFCD7F32), // Bronze
        argent => const Color(0xFF9E9E9E), // Argent (gris lisible)
        or => const Color(0xFFFFB300), // Or (ambre)
      };

  /// Dégradé pour effets de relief (card, dialog).
  List<Color> get gradient => switch (this) {
        bronze => const [Color(0xFFE8A87C), Color(0xFFCD7F32), Color(0xFF8D5524)],
        argent => const [Color(0xFFE0E0E0), Color(0xFF9E9E9E), Color(0xFF616161)],
        or => const [Color(0xFFFFE082), Color(0xFFFFB300), Color(0xFFFF8F00)],
      };

  String get label => switch (this) {
        bronze => 'Bronze',
        argent => 'Argent',
        or => 'Or',
      };
}

// ─── Modèle Badge (constante, non persistée) ─────────────────────

/// Définition statique d'un badge (catalogue).
///
/// [group] identifie la famille de badges à niveaux :
///   - 'streak_7j'  → streak_7j_bronze / _argent / _or
///   - 'premier_pas' → premier_pas_or (niveau unique)
class Badge {
  /// Identifiant unique stable : 'streak_7j_bronze'
  final String id;

  /// Famille du badge (pour grouper les 3 niveaux dans le bottom sheet).
  final String group;

  /// Titre court affiché sur la carte.
  final String title;

  /// Description humaine (peut être cachée si verrouillé).
  final String description;

  /// Catégorie thématique.
  final BadgeCategory category;

  /// Niveau (Bronze / Argent / Or).
  final BadgeLevel level;

  /// Icône Material utilisée pour l'affichage (pas d'emojis).
  final IconData iconData;

  /// Couleur d'accent du badge (background icône, glow).
  final Color color;

  /// Seuil à atteindre pour débloquer ce badge.
  final int requiredValue;

  /// Récompense XP (100 / 250 / 500).
  final int xpReward;

  /// Suffixe affiché après la valeur de progression : "5 / 7 jours".
  final String progressLabel;

  const Badge({
    required this.id,
    required this.group,
    required this.title,
    required this.description,
    required this.category,
    required this.level,
    required this.iconData,
    required this.color,
    required this.requiredValue,
    required this.xpReward,
    required this.progressLabel,
  });

  /// Vrai si l'UserBadge a atteint le seuil ET a une date de déblocage.
  bool isUnlocked(UserBadge? userBadge) =>
      userBadge != null &&
      userBadge.isUnlocked &&
      userBadge.progress >= requiredValue;

  /// Pourcentage de progression [0.0, 1.0] clampé.
  double progressPercent(UserBadge? userBadge) {
    if (requiredValue == 0) return 1.0;
    final p = userBadge?.progress ?? 0;
    return (p / requiredValue).clamp(0.0, 1.0);
  }

  /// Texte affiché sur la carte "en cours" : "5 / 7 jours".
  String progressText(UserBadge? userBadge) {
    final p = (userBadge?.progress ?? 0).clamp(0, requiredValue);
    final suffix =
        progressLabel.isEmpty ? '' : ' $progressLabel';
    return '$p / $requiredValue$suffix';
  }
}

// ─── Modèle UserBadge (persisté Hive) ────────────────────────────

/// État de progression d'un élève pour un badge donné.
/// Persisté dans la Hive box "user_badges" (clé = badgeId).
@HiveType(typeId: 9)
class UserBadge extends HiveObject {
  @HiveField(0)
  String badgeId;

  /// Valeur courante (jours de streak, questions vues, etc.).
  /// Ne peut que croître (max entre ancien et nouveau).
  @HiveField(1)
  int progress;

  /// Date de déblocage. null tant que le badge n'est pas atteint.
  @HiveField(2)
  DateTime? unlockedAt;

  UserBadge({
    required this.badgeId,
    this.progress = 0,
    this.unlockedAt,
  });

  bool get isUnlocked => unlockedAt != null;
}

// ─── Catalogue des 39 badges ─────────────────────────────────────

/// Catalogue statique de tous les badges ExamBoost Togo.
class Badges {
  Badges._();

  /// Liste ordonnée (par catégorie puis niveau) des 39 badges.
  static const List<Badge> all = [
    // ─── Streak (Régularité) — 9 badges ───────────────────────────
    Badge(
      id: 'streak_7j_bronze',
      group: 'streak_7j',
      title: 'Régularité',
      description: 'Révise 7 jours de suite pour ancrer tes habitudes.',
      category: BadgeCategory.streak,
      level: BadgeLevel.bronze,
      iconData: Icons.local_fire_department,
      color: Color(0xFFD97700),
      requiredValue: 7,
      xpReward: 100,
      progressLabel: 'jours',
    ),
    Badge(
      id: 'streak_7j_argent',
      group: 'streak_7j',
      title: 'Régularité',
      description: 'Un mois complet de révision quotidienne ! Tu es une machine.',
      category: BadgeCategory.streak,
      level: BadgeLevel.argent,
      iconData: Icons.local_fire_department,
      color: Color(0xFFD97700),
      requiredValue: 30,
      xpReward: 250,
      progressLabel: 'jours',
    ),
    Badge(
      id: 'streak_7j_or',
      group: 'streak_7j',
      title: 'Régularité',
      description: '100 jours de suite : la discipline des meilleurs élèves.',
      category: BadgeCategory.streak,
      level: BadgeLevel.or,
      iconData: Icons.local_fire_department,
      color: Color(0xFFD97700),
      requiredValue: 100,
      xpReward: 500,
      progressLabel: 'jours',
    ),
    Badge(
      id: 'marathonien_bronze',
      group: 'marathonien',
      title: 'Marathonien',
      description: 'Cumule 50 sessions de révision.',
      category: BadgeCategory.streak,
      level: BadgeLevel.bronze,
      iconData: Icons.directions_run,
      color: Color(0xFF006837),
      requiredValue: 50,
      xpReward: 100,
      progressLabel: 'sessions',
    ),
    Badge(
      id: 'marathonien_argent',
      group: 'marathonien',
      title: 'Marathonien',
      description: '200 sessions : tu dépasses la moitié de l\'année scolaire.',
      category: BadgeCategory.streak,
      level: BadgeLevel.argent,
      iconData: Icons.directions_run,
      color: Color(0xFF006837),
      requiredValue: 200,
      xpReward: 250,
      progressLabel: 'sessions',
    ),
    Badge(
      id: 'marathonien_or',
      group: 'marathonien',
      title: 'Marathonien',
      description: '500 sessions : une endurance d\'athlète académique.',
      category: BadgeCategory.streak,
      level: BadgeLevel.or,
      iconData: Icons.directions_run,
      color: Color(0xFF006837),
      requiredValue: 500,
      xpReward: 500,
      progressLabel: 'sessions',
    ),
    Badge(
      id: 'leve_tot_bronze',
      group: 'leve_tot',
      title: 'Lève-tôt',
      description: 'Révise 5 fois avant 8h du matin.',
      category: BadgeCategory.streak,
      level: BadgeLevel.bronze,
      iconData: Icons.wb_sunny,
      color: Color(0xFFFFC107),
      requiredValue: 5,
      xpReward: 100,
      progressLabel: 'matins',
    ),
    Badge(
      id: 'leve_tot_argent',
      group: 'leve_tot',
      title: 'Lève-tôt',
      description: '20 révisions matinales : tu prends une longueur d\'avance.',
      category: BadgeCategory.streak,
      level: BadgeLevel.argent,
      iconData: Icons.wb_sunny,
      color: Color(0xFFFFC107),
      requiredValue: 20,
      xpReward: 250,
      progressLabel: 'matins',
    ),
    Badge(
      id: 'leve_tot_or',
      group: 'leve_tot',
      title: 'Lève-tôt',
      description: '50 matins de révision : la brise du jour t\'appartient.',
      category: BadgeCategory.streak,
      level: BadgeLevel.or,
      iconData: Icons.wb_sunny,
      color: Color(0xFFFFC107),
      requiredValue: 50,
      xpReward: 500,
      progressLabel: 'matins',
    ),

    // ─── Révision — 9 badges ──────────────────────────────────────
    Badge(
      id: 'curieux_bronze',
      group: 'curieux',
      title: 'Curieux',
      description: 'Réponds à 100 questions.',
      category: BadgeCategory.revision,
      level: BadgeLevel.bronze,
      iconData: Icons.quiz,
      color: Color(0xFF1565C0),
      requiredValue: 100,
      xpReward: 100,
      progressLabel: 'questions',
    ),
    Badge(
      id: 'curieux_argent',
      group: 'curieux',
      title: 'Curieux',
      description: '500 questions vues : tu as balayé large.',
      category: BadgeCategory.revision,
      level: BadgeLevel.argent,
      iconData: Icons.quiz,
      color: Color(0xFF1565C0),
      requiredValue: 500,
      xpReward: 250,
      progressLabel: 'questions',
    ),
    Badge(
      id: 'curieux_or',
      group: 'curieux',
      title: 'Curieux',
      description: '2000 questions : encyclopédie vivante.',
      category: BadgeCategory.revision,
      level: BadgeLevel.or,
      iconData: Icons.quiz,
      color: Color(0xFF1565C0),
      requiredValue: 2000,
      xpReward: 500,
      progressLabel: 'questions',
    ),
    Badge(
      id: 'assidu_bronze',
      group: 'assidu',
      title: 'Assidu',
      description: 'Touche 10 matières différentes.',
      category: BadgeCategory.revision,
      level: BadgeLevel.bronze,
      iconData: Icons.library_books,
      color: Color(0xFF7B1FA2),
      requiredValue: 10,
      xpReward: 100,
      progressLabel: 'matières',
    ),
    Badge(
      id: 'assidu_argent',
      group: 'assidu',
      title: 'Assidu',
      description: 'Explore 30 chapitres distincts.',
      category: BadgeCategory.revision,
      level: BadgeLevel.argent,
      iconData: Icons.library_books,
      color: Color(0xFF7B1FA2),
      requiredValue: 30,
      xpReward: 250,
      progressLabel: 'chapitres',
    ),
    Badge(
      id: 'assidu_or',
      group: 'assidu',
      title: 'Assidu',
      description: '60 chapitres couverts : aucun recoin du programme t\'échappe.',
      category: BadgeCategory.revision,
      level: BadgeLevel.or,
      iconData: Icons.library_books,
      color: Color(0xFF7B1FA2),
      requiredValue: 60,
      xpReward: 500,
      progressLabel: 'chapitres',
    ),
    Badge(
      id: 'rapide_bronze',
      group: 'rapide',
      title: 'Rapide',
      description: 'Réponds à 20 questions en 10 minutes ou moins.',
      category: BadgeCategory.revision,
      level: BadgeLevel.bronze,
      iconData: Icons.bolt,
      color: Color(0xFFD97700),
      requiredValue: 20,
      xpReward: 100,
      progressLabel: 'en 10 min',
    ),
    Badge(
      id: 'rapide_argent',
      group: 'rapide',
      title: 'Rapide',
      description: '50 questions en 20 minutes : rythme d\'examen.',
      category: BadgeCategory.revision,
      level: BadgeLevel.argent,
      iconData: Icons.bolt,
      color: Color(0xFFD97700),
      requiredValue: 50,
      xpReward: 250,
      progressLabel: 'en 20 min',
    ),
    Badge(
      id: 'rapide_or',
      group: 'rapide',
      title: 'Rapide',
      description: '100 questions en 30 minutes : l\'éclair académique.',
      category: BadgeCategory.revision,
      level: BadgeLevel.or,
      iconData: Icons.bolt,
      color: Color(0xFFD97700),
      requiredValue: 100,
      xpReward: 500,
      progressLabel: 'en 30 min',
    ),

    // ─── Maîtrise (BKT) — 9 badges ───────────────────────────────
    Badge(
      id: 'maitre_maths_bronze',
      group: 'maitre_maths',
      title: 'Maître Maths',
      description: 'Maîtrise 5 compétences en Mathématiques (P(L) ≥ 0,85).',
      category: BadgeCategory.mastery,
      level: BadgeLevel.bronze,
      iconData: Icons.calculate,
      color: Color(0xFF0D47A1),
      requiredValue: 5,
      xpReward: 100,
      progressLabel: 'compétences',
    ),
    Badge(
      id: 'maitre_maths_argent',
      group: 'maitre_maths',
      title: 'Maître Maths',
      description: '15 compétences mathématiques maîtrisées.',
      category: BadgeCategory.mastery,
      level: BadgeLevel.argent,
      iconData: Icons.calculate,
      color: Color(0xFF0D47A1),
      requiredValue: 15,
      xpReward: 250,
      progressLabel: 'compétences',
    ),
    Badge(
      id: 'maitre_maths_or',
      group: 'maitre_maths',
      title: 'Maître Maths',
      description: '30 compétences : un répertoire complet pour l\'examen.',
      category: BadgeCategory.mastery,
      level: BadgeLevel.or,
      iconData: Icons.calculate,
      color: Color(0xFF0D47A1),
      requiredValue: 30,
      xpReward: 500,
      progressLabel: 'compétences',
    ),
    Badge(
      id: 'pro_francais_bronze',
      group: 'pro_francais',
      title: 'Pro Français',
      description: 'Maîtrise 5 compétences en Français (P(L) ≥ 0,85).',
      category: BadgeCategory.mastery,
      level: BadgeLevel.bronze,
      iconData: Icons.menu_book,
      color: Color(0xFFC62828),
      requiredValue: 5,
      xpReward: 100,
      progressLabel: 'compétences',
    ),
    Badge(
      id: 'pro_francais_argent',
      group: 'pro_francais',
      title: 'Pro Français',
      description: '15 compétences en Français maîtrisées.',
      category: BadgeCategory.mastery,
      level: BadgeLevel.argent,
      iconData: Icons.menu_book,
      color: Color(0xFFC62828),
      requiredValue: 15,
      xpReward: 250,
      progressLabel: 'compétences',
    ),
    Badge(
      id: 'pro_francais_or',
      group: 'pro_francais',
      title: 'Pro Français',
      description: '30 compétences : tu manies la langue comme un écrivain.',
      category: BadgeCategory.mastery,
      level: BadgeLevel.or,
      iconData: Icons.menu_book,
      color: Color(0xFFC62828),
      requiredValue: 30,
      xpReward: 500,
      progressLabel: 'compétences',
    ),
    Badge(
      id: 'polyvalent_bronze',
      group: 'polyvalent',
      title: 'Polyvalent',
      description: 'Atteins la maîtrise dans 3 matières différentes.',
      category: BadgeCategory.mastery,
      level: BadgeLevel.bronze,
      iconData: Icons.star,
      color: Color(0xFF006837),
      requiredValue: 3,
      xpReward: 100,
      progressLabel: 'matières',
    ),
    Badge(
      id: 'polyvalent_argent',
      group: 'polyvalent',
      title: 'Polyvalent',
      description: 'Maîtrise confirmée dans 5 matières.',
      category: BadgeCategory.mastery,
      level: BadgeLevel.argent,
      iconData: Icons.star,
      color: Color(0xFF006837),
      requiredValue: 5,
      xpReward: 250,
      progressLabel: 'matières',
    ),
    Badge(
      id: 'polyvalent_or',
      group: 'polyvalent',
      title: 'Polyvalent',
      description: '8 matières maîtrisées : profil complet, redoutable à l\'examen.',
      category: BadgeCategory.mastery,
      level: BadgeLevel.or,
      iconData: Icons.star,
      color: Color(0xFF006837),
      requiredValue: 8,
      xpReward: 500,
      progressLabel: 'matières',
    ),

    // ─── Simulation — 9 badges ───────────────────────────────────
    Badge(
      id: 'pret_examen_bronze',
      group: 'pret_examen',
      title: 'Prêt pour l\'examen',
      description: 'Termine ta première simulation d\'examen complète.',
      category: BadgeCategory.simulation,
      level: BadgeLevel.bronze,
      iconData: Icons.timer,
      color: Color(0xFFD97700),
      requiredValue: 1,
      xpReward: 100,
      progressLabel: 'simulation',
    ),
    Badge(
      id: 'pret_examen_argent',
      group: 'pret_examen',
      title: 'Prêt pour l\'examen',
      description: '5 simulations complètes : tu as ritualisé l\'entraînement.',
      category: BadgeCategory.simulation,
      level: BadgeLevel.argent,
      iconData: Icons.timer,
      color: Color(0xFFD97700),
      requiredValue: 5,
      xpReward: 250,
      progressLabel: 'simulations',
    ),
    Badge(
      id: 'pret_examen_or',
      group: 'pret_examen',
      title: 'Prêt pour l\'examen',
      description: '20 simulations : l\'examen n\'aura plus de secret pour toi.',
      category: BadgeCategory.simulation,
      level: BadgeLevel.or,
      iconData: Icons.timer,
      color: Color(0xFFD97700),
      requiredValue: 20,
      xpReward: 500,
      progressLabel: 'simulations',
    ),
    Badge(
      id: 'top_score_bronze',
      group: 'top_score',
      title: 'Top Score',
      description: 'Obtiens 10/20 à une simulation.',
      category: BadgeCategory.simulation,
      level: BadgeLevel.bronze,
      iconData: Icons.emoji_events,
      color: Color(0xFFFFB300),
      requiredValue: 10,
      xpReward: 100,
      progressLabel: '/20',
    ),
    Badge(
      id: 'top_score_argent',
      group: 'top_score',
      title: 'Top Score',
      description: 'Atteins 14/20 à une simulation.',
      category: BadgeCategory.simulation,
      level: BadgeLevel.argent,
      iconData: Icons.emoji_events,
      color: Color(0xFFFFB300),
      requiredValue: 14,
      xpReward: 250,
      progressLabel: '/20',
    ),
    Badge(
      id: 'top_score_or',
      group: 'top_score',
      title: 'Top Score',
      description: '18/20 à une simulation : excellence absolue.',
      category: BadgeCategory.simulation,
      level: BadgeLevel.or,
      iconData: Icons.emoji_events,
      color: Color(0xFFFFB300),
      requiredValue: 18,
      xpReward: 500,
      progressLabel: '/20',
    ),
    Badge(
      id: 'sans_faute_bronze',
      group: 'sans_faute',
      title: 'Sans faute',
      description: 'Réussis une simulation QCM à 100 %.',
      category: BadgeCategory.simulation,
      level: BadgeLevel.bronze,
      iconData: Icons.check_circle,
      color: Color(0xFF2E7D32),
      requiredValue: 1,
      xpReward: 100,
      progressLabel: 'parfaite',
    ),
    Badge(
      id: 'sans_faute_argent',
      group: 'sans_faute',
      title: 'Sans faute',
      description: '3 simulations QCM sans la moindre erreur.',
      category: BadgeCategory.simulation,
      level: BadgeLevel.argent,
      iconData: Icons.check_circle,
      color: Color(0xFF2E7D32),
      requiredValue: 3,
      xpReward: 250,
      progressLabel: 'parfaites',
    ),
    Badge(
      id: 'sans_faute_or',
      group: 'sans_faute',
      title: 'Sans faute',
      description: '10 simulations parfaites : la régularité du sans-faute.',
      category: BadgeCategory.simulation,
      level: BadgeLevel.or,
      iconData: Icons.check_circle,
      color: Color(0xFF2E7D32),
      requiredValue: 10,
      xpReward: 500,
      progressLabel: 'parfaites',
    ),

    // ─── Spécial — 3 badges (Or uniquement) ─────────────────────
    Badge(
      id: 'premier_pas_or',
      group: 'premier_pas',
      title: 'Premier pas',
      description: 'Tu as effectué ta toute première révision sur ExamBoost Togo. Bienvenue dans l\'aventure !',
      category: BadgeCategory.special,
      level: BadgeLevel.or,
      iconData: Icons.baby_changing_station,
      color: Color(0xFFE91E63),
      requiredValue: 1,
      xpReward: 500,
      progressLabel: '',
    ),
    Badge(
      id: 'pionnier_or',
      group: 'pionnier',
      title: 'Pionnier',
      description: 'Tu fais partie des 500 premiers inscrits. Ton soutien de la première heure ouvre la voie à toute une génération d\'élèves togolais.',
      category: BadgeCategory.special,
      level: BadgeLevel.or,
      iconData: Icons.flag,
      color: Color(0xFF006837),
      requiredValue: 1,
      xpReward: 500,
      progressLabel: '',
    ),
    Badge(
      id: 'beta_testeur_or',
      group: 'beta_testeur',
      title: 'Beta-testeur',
      description: 'Tu as signalé un bug ou proposé une fonctionnalité. Merci de contribuer à rendre ExamBoost meilleur pour tous les élèves du Togo.',
      category: BadgeCategory.special,
      level: BadgeLevel.or,
      iconData: Icons.bug_report,
      color: Color(0xFF7B1FA2),
      requiredValue: 1,
      xpReward: 500,
      progressLabel: '',
    ),
  ];

  /// Index id → Badge pour lookup O(1).
  static final Map<String, Badge> _index = {
    for (final b in all) b.id: b,
  };

  /// Récupère un badge par son id, ou null si introuvable.
  static Badge? byId(String id) => _index[id];

  /// Tous les niveaux d'une même famille de badges, triés par niveau.
  /// Pour les badges spéciaux (un seul niveau), retourne une liste singleton.
  static List<Badge> levelsOf(String group) {
    final list = all.where((b) => b.group == group).toList();
    list.sort((a, b) => a.level.index.compareTo(b.level.index));
    return list;
  }

  /// Badges filtrés par catégorie (ordre du catalogue).
  static List<Badge> byCategory(BadgeCategory category) =>
      all.where((b) => b.category == category).toList();
}
