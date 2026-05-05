import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:smoothandesign_package/smoothandesign.dart';
import 'package:uzme/core/constants/feature_flag_keys.dart';
import 'package:uzme/core/models/app_user.dart';
import 'package:uzme/main.dart' show featureFlagsService;
import 'package:uzme/screens/auth/biometric_lock_screen.dart';
import 'package:uzme/screens/auth/login_screen.dart';
import 'package:uzme/screens/auth/register_screen.dart';
import 'package:uzme/screens/auth/splash_screen.dart';
import 'package:uzme/screens/studio/studio_main_scaffold.dart';
import 'package:uzme/screens/studio/session_form_screen.dart';
import 'package:uzme/screens/studio/artist_form_screen.dart';
import 'package:uzme/screens/studio/add_artist_screen.dart';
import 'package:uzme/screens/studio/services_page.dart';
import 'package:uzme/screens/studio/service_form_screen.dart';
import 'package:uzme/screens/studio/rooms_page.dart';
import 'package:uzme/screens/studio/room_form_screen.dart';
import 'package:uzme/screens/studio/session_detail_screen.dart';
import 'package:uzme/screens/studio/studio_claim_screen.dart';
import 'package:uzme/screens/studio/manual_studio_form_screen.dart';
import 'package:uzme/screens/studio/payment_methods_screen.dart';
import 'package:uzme/screens/studio/team_management_screen.dart';
import 'package:uzme/screens/engineer/engineer_main_scaffold.dart';
import 'package:uzme/screens/engineer/session_tracking_screen.dart';
import 'package:uzme/screens/engineer/engineer_availability_screen.dart';
import 'package:uzme/screens/engineer/team_invitations_screen.dart';
import 'package:uzme/screens/artist/artist_main_scaffold.dart';
import 'package:uzme/screens/artist/artist_session_detail_screen.dart';
import 'package:uzme/screens/artist/session_request_screen.dart';
import 'package:uzme/screens/shared/notifications_screen.dart';
import 'package:uzme/screens/shared/profile_screen.dart';
import 'package:uzme/screens/shared/conversations_screen.dart';
import 'package:uzme/screens/shared/chat_screen.dart';
import 'package:uzme/screens/shared/conversation_settings_screen.dart';
import 'package:uzme/screens/shared/about_screen.dart';
import 'package:uzme/screens/shared/account_screen.dart';
import 'package:uzme/screens/shared/favorites_screen.dart';
import 'package:uzme/screens/shared/discover_map_screen.dart';
import 'package:uzme/screens/shared/network_screen.dart';
import 'package:uzme/screens/admin/feature_flags_list_screen.dart';
import 'package:uzme/screens/admin/pioneer_program_detail_screen.dart';
import 'package:uzme/screens/admin/pioneer_programs_list_screen.dart';
import 'package:uzme/screens/admin/studio_claims_screen.dart';
import 'package:uzme/screens/admin/subscription_tiers_screen.dart';
import 'package:uzme/screens/admin/stripe_config_screen.dart';
import 'package:uzme/screens/shared/digital_card_screen.dart';
import 'package:uzme/screens/shared/card_customization_screen.dart';
import 'package:uzme/widgets/card/qr_scanner_screen.dart';
import 'package:uzme/screens/shared/upgrade_screen.dart';
import 'package:uzme/screens/shared/ai_assistant_screen.dart';
import 'package:uzme/screens/studio/ai_settings_screen.dart';
import 'package:uzme/screens/studio/calendar_import_review_screen.dart';
import 'package:uzme/screens/dev/store_screenshots_page.dart';
import 'package:uzme/screens/onboarding/onboarding_screen.dart';
import 'package:uzme/screens/shared/device_sessions_screen.dart';
import 'package:uzme/screens/shared/pro/pro_profile_setup_screen.dart';
import 'package:uzme/screens/shared/pro/pro_bookings_received_screen.dart';
import 'package:uzme/screens/shared/pro/pro_discovery_screen.dart';
import 'package:uzme/screens/studio/stripe_connect_screen.dart';
import 'app_routes.dart';

