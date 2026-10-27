import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smoothandesign_package/smoothandesign.dart';
import 'package:uzme/core/models/app_user.dart';
import 'package:uzme/core/models/pro_profile.dart';
import 'package:uzme/core/services/navigation_service.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/routing/app_routes.dart';
import 'package:uzme/screens/shared/pro/pro_booking_screen.dart';
import 'package:uzme/screens/shared/pro/pro_profile_view_screen.dart';

/// Contacter / réserver / voir le profil complet / itinéraire.
class ProDetailActions extends StatelessWidget {
  final AppUser user;
  final ProProfile profile;

  const ProDetailActions({super.key, required this.user, required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: BlocListener<MessagingBloc, MessagingState>(
        listenWhen: (prev, curr) => curr is ChatOpenState,
        listener: (context, state) {
          if (state is ChatOpenState) {
            Navigator.pop(context);
            context.push('${AppRoutes.conversations}/${state.conversation.id}');
          }
        },
        child: Column(
          children: [
            FilledButton.icon(
              onPressed: () => _startConversation(context, l10n),
              icon: const FaIcon(FontAwesomeIcons.solidMessage, size: 16),
              label: Text(l10n.proDetailContact),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => ProBookingScreen(proUser: user)));
              },
              icon: const FaIcon(FontAwesomeIcons.calendarPlus, size: 16),
              label: Text(l10n.proBookingSend),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: theme.colorScheme.tertiary,
                foregroundColor: theme.colorScheme.onTertiary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => ProProfileViewScreen(user: user)));
              },
              icon: const FaIcon(FontAwesomeIcons.user, size: 14),
              label: Text(l10n.seeFullProfile),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            if (profile.location != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => NavigationService.openDirections(
                  destination: LatLng(profile.location!.latitude, profile.location!.longitude),
                  destinationName: profile.displayName,
                ),
                icon: FaIcon(FontAwesomeIcons.diamondTurnRight, size: 14, color: theme.colorScheme.primary),
                label: Text(l10n.getDirections),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _startConversation(BuildContext context, AppLocalizations l10n) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticatedState) return;

    final currentUser = authState.user as AppUser;
    final currentUserInfo = ParticipantInfo(
      name: currentUser.displayName ?? currentUser.name ?? l10n.user,
      avatarUrl: currentUser.photoURL,
      role: currentUser.role.useMeLabel,
      isPioneer: currentUser.isPioneer,
    );

    final otherUserInfo = ParticipantInfo(
      name: profile.displayName,
      avatarUrl: user.displayPhotoUrl,
      role: user.role.useMeLabel,
      isPioneer: user.isPioneer,
    );

    context.read<MessagingBloc>().add(StartPrivateConversationEvent(
          otherUserId: user.uid,
          otherUserInfo: otherUserInfo,
          currentUserInfo: currentUserInfo,
        ));
  }
}
