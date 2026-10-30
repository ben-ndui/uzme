import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Échelle typographique Inter commune aux deux thèmes — extrait de
/// `useme_theme.dart` pour tenir sous 250 lignes.
TextTheme buildUzmeTextTheme(ColorScheme colorScheme) {
  return GoogleFonts.interTextTheme().copyWith(
    displayLarge: GoogleFonts.inter(fontWeight: FontWeight.bold),
    displayMedium: GoogleFonts.inter(fontWeight: FontWeight.bold),
    displaySmall: GoogleFonts.inter(fontWeight: FontWeight.bold),
    headlineLarge: GoogleFonts.inter(fontWeight: FontWeight.w600),
    headlineMedium: GoogleFonts.inter(fontWeight: FontWeight.w600),
    headlineSmall: GoogleFonts.inter(fontWeight: FontWeight.w600),
    titleLarge: GoogleFonts.inter(fontWeight: FontWeight.w600),
    titleMedium: GoogleFonts.inter(fontWeight: FontWeight.w500),
    titleSmall: GoogleFonts.inter(fontWeight: FontWeight.w500),
    bodyLarge: GoogleFonts.inter(),
    bodyMedium: GoogleFonts.inter(),
    bodySmall: GoogleFonts.inter(),
    labelLarge: GoogleFonts.inter(fontWeight: FontWeight.w500),
    labelMedium: GoogleFonts.inter(fontWeight: FontWeight.w500),
    labelSmall: GoogleFonts.inter(fontWeight: FontWeight.w500),
  );
}
