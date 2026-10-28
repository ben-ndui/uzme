import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uzme/core/models/session.dart';
import 'package:uzme/widgets/common/session/session_status_style.dart';

void main() {
  group('SessionStatusColor', () {
    test('confirmed and inProgress are never the same hue — the bug Ben '
        'found (confirmed blue on some screens, green on others)', () {
      expect(SessionStatus.confirmed.color, isNot(SessionStatus.inProgress.color));
    });

    test('maps every status to the canonical color used across the app', () {
      expect(SessionStatus.pending.color, Colors.orange);
      expect(SessionStatus.confirmed.color, Colors.blue);
      expect(SessionStatus.inProgress.color, Colors.green);
      expect(SessionStatus.completed.color, Colors.grey);
      expect(SessionStatus.cancelled.color, Colors.red);
      expect(SessionStatus.noShow.color, Colors.red);
    });
  });
}
