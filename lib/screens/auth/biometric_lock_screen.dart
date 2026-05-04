import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:smoothandesign_package/smoothandesign.dart';
import 'package:uzme/config/useme_theme.dart';
import 'package:uzme/main.dart' show biometricService;
import 'package:uzme/routing/app_routes.dart';
import 'package:uzme/routing/router.dart';

/// Shown when AuthBloc is in [AuthLockedState] — Firebase tokens are still
/// alive but the user must pass a biometric prompt before reaching the
/// dashboard. On success → UnlockAppEvent. On user-driven fallback →
/// SignOutEvent (full logout, returns to /login).
class BiometricLockScreen extends StatefulWidget {
  const BiometricLockScreen({super.key});

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> {
  bool _isPrompting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runBiometric());
  }

  Future<void> _runBiometric() async {
    if (_isPrompting || !mounted) return;
    setState(() => _isPrompting = true);
    try {
      final ok = await biometricService.authenticate(
        reason: 'Déverrouillez UZME avec Face ID, Touch ID ou votre empreinte.',
      );
      if (!mounted) return;
      if (ok) {
        context.read<AuthBloc>().add(const UnlockAppEvent());
      }
    } finally {
      if (mounted) setState(() => _isPrompting = false);
    }
  }

  void _signOutCompletely() {
    context.read<AuthBloc>().add(const SignOutEvent());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticatedState) {
            context.go(AppRouter.getHomeRouteForUser(state.user));
          } else if (state is AuthUnauthenticatedState) {
            context.go(AppRoutes.login);
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          buildWhen: (prev, curr) =>
              curr is AuthLockedState ||
              curr is AuthLoadingState ||
              curr is AuthAuthenticatedState,
          builder: (context, state) {
            final user = state is AuthLockedState ? state.user : null;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    _Avatar(photoURL: user?.photoURL),
                    const SizedBox(height: 16),
                    Text(
                      user?.displayName ?? user?.name ?? 'Utilisateur',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                    ),
                    const SizedBox(height: 48),
                    Text(
                      'UZME est verrouillé',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: UseMeTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Authentifiez-vous pour accéder à votre dashboard.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isPrompting ? null : _runBiometric,
                        icon: const FaIcon(FontAwesomeIcons.fingerprint),
                        label: Text(_isPrompting ? 'Authentification…' : 'Déverrouiller'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _signOutCompletely,
                      child: const Text('Se déconnecter complètement'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? photoURL;
  const _Avatar({this.photoURL});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 48,
      backgroundColor: UseMeTheme.primaryColor.withValues(alpha: 0.15),
      backgroundImage: photoURL != null && photoURL!.isNotEmpty ? NetworkImage(photoURL!) : null,
      child: photoURL == null || photoURL!.isEmpty
          ? const FaIcon(FontAwesomeIcons.user, size: 36)
          : null,
    );
  }
}
