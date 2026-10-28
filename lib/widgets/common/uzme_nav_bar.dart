import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uzme/config/useme_theme.dart';
import 'package:uzme/widgets/common/nav_bar_geometry.dart';

part 'uzme_nav_bar_parts.dart';
part 'uzme_nav_bar_badge.dart';

/// Un onglet de la barre de navigation UZME.
class UzmeNavItem {
  const UzmeNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badgeCount = 0,
  });

  final FaIconData icon;
  final FaIconData selectedIcon;

  /// Toujours renseigné, même quand il n'est pas affiché : il devient alors
  /// le libellé d'accessibilité de l'onglet.
  final String label;

  /// Nombre en attente. 0 n'affiche rien.
  final int badgeCount;
}

/// Barre de navigation flottante maison (DA 2026-2027) — hauteur 68, rayon 32,
/// décollée des bords (marge latérale 16, marge basse 4 + zone de sécurité).
///
/// ## Fond PLEIN, jamais translucide
///
/// Elle flotte au-dessus du contenu : un fond translucide ferait varier le
/// contraste des libellés selon ce qui défile dessous. Le flottement vient de
/// l'ombre et du rayon, pas de la transparence.
///
/// ## Elle s'INVERSE entre les thèmes (précisé par Ben le 28/10)
///
/// Blanche en sombre (plus élégante sur fond noir), dégradée du bleu de
/// marque en clair — l'inverse de [SmoothDraggableWidget], qui dégrade en
/// sombre et reste plat en clair. L'accent (pilule active) reprend TOUJOURS
/// le même bleu de marque que [SmoothDraggableWidget]
/// (`UseMeTheme.primaryColor`/`secondaryColor`), jamais le `primary` du thème
/// sombre — une teinte différente (`0xFF5B7FE8`) qui créerait deux bleus
/// différents sur un même écran.
///
/// ## La pilule GLISSE d'un onglet à l'autre
///
/// Une seule pilule vit derrière la rangée et se déplace : l'œil suit un
/// OBJET plutôt que de constater un changement d'état.
///
/// ⚠️ Tout est coupé quand le système demande de réduire les animations
/// (`MediaQuery.disableAnimations`).
class UzmeNavBar extends StatelessWidget {
  const UzmeNavBar._({
    required this.items,
    required this.activeIndex,
    required this.onChanged,
    required this.compact,
  });

  /// Chaque onglet porte son libellé sous l'icône. Tient jusqu'à 4 onglets.
  const UzmeNavBar.full({
    required List<UzmeNavItem> items,
    required int activeIndex,
    required ValueChanged<int> onChanged,
  }) : this._(
         items: items,
         activeIndex: activeIndex,
         onChanged: onChanged,
         compact: false,
       );

  /// Seul l'onglet actif porte son libellé, dans une pilule à largeur
  /// intrinsèque ; les autres restent des icônes à zone tactile garantie.
  /// Pour les navigations à plus de 4 onglets.
  const UzmeNavBar.compact({
    required List<UzmeNavItem> items,
    required int activeIndex,
    required ValueChanged<int> onChanged,
  }) : this._(
         items: items,
         activeIndex: activeIndex,
         onChanged: onChanged,
         compact: true,
       );

  final List<UzmeNavItem> items;
  final int activeIndex;
  final ValueChanged<int> onChanged;
  final bool compact;

  static const double height = 68;
  static const double radius = 32;
  static const double tabHeight = 56;

  /// Plancher de la zone tactile d'un onglet (seuil Apple HIG).
  static const double minTapWidth = 44;

  /// En deçà, l'onglet actif n'a pas la place d'écrire son libellé lisiblement
  /// et repasse en icône seule.
  static const double minLabelSpace = 90;
  static const double lateralMargin = 16;

  /// Ce qu'on laisse SOUS la barre, en plus de la zone sûre — au-dessus de la
  /// zone d'accueil, sans empiéter dessus.
  static const double bottomMargin = 4;
  static const double gapBetweenTabs = 2;

  static const Duration slideDuration = Duration(milliseconds: 260);
  static const Duration inkDuration = Duration(milliseconds: 170);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final pillColor = isDark ? UseMeTheme.primaryColor : Colors.white;
    final activeInk = isDark ? Colors.white : UseMeTheme.primaryColor;
    final inactiveInk = isDark
        ? UseMeTheme.primaryColor.withValues(alpha: 0.45)
        : Colors.white.withValues(alpha: 0.75);

    return Padding(
      padding: EdgeInsets.only(
        left: lateralMargin,
        right: lateralMargin,
        bottom: bottomMargin + MediaQuery.of(context).padding.bottom,
      ),
      child: Container(
        key: const Key('uzmeNavBarContainer'),
        height: height,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isDark ? Colors.white : null,
          gradient: isDark
              ? null
              : const LinearGradient(
                  colors: [UseMeTheme.primaryColor, UseMeTheme.secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.15)
                  : UseMeTheme.primaryColor.withValues(alpha: 0.35),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final noAnimations = MediaQuery.disableAnimationsOf(context);
            final geo = NavBarGeometry(
              totalWidth: constraints.maxWidth,
              count: items.length,
              activeIndex: activeIndex,
              compact: compact,
              gap: gapBetweenTabs,
              minWidth: minTapWidth,
            );
            final labelFits = geo.labelFits(minLabelSpace);

            return Stack(
              children: [
                // La pilule, DERRIÈRE les onglets : elle glisse et change de
                // largeur d'une position à l'autre.
                AnimatedPositioned(
                  left: geo.left(activeIndex),
                  width: geo.width(activeIndex),
                  top: 0,
                  bottom: 0,
                  duration: noAnimations ? Duration.zero : slideDuration,
                  curve: Curves.easeOutCubic,
                  child: DecoratedBox(
                    key: const Key('uzmeNavBarPill'),
                    decoration: BoxDecoration(
                      color: pillColor,
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (final (index, item) in items.indexed) ...[
                      if (index > 0) SizedBox(width: gapBetweenTabs),
                      // ⚠️ Largeur EXPLICITE, plus `Expanded` : la pilule doit
                      // viser exactement ce que la rangée occupe.
                      SizedBox(
                        width: geo.width(index),
                        child: _NavTab(
                          item: item,
                          active: index == activeIndex,
                          compact: compact,
                          withLabel:
                              !compact || (index == activeIndex && labelFits),
                          noAnimations: noAnimations,
                          activeInk: activeInk,
                          inactiveInk: inactiveInk,
                          theme: theme,
                          onTap: () => onChanged(index),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
