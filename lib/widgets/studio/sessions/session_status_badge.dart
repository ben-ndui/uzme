import 'package:flutter/material.dart';
import 'package:uzme/core/models/session.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/widgets/common/session/session_status_style.dart';

/// Status badge for session cards
class SessionStatusBadge extends StatelessWidget {
  final SessionStatus status;

  const SessionStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = status.color;
    final label = _label(l10n);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  String _label(AppLocalizations l10n) {
    return switch (status) {
      SessionStatus.pending => l10n.waitingStatus,
      SessionStatus.confirmed => l10n.confirmedStatus,
      SessionStatus.inProgress => l10n.inProgressStatus,
      SessionStatus.completed => l10n.completedStatus,
      SessionStatus.cancelled => l10n.cancelledStatus,
      SessionStatus.noShow => l10n.noShowStatus,
    };
  }
}
