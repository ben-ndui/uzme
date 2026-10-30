import 'package:flutter/material.dart';
import 'package:uzme/config/useme_text_theme.dart';
import 'package:uzme/config/useme_theme.dart';

// Dark Theme Colors — TOUT dérivé de notre bleu (primaryColor/secondaryColor),
// plus aucun gris/noir neutre. Décrété par Ben le 28/10/2026 : "en theme
// dark, je ne devrais voir de noir nulle part, notre dark à nous c'est le
// bleu du dégradé de SmoothDraggableWidget". Avant ce correctif, un wrapper
// (`GradientSurface`) tentait de repeindre ces tokens APRÈS coup pour
// certains écrans seulement — source d'incohérences et de régressions en
// chaîne (cf. historique du 28/10). Corrigé ICI, à la source : une seule
// définition, lue partout, pas de double-thème qui se contredisent.
//
// Extrait de `useme_theme.dart` le 30/10/2026 pour tenir sous 250 lignes.
const Color darkSurface = UseMeTheme.secondaryColor; // 0xFF031473
const Color darkSurfaceContainerLowest = Color(0xFF02103D);
const Color darkSurfaceContainerLow = Color(0xFF0A2566);
const Color darkSurfaceContainer = Color(0xFF123490);
const Color darkSurfaceContainerHigh = Color(0xFF1E47B5);
const Color darkSurfaceContainerHighest = Color(0xFF2E5CD6);
const Color darkPrimary = Color(0xFF5B7FE8);
const Color darkOnPrimary = Color(0xFFFFFFFF);
const Color darkPrimaryContainer = Color(0xFF1A2B5E);
const Color darkOnPrimaryContainer = Color(0xFFB8C8FF);
const Color darkSecondary = Color(0xFF6D86C4);
const Color darkOnSecondary = Color(0xFFFFFFFF);
const Color darkSecondaryContainer = Color(0xFF24345E);
const Color darkOnSecondaryContainer = Color(0xFFD8DCE8);
const Color darkTertiary = Color(0xFF4DD5D1);
const Color darkOnTertiary = UseMeTheme.secondaryColor;
const Color darkOutline = Color(0xFF7C92D9);
const Color darkOutlineVariant = Color(0xFF2A4A9E);
const Color darkOnSurfaceVariant = Color(0xFFA8B5D9);
// Texte/icône en sourdine (hint, switch désactivé) : un bleu-gris lisible,
// jamais un gris neutre qui recrée l'effet "noir" sur le dégradé.
const Color darkMuted = Color(0xFF5A6FA8);

ThemeData buildUzmeDarkTheme() {
  const colorScheme = ColorScheme.dark(
    brightness: Brightness.dark,
    primary: darkPrimary,
    onPrimary: darkOnPrimary,
    primaryContainer: darkPrimaryContainer,
    onPrimaryContainer: darkOnPrimaryContainer,
    secondary: darkSecondary,
    onSecondary: darkOnSecondary,
    secondaryContainer: darkSecondaryContainer,
    onSecondaryContainer: darkOnSecondaryContainer,
    tertiary: darkTertiary,
    onTertiary: darkOnTertiary,
    tertiaryContainer: Color(0xFF0A3A38),
    onTertiaryContainer: Color(0xFFB8F5F2),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: darkSurface,
    onSurface: Color(0xFFE8E8EC),
    onSurfaceVariant: darkOnSurfaceVariant,
    outline: darkOutline,
    outlineVariant: darkOutlineVariant,
    inverseSurface: Color(0xFFE8E8EC),
    onInverseSurface: UseMeTheme.secondaryColor,
    inversePrimary: UseMeTheme.primaryColor,
    surfaceContainerLowest: darkSurfaceContainerLowest,
    surfaceContainerLow: darkSurfaceContainerLow,
    surfaceContainer: darkSurfaceContainer,
    surfaceContainerHigh: darkSurfaceContainerHigh,
    surfaceContainerHighest: darkSurfaceContainerHighest,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: darkSurface,
    textTheme: buildUzmeTextTheme(colorScheme),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: darkSurface,
      foregroundColor: Color(0xFFE8E8EC),
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: darkSurfaceContainer,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: darkOutlineVariant, width: 0.5),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurfaceContainerHigh,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: darkOutlineVariant, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: darkPrimary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(color: darkMuted),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: darkPrimary,
        foregroundColor: darkOnPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: darkPrimary,
        side: const BorderSide(color: darkPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    // darkPrimary (#5B7FE8) sur darkSurface (#031473) ne tient qu'un ratio
    // de contraste ~4.2:1 — sous le seuil AA pour du texte normal.
    // darkOnPrimaryContainer est le token Material3 prévu pour du texte sur
    // un fond teinté primary ; ~9.4:1 ici (Ben, 30/10 : boutons
    // "Enregistrer" peu visibles en thème sombre).
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: darkOnPrimaryContainer),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: darkSurfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: const BorderSide(color: darkOutlineVariant, width: 0.5),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: darkPrimary,
      foregroundColor: darkOnPrimary,
      elevation: 4,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: darkSurfaceContainer,
      surfaceTintColor: Colors.transparent,
      indicatorColor: darkPrimary.withValues(alpha: 0.15),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: darkSurfaceContainerHighest,
      contentTextStyle: const TextStyle(color: Color(0xFFE8E8EC)),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: darkSurfaceContainer,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: darkSurfaceContainer,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    dividerTheme: const DividerThemeData(color: darkOutlineVariant, thickness: 0.5),
    listTileTheme: const ListTileThemeData(
      tileColor: Colors.transparent,
      iconColor: darkOnSurfaceVariant,
    ),
    iconTheme: const IconThemeData(color: darkOnSurfaceVariant),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return darkPrimary;
        return darkMuted;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return darkPrimary.withValues(alpha: 0.3);
        }
        return darkOutlineVariant;
      }),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: darkPrimary,
      linearTrackColor: darkOutlineVariant,
    ),
  );
}
