import 'package:flutter_test/flutter_test.dart';
import 'package:smoothandesign_package/smoothandesign.dart';
import 'package:uzme/core/models/role_switch_advice.dart';

void main() {
  group('RoleSwitchAdvice.fromMap', () {
    test('parses a "stay where you are" payload', () {
      // Server normalizes `staying` based on equality between the two
      // role fields — we trust it as-is here because the UI uses it
      // verbatim to pick the green callout vs the switch CTA.
      final advice = RoleSwitchAdvice.fromMap({
        'recommendedRole': 'client',
        'staying': true,
        'currentRole': 'client',
        'reasoning': 'Tout va bien, ton activité correspond à un Artiste.',
        'highlights': ['Sessions actives', 'Aucun studio géré'],
      });

      expect(advice.recommendedRole, BaseUserRole.client);
      expect(advice.currentRole, BaseUserRole.client);
      expect(advice.staying, isTrue);
      expect(advice.highlights.length, 2);
    });

    test('parses a "switch role" payload', () {
      final advice = RoleSwitchAdvice.fromMap({
        'recommendedRole': 'admin',
        'staying': false,
        'currentRole': 'client',
        'reasoning': 'Tu as 12 sessions, passer en Studio est cohérent.',
        'highlights': [
          '12 sessions confirmées',
          '3 studios liés',
          'Pioneer #4',
        ],
      });

      expect(advice.recommendedRole, BaseUserRole.admin);
      expect(advice.staying, isFalse);
      expect(advice.highlights.first, '12 sessions confirmées');
    });

    test('falls back gracefully on missing or invalid fields', () {
      final advice = RoleSwitchAdvice.fromMap({
        'recommendedRole': 'mystery',
        'staying': null,
        // currentRole missing
        // highlights missing
      });

      // Both fields default to client when unparseable — the UI never
      // renders a null role so the screen always has something to show.
      expect(advice.recommendedRole, BaseUserRole.client);
      expect(advice.currentRole, BaseUserRole.client);
      expect(advice.staying, isFalse);
      expect(advice.reasoning, '');
      expect(advice.highlights, isEmpty);
    });
  });
}
