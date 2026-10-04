import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'data/auth/auth_repository.dart';
import 'features/account/account_providers.dart';
import 'features/account/auth_screen.dart';
import 'features/account/check_email_screen.dart';
import 'features/account/new_password_screen.dart';
import 'features/account/profile_sync.dart';
import 'features/bar_detail/bar_detail_screen.dart';
import 'features/barobranie/barobranie_screen.dart';
import 'features/barobranie/safe_return_screen.dart';
import 'features/bars/bars_screen.dart';
import 'features/checkin/check_in_screen.dart';
import 'features/friends/friends_screen.dart';
import 'features/home/home_screen.dart';
import 'features/landmark_detail/landmark_detail_screen.dart';
import 'features/map/map_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/passport/passport_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/settings/legal_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/splash/splash_screen.dart';
import 'features/trips/trip_preview_screen.dart';
import 'widgets/home_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

GoRoute _tab(String path, Widget screen) =>
    GoRoute(path: path, builder: (context, state) => screen);

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => SplashScreen(
          resetUserData: state.uri.queryParameters['reset'] == '1',
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [_tab('/start', const HomeScreen())]),
          StatefulShellBranch(routes: [_tab('/map', const MapScreen())]),
          StatefulShellBranch(routes: [_tab('/bars', const BarsScreen())]),
          StatefulShellBranch(
            routes: [_tab('/barobranie', const BarobranieScreen())],
          ),
          StatefulShellBranch(
            routes: [_tab('/friends', const FriendsScreen())],
          ),
        ],
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/bar/:id',
        builder: (context, state) =>
            BarDetailScreen(barId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/landmark/:id',
        builder: (context, state) =>
            LandmarkDetailScreen(landmarkId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/trip/:id',
        builder: (context, state) =>
            TripPreviewScreen(tripId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/checkin',
        builder: (context, state) => CheckInScreen(
          preselectedPlaceId: state.uri.queryParameters['place'] ??
              state.uri.queryParameters['bar'],
        ),
      ),
      GoRoute(
        path: '/safe-return',
        builder: (context, state) => const SafeReturnScreen(),
      ),
      GoRoute(
        path: '/passport',
        builder: (context, state) => const PassportScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => AuthScreen(
          signUp: state.uri.queryParameters['signup'] == '1',
          next: state.uri.queryParameters['next'],
        ),
      ),
      GoRoute(
        path: '/auth/check-email',
        builder: (context, state) => CheckEmailScreen(
          email: state.uri.queryParameters['email'] ?? '',
          recovery: state.uri.queryParameters['type'] == 'recovery',
          next: state.uri.queryParameters['next'],
        ),
      ),
      GoRoute(
        path: '/auth/new-password',
        builder: (context, state) => const NewPasswordScreen(),
      ),
      GoRoute(
        path: '/legal/:doc',
        redirect: (context, state) =>
            LegalDoc.byName(state.pathParameters['doc']!) == null
                ? '/settings'
                : null,
        builder: (context, state) =>
            LegalScreen(doc: LegalDoc.byName(state.pathParameters['doc']!)!),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

final _messengerKey = GlobalKey<ScaffoldMessengerState>();

class JakWypijeApp extends ConsumerStatefulWidget {
  const JakWypijeApp({super.key});

  @override
  ConsumerState<JakWypijeApp> createState() => _JakWypijeAppState();
}

class _JakWypijeAppState extends ConsumerState<JakWypijeApp> {
  StreamSubscription<AuthChangeEvent>? _authEvents;

  @override
  void initState() {
    super.initState();
    _authEvents = ref.read(authRepositoryProvider)?.events().listen(
      (event) {
        if (event == AuthChangeEvent.passwordRecovery) _openNewPassword();
      },
      // E.g. an expired link from the e-mail.
      onError: (Object error) => _messengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(authErrorMessage(error))),
      ),
    );
  }

  @override
  void dispose() {
    _authEvents?.cancel();
    super.dispose();
  }

  /// A password-reset link opened the app.
  void _openNewPassword() {
    final router = ref.read(routerProvider);
    if (router.routerDelegate.currentConfiguration.uri.path == '/splash') {
      // The splash would navigate away – it continues there instead.
      ref.read(passwordRecoveryPendingProvider.notifier).state = true;
    } else {
      router.go('/auth/new-password');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keeps the profile in sync with the account for the whole session.
    ref.listen(profileSyncProvider, (_, __) {});
    return MaterialApp.router(
      title: 'JakWypiję',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _messengerKey,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
