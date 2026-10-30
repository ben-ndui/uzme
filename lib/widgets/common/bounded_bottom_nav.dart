import 'package:flutter/material.dart';

/// Centre et borne la largeur d'une barre de navigation sur tablette/desktop.
///
/// DA 2026-2027 (Ben, 29/09/2026) : jamais de barre latérale, même sur grand
/// écran — la barre du bas reste, centrée et de largeur bornée. Sans borne,
/// [UzmeNavBar.compact] étire son onglet actif sur toute la largeur
/// disponible (ses onglets inactifs gardent leur plancher tactile fixe) :
/// sur un iPad en paysage, le libellé actif se retrouve perdu au milieu
/// d'une pilule de près de 1000px.
///
/// ⚠️ `Center`/`Align` sont PROSCRITS ici (régression Ben, 30/10/2026) :
/// posé comme `Scaffold.bottomNavigationBar`, ce slot reçoit des contraintes
/// « loose » mais BORNÉES (max = hauteur du body) — `Center` s'étire alors
/// sur toute cette hauteur pour centrer son enfant DEDANS, et la barre se
/// retrouve au milieu de l'écran au lieu du bas. `Row` ne fait jamais ça :
/// en axe transverse (la hauteur, ici), un `Flex` se cale TOUJOURS sur la
/// taille de son enfant, quelles que soient les contraintes entrantes.
class BoundedBottomNav extends StatelessWidget {
  const BoundedBottomNav({super.key, required this.child});

  final Widget child;

  static const double maxWidth = 420;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ],
    );
  }
}
