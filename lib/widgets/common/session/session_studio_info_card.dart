import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uzme/core/models/models_exports.dart';
import 'package:uzme/core/services/pro_profile_service.dart';
import 'package:uzme/core/services/session_location_resolver.dart';
import 'package:uzme/core/utils/app_logger.dart';
import 'package:uzme/l10n/app_localizations.dart';

/// Carte "où a lieu la session", au même gabarit que les autres cartes
/// d'information de l'écran de détail (icône, titre, valeur). Résolution
/// mise en cache dans `initState` : jamais recréée à chaque rebuild.
class SessionStudioInfoCard extends StatefulWidget {
  final Session session;
  final AppLocalizations l10n;

  /// Injectable pour les tests ; sinon `ProProfileService()` par défaut.
  final ProProfileService? profileService;

  const SessionStudioInfoCard({
    super.key,
    required this.session,
    required this.l10n,
    this.profileService,
  });

  @override
  State<SessionStudioInfoCard> createState() => _SessionStudioInfoCardState();
}

class _SessionStudioInfoCardState extends State<SessionStudioInfoCard> {
  late final Future<SessionLocation?> _location =
      resolveSessionLocation(widget.session, profileService: widget.profileService);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<SessionLocation?>(
      future: _location,
      builder: (context, snapshot) {
        String value;
        if (snapshot.connectionState != ConnectionState.done) {
          value = '…';
        } else if (snapshot.hasError) {
          appLog('SessionStudioInfoCard: échec résolution — ${snapshot.error}');
          value = widget.session.isProSession ? 'Pro' : 'Studio';
        } else if (snapshot.data == null) {
          value = widget.l10n.unnamed;
        } else {
          final location = snapshot.data!;
          value = location.address != null && location.address!.isNotEmpty
              ? '${location.name}\n${location.address}'
              : location.name;
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FaIcon(
                  widget.session.isProSession ? FontAwesomeIcons.userTie : FontAwesomeIcons.recordVinyl,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.session.isProSession ? widget.l10n.prosLabel : widget.l10n.studiosLabel,
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
