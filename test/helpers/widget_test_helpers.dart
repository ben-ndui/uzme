import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smoothandesign_package/smoothandesign.dart';
import 'package:uzme/core/blocs/blocs_exports.dart';
import 'package:uzme/core/constants/feature_flag_keys.dart';
import 'package:uzme/core/models/app_user.dart';
import 'package:uzme/core/models/feature_flag.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/main.dart' show featureFlagsService;

/// Seeds the global [featureFlagsService] with every catalogued flag
/// rolled out as `enabled`. Use in the `setUp` of any widget test that
/// renders a UI gated by `featureFlagsService.isEnabled(...)`.
///
/// Why a helper: the service is a top-level singleton wired from
/// `main.dart` and would otherwise return `false` for every flag in
/// tests (no Firestore snapshot has landed). Tests that explicitly want
/// a feature off can call [featureFlagsService.setFlagsForTesting]
/// directly with a custom map.
void enableAllFeatureFlagsForTesting() {
  featureFlagsService.setFlagsForTesting({
    for (final spec in FeatureFlagKeys.all)
      spec.key: FeatureFlag(
        key: spec.key,
        title: spec.title,
        description: spec.description,
        rollout: FeatureRollout.enabled,
      ),
  });
}

/// Mock BLoCs for widget testing.
class MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class MockProProfileBloc
    extends MockBloc<ProProfileEvent, ProProfileState>
    implements ProProfileBloc {}

class MockMessagingBloc
    extends MockBloc<MessagingEvent, MessagingState>
    implements MessagingBloc {}

class MockSessionBloc extends MockBloc<SessionEvent, SessionState>
    implements SessionBloc {}

class MockFavoriteBloc extends MockBloc<FavoriteEvent, FavoriteState>
    implements FavoriteBloc {}

class MockNetworkBloc extends MockBloc<NetworkEvent, NetworkState>
    implements NetworkBloc {}

/// Creates a test [AppUser] with optional [proProfile].
AppUser testAppUser({
  String uid = 'test-uid',
  String name = 'Test User',
  String email = 'test@test.com',
  String role = 'client',
  Map<String, dynamic>? proProfileMap,
}) {
  return AppUser.fromMap({
    'uid': uid,
    'name': name,
    'email': email,
    'role': role,
    if (proProfileMap != null) 'proProfile': proProfileMap,
  });
}

/// Wraps a [child] widget with MaterialApp, localizations, and BlocProviders.
///
/// Usage:
/// ```dart
/// await tester.pumpWidget(buildTestApp(
///   authBloc: mockAuthBloc,
///   child: const MyWidget(),
/// ));
/// ```
Widget buildTestApp({
  required Widget child,
  AuthBloc? authBloc,
  ProProfileBloc? proProfileBloc,
  MessagingBloc? messagingBloc,
  SessionBloc? sessionBloc,
  FavoriteBloc? favoriteBloc,
  NetworkBloc? networkBloc,
  Locale locale = const Locale('en'),
  List<BlocProvider>? extraProviders,
}) {
  final providers = <BlocProvider>[
    if (authBloc != null) BlocProvider<AuthBloc>.value(value: authBloc),
    if (proProfileBloc != null)
      BlocProvider<ProProfileBloc>.value(value: proProfileBloc),
    if (messagingBloc != null)
      BlocProvider<MessagingBloc>.value(value: messagingBloc),
    if (sessionBloc != null)
      BlocProvider<SessionBloc>.value(value: sessionBloc),
    if (favoriteBloc != null)
      BlocProvider<FavoriteBloc>.value(value: favoriteBloc),
    if (networkBloc != null)
      BlocProvider<NetworkBloc>.value(value: networkBloc),
    ...?extraProviders,
  ];

  final app = MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: child,
  );

  if (providers.isEmpty) return app;

  return MultiBlocProvider(
    providers: providers,
    child: app,
  );
}
