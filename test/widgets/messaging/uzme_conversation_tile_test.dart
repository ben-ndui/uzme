import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:smoothandesign_package/smoothandesign.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/widgets/messaging/uzme_conversation_tile.dart';

BaseConversation _privateConversation({
  required String currentUid,
  required String otherUid,
  required String otherName,
  String? otherRole,
  bool otherIsPioneer = false,
}) {
  final now = DateTime(2026, 5, 5);
  return BaseConversation(
    id: 'c1',
    type: ConversationType.private,
    createdAt: now,
    updatedAt: now,
    createdByUserId: currentUid,
    participantIds: [currentUid, otherUid],
    participantDetails: {
      otherUid: ParticipantInfo(
        name: otherName,
        role: otherRole,
        isPioneer: otherIsPioneer,
      ),
      currentUid: const ParticipantInfo(name: 'Me'),
    },
  );
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: child),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('UzmeConversationTile', () {
    testWidgets('renders the contact name', (tester) async {
      await _pump(
        tester,
        UzmeConversationTile(
          conversation: _privateConversation(
            currentUid: 'me',
            otherUid: 'other',
            otherName: 'Studio Lambda',
          ),
          currentUserId: 'me',
        ),
      );
      expect(find.text('Studio Lambda'), findsOneWidget);
    });

    testWidgets('shows the role chip when participant role is admin',
        (tester) async {
      await _pump(
        tester,
        UzmeConversationTile(
          conversation: _privateConversation(
            currentUid: 'me',
            otherUid: 'studio-uid',
            otherName: 'Cool Studio',
            otherRole: 'admin',
          ),
          currentUserId: 'me',
        ),
      );
      expect(find.text('Studio'), findsOneWidget);
    });

    testWidgets('shows the role chip for worker (Ingé)', (tester) async {
      await _pump(
        tester,
        UzmeConversationTile(
          conversation: _privateConversation(
            currentUid: 'me',
            otherUid: 'eng-uid',
            otherName: 'John Eng',
            otherRole: 'worker',
          ),
          currentUserId: 'me',
        ),
      );
      expect(find.text('Ingé'), findsOneWidget);
    });

    testWidgets('shows the role chip for client (Artiste)', (tester) async {
      await _pump(
        tester,
        UzmeConversationTile(
          conversation: _privateConversation(
            currentUid: 'me',
            otherUid: 'artist-uid',
            otherName: 'MC X',
            otherRole: 'client',
          ),
          currentUserId: 'me',
        ),
      );
      expect(find.text('Artiste'), findsOneWidget);
    });

    testWidgets('renders the Pioneer star when isPioneer is true',
        (tester) async {
      await _pump(
        tester,
        UzmeConversationTile(
          conversation: _privateConversation(
            currentUid: 'me',
            otherUid: 'pioneer-uid',
            otherName: 'Pioneer Studio',
            otherRole: 'admin',
            otherIsPioneer: true,
          ),
          currentUserId: 'me',
        ),
      );
      expect(find.byIcon(FontAwesomeIcons.solidStar), findsOneWidget);
    });

    testWidgets('omits the Pioneer star when isPioneer is false',
        (tester) async {
      await _pump(
        tester,
        UzmeConversationTile(
          conversation: _privateConversation(
            currentUid: 'me',
            otherUid: 'plain-uid',
            otherName: 'Plain Studio',
            otherRole: 'admin',
          ),
          currentUserId: 'me',
        ),
      );
      expect(find.byIcon(FontAwesomeIcons.solidStar), findsNothing);
    });

    testWidgets('omits the role chip when participant role is missing',
        (tester) async {
      // Defensive : conversations created before the role denorm was
      // wired won't have role on participantDetails. Tile must still
      // render cleanly without throwing or showing stale chip.
      await _pump(
        tester,
        UzmeConversationTile(
          conversation: _privateConversation(
            currentUid: 'me',
            otherUid: 'other',
            otherName: 'Anonymous',
          ),
          currentUserId: 'me',
        ),
      );
      expect(find.text('Anonymous'), findsOneWidget);
      // No chip means no role-label string.
      expect(find.text('Studio'), findsNothing);
      expect(find.text('Ingé'), findsNothing);
      expect(find.text('Artiste'), findsNothing);
    });
  });
}
