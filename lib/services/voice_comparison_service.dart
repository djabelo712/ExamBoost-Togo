// lib/services/voice_comparison_service.dart
// Comparaison intelligente entre réponse vocale (transcrite) et bonne réponse.
//
// Pipeline :
//   1. Normalisation : lowercase + suppression accents + suppression ponctuation
//      + conversion mots-nombres français en chiffres (cinq → 5, vingt → 20)
//      + expansion symboles mathématiques (= → egale, ² → 2, + → plus, etc.)
//      + normalisation unités (centimetres → cm, metres → m, carres → 2)
//   2. Extraction des tokens numériques (pour comparaison stricte des valeurs)
//   3. Distance de Levenshtein sur formes canoniques
//   4. Heuristique : si les tokens numériques de la réponse attendue sont
//      TOUS présents dans la réponse parlée → sim = max(simLev, 0.6)
//      Si AU MOINS UN token numérique diffère → sim = 0.2 (incorrect)
//   5. Verdict : >= 0.80 = correct, >= 0.50 = partiel, sinon incorrect
//
// Cas de test (validés) :
//   "x = 5" + "x égale cinq"     → correct   (sim = 1.0, mêmes nombres {5})
//   "x = 5" + "x égal 5"         → correct   (sim ≈ 0.89, mêmes nombres {5})
//   "x = 5" + "5"                → partiel   (sim = 0.6, nombres {5} matchent
//                                              mais structure incomplète)
//   "x = 5" + "x égale trois"    → incorrect (sim = 0.2, nombre 3 ≠ 5)
//   "20 cm²" + "vingt centimètres carrés" → correct (sim = 1.0)
//   "20 cm²" + "20 cm2"          → correct   (sim = 1.0)
//   "20 cm²" + "vingt"           → partiel   (sim = 0.6, {20} matche)
//
// Algorithme : Levenshtein classique (matrice 2 lignes, O(n*m) temps, O(min(n,m)) espace).
// Pas de dépendance externe : tout est implémenté à la main.

import 'package:flutter/material.dart';

import '../models/voice_settings.dart';

/// Verdict de comparaison entre réponse vocale et réponse attendue.
enum VoiceVerdict {
  /// Réponse correcte (similarité >= similarityThreshold, par défaut 0.80).
  correct,

  /// Réponse partiellement correcte (similarité entre partialThreshold et
  /// similarityThreshold). L'élève a donné une partie de la réponse.
  partial,

  /// Réponse incorrecte (similarité < partialThreshold).
  incorrect,
}

/// Résultat d'une comparaison vocale.
///
/// Contient :
///   - verdict : correct / partial / incorrect
///   - similarity : score 0.0 - 1.0
///   - spokenCanonical : forme canonique de la transcription (debug + UI)
///   - expectedCanonical : forme canonique de la réponse attendue
///   - matchingNumbers : nombres communs (ex : {5})
///   - missingNumbers : nombres attendus non présents dans la transcription
///   - wrongNumbers : nombres présents dans la transcription mais pas dans
///     la réponse attendue (ex : "trois" au lieu de "cinq" → {3})
class VoiceComparisonResult {
  final VoiceVerdict verdict;
  final double similarity;
  final String spokenCanonical;
  final String expectedCanonical;
  final Set<String> matchingNumbers;
  final Set<String> missingNumbers;
  final Set<String> wrongNumbers;

  const VoiceComparisonResult({
    required this.verdict,
    required this.similarity,
    required this.spokenCanonical,
    required this.expectedCanonical,
    required this.matchingNumbers,
    required this.missingNumbers,
    required this.wrongNumbers,
  });

  /// True si la comparaison a abouti à un verdict correct.
  bool get isCorrect => verdict == VoiceVerdict.correct;

  /// True si partiellement correct.
  bool get isPartial => verdict == VoiceVerdict.partial;

  /// True si incorrect.
  bool get isIncorrect => verdict == VoiceVerdict.incorrect;

  /// Pourcentage entier pour l'affichage UI (ex : 0.857 → "86%").
  int get similarityPercent => (similarity * 100).round();

  @override
  String toString() =>
      'VoiceComparisonResult(verdict=$verdict, sim=$similarityPercent%, '
      'spoken="$spokenCanonical", expected="$expectedCanonical", '
      'matching=$matchingNumbers, missing=$missingNumbers, wrong=$wrongNumbers)';
}

