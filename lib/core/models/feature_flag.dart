import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Rollout state of a feature flag. Drives the FeatureFlags resolution.
enum FeatureRollout {
  /// Hidden from everyone. Use to ship code while keeping the surface dark.
  disabled,

  /// Visible to current Pioneers (`user.pioneer.isPioneer == true`).
  pioneer,

  /// Visible to a hand-picked list of users (`betaUserIds`). Useful for
  /// closed beta programs outside of Pioneer cohorts.
  beta,

  /// Visible to everyone. Default end state for graduated features.
  enabled;

  static FeatureRollout fromString(String? raw) {
    switch (raw) {
      case 'pioneer':
        return FeatureRollout.pioneer;
      case 'beta':
        return FeatureRollout.beta;
      case 'enabled':
        return FeatureRollout.enabled;
      case 'disabled':
      default:
        return FeatureRollout.disabled;
    }
  }

  String get key => name;

  String get label {
    switch (this) {
      case FeatureRollout.disabled:
        return 'Désactivé';
      case FeatureRollout.pioneer:
        return 'Pioneer';
      case FeatureRollout.beta:
        return 'Beta';
      case FeatureRollout.enabled:
        return 'Activé';
    }
  }
}

/// A feature flag describes one toggleable surface in the app. Stored in
/// Firestore at `feature_flags/{key}` and managed via the smoothbackend
/// `feature_flags/` callables (superAdmin only).
class FeatureFlag extends Equatable {
  /// Stable identifier the code checks against (e.g. 'auto_publish_insta').
  /// Snake_case + lowercase. Doc id in Firestore.
  final String key;

  /// Human-readable label shown in the admin UI.
  final String title;

  /// Optional longer description for the admin UI.
  final String description;

  /// Current rollout state.
  final FeatureRollout rollout;

  /// User uids granted access when [rollout] is `beta`. Ignored otherwise.
  final List<String> betaUserIds;

  /// Free-form admin metadata (category, iosMinVersion, releasedAt, etc.).
  final Map<String, dynamic> metadata;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? updatedBy;

  const FeatureFlag({
    required this.key,
    this.title = '',
    this.description = '',
    this.rollout = FeatureRollout.disabled,
    this.betaUserIds = const [],
    this.metadata = const {},
    this.createdAt,
    this.updatedAt,
    this.updatedBy,
  });

  factory FeatureFlag.fromMap(Map<String, dynamic> map, String key) {
    return FeatureFlag(
      key: key,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      rollout: FeatureRollout.fromString(map['rollout']),
      betaUserIds: List<String>.from(map['betaUserIds'] ?? const []),
      metadata: map['metadata'] is Map
          ? Map<String, dynamic>.from(map['metadata'])
          : const {},
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
      updatedBy: map['updatedBy'],
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String? get category {
    final v = metadata['category'];
    return v is String ? v : null;
  }

  @override
  List<Object?> get props => [
        key,
        title,
        description,
        rollout,
        betaUserIds,
        metadata,
        updatedAt,
      ];
}
