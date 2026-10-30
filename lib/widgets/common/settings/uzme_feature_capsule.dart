import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uzme/config/useme_theme.dart';

/// Capsule de mise en avant pour une entrée de réglages — réutilise le
/// langage déjà établi par [UzmeNavBar]/[AppSnackBar] (pilule, rayon 28,
/// s'inverse entre thèmes) au lieu d'un dégradé pastel générique.
///
/// Relevé par Ben le 30/10/2026 : les cards "Comparateur de rôles" et
/// "Tes nouveautés" (violet/or/vert, badge-icône à son propre dégradé+glow)
/// « ça fait trop généré par IA » — aucune de ces teintes n'appartient à la
/// charte UZME (bleu signature uniquement, zéro gris/noir neutre).
class UzmeFeatureCapsule extends StatefulWidget {
  const UzmeFeatureCapsule({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final FaIconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  State<UzmeFeatureCapsule> createState() => _UzmeFeatureCapsuleState();
}

class _UzmeFeatureCapsuleState extends State<UzmeFeatureCapsule> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Même inversion que UzmeNavBar : blanc en sombre, dégradé bleu en clair.
    final fg = isDark ? UseMeTheme.primaryColor : Colors.white;
    final fgMuted = isDark
        ? UseMeTheme.primaryColor.withValues(alpha: 0.7)
        : Colors.white.withValues(alpha: 0.85);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? Colors.white : null,
              gradient: isDark
                  ? null
                  : const LinearGradient(
                      colors: [UseMeTheme.primaryColor, UseMeTheme.secondaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.15)
                      : UseMeTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: fg.withValues(alpha: isDark ? 0.12 : 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: FaIcon(widget.icon, size: 16, color: fg)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(widget.subtitle, style: TextStyle(color: fgMuted, fontSize: 12)),
                    ],
                  ),
                ),
                FaIcon(FontAwesomeIcons.chevronRight, size: 13, color: fgMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
