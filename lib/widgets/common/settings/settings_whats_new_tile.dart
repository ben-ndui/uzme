import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/routing/app_routes.dart';
import 'package:uzme/widgets/common/settings/uzme_feature_capsule.dart';

/// Settings tile that opens the AI-personalized "what's new" recap.
class SettingsWhatsNewTile extends StatelessWidget {
  const SettingsWhatsNewTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return UzmeFeatureCapsule(
      icon: FontAwesomeIcons.wandMagicSparkles,
      title: l10n.whatsNewTileTitle,
      subtitle: l10n.whatsNewTileSubtitle,
      onTap: () => context.push(AppRoutes.whatsNew),
    );
  }
}
