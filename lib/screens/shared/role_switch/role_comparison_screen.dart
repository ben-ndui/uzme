import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:smoothandesign_package/smoothandesign.dart';
import 'package:uzme/core/models/app_user.dart';
import 'package:uzme/core/services/role_switch_service.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/routing/app_routes.dart';
import 'package:uzme/widgets/common/snackbar/app_snackbar.dart';
import 'package:uzme/widgets/role_switch/role_card.dart';
import 'package:uzme/widgets/role_switch/role_compare_modal.dart';
import 'package:uzme/widgets/role_switch/role_presentation.dart';
import 'package:uzme/widgets/role_switch/role_switch_dialogs.dart';

/// Screen accessible from Settings → "Comparateur de rôles". Shows the
/// 3 switchable role cards (current first), with a persistent CTA at
/// the bottom to open [RoleCompareModal] for a side-by-side table.
///
/// Tapping a card's "Devenir X" CTA opens a confirm dialog → if
/// confirmed, calls [RoleSwitchService.switchUserRole]. The result
/// drives the post-action UX:
///   - `blocked` → opens [RoleSwitchBlockedDialog] with reasons
///   - success → snackbar then `context.go('/splash')` so the splash
///     re-evaluates and routes to onboarding (because the callable
///     reset `isFirstTime: true`).
class RoleComparisonScreen extends StatefulWidget {
  const RoleComparisonScreen({super.key});

  @override
  State<RoleComparisonScreen> createState() => _RoleComparisonScreenState();
}

class _RoleComparisonScreenState extends State<RoleComparisonScreen> {
  final _service = RoleSwitchService();
  bool _switching = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final authState = context.watch<AuthBloc>().state;
    final currentRole = authState is AuthAuthenticatedState
        ? (authState.user as AppUser).role
        : BaseUserRole.client;

    // Sort: current role first (so the user instantly sees where they
    // are), then the other roles in canonical order. We only promote
    // `currentRole` to the top when it's actually one of the public
    // switchable roles — otherwise (superAdmin / user) we'd duplicate
    // a card via the safe-fallback in `RolePresentation.forRole`.
    final isSwitchable =
        RolePresentation.switchableRoles.contains(currentRole);
    final orderedRoles = isSwitchable
        ? [
            currentRole,
            ...RolePresentation.switchableRoles
                .where((r) => r != currentRole),
          ]
        : RolePresentation.switchableRoles;
    final presentations = orderedRoles
        .map((r) => RolePresentation.forRole(r, l10n))
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.roleSwitchScreenTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          _Header(l10n: l10n),
          const SizedBox(height: 16),
          for (final presentation in presentations) ...[
            RoleCard(
              presentation: presentation,
              isCurrent: presentation.role == currentRole,
              onSwitch: _switching
                  ? null
                  : () => _onSwitch(presentation, currentRole),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
      bottomSheet: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
          ),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const FaIcon(FontAwesomeIcons.tableColumns, size: 14),
              onPressed: () => RoleCompareModal.show(
                context: context,
                presentations: RolePresentation.switchableRoles
                    .map((r) => RolePresentation.forRole(r, l10n))
                    .toList(),
              ),
              label: Text(l10n.roleSwitchCompareCta),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onSwitch(
    RolePresentation target,
    BaseUserRole currentRole,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    final confirmed = await RoleSwitchConfirmDialog.show(
      context: context,
      target: target,
    );
    if (!confirmed || !mounted) return;

    setState(() => _switching = true);
    try {
      final result = await _service.switchUserRole(target.role);
      if (!mounted) return;

      if (result.blocked) {
        await RoleSwitchBlockedDialog.show(
          context: context,
          target: target,
          result: result,
          onSubmitRequest: () => _submitArchiveRequest(target.role, result),
        );
        return;
      }

      // Success — route through splash so the auth re-eval picks the
      // new role + isFirstTime → onboarding.
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result.restored
                ? l10n.roleSwitchSuccessRestored(target.title)
                : l10n.roleSwitchSuccessTitle(target.title),
          ),
        ),
      );
      router.go(AppRoutes.splash);
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(
        context,
        _humanizeError(e.toString(), l10n),
      );
    } finally {
      if (mounted) setState(() => _switching = false);
    }
  }

  Future<bool> _submitArchiveRequest(
    BaseUserRole targetRole,
    RoleSwitchResult result,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _service.requestRoleSwitchArchive(
        targetRole: targetRole,
        reasons: result.reasons,
      );
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.roleSwitchBlockedRequestSent)),
      );
      return true;
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.roleSwitchGenericError(e.toString()))),
      );
      return false;
    }
  }

  String _humanizeError(String raw, AppLocalizations l10n) {
    if (raw.contains('resource-exhausted')) {
      return l10n.roleSwitchAnnualLimitReached;
    }
    return l10n.roleSwitchGenericError(raw);
  }
}

class _Header extends StatelessWidget {
  final AppLocalizations l10n;
  const _Header({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      l10n.roleSwitchHeaderIntro,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        height: 1.45,
      ),
    );
  }
}
