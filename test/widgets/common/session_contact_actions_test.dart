import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smoothandesign_package/smoothandesign.dart';
import 'package:uzme/core/models/models_exports.dart';
import 'package:uzme/widgets/common/session/session_contact_actions.dart';

import '../../helpers/mock_services.dart';
import '../../helpers/test_factories.dart';
import '../../helpers/widget_test_helpers.dart';

class _FakeMessagingEvent extends Fake implements MessagingEvent {}

void main() {
  late MockProProfileService mockProfileService;
  late MockAuthBloc mockAuthBloc;
  late MockMessagingBloc mockMessagingBloc;

  setUpAll(() {
    registerFallbackValue(_FakeMessagingEvent());
  });

  setUp(() {
    mockProfileService = MockProProfileService();
    mockAuthBloc = MockAuthBloc();
    mockMessagingBloc = MockMessagingBloc();

    when(() => mockAuthBloc.state).thenReturn(
      AuthAuthenticatedState(user: testAppUser(uid: 'artist-1', name: 'Ben')),
    );
    when(() => mockMessagingBloc.state).thenReturn(const MessagingInitialState());
  });

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(buildTestApp(
      authBloc: mockAuthBloc,
      messagingBloc: mockMessagingBloc,
      child: Scaffold(body: child),
    ));
    await tester.pumpAndSettle();
  }

  group(
    'SessionContactActions '
    '(Ben 29/10/2026 : « message + appel sur la carte, et raccourcis sur le détail »)',
    () {
      testWidgets('studio sans téléphone : message seul, pas d\'icône appel', (tester) async {
        final session = SessionFactory.create(
          studioId: 'studio-1',
          scheduledStart: DateTime.now().add(const Duration(days: 1)),
          scheduledEnd: DateTime.now().add(const Duration(days: 1, hours: 2)),
        );
        when(() => mockProfileService.getUser('studio-1')).thenAnswer(
          (_) async => AppUser(
            uid: 'studio-1',
            email: 's@example.com',
            isPartner: true,
            studioProfile: const StudioProfile(name: 'Studio Lumière'),
          ),
        );

        await pump(
          tester,
          SessionContactActions(session: session, profileService: mockProfileService),
        );

        expect(find.byIcon(FontAwesomeIcons.solidMessage.data), findsOneWidget);
        expect(find.byIcon(FontAwesomeIcons.phone.data), findsNothing);
        expect(find.byIcon(FontAwesomeIcons.diamondTurnRight.data), findsNothing);
      });

      testWidgets('studio avec téléphone : message + appel', (tester) async {
        final session = SessionFactory.create(
          studioId: 'studio-2',
          scheduledStart: DateTime.now().add(const Duration(days: 1)),
          scheduledEnd: DateTime.now().add(const Duration(days: 1, hours: 2)),
        );
        when(() => mockProfileService.getUser('studio-2')).thenAnswer(
          (_) async => AppUser(
            uid: 'studio-2',
            email: 's@example.com',
            isPartner: true,
            studioProfile: const StudioProfile(name: 'Studio Lumière', phone: '0612345678'),
          ),
        );

        await pump(
          tester,
          SessionContactActions(session: session, profileService: mockProfileService),
        );

        expect(find.byIcon(FontAwesomeIcons.solidMessage.data), findsOneWidget);
        expect(find.byIcon(FontAwesomeIcons.phone.data), findsOneWidget);
      });

      testWidgets('showDirections=false (carte) : jamais d\'icône itinéraire, même avec une position', (tester) async {
        final session = SessionFactory.create(
          studioId: 'studio-3',
          scheduledStart: DateTime.now().add(const Duration(days: 1)),
          scheduledEnd: DateTime.now().add(const Duration(days: 1, hours: 2)),
        );
        when(() => mockProfileService.getUser('studio-3')).thenAnswer(
          (_) async => AppUser(
            uid: 'studio-3',
            email: 's@example.com',
            isPartner: true,
            studioProfile: const StudioProfile(
              name: 'Studio Lumière',
              location: GeoPoint(48.85, 2.35),
            ),
          ),
        );

        await pump(
          tester,
          SessionContactActions(session: session, profileService: mockProfileService),
        );

        expect(find.byIcon(FontAwesomeIcons.diamondTurnRight.data), findsNothing);
      });

      testWidgets('tap sur message envoie StartPrivateConversationEvent', (tester) async {
        final session = SessionFactory.create(
          studioId: 'studio-4',
          scheduledStart: DateTime.now().add(const Duration(days: 1)),
          scheduledEnd: DateTime.now().add(const Duration(days: 1, hours: 2)),
        );
        when(() => mockProfileService.getUser('studio-4')).thenAnswer(
          (_) async => AppUser(
            uid: 'studio-4',
            email: 's@example.com',
            isPartner: true,
            studioProfile: const StudioProfile(name: 'Studio Lumière'),
          ),
        );

        await pump(
          tester,
          SessionContactActions(session: session, profileService: mockProfileService),
        );

        await tester.tap(find.byIcon(FontAwesomeIcons.solidMessage.data));
        await tester.pumpAndSettle();

        verify(
          () => mockMessagingBloc.add(any(that: isA<StartPrivateConversationEvent>())),
        ).called(1);
      });

      testWidgets('session pro sans profil résolu : rien ne s\'affiche', (tester) async {
        final session = SessionFactory.create(
          scheduledStart: DateTime.now().add(const Duration(days: 1)),
          scheduledEnd: DateTime.now().add(const Duration(days: 1, hours: 2)),
        ).copyWith(proId: 'pro-introuvable', proName: 'Léo');
        when(() => mockProfileService.getUser('pro-introuvable'))
            .thenAnswer((_) async => null);

        await pump(
          tester,
          SessionContactActions(session: session, profileService: mockProfileService),
        );

        expect(find.byIcon(FontAwesomeIcons.solidMessage.data), findsNothing);
      });
    },
  );
}
