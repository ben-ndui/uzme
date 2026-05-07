import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/screens/admin/pioneer_programs_list_screen.dart';

/// Smoke test for PioneerProgramsListScreen — mounting must succeed
/// without any **lifecycle** assertion (setState callback returning a
/// Future, missing l10n delegate, missing locale, etc.).
///
/// We tolerate FirebaseException explicitly: the StreamBuilder hits
/// `FirebaseFirestore.instance` which throws `[core/no-app]` in test
/// env without a Firebase app initialized. That's expected and not
/// what we're guarding against here.
void main() {
  testWidgets('PioneerProgramsListScreen mounts without lifecycle errors',
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
        home: const PioneerProgramsListScreen(),
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
