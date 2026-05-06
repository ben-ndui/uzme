import 'package:flutter_test/flutter_test.dart';
import 'package:uzme/core/models/whats_new_summary.dart';

void main() {
  group('WhatsNewSummary.fromMap', () {
    test('parses a populated payload with multiple items', () {
      final summary = WhatsNewSummary.fromMap({
        'intro': 'Salut ! Tu as 12 sessions confirmées, voici ce qui...',
        'items': [
          {
            'flagKey': 'ai_assistant',
            'title': 'AI Assistant',
            'summary': 'Tu peux demander des conseils sur tes prochaines sessions.',
            'action': 'Ouvre le chat depuis Messages.',
            'alreadySeen': false,
          },
          {
            'flagKey': 'digital_card',
            'title': 'Carte digitale',
            'summary': 'Partage ton profil Pro avec un QR code.',
            'action': 'Configure ta carte dans Settings.',
            'alreadySeen': true,
          },
        ],
        'empty': false,
      });

      expect(summary.intro, contains('Salut'));
      expect(summary.items.length, 2);
      expect(summary.items.first.flagKey, 'ai_assistant');
      expect(summary.items.first.alreadySeen, isFalse);
      expect(summary.items.last.alreadySeen, isTrue);
      expect(summary.empty, isFalse);
    });

    test('handles the empty case', () {
      final summary = WhatsNewSummary.fromMap({
        'intro': '',
        'items': [],
        'empty': true,
      });
      expect(summary.empty, isTrue);
      expect(summary.items, isEmpty);
    });

    test('falls back gracefully on missing fields', () {
      // Defensive — server fallback path drops some fields.
      final summary = WhatsNewSummary.fromMap({});
      expect(summary.intro, '');
      expect(summary.items, isEmpty);
      expect(summary.empty, isFalse);
    });

    test('item.fromMap maps fields correctly', () {
      final item = WhatsNewItem.fromMap({
        'flagKey': 'pioneer_perk',
        'title': 'Avantage Pioneer',
        'summary': 'Commission 0% permanente.',
        'action': 'Active Stripe Connect maintenant.',
        'alreadySeen': false,
      });
      expect(item.flagKey, 'pioneer_perk');
      expect(item.title, 'Avantage Pioneer');
      expect(item.alreadySeen, isFalse);
    });
  });
}
