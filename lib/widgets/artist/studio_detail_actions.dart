import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:uzme/core/blocs/map/map_bloc.dart';
import 'package:uzme/core/blocs/map/map_event.dart';
import 'package:uzme/core/models/discovered_studio.dart';
import 'package:uzme/core/services/navigation_service.dart';
import 'package:uzme/l10n/app_localizations.dart';

/// Bouton de réservation (ou "non disponible") + itinéraire.
class StudioDetailActions extends StatelessWidget {
  final DiscoveredStudio studio;

  const StudioDetailActions({super.key, required this.studio});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          if (studio.isPartner)
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                context.push(
                  '/artist/request?studioId=${studio.id}&studioName=${Uri.encodeComponent(studio.name)}',
                );
              },
              icon: const FaIcon(FontAwesomeIcons.calendarPlus, size: 16),
              label: Text(l10n.book),
              style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            )
          else
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const FaIcon(FontAwesomeIcons.xmark, size: 16),
              label: Text(l10n.notAvailable),
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            ),
          const SizedBox(height: 10),
          _buildDirectionsRow(context, theme, l10n),
        ],
      ),
    );
  }

  Widget _buildDirectionsRow(BuildContext context, ThemeData theme, AppLocalizations l10n) {
    MapBloc? mapBloc;
    try {
      mapBloc = context.read<MapBloc>();
    } catch (_) {}

    if (mapBloc != null) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                mapBloc!.add(GetDirectionsEvent(destination: studio));
                Navigator.pop(context);
              },
              icon: FaIcon(FontAwesomeIcons.route, size: 14, color: theme.colorScheme.primary),
              label: Text(l10n.getDirections),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50)),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => NavigationService.openDirections(
              destination: studio.position,
              destinationName: studio.name,
            ),
            style: OutlinedButton.styleFrom(minimumSize: const Size(50, 50), padding: EdgeInsets.zero),
            child: FaIcon(FontAwesomeIcons.diamondTurnRight, size: 16, color: theme.colorScheme.primary),
          ),
        ],
      );
    }

    return OutlinedButton.icon(
      onPressed: () => NavigationService.openDirections(
        destination: studio.position,
        destinationName: studio.name,
      ),
      icon: FaIcon(FontAwesomeIcons.diamondTurnRight, size: 16, color: theme.colorScheme.primary),
      label: Text(l10n.getDirections),
      style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
    );
  }
}
