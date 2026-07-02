// lib/models/level_reward.dart
// Catalogue des récompenses débloquables par niveau (méta-gamification).
//
// 8 récompenses réparties sur les niveaux 5, 10, 15, 20, 25, 30, 40, 50.
// Ce sont des features cosmétiques ou fonctionnelles qui se débloquent
// au fur et à mesure que l'élève progresse.
//
// Pas de persistance Hive : ce sont des constantes (catalogue statique).
// L'état "débloquée ou non" est stocké dans UserLevel.unlockedRewardIds.
//
// Branchement côté feature (à faire par l'agent principal lors du wiring) :
//   final userLevel = levelService.getOrCreate(userId);
//   if (userLevel.hasReward('dark_theme')) {
//     // activer le toggle thème sombre dans les settings
//   }

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Définition statique d'une récompense de niveau.
///
/// Chaque récompense correspond à une feature de l'app qui se débloque
/// quand l'élève atteint [requiredLevel]. L'ID est stable et stocké dans
/// [UserLevel.unlockedRewardIds].
class LevelReward {
  /// Identifiant stable : 'dark_theme', 'tts_premium', 'custom_badge', etc.
  final String id;

  /// Titre court affiché sur la carte.
  final String title;

  /// Description humaine (ce que la récompense débloque concrètement).
  final String description;

  /// Niveau requis pour débloquer la récompense (5, 10, 15, 20, 25, 30, 40, 50).
  final int requiredLevel;

  /// Icône Material représentant la récompense (pas d'emojis).
  final IconData iconData;

  /// Couleur d'accent (background icône, glow).
  final Color color;

  /// Catégorie de la récompense (pour grouper visuellement si besoin).
  final LevelRewardCategory category;

  const LevelReward({
    required this.id,
    required this.title,
    required this.description,
    required this.requiredLevel,
    required this.iconData,
    required this.color,
    required this.category,
  });
}

/// Catégories de récompenses (regroupement thématique optionnel).
enum LevelRewardCategory {
  /// Apparence (thème, couleurs).
  apparence,

  /// Fonctionnalité (TTS premium, mode concours).
  fonctionnalite,

  /// Statut social (Ambassadeur, Légende).
  statut,

  /// Récompense physique (swag).
  physique;

  String get label => switch (this) {
        apparence => 'Apparence',
        fonctionnalite => 'Fonctionnalité',
        statut => 'Statut',
        physique => 'Physique',
      };

  IconData get icon => switch (this) {
        apparence => Icons.palette_outlined,
        fonctionnalite => Icons.bolt_outlined,
        statut => Icons.verified_outlined,
        physique => Icons.card_giftcard_outlined,
      };
}

// ─── Catalogue des 8 récompenses ───────────────────────────────────

/// Catalogue statique des récompenses ExamBoost Togo.
/// Trié par niveau croissant.
class LevelRewards {
  LevelRewards._();

  static const List<LevelReward> all = [
    // ── N5 : Thème sombre ──────────────────────────────────────────
    LevelReward(
      id: 'dark_theme',
      title: 'Thème sombre',
      description:
          "Débloque le thème sombre de l'application pour réviser tard "
          'le soir sans fatiguer tes yeux.',
      requiredLevel: 5,
      iconData: Icons.dark_mode_outlined,
      color: Color(0xFF263238),
      category: LevelRewardCategory.apparence,
    ),

    // ── N10 : Voix TTS premium ─────────────────────────────────────
    LevelReward(
      id: 'tts_premium',
      title: 'Voix TTS premium',
      description:
          "Accès à des voix de synthèse vocale plus naturelles pour "
          "l'écoute des cours et des corrections.",
      requiredLevel: 10,
      iconData: Icons.record_voice_over_outlined,
      color: Color(0xFF1565C0),
      category: LevelRewardCategory.fonctionnalite,
    ),

    // ── N15 : Badge personnalisé ───────────────────────────────────
    LevelReward(
      id: 'custom_badge',
      title: 'Badge personnalisé',
      description:
          "Crée ton propre badge de profil : choisis une icône et une "
          'couleur qui te représentent dans la communauté.',
      requiredLevel: 15,
      iconData: Icons.badge_outlined,
      color: Color(0xFF7B1FA2),
      category: LevelRewardCategory.apparence,
    ),

    // ── N20 : Couleurs app personnalisables ────────────────────────
    LevelReward(
      id: 'custom_colors',
      title: 'Couleurs personnalisables',
      description:
          "Personnalise les couleurs de l'application : choisis ta "
          'couleur primaire parmi une palette inspirée du Togo.',
      requiredLevel: 20,
      iconData: Icons.color_lens_outlined,
      color: Color(0xFFD97700),
      category: LevelRewardCategory.apparence,
    ),

    // ── N25 : Mode concours prioritaire ────────────────────────────
    LevelReward(
      id: 'priority_contest_mode',
      title: 'Mode concours prioritaire',
      description:
          "Accès prioritaire au mode concours : simulations chronométrées "
          'avec correction détaillée et classement national.',
      requiredLevel: 25,
      iconData: Icons.emoji_events_outlined,
      color: Color(0xFFFFB300),
      category: LevelRewardCategory.fonctionnalite,
    ),

    // ── N30 : Accès anticipé nouvelles features ────────────────────
    LevelReward(
      id: 'early_access',
      title: 'Accès anticipé',
      description:
          "Profite des nouvelles fonctionnalités en avant-première : "
          'nouveaux modes de révision, outils IA, intégrations à venir.',
      requiredLevel: 30,
      iconData: Icons.flash_on_outlined,
      color: Color(0xFF006837),
      category: LevelRewardCategory.fonctionnalite,
    ),

    // ── N40 : Statut Ambassadeur ExamBoost ─────────────────────────
    LevelReward(
      id: 'ambassador_status',
      title: 'Statut Ambassadeur',
      description:
          "Tu deviens officiellement Ambassadeur ExamBoost Togo : "
          'badge exclusif sur ton profil, accès au canal Telegram des '
          'ambassadeurs et droit de vote sur les prochaines features.',
      requiredLevel: 40,
      iconData: Icons.verified,
      color: Color(0xFF1565C0),
      category: LevelRewardCategory.statut,
    ),

    // ── N50 : Statut Légende ExamBoost + swag physique ─────────────
    LevelReward(
      id: 'legend_status',
      title: 'Statut Légende',
      description:
          "Le statut ultime : Légende ExamBoost Togo. Tu reçois un kit "
          'physique (t-shirt + stickers + carte) livré chez toi au Togo, '
          'et ton nom figure dans le Hall of Fame de l\'app.',
      requiredLevel: 50,
      iconData: Icons.workspace_premium,
      color: Color(0xFFFFB300),
      category: LevelRewardCategory.physique,
    ),
  ];

  /// Index id -> LevelReward pour lookup O(1).
  static final Map<String, LevelReward> _index = {
    for (final r in all) r.id: r,
  };

  /// Récupère une récompense par son id, ou null si introuvable.
  static LevelReward? byId(String id) => _index[id];

  /// Récompenses déjà débloquées pour un niveau donné.
  /// (Toutes les récompenses dont requiredLevel <= currentLevel.)
  static List<LevelReward> unlockedFor(int currentLevel) =>
      all.where((r) => r.requiredLevel <= currentLevel).toList();

  /// Prochaine récompense à débloquer pour un niveau donné.
  /// Retourne null si toutes les récompenses sont débloquées (niveau 50).
  static LevelReward? nextFor(int currentLevel) {
    for (final r in all) {
      if (r.requiredLevel > currentLevel) return r;
    }
    return null;
  }
}
