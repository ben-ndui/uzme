import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uzme/core/models/whats_new_summary.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/main.dart' show featureFlagsService;
import 'package:uzme/widgets/common/app_loader.dart';
import 'package:uzme/widgets/common/snackbar/app_snackbar.dart';

/// Screen accessible from Settings → "Tes nouveautés". Renders the
/// AI-generated recap returned by `getWhatsNewForMe` :
///
/// - intro paragraph
/// - up to 3 cards (one per unlocked feature) with title / summary /
///   action / "déjà vu" badge
/// - empty-state callout when nothing new
/// - regenerate button (re-calls the AI on demand — useful after admin
///   activates a new flag)
class WhatsNewScreen extends StatefulWidget {
  const WhatsNewScreen({super.key});

  @override
  State<WhatsNewScreen> createState() => _WhatsNewScreenState();
}

class _WhatsNewScreenState extends State<WhatsNewScreen> {
  Future<WhatsNewSummary>? _future;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    // Important: block body, not arrow. The arrow form returns the
    // assignment expression's value (a Future<WhatsNewSummary>), which
    // setState detects as async work and asserts on. Block body
    // returns void, which is what setState wants.
    setState(() {
      _future = featureFlagsService.getWhatsNewForMe();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.whatsNewScreenTitle),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.arrowsRotate, size: 16),
            tooltip: l10n.whatsNewRefresh,
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<WhatsNewSummary>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return _Loading(label: l10n.whatsNewLoadingLabel);
          }
          if (snap.hasError) {
            // Error case is rare since the backend has a fallback, but
            // network failures still throw.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                AppSnackBar.error(
                  context,
                  l10n.whatsNewError(snap.error.toString()),
                );
              }
            });
            return _Empty(
              title: l10n.whatsNewEmptyTitle,
              subtitle: l10n.whatsNewEmptySubtitle,
            );
          }
          final summary = snap.data!;
          if (summary.empty) {
            return _Empty(
              title: l10n.whatsNewEmptyTitle,
              subtitle: l10n.whatsNewEmptySubtitle,
            );
          }
          return _Content(summary: summary);
        },
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  final String label;
  const _Loading({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppLoader(),
          const SizedBox(height: 16),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String title;
  final String subtitle;
  const _Empty({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: FaIcon(
                  FontAwesomeIcons.solidCircleCheck,
                  size: 28,
                  color: Color(0xFF10B981),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
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

class _Content extends StatelessWidget {
  final WhatsNewSummary summary;
  const _Content({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        if (summary.intro.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              summary.intro,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.45,
              ),
            ),
          ),
        for (final item in summary.items) ...[
          _ItemCard(item: item),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _ItemCard extends StatelessWidget {
  final WhatsNewItem item;
  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final cs = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (item.alreadySeen)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.whatsNewSeenBadge,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if (item.summary.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.summary,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
          ],
          if (item.action.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FaIcon(
                    FontAwesomeIcons.arrowRight,
                    size: 12,
                    color: cs.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodySmall,
                        children: [
                          TextSpan(
                            text: '${l10n.whatsNewActionLabel} ',
                            style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text: item.action,
                            style: TextStyle(color: cs.onSurface),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
