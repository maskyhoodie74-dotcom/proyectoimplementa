import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Core palette - deep maroon + gold
  static const maroon = Color(0xFF7B1D2D);
  static const maroonDark = Color(0xFF4A0E1A);
  static const maroonDeep = Color(0xFF200612);
  static const maroonAccent = Color(0xFF9C2438);
  static const gold = Color(0xFFD4AF37);
  static const goldLight = Color(0xFFEDD45A);
  static const goldDim = Color(0xFF9C810A);

  // iOS-style backgrounds — true black system
  static const bgDark = Color(0xFF000000);
  static const bgSecondary = Color(0xFF0A0A0A);
  static const bgCard = Color(0xFF1C1C1E);
  static const bgCardLight = Color(0xFF2C2C2E);
  static const bgCardGlass = Color(0xFF1C1C1ECC);
  static const bgElevated = Color(0xFF3A3A3C);

  // Text
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0x99EBEBF5);
  static const textTertiary = Color(0x60EBEBF5);

  // Semantic
  static const success = Color(0xFF32D74B); // iOS green
  static const error = Color(0xFFFF453A);   // iOS red
  static const warning = Color(0xFFFF9F0A); // iOS orange
  static const info = Color(0xFF0A84FF);    // iOS blue

  // Dividers & strokes
  static const divider = Color(0xFF38383A);
  static const stroke = Color(0xFF48484A);

  // Premium Gradients
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFEDD45A), Color(0xFFD4AF37), Color(0xFF9C810A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradientVertical = LinearGradient(
    colors: [Color(0xFFEDD45A), Color(0xFFD4AF37)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient goldGradientDark = LinearGradient(
    colors: [Color(0xFFD4AF37), Color(0xFF9C810A), Color(0xFF4A3810)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient maroonGradient = LinearGradient(
    colors: [Color(0xFF9C2438), Color(0xFF7B1D2D), Color(0xFF4A0E1A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient heroBg = LinearGradient(
    colors: [Color(0xFF200612), Color(0xFF0D000A), Color(0xFF000000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF2C2020), Color(0xFF1C1C1E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadows
  static List<BoxShadow> goldGlow = [
    BoxShadow(
      color: gold.withOpacity(0.4),
      blurRadius: 20,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: gold.withOpacity(0.15),
      blurRadius: 40,
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> goldGlowSubtle = [
    BoxShadow(
      color: gold.withOpacity(0.2),
      blurRadius: 12,
      spreadRadius: 0,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.5),
      blurRadius: 20,
      spreadRadius: -4,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> glassShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.5),
      blurRadius: 24,
      spreadRadius: -4,
      offset: const Offset(0, 12),
    ),
    BoxShadow(
      color: gold.withOpacity(0.05),
      blurRadius: 40,
      spreadRadius: 0,
      offset: const Offset(0, 0),
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
      useMaterial3: true,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 34,
          letterSpacing: -1.0,
          height: 1.1,
        ),
        displayMedium: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 28,
          letterSpacing: -0.8,
          height: 1.15,
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
          letterSpacing: -0.3,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          color: AppColors.textSecondary,
          fontSize: 15,
          letterSpacing: -0.2,
          height: 1.4,
        ),
        labelLarge: GoogleFonts.inter(
          color: AppColors.bgDark,
          fontWeight: FontWeight.w700,
          fontSize: 15,
          letterSpacing: 0.5,
        ),
        labelSmall: GoogleFonts.inter(
          color: AppColors.textSecondary,
          fontSize: 11,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w700,
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
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgCardLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 15),
        hintStyle: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 15),
        prefixIconColor: AppColors.textSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.bgDark,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 0.5,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.bgCardLight,
        contentTextStyle: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
