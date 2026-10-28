// Morceau interne de [UzmeNavBar] — cf. `uzme_nav_bar.dart`.
part of 'uzme_nav_bar.dart';

/// L'icône (pleine quand actif, contour sinon), surmontée de sa pastille de
/// compteur s'il y a lieu.
class _IconWithBadge extends StatelessWidget {
  const _IconWithBadge({
    required this.item,
    required this.active,
    required this.ink,
    required this.theme,
    required this.size,
  });

  final UzmeNavItem item;
  final bool active;
  final Color ink;
  final ThemeData theme;
  final double size;

  @override
  Widget build(BuildContext context) {
    final badgeCount = item.badgeCount;
    final icon = FaIcon(
      active ? item.selectedIcon : item.icon,
      size: size,
      color: ink,
    );
    if (badgeCount <= 0) return icon;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          top: -4,
          right: -8,
          child: Container(
            constraints: const BoxConstraints(minWidth: 18),
            height: 18,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.error,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              // Au-delà de 99 la pastille s'élargirait au point de manger
              // l'onglet voisin ; le nombre exact n'y ajoute rien.
              badgeCount > 99 ? '99+' : '$badgeCount',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onError,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
