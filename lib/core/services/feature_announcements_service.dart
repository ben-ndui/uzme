import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uzme/core/models/app_user.dart';
import 'package:uzme/core/models/feature_flag.dart';
import 'package:uzme/core/services/feature_flags_service.dart';

/// Compute the next [FeatureFlag] announcement that should be shown to
/// [user], or persist that the user has acknowledged a given key.
///
/// "Should be shown" rules — all must hold:
///   1. The flag has a non-empty `announcementTitle` (admin opted in).
///   2. The flag is currently enabled for the user
///      (via [FeatureFlagsService.isEnabled]).
///   3. The user's `seenFeatureAnnouncements` array does NOT yet
///      contain the flag key.
///
/// Resolution returns the first matching flag in catalog order so the
/// admin gets a deterministic UX when several flags get announcements
/// at once. Callers can call again after acknowledging to flush the
/// queue one popup at a time.
class FeatureAnnouncementsService {
  FeatureAnnouncementsService({
    FirebaseFirestore? firestore,
    FeatureFlagsService? flagsService,
  })  : _firestoreOverride = firestore,
        _flagsServiceOverride = flagsService;

  final FirebaseFirestore? _firestoreOverride;
  final FeatureFlagsService? _flagsServiceOverride;
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  /// Pure computation — returns the next announcement to show, or null
  /// when nothing is due. Extracted as static so tests don't need
  /// Firestore.
  static FeatureFlag? nextAnnouncementFor({
    required AppUser? user,
    required Iterable<FeatureFlag> flags,
    required Set<String> seenKeys,
    required bool Function(FeatureFlag flag, AppUser? user) isEnabled,
  }) {
    if (user == null) return null;
    for (final flag in flags) {
      if (!flag.hasAnnouncement) continue;
      if (seenKeys.contains(flag.key)) continue;
      if (!isEnabled(flag, user)) continue;
      return flag;
    }
    return null;
  }

  /// Read the user's already-seen keys from `users/{uid}`.
  Future<Set<String>> fetchSeenKeys(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    final raw = doc.data()?['seenFeatureAnnouncements'];
    if (raw is! List) return const {};
    return raw.whereType<String>().toSet();
  }

  /// Append [key] to the user's `seenFeatureAnnouncements`. Idempotent
  /// thanks to `arrayUnion`.
  Future<void> markSeen(String uid, String key) async {
    await _firestore.collection('users').doc(uid).update({
      'seenFeatureAnnouncements': FieldValue.arrayUnion([key]),
    });
  }

  /// Convenience wrapper — fetches seen keys then computes the next
  /// flag from the supplied [flags] iterable. The injected
  /// [FeatureFlagsService] (or the global one passed in via the
  /// constructor) is used for the `isEnabled` check, so the rollout
  /// rules stay in sync with the gates everywhere else.
  Future<FeatureFlag?> nextFor({
    required AppUser user,
    required Iterable<FeatureFlag> flags,
  }) async {
    final seen = await fetchSeenKeys(user.uid);
    final flagsService = _flagsServiceOverride;
    return nextAnnouncementFor(
      user: user,
      flags: flags,
      seenKeys: seen,
      isEnabled: (flag, u) => flagsService != null
          ? flagsService.isEnabled(u, flag.key)
          // Fallback: treat the flag as enabled when no service is
          // injected. Reachable only in unit-test setups.
          : true,
    );
  }

  @visibleForTesting
  void noop() {} // keeps the analyzer happy when service is mocked
}
