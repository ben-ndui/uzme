import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:smoothandesign_package/smoothandesign.dart';
import 'package:uzme/core/models/role_switch_advice.dart';
import 'package:uzme/core/models/role_switch_request.dart';

/// Reasons returned by the [RoleSwitchService.switchUserRole] callable
/// when the user can't switch right now. Each maps to a localised
/// string + count in the UI dialog.
enum RoleSwitchBlockReason {
  upcomingSessions,
  activeServices,
  pendingTeamInvitations,
  unknown;

  static RoleSwitchBlockReason fromKey(String key) {
    switch (key) {
      case 'upcoming_sessions':
        return RoleSwitchBlockReason.upcomingSessions;
      case 'active_services':
        return RoleSwitchBlockReason.activeServices;
      case 'pending_team_invitations':
        return RoleSwitchBlockReason.pendingTeamInvitations;
      default:
        return RoleSwitchBlockReason.unknown;
    }
  }
}

/// Result of [RoleSwitchService.switchUserRole].
@immutable
class RoleSwitchResult {
  final bool blocked;
  final BaseUserRole? newRole;
  final bool restored;
  final List<RoleSwitchBlockReason> reasons;
  final Map<String, int> counts;

  const RoleSwitchResult({
    required this.blocked,
    this.newRole,
    this.restored = false,
    this.reasons = const [],
    this.counts = const {},
  });
}

/// Bridge to the smoothbackend `role-switch` module.
class RoleSwitchService {
  /// Lazy resolution: the constructor never touches Firebase, so the
  /// service can be instantiated in widget tests / DI graphs without
  /// `Firebase.initializeApp()` being called first.
  RoleSwitchService({FirebaseFunctions? functions})
      : _functionsOverride = functions;

  final FirebaseFunctions? _functionsOverride;
  FirebaseFunctions get _functions =>
      _functionsOverride ?? FirebaseFunctions.instance;

  /// Attempt to switch the current user to [targetRole]. The callable
  /// either performs the switch atomically (success) or returns
  /// `blocked: true` with the list of reasons preventing it. The UI
  /// then offers the user to send an archive request to admins via
  /// [requestRoleSwitchArchive].
  ///
  /// Throws on hard errors (annual limit reached, invalid role,
  /// already on that role, network).
  Future<RoleSwitchResult> switchUserRole(BaseUserRole targetRole) async {
    final result = await _functions
        .httpsCallable('switchUserRole')
        .call({'targetRole': _roleKey(targetRole)});
    final data = Map<String, dynamic>.from(result.data as Map);

    if (data['blocked'] == true) {
      final rawReasons = (data['reasons'] as List? ?? const [])
          .map((r) => RoleSwitchBlockReason.fromKey(r.toString()))
          .toList();
      final rawCounts = (data['counts'] as Map?) ?? const {};
      return RoleSwitchResult(
        blocked: true,
        reasons: rawReasons,
        counts: {
          for (final entry in rawCounts.entries)
            entry.key.toString(): (entry.value as num).toInt(),
        },
      );
    }

    return RoleSwitchResult(
      blocked: false,
      newRole: _roleFromKey(data['newRole']?.toString()),
      restored: data['restored'] == true,
    );
  }

  /// Submit an archive request when the user is blocked. Idempotent
  /// (server de-dups pending requests for same user/targetRole).
  Future<String> requestRoleSwitchArchive({
    required BaseUserRole targetRole,
    required List<RoleSwitchBlockReason> reasons,
  }) async {
    final result = await _functions
        .httpsCallable('requestRoleSwitchArchive')
        .call({
      'targetRole': _roleKey(targetRole),
      'reasons': reasons.map(_reasonKey).toList(),
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    return data['requestId'].toString();
  }

  // ===== Admin (superAdmin only — server enforces) =====

  /// Returns every role-switch request, optionally filtered by status.
  Future<List<RoleSwitchRequest>> listRequests({
    RoleSwitchRequestStatus? status,
  }) async {
    final result = await _functions
        .httpsCallable('listRoleSwitchRequests')
        .call({if (status != null) 'status': status.name});
    final data = Map<String, dynamic>.from(result.data as Map);
    final list = (data['requests'] as List? ?? const []).whereType<Map>();
    return list
        .map((m) => RoleSwitchRequest.fromMap(
              Map<String, dynamic>.from(m),
              (m['id'] ?? '').toString(),
            ))
        .toList();
  }

  /// Approves a pending request: archives the user's blocking docs +
  /// flips role + notifies user. Returns the count of archived docs.
  Future<int> approveRequest(String requestId) async {
    final result = await _functions
        .httpsCallable('approveRoleSwitchRequest')
        .call({'requestId': requestId});
    final data = Map<String, dynamic>.from(result.data as Map);
    return ((data['archivedDocsCount'] as num?) ?? 0).toInt();
  }

  /// Rejects a pending request with an optional reason. The user
  /// receives a notification.
  Future<void> rejectRequest(String requestId, {String reason = ''}) async {
    await _functions
        .httpsCallable('rejectRoleSwitchRequest')
        .call({'requestId': requestId, 'reason': reason});
  }

  /// Asks the AI advisor for a personalized role recommendation based
  /// on the calling user's activity. Server-side falls back to a
  /// deterministic heuristic if Claude fails, so this never throws on
  /// AI provider issues.
  Future<RoleSwitchAdvice> getAdvice() async {
    final result = await _functions.httpsCallable('getRoleSwitchAdvice').call();
    return RoleSwitchAdvice.fromMap(
      Map<String, dynamic>.from(result.data as Map),
    );
  }

  // Use enum.name to roundtrip — works for client/worker/admin/superAdmin/user.
  static String _roleKey(BaseUserRole role) => role.name;

  static BaseUserRole? _roleFromKey(String? key) {
    if (key == null) return null;
    for (final r in BaseUserRole.values) {
      if (r.name == key) return r;
    }
    return null;
  }

  static String _reasonKey(RoleSwitchBlockReason r) {
    switch (r) {
      case RoleSwitchBlockReason.upcomingSessions:
        return 'upcoming_sessions';
      case RoleSwitchBlockReason.activeServices:
        return 'active_services';
      case RoleSwitchBlockReason.pendingTeamInvitations:
        return 'pending_team_invitations';
      case RoleSwitchBlockReason.unknown:
        return 'unknown';
    }
  }
}
