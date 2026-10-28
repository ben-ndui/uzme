// Morceaux internes de [UzmeNavBar]. Séparés du fichier principal pour tenir
// la charte des 250 lignes ; ils restent privés au composant.
part of 'uzme_nav_bar.dart';

/// Un onglet. Il ne peint plus sa pilule : elle vit derrière la rangée et
/// glisse. Lui ne porte que son encre, son rebond et son retour au toucher.
class _NavTab extends StatefulWidget {
  const _NavTab({
    required this.item,
    required this.active,
    required this.compact,
    required this.withLabel,
    required this.noAnimations,
    required this.activeInk,
    required this.inactiveInk,
    required this.theme,
    required this.onTap,
  });

  final UzmeNavItem item;
  final bool active;
  final bool compact;

  /// L'onglet écrit-il son libellé ? La barre en décide : il faut la place.
  final bool withLabel;

  /// Le système demande de réduire les animations : tout devient instantané.
  final bool noAnimations;

  /// Couleur de l'encre sur l'onglet actif (contraste avec la pilule) et sur
  /// les onglets inactifs (contraste avec le fond de la barre) — calculées
  /// par [UzmeNavBar] selon le thème, jamais dérivées du `ColorScheme`
  /// générique ici.
  final Color activeInk;
  final Color inactiveInk;

  final ThemeData theme;
  final VoidCallback onTap;

  @override
  State<_NavTab> createState() => _NavTabState();
}

class _NavTabState extends State<_NavTab> {
  bool _pressed = false;

  /// Le doigt est posé : l'onglet s'enfonce légèrement.
  ///
  /// Sans ça, rien ne répond au moment du toucher — l'écran ne change qu'une
  /// fois la navigation faite, et l'appui semble n'avoir servi à rien.
  void _press(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final duration = widget.noAnimations
        ? Duration.zero
        : UzmeNavBar.inkDuration;

    return Semantics(
      // Le libellé n'est annoncé que s'il n'est PAS écrit : sinon
      // l'annotation et le texte fusionnent côté lecteur d'écran.
      label: widget.withLabel ? null : widget.item.label,
      button: true,
      selected: widget.active,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => _press(true),
        onTapUp: (_) => _press(false),
        onTapCancel: () => _press(false),
        child: AnimatedScale(
          scale: _pressed ? 0.94 : 1,
          duration: widget.noAnimations
              ? Duration.zero
              : const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          child: SizedBox(
            height: UzmeNavBar.tabHeight,
            // ⚠️ L'encre se FOND d'une couleur à l'autre : une bascule sèche
            // arriverait avant la pilule et l'onglet clignoterait.
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: widget.active ? 1 : 0),
              duration: duration,
              curve: Curves.easeOut,
              builder: (_, progress, _) => _TabContent(
                item: widget.item,
                active: widget.active,
                compact: widget.compact,
                withLabel: widget.withLabel,
                ink: Color.lerp(
                  widget.inactiveInk,
                  widget.activeInk,
                  progress,
                )!,
                noAnimations: widget.noAnimations,
                theme: widget.theme,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Icône, libellé et compteur — disposés selon la variante.
class _TabContent extends StatelessWidget {
  const _TabContent({
    required this.item,
    required this.active,
    required this.compact,
    required this.withLabel,
    required this.ink,
    required this.noAnimations,
    required this.theme,
  });

  final UzmeNavItem item;
  final bool active;
  final bool compact;
  final bool withLabel;
  final Color ink;
  final bool noAnimations;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final icon = _BouncingIcon(
      active: active,
      noAnimations: noAnimations,
      child: _IconWithBadge(
        item: item,
        active: active,
        ink: ink,
        theme: theme,
        size: compact && !withLabel ? 24 : (compact ? 20 : 22),
      ),
    );

    if (!withLabel) return Center(child: icon);

    final label = Text(
      item.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: compact ? 14 : 11,
        fontWeight: active ? FontWeight.w600 : FontWeight.w500,
        color: ink,
      ),
    );

    // En compact, l'actif se lit en ligne (icône puis libellé) ; en complet,
    // chaque onglet empile son icône au-dessus de son libellé.
    //
    // ⚠️ `Center` est nécessaire ici : en compact, la pilule active hérite de
    // TOUTE la largeur laissée par les onglets inactifs (repliés sur leur
    // plancher tactile), bien plus large que son contenu. Sans centrage, la
    // Row se cale à gauche et tout l'espace en trop part visiblement à
    // droite — repéré par Ben le 28/10.
    return compact
        ? Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon,
                  const SizedBox(width: 8),
                  Flexible(child: label),
                ],
              ),
            ),
          )
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(height: 2),
              Flexible(child: label),
            ],
          );
  }
}

/// L'icône de l'onglet choisi grossit d'un cran, avec un léger dépassement.
///
/// ⚠️ Un cran, pas un zoom : sur une barre qu'on touche vingt fois par
/// session, une icône qui bondit devient fatigante.
class _BouncingIcon extends StatelessWidget {
  const _BouncingIcon({
    required this.active,
    required this.noAnimations,
    required this.child,
  });

  final bool active;
  final bool noAnimations;
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: active ? 1 : 0),
    duration: noAnimations ? Duration.zero : const Duration(milliseconds: 320),
    // `easeOutBack` dépasse la valeur cible puis revient : c'est le
    // dépassement qui donne le rebond, pas une seconde animation.
    curve: Curves.easeOutBack,
    builder: (_, progress, constantChild) =>
        Transform.scale(scale: 1 + 0.09 * progress, child: constantChild),
    child: child,
  );
}