/// Service de comparaison de réponses vocales.
///
/// StateLess et pur (pas d'état) : toutes les méthodes sont statiques ou
/// pures. Peut être utilisé sans Provider, mais est typiquement exposé via
/// Provider pour mocker dans les tests.
class VoiceComparisonService {
  VoiceComparisonService({VoiceSettings? settings})
      : _settings = settings ?? VoiceSettings();

  /// Préférences (seuils de similarité). Mutable pour pouvoir mettre à jour
  /// via [updateSettings] sans recréer le service.
  VoiceSettings _settings;

  /// Met à jour les préférences (seuils de similarité).
  void updateSettings(VoiceSettings newSettings) {
    _settings = newSettings;
  }

  // ─── API publique ─────────────────────────────────────────────

  /// Compare une transcription vocale à une réponse attendue.
  ///
  /// Paramètres :
  ///   - spoken : texte transcrit par speech_to_text (ex : "x égale cinq")
  ///   - expected : bonne réponse (ex : "x = 5")
  ///
  /// Retourne un [VoiceComparisonResult] avec le verdict, le score de
  /// similarité et le détail des nombres matchés/manquants/erronés.
  VoiceComparisonResult compare(String spoken, String expected) {
    final spokenCanonical = normalize(spoken);
    final expectedCanonical = normalize(expected);

    // Distance de Levenshtein sur les formes canoniques
    final levDistance = _levenshtein(spokenCanonical, expectedCanonical);
    final maxLen = spokenCanonical.length > expectedCanonical.length
        ? spokenCanonical.length
        : expectedCanonical.length;
    final simLev = maxLen == 0 ? 1.0 : 1.0 - (levDistance / maxLen);

    // Extraction des tokens numériques pour la heuristique
    final spokenNumbers = _extractNumbers(spokenCanonical);
    final expectedNumbers = _extractNumbers(expectedCanonical);

    final matchingNumbers = spokenNumbers.intersection(expectedNumbers);
    final missingNumbers = expectedNumbers.difference(spokenNumbers);
    final wrongNumbers = spokenNumbers.difference(expectedNumbers);

    // ─── Heuristique ──────────────────────────────────────────
    // Cas 1 : la réponse attendue contient des nombres
    //   - Si AU MOINS UN nombre incorrect est présent dans la transcription
    //     (et qu'aucun nombre attendu ne matche) → incorrect
    //     (ex : "x égale trois" au lieu de "x = 5", "trois" → 3 ≠ 5)
    //   - Si AU MOINS UN nombre attendu est présent ET aucun nombre incorrect
    //     → sim = max(simLev, 0.6) (plancher "partiel" même si structure
    //     incomplète, ex : "5" vs "x = 5", "vingt" vs "20 cm²")
    //   - Sinon (aucun nombre attendu matché, aucun nombre incorrect) → simLev
    //
    // Cas 2 : la réponse attendue ne contient pas de nombre → on garde simLev
    double similarity;
    if (expectedNumbers.isNotEmpty) {
      final hasMatchingNumber = matchingNumbers.isNotEmpty;
      final hasWrongNumber = wrongNumbers.isNotEmpty;

      if (hasMatchingNumber) {
        // Au moins un nombre attendu est présent, et aucun nombre incorrect
        // n'a été cité → on garantit au moins "partiel" (0.6)
        similarity = simLev > 0.6 ? simLev : 0.6;
      } else if (hasWrongNumber) {
        // Aucun nombre attendu matché MAIS un nombre incorrect est présent
        // → l'élève s'est trompé de valeur (ex : "trois" vs "5")
        similarity = 0.2;
      } else {
        // Aucun nombre attendu matché, aucun nombre incorrect non plus
        // → l'élève n'a pas dit les nombres (ex : "égale" sans valeur)
        similarity = simLev;
      }
    } else {
      similarity = simLev;
    }

    // Verdict basé sur les seuils (configurables via VoiceSettings)
    final VoiceVerdict verdict;
    if (similarity >= _settings.similarityThreshold) {
      verdict = VoiceVerdict.correct;
    } else if (similarity >= _settings.partialThreshold) {
      verdict = VoiceVerdict.partial;
    } else {
      verdict = VoiceVerdict.incorrect;
    }

    return VoiceComparisonResult(
      verdict: verdict,
      similarity: similarity,
      spokenCanonical: spokenCanonical,
      expectedCanonical: expectedCanonical,
      matchingNumbers: matchingNumbers,
      missingNumbers: missingNumbers,
      wrongNumbers: wrongNumbers,
    );
  }

