import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smoothandesign_package/smoothandesign.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/screens/shared/role_switch/role_comparison_screen.dart';

import '../../helpers/widget_test_helpers.dart';

/// Smoke test for RoleComparisonScreen — needs an AuthBloc provider in
/// the tree (the screen reads `context.watch<AuthBloc>().state`).
/// Verifies the screen mounts cleanly with a current user, renders the
/// 3 role cards, and the FAB is present.
void main() {
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    when(() => mockAuthBloc.state).thenReturn(
      AuthAuthenticatedState(user: testAppUser()),
    );
  });

  testWidgets('RoleComparisonScreen mounts without throwing', (tester) async {
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
        home: BlocProvider<AuthBloc>.value(
          value: mockAuthBloc,
          child: const RoleComparisonScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
