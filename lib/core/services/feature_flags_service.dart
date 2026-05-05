import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:uzme/core/models/app_user.dart';
import 'package:uzme/core/models/feature_flag.dart';

/// Centralised feature flag resolver. Subscribes once to the
/// `feature_flags` collection and exposes both a synchronous `isEnabled`
/// (after first snapshot) and a Stream for live UI binding.
///
/// Usage from a feature surface :
/// ```dart
/// if (featureFlagsService.isEnabled(currentUser, 'auto_publish_insta')) {
///   showAutoPublishUI();
/// }
/// ```
///
/// Resolution rules per [FeatureRollout] :
/// - `disabled`  → false for everyone
/// - `enabled`   → true for everyone (still requires authenticated user
///                 to satisfy Firestore rules but no role check)
/// - `beta`      → true if `user.uid` is in `betaUserIds`
/// - `pioneer`   → true if `user.pioneer?.isPioneer == true`
///
/// Unknown / non-existent flag keys default to `false` (deny by default).
class FeatureFlagsService {
  FeatureFlagsService({FirebaseFirestore? firestore, FirebaseFunctions? functions})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  static const _collection = 'feature_flags';

  StreamSubscription? _subscription;
  Map<String, FeatureFlag> _flags = const {};
  final _streamController = StreamController<Map<String, FeatureFlag>>.broadcast();
  bool _initialised = false;

  /// Start listening to the flags collection. Idempotent — safe to call
  /// from main.dart at every app boot.
  void initialize() {
    if (_subscription != null) return;
    _subscription = _firestore
        .collection(_collection)
        .snapshots()
        .listen((snap) {
      _flags = {
        for (final doc in snap.docs)
          doc.id: FeatureFlag.fromMap(doc.data(), doc.id),
      };
      _initialised = true;
      _streamController.add(_flags);
    }, onError: (_) {
      // On error, keep _flags as-is. UI surfaces fall back to the rollout
      // state of the last cached snapshot, or the safe default of false.
    });
  }

  /// Tear down the subscription. Call from main.dart on logout / dispose.
  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    await _streamController.close();
  }

  /// Live stream of the full flag map. Useful for admin screens.
  Stream<Map<String, FeatureFlag>> watchAll() => _streamController.stream;

  /// Latest snapshot of all known flags.
  Map<String, FeatureFlag> get current => Map.unmodifiable(_flags);

  /// Whether the first snapshot has landed. UIs that need to gate on a
  /// flag at boot time should wait for [whenReady] before deciding.
  bool get isReady => _initialised;

  /// Future that completes the first time we receive a snapshot.
  Future<void> whenReady() async {
    if (_initialised) return;
    await _streamController.stream.first;
  }

  /// Synchronous resolution. Returns `false` if the service hasn't loaded
  /// its first snapshot yet — call [whenReady] beforehand if you need to
  /// gate on a feature at app launch.
  bool isEnabled(AppUser? user, String key) {
    final flag = _flags[key];
    if (flag == null) return false;
    switch (flag.rollout) {
      case FeatureRollout.disabled:
        return false;
      case FeatureRollout.enabled:
        return true;
      case FeatureRollout.beta:
        if (user == null) return false;
        return flag.betaUserIds.contains(user.uid);
      case FeatureRollout.pioneer:
        return user?.pioneer?.isPioneer == true;
    }
  }

  /// Async variant — waits for the first snapshot if needed.
  Future<bool> isEnabledAsync(AppUser? user, String key) async {
    if (!_initialised) await whenReady();
    return isEnabled(user, key);
  }

  // ===== Admin callables (superAdmin only — server enforces) =====

  /// Returns all flags including their full config (admin UI).
  Future<List<FeatureFlag>> listFlagsAdmin() async {
    final result = await _functions.httpsCallable('listFeatureFlags').call();
    final flags = (result.data as Map)['flags'] as List? ?? const [];
    return flags
        .whereType<Map>()
        .map((m) => FeatureFlag.fromMap(
              Map<String, dynamic>.from(m),
              (m['key'] ?? '').toString(),
            ))
        .toList();
  }

  /// Create-or-update a flag. The key is immutable once created.
  Future<void> upsertFlag({
    required String key,
    String title = '',
    String description = '',
    FeatureRollout rollout = FeatureRollout.disabled,
    List<String> betaUserIds = const [],
    Map<String, dynamic> metadata = const {},
  }) async {
    await _functions.httpsCallable('upsertFeatureFlag').call({
      'key': key,
      'title': title,
      'description': description,
      'rollout': rollout.key,
      'betaUserIds': betaUserIds,
      'metadata': metadata,
    });
  }

  /// Permanently delete a flag. Only safe when the code no longer
  /// references the key.
  Future<void> deleteFlag(String key) async {
    await _functions.httpsCallable('deleteFeatureFlag').call({'key': key});
  }
}
