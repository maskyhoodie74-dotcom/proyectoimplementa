import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const maroon = Color(0xFF6B1B2B);
  static const maroonDark = Color(0xFF4A1020);
  static const maroonDeep = Color(0xFF2D0A14);
  static const gold = Color(0xFFC9A84C);
  static const goldLight = Color(0xFFE8C96A);
  static const bgDark = Color(0xFF000000); // True black for iOS
  static const bgCard = Color(0xFF1C1C1E); // iOS dark card color
  static const bgCardLight = Color(0xFF2C2C2E); // iOS lighter card color
  static const textPrimary = Color(0xFFFFFFFF); // Pure white text
  static const textSecondary = Color(0x99EBEBF5); // iOS secondary text (60% opacity)
  static const success = Color(0xFF34C759); // iOS green
  static const error = Color(0xFFFF3B30); // iOS red
  static const divider = Color(0xFF38383A); // iOS separator

  // Premium Gradients
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFE8C96A), Color(0xFFC9A84C), Color(0xFF8B6B22)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradientDark = LinearGradient(
    colors: [Color(0xFFC9A84C), Color(0xFF8B6B22), Color(0xFF4A3810)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient maroonGradient = LinearGradient(
    colors: [Color(0xFF8A2337), Color(0xFF6B1B2B), Color(0xFF4A1020)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Premium Shadows
  static List<BoxShadow> goldGlow = [
    BoxShadow(
      color: gold.withOpacity(0.3),
      blurRadius: 12,
      spreadRadius: 2,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> glassShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.4),
      blurRadius: 16,
      spreadRadius: -2,
      offset: const Offset(0, 8),
    ),
  ];
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
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 34,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 28,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 22,
          letterSpacing: -0.5,
        ),
        titleMedium: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 17,
          letterSpacing: -0.4,
        ),
        bodyLarge: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 17,
          letterSpacing: -0.4,
        ),
        bodyMedium: GoogleFonts.inter(
          color: AppColors.textSecondary,
          fontSize: 15,
          letterSpacing: -0.2,
        ),
        labelLarge: GoogleFonts.inter(
          color: AppColors.bgDark,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
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
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgCardLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 15),
        hintStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 15),
        prefixIconColor: AppColors.textSecondary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.bgDark,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          textStyle: GoogleFonts.inter(
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
