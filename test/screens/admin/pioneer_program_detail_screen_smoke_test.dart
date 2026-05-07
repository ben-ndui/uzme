import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/screens/admin/pioneer_program_detail_screen.dart';

/// Smoke test for PioneerProgramDetailScreen — mounting must succeed
/// without any **lifecycle** assertion. Same Firebase-no-app exception
/// drain as the sibling pioneer list smoke test.
void main() {
  testWidgets('PioneerProgramDetailScreen mounts without lifecycle errors',
      (tester) async {
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
        home: const PioneerProgramDetailScreen(programId: 'test-program-id'),
      ),
    );
    await tester.pump();

    Object? exception;
    while ((exception = tester.takeException()) != null) {
      final str = exception.toString();
      if (str.contains('FirebaseException') ||
          str.contains('No Firebase App')) {
        continue;
      }
      fail('Unexpected exception at mount: $exception');
    }
  });
}
