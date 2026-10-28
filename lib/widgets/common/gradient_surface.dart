import 'package:flutter/material.dart';
import 'package:uzme/config/useme_theme.dart';

/// Pose le DÉGRADÉ visuel (pas juste une couleur plate) de
/// [SmoothDraggableWidget] derrière [child], en rendant transparents le
/// Scaffold et l'AppBar ambiants pour qu'il se voie.
///
/// Le thème dark lui-même (`UseMeTheme.darkTheme`) ne contient plus aucun
/// gris/noir neutre depuis le 28/10/2026 — tous ses tokens
/// (`surfaceContainer*`, `outline`, `chipTheme`, `bottomSheetTheme`...)
/// sont désormais des bleus de marque. Ce widget n'a donc plus qu'UN seul
/// rôle : peindre le dégradé proprement dit, que `ColorScheme` ne sait pas
/// exprimer (il ne prend qu'une Color plate). Tout le reste — cartes,
/// puces, feuilles, contours — est déjà correct par construction, lu
/// PARTOUT depuis la même définition, sans wrapper à poser au bon endroit
/// ni risque de collision avec un widget qui lirait ce token autrement
/// (cf. historique : un ancien override ici cassait la barre de recherche
/// de la carte et la pastille "20 studios", qui ont leur propre logique
/// `isDark ? ... : ...` câblée sur CE thème).
class GradientSurface extends StatelessWidget {
  final Widget child;

  const GradientSurface({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (theme.brightness != Brightness.dark) return child;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [UseMeTheme.primaryColor, UseMeTheme.secondaryColor],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Theme(
        data: theme.copyWith(
          scaffoldBackgroundColor: Colors.transparent,
          appBarTheme: theme.appBarTheme.copyWith(
            backgroundColor: Colors.transparent,
          ),
        ),
        child: child,
      ),
    );
  }
}
