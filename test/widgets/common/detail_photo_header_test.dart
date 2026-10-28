import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uzme/widgets/common/detail_photo_header.dart';

void main() {
  Widget build({
    List<String> photoUrls = const [],
    List<String?> attributions = const [],
    bool isLoading = false,
    bool hasError = false,
    Widget? topRight,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: DetailPhotoHeader(
          photoUrls: photoUrls,
          attributions: attributions,
          isLoading: isLoading,
          hasError: hasError,
          placeholderIcon: FontAwesomeIcons.buildingUser,
          topRight: topRight,
        ),
      ),
    );
  }

  FaIcon findFaIcon(WidgetTester tester) =>
      tester.widget<FaIcon>(find.byType(FaIcon));

  group('DetailPhotoHeader', () {
    testWidgets('empty + not loading shows the PLACEHOLDER icon, no PageView', (
      tester,
    ) async {
      await tester.pumpWidget(build());
      await tester.pumpAndSettle();

      expect(find.byType(PageView), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(findFaIcon(tester).icon, FontAwesomeIcons.buildingUser.data);
    });

    testWidgets(
      'empty + hasError shows the ERROR icon, distinct from the placeholder',
      (tester) async {
        // Un échec réseau sur Place Details ne doit pas ressembler à un
        // studio qui n'a vraiment aucune photo — sinon l'un se fait passer
        // pour l'autre à l'écran.
        await tester.pumpWidget(build(hasError: true));
        await tester.pumpAndSettle();

        expect(find.byType(PageView), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(
          findFaIcon(tester).icon,
          FontAwesomeIcons.triangleExclamation.data,
        );
      },
    );

    testWidgets('loading wins over hasError while a retry is in flight', (
      tester,
    ) async {
      await tester.pumpWidget(build(isLoading: true, hasError: true));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(FaIcon), findsNothing);
    });

    testWidgets('empty + loading shows a spinner, no placeholder icon', (
      tester,
    ) async {
      await tester.pumpWidget(build(isLoading: true));
      await tester.pump();

      expect(find.byType(PageView), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(FaIcon), findsNothing);
    });

    testWidgets('single photo shows a gallery without page dots', (
      tester,
    ) async {
      await tester.pumpWidget(
        build(photoUrls: const ['https://example.com/a.jpg']),
      );
      await tester.pump();

      expect(find.byType(PageView), findsOneWidget);
      // Les pastilles de pagination n'apparaissent qu'à partir de 2 photos.
      expect(find.byType(AnimatedContainer), findsNothing);
    });

    testWidgets('multiple photos show page dots, one per photo', (
      tester,
    ) async {
      await tester.pumpWidget(
        build(
          photoUrls: const [
            'https://example.com/a.jpg',
            'https://example.com/b.jpg',
            'https://example.com/c.jpg',
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(PageView), findsOneWidget);
      expect(find.byType(AnimatedContainer), findsNWidgets(3));
    });

    testWidgets('renders the topRight slot over the photo', (tester) async {
      await tester.pumpWidget(
        build(
          photoUrls: const ['https://example.com/a.jpg'],
          topRight: const Icon(Icons.favorite, key: Key('fav')),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('fav')), findsOneWidget);
    });

    testWidgets('broken image falls back to the placeholder icon', (
      tester,
    ) async {
      // En test, l'image ne peut pas charger (pas de vrai réseau) :
      // errorWidget doit prendre le relais au lieu de laisser planter l'arbre.
      await tester.pumpWidget(
        build(photoUrls: const ['https://example.com/broken.jpg']),
      );
      await tester.pumpAndSettle();

      expect(findFaIcon(tester).icon, FontAwesomeIcons.buildingUser.data);
    });

    testWidgets('shows the Google attribution for the current page only', (
      tester,
    ) async {
      await tester.pumpWidget(
        build(
          photoUrls: const [
            'https://example.com/a.jpg',
            'https://example.com/b.jpg',
          ],
          attributions: const ['Jean Dupont', null],
        ),
      );
      await tester.pump();

      expect(find.text('Jean Dupont'), findsOneWidget);
    });

    testWidgets(
      'no attribution overlay when the gallery has none (partner/pro)',
      (tester) async {
        await tester.pumpWidget(
          build(photoUrls: const ['https://example.com/a.jpg']),
        );
        await tester.pump();

        expect(find.byType(Text), findsNothing);
      },
    );
  });
}
