import 'package:chto_prigotovit/app/theme.dart';
import 'package:chto_prigotovit/core/adaptive/adaptive_provider.dart';
import 'package:chto_prigotovit/core/adaptive/adaptive_spec.dart';
import 'package:chto_prigotovit/core/adaptive/ui_profile.dart';
import 'package:chto_prigotovit/core/ai/ai_failure.dart';
import 'package:chto_prigotovit/core/ai/ai_service.dart';
import 'package:chto_prigotovit/core/ai/ai_settings_service.dart';
import 'package:chto_prigotovit/core/ai/recipe_validator.dart';
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
import 'package:chto_prigotovit/features/settings/ai_diagnostics_screen.dart';
import 'package:chto_prigotovit/features/settings/ai_settings_screen.dart';
import 'package:chto_prigotovit/features/settings/appearance_settings_screen.dart';
import 'package:chto_prigotovit/features/settings/taste_preferences_screen.dart';
import 'package:chto_prigotovit/features/statistics/statistics_screen.dart';
import 'package:chto_prigotovit/features/suggestions/suggestions_screen.dart';
import 'package:chto_prigotovit/l10n/app_localizations.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'daily_notification_service_test.dart';

const longDishTitle =
    'Очень вкусное домашнее запеченное рагу с овощами и мясом птицы'; // 60 chars
const longIngredientName = 'Свежий органический картофель'; // 30 chars
const longStepText =
    'Тщательно вымойте все свежие органические овощи под проточной водой, очистите картофель и морковь от кожуры, затем нарежьте картофель ровными кубиками размером примерно полтора сантиметра, морковь тонкой соломкой, а лук мелкими кубиками для равномерной и качественной последующей обжарки на сковороде.'; // 300 chars

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

class _MockAiService extends Fake implements AiService {
  @override
  Future<AiResult<List<AiDishSuggestion>>> suggestDishes({
    required List<String> availableIngredients,
    List<String> forbiddenIngredients = const [],
    List<String> doNotSuggest = const [],
    String? dishTypeFilter,
    String? difficultyFilter,
    int? maxTotalMinutes,
    List<String> likes = const [],
    List<String> dislikes = const [],
    List<String> topRated = const [],
    int count = 6,
    Map<String, dynamic>? profile,
    Map<String, List<String>>? ingredientHierarchy,
    String? Function(String name)? resolveIngredientId,
    Map<String, List<String>>? forbiddenTerms,
    bool bypassCache = false,
  }) async {
    return const AiSuccess([
      AiDishSuggestion(
        title: longDishTitle,
        dishType: 'main',
        difficulty: 'medium',
        totalMinutes: 60,
        mainIngredients: [longIngredientName, 'морковь'],
        missing: [],
        why: 'Сытное горячее блюдо для всей семьи.',
        raw: {},
      ),
    ]);
  }

