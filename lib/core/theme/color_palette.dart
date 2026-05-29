import 'package:flutter/material.dart';

class ColorPalette {
  // Neo-Brutalism Palette
  static const Color background = Color(0xFFF4F4F0); // Off-white/light gray
  static const Color surface = Color(0xFFFFFFFF); // Pure white
  static const Color surfaceLighter = Color(0xFFFFFFFF); 
  
  static const Color primary = Color(0xFFFF3366); // Hot Pink
  static const Color primaryDark = Color(0xFFCC0033); 
  static const Color secondary = Color(0xFF00E5FF); // Cyan
  static const Color secondaryDark = Color(0xFF00B3CC);
  static const Color tertiary = Color(0xFFFFD500); // Bright Yellow
  
  static const Color success = Color(0xFF00FF66); // Neon Green
  static const Color error = Color(0xFFFF3333); // Bright Red
  static const Color warning = Color(0xFFFFD500); // Bright Yellow

  static const Color textPrimary = Color(0xFF111111); // Almost black
  static const Color textSecondary = Color(0xFF444444); // Dark gray
  static const Color textDark = Color(0xFF000000); // Pure black

  // Crossword Cells
  static const Color cellNormal = Color(0xFFFFFFFF);
  static const Color cellSelected = Color(0xFF00E5FF);
  static const Color cellCursor = Color(0xFFFFD500);
  static const Color cellCorrect = Color(0xFF00FF66);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF00E5FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFF1E1A33), Color(0xFF161324)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const LinearGradient correctGradient = LinearGradient(
    colors: [Color(0xFF00E676), Color(0xFF00C853)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
