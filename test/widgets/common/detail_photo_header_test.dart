import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uzme/widgets/common/detail_photo_header.dart';

void main() {
  Widget build({
    List<String> photoUrls = const [],
    bool isLoading = false,
    Widget? topRight,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: DetailPhotoHeader(
          photoUrls: photoUrls,
          isLoading: isLoading,
          placeholderIcon: FontAwesomeIcons.buildingUser,
          topRight: topRight,
        ),
      ),
    );
  }

  group('DetailPhotoHeader', () {
    testWidgets('empty + not loading shows placeholder icon, no PageView', (tester) async {
      await tester.pumpWidget(build());
      await tester.pumpAndSettle();

      expect(find.byType(PageView), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(FaIcon), findsOneWidget);
    });

    testWidgets('empty + loading shows a spinner, no placeholder icon', (tester) async {
      await tester.pumpWidget(build(isLoading: true));
      await tester.pump();

      expect(find.byType(PageView), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(FaIcon), findsNothing);
    });

    testWidgets('single photo shows a gallery without page dots', (tester) async {
      await tester.pumpWidget(build(photoUrls: const ['https://example.com/a.jpg']));
      await tester.pump();

      expect(find.byType(PageView), findsOneWidget);
      // Les pastilles de pagination n'apparaissent qu'à partir de 2 photos.
      expect(find.byType(AnimatedContainer), findsNothing);
    });

    testWidgets('multiple photos show page dots, one per photo', (tester) async {
      await tester.pumpWidget(build(photoUrls: const [
        'https://example.com/a.jpg',
        'https://example.com/b.jpg',
        'https://example.com/c.jpg',
      ]));
      await tester.pump();

      expect(find.byType(PageView), findsOneWidget);
      expect(find.byType(AnimatedContainer), findsNWidgets(3));
    });

    testWidgets('renders the topRight slot over the photo', (tester) async {
      await tester.pumpWidget(build(
        photoUrls: const ['https://example.com/a.jpg'],
        topRight: const Icon(Icons.favorite, key: Key('fav')),
      ));
      await tester.pump();

      expect(find.byKey(const Key('fav')), findsOneWidget);
    });

    testWidgets('broken image falls back to the placeholder icon', (tester) async {
      // En test, Image.network ne peut pas charger (pas de vrai réseau) :
      // errorBuilder doit prendre le relais au lieu de laisser planter l'arbre.
      await tester.pumpWidget(build(photoUrls: const ['https://example.com/broken.jpg']));
      await tester.pumpAndSettle();

      expect(find.byType(FaIcon), findsOneWidget);
    });
  });
}
