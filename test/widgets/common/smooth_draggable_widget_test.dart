import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uzme/widgets/common/smooth_draggable_widget.dart';

void main() {
  group('SmoothDraggableWidget.pinnedFooter', () {
    testWidgets(
        'stays flush with the true bottom of the screen, not the sheet\'s '
        'own (always-short-of-full) height — otherwise the modal\'s dimming '
        'barrier shows through as a black band underneath (Ben, 28/10)',
        (tester) async {
      // ⚠️ Reproduire via un vrai `showModalBottomSheet` (isScrollControlled)
      // est essentiel ici : un `Scaffold.body` direct donne des contraintes
      // STRICTES (toujours la taille de l'écran, bug ou pas) qui masquaient
      // le bug — seule la modale donne les contraintes LÂCHES où le `Stack`
      // externe, sans `SizedBox.expand`, se contentait de la taille de la
      // feuille au lieu du plein écran.
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => SmoothDraggableWidget(
                    // Petite feuille à peine ouverte : le bug se voyait
                    // précisément quand la feuille n'occupe qu'une fraction
                    // de l'écran.
                    initial: 0.3,
                    minSize: 0.3,
                    maxSize: 0.92,
                    bodyContent: const SizedBox(height: 50),
                    pinnedFooter: Container(
                      key: const Key('footer'),
                      height: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      // La modale glisse depuis le bas de l'écran : il faut laisser cette
      // animation finir avant de mesurer une position, sinon on juge une
      // image intermédiaire du slide-up, pas l'état au repos.
      await tester.pumpAndSettle();

      final footerBottom =
          tester.getBottomLeft(find.byKey(const Key('footer'))).dy;
      final screenHeight =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;

      expect(footerBottom, screenHeight);
    });
  });
}
