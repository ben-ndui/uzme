import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/widgets/role_switch/role_presentation.dart';

/// Card representing one role on [RoleComparisonScreen]. Includes a
/// "Tu es ici" badge when [isCurrent] is true and disables the CTA.
class RoleCard extends StatelessWidget {
  final RolePresentation presentation;
  final bool isCurrent;
  final VoidCallback? onSwitch;

  const RoleCard({
    super.key,
    required this.presentation,
    required this.isCurrent,
    this.onSwitch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final cs = theme.colorScheme;
    final accent = presentation.accentColor;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrent
              ? accent.withValues(alpha: 0.5)
              : cs.outlineVariant,
          width: isCurrent ? 1.5 : 1,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme, l10n, accent),
          const SizedBox(height: 12),
          Text(
            presentation.intro,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          _buildSection(
            theme,
            label: l10n.roleSwitchSectionFeatures,
            color: accent,
            items: presentation.features,
            icon: FontAwesomeIcons.solidCircleCheck,
          ),
          const SizedBox(height: 16),
          _buildSection(
            theme,
            label: l10n.roleSwitchSectionAdvantages,
            color: const Color(0xFF10B981),
            items: presentation.advantages,
            icon: FontAwesomeIcons.solidStar,
          ),
          if (presentation.constraints.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSection(
              theme,
              label: l10n.roleSwitchSectionConstraints,
              color: const Color(0xFFF59E0B),
              items: presentation.constraints,
              icon: FontAwesomeIcons.triangleExclamation,
            ),
          ],
          const SizedBox(height: 20),
          _buildCta(theme, accent),
        ],
      ),
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    AppLocalizations l10n,
    Color accent,
  ) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: FaIcon(presentation.icon, size: 22, color: accent),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      presentation.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (isCurrent) ...[
                    const SizedBox(width: 8),
                    _CurrentBadge(label: l10n.roleSwitchYouAreHere),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                presentation.subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection(
    ThemeData theme, {
    required String label,
    required Color color,
    required List<String> items,
    required FaIconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (text) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: FaIcon(icon, size: 12, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCta(ThemeData theme, Color accent) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: isCurrent ? null : onSwitch,
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: theme.colorScheme.surfaceContainerHigh,
          disabledForegroundColor: theme.colorScheme.onSurfaceVariant,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        icon: FaIcon(
          isCurrent ? FontAwesomeIcons.check : FontAwesomeIcons.arrowRight,
          size: 14,
        ),
        label: Text(
          presentation.cta,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _CurrentBadge extends StatelessWidget {
  final String label;
  const _CurrentBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: cs.primary,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}
