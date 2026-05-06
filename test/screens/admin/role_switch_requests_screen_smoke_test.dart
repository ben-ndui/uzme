import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/screens/admin/role_switch_requests_screen.dart';

/// Smoke test for RoleSwitchRequestsScreen — mounting must succeed
/// without any **lifecycle** assertion (setState callback returning a
/// Future, missing l10n delegate, etc.).
///
/// We tolerate FirebaseException explicitly: the FutureBuilder's
/// network call hits `FirebaseFunctions.instance` which throws
/// `[core/no-app]` in test env without a Firebase app initialized.
/// That's expected and not what we're guarding against here. What we
/// catch is the family of bugs the framework would surface AT MOUNT
/// (synchronous, before the future resolves).
void main() {
  testWidgets('RoleSwitchRequestsScreen mounts without lifecycle errors',
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
        home: const RoleSwitchRequestsScreen(),
      ),
    );
    await tester.pump();

    // Drain expected Firebase no-app exception(s); fail on anything else.
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
