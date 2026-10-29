import 'package:flutter_test/flutter_test.dart';
import 'package:uzme/l10n/app_localizations_fr.dart';
import 'package:uzme/screens/artist/artist_nav_items.dart';
import 'package:uzme/screens/engineer/engineer_nav_items.dart';
import 'package:uzme/screens/studio/studio_nav_items.dart';

/// Régression : l'onglet Réglages affichait le même badge que l'onglet
/// Sessions (copier-coller de `pendingCount`), alors que rien dans Réglages
/// ne justifie un badge. Relevé par Ben le 29/10/2026 : « j'ai un badge sur
/// réglage... et lorsque je m'y rends je vois rien ».
void main() {
  final l10n = AppLocalizationsFr();

  test('artistRailItems: Réglages ne porte aucun badge même si des sessions sont en attente', () {
    final items = artistRailItems(l10n, pendingCount: 3);
    final settings = items.last;
    expect(settings.label, l10n.settings);
    expect(settings.badgeCount, 0);
  });

  test('engineerRailItems: Réglages ne porte aucun badge même si des sessions sont en attente', () {
    final items = engineerRailItems(l10n, pendingCount: 3);
    final settings = items.last;
    expect(settings.label, l10n.settings);
    expect(settings.badgeCount, 0);
  });

  test('studioRailItems: Réglages ne porte aucun badge même si des sessions sont en attente', () {
    final items = studioRailItems(l10n, pendingCount: 3);
    final settings = items.last;
    expect(settings.label, l10n.settings);
    expect(settings.badgeCount, 0);
  });
}
