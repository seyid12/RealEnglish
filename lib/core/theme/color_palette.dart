import 'package:flutter/material.dart';

class ColorPalette {
  // Backgrounds
  static const Color background = Color(0xFF0B0914); // Deep Cosmic Black/Purple
  static const Color surface = Color(0xFF161324);    // Card Surface
  static const Color surfaceLighter = Color(0xFF251F3D); 

  // Accents & Neon
  static const Color primary = Color(0xFF00E5FF);    // Neon Cyan
  static const Color primaryDark = Color(0xFF008B99); 
  static const Color secondary = Color(0xFF7C3AED);  // Vibrant Purple
  static const Color secondaryDark = Color(0xFF4C1D95);
  static const Color tertiary = Color(0xFFFF007F);   // Neon Pink
  
  // Game Cells
  static const Color cellNormal = Color(0xFF1E1A33);
  static const Color cellSelected = Color(0xFF4C1D95);
  static const Color cellCursor = Color(0xFF00E5FF);
  static const Color cellCorrect = Color(0xFF00E676); // Emerald Green
  
  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA09DB0);
  static const Color textDark = Color(0xFF0B0914);

  // Status Colors
  static const Color success = Color(0xFF00E676);
  static const Color error = Color(0xFFFF3366);
  static const Color warning = Color(0xFFFFD600);

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
