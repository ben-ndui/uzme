import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/widgets/admin/pioneer_create_sheet.dart';

/// Smoke test for PioneerCreateSheet — mounting the bottom sheet must
/// succeed without any **lifecycle** assertion. The form is fully
/// stateful and DateFormat depends on `Localizations.localeOf(context)`
/// being initialized, so this catches missing l10n delegates and
/// missing locales — regressions of the v1.5.20 setState-arrow class.
void main() {
  testWidgets('PioneerCreateSheet mounts without lifecycle errors',
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
        home: const Scaffold(body: PioneerCreateSheet()),
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
