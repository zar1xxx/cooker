import 'dart:math';

import 'package:chto_prigotovit/app/theme.dart';
import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/db/daos/history_dao.dart';
import 'package:chto_prigotovit/core/db/daos/ingredient_dao.dart';
import 'package:chto_prigotovit/core/db/daos/pantry_dao.dart';
import 'package:chto_prigotovit/core/db/daos/plan_dao.dart';
import 'package:chto_prigotovit/core/db/daos/recipe_dao.dart';
import 'package:chto_prigotovit/core/db/enums.dart';
import 'package:chto_prigotovit/core/preferences/preference_service.dart';
import 'package:chto_prigotovit/core/providers.dart';
import 'package:chto_prigotovit/core/services/daily_notification_service.dart';
import 'package:chto_prigotovit/core/services/notification_service.dart';
import 'package:chto_prigotovit/features/calendar/calendar_screen.dart';
import 'package:chto_prigotovit/features/calendar/today_screen.dart';
import 'package:chto_prigotovit/features/history/history_screen.dart';
import 'package:chto_prigotovit/features/pantry/pantry_screen.dart';
import 'package:chto_prigotovit/features/recipe/cooking_screen.dart';
import 'package:chto_prigotovit/features/recipe/recipe_screen.dart';
import 'package:chto_prigotovit/features/settings/ai_settings_screen.dart';
import 'package:chto_prigotovit/features/settings/backup_screen.dart';
import 'package:chto_prigotovit/features/settings/taste_preferences_screen.dart';
import 'package:chto_prigotovit/features/suggestions/suggestions_screen.dart';
import 'package:chto_prigotovit/l10n/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'daily_notification_service_test.dart';

class _FakeCookingNotificationService extends Fake
    implements CookingNotificationService {
  @override
  Future<void> init() async {}
  @override
  Future<void> scheduleTimer({
    required int id,
    required String recipeTitle,
    required int stepNumber,
    required int seconds,
  }) async {}
  @override
  Future<void> cancelTimer(int id) async {}
  @override
  Future<void> cancelAll() async {}
}

