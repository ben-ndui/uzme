/// Payment tracking status for session deposits and full payments.
enum PaymentStatus {
  none,
  depositPending,
  depositPaid,
  fullyPaid,
}

/// Refund status after cancellation.
enum RefundStatus {
  none,
  pending,
  partial,
  full,
  failed,
}

extension RefundStatusExtension on RefundStatus {
  static RefundStatus fromString(String? value) {
    switch (value) {
      case 'pending':
        return RefundStatus.pending;
      case 'partial':
        return RefundStatus.partial;
      case 'full':
        return RefundStatus.full;
      case 'failed':
        return RefundStatus.failed;
      default:
        return RefundStatus.none;
    }
  }
}

extension PaymentStatusExtension on PaymentStatus {
  static PaymentStatus fromString(String? value) {
    switch (value) {
      case 'depositPending':
        return PaymentStatus.depositPending;
      case 'depositPaid':
        return PaymentStatus.depositPaid;
      case 'fullyPaid':
        return PaymentStatus.fullyPaid;
      default:
        return PaymentStatus.none;
    }
  }
}

/// Session status enum
enum SessionStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled,
  noShow,
}

extension SessionStatusExtension on SessionStatus {
  String get label {
    switch (this) {
      case SessionStatus.pending:
        return 'En attente';
      case SessionStatus.confirmed:
        return 'Confirmée';
      case SessionStatus.inProgress:
        return 'En cours';
      case SessionStatus.completed:
        return 'Terminée';
      case SessionStatus.cancelled:
        return 'Annulée';
      case SessionStatus.noShow:
        return 'Absent';
    }
  }

  static SessionStatus fromString(String? value) {
    switch (value) {
      case 'confirmed':
        return SessionStatus.confirmed;
      case 'inProgress':
        return SessionStatus.inProgress;
      case 'completed':
        return SessionStatus.completed;
      case 'cancelled':
        return SessionStatus.cancelled;
      case 'noShow':
        return SessionStatus.noShow;
      default:
        return SessionStatus.pending;
    }
  }
}
