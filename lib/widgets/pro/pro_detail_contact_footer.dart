import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:smoothandesign_package/smoothandesign.dart';
import 'package:uzme/config/useme_theme.dart';
import 'package:uzme/core/models/app_user.dart';
import 'package:uzme/core/models/pro_profile.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/routing/app_routes.dart';

/// Barre d'action ANCRÉE en bas de la feuille (SmoothDraggableWidget.pinnedFooter) —
/// "Contacter" est l'action principale pour un pro, les autres (réserver,
/// profil complet, itinéraire) restent dans le corps défilant.
class ProDetailContactFooter extends StatelessWidget {
  final AppUser user;
  final ProProfile profile;

  const ProDetailContactFooter({
    super.key,
    required this.user,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    // La feuille a un fond dégradé bleu en dark (cf. SmoothDraggableWidget) :
    // `colorScheme.surface` y est le gris neutre quasi-noir de l'app, pas
    // celui de la feuille — d'où le bandeau noir sous "Contacter" relevé par
    // Ben le 28/10. On reprend la même couleur que le bas du dégradé.
    final footerBackground = theme.brightness == Brightness.dark
        ? UseMeTheme.secondaryColor
        : theme.colorScheme.surface;

    return BlocListener<MessagingBloc, MessagingState>(
      listenWhen: (prev, curr) => curr is ChatOpenState,
      listener: (context, state) {
        if (state is ChatOpenState) {
          Navigator.pop(context);
          context.push('${AppRoutes.conversations}/${state.conversation.id}');
        }
      },
      child: DecoratedBox(
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
          child: FilledButton.icon(
            onPressed: () => _startConversation(context, l10n),
            icon: const FaIcon(FontAwesomeIcons.solidMessage, size: 16),
            label: Text(l10n.proDetailContact),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
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

    context.read<MessagingBloc>().add(
      StartPrivateConversationEvent(
        otherUserId: user.uid,
        otherUserInfo: otherUserInfo,
        currentUserInfo: currentUserInfo,
      ),
    );
  }
}
