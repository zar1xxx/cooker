import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/calendar/calendar_screen.dart';
import '../features/calendar/today_screen.dart';
import '../features/history/history_screen.dart';
import '../features/pantry/pantry_screen.dart';
import '../features/suggestions/suggestions_screen.dart';
import 'scaffold_with_nav_bar.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/today',
  routes: [
    GoRoute(
      path: '/suggestions',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const SuggestionsScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/today',
              builder: (context, state) => const TodayScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/pantry',
              builder: (context, state) => const PantryScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/calendar',
              builder: (context, state) => const CalendarScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/history',
              builder: (context, state) => const HistoryScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
