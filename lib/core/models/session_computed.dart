import 'session.dart';

/// Propriétés calculées de [Session]. Séparées de `session.dart` pour rester
/// sous la limite de 250 lignes (charte readability.md).
extension SessionComputedX on Session {
  /// Whether this is a pro service booking (vs studio session).
  bool get isProSession => proId != null && proId!.isNotEmpty;

  bool get hasRoom => roomId != null;

  /// Vérifie si au moins un ingénieur est assigné (single ou multi)
  bool get hasEngineer => engineerId != null || engineerIds.isNotEmpty;

  /// Vérifie si des ingénieurs ont été proposés mais pas encore assignés
  bool get hasPendingProposals => proposedEngineerIds.isNotEmpty;

  /// Vérifie si la session a plusieurs ingénieurs assignés
  bool get hasMultipleEngineers => engineerIds.length > 1;

  /// Nombre d'ingénieurs assignés
  int get engineerCount => engineerIds.isNotEmpty ? engineerIds.length : (engineerId != null ? 1 : 0);

  bool get hasArtists => artistIds.isNotEmpty;
  bool get hasMultipleArtists => artistIds.length > 1;
  int get artistCount => artistIds.length;

  bool get isPending => status == SessionStatus.pending;
  bool get isConfirmed => status == SessionStatus.confirmed;
  bool get isInProgress => status == SessionStatus.inProgress;
  bool get isCompleted => status == SessionStatus.completed;
  bool get isCancelled => status == SessionStatus.cancelled;

  /// Vérifie si la session est passée (date de fin < maintenant)
  bool get isPast => scheduledEnd.isBefore(DateTime.now());

  /// Vérifie si la session est en cours (entre début et fin)
  bool get isCurrentlyHappening {
    final now = DateTime.now();
    return now.isAfter(scheduledStart) && now.isBefore(scheduledEnd);
  }

  /// Statut d'affichage calculé basé sur l'heure actuelle
  /// Prend en compte les sessions confirmées qui sont en cours ou passées
  SessionStatus get displayStatus {
    // Si déjà terminée, annulée ou noShow, garder le statut
    if (status == SessionStatus.completed ||
        status == SessionStatus.cancelled ||
        status == SessionStatus.noShow) {
      return status;
    }

    // Si confirmée et actuellement en cours → afficher "en cours"
    if (status == SessionStatus.confirmed && isCurrentlyHappening) {
      return SessionStatus.inProgress;
    }

    // Si confirmée/pending et passée → afficher "terminée"
    if ((status == SessionStatus.confirmed || status == SessionStatus.pending) && isPast) {
      return SessionStatus.completed;
    }

    // Sinon, garder le statut original
    return status;
  }

  /// Vérifie si la session peut être annulée (pas passée et pas déjà terminée/annulée)
  bool get canBeCancelled =>
      !isPast &&
      !isCurrentlyHappening &&
      status != SessionStatus.completed &&
      status != SessionStatus.cancelled &&
      status != SessionStatus.noShow;

  double get durationHours => durationMinutes / 60.0;

  /// Label combiné des types de session
  /// Ex: "Enregistrement + Mix + Mastering"
  String get typeLabel => SessionTypeExtension.combinedLabel(types);

  /// Vérifie si la session inclut un type spécifique
  bool hasType(SessionType t) => types.contains(t);

  /// Vérifie si c'est une session avec plusieurs types
  bool get hasMultipleTypes => types.length > 1;

  /// Nom d'affichage des artistes (séparés par ", " ou "& " pour le dernier).
  String get artistName {
    if (artistNames.isEmpty) return 'Artiste inconnu';
    if (artistNames.length == 1) return artistNames.first;
    if (artistNames.length == 2) return '${artistNames[0]} & ${artistNames[1]}';
    return '${artistNames.sublist(0, artistNames.length - 1).join(', ')} & ${artistNames.last}';
  }

  /// Nom d'affichage des ingénieurs (single ou multi)
  String get allEngineerNames {
    if (engineerNames.isNotEmpty) {
      if (engineerNames.length == 1) return engineerNames.first;
      if (engineerNames.length == 2) return '${engineerNames[0]} & ${engineerNames[1]}';
      return '${engineerNames.sublist(0, engineerNames.length - 1).join(', ')} & ${engineerNames.last}';
    }
    return engineerName ?? '';
  }

  /// Premier ID artiste (pour rétro-compatibilité).
  String get artistId => artistIds.isNotEmpty ? artistIds.first : '';

  /// Vérifie si un artiste participe à cette session.
  bool hasArtist(String artistId) => artistIds.contains(artistId);

  /// Vérifie si un ingénieur est assigné à cette session
  bool isEngineerAssigned(String engId) =>
      engineerId == engId || engineerIds.contains(engId);

  /// Vérifie si un ingénieur a reçu une proposition pour cette session
  bool isEngineerProposed(String engId) => proposedEngineerIds.contains(engId);

  /// Whether payment tracking is active (deposit was requested)
  bool get hasPaymentTracking => paymentStatus != PaymentStatus.none;

  /// Whether the deposit has been marked as received
  bool get isDepositPaid =>
      paymentStatus == PaymentStatus.depositPaid ||
      paymentStatus == PaymentStatus.fullyPaid;

  /// Whether the session is fully paid
  bool get isFullyPaid => paymentStatus == PaymentStatus.fullyPaid;

  /// Whether the session has a refund
  bool get hasRefund => refundStatus != RefundStatus.none;

  /// Whether an artist can pay the deposit via Stripe
  /// Only on confirmed sessions that haven't been cancelled
  bool get canPayDeposit =>
      paymentStatus == PaymentStatus.depositPending &&
      totalAmount != null &&
      depositAmount != null &&
      depositAmount! > 0 &&
      status == SessionStatus.confirmed &&
      status != SessionStatus.cancelled &&
      status != SessionStatus.noShow;

  /// Whether an artist can pay the remaining balance via Stripe
  /// Allowed even after session ends (debt), but not if cancelled/noShow
  bool get canPayRemaining =>
      paymentStatus == PaymentStatus.depositPaid &&
      !isFullyPaid &&
      totalAmount != null &&
      remainingAmount > 0 &&
      status != SessionStatus.cancelled &&
      status != SessionStatus.noShow;

  /// Remaining amount after deposit
  double get remainingAmount {
    if (totalAmount == null) return 0;
    if (isFullyPaid) return 0;
    if (isDepositPaid) return totalAmount! - (depositAmount ?? 0);
    return totalAmount!;
  }

  bool isOnDate(DateTime date) =>
      scheduledStart.year == date.year &&
      scheduledStart.month == date.month &&
      scheduledStart.day == date.day;
}
