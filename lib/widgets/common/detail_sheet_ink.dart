import 'package:flutter/material.dart';

/// Couleurs pour le contenu des bottom sheets de détail (studio, pro).
///
/// En dark, ce contenu n'est PAS posé sur `colorScheme.surface` (quasi-noir)
/// mais sur le dégradé bleu de marque de `SmoothDraggableWidget` — un badge
/// qui lit `colorScheme.outline` (gris calibré pour du quasi-noir) devient
/// illisible sur ce bleu moyen. Relevé par Ben le 28/10/2026 sur
/// `ProDetailBottomSheet` : badge ville à peine visible, libellés de
/// sections ("Specialites", "Genres"...) fondus dans le fond.
///
/// En light, le fond du sheet reste neutre (`colorScheme.surface`) : les
/// tokens de thème habituels sont corrects et restent utilisés tels quels.
class DetailSheetInk {
  DetailSheetInk(BuildContext context)
    : isDark = Theme.of(context).brightness == Brightness.dark,
      theme = Theme.of(context);

  final bool isDark;
  final ThemeData theme;

  /// Fond d'un badge/chip/stat.
  Color get chipBackground => isDark
      ? Colors.white.withValues(alpha: 0.16)
      : theme.colorScheme.surfaceContainerHighest;

  /// Texte/icône neutre (sous-titres de section, libellés secondaires) —
  /// remplace `colorScheme.outline`.
  Color get mutedInk =>
      isDark ? Colors.white.withValues(alpha: 0.75) : theme.colorScheme.outline;

  /// Accent (prix, tags actifs, liens) — remplace `colorScheme.primary`.
  Color get accentInk => isDark ? Colors.white : theme.colorScheme.primary;

  /// Corps de texte (bio, description) — remplace `colorScheme.onSurfaceVariant`.
  Color get bodyInk => isDark
      ? Colors.white.withValues(alpha: 0.88)
      : theme.colorScheme.onSurfaceVariant;
}