double _relativeLuminance(Color c) {
  double channel(double value) {
    return value <= 0.03928
        ? value / 12.92
        : pow((value + 0.055) / 1.055, 2.4).toDouble();
  }

  final r = channel(c.r);
  final g = channel(c.g);
  final b = channel(c.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double _contrastRatio(Color c1, Color c2) {
  final l1 = _relativeLuminance(c1);
  final l2 = _relativeLuminance(c2);
  final lighter = max(l1, l2);
  final darker = min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('ru', null);
  });

  group('Accessibility & Senior UX (S6-01 / TZ 7.1, skills/senior-ux)', () {
    late AppDatabase db;
    late RecipeDao recipeDao;
    late PlanDao planDao;
    late IngredientDao ingredientDao;
    late PantryDao pantryDao;
    late PreferenceService prefService;
    late HistoryDao historyDao;
    late DailyNotificationService dailyNotif;
    late _FakeCookingNotificationService fakeCookingNotif;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory(), seed: true);
      await db.customSelect('SELECT 1').get();

      recipeDao = RecipeDao(db);
      planDao = PlanDao(db);
      ingredientDao = IngredientDao(db);
      pantryDao = PantryDao(db);
      prefService = PreferenceService(db);
      historyDao = HistoryDao(db, preferenceService: prefService);
      dailyNotif = DailyNotificationService(
        plugin: RecordingNotificationPlugin(),
        storage: FakeSecureStorage(),
      );
      fakeCookingNotif = _FakeCookingNotificationService();
    });

    tearDown(() async {
      await db.close();
    });

    Widget createAccessibleApp({
      required Widget child,
      double textScale = 2.0,
      bool dark = false,
      Size size = const Size(390, 844),
    }) {
      return ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          recipeDaoProvider.overrideWithValue(recipeDao),
          planDaoProvider.overrideWithValue(planDao),
          ingredientDaoProvider.overrideWithValue(ingredientDao),
          pantryDaoProvider.overrideWithValue(pantryDao),
          preferenceServiceProvider.overrideWithValue(prefService),
          historyDaoProvider.overrideWithValue(historyDao),
          dailyNotificationServiceProvider.overrideWithValue(dailyNotif),
          notificationServiceProvider.overrideWithValue(fakeCookingNotif),
        ],
        child: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: dark ? ThemeMode.dark : ThemeMode.light,
            locale: const Locale('ru'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('ru')],
            home: child,
          ),
        ),
      );
    }

    test('Theme color contrast meets WCAG AA >= 4.5:1 in both light and dark themes', () {
      // Light theme
      final lightPrimaryContrast = _contrastRatio(
        AppTheme.primaryLight,
        AppTheme.onPrimaryLight,
      );
      expect(
        lightPrimaryContrast >= 4.5,
        isTrue,
        reason:
            'Light primary text contrast must be >= 4.5:1, got $lightPrimaryContrast',
      );

      final lightSurfaceContrast = _contrastRatio(
        AppTheme.surfaceLight,
        AppTheme.onSurfaceLight,
      );
      expect(
        lightSurfaceContrast >= 4.5,
        isTrue,
        reason:
            'Light surface text contrast must be >= 4.5:1, got $lightSurfaceContrast',
      );

      final lightBgContrast = _contrastRatio(
        AppTheme.backgroundLight,
        AppTheme.onSurfaceLight,
      );
      expect(
        lightBgContrast >= 4.5,
        isTrue,
        reason:
            'Light background text contrast must be >= 4.5:1, got $lightBgContrast',
      );

      // Dark theme
      final darkPrimaryContrast = _contrastRatio(
        AppTheme.primaryDark,
        AppTheme.onPrimaryDark,
      );
      expect(
        darkPrimaryContrast >= 4.5,
        isTrue,
        reason:
            'Dark primary text contrast must be >= 4.5:1, got $darkPrimaryContrast',
      );

      final darkSurfaceContrast = _contrastRatio(
        AppTheme.surfaceDark,
        AppTheme.onSurfaceDark,
      );
      expect(
        darkSurfaceContrast >= 4.5,
        isTrue,
        reason:
            'Dark surface text contrast must be >= 4.5:1, got $darkSurfaceContrast',
      );

      final darkBgContrast = _contrastRatio(
        AppTheme.backgroundDark,
        AppTheme.onSurfaceDark,
      );
      expect(
        darkBgContrast >= 4.5,
        isTrue,
        reason:
            'Dark background text contrast must be >= 4.5:1, got $darkBgContrast',
      );
    });

    test('Theme touch targets conform to minimum 56x56 dp rule', () {
      expect(AppTheme.minTouchTarget, 56.0);
      final lightTheme = AppTheme.light;
      expect(
        lightTheme.filledButtonTheme.style?.minimumSize?.resolve({})?.height,
        greaterThanOrEqualTo(56.0),
      );
      expect(
        lightTheme.outlinedButtonTheme.style?.minimumSize?.resolve({})?.height,
        greaterThanOrEqualTo(56.0),
      );
      expect(
        lightTheme.iconButtonTheme.style?.minimumSize?.resolve({})?.height,
        greaterThanOrEqualTo(56.0),
      );
      expect(
        lightTheme.floatingActionButtonTheme.sizeConstraints?.minHeight,
        greaterThanOrEqualTo(56.0),
      );
    });

    testWidgets('TodayScreen renders without overflow at 200% font scale', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createAccessibleApp(child: const TodayScreen(), textScale: 2.0),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.byType(TodayScreen), findsOneWidget);
    });

    testWidgets(
      'TodayScreen with planned dish renders without overflow at 200% font scale',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final todayStr = PlanDao.formatDate(DateTime.now());
        await planDao.upsertEntry(
          date: todayStr,
          recipeId: 'borscht',
          status: MealPlanStatus.planned,
          locked: false,
        );

        await tester.pumpWidget(
          createAccessibleApp(child: const TodayScreen(), textScale: 2.0),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
        expect(find.byType(TodayScreen), findsOneWidget);
      },
    );

    testWidgets('CalendarScreen renders without overflow at 200% font scale', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createAccessibleApp(child: const CalendarScreen(), textScale: 2.0),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.byType(CalendarScreen), findsOneWidget);
    });

    testWidgets('RecipeScreen renders without overflow at 200% font scale', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createAccessibleApp(
          child: const RecipeScreen(recipeId: 'borscht'),
          textScale: 2.0,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.byType(RecipeScreen), findsOneWidget);
    });

    testWidgets('CookingScreen renders without overflow at 200% font scale', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createAccessibleApp(
          child: const CookingScreen(recipeId: 'borscht'),
          textScale: 2.0,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.byType(CookingScreen), findsOneWidget);
    });

    testWidgets(
      'SuggestionsScreen renders without overflow at 200% font scale',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          createAccessibleApp(child: const SuggestionsScreen(), textScale: 2.0),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
        expect(find.byType(SuggestionsScreen), findsOneWidget);
      },
    );

    testWidgets('PantryScreen renders without overflow at 200% font scale', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createAccessibleApp(child: const PantryScreen(), textScale: 2.0),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.byType(PantryScreen), findsOneWidget);
    });

    testWidgets('HistoryScreen renders without overflow at 200% font scale', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createAccessibleApp(child: const HistoryScreen(), textScale: 2.0),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.byType(HistoryScreen), findsOneWidget);
    });

    testWidgets(
      'TastePreferencesScreen renders without overflow at 200% font scale',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          createAccessibleApp(
            child: const TastePreferencesScreen(),
            textScale: 2.0,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
        expect(find.byType(TastePreferencesScreen), findsOneWidget);
      },
    );

    testWidgets('BackupScreen renders without overflow at 200% font scale', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createAccessibleApp(child: const BackupScreen(), textScale: 2.0),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.byType(BackupScreen), findsOneWidget);
    });

    testWidgets(
      'AiSettingsScreen renders without overflow at 200% font scale',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          createAccessibleApp(child: const AiSettingsScreen(), textScale: 2.0),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
        expect(find.byType(AiSettingsScreen), findsOneWidget);
      },
    );
  });
}
