import 'package:cloud_firestore/cloud_firestore.dart';
import 'session.dart';

/// Construit un [Session] depuis un document Firestore.
/// Séparé de `session.dart` pour rester sous la limite de 250 lignes
/// (charte readability.md) : `Session.fromMap` n'est qu'un délégué vers ici.
Session sessionFromMap(Map<String, dynamic> map) {
  // Rétro-compatibilité : si artistId/artistName existent (ancien format)
  List<String> artistIds;
  List<String> artistNames;

  if (map['artistIds'] != null) {
    artistIds = List<String>.from(map['artistIds']);
    artistNames = List<String>.from(map['artistNames'] ?? []);
  } else if (map['artistId'] != null) {
    // Ancien format single artist
    artistIds = [map['artistId']?.toString() ?? ''];
    artistNames = [map['artistName']?.toString() ?? ''];
  } else {
    artistIds = [];
    artistNames = [];
  }

  // Multi-ingénieurs : support nouveau format + rétro-compat
  List<String> engineerIds = List<String>.from(map['engineerIds'] ?? []);
  List<String> engineerNames = List<String>.from(map['engineerNames'] ?? []);
  List<String> proposedEngineerIds = List<String>.from(map['proposedEngineerIds'] ?? []);

  // Multi-types : support nouveau format + rétro-compat avec 'type' single
  List<SessionType> types;
  if (map['types'] != null && (map['types'] as List).isNotEmpty) {
    types = SessionTypeExtension.listFromStrings(map['types'] as List);
  } else {
    // Fallback sur l'ancien format single type
    types = [SessionTypeExtension.fromString(map['type']?.toString())];
  }

  return Session(
    id: map['id']?.toString() ?? '',
    studioId: map['studioId']?.toString() ?? '',
    studioName: map['studioName']?.toString(),
    studioAddress: map['studioAddress']?.toString(),
    roomId: map['roomId']?.toString(),
    roomName: map['roomName']?.toString(),
    proId: map['proId']?.toString(),
    proName: map['proName']?.toString(),
    engineerId: map['engineerId']?.toString(),
    engineerName: map['engineerName']?.toString(),
    engineerIds: engineerIds,
    engineerNames: engineerNames,
    proposedEngineerIds: proposedEngineerIds,
    artistIds: artistIds,
    artistNames: artistNames,
    types: types,
    status: SessionStatusExtension.fromString(map['status']?.toString()),
    scheduledStart: parseSessionDateTime(map['scheduledStart']) ?? DateTime.now(),
    scheduledEnd: parseSessionDateTime(map['scheduledEnd']) ?? DateTime.now(),
    durationMinutes: map['durationMinutes'] as int? ?? 60,
    notes: map['notes']?.toString(),
    intervention: SessionIntervention.fromMap(
        map['intervention'] as Map<String, dynamic>?),
    createdAt: parseSessionDateTime(map['createdAt']) ?? DateTime.now(),
    updatedAt: parseSessionDateTime(map['updatedAt']),
    paymentStatus: PaymentStatusExtension.fromString(map['paymentStatus']?.toString()),
    totalAmount: (map['totalAmount'] as num?)?.toDouble(),
    depositAmount: (map['depositAmount'] as num?)?.toDouble(),
    paymentMethodLabel: map['paymentMethodLabel']?.toString(),
    depositPaidAt: parseSessionDateTime(map['depositPaidAt']),
    fullyPaidAt: parseSessionDateTime(map['fullyPaidAt']),
    stripePaymentIntentId: map['stripePaymentIntentId']?.toString(),
    stripeDepositIntentId: map['stripeDepositIntentId']?.toString(),
    cancellationReason: map['cancellationReason']?.toString(),
    cancelledBy: map['cancelledBy']?.toString(),
    refundAmount: (map['refundAmount'] as num?)?.toDouble(),
    refundStatus: RefundStatusExtension.fromString(map['refundStatus']?.toString()),
  );
}

DateTime? parseSessionDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return null;
}

