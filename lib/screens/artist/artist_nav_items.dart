import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/widgets/common/uzme_nav_bar.dart';

/// Onglets de la barre flottante (mobile ET tablette/desktop, DA 2026-2027)
/// de [ArtistMainScaffold].
List<UzmeNavItem> artistNavItems(
  AppLocalizations l10n, {
  int pendingCount = 0,
  int unreadCount = 0,
}) => [
  UzmeNavItem(
    icon: FontAwesomeIcons.house,
    selectedIcon: FontAwesomeIcons.houseChimney,
    label: l10n.home,
  ),
  UzmeNavItem(
    icon: FontAwesomeIcons.calendarDays,
    selectedIcon: FontAwesomeIcons.calendarCheck,
    label: l10n.sessionsLabel,
    badgeCount: pendingCount,
  ),
  UzmeNavItem(
    icon: FontAwesomeIcons.heart,
    selectedIcon: FontAwesomeIcons.solidHeart,
    label: l10n.favorites,
  ),
  UzmeNavItem(
    icon: FontAwesomeIcons.comment,
    selectedIcon: FontAwesomeIcons.solidComment,
    label: l10n.messages,
    badgeCount: unreadCount,
  ),
  UzmeNavItem(
    icon: FontAwesomeIcons.gear,
    selectedIcon: FontAwesomeIcons.gears,
    label: l10n.settings,
  ),
];
