import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'color_palette.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.light, // Neo-brutalism is typically light mode based
      primaryColor: ColorPalette.primary,
      scaffoldBackgroundColor: ColorPalette.background,
      textTheme: GoogleFonts.spaceGroteskTextTheme().apply(
        bodyColor: ColorPalette.textPrimary,
        displayColor: ColorPalette.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: ColorPalette.textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorPalette.primary,
          foregroundColor: ColorPalette.surface,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: const BorderSide(color: ColorPalette.textDark, width: 3),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
