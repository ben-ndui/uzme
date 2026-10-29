// ignore_for_file: deprecated_member_use_from_same_package
// The deprecated 'type' field is intentionally used for backward compatibility with Firestore

export 'session_type.dart';
export 'session_status.dart';
export 'session_intervention.dart';
export 'session_mapping.dart';
export 'session_computed.dart';

import 'session_intervention.dart';
import 'session_mapping.dart';
import 'session_status.dart';
import 'session_type.dart';

/// Session model for studio bookings and pro service bookings.
///
/// `fromMap`/`toMap`/`copyWith` vivent dans `session_mapping.dart`, les
/// getters calculés dans `session_computed.dart` (charte readability.md,
/// 250 lignes max : la classe seule dépassait déjà 770 lignes).
class Session {
  final String id;
  final String studioId;

  /// Dénormalisés à la création : évitent un fetch par carte/écran pour
  /// savoir où a lieu la session (relevé par Ben le 29/10/2026 : la carte et
  /// l'écran de détail n'affichaient que le type, la date et l'heure, aucune
  /// information sur le studio).
  final String? studioName;
  final String? studioAddress;

  final String? roomId;
  final String? roomName;

  /// Pro freelance booking: ID and name of the pro being booked.
  /// When set, this is a pro service session (not a studio session).
  final String? proId;
  final String? proName;

  /// Ingénieur principal (rétro-compatibilité single engineer)
  final String? engineerId;
  final String? engineerName;

  /// Multi-ingénieurs : liste des ingénieurs assignés à la session
  final List<String> engineerIds;
  final List<String> engineerNames;

  /// Ingénieurs à qui la session a été proposée (en attente de réponse)
  final List<String> proposedEngineerIds;

  /// Liste des IDs d'artistes participant à la session.
  final List<String> artistIds;

  /// Liste des noms d'artistes (pour affichage sans fetch).
  final List<String> artistNames;

  /// Types de session multiples (enregistrement, mix, mastering, etc.)
  /// Permet les combinaisons comme "Enregistrement + Mix + Mastering"
  final List<SessionType> types;

  /// Type principal (rétro-compatibilité avec l'ancien format single type)
  @Deprecated('Use types instead')
  final SessionType type;

  final SessionStatus status;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  final int durationMinutes;
  final String? notes;
  final SessionIntervention intervention;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Payment tracking
  final PaymentStatus paymentStatus;
  final double? totalAmount;
  final double? depositAmount;
  final String? paymentMethodLabel;
  final DateTime? depositPaidAt;
  final DateTime? fullyPaidAt;
  final String? stripePaymentIntentId;
  final String? stripeDepositIntentId;

  // Cancellation tracking
  final String? cancellationReason;
  final String? cancelledBy;
  final double? refundAmount;
  final RefundStatus refundStatus;

  Session({
    required this.id,
    required this.studioId,
    this.studioName,
    this.studioAddress,
    this.roomId,
    this.roomName,
    this.proId,
    this.proName,
    this.engineerId,
    this.engineerName,
    this.engineerIds = const [],
    this.engineerNames = const [],
    this.proposedEngineerIds = const [],
    required this.artistIds,
    required this.artistNames,
    List<SessionType>? types,
    SessionType? type,
    this.status = SessionStatus.pending,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.durationMinutes,
    this.notes,
    SessionIntervention? intervention,
    required this.createdAt,
    this.updatedAt,
    this.paymentStatus = PaymentStatus.none,
    this.totalAmount,
    this.depositAmount,
    this.paymentMethodLabel,
    this.depositPaidAt,
    this.fullyPaidAt,
    this.stripePaymentIntentId,
    this.stripeDepositIntentId,
    this.cancellationReason,
    this.cancelledBy,
    this.refundAmount,
    this.refundStatus = RefundStatus.none,
  })  : types = types ?? (type != null ? [type] : [SessionType.other]),
        type = type ?? (types?.isNotEmpty == true ? types!.first : SessionType.other),
        intervention = intervention ?? const SessionIntervention();

  /// Constructeur pratique pour un seul artiste.
  factory Session.single({
    required String id,
    required String studioId,
    String? studioName,
    String? studioAddress,
    String? roomId,
    String? roomName,
    String? proId,
    String? proName,
    String? engineerId,
    String? engineerName,
    List<String> engineerIds = const [],
    List<String> engineerNames = const [],
    List<String> proposedEngineerIds = const [],
    required String artistId,
    required String artistName,
    List<SessionType>? types,
    SessionType? type,
    SessionStatus status = SessionStatus.pending,
    required DateTime scheduledStart,
    required DateTime scheduledEnd,
    required int durationMinutes,
    String? notes,
    SessionIntervention? intervention,
    required DateTime createdAt,
    DateTime? updatedAt,
    PaymentStatus paymentStatus = PaymentStatus.none,
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
    RefundStatus refundStatus = RefundStatus.none,
  }) {
    return Session(
      id: id,
      studioId: studioId,
      studioName: studioName,
      studioAddress: studioAddress,
      roomId: roomId,
      roomName: roomName,
      proId: proId,
      proName: proName,
      engineerId: engineerId,
      engineerName: engineerName,
      engineerIds: engineerIds,
      engineerNames: engineerNames,
      proposedEngineerIds: proposedEngineerIds,
      artistIds: [artistId],
      artistNames: [artistName],
      types: types,
      type: type,
      status: status,
      scheduledStart: scheduledStart,
      scheduledEnd: scheduledEnd,
      durationMinutes: durationMinutes,
      notes: notes,
      intervention: intervention,
      createdAt: createdAt,
      updatedAt: updatedAt,
      paymentStatus: paymentStatus,
      totalAmount: totalAmount,
      depositAmount: depositAmount,
      paymentMethodLabel: paymentMethodLabel,
      depositPaidAt: depositPaidAt,
      fullyPaidAt: fullyPaidAt,
      stripePaymentIntentId: stripePaymentIntentId,
      stripeDepositIntentId: stripeDepositIntentId,
      cancellationReason: cancellationReason,
      cancelledBy: cancelledBy,
      refundAmount: refundAmount,
      refundStatus: refundStatus,
    );
  }

  factory Session.fromMap(Map<String, dynamic> map) => sessionFromMap(map);
}