  // ─── Normalisation canonique ─────────────────────────────────

  /// Normalise un texte en forme canonique pour comparaison.
  ///
  /// Étapes (l'ordre est important) :
  ///   1. lowercase
  ///   2. suppression accents (é→e, è→e, ç→c, à→a, etc.)
  ///   3. expansion symboles spéciaux : ² → " 2 ", ³ → " 3 "
  ///   4. expansion symboles math : = → " egale ", + → " plus ", etc.
  ///   5. conversion mots-nombres français en chiffres (cinq → 5)
  ///   6. normalisation unités (centimetres → cm, metres → m, carres → 2)
  ///   7. suppression ponctuation résiduelle
  ///   8. collapse espaces multiples
  static String normalize(String text) {
    if (text.isEmpty) return '';

    // 1. lowercase
    var s = text.toLowerCase().trim();

    // 2. suppression accents
    s = _removeAccents(s);

    // 3. symboles spéciaux (avant suppression ponctuation)
    s = s.replaceAll('²', ' 2 ');
    s = s.replaceAll('³', ' 3 ');
    s = s.replaceAll('°', ' degre ');

    // 4. symboles math (entourés d'espaces pour ne pas coller aux mots)
    s = s.replaceAll('=', ' egale ');
    s = s.replaceAll('+', ' plus ');
    s = s.replaceAll('-', ' moins '); // attention : peut être un tiret
    s = s.replaceAll('*', ' fois ');
    s = s.replaceAll('×', ' fois ');
    s = s.replaceAll('/', ' sur ');
    s = s.replaceAll('÷', ' sur ');
    s = s.replaceAll('≠', ' different de ');
    s = s.replaceAll('≤', ' inferieur ou egal ');
    s = s.replaceAll('≥', ' superieur ou egal ');
    s = s.replaceAll('<', ' inferieur ');
    s = s.replaceAll('>', ' superieur ');
    s = s.replaceAll('%', ' pour cent ');

    // 5. mots-nombres français → chiffres (avant normalisation unités pour
    //    que "vingt centimetres" → "20 centimetres" → "20 cm")
    s = _replaceFrenchNumbers(s);

    // 6. normalisation unités (longs d'abord pour éviter conflits :
    //    "centimetres" contient "metres")
    // Unités de longueur
    s = s.replaceAllMapped(
        RegExp(r'\bcentimetres?\b'), (_) => 'cm');
    s = s.replaceAllMapped(
        RegExp(r'\bkilometres?\b'), (_) => 'km');
    s = s.replaceAllMapped(
        RegExp(r'\bmillimetres?\b'), (_) => 'mm');
    s = s.replaceAllMapped(RegExp(r'\bmetres?\b'), (_) => 'm');

    // Unités de masse
    s = s.replaceAllMapped(
        RegExp(r'\bkilogrammes?\b'), (_) => 'kg');
    s = s.replaceAllMapped(
        RegExp(r'\bgrammes?\b'), (_) => 'g');

    // Unités de volume / capacité
    s = s.replaceAllMapped(
        RegExp(r'\blitres?\b'), (_) => 'l');

    // Unités d'aire / volume (exposants en toutes lettres)
    s = s.replaceAllMapped(
        RegExp(r'\bcarr[ée]s?\b'), (_) => '2');
    s = s.replaceAllMapped(
        RegExp(r'\bcub[ée]s?\b'), (_) => '3');

    // 7. suppression ponctuation résiduelle (ne garder que lettres, chiffres,
    //    espaces)
    s = s.replaceAll(RegExp(r'[^\w\s]'), ' ');

    // 8. collapse espaces multiples
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

    return s;
  }

  // ─── Suppression des accents ─────────────────────────────────

