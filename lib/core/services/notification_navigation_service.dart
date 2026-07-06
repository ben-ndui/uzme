import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import 'package:uzme/core/models/app_user.dart';
import 'package:uzme/main.dart' show useMeAuthService;
import 'package:uzme/routing/app_routes.dart';

/// Service for handling notification navigation in Use Me.
class NotificationNavigationService {
  static final NotificationNavigationService _instance =
      NotificationNavigationService._internal();
  factory NotificationNavigationService() => _instance;
  NotificationNavigationService._internal();

  GoRouter? _router;

  /// Tant que le splash n'a pas résolu l'auth et navigué, un push de
  /// notification serait écrasé par son context.go() différé (app tuée →
  /// tap sur une notif : le message initial est rejoué immédiatement,
  /// AVANT la navigation du splash). On mémorise la route et le splash
  /// la consomme après sa propre navigation.
  bool _appReady = false;
  String? _pendingRoute;

  void setRouter(GoRouter router) {
    _router = router;
  }

  /// À appeler par le splash après avoir navigué vers une destination
  /// authentifiée : rejoue la navigation de notification en attente.
  void consumePendingRoute() {
    _appReady = true;
    final pending = _pendingRoute;
    _pendingRoute = null;
    if (pending != null) _router?.push(pending);
  }

  /// À appeler par le splash quand l'utilisateur n'est PAS authentifié
  /// (login/lock) : la destination de la notif serait inaccessible.
  void clearPendingRoute() {
    _appReady = true;
    _pendingRoute = null;
  }

  /// Navigate based on notification data
  void handleNotificationTap(RemoteMessage message) {
    if (_router == null) return;

    final route = getRouteForNotification(message.data);
    if (route == null) return;
    if (!_appReady) {
      _pendingRoute = route;
      return;
    }
    _router!.push(route);
  }

  /// Get route for notification data
  String? getRouteForNotification(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    switch (type) {
      case 'new_message':
        final conversationId = data['conversationId'];
        if (conversationId != null) {
          return '/conversations/$conversationId';
        }
        return AppRoutes.conversations;

      case 'pro_booking_request':
        return AppRoutes.proBookingsReceived;

      case 'session_assigned':
      case 'session_updated':
        // Route selon le RÔLE : '/sessions/{id}' est l'écran ADMIN studio
        // (actions confirmer/annuler) — un ingénieur qui tapait sa notif
        // « session assignée » atterrissait dessus au lieu de son écran
        // de suivi, et un artiste sur un écran interdit.
        final sessionId = data['sessionId'];
        final user = useMeAuthService.appUser;
        if (sessionId != null) {
          if (user != null && user.isEngineer) {
            return '/engineer/sessions/$sessionId';
          }
          if (user != null && !user.isStudio && !user.isSuperAdmin) {
            return '/artist/sessions/$sessionId';
          }
          return '/sessions/$sessionId';
        }
        return _sessionsListRouteForRole(user);

      case 'booking_confirmed':
      case 'booking_updated':
        // Les routes '/bookings/*' n'existent pas dans le router (écran
        // 404) : renvoyer vers la liste de sessions du rôle.
        return _sessionsListRouteForRole(useMeAuthService.appUser);

      case 'team_invitation':
        return AppRoutes.engineerInvitations;

      default:
        return AppRoutes.notifications;
    }
  }

  /// Liste de sessions adaptée au rôle courant (fallback des notifs
  /// session/booking sans ID exploitable).
  String _sessionsListRouteForRole(AppUser? user) {
    if (user == null) return AppRoutes.notifications;
    if (user.isEngineer) return AppRoutes.engineerSessions;
    if (user.isStudio || user.isSuperAdmin) return AppRoutes.sessions;
    return '/artist/sessions';
  }

  /// Navigate to a specific route
  void navigateTo(String route) {
    _router?.push(route);
  }
}
