import 'package:flutter_test/flutter_test.dart';
import 'package:uzme/core/services/role_switch_service.dart';

void main() {
  group('RoleSwitchBlockReason.fromKey', () {
    // Locks the wire format expected from the smoothbackend callable.
    // If the backend ever renames a key, this test fails BEFORE the
    // Flutter UI silently shows a generic "unknown" reason.
    test('maps known backend keys to the correct enum', () {
      expect(
        RoleSwitchBlockReason.fromKey('upcoming_sessions'),
        RoleSwitchBlockReason.upcomingSessions,
      );
      expect(
        RoleSwitchBlockReason.fromKey('active_services'),
        RoleSwitchBlockReason.activeServices,
      );
      expect(
        RoleSwitchBlockReason.fromKey('pending_team_invitations'),
        RoleSwitchBlockReason.pendingTeamInvitations,
      );
    });

    test('falls back to `unknown` for unmapped keys', () {
      expect(
        RoleSwitchBlockReason.fromKey('mystery_reason'),
        RoleSwitchBlockReason.unknown,
      );
      expect(
        RoleSwitchBlockReason.fromKey(''),
        RoleSwitchBlockReason.unknown,
      );
    });
  });

  group('RoleSwitchResult', () {
    test('blocked result carries reasons and counts', () {
      const result = RoleSwitchResult(
        blocked: true,
        reasons: [
          RoleSwitchBlockReason.upcomingSessions,
          RoleSwitchBlockReason.activeServices,
        ],
        counts: {'upcomingSessions': 3, 'activeServices': 2},
      );
      expect(result.blocked, isTrue);
      expect(result.newRole, isNull);
      expect(result.reasons.length, 2);
      expect(result.counts['upcomingSessions'], 3);
    });
  });
}
