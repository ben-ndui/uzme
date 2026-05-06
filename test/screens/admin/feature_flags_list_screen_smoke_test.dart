import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/screens/admin/feature_flags_list_screen.dart';

import '../../helpers/widget_test_helpers.dart';

/// Smoke test for FeatureFlagsListScreen — verifies it mounts cleanly
/// (StreamBuilder on featureFlagsService doesn't throw on initState,
/// no missing l10n delegate, etc.).
void main() {
  testWidgets('FeatureFlagsListScreen mounts without throwing',
      (tester) async {
    // Seed the global feature_flags service with an empty map so the
    // StreamBuilder gets a valid initial snapshot — empty list state
    // renders in the screen, which is the path we want to exercise.
    enableAllFeatureFlagsForTesting();

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
        home: const FeatureFlagsListScreen(),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
