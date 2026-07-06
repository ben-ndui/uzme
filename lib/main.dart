import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uzme/firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:smoothandesign_auth_biometric/smoothandesign_auth_biometric.dart'
    hide RecentAccountsService;
import 'package:smoothandesign_package/smoothandesign.dart';
import 'package:uzme/config/useme_theme.dart';
import 'package:uzme/core/blocs/blocs_exports.dart';
import 'package:uzme/core/localization/sango_material_localizations.dart';
import 'package:uzme/core/models/app_user.dart';
import 'package:uzme/core/services/auth_service.dart';
import 'package:uzme/core/services/deep_link_service.dart';
import 'package:uzme/core/services/notification_navigation_service.dart';
import 'package:uzme/core/services/feature_flags_service.dart';
import 'package:uzme/core/services/notification_service.dart';
import 'package:uzme/core/services/pioneer_service.dart';
import 'package:uzme/core/services/recent_accounts_service.dart';
import 'package:uzme/core/utils/app_logger.dart';
import 'package:uzme/core/utils/crashlytics_bloc_observer.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/routing/router.dart';
import 'package:uzme/widgets/feature_flags/feature_announcement_watcher.dart';

/// Global navigator key for notification navigation
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Service d'authentification global.
final useMeAuthService = UseMeAuthService();

/// Service de préférences global.
final preferencesService = BasePreferencesService();

/// Service de comptes récents global.
final recentAccountsService = RecentAccountsService();

/// Service de biométrie global (Face ID / Touch ID / empreinte).
final biometricService = BiometricService();

/// Service de notifications global.
final notificationService = UseMeNotificationService.instance;

/// Service de deep links global.
final deepLinkService = DeepLinkService();

/// Service de sessions d'appareils global.
final deviceSessionService = BaseDeviceSessionService();

/// Pioneer service global — call les Cloud Functions du module pioneer
/// (création/distribution programmes, recordUserActive).
final pioneerService = PioneerService();

/// Feature flags service global — résout dynamiquement quelles features
/// sont visibles selon le rollout state (disabled / pioneer / beta /
/// enabled). Initialisé au boot pour que les UIs aient un snapshot dès
/// le premier render.
final featureFlagsService = FeatureFlagsService();

/// CalendarBloc global (needed for deep link callbacks).
late CalendarBloc globalCalendarBloc;

/// Boot-time logger visible in release: print() goes to stdout (terminal of
/// `flutter run --release`) and to iOS unified logging (Console.app).
/// Also pushed as a Crashlytics breadcrumb so it surfaces in any crash report
/// once Firebase is initialized.
void _bootLog(String message) {
  // ignore: avoid_print
  print('UZME_BOOT: $message');
  developer.log(message, name: 'uzme.boot');
  try {
    FirebaseCrashlytics.instance.log('boot: $message');
  } catch (_) {}
}

void main() {
  runZonedGuarded<Future<void>>(
    () async {
      _bootLog('start');
      WidgetsFlutterBinding.ensureInitialized();
      _bootLog('bindings');

      try {
        await dotenv.load(fileName: 'assets/.env');
        _bootLog('dotenv:ok');
      } catch (_) {
        _bootLog('dotenv:skipped');
      }

      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        _bootLog('firebase:ok');
      } catch (e, st) {
        _bootLog('firebase:FAIL: $e');
        _bootLog('firebase:STACK: $st');
        rethrow;
      }

      try {
        SmoothFirebase.initializeWithDefault();
        _bootLog('smoothfirebase:ok');
      } catch (e, st) {
        _bootLog('smoothfirebase:FAIL: $e');
        _bootLog('smoothfirebase:STACK: $st');
        rethrow;
      }

      await _purgeStaleKeychainOnFreshInstall();

      // Subscribe to feature_flags collection — runs in background, won't
      // block boot. UIs that need to gate on a flag at first render
      // should `await featureFlagsService.whenReady()` themselves.
      featureFlagsService.initialize();
      _bootLog('featureflags:subscribed');

      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      Bloc.observer = CrashlyticsBlocObserver();
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
      _bootLog('errorhandlers:ok');

      try {
        await initializeDateFormatting('fr_FR', null);
        _bootLog('dateformat:ok');
      } catch (e, st) {
        _bootLog('dateformat:FAIL: $e');
        _bootLog('dateformat:STACK: $st');
      }

      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      _bootLog('orientations:ok');

      try {
        await recentAccountsService.load();
        _bootLog('recentaccounts:ok');
      } catch (e, st) {
        _bootLog('recentaccounts:FAIL: $e');
        _bootLog('recentaccounts:STACK: $st');
      }

      globalCalendarBloc = CalendarBloc();
      _bootLog('calendarbloc:ok');

      _bootLog('about-to-runApp');
      runApp(const UseMeApp());
      _bootLog('runApp-returned');

      _initializeNotificationListeners();
      _initializeDeepLinks();
    },
    (error, stack) {
      _bootLog('ZONE-ERROR: $error');
      _bootLog('ZONE-STACK: $stack');
      try {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      } catch (_) {}
    },
  );
}

