import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/ai/ai_service.dart';

import '../features/calendar/calendar_screen.dart';
import '../features/calendar/today_screen.dart';
import '../features/feed/feed_screen.dart';
import '../features/feed/feed_sections_screen.dart';
import '../features/feed/feed_settings_screen.dart';
import '../features/history/history_screen.dart';
import '../features/pantry/pantry_screen.dart';
import '../features/recipe/cooking_screen.dart';
import '../features/recipe/recipe_screen.dart';
import '../features/settings/ai_diagnostics_screen.dart';
import '../features/settings/ai_settings_screen.dart';
import '../features/settings/appearance_settings_screen.dart';
import '../features/settings/backup_screen.dart';
import '../features/settings/mode_onboarding_screen.dart';
import '../features/settings/qr_scanner_screen.dart';
import '../features/settings/taste_preferences_screen.dart';
import '../features/statistics/statistics_screen.dart';
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
    GoRoute(
      path: '/feed',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const FeedScreen(),
    ),
    GoRoute(
      path: '/feed/sections',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const FeedSectionsScreen(),
    ),
    GoRoute(
      path: '/feed/section/:group',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) =>
          FeedSectionScreen(groupId: state.pathParameters['group'] ?? ''),
    ),
    GoRoute(
      path: '/settings/feed',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const FeedSettingsScreen(),
    ),
    GoRoute(
      path: '/statistics',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const StatisticsScreen(),
    ),
    GoRoute(
      path: '/stats',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const StatisticsScreen(),
    ),
    GoRoute(
      path: '/settings/ai',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const AiSettingsScreen(),
    ),
    GoRoute(
      path: '/settings/ai/diagnostics',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const AiDiagnosticsScreen(),
    ),
    GoRoute(
      path: '/settings/ai/qr-scanner',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const QrScannerScreen(),
    ),
    GoRoute(
      path: '/settings/appearance',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const AppearanceSettingsScreen(),
    ),
    GoRoute(
      path: '/onboarding/mode',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const ModeOnboardingScreen(),
    ),
    GoRoute(
      path: '/settings/preferences',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const TastePreferencesScreen(),
    ),
    GoRoute(
      path: '/settings/taste',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const TastePreferencesScreen(),
    ),
    GoRoute(
      path: '/settings/backup',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const BackupScreen(),
    ),
    GoRoute(
      path: '/settings',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const AiSettingsScreen(),
    ),
    GoRoute(
      path: '/recipe/:id',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        final suggestion = state.extra is AiDishSuggestion
            ? state.extra as AiDishSuggestion
            : null;
        return RecipeScreen(recipeId: id, initialSuggestion: suggestion);
      },
    ),
    GoRoute(
      path: '/cooking/:id',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return CookingScreen(recipeId: id);
      },
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