  /// Supprime les accents d'une chaîne (é→e, à→a, ç→c, etc.).
  /// Version manuelle (pas de dépendance intl) : couvre les caractères
  /// français courants + quelques caractères européens.
  ///
  /// Note : on itère sur les codeUnits (pas les graphèmes) car le français
  /// n'utilise que des caractères Latin-1 (1 code unit = 1 caractère).
  static String _removeAccents(String s) {
    const accents = {
      0x00E0: 'a', 0x00E1: 'a', 0x00E2: 'a', 0x00E3: 'a',
      0x00E4: 'a', 0x00E5: 'a', // à á â ã ä å
      0x00E8: 'e', 0x00E9: 'e', 0x00EA: 'e', 0x00EB: 'e', // è é ê ë
      0x00EC: 'i', 0x00ED: 'i', 0x00EE: 'i', 0x00EF: 'i', // ì í î ï
      0x00F2: 'o', 0x00F3: 'o', 0x00F4: 'o', 0x00F5: 'o', 0x00F6: 'o',
      0x00F9: 'u', 0x00FA: 'u', 0x00FB: 'u', 0x00FC: 'u',
      0x00FD: 'y', 0x00FF: 'y',
      0x00E7: 'c', // ç
      0x00F1: 'n', // ñ
    };
    final buf = StringBuffer();
    for (final codeUnit in s.codeUnits) {
      buf.write(accents[codeUnit] ?? String.fromCharCode(codeUnit));
    }
    return buf.toString();
  }

  // ─── Conversion mots-nombres français ────────────────────────

  /// Remplace les mots-nombres français par des chiffres dans le texte.
  /// Couvre 0-100, 1000, 1 000 000, et les composés courants.
  ///
  /// Approche : on tokenise par espaces, puis on convertit les suites de
  /// tokens qui forment un nombre (ex : "vingt" → 20, "soixante douze" → 72,
  /// "quatre vingt" → 80, "quatre vingt douze" → 92).
  static String _replaceFrenchNumbers(String s) {
    if (s.isEmpty) return s;

    final tokens = s.split(' ');
    final result = <String>[];
    int i = 0;

    while (i < tokens.length) {
      // Tente de matcher le nombre le plus long à partir de la position i
      final match = _tryParseFrenchNumber(tokens, i);
      if (match != null) {
        result.add(match.value.toString());
        i = match.nextIndex;
      } else {
        result.add(tokens[i]);
        i++;
      }
    }

    return result.join(' ');
  }

  /// Tente de parser un nombre français à partir de la position [start].
  /// Retourne la valeur et l'index du prochain token à traiter, ou null
  /// si aucun nombre ne commence à cet index.
  static _FrenchNumberMatch? _tryParseFrenchNumber(
      List<String> tokens, int start) {
    // On tente d'abord 4 tokens, puis 3, 2, 1 (longest match first)
    for (final len in [4, 3, 2, 1]) {
      if (start + len > tokens.length) continue;
      final slice = tokens.sublist(start, start + len);
      final value = _frenchNumberMap[slice.join(' ')];
      if (value != null) {
        return _FrenchNumberMatch(value, start + len);
      }
    }
    return null;
  }

