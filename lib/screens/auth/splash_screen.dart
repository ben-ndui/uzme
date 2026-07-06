import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:smoothandesign_package/smoothandesign.dart';
import 'package:uzme/config/useme_theme.dart';
import 'package:uzme/core/models/app_user.dart';
import 'package:uzme/routing/app_routes.dart';
import 'package:uzme/routing/router.dart';
import 'package:uzme/core/services/notification_navigation_service.dart';
import 'package:uzme/core/utils/app_logger.dart';

/// Splash screen shown on app launch
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _hasNavigated = false;
  bool _isCheckingAuth = false;
  int _authRetries = 0;

  /// Watchdog : nombre max de retries de 500ms avant d'abandonner l'attente
  /// de l'AuthBloc et d'envoyer l'utilisateur sur /login. Sans borne, un
  /// CheckAuthEvent qui ne se résout pas gèle le splash indéfiniment
  /// (rejet App Review Guideline 2.1(a)). ~24 × 500ms = 12s après l'anim.
  static const int _maxAuthRetries = 24;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5)),
    );

    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reset navigation state on hot reload and check auth
    _hasNavigated = false;
    _isCheckingAuth = false;
    _authRetries = 0;
    _scheduleAuthCheck();
  }

  void _scheduleAuthCheck() {
    if (_isCheckingAuth) return;
    _isCheckingAuth = true;

    // Wait for animation to complete, then check auth
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      _navigateBasedOnAuth();
    });
  }

  void _navigateBasedOnAuth() {
    if (_hasNavigated || !mounted) return;

    final state = context.read<AuthBloc>().state;

    // If still loading, wait and retry — bounded by the watchdog
    if (state is AuthInitialState || state is AuthLoadingState) {
      if (_authRetries >= _maxAuthRetries) {
        _hasNavigated = true;
        appLog('🚀 Splash: auth watchdog fired — fallback to /login');
        context.go(AppRoutes.login);
        return;
      }
      _authRetries++;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _navigateBasedOnAuth();
      });
      return;
    }

    _hasNavigated = true;

    if (state is AuthLockedState) {
      // Tokens still alive — gate the dashboard behind biometric.
      appLog('🚀 Splash: Navigating to lock screen');
      NotificationNavigationService().clearPendingRoute();
      context.go(AppRoutes.lock);
      return;
    }

    if (state is AuthAuthenticatedState) {
      final user = state.user as AppUser;
      appLog('🚀 Splash: user.isFirstTime = ${user.isFirstTime}');
      appLog('🚀 Splash: user.role = ${user.role}');
      final route = AppRouter.routeForAuthenticatedUser(user);
      appLog('🚀 Splash: Navigating to $route');
      context.go(route);
      // Rejoue le tap de notification arrivé pendant le boot (app tuée) —
      // sans ça, le push initial était écrasé par le context.go ci-dessus.
      NotificationNavigationService().consumePendingRoute();
    } else {
      NotificationNavigationService().clearPendingRoute();
      context.go(AppRoutes.login);
    }
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // When auth state changes, try to navigate
        _navigateBasedOnAuth();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Container(
          color: Colors.white,
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title
                        Text(
                          'UZME',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: UseMeTheme.primaryColor,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Studio Sessions',
                          style: TextStyle(
                            fontSize: 16,
                            color: UseMeTheme.primaryColor.withValues(alpha: 0.7),
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
