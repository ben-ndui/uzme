import 'dart:math' as math;

/// Où se pose chaque onglet de la barre, et donc où glisse la pilule.
///
/// ## Pourquoi un calcul et pas `Expanded`
///
/// La pilule active se déplace derrière la rangée, dans un `Stack` : elle doit
/// donc connaître la position et la largeur de l'onglet visé. Tant que les
/// onglets se dimensionnaient tout seuls (`Expanded`, `minWidth`), la pilule
/// aurait dû DEVINER ce que la mise en page avait décidé — et un simple
/// changement de marge l'aurait décalée sans que rien ne le signale.
///
/// Les largeurs sont donc calculées ici, une fois, et **la rangée comme la
/// pilule les lisent**. Elles ne peuvent plus diverger.
class NavBarGeometry {
  NavBarGeometry({
    required this.totalWidth,
    required this.count,
    required this.activeIndex,
    required this.compact,
    required this.gap,
    required this.minWidth,
  }) : assert(count > 0);

  final double totalWidth;
  final int count;
  final int activeIndex;

  /// En compact, seul l'onglet actif s'étire ; les autres tiennent leur
  /// plancher tactile.
  final bool compact;

  /// L'espace entre deux onglets.
  final double gap;

  /// Le plancher tactile d'un onglet inactif (seuil Apple HIG).
  final double minWidth;

  double get _gaps => (count - 1) * gap;

  /// La largeur de l'onglet [index].
  double width(int index) {
    if (!compact) {
      // Tous égaux : la rangée se partage ce qui reste une fois les espaces
      // retirés.
      return math.max(0, (totalWidth - _gaps) / count);
    }
    if (index != activeIndex) return minWidth;
    // ⚠️ Jamais sous le plancher tactile, même sur un écran étroit : mieux
    // vaut une barre qui déborde légèrement qu'un onglet qu'on ne peut pas
    // toucher.
    final remaining = totalWidth - _gaps - (count - 1) * minWidth;
    return math.max(minWidth, remaining);
  }

  /// Le bord gauche de l'onglet [index].
  double left(int index) {
    var x = 0.0;
    for (var i = 0; i < index; i++) {
      x += width(i) + gap;
    }
    return x;
  }

  /// Vrai si l'onglet actif a la place d'écrire son libellé.
  ///
  /// En dessous, il serait réduit à une ellipse : autant l'omettre et garder
  /// la cible tactile.
  bool labelFits(double minSpace) => !compact || width(activeIndex) >= minSpace;
}
