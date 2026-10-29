import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Types of snackbar notifications.
enum SnackBarType {
  success,
  error,
  warning,
  info,
}

/// Configuration for snackbar styling (couleur d'accent uniquement, la forme
/// est fixe — voir [_SnackBarContent]).
class SnackBarConfig {
  final FaIconData icon;
  final Color accentColor;

  const SnackBarConfig({required this.icon, required this.accentColor});
}

/// Snackbar UZME : une capsule glass, alignée sur `GlassChip` et
/// `UzmeNavBar` (même famille visuelle que le reste de l'app) plutôt que la
/// carte à icône encadrée du package partagé.
///
/// Relevé par Ben le 29/10/2026 : « le design de ce widget... doit être plus
/// à l'image de l'app pas juste la couleur ». La forme est propre à UZME
/// (comme `UzmeNavBar` déjà), contrairement à `AppUser`/`FavoriteService` qui
/// restent dans `smoothandesign_package` : chaque app du parc a sa propre
/// géométrie, seule la logique (types, auto-dismiss, action) est commune.
///
/// Usage (inchangé) :
/// ```dart
/// AppSnackBar.success(context, 'Opération réussie');
/// AppSnackBar.error(context, 'Une erreur est survenue');
/// ```
class AppSnackBar {
  AppSnackBar._();

  static void show(
    BuildContext context, {
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
    EdgeInsetsGeometry? margin,
  }) {
    final theme = Theme.of(context);
    final config = getTypeConfig(type, theme);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: _SnackBarContent(
          message: message,
          icon: config.icon,
          accentColor: config.accentColor,
          actionLabel: actionLabel,
          onAction: onAction,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        margin: margin ?? const EdgeInsets.fromLTRB(16, 0, 16, 100),
        padding: EdgeInsets.zero,
      ),
    );
  }

  static void success(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) {
    show(context, message: message, type: SnackBarType.success, actionLabel: actionLabel, onAction: onAction);
  }

  static void error(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) {
    show(context, message: message, type: SnackBarType.error, actionLabel: actionLabel, onAction: onAction);
  }

  static void warning(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) {
    show(context, message: message, type: SnackBarType.warning, actionLabel: actionLabel, onAction: onAction);
  }

  static void info(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) {
    show(context, message: message, type: SnackBarType.info, actionLabel: actionLabel, onAction: onAction);
  }

  /// success/error/warning gardent une couleur sémantique universelle (feu
  /// rouge/orange/vert). info reprend la couleur primaire du thème : c'est
  /// la seule des quatre sans convention universelle.
  static SnackBarConfig getTypeConfig(SnackBarType type, ThemeData theme) {
    switch (type) {
      case SnackBarType.success:
        return const SnackBarConfig(icon: FontAwesomeIcons.circleCheck, accentColor: Color(0xFF22C55E));
      case SnackBarType.error:
        return const SnackBarConfig(icon: FontAwesomeIcons.circleExclamation, accentColor: Color(0xFFEF4444));
      case SnackBarType.warning:
        return const SnackBarConfig(icon: FontAwesomeIcons.triangleExclamation, accentColor: Color(0xFFF59E0B));
      case SnackBarType.info:
        return SnackBarConfig(icon: FontAwesomeIcons.circleInfo, accentColor: theme.colorScheme.primary);
    }
  }
}

class _SnackBarContent extends StatelessWidget {
  final String message;
  final FaIconData icon;
  final Color accentColor;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SnackBarContent({
    required this.message,
    required this.icon,
    required this.accentColor,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    // Même convention que GlassChip : blanc translucide en sombre,
    // colorScheme en clair — jamais de gris neutre fixe.
    final fgColor = isDark ? Colors.white : cs.onSurface;
    final bgColor = isDark ? Colors.white.withValues(alpha: 0.1) : cs.surfaceContainerHigh;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.2) : cs.outlineVariant;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.1), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Liseré d'accent, 3px, sur toute la hauteur de la capsule.
              Container(width: 3, color: accentColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      FaIcon(icon, size: 15, color: accentColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          message,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: fgColor),
                        ),
                      ),
                      if (actionLabel != null && onAction != null) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            onAction!();
                          },
                          child: Text(
                            actionLabel!,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: accentColor),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
