import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:uzme/config/useme_theme.dart';
import 'package:uzme/core/blocs/map/map_bloc.dart';
import 'package:uzme/core/blocs/map/map_event.dart';
import 'package:uzme/core/models/discovered_studio.dart';
import 'package:uzme/core/services/navigation_service.dart';
import 'package:uzme/l10n/app_localizations.dart';

/// Barre d'action ANCRÉE en bas de la feuille (SmoothDraggableWidget.pinnedFooter) :
/// une seule action principale — réserver pour un partenaire, sinon l'itinéraire
/// (c'est la seule chose qu'on peut faire sur un studio non réservable).
class StudioDetailActions extends StatelessWidget {
  final DiscoveredStudio studio;

  const StudioDetailActions({super.key, required this.studio});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    // La feuille a un fond dégradé bleu en dark (cf. SmoothDraggableWidget) :
    // `colorScheme.surface` y est le gris neutre quasi-noir de l'app, pas
    // celui de la feuille — d'où le bandeau noir sous "Y aller" relevé par
    // Ben le 28/10. On reprend la même couleur que le bas du dégradé.
    final footerBackground = theme.brightness == Brightness.dark
        ? UseMeTheme.secondaryColor
        : theme.colorScheme.surface;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: footerBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 12),
        child: studio.isPartner
            ? _bookRow(context, l10n)
            : _directionsRow(context, theme, l10n),
      ),
    );
  }

  Widget _bookRow(BuildContext context, AppLocalizations l10n) {
    return FilledButton.icon(
      onPressed: () {
        Navigator.pop(context);
        context.push(
          '/artist/request?studioId=${studio.id}&studioName=${Uri.encodeComponent(studio.name)}',
        );
      },
      icon: const FaIcon(FontAwesomeIcons.calendarPlus, size: 16),
      label: Text(l10n.book),
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
      ),
    );
  }

  Widget _directionsRow(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    MapBloc? mapBloc;
    try {
      mapBloc = context.read<MapBloc>();
    } catch (_) {}

    final primary = FilledButton.icon(
      onPressed: () {
        if (mapBloc != null) {
          mapBloc.add(GetDirectionsEvent(destination: studio));
        } else {
          NavigationService.openDirections(
            destination: studio.position,
            destinationName: studio.name,
          );
        }
        Navigator.pop(context);
      },
      icon: const FaIcon(FontAwesomeIcons.route, size: 16),
      label: Text(l10n.getDirections),
      style: FilledButton.styleFrom(minimumSize: const Size(0, 50)),
    );

    if (mapBloc == null) {
      return SizedBox(width: double.infinity, child: primary);
    }

    return Row(
      children: [
        Expanded(child: primary),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: () => NavigationService.openDirections(
            destination: studio.position,
            destinationName: studio.name,
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(50, 50),
            padding: EdgeInsets.zero,
          ),
          child: FaIcon(
            FontAwesomeIcons.diamondTurnRight,
            size: 16,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
