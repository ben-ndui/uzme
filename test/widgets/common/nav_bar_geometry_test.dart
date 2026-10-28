import 'package:flutter_test/flutter_test.dart';
import 'package:uzme/widgets/common/nav_bar_geometry.dart';

void main() {
  group('NavBarGeometry', () {
    test('full mode splits width evenly across tabs', () {
      final geo = NavBarGeometry(
        totalWidth: 310,
        count: 5,
        activeIndex: 0,
        compact: false,
        gap: 2,
        minWidth: 44,
      );

      // (310 - 4*2) / 5 = 60.4
      expect(geo.width(0), closeTo(60.4, 0.01));
      expect(geo.width(2), closeTo(60.4, 0.01));
      expect(geo.labelFits(90), isTrue);
    });

    test(
      'compact mode gives every tab the floor width except the active one',
      () {
        final geo = NavBarGeometry(
          totalWidth: 310,
          count: 5,
          activeIndex: 2,
          compact: true,
          gap: 2,
          minWidth: 44,
        );

        expect(geo.width(0), 44);
        expect(geo.width(1), 44);
        expect(geo.width(3), 44);
        // Reste pour l'actif : 310 - 4*2 - 4*44 = 126
        expect(geo.width(2), closeTo(126, 0.01));
      },
    );

    test(
      'active tab width never drops below the tap floor on a narrow bar',
      () {
        final geo = NavBarGeometry(
          totalWidth: 180,
          count: 5,
          activeIndex: 0,
          compact: true,
          gap: 2,
          minWidth: 44,
        );

        // La barre déborde plutôt que de couper la cible tactile.
        expect(geo.width(0), 44);
      },
    );

    test(
      'left() places each tab right after the previous one plus the gap',
      () {
        final geo = NavBarGeometry(
          totalWidth: 220,
          count: 4,
          activeIndex: 0,
          compact: false,
          gap: 2,
          minWidth: 44,
        );

        expect(geo.left(0), 0);
        expect(geo.left(1), closeTo(geo.width(0) + 2, 0.01));
        expect(geo.left(2), closeTo(geo.width(0) + geo.width(1) + 4, 0.01));
      },
    );

    test(
      'labelFits is false when the active tab is too narrow for a label',
      () {
        final geo = NavBarGeometry(
          totalWidth: 180,
          count: 6,
          activeIndex: 0,
          compact: true,
          gap: 2,
          minWidth: 44,
        );

        // Avec 6 onglets sur 180px, l'actif n'a que le plancher tactile.
        expect(geo.labelFits(90), isFalse);
      },
    );
  });
}
