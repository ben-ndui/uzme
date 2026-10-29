import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uzme/core/models/models_exports.dart';
import 'package:uzme/core/services/pro_profile_service.dart';
import 'package:uzme/core/services/session_location_resolver.dart';
import 'package:uzme/core/utils/app_logger.dart';

/// Ligne "où a lieu la session" : nom du studio (ou du pro, pour une session
/// freelance), avec adresse optionnelle. Résolution mise en cache dans
/// `initState`, jamais recréée à chaque rebuild (cf. pieges-flutter-recurrents.md).
class SessionLocationLine extends StatefulWidget {
  final Session session;
  final TextStyle? style;
  final Color? iconColor;
  final bool showAddress;

  /// Injectable pour les tests ; sinon `ProProfileService()` par défaut.
  final ProProfileService? profileService;

  const SessionLocationLine({
    super.key,
    required this.session,
    this.style,
    this.iconColor,
    this.showAddress = false,
    this.profileService,
  });

  @override
  State<SessionLocationLine> createState() => _SessionLocationLineState();
}

class _SessionLocationLineState extends State<SessionLocationLine> {
  late final Future<SessionLocation?> _location =
      resolveSessionLocation(widget.session, profileService: widget.profileService);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SessionLocation?>(
      future: _location,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        if (snapshot.hasError) {
          // Ne pas avaler l'erreur en silence (vide = mensonge) : on sait
          // qu'il y a un lieu, juste pas lequel pour l'instant.
          appLog('SessionLocationLine: échec résolution — ${snapshot.error}');
          return _line(widget.session.isProSession ? 'Pro' : 'Studio');
        }
        final location = snapshot.data;
        if (location == null) return const SizedBox.shrink();
        return _line(
          location.name,
          address: widget.showAddress ? location.address : null,
        );
      },
    );
  }

  Widget _line(String name, {String? address}) {
    final theme = Theme.of(context);
    final style = widget.style ??
        TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.6));
    final text = address != null && address.isNotEmpty ? '$name • $address' : name;

    return Row(
      children: [
        FaIcon(
          FontAwesomeIcons.locationDot,
          size: 11,
          color: widget.iconColor ?? theme.colorScheme.onSurface.withValues(alpha: 0.45),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
