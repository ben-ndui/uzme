import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uzme/core/models/discovered_studio.dart';
import 'package:uzme/core/services/navigation_service.dart';
import 'package:uzme/l10n/app_localizations.dart';

/// Repli liste pour macOS — `google_maps_flutter` n'a aucune implémentation
/// macOS (constaté 30/10/2026, bannière "not yet supported" du plugin). Même
/// données que la carte (`MapBloc`), juste sans widget carte : la fiche liste
/// la distance/note et ouvre Google Maps dans le navigateur pour le point
/// précis plutôt que de simuler une carte factice (charte "rien de faux").
class StudioMapListFallback extends StatelessWidget {
  final bool isLoading;
  final List<DiscoveredStudio> studios;
  final void Function(DiscoveredStudio) onStudioTap;

  const StudioMapListFallback({
    super.key,
    required this.isLoading,
    required this.studios,
    required this.onStudioTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (isLoading && studios.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(l10n.searchingStudios),
          ],
        ),
      );
    }

    if (studios.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(
                FontAwesomeIcons.locationCrosshairs,
                size: 28,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(l10n.noStudioFound, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 120, 16, 16),
      itemCount: studios.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final studio = studios[index];
        return _StudioListTile(
          studio: studio,
          l10n: l10n,
          onTap: () => onStudioTap(studio),
        );
      },
    );
  }
}

class _StudioListTile extends StatelessWidget {
  final DiscoveredStudio studio;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  const _StudioListTile({
    required this.studio,
    required this.l10n,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _Avatar(studio: studio),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studio.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        studio.formattedDistance,
                        if (studio.isPro) 'Pro',
                        if (studio.isPartner) l10n.partnerLabel,
                        if (studio.rating != null) '★ ${studio.rating!.toStringAsFixed(1)}',
                      ].join(' • '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: FaIcon(FontAwesomeIcons.locationArrow, size: 16, color: theme.colorScheme.primary),
                tooltip: l10n.openInMaps,
                onPressed: () => NavigationService.openLocation(
                  position: studio.position,
                  name: studio.name,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final DiscoveredStudio studio;

  const _Avatar({required this.studio});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 52,
        height: 52,
        child: studio.photoUrl != null
            ? Image.network(
                studio.photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(theme),
              )
            : _placeholder(theme),
      ),
    );
  }

  Widget _placeholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primaryContainer,
      child: FaIcon(FontAwesomeIcons.microphone, size: 18, color: theme.colorScheme.onPrimaryContainer),
    );
  }
}
