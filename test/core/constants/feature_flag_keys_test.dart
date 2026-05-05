import 'package:flutter_test/flutter_test.dart';
import 'package:uzme/core/constants/feature_flag_keys.dart';

void main() {
  group('FeatureFlagKeys catalogue', () {
    test('every spec in `all` has a unique snake_case key', () {
      final keys = <String>{};
      for (final spec in FeatureFlagKeys.all) {
        expect(
          RegExp(r'^[a-z0-9_]+$').hasMatch(spec.key),
          isTrue,
          reason: 'Key "${spec.key}" must be snake_case',
        );
        expect(keys.add(spec.key), isTrue, reason: 'Duplicate key: ${spec.key}');
      }
    });

    test('every spec has non-empty title + category', () {
      for (final spec in FeatureFlagKeys.all) {
        expect(spec.title, isNotEmpty, reason: 'Spec ${spec.key} title is empty');
        expect(spec.category, isNotEmpty,
            reason: 'Spec ${spec.key} category is empty');
      }
    });

    test('lookup returns the matching spec', () {
      final spec = FeatureFlagKeys.lookup('ai_assistant');
      expect(spec, isNotNull);
      expect(spec!.key, 'ai_assistant');
      expect(spec.title, 'AI Assistant');
      expect(spec.category, 'ai');
    });

    test('lookup returns null for unknown key', () {
      expect(FeatureFlagKeys.lookup('not_a_real_flag'), isNull);
    });

    test('isCatalogued matches lookup', () {
      expect(FeatureFlagKeys.isCatalogued('ai_assistant'), isTrue);
      expect(FeatureFlagKeys.isCatalogued('ai_assistant_pro'), isTrue);
      expect(FeatureFlagKeys.isCatalogued('ghost_flag'), isFalse);
    });

    test('B3.1 AI gates are present in the catalogue', () {
      // These keys are referenced by conversations_screen.dart and
      // studio_config_section.dart. If a rename ever drops them from the
      // catalogue, this test fails BEFORE the runtime gates silently break.
      expect(FeatureFlagKeys.aiAssistant.key, 'ai_assistant');
      expect(FeatureFlagKeys.aiAssistantPro.key, 'ai_assistant_pro');
    });

    test('B3.2 premium gates are present in the catalogue', () {
      // Referenced by studio_config_section, calendar_connection_section,
      // settings_digital_card_tile, and the 3 home/dashboard quick-access
      // pills. Same protection as the AI gate test above.
      expect(FeatureFlagKeys.stripeConnectOnboarding.key,
          'stripe_connect_onboarding');
      expect(FeatureFlagKeys.calendarGoogleSync.key, 'calendar_google_sync');
      expect(FeatureFlagKeys.digitalCard.key, 'digital_card');
    });
  });
}
