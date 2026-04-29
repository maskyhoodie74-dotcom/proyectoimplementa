import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const maroon = Color(0xFF6B1B2B);
  static const maroonDark = Color(0xFF4A1020);
  static const maroonDeep = Color(0xFF2D0A14);
  static const gold = Color(0xFFC9A84C);
  static const goldLight = Color(0xFFE8C96A);
  static const bgDark = Color(0xFF0D0A0B);
  static const bgCard = Color(0xFF1A1215);
  static const bgCardLight = Color(0xFF231820);
  static const textPrimary = Color(0xFFF5F0E8);
  static const textSecondary = Color(0xFFB0A090);
  static const success = Color(0xFF4CAF76);
  static const error = Color(0xFFE53935);
  static const divider = Color(0xFF3A2530);
}

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDark,
      primaryColor: AppColors.maroon,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.maroon,
        secondary: AppColors.gold,
        surface: AppColors.bgCard,
        error: AppColors.error,
        onPrimary: AppColors.textPrimary,
        onSecondary: AppColors.bgDark,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.oswald(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 32,
          letterSpacing: 1.5,
        ),
        displayMedium: GoogleFonts.oswald(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 24,
          letterSpacing: 1.2,
        ),
        titleLarge: GoogleFonts.oswald(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 20,
          letterSpacing: 1.0,
        ),
        titleMedium: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        bodyLarge: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 15,
        ),
        bodyMedium: GoogleFonts.inter(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
        labelLarge: GoogleFonts.oswald(
          color: AppColors.bgDark,
          fontWeight: FontWeight.w600,
          fontSize: 15,
          letterSpacing: 1.5,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.oswald(
          color: AppColors.gold,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgCard,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgCardLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
        hintStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
        prefixIconColor: AppColors.textSecondary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.bgDark,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          textStyle: GoogleFonts.oswald(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),
    );
  }
}
