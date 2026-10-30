import 'package:flutter_test/flutter_test.dart';
import 'package:uzme/l10n/app_localizations_fr.dart';
import 'package:uzme/screens/artist/artist_nav_items.dart';
import 'package:uzme/screens/engineer/engineer_nav_items.dart';
import 'package:uzme/screens/studio/studio_nav_items.dart';

/// Régression : l'onglet Réglages affichait le même badge que l'onglet
/// Sessions (copier-coller de `pendingCount`), alors que rien dans Réglages
/// ne justifie un badge. Relevé par Ben le 29/10/2026 : « j'ai un badge sur
/// réglage... et lorsque je m'y rends je vois rien ».
///
/// Ces listes alimentent désormais la même barre flottante [UzmeNavBar] sur
/// mobile ET tablette/desktop (DA 2026-2027 : plus de barre latérale,
/// audit 2026-10-30) — le test ne change pas, seul le type des items a
/// changé (`UzmeNavItem` au lieu de l'ancien `AppNavRailItem`).
void main() {
  final l10n = AppLocalizationsFr();

  test('artistNavItems: Réglages ne porte aucun badge même si des sessions sont en attente', () {
    final items = artistNavItems(l10n, pendingCount: 3);
    final settings = items.last;
    expect(settings.label, l10n.settings);
    expect(settings.badgeCount, 0);
  });

  test('engineerNavItems: Réglages ne porte aucun badge même si des sessions sont en attente', () {
    final items = engineerNavItems(l10n, pendingCount: 3);
    final settings = items.last;
    expect(settings.label, l10n.settings);
    expect(settings.badgeCount, 0);
  });

  test('studioNavItems: Réglages ne porte aucun badge même si des sessions sont en attente', () {
    final items = studioNavItems(l10n, pendingCount: 3);
    final settings = items.last;
    expect(settings.label, l10n.settings);
    expect(settings.badgeCount, 0);
  });

  test('artistNavItems: Messages porte le compteur de non-lus, pas celui des sessions', () {
    final items = artistNavItems(l10n, pendingCount: 3, unreadCount: 7);
    final messages = items[3];
    expect(messages.label, l10n.messages);
    expect(messages.badgeCount, 7);
  });
}
