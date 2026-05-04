import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Status of a Pioneer cohort. Distribution flow: draft → active →
/// distributed → archived.
enum PioneerProgramStatus {
  draft,
  active,
  distributed,
  archived;

  static PioneerProgramStatus fromString(String? raw) {
    switch (raw) {
      case 'active':
        return PioneerProgramStatus.active;
      case 'distributed':
        return PioneerProgramStatus.distributed;
      case 'archived':
        return PioneerProgramStatus.archived;
      case 'draft':
      default:
        return PioneerProgramStatus.draft;
    }
  }

  String get key => name;
}

/// Weights applied to each engagement counter when computing a user's score.
class PioneerWeights extends Equatable {
  final int confirmedSessions;
  final int messagesSent;
  final int activeDays;

  const PioneerWeights({
    this.confirmedSessions = 5,
    this.messagesSent = 1,
    this.activeDays = 2,
  });

  factory PioneerWeights.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const PioneerWeights();
    return PioneerWeights(
      confirmedSessions: (map['confirmedSessions'] as num?)?.toInt() ?? 5,
      messagesSent: (map['messagesSent'] as num?)?.toInt() ?? 1,
      activeDays: (map['activeDays'] as num?)?.toInt() ?? 2,
    );
  }

  Map<String, dynamic> toMap() => {
        'confirmedSessions': confirmedSessions,
        'messagesSent': messagesSent,
        'activeDays': activeDays,
      };

  @override
  List<Object?> get props => [confirmedSessions, messagesSent, activeDays];
}

/// Benefits granted to recipients of a Pioneer cohort. Each flag is
/// interpreted by the right surface in the app (badge UI, search ranking,
/// pin renderer, Stripe fees split, feature flag gate).
class PioneerBenefits extends Equatable {
  final bool visualBadge;
  final double discountPct;
  final List<String> earlyAccessFeatures;
  final bool searchBoost;
  final bool mapHighlight;

  const PioneerBenefits({
    this.visualBadge = true,
    this.discountPct = 0,
    this.earlyAccessFeatures = const [],
    this.searchBoost = true,
    this.mapHighlight = true,
  });

  factory PioneerBenefits.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const PioneerBenefits();
    return PioneerBenefits(
      visualBadge: map['visualBadge'] ?? true,
      discountPct: (map['discountPct'] as num?)?.toDouble() ?? 0,
      earlyAccessFeatures: List<String>.from(
        map['earlyAccessFeatures'] ?? const [],
      ),
      searchBoost: map['searchBoost'] ?? true,
      mapHighlight: map['mapHighlight'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'visualBadge': visualBadge,
        'discountPct': discountPct,
        'earlyAccessFeatures': earlyAccessFeatures,
        'searchBoost': searchBoost,
        'mapHighlight': mapHighlight,
      };

  @override
  List<Object?> get props => [
        visualBadge,
        discountPct,
        earlyAccessFeatures,
        searchBoost,
        mapHighlight,
      ];
}

/// A Pioneer cohort. Stored in Firestore at `pioneer_programs/{id}` and
/// managed by the smoothbackend `pioneer/` module.
class PioneerProgram extends Equatable {
  final String id;
  final PioneerProgramStatus status;
  final String name;
  final String description;
  final int targetCount;
  final DateTime deadline;
  final PioneerWeights weights;
  final PioneerBenefits benefits;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? distributedAt;
  final int? distributedCount;

  const PioneerProgram({
    required this.id,
    required this.status,
    required this.name,
    this.description = '',
    required this.targetCount,
    required this.deadline,
    this.weights = const PioneerWeights(),
    this.benefits = const PioneerBenefits(),
    this.createdBy,
    this.createdAt,
    this.distributedAt,
    this.distributedCount,
  });

  factory PioneerProgram.fromMap(Map<String, dynamic> map, String id) {
    return PioneerProgram(
      id: id,
      status: PioneerProgramStatus.fromString(map['status']),
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      targetCount: (map['targetCount'] as num?)?.toInt() ?? 0,
      deadline: _parseDate(map['deadline']) ?? DateTime.now(),
      weights: PioneerWeights.fromMap(
        map['weights'] as Map<String, dynamic>?,
      ),
      benefits: PioneerBenefits.fromMap(
        map['benefits'] as Map<String, dynamic>?,
      ),
      createdBy: map['createdBy'],
      createdAt: _parseDate(map['createdAt']),
      distributedAt: _parseDate(map['distributedAt']),
      distributedCount: (map['distributedCount'] as num?)?.toInt(),
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

  bool get isEditable =>
      status == PioneerProgramStatus.draft ||
      status == PioneerProgramStatus.active;

  @override
  List<Object?> get props => [
        id,
        status,
        name,
        description,
        targetCount,
        deadline,
        weights,
        benefits,
        createdBy,
        createdAt,
        distributedAt,
        distributedCount,
      ];
}

/// One row of a Pioneer program leaderboard preview / final recipients.
class PioneerLeaderboardEntry extends Equatable {
  final int rank;
  final String uid;
  final String name;
  final String role;
  final num score;
  final int confirmedSessions;
  final int messagesSent;
  final int activeDays;

  const PioneerLeaderboardEntry({
    required this.rank,
    required this.uid,
    required this.name,
    required this.role,
    required this.score,
    required this.confirmedSessions,
    required this.messagesSent,
    required this.activeDays,
  });

  factory PioneerLeaderboardEntry.fromMap(Map<String, dynamic> map) {
    final metrics = map['metrics'] as Map<String, dynamic>? ?? const {};
    return PioneerLeaderboardEntry(
      rank: (map['rank'] as num?)?.toInt() ?? 0,
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'user',
      score: map['score'] ?? 0,
      confirmedSessions:
          (metrics['confirmedSessions'] as num?)?.toInt() ?? 0,
      messagesSent: (metrics['messagesSent'] as num?)?.toInt() ?? 0,
      activeDays: (metrics['activeDays'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        rank,
        uid,
        name,
        role,
        score,
        confirmedSessions,
        messagesSent,
        activeDays,
      ];
}
