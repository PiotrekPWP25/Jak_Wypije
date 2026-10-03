import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/bar_detail/bar_detail_screen.dart';
import 'features/barobranie/barobranie_screen.dart';
import 'features/barobranie/fundraiser_detail_screen.dart';
import 'features/checkin/check_in_screen.dart';
import 'features/friends/friends_screen.dart';
import 'features/map/map_screen.dart';
import 'features/planner/planner_screen.dart';
import 'features/profile/profile_screen.dart';
import 'widgets/home_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/map',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/map',
                builder: (context, state) => const MapScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/planner',
                builder: (context, state) => const PlannerScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/barobranie',
                builder: (context, state) => const BarobranieScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/friends',
                builder: (context, state) => const FriendsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/bar/:id',
        builder: (context, state) =>
            BarDetailScreen(barId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/fundraiser/:id',
        builder: (context, state) =>
            FundraiserDetailScreen(fundraiserId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/checkin',
        builder: (context, state) =>
            CheckInScreen(preselectedBarId: state.uri.queryParameters['bar']),
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
      themeMode: ThemeMode.dark,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
