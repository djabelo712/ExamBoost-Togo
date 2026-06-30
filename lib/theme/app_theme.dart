// lib/theme/app_theme.dart
// Thème principal d'ExamBoost Togo
// Palette : vert forêt (couleur nationale Togo) + orange chaleureux + blanc cassé

import 'package:flutter/material.dart';

class AppColors {
  // ─── Couleurs primaires ────────────────────────────────────────
  static const Color primary        = Color(0xFF006837); // Vert Togo
  static const Color primaryLight   = Color(0xFF4CAF7A);
  static const Color primaryDark    = Color(0xFF004A26);
  static const Color primarySurface = Color(0xFFE8F5ED);

  // ─── Couleurs secondaires ─────────────────────────────────────
  static const Color accent         = Color(0xFFD97700); // Orange chaleureux
  static const Color accentLight    = Color(0xFFFFB74D);
  static const Color accentSurface  = Color(0xFFFFF3E0);

  // ─── Sémantique ───────────────────────────────────────────────
  static const Color success        = Color(0xFF2E7D32);
  static const Color warning        = Color(0xFFF57C00);
  static const Color error          = Color(0xFFC62828);
  static const Color info           = Color(0xFF1565C0);

  // ─── Niveaux de difficulté (SRS) ──────────────────────────────
  static const Color facile         = Color(0xFF2E7D32); // Vert
  static const Color moyen          = Color(0xFF1565C0); // Bleu
  static const Color difficile      = Color(0xFFD97700); // Orange
  static const Color echec          = Color(0xFFC62828); // Rouge

  // ─── Neutres ──────────────────────────────────────────────────
  static const Color background     = Color(0xFFF8F9FA);
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F3F4);
  static const Color divider        = Color(0xFFE0E0E0);
  static const Color textPrimary    = Color(0xFF1A1A1A);
  static const Color textSecondary  = Color(0xFF757575);
  static const Color textDisabled   = Color(0xFFBDBDBD);
}

class AppTextStyles {
  static const String fontFamily = 'Roboto';

  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.35,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  static const TextStyle questionText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.6,
  );
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTextStyles.fontFamily,

      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        background: AppColors.background,
        error: AppColors.error,
      ),

      scaffoldBackgroundColor: AppColors.background,

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.h3,
      ),

      cardTheme: CardTheme(
        color: AppColors.surface,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: AppTextStyles.button,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.button,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textDisabled),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.primarySurface,
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),
    );
  }
}
