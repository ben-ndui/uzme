import 'package:flutter/material.dart';
import 'package:uzme/core/models/models_exports.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/widgets/common/session/session_status_style.dart';

/// A status badge widget for sessions in dashboards
class DashboardStatusBadge extends StatelessWidget {
  final SessionStatus status;
  final AppLocalizations l10n;

  const DashboardStatusBadge({
    super.key,
    required this.status,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    final label = switch (status) {
      SessionStatus.pending => l10n.waitingStatus,
      SessionStatus.confirmed => l10n.confirmedStatus,
      SessionStatus.inProgress => l10n.inProgressStatus,
      SessionStatus.completed => l10n.completedStatus,
      SessionStatus.cancelled => l10n.cancelledStatus,
      SessionStatus.noShow => l10n.noShowStatus,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
