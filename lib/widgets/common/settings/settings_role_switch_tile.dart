import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/routing/app_routes.dart';
import 'package:uzme/widgets/common/settings/uzme_feature_capsule.dart';

/// Settings tile that opens the role comparator screen.
class SettingsRoleSwitchTile extends StatelessWidget {
  const SettingsRoleSwitchTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return UzmeFeatureCapsule(
      icon: FontAwesomeIcons.arrowRightArrowLeft,
      title: l10n.roleSwitchTileTitle,
      subtitle: l10n.roleSwitchTileSubtitle,
      onTap: () => context.push(AppRoutes.roleSwitch),
    );
  }
}
