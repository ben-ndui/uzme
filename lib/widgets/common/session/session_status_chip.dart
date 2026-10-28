import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uzme/core/models/models_exports.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/widgets/common/session/session_status_style.dart';

/// A colored chip displaying session status
class SessionStatusChip extends StatelessWidget {
  final SessionStatus status;
  final PaymentStatus? paymentStatus;
  final AppLocalizations l10n;

  const SessionStatusChip({
    super.key,
    required this.status,
    required this.l10n,
    this.paymentStatus,
  });

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = _resolve();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: 10, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  (Color, FaIconData, String) _resolve() {
    // When confirmed but deposit not yet paid, show "Awaiting payment"
    if (status == SessionStatus.confirmed &&
        paymentStatus == PaymentStatus.depositPending) {
      return (
        Colors.orange,
        FontAwesomeIcons.moneyBill,
        l10n.paymentStatusDepositPending,
      );
    }

    return switch (status) {
      SessionStatus.pending => (status.color, FontAwesomeIcons.hourglass, l10n.waitingStatus),
      SessionStatus.confirmed => (status.color, FontAwesomeIcons.circleCheck, l10n.confirmedStatus),
      SessionStatus.inProgress => (status.color, FontAwesomeIcons.play, l10n.inProgressStatus),
      SessionStatus.completed => (status.color, FontAwesomeIcons.check, l10n.completedStatus),
      SessionStatus.cancelled => (status.color, FontAwesomeIcons.xmark, l10n.cancelledStatus),
      SessionStatus.noShow => (status.color, FontAwesomeIcons.userXmark, l10n.noShowStatus),
    };
  }
}
