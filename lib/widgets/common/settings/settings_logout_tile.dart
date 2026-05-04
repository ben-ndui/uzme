import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:smoothandesign_package/smoothandesign.dart';
import 'package:uzme/core/blocs/blocs_exports.dart';
import 'package:uzme/core/services/notification_service.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/routing/app_routes.dart';
import 'package:uzme/widgets/auth/lock_or_signout_sheet.dart';

/// A logout tile for settings pages. Opens a Lock/Sign-out bottom sheet
/// when biometric is enabled, falls back to direct sign-out otherwise.
class SettingsLogoutTile extends StatelessWidget {
  const SettingsLogoutTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: FaIcon(FontAwesomeIcons.rightFromBracket, size: 18, color: Colors.red),
        ),
      ),
      title: Text(l10n.logout, style: const TextStyle(color: Colors.red)),
      onTap: () => _onLogoutTap(context),
    );
  }

  Future<void> _onLogoutTap(BuildContext context) async {
    final authBloc = context.read<AuthBloc>();
    final sessionBloc = context.read<SessionBloc>();
    final artistBloc = context.read<ArtistBloc>();
    final serviceBloc = context.read<ServiceBloc>();
    final messagingBloc = context.read<MessagingBloc>();
    final favoriteBloc = context.read<FavoriteBloc>();
    final router = GoRouter.of(context);

    final email = (authBloc.state is AuthAuthenticatedState)
        ? (authBloc.state as AuthAuthenticatedState).user.email
        : '';

    await showLockOrSignOutSheet(
      context,
      email: email,
      onSignOut: () async {
        await UseMeNotificationService.instance.removeToken();
        sessionBloc.add(const ClearSessionsEvent());
        artistBloc.add(const ClearArtistsEvent());
        serviceBloc.add(const ClearServicesEvent());
        messagingBloc.add(const ClearMessagingEvent());
        favoriteBloc.add(const ClearFavoritesEvent());
        authBloc.add(const SignOutEvent());
        router.go(AppRoutes.login);
      },
      onLock: () async {
        authBloc.add(const LockAppEvent());
        router.go(AppRoutes.lock);
      },
    );
  }
}
