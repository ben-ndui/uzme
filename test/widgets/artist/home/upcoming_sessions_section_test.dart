import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uzme/core/blocs/blocs_exports.dart';
import 'package:uzme/widgets/artist/home/upcoming_sessions_section.dart';

import '../../../helpers/widget_test_helpers.dart';

void main() {
  late MockSessionBloc mockSessionBloc;

  setUp(() {
    mockSessionBloc = MockSessionBloc();
  });

  Widget build() {
    return buildTestApp(
      sessionBloc: mockSessionBloc,
      child: const Scaffold(body: UpcomingSessionsSection()),
    );
  }

  group('UpcomingSessionsSection empty state', () {
    testWidgets(
        'shows no action button — the portal FAB already books a session, '
        'a second identical button here duplicated it on screen (Ben, 28/10)',
        (tester) async {
      when(() => mockSessionBloc.state).thenReturn(const SessionState(sessions: []));

      await tester.pumpWidget(build());
      await tester.pumpAndSettle();

      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(TextButton), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
    });
  });
}
