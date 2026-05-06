import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smoothandesign_package/smoothandesign.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/widgets/role_switch/role_presentation.dart';

/// Resolve [AppLocalizations] without spinning up the full app — uses
/// a hidden widget that grabs the delegate-built instance.
Future<AppLocalizations> _l10n(WidgetTester tester) async {
  AppLocalizations? captured;
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
      home: Builder(
        builder: (context) {
          captured = AppLocalizations.of(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return captured!;
}

void main() {
  testWidgets('switchableRoles lists exactly the 3 user-facing roles',
      (tester) async {
    expect(RolePresentation.switchableRoles, [
      BaseUserRole.client,
      BaseUserRole.admin,
      BaseUserRole.worker,
    ]);
  });

  testWidgets('forRole(client) carries the artist copy', (tester) async {
    final l10n = await _l10n(tester);
    final p = RolePresentation.forRole(BaseUserRole.client, l10n);
    expect(p.role, BaseUserRole.client);
    expect(p.title, l10n.artist);
    expect(p.subtitle, l10n.roleArtistSubtitle);
    expect(p.features, isNotEmpty);
    expect(p.advantages, isNotEmpty);
    expect(p.cta, l10n.roleArtistCta);
  });

  testWidgets('forRole(admin) carries the studio copy', (tester) async {
    final l10n = await _l10n(tester);
    final p = RolePresentation.forRole(BaseUserRole.admin, l10n);
    expect(p.role, BaseUserRole.admin);
    expect(p.title, l10n.studio);
    expect(p.features.length, 5,
        reason: 'Studio gets 5 features per the spec');
  });

  testWidgets('forRole(worker) carries the engineer copy', (tester) async {
    final l10n = await _l10n(tester);
    final p = RolePresentation.forRole(BaseUserRole.worker, l10n);
    expect(p.role, BaseUserRole.worker);
    expect(p.title, l10n.engineer);
    expect(p.cta, l10n.roleEngineerCta);
  });

  testWidgets('forRole(superAdmin) safe-falls-back without crashing',
      (tester) async {
    // SuperAdmin has no public-facing card — the screen never lists
    // it, but the factory must still return *something* sane in case
    // a code path calls it.
    final l10n = await _l10n(tester);
    final p = RolePresentation.forRole(BaseUserRole.superAdmin, l10n);
    expect(p, isNotNull);
    expect(p.title, isNotEmpty);
  });

  testWidgets('every spec exposes 4 compare fields', (tester) async {
    // Locks the wire format for RoleCompareModal — if any compare
    // field is forgotten on a future role addition, this test fails.
    final l10n = await _l10n(tester);
    for (final role in RolePresentation.switchableRoles) {
      final p = RolePresentation.forRole(role, l10n);
      expect(p.compareAudience, isNotEmpty);
      expect(p.comparePricing, isNotEmpty);
      expect(p.compareTools, isNotEmpty);
      expect(p.compareIdeal, isNotEmpty);
    }
  });
}
