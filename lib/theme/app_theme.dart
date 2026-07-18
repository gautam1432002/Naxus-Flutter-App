import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color deepNavy = Color(0xFF0A0E27);
  static const Color nearBlack = Color(0xFF0A0A12);
  static const Color accentCyan = Color(0xFF00D9FF);

  static BoxDecoration get spaceBackground => const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [deepNavy, nearBlack],
    ),
  );

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: const ColorScheme.dark(
        primary: accentCyan,
        secondary: accentCyan,
        surface: deepNavy,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold),
        displaySmall: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.w600),
        headlineSmall: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.w600),
        titleLarge: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.w600),
        titleSmall: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.inter(color: Colors.white70),
        bodyMedium: GoogleFonts.inter(color: Colors.white70),
        bodySmall: GoogleFonts.inter(color: Colors.white70),
        labelLarge: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentCyan,
          foregroundColor: nearBlack,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
