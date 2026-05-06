import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uzme/core/models/role_switch_advice.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/widgets/role_switch/role_presentation.dart';

/// Bottom sheet showing the AI's role-switch recommendation. Two flows:
///
///   1. AI says "stay where you are" ([advice.staying] = true) →
///      green callout, no switch CTA, just a dismiss button.
///   2. AI suggests a different role → callout with the recommended
///      role's accent color + a "Basculer en X" button that triggers
///      [onSwitchRecommended] (which the parent screen wires to its
///      regular switch flow → confirm dialog → callable).
///
/// On AI failure (deterministic fallback), [advice.highlights] may be
/// empty; the sheet still renders the reasoning paragraph cleanly.
class RoleAdvisorSheet extends StatelessWidget {
  final RoleSwitchAdvice advice;
  final VoidCallback onSwitchRecommended;

  const RoleAdvisorSheet({
    super.key,
    required this.advice,
    required this.onSwitchRecommended,
  });

  static Future<void> show({
    required BuildContext context,
    required RoleSwitchAdvice advice,
    required VoidCallback onSwitchRecommended,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => RoleAdvisorSheet(
        advice: advice,
        onSwitchRecommended: onSwitchRecommended,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final viewInsets = MediaQuery.of(context).viewInsets;
    final recommended = RolePresentation.forRole(advice.recommendedRole, l10n);
    final accent = advice.staying ? const Color(0xFF10B981) : recommended.accentColor;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 24 + viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BadgeRow(label: l10n.roleSwitchAdvisorBadge),
          const SizedBox(height: 16),
          _Header(
            advice: advice,
            recommended: recommended,
            accent: accent,
            l10n: l10n,
          ),
          const SizedBox(height: 16),
          Text(
            advice.reasoning,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (advice.highlights.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...advice.highlights.map(
              (h) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: FaIcon(
                        FontAwesomeIcons.solidCircleCheck,
                        size: 12,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        h,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (!advice.staying)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  onSwitchRecommended();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const FaIcon(FontAwesomeIcons.arrowRight, size: 14),
                label: Text(
                  l10n.roleSwitchAdvisorSwitchCta(recommended.title),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          if (advice.staying)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(l10n.roleSwitchAdvisorDismiss),
              ),
            ),
        ],
      ),
    );
  }
}

class _BadgeRow extends StatelessWidget {
  final String label;
  const _BadgeRow({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(
                FontAwesomeIcons.wandMagicSparkles,
                size: 12,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final RoleSwitchAdvice advice;
  final RolePresentation recommended;
  final Color accent;
  final AppLocalizations l10n;
  const _Header({
    required this.advice,
    required this.recommended,
    required this.accent,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: FaIcon(
              advice.staying ? FontAwesomeIcons.solidCircleCheck : recommended.icon,
              size: 24,
              color: accent,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            advice.staying
                ? l10n.roleSwitchAdvisorStayingTitle(recommended.title)
                : l10n.roleSwitchAdvisorRecommendTitle(recommended.title),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
