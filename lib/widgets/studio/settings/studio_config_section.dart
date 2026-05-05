import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:smoothandesign_package/smoothandesign.dart';
import 'package:uzme/core/constants/feature_flag_keys.dart';
import 'package:uzme/core/models/app_user.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/main.dart' show featureFlagsService;
import 'package:uzme/routing/app_routes.dart';
import 'package:uzme/widgets/common/settings/settings_exports.dart';

/// Section des paramètres de configuration du studio.
class StudioConfigSection extends StatelessWidget {
  final String? userId;

  const StudioConfigSection({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticatedState
        ? authState.user as AppUser?
        : null;
    final aiProEnabled = featureFlagsService.isEnabled(
      user,
      FeatureFlagKeys.aiAssistantPro.key,
    );
    final stripeConnectEnabled = featureFlagsService.isEnabled(
      user,
      FeatureFlagKeys.stripeConnectOnboarding.key,
    );
    final teamManagementEnabled = featureFlagsService.isEnabled(
      user,
      FeatureFlagKeys.teamManagement.key,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: l10n.studio),
        SettingsTile(
          icon: FontAwesomeIcons.buildingUser,
          title: l10n.studioProfile,
          subtitle: l10n.nameAddressContact,
          onTap: () => context.push(AppRoutes.profile),
        ),
        SettingsTile(
          icon: FontAwesomeIcons.tags,
          title: l10n.services,
          subtitle: l10n.serviceCatalog,
          onTap: () => context.push(AppRoutes.services),
        ),
        SettingsTile(
          icon: FontAwesomeIcons.doorOpen,
          title: l10n.rooms,
          subtitle: l10n.createRoomsHint,
          onTap: () => context.push(AppRoutes.rooms),
        ),
        if (teamManagementEnabled)
          SettingsTile(
            icon: FontAwesomeIcons.userTie,
            title: l10n.team,
            subtitle: l10n.manageEngineers,
            onTap: () => context.push(AppRoutes.teamManagement),
          ),
        SettingsTile(
          icon: FontAwesomeIcons.creditCard,
          title: l10n.paymentMethods,
          subtitle: l10n.paymentMethodsSubtitle,
          onTap: () => context.push(AppRoutes.paymentMethods),
        ),
        if (stripeConnectEnabled)
          SettingsTile(
            icon: FontAwesomeIcons.stripe,
            title: l10n.stripeConnect,
            subtitle: l10n.stripeConnectSubtitle,
            onTap: () => context.push(AppRoutes.stripeConnect),
          ),
        if (aiProEnabled)
          SettingsTile(
            icon: FontAwesomeIcons.robot,
            title: l10n.aiAssistant,
            subtitle: l10n.aiSettingsSubtitle,
            onTap: () => context.push(
              '${AppRoutes.aiSettings}?studioId=${userId ?? ''}',
            ),
          ),
      ],
    );
  }
}
