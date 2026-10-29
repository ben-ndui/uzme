import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:smoothandesign_package/smoothandesign.dart';
import 'package:uzme/config/responsive_config.dart';
import 'package:uzme/core/blocs/blocs_exports.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/screens/engineer/engineer_dashboard_page.dart';
import 'package:uzme/screens/engineer/engineer_sessions_page.dart';
import 'package:uzme/screens/engineer/engineer_settings_page.dart';
import 'package:uzme/screens/shared/conversations_screen.dart';
import 'package:uzme/screens/shared/favorites_screen.dart';
import 'package:uzme/screens/engineer/engineer_nav_items.dart';
import 'package:uzme/widgets/common/app_navigation_rail.dart';
import 'package:uzme/widgets/common/gradient_surface.dart';
import 'package:uzme/widgets/common/snackbar/app_snackbar.dart';
import 'package:uzme/widgets/common/uzme_nav_bar.dart';

/// Main scaffold for Engineer role with adaptive navigation
class EngineerMainScaffold extends StatefulWidget {
  final int initialPage;

  const EngineerMainScaffold({super.key, this.initialPage = 0});

  @override
  State<EngineerMainScaffold> createState() => _EngineerMainScaffoldState();
}

class _EngineerMainScaffoldState extends State<EngineerMainScaffold> {
  late int _currentIndex;
  late PageController _pageController;

  final List<Widget> _pages = const [
    EngineerDashboardPage(),
    EngineerSessionsPage(),
    FavoritesScreen(),
    ConversationsScreen(),
    EngineerSettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialPage;
    _pageController = PageController(initialPage: _currentIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticatedState) {
      final user = authState.user;
      context.read<SessionBloc>().add(
        LoadEngineerSessionsEvent(engineerId: user.uid),
      );
      context.read<FavoriteBloc>().add(LoadFavoritesEvent(userId: user.uid));
      _syncMessagingUser(user);
      context.read<MessagingBloc>().add(
        LoadConversationsEvent(userId: user.uid),
      );
    }
  }

  void _syncMessagingUser(BaseUser user) {
    context.read<MessagingBloc>().setCurrentUser(
      userId: user.uid,
      userName: user.displayName ?? user.name ?? 'Ingénieur',
      avatarUrl: user.photoURL,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTapped(int index) {
    if (context.isTabletOrLarger) {
      setState(() => _currentIndex = index);
    } else {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// L'accueil gère déjà son propre dégradé ; les autres doivent vivre
  /// DANS [GradientSurface] pour que leur `build()` lise un thème réécrit.
  Widget _tabAt(int index) =>
      index == 0 ? _pages[index] : GradientSurface(child: _pages[index]);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isWide = context.isTabletOrLarger;

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentIndex != 0) _onNavTapped(0);
      },
      child: BlocListener<FavoriteBloc, FavoriteState>(
        // Feedback central des échecs de toggle favori (FavoriteErrorState
        // n'était écouté nulle part — échec silencieux).
        listenWhen: (prev, curr) => curr is FavoriteErrorState,
        listener: (context, state) =>
            AppSnackBar.error(context, l10n.errorOccurred),
        child: BlocListener<AuthBloc, AuthState>(
          listenWhen: (prev, curr) =>
              prev is AuthAuthenticatedState &&
              curr is AuthAuthenticatedState &&
              prev.user.photoURL != curr.user.photoURL,
          listener: (context, state) {
            if (state is AuthAuthenticatedState) {
              _syncMessagingUser(state.user);
            }
          },
          child: isWide ? _buildWideScaffold(l10n) : _buildMobileScaffold(l10n),
        ),
      ),
    );
  }

  Widget _buildWideScaffold(AppLocalizations l10n) {
    return Scaffold(
      body: BlocBuilder<SessionBloc, SessionState>(
        buildWhen: (prev, curr) => prev.pendingCount != curr.pendingCount,
        builder: (context, sessionState) {
          return Row(
            children: [
              AppNavigationRail(
                selectedIndex: _currentIndex,
                onDestinationSelected: _onNavTapped,
                items: engineerRailItems(
                  l10n,
                  pendingCount: sessionState.pendingCount,
                ),
              ),
              Expanded(child: _tabAt(_currentIndex)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMobileScaffold(AppLocalizations l10n) {
    return Scaffold(
      extendBody: true,
      body: PageView(
        controller: _pageController,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        physics: _currentIndex == 0
            ? const NeverScrollableScrollPhysics()
            : const BouncingScrollPhysics(),
        children: [for (var i = 0; i < _pages.length; i++) _tabAt(i)],
      ),
      bottomNavigationBar: BlocBuilder<SessionBloc, SessionState>(
        buildWhen: (prev, curr) => prev.pendingCount != curr.pendingCount,
        builder: (context, sessionState) {
          return BlocBuilder<MessagingBloc, MessagingState>(
            buildWhen: (previous, current) {
              final prevCount = previous is ConversationsLoadedState
                  ? previous.totalUnreadCount
                  : 0;
              final currCount = current is ConversationsLoadedState
                  ? current.totalUnreadCount
                  : 0;
              return prevCount != currCount;
            },
            builder: (context, messagingState) {
              final unreadCount = messagingState is ConversationsLoadedState
                  ? messagingState.totalUnreadCount
                  : 0;

              return UzmeNavBar.compact(
                activeIndex: _currentIndex,
                onChanged: _onNavTapped,
                items: [
                  UzmeNavItem(
                    icon: FontAwesomeIcons.house,
                    selectedIcon: FontAwesomeIcons.houseChimney,
                    label: l10n.home,
                  ),
                  UzmeNavItem(
                    icon: FontAwesomeIcons.calendarDays,
                    selectedIcon: FontAwesomeIcons.calendarCheck,
                    label: l10n.sessionsLabel,
                    badgeCount: sessionState.pendingCount,
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
                ],
              );
            },
          );
        },
      ),
    );
  }
}