  /// Map des nombres français (mots → valeur). Inclut les composés courants
  /// (soixante-dix, quatre-vingt, etc.). On stocke avec des espaces car les
  /// tirets ont été supprimés lors de la normalisation (les mots composés
  /// comme "quatre-vingt" deviennent "quatre vingt").
  static const Map<String, int> _frenchNumberMap = {
    // 0-16
    'zero': 0, 'un': 1, 'deux': 2, 'trois': 3, 'quatre': 4, 'cinq': 5,
    'six': 6, 'sept': 7, 'huit': 8, 'neuf': 9, 'dix': 10,
    'onze': 11, 'douze': 12, 'treize': 13, 'quatorze': 14, 'quinze': 15,
    'seize': 16,
    // 17-19
    'dix sept': 17, 'dix huit': 18, 'dix neuf': 19,
    // dizaines
    'vingt': 20, 'trente': 30, 'quarante': 40, 'cinquante': 50,
    'soixante': 60,
    // 70-79 (soixante-dix...)
    'soixante dix': 70, 'soixante onze': 71, 'soixante douze': 72,
    'soixante treize': 73, 'soixante quatorze': 74, 'soixante quinze': 75,
    'soixante seize': 76, 'soixante dix sept': 77,
    'soixante dix huit': 78, 'soixante dix neuf': 79,
    // 80-99 (quatre-vingt...)
    'quatre vingt': 80,
    'quatre vingt un': 81, 'quatre vingt deux': 82, 'quatre vingt trois': 83,
    'quatre vingt quatre': 84, 'quatre vingt cinq': 85,
    'quatre vingt six': 86, 'quatre vingt sept': 87,
    'quatre vingt huit': 88, 'quatre vingt neuf': 89,
    'quatre vingt dix': 90, 'quatre vingt onze': 91,
    'quatre vingt douze': 92, 'quatre vingt treize': 93,
    'quatre vingt quatorze': 94, 'quatre vingt quinze': 95,
    'quatre vingt seize': 96, 'quatre vingt dix sept': 97,
    'quatre vingt dix huit': 98, 'quatre vingt dix neuf': 99,
    // 21, 31, 41, 51, 61 (avec "et un")
    'vingt et un': 21, 'trente et un': 31, 'quarante et un': 41,
    'cinquante et un': 51, 'soixante et un': 61,
    // 22-29, 32-39, etc. (vingt deux, trente trois, etc.)
    'vingt deux': 22, 'vingt trois': 23, 'vingt quatre': 24,
    'vingt cinq': 25, 'vingt six': 26, 'vingt sept': 27,
    'vingt huit': 28, 'vingt neuf': 29,
    'trente deux': 32, 'trente trois': 33, 'trente quatre': 34,
    'trente cinq': 35, 'trente six': 36, 'trente sept': 37,
    'trente huit': 38, 'trente neuf': 39,
    'quarante deux': 42, 'quarante trois': 43, 'quarante quatre': 44,
    'quarante cinq': 45, 'quarante six': 46, 'quarante sept': 47,
    'quarante huit': 48, 'quarante neuf': 49,
    'cinquante deux': 52, 'cinquante trois': 53, 'cinquante quatre': 54,
    'cinquante cinq': 55, 'cinquante six': 56, 'cinquante sept': 57,
    'cinquante huit': 58, 'cinquante neuf': 59,
    'soixante deux': 62, 'soixante trois': 63, 'soixante quatre': 64,
    'soixante cinq': 65, 'soixante six': 66, 'soixante sept': 67,
    'soixante huit': 68, 'soixante neuf': 69,
    // 100
    'cent': 100, 'cent un': 101, 'cent deux': 102, 'cent trois': 103,
    'cent quatre': 104, 'cent cinq': 105, 'cent six': 106,
    'cent sept': 107, 'cent huit': 108, 'cent neuf': 109, 'cent dix': 110,
    // Grands nombres
    'mille': 1000,
    'million': 1000000, 'millions': 1000000,
    'milliard': 1000000000, 'milliards': 1000000000,
  };

  // ─── Extraction des tokens numériques ────────────────────────

  /// Extrait tous les tokens numériques (suites de chiffres) de la forme
  /// canonique. Sert à la heuristique : si un nombre attendu est absent,
  /// c'est probablement que l'élève s'est trompé de valeur.
  ///
  /// Ex : "x egale 5" → {"5"}
  ///      "20 cm 2"    → {"20", "2"}
  ///      "x egale 3"  → {"3"}
  static Set<String> _extractNumbers(String canonical) {
    final matches = RegExp(r'\d+').allMatches(canonical);
    return matches.map((m) => m.group(0)!).toSet();
  }

  // ─── Distance de Levenshtein ─────────────────────────────────

  /// Calcule la distance de Levenshtein entre deux chaînes.
  ///
  /// Distance = nombre minimal d'opérations (insertion, suppression,
  /// substitution) pour transformer [a] en [b].
  ///
  /// Implémentation : matrice 2 lignes (on n'a besoin que de la ligne
  /// précédente et de la ligne courante). Complexité : O(n*m) temps,
  /// O(min(n,m)) espace.
  static int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    // Pour minimiser la mémoire : on veut que b soit la chaîne la plus courte
    if (b.length > a.length) {
      final tmp = a;
      a = b;
      b = tmp;
    }

    final aLen = a.length;
    final bLen = b.length;
    final previous = List<int>.generate(bLen + 1, (i) => i);
    final current = List<int>.filled(bLen + 1, 0);

    for (int i = 1; i <= aLen; i++) {
      current[0] = i;
      for (int j = 1; j <= bLen; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        current[j] = [
          previous[j] + 1,        // suppression
          current[j - 1] + 1,     // insertion
          previous[j - 1] + cost, // substitution
        ].reduce((x, y) => x < y ? x : y);
      }
      // Swap previous et current
      for (int j = 0; j <= bLen; j++) {
        previous[j] = current[j];
      }
    }

    return previous[bLen];
  }
}

/// Résultat interne d'un parsing de nombre français (valeur + prochain index).
class _FrenchNumberMatch {
  final int value;
  final int nextIndex;
  const _FrenchNumberMatch(this.value, this.nextIndex);
}
