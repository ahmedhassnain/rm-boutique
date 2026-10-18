import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// R&M Boutique brand colours (same as the logo and slides).
class AppColors {
  static const olive = Color(0xFF2F3A2C); // Deep Olive
  static const terracotta = Color(0xFFB4472C);
  static const sand = Color(0xFFE8DDCB);
  static const ivory = Color(0xFFFAF6EF);
  static const charcoal = Color(0xFF26292B);
  static const accentOnDark = Color(0xFFE58B6C);
}

class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.olive).copyWith(
      primary: AppColors.olive,
      onPrimary: AppColors.ivory,
      secondary: AppColors.terracotta,
      onSecondary: AppColors.ivory,
      error: AppColors.terracotta,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.ivory,
      textTheme: GoogleFonts.jostTextTheme(base.textTheme)
          .apply(bodyColor: AppColors.charcoal, displayColor: AppColors.olive),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.olive,
        foregroundColor: AppColors.ivory,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.olive,
          foregroundColor: AppColors.ivory,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
