import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uzme/widgets/common/bounded_bottom_nav.dart';

/// DA 2026-2027 (Ben, 29/09/2026) : jamais de barre latérale, même sur grand
/// écran — la barre du bas reste, centrée et de largeur bornée. Régression
/// visée (30/10/2026) : la nav rail d'iPad a été remplacée par la barre
/// flottante mobile, qui doit rester bornée pour ne pas s'étirer sur toute
/// la largeur d'un iPad en paysage.
void main() {
  // Un iPad en paysage : plus large que n'importe quel plancher tactile,
  // c'est exactement le cas qui étirait l'ancienne NavigationRail.
  const screenWidth = 1200.0;

  Future<void> pumpBar(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(screenWidth, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BoundedBottomNav(
          child: Container(key: const Key('bar'), color: Colors.blue, height: 68),
        ),
      ),
    ));
  }

  testWidgets('borne la largeur du contenu même sur un écran très large', (tester) async {
    await pumpBar(tester);

    final size = tester.getSize(find.byKey(const Key('bar')));
    expect(size.width, BoundedBottomNav.maxWidth);
  });

  testWidgets('centre le contenu dans l\'espace disponible', (tester) async {
    await pumpBar(tester);

    final barLeft = tester.getTopLeft(find.byKey(const Key('bar'))).dx;
    final expectedLeft = (screenWidth - BoundedBottomNav.maxWidth) / 2;
    expect(barLeft, closeTo(expectedLeft, 0.5));
  });
}
