import 'package:flutter_test/flutter_test.dart';
import 'package:smoothandesign_package/smoothandesign.dart';
import 'package:uzme/core/models/app_user.dart';
import 'package:uzme/routing/app_routes.dart';
import 'package:uzme/routing/router.dart';

AppUser _user({
  String uid = 'u1',
  bool isFirstTime = false,
  BaseUserRole role = BaseUserRole.client,
}) {
  return AppUser(
    uid: uid,
    email: '$uid@test.com',
    role: role,
    isFirstTime: isFirstTime,
  );
}

void main() {
  group('AppRouter.routeForAuthenticatedUser', () {
    test('first-time client → /onboarding?role=client', () {
      final route = AppRouter.routeForAuthenticatedUser(
        _user(isFirstTime: true, role: BaseUserRole.client),
      );
      expect(route, '${AppRoutes.onboarding}?role=client');
    });

    test('first-time studio (admin) → /onboarding?role=admin', () {
      final route = AppRouter.routeForAuthenticatedUser(
        _user(isFirstTime: true, role: BaseUserRole.admin),
      );
      expect(route, '${AppRoutes.onboarding}?role=admin');
    });

    test('first-time engineer (worker) → /onboarding?role=worker', () {
      final route = AppRouter.routeForAuthenticatedUser(
        _user(isFirstTime: true, role: BaseUserRole.worker),
      );
      expect(route, '${AppRoutes.onboarding}?role=worker');
    });

    test('returning client → artist portal', () {
      final route = AppRouter.routeForAuthenticatedUser(
        _user(isFirstTime: false, role: BaseUserRole.client),
      );
      expect(route, AppRoutes.artistPortal);
    });

    test('returning studio → home', () {
      final route = AppRouter.routeForAuthenticatedUser(
        _user(isFirstTime: false, role: BaseUserRole.admin),
      );
      expect(route, AppRoutes.home);
    });

    test('returning engineer → engineer dashboard', () {
      final route = AppRouter.routeForAuthenticatedUser(
        _user(isFirstTime: false, role: BaseUserRole.worker),
      );
      expect(route, AppRoutes.engineerDashboard);
    });
  });

  group('AppRouter.getHomeRouteForUser', () {
    test('routes are role-correct (regression guard)', () {
      // The function ignores isFirstTime — only used by paths that
      // already know the user shouldn't see onboarding.
      expect(
        AppRouter.getHomeRouteForUser(_user(role: BaseUserRole.admin)),
        AppRoutes.home,
      );
      expect(
        AppRouter.getHomeRouteForUser(_user(role: BaseUserRole.worker)),
        AppRoutes.engineerDashboard,
      );
      expect(
        AppRouter.getHomeRouteForUser(_user(role: BaseUserRole.client)),
        AppRoutes.artistPortal,
      );
    });
  });
}
