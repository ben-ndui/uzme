import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uzme/core/models/discovered_studio.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/widgets/map/studio_map_list_fallback.dart';

/// Régression (Ben, 30/10/2026) : `google_maps_flutter` n'a pas
/// d'implémentation macOS — la carte doit se replier sur cette liste au
/// lieu d'un écran cassé.
void main() {
  Widget wrap(Widget child) => MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  const studio = DiscoveredStudio(
    id: 'studio-1',
    name: 'Smooth Studio',
    position: LatLng(43.7, 7.26),
    isPartner: true,
    rating: 4.5,
    distanceMeters: 1200,
  );

  testWidgets('chargement initial : indicateur + texte', (tester) async {
    await tester.pumpWidget(wrap(StudioMapListFallback(
      isLoading: true,
      studios: const [],
      onStudioTap: (_) {},
    )));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('aucun studio : état vide', (tester) async {
    await tester.pumpWidget(wrap(StudioMapListFallback(
      isLoading: false,
      studios: const [],
      onStudioTap: (_) {},
    )));

    expect(find.text('Aucun studio trouvé'), findsOneWidget);
  });

  testWidgets('liste : nom, distance et badge partenaire affichés, tap déclenche le callback',
      (tester) async {
    DiscoveredStudio? tapped;
    await tester.pumpWidget(wrap(StudioMapListFallback(
      isLoading: false,
      studios: const [studio],
      onStudioTap: (s) => tapped = s,
    )));

    expect(find.text('Smooth Studio'), findsOneWidget);
    expect(find.textContaining('Partenaire'), findsOneWidget);
    expect(find.textContaining('★ 4.5'), findsOneWidget);

    await tester.tap(find.text('Smooth Studio'));
    expect(tapped, studio);
  });
}
