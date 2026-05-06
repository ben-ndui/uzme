import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uzme/core/services/role_switch_service.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/widgets/role_switch/role_presentation.dart';

/// Confirmation dialog shown before calling `switchUserRole`. Returns
/// `true` if the user clicks "Confirm".
class RoleSwitchConfirmDialog {
  static Future<bool> show({
    required BuildContext context,
    required RolePresentation target,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: target.accentColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: FaIcon(target.icon, size: 24, color: target.accentColor),
          ),
        ),
        title: Text(
          l10n.roleSwitchConfirmTitle(target.title),
          textAlign: TextAlign.center,
        ),
        content: Text(
          l10n.roleSwitchConfirmBody,
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.roleSwitchConfirmCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: target.accentColor,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.roleSwitchConfirmCta),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

/// Blocked dialog shown when [RoleSwitchService.switchUserRole] returns
/// `blocked: true`. Lists the blocking conditions and offers to send
/// an admin archive request via [RoleSwitchService.requestRoleSwitchArchive].
///
/// Returns the action taken so the caller can finalise (snackbar etc.):
///   - `RoleSwitchBlockedAction.requested` — user submitted the request
///   - `RoleSwitchBlockedAction.dismissed` — user closed without action
class RoleSwitchBlockedDialog {
  static Future<RoleSwitchBlockedAction> show({
    required BuildContext context,
    required RolePresentation target,
    required RoleSwitchResult result,
    required Future<bool> Function() onSubmitRequest,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final action = await showDialog<RoleSwitchBlockedAction>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const FaIcon(
          FontAwesomeIcons.triangleExclamation,
          color: Color(0xFFF59E0B),
          size: 32,
        ),
        title: Text(l10n.roleSwitchBlockedTitle, textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.roleSwitchBlockedIntro),
            const SizedBox(height: 12),
            ...result.reasons
                .map((r) => _ReasonRow(reason: r, counts: result.counts)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(RoleSwitchBlockedAction.dismissed),
            child: Text(l10n.roleSwitchBlockedDismissCta),
          ),
          FilledButton.icon(
            icon: const FaIcon(FontAwesomeIcons.paperPlane, size: 14),
            onPressed: () async {
              final ok = await onSubmitRequest();
              if (ctx.mounted) {
                Navigator.of(ctx).pop(
                  ok
                      ? RoleSwitchBlockedAction.requested
                      : RoleSwitchBlockedAction.dismissed,
                );
              }
            },
            label: Text(l10n.roleSwitchBlockedRequestCta),
          ),
        ],
      ),
    );
    return action ?? RoleSwitchBlockedAction.dismissed;
  }
}

enum RoleSwitchBlockedAction { requested, dismissed }

class _ReasonRow extends StatelessWidget {
  final RoleSwitchBlockReason reason;
  final Map<String, int> counts;
  const _ReasonRow({required this.reason, required this.counts});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final (label, count) = _resolve(l10n);
    if (label == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: theme.colorScheme.error,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          if (count != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  (String?, int?) _resolve(AppLocalizations l10n) {
    switch (reason) {
      case RoleSwitchBlockReason.upcomingSessions:
        final c = counts['upcomingSessions'] ?? 0;
        return (l10n.roleSwitchBlockedReasonUpcomingSessions(c), c);
      case RoleSwitchBlockReason.activeServices:
        final c = counts['activeServices'] ?? 0;
        return (l10n.roleSwitchBlockedReasonActiveServices(c), c);
      case RoleSwitchBlockReason.pendingTeamInvitations:
        final c = counts['pendingTeamInvitations'] ?? 0;
        return (l10n.roleSwitchBlockedReasonInvitations(c), c);
      case RoleSwitchBlockReason.unknown:
        return (null, null);
    }
  }
}