/// GoRouter configuration for Use Me
class AppRouter {
  static GoRouter getRouter({GlobalKey<NavigatorState>? navigatorKey}) {
    return GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: AppRoutes.splash,
      debugLogDiagnostics: true,

      routes: [
        // Splash / Root
        GoRoute(
          path: AppRoutes.splash,
          builder: (context, state) => const SplashScreen(),
        ),

        // Authentication routes
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: AppRoutes.signup,
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: AppRoutes.lock,
          builder: (context, state) {
            // extra: {'auto': false} when navigating from a user-triggered
            // lock (Settings → Verrouiller) so we don't auto-fire Face ID
            // while the user is still staring at the screen.
            final extra = state.extra;
            final autoRun = !(extra is Map && extra['auto'] == false);
            return BiometricLockScreen(autoRun: autoRun);
          },
        ),

        // Onboarding
        GoRoute(
          path: AppRoutes.onboarding,
          builder: (context, state) {
            final role = state.uri.queryParameters['role'] ?? 'client';
            return OnboardingScreen(role: role);
          },
        ),

        // Studio (Admin) dashboard - Main scaffold with pages
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const StudioMainScaffold(initialPage: 0),
        ),
        GoRoute(
          path: AppRoutes.sessions,
          builder: (context, state) => const StudioMainScaffold(initialPage: 1),
        ),
        GoRoute(
          path: AppRoutes.artists,
          builder: (context, state) => const StudioMainScaffold(initialPage: 2),
        ),
        GoRoute(
          path: AppRoutes.settings,
          builder: (context, state) => const StudioMainScaffold(initialPage: 4),
        ),
        GoRoute(
          path: '/studio/messages',
          builder: (context, state) => const StudioMainScaffold(initialPage: 3),
        ),

        // Session routes
        GoRoute(
          path: AppRoutes.sessionAdd,
          builder: (context, state) => const SessionFormScreen(),
        ),
        GoRoute(
          path: AppRoutes.sessionDetail,
          builder: (context, state) {
            final sessionId = state.pathParameters['id']!;
            return SessionDetailScreen(sessionId: sessionId);
          },
        ),
        GoRoute(
          path: AppRoutes.sessionEdit,
          builder: (context, state) {
            final sessionId = state.pathParameters['id']!;
            return SessionFormScreen(sessionId: sessionId);
          },
        ),

        // Artist routes
        GoRoute(
          path: AppRoutes.artistAdd,
          builder: (context, state) => const AddArtistScreen(),
        ),
        GoRoute(
          path: AppRoutes.artistDetail,
          builder: (context, state) {
            final artistId = state.pathParameters['id']!;
            return ArtistFormScreen(artistId: artistId);
          },
        ),
        GoRoute(
          path: AppRoutes.artistEdit,
          builder: (context, state) {
            final artistId = state.pathParameters['id']!;
            return ArtistFormScreen(artistId: artistId);
          },
        ),

        // Service routes
        GoRoute(
          path: AppRoutes.services,
          builder: (context, state) => const ServicesPage(),
        ),
        GoRoute(
          path: AppRoutes.serviceAdd,
          builder: (context, state) => const ServiceFormScreen(),
        ),
        GoRoute(
          path: '/services/:id/edit',
          builder: (context, state) {
            final serviceId = state.pathParameters['id']!;
            return ServiceFormScreen(serviceId: serviceId);
          },
        ),

        // Room routes
        GoRoute(
          path: AppRoutes.rooms,
          builder: (context, state) => const RoomsPage(),
        ),
        GoRoute(
          path: AppRoutes.roomAdd,
          builder: (context, state) => const RoomFormScreen(),
        ),
        GoRoute(
          path: '/rooms/:id/edit',
          builder: (context, state) {
            final roomId = state.pathParameters['id']!;
            return RoomFormScreen(roomId: roomId);
          },
        ),

        // Engineer routes
        GoRoute(
          path: AppRoutes.engineerDashboard,
          builder: (context, state) => const EngineerMainScaffold(initialPage: 0),
        ),
        GoRoute(
          path: AppRoutes.engineerSessions,
          builder: (context, state) => const EngineerMainScaffold(initialPage: 1),
        ),
        GoRoute(
          path: AppRoutes.engineerSessionDetail,
          builder: (context, state) {
            final sessionId = state.pathParameters['id']!;
            return SessionTrackingScreen(sessionId: sessionId);
          },
        ),
        GoRoute(
          path: AppRoutes.engineerAvailability,
          builder: (context, state) => const EngineerAvailabilityScreen(),
        ),
        GoRoute(
          path: AppRoutes.engineerInvitations,
          redirect: (context, state) =>
              _featureGuard(context, FeatureFlagKeys.teamManagement.key),
          builder: (context, state) => const TeamInvitationsScreen(),
        ),

