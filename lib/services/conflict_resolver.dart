// lib/services/conflict_resolver.dart
// Resolution de conflits CRDT-like entre etat local (Hive) et etat distant
// (backend).
//
// Strategies :
//   - ReviewCard   : Last-Write-Wins (LWW) sur lastReviewDate.
//   - BKT pL       : LWW sur updatedAt, mais si meme timestamp on prend le
//                    PLUS BAS (conservateur — evite surestimer la maitrise).
//   - Badges       : Union (OR) — un badge debloque ne peut jamais etre
//                    re-verrouille.
//   - Simulations  : idempotence par (user_id, examen, serie, created_at).
//   - User progress: max(local, remote) sur les compteurs (monotones).
//
// Ces fonctions sont pures (pas d'effet de bord) — le service appelant est
// responsable de la persistance. Le backend a son propre miroir dans
// backend/services/sync_service.py (ConflictResolver) avec les MEMES regles
// pour garantir la convergence.

import 'package:flutter/foundation.dart';

import '../models/review_card.dart';

/// Resultat d'une resolution de conflit.
///
/// [resolved] : la valeur finale a conserver.
/// [source] : d'ou vient la valeur retenue (pour debug / telemetry).
@immutable
class ConflictResolution<T> {
  final T resolved;
  final ConflictSource source;

  const ConflictResolution(this.resolved, this.source);
}

enum ConflictSource {
  /// Valeur locale conservee (plus recente ou egale).
  localKept,

  /// Valeur distante adoptee (plus recente).
  remoteAdopted,

  /// Fusion des deux cotes (ex: badges en union).
  merged,

  /// Pas de conflit (les deux valeurs etaient identiques).
  noConflict,
}

class ConflictResolver {
  ConflictResolver._(); // constructeur prive : utilitaire static uniquement

  // ─── ReviewCard (SM-2) — Last-Write-Wins ──────────────────────────

  /// Resout un conflit sur une ReviewCard.
  ///
  /// Compare [local.lastReviewDate] et [remote['last_review_date']]. Si le
  /// distant est strictement plus recent, on adopte toute la carte distante
  /// (les champs SM-2 forment un tout coherent — ne pas mixer repetitions
  /// local avec easinessFactor distant).
  ///
  /// [remote] format attendu (JSON snake_case depuis le backend) :
  ///   {
  ///     'repetitions': int,
  ///     'easiness_factor': double,
  ///     'interval_days': int,
  ///     'next_review_date': '2026-07-01T10:30:00Z',
  ///     'last_review_date': '2026-06-30T15:00:00Z',
  ///     'total_attempts': int,
  ///     'correct_attempts': int,
  ///     'is_learning': bool,
  ///   }
  static ConflictResolution<ReviewCard> resolveReviewCardConflict(
    ReviewCard local,
    Map<String, dynamic> remote,
  ) {
    final localLast = local.lastReviewDate;
    final remoteLastRaw = remote['last_review_date'] as String?;

    // Cas 1 : pas de date distante -> on garde local (donnees partielles).
    if (remoteLastRaw == null) {
      return ConflictResolution(local, ConflictSource.localKept);
    }

    // Cas 2 : pas de date locale -> on adopte distant (carte locale vierge).
    if (localLast == null) {
      return ConflictResolution(
        _reviewCardFromRemote(local.userId, local.questionId, remote),
        ConflictSource.remoteAdopted,
      );
    }

    final remoteLast = DateTime.parse(remoteLastRaw);

    // Cas 3 : egalite parfaite -> pas de conflit (on peut garder local).
    if (remoteLast.isAtSameMomentAs(localLast)) {
      // On verifie quand meme que le contenu est coherent.
      if (_reviewCardEqualsRemote(local, remote)) {
        return ConflictResolution(local, ConflictSource.noConflict);
      }
      // Meme date mais contenu different (rare, defaut d'horloge) : on
      // garde local (priorite au device qui a produit l'action).
      return ConflictResolution(local, ConflictSource.localKept);
    }

    // Cas 4 : LWW classique.
    if (remoteLast.isAfter(localLast)) {
      return ConflictResolution(
        _reviewCardFromRemote(local.userId, local.questionId, remote),
        ConflictSource.remoteAdopted,
      );
    }
    return ConflictResolution(local, ConflictSource.localKept);
  }

  static ReviewCard _reviewCardFromRemote(
    String userId,
    String questionId,
    Map<String, dynamic> remote,
  ) {
    return ReviewCard(
      userId: userId,
      questionId: questionId,
      repetitions: (remote['repetitions'] as num?)?.toInt() ?? 0,
      easinessFactor:
          (remote['easiness_factor'] as num?)?.toDouble() ?? 2.5,
      intervalDays: (remote['interval_days'] as num?)?.toInt() ?? 0,
      nextReviewDate: _parseDate(remote['next_review_date']) ?? DateTime.now(),
      lastReviewDate: _parseDate(remote['last_review_date']),
      totalAttempts: (remote['total_attempts'] as num?)?.toInt() ?? 0,
      correctAttempts: (remote['correct_attempts'] as num?)?.toInt() ?? 0,
      isLearning: (remote['is_learning'] as bool?) ?? true,
    );
  }

