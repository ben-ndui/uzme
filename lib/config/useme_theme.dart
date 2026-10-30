import 'package:flutter/material.dart';
import 'package:uzme/config/useme_dark_theme.dart';
import 'package:uzme/config/useme_text_theme.dart';

/// Use Me Theme Configuration
/// Primary: Blue (Viba-inspired)
/// Secondary: Light Blue
/// Tertiary: Turquoise
///
/// Thème sombre extrait dans `useme_dark_theme.dart` (tenir sous 250 lignes).
class UseMeTheme {
  // Brand Colors (Viba-inspired)
  static const Color primaryColor = Color(0xFF0B38BF);      // Viba Blue
  static const Color secondaryColor = Color(0xFF031473);    // Dark Blue
  static const Color tertiaryColor = Color(0xFF00CEC9);     // Turquoise
  static const Color accentColor = Color(0xFF3B5FC7);       // Light Blue

  // Semantic Colors
  static const Color successColor = Color(0xFF00B894);
  static const Color warningColor = Color(0xFFFDCB6E);
  static const Color errorColor = Color(0xFFE17055);
  static const Color infoColor = Color(0xFF74B9FF);

  /// Fond d'une feuille maison qui construit elle-même son `Container`
  /// (pas via `BottomSheetThemeData`) — `colorScheme.surface` n'est plus
  /// réécrit globalement (trop de fichiers le lisent avec leur propre
  /// logique dark, cf. `gradient_surface.dart`), donc ces feuilles restaient
  /// quasi-noires au lieu du bleu de marque demandé par Ben le 28/10
  /// ("pourquoi ce n'est pas notre dégradé de bleu ici").
  static Color sheetBackground(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? secondaryColor
        : theme.colorScheme.surface;
  }

  // Light Theme
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: tertiaryColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: buildUzmeTextTheme(colorScheme),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: primaryColor.withValues(alpha: 0.2),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }

  // Dark Theme — construction complète dans useme_dark_theme.dart
  static ThemeData get darkTheme => buildUzmeDarkTheme();
}
