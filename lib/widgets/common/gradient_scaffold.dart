import 'package:flutter/material.dart';
import 'package:uzme/widgets/common/gradient_surface.dart';

/// Scaffold pour un écran poussé en route à part (profil, chat, réglages
/// de conversation...) : pose [GradientSurface] directement au-dessus du
/// Scaffold qu'il construit. Marche ici car l'écran qui l'utilise ne lit
/// PAS `Theme.of(context)` lui-même avant de le renvoyer — sinon (ex. un
/// onglet de [ArtistMainScaffold] qui résout une couleur dans son propre
/// `build()`), voir l'avertissement dans `gradient_surface.dart` : il faut
/// alors poser [GradientSurface] un niveau plus haut, autour du contenu
/// des onglets, pas ici.
class GradientScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool extendBody;
  final bool extendBodyBehindAppBar;

  const GradientScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    // [GradientSurface] ne peint le dégradé qu'en thème sombre (en clair,
    // elle renvoie `child` tel quel). Forcer `transparent` ici dans les DEUX
    // thèmes laissait l'écran sans AUCUN fond en clair — noir par défaut
    // (relevé par Ben le 30/10/2026 sur l'écran de chat).
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GradientSurface(
      child: Scaffold(
        backgroundColor: isDark ? Colors.transparent : null,
        appBar: appBar,
        body: body,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButtonLocation: floatingActionButtonLocation,
        floatingActionButton: floatingActionButton,
        extendBody: extendBody,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
      ),
    );
  }
}
