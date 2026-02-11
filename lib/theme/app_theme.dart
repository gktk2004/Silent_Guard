import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        background: AppColors.background,
      ),
      textTheme: TextTheme(
        // Headings use Playfair Display (serif)
        displayLarge: GoogleFonts.playfairDisplay(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 48,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 32,
          letterSpacing: -0.5,
        ),
        displaySmall: GoogleFonts.playfairDisplay(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
        headlineMedium: GoogleFonts.playfairDisplay(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
        // Body text uses Montserrat (sans-serif)
        bodyLarge: GoogleFonts.montserrat(
          color: AppColors.textPrimary,
          fontSize: 16,
        ),
        bodyMedium: GoogleFonts.montserrat(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        bodySmall: GoogleFonts.montserrat(
          color: AppColors.textMuted,
          fontSize: 12,
        ),
        labelLarge: GoogleFonts.montserrat(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.playfairDisplay(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30), // Pill-shaped
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.03),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.goldAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: GoogleFonts.montserrat(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.montserrat(
          color: AppColors.textMuted,
          fontSize: 14,
        ),
      ),
    );
  }

  // Luna Card Decoration - White card with soft shadow and gold border
  static BoxDecoration lunaCardDecoration({
    double borderRadius = 24,
    bool showBorder = true,
    Color? backgroundColor,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? AppColors.surface,
      borderRadius: BorderRadius.circular(borderRadius),
      border: showBorder
          ? Border.all(color: AppColors.cardBorder, width: 1)
          : null,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 30,
          offset: const Offset(0, 10),
          spreadRadius: 0,
        ),
      ],
    );
  }

  // Legacy support - keep for backwards compatibility
  static BoxDecoration glassDecoration({
    double borderRadius = 24,
    bool showBorder = true,
  }) {
    return lunaCardDecoration(borderRadius: borderRadius, showBorder: showBorder);
  }
}
