import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uzme/core/models/app_user.dart';
import 'package:uzme/core/models/pioneer_program.dart';

/// Resolves whether a Pioneer user has access to a given early-access
/// feature flag. The list of unlocked features lives in the active or
/// most-recently distributed program's `benefits.earlyAccessFeatures`
/// array — Pioneers from a distributed cohort keep their flags until the
/// cohort is archived or replaced.
///
/// Usage from a feature surface (e.g. auto-publish IG button) :
/// ```dart
/// final canAutoPublish = await PioneerFeatureGate.has(
///   user: currentUser,
///   featureKey: 'auto_publish_insta',
/// );
/// if (canAutoPublish) showAutoPublishUI();
/// ```
class PioneerFeatureGate {
  PioneerFeatureGate._();

  /// In-memory cache of the active program's earlyAccessFeatures —
  /// avoids hitting Firestore on every UI build. Invalidated by [reset].
  static List<String>? _cachedFeatures;

  /// Returns true if [user] is a Pioneer AND the active program grants
  /// [featureKey]. Returns false if the user isn't a Pioneer at all,
  /// regardless of the feature flag.
  static Future<bool> has({
    required AppUser? user,
    required String featureKey,
  }) async {
    if (user == null) return false;
    if (user.pioneer?.isPioneer != true) return false;
    final features = await _activeFeatures();
    return features.contains(featureKey);
  }

  /// Synchronous variant for callers that already loaded the program
  /// (e.g. inside a BlocBuilder that has both the user and the program
  /// in its state).
  static bool hasSync({
    required AppUser? user,
    required PioneerProgram? activeProgram,
    required String featureKey,
  }) {
    if (user?.pioneer?.isPioneer != true) return false;
    if (activeProgram == null) return false;
    return activeProgram.benefits.earlyAccessFeatures.contains(featureKey);
  }

  /// Drop the cached feature list so the next [has] call re-fetches the
  /// program. Call this when the admin distributes / archives a cohort
  /// from the same session.
  static void reset() {
    _cachedFeatures = null;
  }

  /// Fetch the earlyAccessFeatures list of the active (or distributed)
  /// program. We prefer 'active' first; if none, fall back to the most
  /// recent 'distributed' so already-granted Pioneers keep their flags.
  static Future<List<String>> _activeFeatures() async {
    final cached = _cachedFeatures;
    if (cached != null) return cached;
    try {
      final col = FirebaseFirestore.instance.collection('pioneer_programs');
      var snap = await col
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();
      if (snap.docs.isEmpty) {
        snap = await col
            .where('status', isEqualTo: 'distributed')
            .orderBy('distributedAt', descending: true)
            .limit(1)
            .get();
      }
      if (snap.docs.isEmpty) {
        _cachedFeatures = const [];
        return const [];
      }
      final data = snap.docs.first.data();
      final benefits = data['benefits'] as Map<String, dynamic>?;
      final list = (benefits?['earlyAccessFeatures'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[];
      _cachedFeatures = list;
      return list;
    } catch (_) {
      _cachedFeatures = const [];
      return const [];
    }
  }
}