  static bool _reviewCardEqualsRemote(
    ReviewCard local,
    Map<String, dynamic> remote,
  ) {
    return local.repetitions == (remote['repetitions'] as num?)?.toInt() &&
        (local.easinessFactor - ((remote['easiness_factor'] as num?)?.toDouble() ?? 0))
            .abs() <
            0.001 &&
        local.totalAttempts == (remote['total_attempts'] as num?)?.toInt();
  }

  // ─── BKT p(L) — LWW + conservateur sur egalite ───────────────────

  /// Resout un conflit sur P(L) d'une competence BKT.
  ///
  /// Regles :
  ///   - Si seulement local a un timestamp -> garde local.
  ///   - Si seulement remote a un timestamp -> adopte remote.
  ///   - Si timestamps egaux -> garde le PLUS BAS (conservateur : evite
  ///     de surestimer la maitrise et de sauter des questions cruciales).
  ///   - Sinon -> LWW (le plus recent gagne).
  ///
  /// [localPL] / [remotePL] : valeurs de P(L) entre 0 et 1.
  /// [localUpdatedAt] / [remoteUpdatedAt] : timestamps de derniere mise
  /// a jour (peuvent etre null si non suivis).
  static ConflictResolution<double> resolveBktConflict(
    double localPL,
    double remotePL,
    DateTime? localUpdatedAt,
    DateTime? remoteUpdatedAt,
  ) {
    // Bornes defensives
    final lp = localPL.clamp(0.0, 1.0);
    final rp = remotePL.clamp(0.0, 1.0);

    if (localUpdatedAt == null && remoteUpdatedAt == null) {
      // Pas d'info temporelle : on prend le plus bas (conservateur).
      final resolved = lp <= rp ? lp : rp;
      return ConflictResolution(
        resolved,
        resolved == lp ? ConflictSource.localKept : ConflictSource.remoteAdopted,
      );
    }
    if (remoteUpdatedAt == null) {
      return ConflictResolution(lp, ConflictSource.localKept);
    }
    if (localUpdatedAt == null) {
      return ConflictResolution(rp, ConflictSource.remoteAdopted);
    }

    if (localUpdatedAt.isAtSameMomentAs(remoteUpdatedAt)) {
      // Egalite temporelle : conservateur.
      final resolved = lp <= rp ? lp : rp;
      return ConflictResolution(resolved, ConflictSource.merged);
    }

    // LWW classique.
    if (localUpdatedAt.isAfter(remoteUpdatedAt)) {
      return ConflictResolution(lp, ConflictSource.localKept);
    }
    return ConflictResolution(rp, ConflictSource.remoteAdopted);
  }

  // ─── Badges — Union (monotone) ───────────────────────────────────

  /// Resout un conflit sur le deblocage d'un badge.
  ///
  /// Regle : un badge debloque ne peut JAMAIS etre re-verrouille.
  /// Donc : result = localUnlocked || remoteUnlocked.
  static ConflictResolution<bool> resolveBadgeConflict(
    bool localUnlocked,
    bool remoteUnlocked,
  ) {
    if (localUnlocked == remoteUnlocked) {
      return ConflictResolution(localUnlocked, ConflictSource.noConflict);
    }
    return ConflictResolution(true, ConflictSource.merged);
  }

  // ─── Compteurs utilisateur — max() monotone ──────────────────────

  /// Resout un conflit sur un compteur monotone (questions answered,
  /// sessions count, etc.).
  ///
  /// On prend le max pour ne jamais perdre de progres. Les compteurs ne
  /// peuvent qu'augmenter, donc c'est une convergence naturelle.
  static ConflictResolution<int> resolveCounterConflict(
    int localValue,
    int remoteValue,
  ) {
    if (localValue == remoteValue) {
      return ConflictResolution(localValue, ConflictSource.noConflict);
    }
    final resolved = localValue > remoteValue ? localValue : remoteValue;
    return ConflictResolution(
      resolved,
      resolved == localValue
          ? ConflictSource.localKept
          : ConflictSource.remoteAdopted,
    );
  }

  // ─── Map BKT complete — merge par cle ────────────────────────────

  /// Fusionne deux maps BKT {competence_id: pL} en appliquant
  /// [resolveBktConflict] sur chaque cle.
  ///
  /// [localUpdatedAt] / [remoteUpdatedAt] : timestamps globaux de derniere
  /// maj (appliques a toutes les cles — simplification acceptable car en
  /// pratique une sync batch arrive avec un seul timestamp).
  static Map<String, double> mergeBktMaps(
    Map<String, double> local,
    Map<String, double> remote, {
    DateTime? localUpdatedAt,
    DateTime? remoteUpdatedAt,
  }) {
    final merged = <String, double>{};
    final allKeys = {...local.keys, ...remote.keys};

    for (final key in allKeys) {
      final lp = local[key];
      final rp = remote[key];
      if (lp != null && rp != null) {
        merged[key] = resolveBktConflict(
          lp,
          rp,
          localUpdatedAt,
          remoteUpdatedAt,
        ).resolved;
      } else if (lp != null) {
        merged[key] = lp;
      } else {
        merged[key] = rp!;
      }
    }
    return merged;
  }

  // ─── Helpers ─────────────────────────────────────────────────────

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
