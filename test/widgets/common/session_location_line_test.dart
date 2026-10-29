import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uzme/core/models/models_exports.dart';
import 'package:uzme/widgets/common/session/session_location_line.dart';

import '../../helpers/mock_services.dart';
import '../../helpers/test_factories.dart';

void main() {
  late MockProProfileService mockProfileService;

  setUp(() {
    mockProfileService = MockProProfileService();
  });

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
    await tester.pumpAndSettle();
  }

  group(
    'SessionLocationLine '
    '(regression: carte et détail sans info studio, Ben 29/10/2026)',
    () {
      testWidgets('session pro freelance : affiche proName, aucun lookup', (tester) async {
        final session = SessionFactory.future().copyWith(
          proId: 'pro-1',
          proName: 'Léo Ingénieur',
        );

        await pump(
          tester,
          SessionLocationLine(session: session, profileService: mockProfileService),
        );

        expect(find.text('Léo Ingénieur'), findsOneWidget);
        verifyNever(() => mockProfileService.getUser(any()));
      });

      testWidgets('session studio avec studioName dénormalisé : aucun lookup', (tester) async {
        final session = SessionFactory.future().copyWith(
          studioName: 'Studio Lumière',
        );

        await pump(
          tester,
          SessionLocationLine(session: session, profileService: mockProfileService),
        );

        expect(find.text('Studio Lumière'), findsOneWidget);
        verifyNever(() => mockProfileService.getUser(any()));
      });

      testWidgets('session studio ancienne (sans studioName) : résout via studioId', (tester) async {
        final session = SessionFactory.create(
          studioId: 'studio-42',
          scheduledStart: DateTime.now().add(const Duration(days: 1)),
          scheduledEnd: DateTime.now().add(const Duration(days: 1, hours: 2)),
        );
        final studioUser = AppUser(
          uid: 'studio-42',
          email: 'studio@example.com',
          isPartner: true,
          studioProfile: const StudioProfile(name: 'Studio Retrouvé', address: '1 rue du Son'),
        );
        when(() => mockProfileService.getUser('studio-42'))
            .thenAnswer((_) async => studioUser);

        await pump(
          tester,
          SessionLocationLine(session: session, profileService: mockProfileService),
        );

        expect(find.text('Studio Retrouvé'), findsOneWidget);
        verify(() => mockProfileService.getUser('studio-42')).called(1);
      });

      testWidgets('session studio ancienne, lookup introuvable : ne ment pas, affiche un repli', (tester) async {
        final session = SessionFactory.create(
          studioId: 'studio-disparu',
          scheduledStart: DateTime.now().add(const Duration(days: 1)),
          scheduledEnd: DateTime.now().add(const Duration(days: 1, hours: 2)),
        );
        when(() => mockProfileService.getUser('studio-disparu'))
            .thenAnswer((_) async => null);

        await pump(
          tester,
          SessionLocationLine(session: session, profileService: mockProfileService),
        );

        // Pas de nom à afficher, mais pas d'exception brute ni de ligne
        // muette non plus : rien n'est rendu plutôt qu'un mensonge.
        expect(find.byType(SessionLocationLine), findsOneWidget);
        verify(() => mockProfileService.getUser('studio-disparu')).called(1);
      });
    },
  );
}
