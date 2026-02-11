import 'package:flutter/material.dart';

class AppColors {
  // Luna Light Theme - Warm & Premium
  static const Color background = Color(0xFFFDFBF7); // Warm cream / Pearl white
  static const Color surface = Color(0xFFFFFFFF); // Pure white for cards
  static const Color surfaceLight = Color(0xFFFEFEFE); // Slightly off-white
  
  // Primary accent colors
  static const Color primary = Color(0xFFE5BBA1); // Muted Rose (buttons)
  static const Color secondary = Color(0xFFC5A059); // Secondary Gold (icons, active states)
  static const Color accent = Color(0xFFE5BBA1); // Muted Rose accent
  
  // Typography colors
  static const Color textPrimary = Color(0xFF4A4238); // Soft charcoal brown
  static const Color textSecondary = Color(0xFF8B7E74); // Muted brown
  static const Color textMuted = Color(0xFFB5ACA3); // Light brown/taupe
  
  // Status colors (softer versions for Luna aesthetic)
  static const Color success = Color(0xFF88C4A8); // Soft sage green
  static const Color warning = Color(0xFFE5BBA1); // Muted rose (same as primary)
  static const Color error = Color(0xFFD4A5A5); // Soft dusty rose
  
  // Luna-specific colors
  static const Color goldAccent = Color(0xFFC5A059); // Gold for icons and highlights
  static const Color cardBorder = Color(0xFFE8DFD6); // Subtle gold-tinted border
  
  // Glass/Card styling
  static Color glassBackground = Colors.white.withOpacity(0.7);
  static Color glassBorder = const Color(0xFFC5A059).withOpacity(0.2); // Gold border
  
  // Gradients for Luna aesthetic
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFEE6D9), Color(0xFFD4E9F2)], // Pale Peach to Misty Blue
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFEE6D9), Color(0xFFD4E9F2)], // Soft gradient for cards
    begin: Alignment(0.0, -1.0),
    end: Alignment(0.0, 1.0),
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFE5BBA1), Color(0xFFD4A095)], // Rose gradient
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
