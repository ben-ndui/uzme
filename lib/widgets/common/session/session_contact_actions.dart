import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:smoothandesign_package/smoothandesign.dart';
import 'package:uzme/core/models/models_exports.dart';
import 'package:uzme/core/services/pro_profile_service.dart';
import 'package:uzme/core/services/navigation_service.dart';
import 'package:uzme/core/services/session_contact_resolver.dart';
import 'package:uzme/core/utils/app_logger.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/routing/app_routes.dart';
import 'package:url_launcher/url_launcher.dart';

/// Écrire au studio (ou au pro) d'une session, l'appeler si un numéro est
/// renseigné, et s'y rendre si `showDirections` est activé (détail de
/// session) et qu'une position est connue. Résolution du contact mise en
/// cache dans `initState`.
class SessionContactActions extends StatefulWidget {
  final Session session;
  final bool showDirections;

  /// Injectable pour les tests ; sinon `ProProfileService()` par défaut.
  final ProProfileService? profileService;

  const SessionContactActions({
    super.key,
    required this.session,
    this.showDirections = false,
    this.profileService,
  });

  @override
  State<SessionContactActions> createState() => _SessionContactActionsState();
}

class _SessionContactActionsState extends State<SessionContactActions> {
  late final Future<SessionContact?> _contact =
      resolveSessionContact(widget.session, profileService: widget.profileService);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<SessionContact?>(
      future: _contact,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        if (snapshot.hasError) {
          appLog('SessionContactActions: échec résolution contact — ${snapshot.error}');
          return const SizedBox.shrink();
        }
        final contact = snapshot.data;
        if (contact == null) return const SizedBox.shrink();

        return BlocListener<MessagingBloc, MessagingState>(
          listenWhen: (_, current) => current is ChatOpenState,
          listener: (context, state) {
            if (state is ChatOpenState) {
              context.push('${AppRoutes.conversations}/${state.conversation.id}');
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionButton(
                icon: FontAwesomeIcons.solidMessage,
                color: theme.colorScheme.primary,
                onTap: () => _openConversation(context, contact),
              ),
              if (contact.phone != null) ...[
                const SizedBox(width: 6),
                _ActionButton(
                  icon: FontAwesomeIcons.phone,
                  color: theme.colorScheme.primary,
                  onTap: () => _call(contact.phone!),
                ),
              ],
              if (widget.showDirections && contact.location != null) ...[
                const SizedBox(width: 6),
                _ActionButton(
                  icon: FontAwesomeIcons.diamondTurnRight,
                  color: theme.colorScheme.primary,
                  onTap: () => NavigationService.openDirections(
                    destination: contact.location!,
                    destinationName: contact.name,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _openConversation(BuildContext context, SessionContact contact) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticatedState) return;
    final l10n = AppLocalizations.of(context)!;
    final currentUser = authState.user as AppUser;

    context.read<MessagingBloc>().add(
      StartPrivateConversationEvent(
        otherUserId: contact.userId,
        otherUserInfo: ParticipantInfo(
          name: contact.name,
          avatarUrl: contact.avatarUrl,
          role: contact.role,
          isPioneer: contact.isPioneer,
        ),
        currentUserInfo: ParticipantInfo(
          name: currentUser.displayName ?? currentUser.name ?? l10n.user,
          avatarUrl: currentUser.photoURL,
          role: currentUser.role.useMeLabel,
          isPioneer: currentUser.isPioneer,
        ),
      ),
    );
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

class _ActionButton extends StatelessWidget {
  final FaIconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: FaIcon(icon, size: 13, color: color),
      ),
    );
  }
}
