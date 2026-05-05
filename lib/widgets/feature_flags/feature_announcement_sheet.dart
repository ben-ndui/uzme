import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uzme/core/models/feature_flag.dart';
import 'package:uzme/l10n/app_localizations.dart';

/// Modal bottomsheet shown the first time an authenticated user gains
/// access to a feature whose admin-set [FeatureFlag.announcementTitle]
/// is non-empty. Render-only — caller resolves the flag and acks
/// dismissal (typically via FeatureAnnouncementsService.markSeen).
///
/// Returns `true` from `Navigator.pop` when the user confirms — caller
/// can then persist the seen state. Drag-down also returns `true` (the
/// announcement is functionally acknowledged once shown).
class FeatureAnnouncementSheet extends StatelessWidget {
  final FeatureFlag flag;
  const FeatureAnnouncementSheet({super.key, required this.flag});

  /// Convenience opener — wraps `showModalBottomSheet` with the right
  /// shape, drag handle, and pop semantics. Returns the same bool as
  /// the underlying sheet.
  static Future<bool> show({
    required BuildContext context,
    required FeatureFlag flag,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      // Acknowledged on any close path — barrier dismiss + drag-down
      // both count as "seen" so we don't re-popup on the next foreground.
      builder: (_) => FeatureAnnouncementSheet(flag: flag),
    );
    return result ?? true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 24 + viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
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
                      l10n.featureAnnouncementBadge,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            flag.announcementTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (flag.announcementBody.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              flag.announcementBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(l10n.featureAnnouncementCta),
            ),
          ),
        ],
      ),
    );
  }
}