        // Artist portal routes
        GoRoute(
          path: AppRoutes.artistPortal,
          builder: (context, state) => const ArtistMainScaffold(initialPage: 0),
        ),
        GoRoute(
          path: '/artist/sessions',
          builder: (context, state) => const ArtistMainScaffold(initialPage: 1),
        ),
        GoRoute(
          path: '/artist/sessions/:id',
          builder: (context, state) {
            final sessionId = state.pathParameters['id']!;
            return ArtistSessionDetailScreen(sessionId: sessionId);
          },
        ),
        GoRoute(
          path: '/artist/request',
          builder: (context, state) {
            final studioId = state.uri.queryParameters['studioId'];
            final studioName = state.uri.queryParameters['studioName'];
            return SessionRequestScreen(
              studioId: studioId,
              studioName: studioName,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.artistSettings,
          builder: (context, state) => const ArtistMainScaffold(initialPage: 4),
        ),
        GoRoute(
          path: '/artist/favorites',
          builder: (context, state) => const ArtistMainScaffold(initialPage: 2),
        ),

        // Profile & Settings
        GoRoute(
          path: AppRoutes.profile,
          builder: (context, state) => const ProfileScreen(),
        ),

        // Pro marketplace — setup, discover, bookings — all under
        // pro_profile flag.
        GoRoute(
          path: AppRoutes.proProfileSetup,
          redirect: (context, state) =>
              _featureGuard(context, FeatureFlagKeys.proProfile.key),
          builder: (context, state) => const ProProfileSetupScreen(),
        ),
        GoRoute(
          path: AppRoutes.proDiscovery,
          redirect: (context, state) =>
              _featureGuard(context, FeatureFlagKeys.proProfile.key),
          builder: (context, state) => const ProDiscoveryScreen(),
        ),
        GoRoute(
          path: AppRoutes.proBookingsReceived,
          redirect: (context, state) =>
              _featureGuard(context, FeatureFlagKeys.proProfile.key),
          builder: (context, state) => const ProBookingsReceivedScreen(),
        ),

        // Team management — gated under team_management.
        GoRoute(
          path: AppRoutes.teamManagement,
          redirect: (context, state) =>
              _featureGuard(context, FeatureFlagKeys.teamManagement.key),
          builder: (context, state) => const TeamManagementScreen(),
        ),

        // Studio claim
        GoRoute(
          path: AppRoutes.studioClaim,
          builder: (context, state) => const StudioClaimScreen(),
        ),
        GoRoute(
          path: AppRoutes.studioCreate,
          builder: (context, state) => const ManualStudioFormScreen(),
        ),
        GoRoute(
          path: AppRoutes.paymentMethods,
          builder: (context, state) => const PaymentMethodsScreen(),
        ),

        // Admin (SuperAdmin) routes
        GoRoute(
          path: AppRoutes.studioClaims,
          builder: (context, state) => const StudioClaimsScreen(),
        ),
        GoRoute(
          path: AppRoutes.pioneerPrograms,
          builder: (context, state) => const PioneerProgramsListScreen(),
        ),
        GoRoute(
          path: '/admin/pioneer/:id',
          builder: (context, state) => PioneerProgramDetailScreen(
            programId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: AppRoutes.featureFlags,
          builder: (context, state) => const FeatureFlagsListScreen(),
        ),
        GoRoute(
          path: '/admin/subscription-tiers',
          builder: (context, state) => const SubscriptionTiersScreen(),
        ),
        GoRoute(
          path: '/admin/stripe-config',
          builder: (context, state) => const StripeConfigScreen(),
        ),

        // Subscription / Upgrade
        GoRoute(
          path: '/upgrade',
          builder: (context, state) => const UpgradeScreen(),
        ),
        // Digital card + customization + QR scanner — all gated under
        // a single flag. Each route checks individually so deep-linking
        // any of them is blocked when the feature is off.
        GoRoute(
          path: AppRoutes.digitalCard,
          redirect: (context, state) =>
              _featureGuard(context, FeatureFlagKeys.digitalCard.key),
          builder: (context, state) => const DigitalCardScreen(),
        ),
        GoRoute(
          path: AppRoutes.cardCustomize,
          redirect: (context, state) =>
              _featureGuard(context, FeatureFlagKeys.digitalCard.key),
          builder: (context, state) => const CardCustomizationScreen(),
        ),
        GoRoute(
          path: AppRoutes.qrScanner,
          redirect: (context, state) =>
              _featureGuard(context, FeatureFlagKeys.digitalCard.key),
          builder: (context, state) => const QrScannerScreen(),
        ),

        // Notifications
        GoRoute(
          path: AppRoutes.notifications,
          builder: (context, state) => const NotificationsScreen(),
        ),

        // Messaging
        GoRoute(
          path: AppRoutes.conversations,
          builder: (context, state) => const ConversationsScreen(),
        ),
        GoRoute(
          path: AppRoutes.chat,
          builder: (context, state) {
            final conversationId = state.pathParameters['id']!;
            return ChatScreen(conversationId: conversationId);
          },
        ),
        GoRoute(
          path: AppRoutes.conversationSettings,
          builder: (context, state) {
            final conversationId = state.pathParameters['id']!;
            return ConversationSettingsScreen(conversationId: conversationId);
          },
        ),

        // About
        GoRoute(
          path: AppRoutes.about,
          builder: (context, state) => const AboutScreen(),
        ),

        // Account
        GoRoute(
          path: AppRoutes.account,
          builder: (context, state) => const AccountScreen(),
        ),

        // Favorites
        GoRoute(
          path: AppRoutes.favorites,
          builder: (context, state) => const FavoritesScreen(),
        ),

        // Stripe Connect onboarding (Studio) — sensitive vis-à-vis
        // App Review Apple, defaults to disabled until rollout.
        GoRoute(
          path: AppRoutes.stripeConnect,
          redirect: (context, state) => _featureGuard(
              context, FeatureFlagKeys.stripeConnectOnboarding.key),
          builder: (context, state) => const StripeConnectScreen(),
        ),

        // Discover map (Studio & Engineer)
        GoRoute(
          path: AppRoutes.discoverMap,
          builder: (context, state) => const DiscoverMapScreen(),
        ),

        // Network
        GoRoute(
          path: AppRoutes.network,
          builder: (context, state) => const NetworkScreen(),
        ),

        // AI Assistant — gated by ai_assistant flag (route-level
        // defense-in-depth, in addition to the entry tile in
        // conversations_screen). Disabled flag → bounce to home.
        GoRoute(
          path: AppRoutes.aiAssistant,
          redirect: (context, state) =>
              _featureGuard(context, FeatureFlagKeys.aiAssistant.key),
          builder: (context, state) => const AIAssistantScreen(),
        ),
        GoRoute(
          path: AppRoutes.aiSettings,
          redirect: (context, state) =>
              _featureGuard(context, FeatureFlagKeys.aiAssistantPro.key),
          builder: (context, state) {
            final studioId = state.uri.queryParameters['studioId'] ?? '';
            return AISettingsScreen(studioId: studioId);
          },
        ),

        // Calendar Import Review — child of the calendar_google_sync
        // feature; useless without the connection.
        GoRoute(
          path: AppRoutes.calendarImportReview,
          redirect: (context, state) =>
              _featureGuard(context, FeatureFlagKeys.calendarGoogleSync.key),
          builder: (context, state) {
            final userId = state.uri.queryParameters['userId'] ?? '';
            return CalendarImportReviewScreen(userId: userId);
          },
        ),

        // Upgrade
        GoRoute(
          path: AppRoutes.upgrade,
          builder: (context, state) => const UpgradeScreen(),
        ),

        // Device Sessions / Security
        GoRoute(
          path: AppRoutes.connectedDevices,
          builder: (context, state) => const LocalDeviceSessionsScreen(),
        ),

        // Dev tools (debug only)
        if (kDebugMode)
          GoRoute(
            path: '/dev/screenshots',
            builder: (context, state) => const StoreScreenshotsPage(),
          ),
      ],

      // Error handling
      errorBuilder: (context, state) {
        return _NotFoundScreen(uri: state.uri.toString());
      },
    );
  }

