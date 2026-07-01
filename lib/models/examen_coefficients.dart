// lib/models/examen_coefficients.dart
// Coefficients officiels BEPC / BAC du Ministère togolais de l'Enseignement
// Primaire, Secondaire et Technique (MEPST).
//
// IMPORTANT : Coefficients à valider avec MEPST officiellement.
// Les valeurs ci-dessous sont basées sur la pratique commune des examens
// BEPC / BAC en Afrique francophone (Côte d'Ivoire, Sénégal, Burkina, Mali)
// et constituent un point de départ réaliste. Une fois le document officiel
// MEPST récupéré, ajuster les Maps statiques ci-dessous.
//
// Différenciateur ExamBoost vs Khan Academy / Afrilearn :
// nous pondérons par les coefficients officiels du Togo, pas générique.

/// Coefficients officiels MEPST par examen et série.
///
/// Méthode de calcul du score pondéré :
///   score = Σ (note_matiere × coef_matiere) / Σ coef_matiere
///
/// Toutes les notes sont sur 20. Le score pondéré est donc aussi sur 20.
class ExamenCoefficients {
  ExamenCoefficients._(); // classe utilitaire — pas d'instance

  // ─── BEPC (Brevet d'Études du Premier Cycle) ─────────────────────
  // Coefficients à valider avec MEPST officiel.
  static const Map<String, int> bepc = {
    'Mathématiques': 4,
    'Français': 4,
    'Sciences Physiques': 3,
    'Sciences de la Vie et de la Terre': 3,
    'Histoire-Géographie': 3,
    'Anglais': 2,
    'Éducation Physique et Sportive': 1,
    'Travaux Manuels': 1,
  };

  // ─── BAC série A (série littéraire) ──────────────────────────────
  // Coefficients à valider avec MEPST officiel.
  static const Map<String, int> bacA = {
    'Français': 6,
    'Philosophie': 5,
    'Anglais': 4,
    'Histoire-Géographie': 4,
    'Mathématiques': 2,
    'Sciences Physiques': 2,
    'Sciences de la Vie et de la Terre': 2,
  };

  // ─── BAC série B (sciences économiques et sociales) ──────────────
  // Coefficients à valider avec MEPST officiel.
  static const Map<String, int> bacB = {
    'Économie': 6,
    'Mathématiques': 5,
    'Histoire-Géographie': 4,
    'Français': 3,
    'Philosophie': 3,
    'Anglais': 3,
    'Sciences Physiques': 2,
  };

  // ─── BAC série C (sciences mathématiques et physiques) ───────────
  // Coefficients à valider avec MEPST officiel.
  static const Map<String, int> bacC = {
    'Mathématiques': 6,
    'Sciences Physiques': 6,
    'Sciences de la Vie et de la Terre': 2,
    'Français': 2,
    'Philosophie': 2,
    'Anglais': 2,
    'Histoire-Géographie': 1,
    'Travaux Pratiques': 2,
  };

  // ─── BAC série D (sciences naturelles) ───────────────────────────
  // Coefficients à valider avec MEPST officiel.
  static const Map<String, int> bacD = {
    'Sciences de la Vie et de la Terre': 6,
    'Sciences Physiques': 5,
    'Mathématiques': 4,
    'Français': 2,
    'Philosophie': 2,
    'Anglais': 2,
    'Histoire-Géographie': 1,
  };

  // ─── BAC série F (série technique) ───────────────────────────────
  // Coefficients à valider avec MEPST officiel.
  // Sous-séries F1/F2/F3 à affiner avec MEPST — version générique ici.
  static const Map<String, int> bacF = {
    'Mathématiques': 5,
    'Sciences Physiques': 4,
    'Technologie': 6,
    'Français': 2,
    'Philosophie': 2,
    'Anglais': 2,
  };

  /// Toutes les séries BAC supportées (ordonnées alphabétiquement).
  static const List<String> seriesBac = ['A', 'B', 'C', 'D', 'F'];

  /// Libellés lisibles des séries BAC pour l'UI.
  static const Map<String, String> seriesLabels = {
    'A': 'Série A — Littéraire',
    'B': 'Série B — Sciences économiques',
    'C': 'Série C — Mathématiques et Physique',
    'D': 'Série D — Sciences naturelles',
    'F': 'Série F — Technique',
  };

  /// Récupère les coefficients d'un examen.
  ///
  /// [examen] : "BEPC", "BAC", "BAC1", "BAC2", "Probatoire"
  /// [serie]  : "A", "B", "C", "D", "F" (null pour BEPC)
  static Map<String, int> get(String examen, [String? serie]) {
    final normalized = _normalizeExamen(examen);
    if (normalized == 'BEPC') return bepc;
    if (normalized == 'BAC') {
      switch (serie?.toUpperCase()) {
        case 'A':
          return bacA;
        case 'B':
          return bacB;
        case 'C':
          return bacC;
        case 'D':
          return bacD;
        case 'F':
          return bacF;
        default:
          // Série D par défaut (la plus fréquente au Togo)
          return bacD;
      }
    }
    // Fallback conservateur
    return bepc;
  }

  /// Total des coefficients (somme).
  static int total(String examen, [String? serie]) {
    return get(examen, serie).values.fold(0, (a, b) => a + b);
  }

  /// Coefficient d'une matière spécifique.
  static int coefficient(String examen, String? serie, String matiere) {
    return get(examen, serie)[matiere] ?? 0;
  }

  /// Liste ordonnée des matières par coefficient descendant.
  /// Utile pour l'affichage du breakdown.
  static List<MapEntry<String, int>> sortedByCoefDesc(
    String examen, [
    String? serie,
  ]) {
    final entries = get(examen, serie).entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  /// Normalise l'étiquette d'examen.
  /// "BAC1", "BAC2", "Probatoire", "BAC" -> "BAC"
  /// "BEPC", "Bepc", "bepc"              -> "BEPC"
  static String _normalizeExamen(String examen) {
    final upper = examen.toUpperCase().trim();
    if (upper.startsWith('BAC')) return 'BAC';
    if (upper == 'PROBATOIRE') return 'BAC'; // Probatoire ≈ BAC1
    if (upper.startsWith('BEPC')) return 'BEPC';
    return upper;
  }

  /// Libellé lisible d'un examen (ex: "BEPC", "BAC série C").
  static String label(String examen, [String? serie]) {
    final normalized = _normalizeExamen(examen);
    if (normalized == 'BEPC') return 'BEPC';
    if (normalized == 'BAC' && serie != null && serie.isNotEmpty) {
      return 'BAC série ${serie.toUpperCase()}';
    }
    return normalized;
  }
}
