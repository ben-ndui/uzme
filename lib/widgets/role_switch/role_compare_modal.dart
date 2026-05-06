import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/widgets/role_switch/role_presentation.dart';

/// Side-by-side comparison of the 3 switchable roles, opened from
/// [RoleComparisonScreen]'s "Comparer" CTA. Renders as a draggable
/// bottom sheet so the user can resize.
class RoleCompareModal extends StatelessWidget {
  final List<RolePresentation> presentations;
  const RoleCompareModal({super.key, required this.presentations});

  static Future<void> show({
    required BuildContext context,
    required List<RolePresentation> presentations,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => RoleCompareModal(
          presentations: presentations,
        )._wrapWithScroll(controller),
      ),
    );
  }

  Widget _wrapWithScroll(ScrollController controller) {
    return SingleChildScrollView(
      controller: controller,
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.roleSwitchCompareModalTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          // Header row with role icons
          _buildHeaderRow(theme),
          const Divider(height: 24),
          _buildRow(
            theme,
            label: l10n.roleCompareColAudience,
            getter: (p) => p.compareAudience,
          ),
          const Divider(height: 16),
          _buildRow(
            theme,
            label: l10n.roleCompareColPricing,
            getter: (p) => p.comparePricing,
          ),
          const Divider(height: 16),
          _buildRow(
            theme,
            label: l10n.roleCompareColTools,
            getter: (p) => p.compareTools,
          ),
          const Divider(height: 16),
          _buildRow(
            theme,
            label: l10n.roleCompareColIdeal,
            getter: (p) => p.compareIdeal,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.circleInfo,
                  size: 12,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.roleSwitchAnnualLimitNote,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow(ThemeData theme) {
    return Row(
      children: [
        const SizedBox(width: 90), // label column
        ...presentations.map(
          (p) => Expanded(
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: p.accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: FaIcon(
                      p.icon,
                      size: 16,
                      color: p.accentColor,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  p.title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(
    ThemeData theme, {
    required String label,
    required String Function(RolePresentation p) getter,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...presentations.map(
          (p) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                getter(p),
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
