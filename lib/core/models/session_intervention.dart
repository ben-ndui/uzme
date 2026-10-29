import 'package:cloud_firestore/cloud_firestore.dart';

/// Session intervention data (check-in, photos, notes)
class SessionIntervention {
  final DateTime? checkinTime;
  final DateTime? checkoutTime;
  final List<String> photos;
  final String? notes;

  const SessionIntervention({
    this.checkinTime,
    this.checkoutTime,
    this.photos = const [],
    this.notes,
  });

  factory SessionIntervention.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const SessionIntervention();
    return SessionIntervention(
      checkinTime: _parseDateTime(map['checkinTime']),
      checkoutTime: _parseDateTime(map['checkoutTime']),
      photos: List<String>.from(map['photos'] ?? []),
      notes: map['notes']?.toString(),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  Map<String, dynamic> toMap() => {
        'checkinTime': checkinTime?.millisecondsSinceEpoch,
        'checkoutTime': checkoutTime?.millisecondsSinceEpoch,
        'photos': photos,
        'notes': notes,
      };

  SessionIntervention copyWith({
    DateTime? checkinTime,
    DateTime? checkoutTime,
    List<String>? photos,
    String? notes,
  }) =>
      SessionIntervention(
        checkinTime: checkinTime ?? this.checkinTime,
        checkoutTime: checkoutTime ?? this.checkoutTime,
        photos: photos ?? this.photos,
        notes: notes ?? this.notes,
      );

  bool get hasCheckedIn => checkinTime != null;
  bool get hasCheckedOut => checkoutTime != null;
}