extension SessionMappingX on Session {
  Map<String, dynamic> toMap() => {
        'id': id,
        'studioId': studioId,
        'studioName': studioName,
        'studioAddress': studioAddress,
        'roomId': roomId,
        'roomName': roomName,
        'proId': proId,
        'proName': proName,
        'engineerId': engineerId,
        'engineerName': engineerName,
        'engineerIds': engineerIds,
        'engineerNames': engineerNames,
        'proposedEngineerIds': proposedEngineerIds,
        'artistIds': artistIds,
        'artistNames': artistNames,
        'types': types.map((t) => t.name).toList(),
        'type': type.name, // Rétro-compatibilité
        'status': status.name,
        'scheduledStart': scheduledStart.millisecondsSinceEpoch,
        'scheduledEnd': scheduledEnd.millisecondsSinceEpoch,
        'durationMinutes': durationMinutes,
        'notes': notes,
        'intervention': intervention.toMap(),
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt?.millisecondsSinceEpoch,
        'paymentStatus': paymentStatus.name,
        'totalAmount': totalAmount,
        'depositAmount': depositAmount,
        'paymentMethodLabel': paymentMethodLabel,
        'depositPaidAt': depositPaidAt?.millisecondsSinceEpoch,
        'fullyPaidAt': fullyPaidAt?.millisecondsSinceEpoch,
        'stripePaymentIntentId': stripePaymentIntentId,
        'stripeDepositIntentId': stripeDepositIntentId,
        'cancellationReason': cancellationReason,
        'cancelledBy': cancelledBy,
        'refundAmount': refundAmount,
        'refundStatus': refundStatus.name,
      };

  Session copyWith({
    String? id,
    String? studioId,
    String? studioName,
    String? studioAddress,
    String? roomId,
    String? roomName,
    String? proId,
    String? proName,
    String? engineerId,
    String? engineerName,
    List<String>? engineerIds,
    List<String>? engineerNames,
    List<String>? proposedEngineerIds,
    List<String>? artistIds,
    List<String>? artistNames,
    List<SessionType>? types,
    SessionType? type,
    SessionStatus? status,
    DateTime? scheduledStart,
    DateTime? scheduledEnd,
    int? durationMinutes,
    String? notes,
    SessionIntervention? intervention,
    DateTime? createdAt,
    DateTime? updatedAt,
    PaymentStatus? paymentStatus,
    double? totalAmount,
    double? depositAmount,
    String? paymentMethodLabel,
    DateTime? depositPaidAt,
    DateTime? fullyPaidAt,
    String? stripePaymentIntentId,
    String? stripeDepositIntentId,
    String? cancellationReason,
    String? cancelledBy,
    double? refundAmount,
    RefundStatus? refundStatus,
  }) =>
      Session(
        id: id ?? this.id,
        studioId: studioId ?? this.studioId,
        studioName: studioName ?? this.studioName,
        studioAddress: studioAddress ?? this.studioAddress,
        roomId: roomId ?? this.roomId,
        roomName: roomName ?? this.roomName,
        proId: proId ?? this.proId,
        proName: proName ?? this.proName,
        engineerId: engineerId ?? this.engineerId,
        engineerName: engineerName ?? this.engineerName,
        engineerIds: engineerIds ?? this.engineerIds,
        engineerNames: engineerNames ?? this.engineerNames,
        proposedEngineerIds: proposedEngineerIds ?? this.proposedEngineerIds,
        artistIds: artistIds ?? this.artistIds,
        artistNames: artistNames ?? this.artistNames,
        types: types ?? this.types,
        type: type,
        status: status ?? this.status,
        scheduledStart: scheduledStart ?? this.scheduledStart,
        scheduledEnd: scheduledEnd ?? this.scheduledEnd,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        notes: notes ?? this.notes,
        intervention: intervention ?? this.intervention,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        paymentStatus: paymentStatus ?? this.paymentStatus,
        totalAmount: totalAmount ?? this.totalAmount,
        depositAmount: depositAmount ?? this.depositAmount,
        paymentMethodLabel: paymentMethodLabel ?? this.paymentMethodLabel,
        depositPaidAt: depositPaidAt ?? this.depositPaidAt,
        fullyPaidAt: fullyPaidAt ?? this.fullyPaidAt,
        stripePaymentIntentId:
            stripePaymentIntentId ?? this.stripePaymentIntentId,
        stripeDepositIntentId:
            stripeDepositIntentId ?? this.stripeDepositIntentId,
        cancellationReason: cancellationReason ?? this.cancellationReason,
        cancelledBy: cancelledBy ?? this.cancelledBy,
        refundAmount: refundAmount ?? this.refundAmount,
        refundStatus: refundStatus ?? this.refundStatus,
      );
}
