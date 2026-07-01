// lib/services/score_predictor.dart
// Orchestrateur de prédiction de score + persistance de l'historique.
//
// Rôle :
//   1. Détecter l'examen + série de l'élève à partir de son AppUser.
//   2. Appeler [ScoreCalculator.predict] avec les bons paramètres.
//   3. Persister la prédiction dans une Hive box "score_predictions"
//      (sous forme de JSON String, pour éviter les adapters générés).
//   4. Fournir l'historique pour le LineChart "Évolution 3 mois".
//
// Note sur la persistance : on utilise une Hive box<String> contenant
// du JSON sérialisé. Cela évite d'avoir à déclarer des TypeAdapter
// générés par build_runner (qui ne sont pas encore générés à ce stade).
// Si plus tard on veut des requêtes plus riches, on pourra migrer vers
// un vrai TypeAdapter Hive.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/score_prediction.dart';
import '../models/user.dart';
import 'score_calculator.dart';

/// Service de prédiction de score officiel BEPC/BAC.
///
/// Combinaison : BKT (par compétence) + coefficients MEPST (par matière).
///
/// Usage typique depuis le Dashboard :
/// ```dart
/// final prediction = await ScorePredictor.instance.predictForUser(user);
/// Navigator.push(context, MaterialPageRoute(
///   builder: (_) => ScorePredictionScreen(prediction: prediction),
/// ));
/// ```
class ScorePredictor {
  ScorePredictor._();
  static final ScorePredictor instance = ScorePredictor._();

  static const String _boxName = 'score_predictions';
  static const String _historyKeyPrefix =
      'history_'; // history_<userId>
  static const Duration _historyRetention = Duration(days: 90);

  /// Calcule la prédiction pour l'utilisateur courant.
  ///
  /// [user] : l'élève courant. L'examen et la série sont déduits
  ///   automatiquement depuis [user.niveauScolaire] et [user.serie].
  /// [force] : si true, recalcule même si une prédiction récente
  ///   (moins de 1 heure) existe déjà.
  Future<ScorePrediction> predictForUser(
    AppUser user, {
    bool force = false,
  }) async {
    final examen = _inferExamen(user);
    final serie = user.serie;

    // Vérifie si on a une prédiction récente en cache (< 1h)
    if (!force) {
      final cached = await _getCachedPrediction(user.id);
      if (cached != null &&
          DateTime.now().difference(cached.predictedAt).inMinutes < 60) {
        return cached;
      }
    }

    final prediction = ScoreCalculator.predict(
      user: user,
      examen: examen,
      serie: serie,
    );

    // Persiste dans l'historique
    await _saveToHistory(user.id, prediction);

    return prediction;
  }

  /// Calcule une prédiction "fraîche" en force, sans utiliser le cache.
  Future<ScorePrediction> recalculate(AppUser user) async {
    return predictForUser(user, force: true);
  }

  /// Récupère l'historique des prédictions d'un utilisateur
  /// sur les 3 derniers mois (90 jours), ordonné du plus ancien
  /// au plus récent. Pratique pour le LineChart d'évolution.
  Future<List<ScorePrediction>> getHistory(
    String userId, {
    Duration retention = _historyRetention,
  }) async {
    try {
      final box = await _openBox();
      final raw = box.get('$_historyKeyPrefix$userId');
      if (raw == null) return [];

      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      final cutoff = DateTime.now().subtract(retention);

      final predictions = decoded
          .map((e) => ScorePrediction.fromJson(e as Map<String, dynamic>))
          .where((p) => p.predictedAt.isAfter(cutoff))
          .toList()
        ..sort((a, b) => a.predictedAt.compareTo(b.predictedAt));

      return predictions;
    } catch (e) {
      debugPrint('ScorePredictor.getHistory() error: $e');
      return [];
    }
  }

  /// Récupère la dernière prédiction en cache pour un utilisateur.
  Future<ScorePrediction?> getLastPrediction(String userId) async {
    final history = await getHistory(userId);
    if (history.isEmpty) return null;
    return history.last;
  }

  /// Supprime l'historique d'un utilisateur (RGPD / reset).
  Future<void> clearHistory(String userId) async {
    try {
      final box = await _openBox();
      await box.delete('$_historyKeyPrefix$userId');
    } catch (e) {
      debugPrint('ScorePredictor.clearHistory() error: $e');
    }
  }

  // ─── Internes ────────────────────────────────────────────────────

  Future<Box<String>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<String>(_boxName);
    }
    return Hive.openBox<String>(_boxName);
  }

  Future<ScorePrediction?> _getCachedPrediction(String userId) async {
    try {
      final box = await _openBox();
      final raw = box.get('$_historyKeyPrefix$userId');
      if (raw == null) return null;
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      if (decoded.isEmpty) return null;
      return ScorePrediction.fromJson(
        decoded.last as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('ScorePredictor._getCachedPrediction() error: $e');
      return null;
    }
  }

  Future<void> _saveToHistory(
    String userId,
    ScorePrediction prediction,
  ) async {
    try {
      final box = await _openBox();
      final key = '$_historyKeyPrefix$userId';
      final raw = box.get(key);
      List<dynamic> decoded = [];
      if (raw != null) {
        decoded = jsonDecode(raw) as List<dynamic>;
      }
      // On évite les doublons à la minute près
      if (decoded.isNotEmpty) {
        final last = ScorePrediction.fromJson(
          decoded.last as Map<String, dynamic>,
        );
        if (last.predictedAt.difference(prediction.predictedAt).inMinutes
                .abs() <
            1) {
          decoded.removeLast();
        }
      }
      decoded.add(prediction.toJson());

      // Nettoie les prédictions trop anciennes (> 90 jours)
      final cutoff = DateTime.now().subtract(_historyRetention);
      decoded = decoded.where((e) {
        final p = ScorePrediction.fromJson(e as Map<String, dynamic>);
        return p.predictedAt.isAfter(cutoff);
      }).toList();

      await box.put(key, jsonEncode(decoded));
    } catch (e) {
      debugPrint('ScorePredictor._saveToHistory() error: $e');
    }
  }

  /// Infère l'examen à partir du niveau scolaire de l'élève.
  ///
  /// Règles :
  ///   - "3eme" ou tout niveau primaire/collège -> "BEPC"
  ///   - "2nde", "1ere", "Terminale" ou "Tle"   -> "BAC" (série utilisée)
  ///   - sinon                                  -> "BEPC" (défaut)
  String _inferExamen(AppUser user) {
    final niveau = user.niveauScolaire.toLowerCase().trim();
    if (niveau.contains('3') ||
        niveau.contains('cm') ||
        niveau.contains('collège') ||
        niveau.contains('college')) {
      return 'BEPC';
    }
    if (niveau.contains('2') ||
        niveau.contains('1') ||
        niveau.contains('term') ||
        niveau.contains('tle') ||
        niveau.contains('lycée') ||
        niveau.contains('lycee')) {
      return 'BAC';
    }
    return 'BEPC';
  }
}
