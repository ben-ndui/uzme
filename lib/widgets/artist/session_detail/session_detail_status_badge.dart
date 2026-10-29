import 'package:flutter/material.dart';
import 'package:uzme/core/models/models_exports.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/widgets/common/session/session_status_style.dart';

/// Pastille de statut en tête de l'écran de détail de session.
class SessionDetailStatusBadge extends StatelessWidget {
  final SessionStatus status;
  final AppLocalizations l10n;

  const SessionDetailStatusBadge({super.key, required this.status, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    final label = _label();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  String _label() {
    return switch (status) {
      SessionStatus.pending => l10n.pendingStatus,
      SessionStatus.confirmed => l10n.confirmedStatus,
      SessionStatus.inProgress => l10n.inProgressStatus,
      SessionStatus.completed => l10n.completedStatus,
      SessionStatus.cancelled => l10n.cancelledStatus,
      SessionStatus.noShow => l10n.noShowStatus,
    };
  }
}
