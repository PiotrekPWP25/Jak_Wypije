import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
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
        builder: (context, state) => const SplashScreen(),
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
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class JakWypijeApp extends ConsumerWidget {
  const JakWypijeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'JakWypiję',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
