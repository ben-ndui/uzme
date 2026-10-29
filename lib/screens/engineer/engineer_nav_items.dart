import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/widgets/common/app_navigation_rail.dart';

/// Éléments de la barre latérale (tablette/desktop) de [EngineerMainScaffold].
List<AppNavRailItem> engineerRailItems(
  AppLocalizations l10n, {
  int pendingCount = 0,
}) => [
  AppNavRailItem(
    icon: FontAwesomeIcons.house,
    selectedIcon: FontAwesomeIcons.houseChimney,
    label: l10n.home,
  ),
  AppNavRailItem(
    icon: FontAwesomeIcons.calendarDays,
    selectedIcon: FontAwesomeIcons.calendarCheck,
    label: l10n.sessionsLabel,
    badgeCount: pendingCount,
  ),
  AppNavRailItem(
    icon: FontAwesomeIcons.heart,
    selectedIcon: FontAwesomeIcons.solidHeart,
    label: l10n.favorites,
  ),
  AppNavRailItem(
    icon: FontAwesomeIcons.comment,
    selectedIcon: FontAwesomeIcons.solidComment,
    label: l10n.messages,
    isMessages: true,
  ),
  AppNavRailItem(
    icon: FontAwesomeIcons.gear,
    selectedIcon: FontAwesomeIcons.gears,
    label: l10n.settings,
  ),
];
