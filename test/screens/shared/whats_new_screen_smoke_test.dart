import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/screens/shared/whats_new_screen.dart';

/// Smoke test — mounts the screen exactly like real navigation does
/// and verifies it doesn't throw on `initState`. Catches the family of
/// bugs unit tests don't see :
///   - "setState callback returned a Future" (sync vs async lifecycle)
///   - missing localization delegates
///   - null-deref on first frame
///
/// We don't assert on AI output (the call would hit the network and
/// fail in test env). The default behaviour without Firebase wired is
/// that the FutureBuilder shows the loading state and stays there —
/// which is enough to prove the screen mounts cleanly.
void main() {
  testWidgets('WhatsNewScreen mounts without throwing', (tester) async {
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
        home: const WhatsNewScreen(),
      ),
    );
    // First frame — initState ran. If setState callback returned a
    // Future, this would have thrown already.
    await tester.pump();

    // Loading label is shown by the screen while the FutureBuilder
    // resolves. We verify it landed without firing exceptions, which
    // is what we care about here.
    expect(tester.takeException(), isNull);
  });
}
