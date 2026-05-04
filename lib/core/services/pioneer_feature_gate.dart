import 'package:uzme/core/models/app_user.dart';
import 'package:uzme/main.dart' show featureFlagsService;

/// Backwards-compatible facade over [FeatureFlagsService] for callers
/// that were written against the original Pioneer-only check.
///
/// New code should call `featureFlagsService.isEnabled(user, key)`
/// directly — it covers Pioneer, beta lists, and global rollouts in one
/// shot. This class is kept so existing call sites compile unchanged.
class PioneerFeatureGate {
  PioneerFeatureGate._();

  /// True when the user is a Pioneer **and** the active feature flag for
  /// [featureKey] is set to `pioneer` rollout (or `enabled`, since that
  /// implies pioneers see it too).
  ///
  /// Returns false if no flag exists for that key (deny-by-default).
  static Future<bool> has({
    required AppUser? user,
    required String featureKey,
  }) async {
    if (user?.pioneer?.isPioneer != true) return false;
    return featureFlagsService.isEnabledAsync(user, featureKey);
  }

  /// Synchronous variant — assumes the FeatureFlagsService has already
  /// loaded its first snapshot. Safe in BlocBuilders / build methods.
  static bool hasSync({
    required AppUser? user,
    required String featureKey,
  }) {
    if (user?.pioneer?.isPioneer != true) return false;
    return featureFlagsService.isEnabled(user, featureKey);
  }

  /// No-op kept for source compatibility — the new
  /// [FeatureFlagsService] subscribes once and stays live, no manual
  /// reset is needed.
  static void reset() {}
}
