import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:smoothandesign_package/smoothandesign.dart';
import 'package:uzme/l10n/app_localizations.dart';

/// Pure data carrying the copy + visuals for one role's card and the
/// compare table column. Built from [AppLocalizations] at render time
/// so all strings come from ARB files.
@immutable
class RolePresentation {
  final BaseUserRole role;
  final FaIconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;
  final String intro;
  final List<String> features;
  final List<String> advantages;
  final List<String> constraints;
  final String cta;

  // Compare table fields
  final String compareAudience;
  final String comparePricing;
  final String compareTools;
  final String compareIdeal;

  const RolePresentation({
    required this.role,
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.intro,
    required this.features,
    required this.advantages,
    required this.constraints,
    required this.cta,
    required this.compareAudience,
    required this.comparePricing,
    required this.compareTools,
    required this.compareIdeal,
  });

  /// Build the presentation for [role] from the current locale.
  factory RolePresentation.forRole(
    BaseUserRole role,
    AppLocalizations l10n,
  ) {
    switch (role) {
      case BaseUserRole.client:
        return RolePresentation(
          role: role,
          icon: FontAwesomeIcons.music,
          accentColor: const Color(0xFF8B5CF6), // purple
          title: l10n.artist,
          subtitle: l10n.roleArtistSubtitle,
          intro: l10n.roleArtistIntro,
          features: [
            l10n.roleArtistFeature1,
            l10n.roleArtistFeature2,
            l10n.roleArtistFeature3,
            l10n.roleArtistFeature4,
          ],
          advantages: [
            l10n.roleArtistAdvantage1,
            l10n.roleArtistAdvantage2,
            l10n.roleArtistAdvantage3,
          ],
          constraints: [
            l10n.roleArtistConstraint1,
            l10n.roleArtistConstraint2,
          ],
          cta: l10n.roleArtistCta,
          compareAudience: l10n.roleArtistCompareAudience,
          comparePricing: l10n.roleArtistComparePricing,
          compareTools: l10n.roleArtistCompareTools,
          compareIdeal: l10n.roleArtistCompareIdeal,
        );
      case BaseUserRole.admin:
        return RolePresentation(
          role: role,
          icon: FontAwesomeIcons.buildingUser,
          accentColor: const Color(0xFFFFB800), // gold-ish
          title: l10n.studio,
          subtitle: l10n.roleStudioSubtitle,
          intro: l10n.roleStudioIntro,
          features: [
            l10n.roleStudioFeature1,
            l10n.roleStudioFeature2,
            l10n.roleStudioFeature3,
            l10n.roleStudioFeature4,
            l10n.roleStudioFeature5,
          ],
          advantages: [
            l10n.roleStudioAdvantage1,
            l10n.roleStudioAdvantage2,
            l10n.roleStudioAdvantage3,
          ],
          constraints: [
            l10n.roleStudioConstraint1,
            l10n.roleStudioConstraint2,
            l10n.roleStudioConstraint3,
          ],
          cta: l10n.roleStudioCta,
          compareAudience: l10n.roleStudioCompareAudience,
          comparePricing: l10n.roleStudioComparePricing,
          compareTools: l10n.roleStudioCompareTools,
          compareIdeal: l10n.roleStudioCompareIdeal,
        );
      case BaseUserRole.worker:
        return RolePresentation(
          role: role,
          icon: FontAwesomeIcons.headphones,
          accentColor: const Color(0xFF10B981), // emerald
          title: l10n.engineer,
          subtitle: l10n.roleEngineerSubtitle,
          intro: l10n.roleEngineerIntro,
          features: [
            l10n.roleEngineerFeature1,
            l10n.roleEngineerFeature2,
            l10n.roleEngineerFeature3,
            l10n.roleEngineerFeature4,
          ],
          advantages: [
            l10n.roleEngineerAdvantage1,
            l10n.roleEngineerAdvantage2,
            l10n.roleEngineerAdvantage3,
          ],
          constraints: [
            l10n.roleEngineerConstraint1,
            l10n.roleEngineerConstraint2,
          ],
          cta: l10n.roleEngineerCta,
          compareAudience: l10n.roleEngineerCompareAudience,
          comparePricing: l10n.roleEngineerComparePricing,
          compareTools: l10n.roleEngineerCompareTools,
          compareIdeal: l10n.roleEngineerCompareIdeal,
        );
      case BaseUserRole.superAdmin:
      case BaseUserRole.user:
        // SuperAdmin and "user" don't have a public-facing role card.
        // Fall back to artist as a safe default — this branch should
        // never actually render in production (the screen only lists
        // the 3 supported roles).
        return RolePresentation.forRole(BaseUserRole.client, l10n);
    }
  }

  /// The 3 roles the user can switch between, in display order.
  static const List<BaseUserRole> switchableRoles = [
    BaseUserRole.client,
    BaseUserRole.admin,
    BaseUserRole.worker,
  ];
}
