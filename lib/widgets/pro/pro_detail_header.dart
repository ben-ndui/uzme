import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uzme/core/models/app_user.dart';
import 'package:uzme/core/models/pro_profile.dart';
import 'package:uzme/widgets/common/badges/pioneer_badge.dart';

/// Nom + badges du pro, affichés sous le header photo du bottom sheet.
class ProDetailTitleRow extends StatelessWidget {
  final AppUser user;
  final ProProfile profile;

  const ProDetailTitleRow({super.key, required this.user, required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  profile.displayName,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (profile.isVerified)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: FaIcon(FontAwesomeIcons.solidCircleCheck, size: 18, color: Colors.blue),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            profile.proTypesLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (user.isPioneer && user.pioneerNumber != null)
                PioneerBadge(pioneerNumber: user.pioneerNumber!, compact: true),
              if (profile.city != null)
                _badge(theme, icon: FontAwesomeIcons.locationDot, label: profile.city!, color: theme.colorScheme.outline),
              if (profile.remote)
                _badge(theme, icon: FontAwesomeIcons.wifi, label: 'Remote', color: Colors.green),
            ],
          ),
        ],
      ),
    );
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
            style: theme.textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
