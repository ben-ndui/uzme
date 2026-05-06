import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:smoothandesign_package/smoothandesign.dart';

enum RoleSwitchRequestStatus {
  pending,
  approved,
  rejected;

  static RoleSwitchRequestStatus fromString(String? raw) {
    switch (raw) {
      case 'approved':
        return RoleSwitchRequestStatus.approved;
      case 'rejected':
        return RoleSwitchRequestStatus.rejected;
      default:
        return RoleSwitchRequestStatus.pending;
    }
  }
}

/// Doc in `role_switch_requests/{id}`. Created by users via the
/// `requestRoleSwitchArchive` callable when blocked, processed by
/// admins from the role-switch dashboard (Phase E5).
class RoleSwitchRequest extends Equatable {
  final String id;
  final String userId;
  final BaseUserRole? fromRole;
  final BaseUserRole targetRole;
  final List<String> reasons;
  final RoleSwitchRequestStatus status;
  final String? rejectedReason;
  final int? archivedDocsCount;
  final DateTime? createdAt;
  final DateTime? processedAt;
  final String? processedBy;

  const RoleSwitchRequest({
    required this.id,
    required this.userId,
    required this.targetRole,
    required this.status,
    this.fromRole,
    this.reasons = const [],
    this.rejectedReason,
    this.archivedDocsCount,
    this.createdAt,
    this.processedAt,
    this.processedBy,
  });

  factory RoleSwitchRequest.fromMap(Map<String, dynamic> map, String id) {
    return RoleSwitchRequest(
      id: id,
      userId: (map['userId'] ?? '').toString(),
      fromRole: _roleFromKey(map['fromRole']?.toString()),
      targetRole: _roleFromKey(map['targetRole']?.toString()) ??
          BaseUserRole.client,
      reasons: List<String>.from(map['reasons'] ?? const []),
      status: RoleSwitchRequestStatus.fromString(map['status']?.toString()),
      rejectedReason: map['rejectedReason']?.toString(),
      archivedDocsCount: map['archivedDocsCount'] is num
          ? (map['archivedDocsCount'] as num).toInt()
          : null,
      createdAt: _parseDate(map['createdAt']),
      processedAt: _parseDate(map['processedAt']),
      processedBy: map['processedBy']?.toString(),
    );
  }

  static BaseUserRole? _roleFromKey(String? key) {
    if (key == null) return null;
    for (final r in BaseUserRole.values) {
      if (r.name == key) return r;
    }
    return null;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        fromRole,
        targetRole,
        reasons,
        status,
        rejectedReason,
        archivedDocsCount,
        createdAt,
        processedAt,
        processedBy,
      ];
}