  /// Get the home route based on user role
  static String getHomeRouteForUser(BaseUser user) {
    final appUser = user as AppUser;

    if (appUser.isSuperAdmin || appUser.isStudio) {
      return AppRoutes.home;
    } else if (appUser.isEngineer) {
      return AppRoutes.engineerDashboard;
    } else {
      return AppRoutes.artistPortal;
    }
  }
}

/// Not found screen with role-aware redirect
class _NotFoundScreen extends StatelessWidget {
  final String uri;

  const _NotFoundScreen({required this.uri});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const FaIcon(FontAwesomeIcons.circleExclamation, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Page non trouvée', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(uri, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (authState is AuthAuthenticatedState) {
                      context.go(AppRouter.getHomeRouteForUser(authState.user));
                    } else {
                      context.go(AppRoutes.login);
                    }
                  },
                  child: const Text('Retour à l\'accueil'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Returns a redirect path when [flagKey] is **not** enabled for the
/// current user — used by `redirect:` on gated GoRoutes. Returning null
/// means "allow navigation". The redirect target is the user's home
/// route if authenticated, otherwise login.
///
/// Note: relies on `featureFlagsService` having received its first
/// snapshot (initialized at boot in `main.dart`). Before the snapshot
/// lands, every flag resolves to `false`, so the redirect would block
/// AI routes for a brief moment after cold start. Acceptable trade-off
/// vs leaving a gated feature reachable during boot.
String? _featureGuard(BuildContext context, String flagKey) {
  final authState = context.read<AuthBloc>().state;
  final user = authState is AuthAuthenticatedState
      ? authState.user as AppUser?
      : null;
  if (featureFlagsService.isEnabled(user, flagKey)) {
    return null;
  }
  if (authState is AuthAuthenticatedState) {
    return AppRouter.getHomeRouteForUser(authState.user);
  }
  return AppRoutes.login;
}