/// Sur iOS, le keychain (session Firebase Auth) et le secure storage (flag
/// de verrouillage biométrique, tokens) survivent à la désinstallation de
/// l'app. Une session périmée héritée d'une installation précédente envoie
/// le boot dans le chemin authentifié — reload Firestore d'un user qui
/// n'existe plus, token révoqué — et peut geler le splash indéfiniment
/// (rejet App Review Guideline 2.1(a), les devices de review sont réutilisés).
/// À la première exécution après installation, on repart d'un état propre.
Future<void> _purgeStaleKeychainOnFreshInstall() async {
  const hasLaunchedKey = 'uzme_has_launched_before';
  try {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(hasLaunchedKey) ?? false) return;
    // Les SharedPreferences (NSUserDefaults) sont effacées à la
    // désinstallation, contrairement au keychain : des prefs non vides
    // signifient une mise à jour d'app, pas une réinstallation — on ne
    // déconnecte pas les utilisateurs existants dans ce cas.
    final isFreshInstall = prefs.getKeys().isEmpty;
    if (isFreshInstall) {
      await FirebaseAuth.instance.signOut();
      await const FlutterSecureStorage().deleteAll();
      _bootLog('freshinstall:purged');
    }
    await prefs.setBool(hasLaunchedKey, true);
  } catch (e) {
    _bootLog('freshinstall:FAIL: $e');
  }
}

/// Create device session for the authenticated user.
Future<void> _createDeviceSession(String userId) async {
  try {
    // Get FCM token for push notifications
    final fcmToken = notificationService.fcmToken;

    // Create or update the device session
    final session = await deviceSessionService.createSession(
      userId: userId,
      fcmToken: fcmToken,
      appVersion: '1.0.0',
    );
    appLog('Device session created for user: $userId');

    // Start listening for session revocation
    _startSessionRevocationListener(session.id);
  } catch (e) {
    appLog('Failed to create device session: $e');
  }
}

/// Subscription for session revocation listener.
StreamSubscription<bool>? _sessionRevocationSubscription;

/// Start listening for session revocation (remote logout).
void _startSessionRevocationListener(String sessionId) {
  _sessionRevocationSubscription?.cancel();
  _sessionRevocationSubscription = deviceSessionService.watchSessionRevoked(sessionId).listen(
    (isRevoked) {
      if (isRevoked) {
        appLog('Session revoked remotely, forcing logout...');
        _handleRemoteLogout();
      }
    },
    onError: (e) => appLog('Session revocation listener error: $e'),
  );
}

/// Handle remote logout when session is revoked.
void _handleRemoteLogout() {
  _sessionRevocationSubscription?.cancel();
  _sessionRevocationSubscription = null;

  final context = rootNavigatorKey.currentContext;
  if (context != null) {
    // Show message to user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vous avez été déconnecté depuis un autre appareil'),
        duration: Duration(seconds: 4),
      ),
    );

    // Trigger logout
    context.read<AuthBloc>().add(const SignOutEvent());
  }
}

/// Initialize deep link handling
Future<void> _initializeDeepLinks() async {
  try {
    // Set callback for calendar OAuth result
    deepLinkService.onCalendarCallback = (success, error) {
      appLog('Calendar OAuth callback: success=$success, error=$error');

      if (success) {
        // Get current user ID and reload calendar status
        final context = rootNavigatorKey.currentContext;
        if (context != null) {
          try {
            final authState = context.read<AuthBloc>().state;
            if (authState is AuthAuthenticatedState) {
              globalCalendarBloc.add(
                LoadCalendarStatusEvent(userId: authState.user.uid),
              );
            }
          } catch (e) {
            appLog('Error reloading calendar status: $e');
          }
        }
      }
    };

    await deepLinkService.initialize();
  } catch (e) {
    appLog('Deep link init error: $e');
  }
}

/// Initialize notification listeners - non-blocking
Future<void> _initializeNotificationListeners() async {
  try {
    final navService = NotificationNavigationService();

    await notificationService.initialize(
      onNotificationTap: (message) {
        navService.handleNotificationTap(message);
      },
      onForegroundMessage: (message) {
        final context = rootNavigatorKey.currentContext;
        if (context != null) {
          InAppNotificationBanner.show(
            context,
            message,
            onTap: () => navService.handleNotificationTap(message),
          );
        }
      },
    );
  } catch (e) {
    appLog('Notification init error: $e');
  }
}

