import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uzme/core/models/role_switch_request.dart';
import 'package:uzme/core/services/role_switch_service.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/widgets/common/app_loader.dart';
import 'package:uzme/widgets/common/snackbar/app_snackbar.dart';

/// SuperAdmin screen — list of role-switch requests with approve / reject
/// actions. Admin can filter by status. Approving soft-archives blocking
/// docs (sessions, services, invites) and flips the user's role.
class RoleSwitchRequestsScreen extends StatefulWidget {
  const RoleSwitchRequestsScreen({super.key});

  @override
  State<RoleSwitchRequestsScreen> createState() =>
      _RoleSwitchRequestsScreenState();
}

class _RoleSwitchRequestsScreenState extends State<RoleSwitchRequestsScreen> {
  final _service = RoleSwitchService();
  RoleSwitchRequestStatus? _filter = RoleSwitchRequestStatus.pending;
  Future<List<RoleSwitchRequest>>? _future;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    // Block body — arrow form returns the Future-typed assignment
    // value, which trips Flutter's setState assertion. See
    // whats_new_screen smoke-test fix for the canonical example.
    setState(() {
      _future = _service.listRequests(status: _filter);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminRoleSwitchRequestsTitle)),
      body: Column(
        children: [
          _FilterBar(
            current: _filter,
            onChanged: (s) {
              _filter = s;
              _refresh();
            },
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<RoleSwitchRequest>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: AppLoader());
                }
                final list = snap.data ?? const [];
                if (list.isEmpty) {
                  return _Empty(label: l10n.adminRoleSwitchEmpty);
                }
                return RefreshIndicator(
                  onRefresh: () async => _refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _RequestCard(
                      request: list[i],
                      onApprove: () => _approve(list[i]),
                      onReject: () => _reject(list[i]),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approve(RoleSwitchRequest req) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminRoleSwitchApproveConfirmTitle),
        content: Text(l10n.adminRoleSwitchApproveConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.roleSwitchConfirmCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.adminRoleSwitchApproveCta),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final count = await _service.approveRequest(req.id);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.adminRoleSwitchApproveSuccess(count))),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, e.toString());
    }
  }

  Future<void> _reject(RoleSwitchRequest req) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminRoleSwitchRejectConfirmTitle),
        content: TextField(
          controller: reasonController,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: l10n.adminRoleSwitchRejectReasonHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.roleSwitchConfirmCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.adminRoleSwitchRejectCta),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _service.rejectRequest(req.id, reason: reasonController.text.trim());
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.adminRoleSwitchRejectSuccess)),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, e.toString());
    }
  }
}

class _FilterBar extends StatelessWidget {
  final RoleSwitchRequestStatus? current;
  final ValueChanged<RoleSwitchRequestStatus?> onChanged;

  const _FilterBar({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _chip(label: l10n.adminRoleSwitchFilterAll, value: null),
          _chip(
            label: l10n.adminRoleSwitchFilterPending,
            value: RoleSwitchRequestStatus.pending,
          ),
          _chip(
            label: l10n.adminRoleSwitchFilterApproved,
            value: RoleSwitchRequestStatus.approved,
          ),
          _chip(
            label: l10n.adminRoleSwitchFilterRejected,
            value: RoleSwitchRequestStatus.rejected,
          ),
        ],
      ),
    );
  }

  Widget _chip({required String label, required RoleSwitchRequestStatus? value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: current == value,
        onSelected: (_) => onChanged(value),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final RoleSwitchRequest request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _RequestCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isPending = request.status == RoleSwitchRequestStatus.pending;
    final dateFmt = DateFormat('dd/MM HH:mm');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.adminRoleSwitchFromTo(
                      request.fromRole?.name ?? '?',
                      request.targetRole.name,
                    ),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _StatusChip(status: request.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.adminRoleSwitchUserPrefix(request.userId),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
                fontFamily: 'monospace',
              ),
            ),
            if (request.createdAt != null) ...[
              const SizedBox(height: 2),
              Text(
                dateFmt.format(request.createdAt!),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
            if (request.reasons.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                l10n.adminRoleSwitchReasonsLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: request.reasons
                    .map((r) => Chip(
                          label: Text(r, style: const TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ],
            if (request.rejectedReason != null &&
                request.rejectedReason!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                request.rejectedReason!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (isPending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const FaIcon(FontAwesomeIcons.xmark, size: 12),
                      label: Text(l10n.adminRoleSwitchRejectCta),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onApprove,
                      icon: const FaIcon(FontAwesomeIcons.check, size: 12),
                      label: Text(l10n.adminRoleSwitchApproveCta),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final RoleSwitchRequestStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (label, color) = switch (status) {
      RoleSwitchRequestStatus.pending => (
          l10n.adminRoleSwitchStatusPending,
          Colors.orange,
        ),
      RoleSwitchRequestStatus.approved => (
          l10n.adminRoleSwitchStatusApproved,
          Colors.green,
        ),
      RoleSwitchRequestStatus.rejected => (
          l10n.adminRoleSwitchStatusRejected,
          Colors.red,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String label;
  const _Empty({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              FontAwesomeIcons.inbox,
              size: 40,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