  @override
  Future<AiResult<Map<String, dynamic>>> fullRecipe({
    required String title,
    required String dishType,
    required String difficulty,
    required List<String> mainIngredients,
    required List<String> availableIngredients,
    int servings = 2,
    List<String> forbiddenIngredients = const [],
    Map<String, dynamic>? profile,
    Map<String, List<String>>? ingredientHierarchy,
    String? Function(String name)? resolveIngredientId,
    Map<String, List<String>>? forbiddenTerms,
  }) async {
    return const AiSuccess({
      'title': longDishTitle,
      'dish_type': 'main',
      'difficulty': 'medium',
      'servings': 2,
      'prep_minutes': 15,
      'cook_minutes': 45,
      'total_minutes': 60,
      'ingredients': [
        {
          'name': longIngredientName,
          'amount': 400.0,
          'unit': 'g',
          'is_staple': false,
        },
      ],
      'steps': [
        {'step_number': 1, 'text': longStepText, 'timer_seconds': 0},
      ],
    });
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('ru', null);
  });

  group('Overflow across all screens (R3-09)', () {
    late AppDatabase db;
    late RecipeDao recipeDao;
    late PlanDao planDao;
    late IngredientDao ingredientDao;
    late PantryDao pantryDao;
    late PreferenceService prefService;
    late HistoryDao historyDao;
    late DailyNotificationService dailyNotif;
    late _FakeCookingNotificationService fakeCookingNotif;
    late AiSettingsService aiSettingsService;
    late _MockAiService mockAiService;

    setUpAll(() async {
      drift.driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      db = AppDatabase(NativeDatabase.memory(), seed: true);
      await db.customSelect('SELECT 1').get();

      recipeDao = RecipeDao(db);
      planDao = PlanDao(db);
      ingredientDao = IngredientDao(db);
      pantryDao = PantryDao(db);
      prefService = PreferenceService(db);
      historyDao = HistoryDao(db, preferenceService: prefService);
      final fakeStorage = FakeSecureStorage();
      dailyNotif = DailyNotificationService(
        plugin: RecordingNotificationPlugin(),
        storage: fakeStorage,
      );
      fakeCookingNotif = _FakeCookingNotificationService();
      aiSettingsService = AiSettingsService(storage: fakeStorage);
      mockAiService = _MockAiService();

      // Update recipe 'borscht' to have long title
      await (db.update(db.recipes)..where((tbl) => tbl.id.equals('borscht')))
          .write(const RecipesCompanion(title: drift.Value(longDishTitle)));

      // Update first step of 'borscht' to have long text
      await (db.update(db.recipeSteps)..where(
            (tbl) => tbl.recipeId.equals('borscht') & tbl.position.equals(1),
          ))
          .write(
            const RecipeStepsCompanion(textContent: drift.Value(longStepText)),
          );

      // Update ingredient 'potato' to have long name
      await (db.update(
        db.ingredients,
      )..where((tbl) => tbl.id.equals('potato'))).write(
        const IngredientsCompanion(name: drift.Value(longIngredientName)),
      );

      // Set ingredients in pantry
      await pantryDao.setAvailable('potato', true);
      await pantryDao.setAvailable('beetroot', true);
      await pantryDao.setAvailable('cabbage', true);
      await pantryDao.setAvailable('beef', true);

      // Plan borscht for today
      final todayStr = PlanDao.formatDate(DateTime.now());
      await planDao.upsertEntry(
        date: todayStr,
        recipeId: 'borscht',
        status: MealPlanStatus.planned,
        locked: false,
      );

      // Insert history with long dish and note
      await historyDao.recordCooked(
        recipeId: 'borscht',
        rating: 5,
        note: longStepText,
      );

      // Insert an AI request log with long note
      await db
          .into(db.aiRequests)
          .insert(
            AiRequestsCompanion(
              id: const drift.Value('req_long_1'),
              at: drift.Value(DateTime.now().millisecondsSinceEpoch),
              model: const drift.Value('qwen2.5-7b'),
              kind: const drift.Value('suggest_dishes'),
              promptHash: const drift.Value('abc123hash'),
              status: const drift.Value('error'),
              responseJson: const drift.Value(longStepText),
            ),
          );
    });

    tearDownAll(() async {
      await db.close();
    });

    Widget buildTestApp({
      required Widget child,
      required double width,
      required double textScale,
      UiMode mode = UiMode.simple,
      bool isDark = false,
    }) {
      final profile = mode == UiMode.simple
          ? UiProfile.defaultSimple()
          : UiProfile.defaultFull();
      final spec = AdaptiveSpec(profile: profile, systemFontScale: textScale);
      final theme = isDark ? AppTheme.darkFor(spec) : AppTheme.lightFor(spec);

      return ProviderScope(
        overrides: [
          uiProfileProvider.overrideWith(
            () => _FixedUiProfileNotifier(profile),
          ),
          databaseProvider.overrideWithValue(db),
          recipeDaoProvider.overrideWithValue(recipeDao),
          planDaoProvider.overrideWithValue(planDao),
          ingredientDaoProvider.overrideWithValue(ingredientDao),
          pantryDaoProvider.overrideWithValue(pantryDao),
          preferenceServiceProvider.overrideWithValue(prefService),
          historyDaoProvider.overrideWithValue(historyDao),
          dailyNotificationServiceProvider.overrideWithValue(dailyNotif),
          notificationServiceProvider.overrideWithValue(fakeCookingNotif),
          aiSettingsServiceProvider.overrideWithValue(aiSettingsService),
          aiServiceProvider.overrideWith((ref) async => mockAiService),
          recipeValidatorProvider.overrideWith(
            (ref) async => const RecipeValidator(safetyMinimums: {}),
          ),
        ],
        child: AdaptiveScope(
          spec: spec,
          child: MediaQuery(
            data: MediaQueryData(
              size: Size(width, 800),
              textScaler: TextScaler.linear(textScale),
            ),
            child: MaterialApp(
              theme: theme,
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
        ),
      );
    }

    void assertNoClippedText(WidgetTester tester, String screenName) {
      final renderObjects = tester.renderObjectList<RenderParagraph>(
        find.byType(RichText),
      );
      for (final ro in renderObjects) {
        if (ro.maxLines != null) continue; // intentional truncation (cards)
        if (!ro.hasSize || ro.size.isEmpty) continue;
        // Skip icon glyphs (e.g. MaterialIcons)
        if (ro.text.style?.fontFamily?.contains('Icons') == true) continue;

        // 1. Check intrinsic text height vs actual rendered height:
        final intrinsicHeight = ro.getMaxIntrinsicHeight(ro.size.width);
        if (intrinsicHeight > ro.size.height + 1.0) {
          fail(
            '[$screenName] Text is vertically clipped: intrinsicHeight=$intrinsicHeight > size.height=${ro.size.height} for text "${ro.text.toPlainText()}"',
          );
        }

        // 2. Check if RenderParagraph extends beyond bounds of closest non-viewport RenderClip* ancestor:
        final viewport = RenderAbstractViewport.maybeOf(ro);
        RenderObject? node = ro.parent;
        while (node != null) {
          if (node is RenderBox &&
              node.runtimeType.toString().startsWith('RenderClip')) {
            final isViewportClip =
                viewport != null &&
                (identical(node, viewport) ||
                    node.depth <= (viewport as RenderObject).depth);
            if (!isViewportClip && node.hasSize) {
              final roTopLeftInClip = ro.localToGlobal(
                Offset.zero,
                ancestor: node,
              );
              final roBottomInClip = roTopLeftInClip.dy + ro.size.height;
              final clipHeight = node.size.height;
              if (roTopLeftInClip.dy < -1.0 ||
                  roBottomInClip > clipHeight + 1.0) {
                fail(
                  '[$screenName] Text "${ro.text.toPlainText()}" extends outside ${node.runtimeType}: '
                  'text top=${roTopLeftInClip.dy}, bottom=$roBottomInClip vs clipHeight=$clipHeight',
                );
              }
            }
            break;
          }
          node = node.parent;
        }
      }
    }

    final screens = <String, Widget Function()>{
      '1. TodayScreen': () => const TodayScreen(),
      '2. PantryScreen': () => const PantryScreen(),
      '3. SuggestionsScreen': () => const SuggestionsScreen(),
      '4. RecipeScreen': () => const RecipeScreen(recipeId: 'borscht'),
      '5. CookingScreen': () => const CookingScreen(recipeId: 'borscht'),
      '6. CalendarScreen': () => const CalendarScreen(),
      '7. HistoryScreen': () => const HistoryScreen(),
      '8. AiSettingsScreen': () => const AiSettingsScreen(),
      '9. AiDiagnosticsScreen': () => const AiDiagnosticsScreen(),
      '10. TastePreferencesScreen': () => const TastePreferencesScreen(),
      '11. AppearanceSettingsScreen': () => const AppearanceSettingsScreen(),
      '12. StatisticsScreen': () => const StatisticsScreen(),
    };

    // R8-19: каждый экран × 2 режима × шрифт 1.0/2.0 × светлая/тёмная тема × 360 и 412 dp.
    final widths = [360.0, 412.0];
    final scales = [1.0, 2.0];
    final modes = [UiMode.simple, UiMode.full];
    final themes = [false, true]; // false: light, true: dark

    for (final entry in screens.entries) {
      final screenName = entry.key;
      final builder = entry.value;

      for (final mode in modes) {
        for (final isDark in themes) {
          for (final w in widths) {
            for (final s in scales) {
              final modeTag = mode == UiMode.simple ? 'Simple' : 'Full';
              final themeTag = isDark ? 'Dark' : 'Light';
              testWidgets(
                '$screenName ($modeTag, $themeTag, ${w.toInt()}dp, ${s}x)',
                (tester) async {
                  FlutterErrorDetails? caughtDetails;
                  final oldOnError = FlutterError.onError;
                  FlutterError.onError = (details) {
                    caughtDetails = details;
                  };
                  addTearDown(() => FlutterError.onError = oldOnError);

                  await tester.binding.setSurfaceSize(Size(w, 800));
                  addTearDown(() => tester.binding.setSurfaceSize(null));

                  await tester.pumpWidget(
                    buildTestApp(
                      child: builder(),
                      width: w,
                      textScale: s,
                      mode: mode,
                      isDark: isDark,
                    ),
                  );
                  await tester.pump();
                  await tester.pump(const Duration(milliseconds: 300));
                  final err = tester.takeException();
                  expect(err, isNull);
                  expect(caughtDetails, isNull);
                  assertNoClippedText(tester, screenName);
                },
              );
            }
          }
        }
      }
    }
  });
}

class _FixedUiProfileNotifier extends UiProfileNotifier {
  _FixedUiProfileNotifier(this._initial);
  final UiProfile _initial;
  @override
  UiProfile build() => _initial;
}