class UseMeApp extends StatefulWidget {
  const UseMeApp({super.key});

  @override
  State<UseMeApp> createState() => _UseMeAppState();
}

class _UseMeAppState extends State<UseMeApp> {
  late final _router = AppRouter.getRouter(navigatorKey: rootNavigatorKey);

  @override
  void initState() {
    super.initState();
    // Set router for notification navigation
    NotificationNavigationService().setRouter(_router);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Theme BLoC from package
        BlocProvider<ThemeBloc>(
          create: (_) => ThemeBloc(preferencesService: preferencesService)
            ..add(const LoadThemeEvent()),
        ),
        // Locale BLoC
        BlocProvider<LocaleBloc>(
          create: (_) => LocaleBloc()..add(const LoadLocaleEvent()),
        ),
        // Auth BLoC from package with Use Me service
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(authService: useMeAuthService)
            ..add(const CheckAuthEvent()),
        ),
        // Use Me specific BLoCs
        BlocProvider<SessionBloc>(create: (_) => SessionBloc()),
        BlocProvider<ArtistBloc>(create: (_) => ArtistBloc()),
        BlocProvider<ServiceBloc>(create: (_) => ServiceBloc()),
        BlocProvider<StudioRoomBloc>(create: (_) => StudioRoomBloc()),
        BlocProvider<BookingBloc>(create: (_) => BookingBloc()),
        BlocProvider<MessagingBloc>(create: (_) => MessagingBloc()),
        BlocProvider<FavoriteBloc>(create: (_) => FavoriteBloc()),
        BlocProvider<ProProfileBloc>(create: (_) => ProProfileBloc()),
        BlocProvider<NetworkBloc>(create: (_) => NetworkBloc()),
        BlocProvider<CardConfigBloc>(create: (_) => CardConfigBloc()),
        BlocProvider<CalendarBloc>.value(value: globalCalendarBloc),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return BlocBuilder<LocaleBloc, LocaleState>(
            builder: (context, localeState) {
              return BlocListener<AuthBloc, AuthState>(
                listenWhen: (prev, curr) {
                  // Skip transitions toward AuthLockedState — locking is a soft
                  // gate, not a sign-out. Keep the FCM token, calendar bloc,
                  // device session, etc. alive so notifications keep flowing
                  // and the unlock is instant.
                  if (curr is AuthLockedState) return false;
                  final wasAuth = prev is AuthAuthenticatedState;
                  final isAuth = curr is AuthAuthenticatedState;
                  return wasAuth != isAuth;
                },
                listener: (context, state) async {
                  if (state is AuthAuthenticatedState) {
                    final user = state.user;

                    // Crashlytics — identify user for crash reports
                    FirebaseCrashlytics.instance.setUserIdentifier(user.uid);
                    FirebaseCrashlytics.instance.setCustomKey('role', user.role.name);
                    FirebaseCrashlytics.instance.log('User authenticated: ${user.uid} (${user.role.name})');

                    // User logged in: set userId for notification token
                    notificationService.setUserId(user.uid);

                    // Create device session
                    _createDeviceSession(user.uid);

                    // Record activity — bumps activeDaysCount once per UTC
                    // day (Pioneer engagement metric). Fire-and-forget;
                    // PioneerService swallows errors so a network blip
                    // doesn't block the auth flow.
                    pioneerService.recordUserActive();

                    // Load calendar status for studios
                    if (user.role.isStudio || user.role.isSuperAdmin) {
                      globalCalendarBloc.add(
                        LoadCalendarStatusEvent(userId: user.uid),
                      );
                    }
                  } else {
                    // Crashlytics — clear user identity on logout
                    FirebaseCrashlytics.instance.setUserIdentifier('');
                    FirebaseCrashlytics.instance.log('User signed out');

                    // User logged out: remove token, reset calendar
                    notificationService.removeToken();
                    globalCalendarBloc.add(const ResetCalendarEvent());

                    // Cancel session revocation listener and clear local session
                    _sessionRevocationSubscription?.cancel();
                    _sessionRevocationSubscription = null;
                    deviceSessionService.clearLocalSession();
                  }
                },
                child: MaterialApp.router(
                  title: 'UZME',
                  debugShowCheckedModeBanner: false,
                  theme: UseMeTheme.lightTheme,
                  darkTheme: UseMeTheme.darkTheme,
                  themeMode: themeState.themeMode,
                  locale: localeState.locale,
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    SangoMaterialLocalizationsDelegate(),
                    SangoCupertinoLocalizationsDelegate(),
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  routerConfig: _router,
                  // Watcher mounted once near the root so any
                  // newly-available feature with an announcement pops
                  // its bottomsheet, regardless of which scaffold the
                  // user lands on.
                  builder: (context, child) => FeatureAnnouncementWatcher(
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
