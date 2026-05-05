import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uzme/core/constants/feature_flag_keys.dart';
import 'package:uzme/core/models/feature_flag.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/main.dart' show featureFlagsService;
import 'package:uzme/widgets/admin/feature_flag_edit_sheet.dart';
import 'package:uzme/widgets/admin/feature_rollout_l10n.dart';

/// SuperAdmin screen — manage every feature flag of the app: rollout
/// state (disabled / pioneer / beta / enabled), beta tester list,
/// description / category. Live-updates from the Firestore subscription
/// already maintained by FeatureFlagsService.
class FeatureFlagsListScreen extends StatelessWidget {
  const FeatureFlagsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.featureFlagsScreenTitle),
      ),
      body: StreamBuilder<Map<String, FeatureFlag>>(
        stream: featureFlagsService.watchAll(),
        initialData: featureFlagsService.current,
        builder: (context, snapshot) {
          final flags = (snapshot.data ?? const {}).values.toList()
            ..sort((a, b) {
              final cat = (a.category ?? '').compareTo(b.category ?? '');
              if (cat != 0) return cat;
              return a.key.compareTo(b.key);
            });
          if (flags.isEmpty) {
            return const _EmptyView();
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: flags.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _FlagTile(flag: flags[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openSheet(context, null),
        icon: const FaIcon(FontAwesomeIcons.plus, size: 16),
        label: Text(l10n.featureFlagsCreateButton),
      ),
    );
  }

  Future<void> _openSheet(BuildContext context, FeatureFlag? existing) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => FeatureFlagEditSheet(existing: existing),
    );
    if (result != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.featureFlagSavedSnack(result))),
      );
    }
  }
}

class _FlagTile extends StatelessWidget {
  final FeatureFlag flag;
  const _FlagTile({required this.flag});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final messenger = ScaffoldMessenger.of(context);
          final result = await showModalBottomSheet<String>(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (_) => FeatureFlagEditSheet(existing: flag),
          );
          if (result != null) {
            messenger.showSnackBar(
              SnackBar(content: Text(l10n.featureFlagSavedSnack(result))),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            flag.title.isEmpty ? flag.key : flag.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (FeatureFlagKeys.isCatalogued(flag.key)) ...[
                          const SizedBox(width: 6),
                          Tooltip(
                            message: l10n.featureFlagCataloguedTooltip,
                            child: FaIcon(
                              FontAwesomeIcons.bookOpen,
                              size: 12,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      flag.key,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                        fontFamily: 'monospace',
                      ),
                    ),
                    if (flag.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        flag.description,
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _RolloutChip(rollout: flag.rollout),
            ],
          ),
        ),
      ),
    );
  }
}

class _RolloutChip extends StatelessWidget {
  final FeatureRollout rollout;
  const _RolloutChip({required this.rollout});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = switch (rollout) {
      FeatureRollout.disabled => Colors.grey,
      FeatureRollout.pioneer => const Color(0xFFFFD700),
      FeatureRollout.beta => Colors.orange,
      FeatureRollout.enabled => Colors.green,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        featureRolloutLabel(l10n, rollout),
        style: TextStyle(
          color: color == const Color(0xFFFFD700)
              ? Colors.brown.shade700
              : color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              FontAwesomeIcons.toggleOff,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.featureFlagsEmptyTitle,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.featureFlagsEmptyDesc,
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
