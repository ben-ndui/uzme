import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uzme/core/models/discovered_studio.dart';
import 'package:uzme/core/models/studio_profile.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/widgets/common/badges/pioneer_badge.dart';
import 'package:uzme/widgets/common/detail_sheet_ink.dart';

/// Nom + badges du studio, affichés sous le header photo du bottom sheet.
class StudioDetailTitleRow extends StatelessWidget {
  final DiscoveredStudio studio;

  const StudioDetailTitleRow({super.key, required this.studio});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final ink = DetailSheetInk(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            studio.name,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (studio.isPioneer && studio.pioneerNumber != null)
                PioneerBadge(
                  pioneerNumber: studio.pioneerNumber!,
                  compact: true,
                ),
              if (studio.isVerified)
                _badge(
                  theme,
                  icon: FontAwesomeIcons.shieldHalved,
                  label: l10n.verified,
                  color: Colors.blue,
                ),
              if (studio.isPartner && !studio.isPioneer)
                _badge(
                  theme,
                  icon: FontAwesomeIcons.solidCircleCheck,
                  label: l10n.partner,
                  color: Colors.green,
                ),
              if (!studio.isPartner)
                _badge(
                  theme,
                  icon: FontAwesomeIcons.circleXmark,
                  label: l10n.notAvailable,
                  color: ink.mutedInk,
                ),
              _studioTypeBadge(theme, l10n),
            ],
          ),
        ],
      ),
    );
  }

  Widget _studioTypeBadge(ThemeData theme, AppLocalizations l10n) {
    final (icon, label, color) = switch (studio.studioType) {
      StudioType.pro => (
        FontAwesomeIcons.building,
        l10n.studioTypePro,
        Colors.purple,
      ),
      StudioType.independent => (
        FontAwesomeIcons.houseUser,
        l10n.studioTypeIndependent,
        Colors.blue,
      ),
      StudioType.amateur => (
        FontAwesomeIcons.house,
        l10n.studioTypeAmateur,
        Colors.orange,
      ),
    };
    return _badge(theme, icon: icon, label: label, color: color);
  }

  Widget _badge(
    ThemeData theme, {
    required FaIconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
