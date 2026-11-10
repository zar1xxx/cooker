import 'package:chto_prigotovit/app/theme.dart';
import 'package:chto_prigotovit/core/ai/ai_service.dart';
import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/db/daos/pantry_dao.dart';
import 'package:chto_prigotovit/core/db/daos/recipe_dao.dart';
import 'package:chto_prigotovit/core/providers.dart';
import 'package:chto_prigotovit/features/recipe/recipe_screen.dart';
import 'package:chto_prigotovit/l10n/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _createTestWidget(AppDatabase db, String recipeId) {
  return ProviderScope(
    overrides: [databaseProvider.overrideWithValue(db)],
    child: MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ru'),
      home: RecipeScreen(recipeId: recipeId),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory(), seed: true);
    // Trigger seed
    await db.customSelect('SELECT 1').get();
  });

  tearDown(() async {
    await db.close();
  });

  group('RecipeScreen (S2-01 / TZ 7.2)', () {
    testWidgets('renders recipe header, servings, ingredients and steps', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_createTestWidget(db, 'chicken_soup_potato'));
      await tester.pumpAndSettle();

      // Title and header
      expect(find.text('Куриный суп с картошкой'), findsOneWidget);
      expect(find.text('Суп'), findsOneWidget);
      expect(find.text('Легко'), findsOneWidget);
      expect(find.text('65 мин'), findsOneWidget);

      // Servings
      expect(find.text('Порции: 4'), findsOneWidget);

      // Ingredients
      expect(find.text('Ингредиенты'), findsOneWidget);
      expect(find.textContaining('Курица'), findsWidgets);
      expect(find.textContaining('Картофель'), findsWidgets);

      // Steps
      expect(find.text('Шаги приготовления'), findsOneWidget);
      expect(find.text('Шаг 1'), findsOneWidget);
      expect(find.text('Шаг 2'), findsOneWidget);

      // Main action
      expect(find.text('Начать готовить'), findsOneWidget);
    });

    testWidgets(
      'adjusting servings with + and - scales ingredient quantities',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_createTestWidget(db, 'chicken_soup_potato'));
        await tester.pumpAndSettle();

        // Initial base servings: 4. Chicken is 500 g.
        expect(find.text('Порции: 4'), findsOneWidget);
        expect(find.text('500 г'), findsOneWidget);

        // Tap increase button (+)
        final plusButton = find.byIcon(Icons.add);
        expect(plusButton, findsOneWidget);
        await tester.tap(plusButton);
        await tester.pumpAndSettle();

        // Now 5 servings. Chicken scaled: 500 * 5 / 4 = 625 g.
        expect(find.text('Порции: 5'), findsOneWidget);
        expect(find.text('625 г'), findsOneWidget);

        // Tap decrease button (-) twice: 5 -> 4 -> 3 servings
        final minusButton = find.byIcon(Icons.remove);
        expect(minusButton, findsOneWidget);
        await tester.tap(minusButton);
        await tester.pumpAndSettle();
        expect(find.text('Порции: 4'), findsOneWidget);
        expect(find.text('500 г'), findsOneWidget);

        await tester.tap(minusButton);
        await tester.pumpAndSettle();
        expect(find.text('Порции: 3'), findsOneWidget);
        // Chicken scaled: 500 * 3 / 4 = 375 g
        expect(find.text('375 г'), findsOneWidget);
      },
    );

    testWidgets(
      'marks ingredients as available or missing based on pantry contents',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        // Put potato and carrot into pantry
        final pantryDao = PantryDao(db);
        await pantryDao.setAvailable('potato', true);
        await pantryDao.setAvailable('carrot', true);

        await tester.pumpWidget(_createTestWidget(db, 'chicken_soup_potato'));
        await tester.pumpAndSettle();

        // We expect at least 2 "Есть дома" and some "Нужно купить" (chicken, water/onion/etc.)
        expect(find.text('Есть дома'), findsWidgets);
        expect(find.text('Нужно купить'), findsWidgets);
      },
    );

    testWidgets(
      'toggling favorite updates the icon and persists to the database',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final recipeDao = RecipeDao(db);
        final initialRecipe = await recipeDao.byId('chicken_soup_potato');
        expect(initialRecipe!.isFavorite, isFalse);

        await tester.pumpWidget(_createTestWidget(db, 'chicken_soup_potato'));
        await tester.pumpAndSettle();

        // Tap the favorite button in the app bar
        final favAction = find.byTooltip('В избранное');
        expect(favAction, findsOneWidget);

        await tester.tap(favAction);
        await tester.pumpAndSettle();

        // Snackbar shown
        expect(find.text('Рецепт добавлен в избранное'), findsOneWidget);
        expect(find.byTooltip('В избранном'), findsOneWidget);

        // DB persisted
        final updatedRecipe = await recipeDao.byId('chicken_soup_potato');
        expect(updatedRecipe!.isFavorite, isTrue);
      },
    );

    testWidgets(
      'R8-07: RecipeScreen opened with initialSuggestion immediately renders title, meta, assistant badge and main ingredients',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const suggestion = AiDishSuggestion(
          title: 'Овощное рагу от шефа',
          dishType: 'main',
          difficulty: 'easy',
          totalMinutes: 35,
          mainIngredients: ['картофель', 'кабачок', 'морковь'],
          missing: [],
          why: 'Простое и быстрое блюдо',
          raw: {},
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWithValue(db)],
            child: MaterialApp(
              theme: AppTheme.light,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('ru'),
              home: const RecipeScreen(
                recipeId: 'new',
                initialSuggestion: suggestion,
              ),
            ),
          ),
        );
        await tester.pump();

        // Immediate view without waiting for LLM completion
        expect(find.text('Овощное рагу от шефа'), findsOneWidget);
        expect(find.text('От помощника'), findsOneWidget);
        expect(find.text('Второе'), findsOneWidget);
        expect(find.text('Легко'), findsOneWidget);
        expect(find.text('35 мин'), findsOneWidget);
        expect(find.text('Главные продукты'), findsOneWidget);
        expect(find.text('картофель'), findsOneWidget);
        expect(find.text('кабачок'), findsOneWidget);
        expect(find.text('морковь'), findsOneWidget);
        expect(
          find.text('Помощник составляет пошаговый рецепт...'),
          findsOneWidget,
        );
      },
    );
  });
}
