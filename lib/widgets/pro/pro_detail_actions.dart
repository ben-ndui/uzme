import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uzme/core/models/app_user.dart';
import 'package:uzme/core/models/pro_profile.dart';
import 'package:uzme/core/services/navigation_service.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/screens/shared/pro/pro_booking_screen.dart';
import 'package:uzme/screens/shared/pro/pro_profile_view_screen.dart';

/// Réserver / voir le profil complet / itinéraire — le "Contacter" principal
/// vit désormais dans la barre ancrée en bas ([ProDetailContactFooter]).
class ProDetailActions extends StatelessWidget {
  final AppUser user;
  final ProProfile profile;

  const ProDetailActions({
    super.key,
    required this.user,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProBookingScreen(proUser: user),
                ),
              );
            },
            icon: const FaIcon(FontAwesomeIcons.calendarPlus, size: 16),
            label: Text(l10n.proBookingSend),
            // Pas de couleur à part : un turquoise isolé au milieu d'une
            // fiche bleue n'avait aucun rapport avec le reste de la palette
            // (relevé par Ben le 28/10) — le style par défaut (primary,
            // comme "Contacter") suffit à le distinguer des boutons outlined.
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProProfileViewScreen(user: user),
                ),
              );
            },
            icon: const FaIcon(FontAwesomeIcons.user, size: 14),
            label: Text(l10n.seeFullProfile),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          if (profile.location != null) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => NavigationService.openDirections(
                destination: LatLng(
                  profile.location!.latitude,
                  profile.location!.longitude,
                ),
                destinationName: profile.displayName,
              ),
              icon: FaIcon(
                FontAwesomeIcons.diamondTurnRight,
                size: 14,
                color: theme.colorScheme.primary,
              ),
              label: Text(l10n.getDirections),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
