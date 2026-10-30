import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uzme/widgets/common/bounded_bottom_nav.dart';

/// DA 2026-2027 (Ben, 29/09/2026) : jamais de barre latérale, même sur grand
/// écran — la barre du bas reste, centrée et de largeur bornée.
void main() {
  // Un iPad en paysage : plus large que n'importe quel plancher tactile,
  // c'est exactement le cas qui étirait l'ancienne NavigationRail.
  const screenWidth = 1200.0;
  const screenHeight = 800.0;
  const barHeight = 68.0;

  Future<void> pumpInBody(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(screenWidth, screenHeight));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BoundedBottomNav(
          child: Container(key: const Key('bar'), color: Colors.blue, height: barHeight),
        ),
      ),
    ));
  }

  /// Régression (Ben, 30/10/2026) : posée comme `body`, la barre passait les
  /// deux tests ci-dessus — mais posée comme VRAI `bottomNavigationBar`, elle
  /// se retrouvait au milieu de l'écran. `Scaffold.bottomNavigationBar` donne
  /// des contraintes loose mais BORNÉES (max = hauteur du body) ; un `Center`
  /// s'étire sur cette hauteur et centre son enfant dedans. Seul CE contexte
  /// le révèle — d'où ce second pump, qui doit rester vert en plus du premier.
  Future<void> pumpAsBottomNavigationBar(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(screenWidth, screenHeight));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        extendBody: true,
        body: const SizedBox.expand(),
        bottomNavigationBar: BoundedBottomNav(
          child: Container(key: const Key('bar'), color: Colors.blue, height: barHeight),
        ),
      ),
    ));
  }

  group('posée comme body (sanity check)', () {
    testWidgets('borne la largeur du contenu même sur un écran très large', (tester) async {
      await pumpInBody(tester);

      final size = tester.getSize(find.byKey(const Key('bar')));
      expect(size.width, BoundedBottomNav.maxWidth);
    });

    testWidgets('centre le contenu dans l\'espace disponible', (tester) async {
      await pumpInBody(tester);

      final barLeft = tester.getTopLeft(find.byKey(const Key('bar'))).dx;
      final expectedLeft = (screenWidth - BoundedBottomNav.maxWidth) / 2;
      expect(barLeft, closeTo(expectedLeft, 0.5));
    });
  });

  group('posée comme Scaffold.bottomNavigationBar (le vrai contexte d\'usage)', () {
    testWidgets('reste collée en bas, ne flotte pas au milieu de l\'écran', (tester) async {
      await pumpAsBottomNavigationBar(tester);

      final barTop = tester.getTopLeft(find.byKey(const Key('bar'))).dy;
      // La barre doit toucher (quasi) le bas de l'écran, pas son milieu.
      expect(barTop, greaterThan(screenHeight - barHeight - 40));
    });

    testWidgets('garde sa hauteur naturelle, ne s\'étire pas verticalement', (tester) async {
      await pumpAsBottomNavigationBar(tester);

      final size = tester.getSize(find.byKey(const Key('bar')));
      expect(size.height, barHeight);
    });

    testWidgets('reste centrée et bornée en largeur', (tester) async {
      await pumpAsBottomNavigationBar(tester);

      final size = tester.getSize(find.byKey(const Key('bar')));
      expect(size.width, BoundedBottomNav.maxWidth);
    });
  });
}
