import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smoothandesign_package/smoothandesign.dart';
import 'package:uzme/core/models/role_switch_request.dart';

void main() {
  group('RoleSwitchRequestStatus.fromString', () {
    test('maps known wire values', () {
      expect(
        RoleSwitchRequestStatus.fromString('approved'),
        RoleSwitchRequestStatus.approved,
      );
      expect(
        RoleSwitchRequestStatus.fromString('rejected'),
        RoleSwitchRequestStatus.rejected,
      );
      expect(
        RoleSwitchRequestStatus.fromString('pending'),
        RoleSwitchRequestStatus.pending,
      );
    });

    test('falls back to pending for null / unknown', () {
      expect(
        RoleSwitchRequestStatus.fromString(null),
        RoleSwitchRequestStatus.pending,
      );
      expect(
        RoleSwitchRequestStatus.fromString('mystery'),
        RoleSwitchRequestStatus.pending,
      );
    });
  });

  group('RoleSwitchRequest.fromMap', () {
    test('parses a fully-populated approved request', () {
      final ts = Timestamp.fromMillisecondsSinceEpoch(1700000000000);
      final req = RoleSwitchRequest.fromMap({
        'userId': 'uid-123',
        'fromRole': 'admin',
        'targetRole': 'client',
        'reasons': ['upcoming_sessions', 'active_services'],
        'status': 'approved',
        'archivedDocsCount': 5,
        'createdAt': ts,
        'processedAt': ts,
        'processedBy': 'admin-uid',
      }, 'req-1');

      expect(req.id, 'req-1');
      expect(req.userId, 'uid-123');
      expect(req.fromRole, BaseUserRole.admin);
      expect(req.targetRole, BaseUserRole.client);
      expect(req.reasons.length, 2);
      expect(req.status, RoleSwitchRequestStatus.approved);
      expect(req.archivedDocsCount, 5);
      expect(req.processedBy, 'admin-uid');
    });

    test('handles missing optional fields gracefully', () {
      final req = RoleSwitchRequest.fromMap({
        'userId': 'u1',
        'targetRole': 'worker',
        'status': 'pending',
      }, 'req-2');

      expect(req.fromRole, isNull);
      expect(req.targetRole, BaseUserRole.worker);
      expect(req.reasons, isEmpty);
      expect(req.archivedDocsCount, isNull);
      expect(req.rejectedReason, isNull);
    });

    test('falls back to client when targetRole is unparseable', () {
      // Defensive — production server should never emit this, but the
      // model must not crash on bad data from a future schema change.
      final req = RoleSwitchRequest.fromMap({
        'userId': 'u1',
        'targetRole': 'martian',
        'status': 'pending',
      }, 'req-3');
      expect(req.targetRole, BaseUserRole.client);
    });
  });
}
