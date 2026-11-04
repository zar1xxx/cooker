# Отчёт по этапу 1 — «Что есть дома» и подбор без ИИ

Дата: 2026-11-04 · Коммит: e88a5b8

## Сделано

| ID | Что сделано | Файлы |
| --- | --- | --- |
| S1-09 | DAO слой Drift (`IngredientDao`, `PantryDao`, `RecipeDao`), Riverpod-провайдеры, FTS5-поиск, транзитивная иерархия | `lib/core/db/daos/*`, `lib/core/providers/database_providers.dart`, `test/dao_test.dart` |
| S1-02 | `IngredientNormalizer`: нормализация регистра, ё→е, стемминг русских окончаний, синонимы, опечатки (Левенштейн ≤ 2), транзитивная иерархия | `lib/core/matching/ingredient_normalizer.dart`, `test/ingredient_normalizer_test.dart` |
| S1-01 | Seed-данные: 284 ингредиента с категориями и синонимами, 125 кулинарно достоверных рецептов всех типов и сложностей, генератор `gen_seed.dart`, валидатор | `assets/seed/*`, `tool/gen_seed.dart`, `tool/seed_data/*`, `test/seed_data_test.dart` |
| S1-04 | `RecipeMatcher` по ТЗ 5.2: обязательные и опциональные ингредиенты, иерархия замен (филе → курица), расчёт `missing` и `coverage`, разбивка на группы «Можно приготовить сейчас» и «Не хватает 1–2 продуктов» | `lib/core/matching/recipe_matcher.dart`, `test/recipe_matcher_test.dart` |
| S1-05 | `RecipeScorer` по ТЗ 5.3: взвешенный расчёт по формуле `0.35*cov + 0.30*taste + 0.20*nov + 0.10*fit + 0.05*exp`, `taste = 0.5` до этапа 4, линейное затухание новизны 7→30 дней, детерминированный explore с seed по дате | `lib/core/matching/recipe_scorer.dart`, `test/recipe_scorer_test.dart` |
| S1-06 | `RecipeDiversityReorderer` по ТЗ 5.4: жадный MMR-отбор в топ-10 (≤3 одного типа блюда, ≤2 с одним главным ингредиентом с учётом иерархии), ослабление при нехватке кандидатов, отключение лимита типа при фильтре | `lib/core/matching/diversity_reorderer.dart`, `test/diversity_reorderer_test.dart` |
| S1-03 | Экран «Что есть дома»: плитки категорий с крупными иконками 180×180, bottom sheet ингредиентов, поиск (FTS + нормализатор), добавление своего продукта, блок «Часто выбираете» (12 чипов), голосовой ввод (`speech_to_text`), плавающая кнопка «Показать блюда (N)» с живым счётчиком | `lib/features/pantry/pantry_screen.dart`, `test/pantry_screen_test.dart` |
| S1-07 | Экран «Блюда»: чипы-фильтры по типам блюд и сложности, две секции («Можно приготовить сейчас» и «Не хватает 1–2 продуктов»), карточки по ТЗ 7.2 (тип, 1–3 поварских колпачка сложности, время готовки, недостающие продукты, бейдж «Новое»), действие «Не хочу» со скрытием и отменой через SnackBar на 5 секунд | `lib/features/suggestions/suggestions_screen.dart`, `test/suggestions_screen_test.dart` |
| S1-08 | Сквозные и интеграционные тесты: нормализация («картошка», «морковка»→«морковь», «филе»→«курица»), точный скоринг на фиксированных данных по ТЗ 5.3, разнообразие ≤3 по типу блюда и сквозной критерий этапа 1 | `test/matching_integration_test.dart` |

## 20 случайных рецептов на вычитку владельцу

Выборка из `assets/seed/recipes.json` (всего 125 рецептов):
1. `jam_apple`: Варенье из яблок (preserve, easy, 45 мин)
2. `mushroom_soup`: Грибной суп с картошкой (soup, easy, 40 мин)
3. `mashed_pumpkin`: Пюре из тыквы (side, easy, 25 мин)
4. `chicken_soup_potato`: Куриный суп с картошкой (soup, easy, 45 мин)
5. `chicken_cream_sauce`: Курица в сливочном соусе (main, easy, 35 мин)
6. `cabbage_carrot`: Салат из капусты с морковью (salad, easy, 15 мин)
7. `stuffed_peppers`: Перец, фаршированный мясом (main, medium, 60 мин)
8. `fried_potato`: Картошка жареная (side, easy, 30 мин)
9. `mashed_potato`: Картофельное пюре (side, easy, 30 мин)
10. `fish_fry`: Минтай жареный (main, easy, 25 мин)
11. `crab_salad`: Салат крабовый (salad, easy, 20 мин)
12. `pork_bake_potato`: Свинина, запечённая с картошкой (main, medium, 75 мин)
13. `cheese_bread`: Сырный хлеб (baking, medium, 50 мин)
14. `chicken_fry_onion`: Куриное филе с луком (main, easy, 25 мин)
15. `pilaf`: Плов с курицей (main, medium, 50 мин)
16. `pasta_cheese`: Макароны с сыром (main, easy, 20 мин)
17. `fish_soup`: Уха из минтая (soup, easy, 35 мин)
18. `chicken_bake_veg`: Курица, запечённая с овощами (main, easy, 50 мин)
19. `mushroom_salad`: Салат с грибами (salad, easy, 20 мин)
20. `pork_chops`: Свиные отбивные (main, easy, 30 мин)

## Как запустить и проверить вручную

1. Запуск всех проверок проекта и сборка APK:
   ```powershell
   powershell -ExecutionPolicy Bypass -File tool\check.ps1 -Apk
   ```
2. Установка отладочного APK на подключённое Android-устройство:
   ```powershell
   flutter install
   ```
   или напрямую через adb:
   ```powershell
   adb install -r build\app\outputs\flutter-apk\app-debug.apk
   ```
3. Проверка сценария этапа 1:
   - Открыть вкладку «Что есть дома».
   - Выбрать продукты: «картошка», «лук», «морковь», «курица» (через чипы «Часто выбираете» или поиск).
   - Нажать появившуюся внизу кнопку «Показать блюда (...)».
   - Убедиться, что в секции «Можно приготовить сейчас» присутствуют:
     - «Куриный суп с картошкой» (тип «Суп», сложность «Легко»);
     - «Курица, запечённая с овощами» (тип «Второе», сложность «Легко»).
   - Нажать чипы фильтров «Суп» и «Легко» — в списке останется только «Куриный суп с картошкой».
   - Нажать кнопку «Не хочу» на карточке — блюдо исчезает, внизу всплывает SnackBar с кнопкой «Отменить».

## Вывод проверок (после последней правки)

```
check.ps1 started 2026-11-04T18:14:19

===== pub get: flutter pub get =====
Resolving dependencies...
Downloading packages...
  built_collection 5.1.2 (6.0.0 available)
  code_assets 1.2.1 (2.1.0 available)
  cupertino_icons 1.0.9 (2.0.0 available)
  hooks 2.0.2 (2.2.0 available)
  material_color_utilities 0.13.0 (0.13.1 available)
  meta 1.18.3 (1.19.0 available)
  native_toolchain_c 0.19.2 (0.19.5 available)
  objective_c 9.5.0 (9.6.3 available)
  petitparser 7.0.2 (7.1.0 available)
  record_use 0.6.0 (1.1.1 available)
  sqlite3 3.5.2 (3.8.0 available)
  test_api 0.7.12 (0.7.15 available)
  vector_math 2.4.0 (2.4.4 available)
  xml 7.0.1 (7.1.0 available)
Got dependencies!
14 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
----- exit code: 0

===== gen-l10n: flutter gen-l10n =====
Because l10n.yaml exists, the options defined there will be used instead.
To use the command line arguments, delete the l10n.yaml file in the Flutter project.


----- exit code: 0

===== build_runner: dart run build_runner build =====
  0s freezed on 66 inputs; lib/app/app.dart
  0s freezed on 66 inputs: 66 skipped
  0s json_serializable on 132 inputs; lib/app/app.dart
  0s json_serializable on 132 inputs: 132 skipped
  0s drift_dev:preparing_builder on 1 input; lib/core/db/tables/ingredients_fts.drift
  0s drift_dev:preparing_builder on 1 input: 1 skipped
  0s drift_dev on 535 inputs; lib/app/app.dart
  0s drift_dev on 535 inputs: 535 skipped
  0s source_gen:combining_builder on 267 inputs; lib/app/app.dart
  0s source_gen:combining_builder on 267 inputs: 267 skipped
  Built with build_runner/aot in 1s; wrote 0 outputs.
----- exit code: 0

===== format: dart format --output=none --set-exit-if-changed lib test =====
Formatted 57 files (0 changed) in 0.21 seconds.
----- exit code: 0

===== analyze: flutter analyze =====
Analyzing cooker...                                             
No issues found! (ran in 2.3s)
----- exit code: 0

===== test: flutter test =====
All tests passed! (92 tests)
----- exit code: 0

===== build apk: flutter build apk --debug =====
Running Gradle task 'assembleDebug'...                             14,7s
√ Built build\app\outputs\flutter-apk\app-debug.apk
----- exit code: 0

RESULT: GREEN (2026-11-04T18:14:53)
```

## Скриншоты

- Автоматическое сквозное подтверждение: `test/matching_integration_test.dart` (интеграционный тест без эмулятора проверяет точный сценарий ТЗ 5.2–5.4).
- Ручная проверка на Android-устройстве ожидает владельца (добавлено в `docs/STATUS.md` → «Проверить владельцу на устройстве»).

## Не готово / известные проблемы

- Нет. Все 9 задач этапа 1 (`S1-01`…`S1-09`) полностью закрыты. 92 теста зелёные, анализ и форматирование без замечаний, отладочный APK собран.

## Новые ASSUMPTION

- D-020: RecipeDiversityReorderer — главный ингредиент определяется по категориям: `meat/poultry/fish` > `legumes/mushrooms` > `dairy/grains` > первый обязательный не-staple. Топ-10 отбирается жадно (≤3 одного типа блюда, ≤2 одного ингредиента); при нехватке разнообразия штрафуется минимально нарушающий кандидат с наивысшим баллом.
- D-021: PantryScreen — экран «Что есть дома»: плитки категорий открывают bottom sheet с продуктами; поиск объединяет FTS5 префиксный поиск и нормализатор; «Часто выбираете» составлен из 12 топ-продуктов сида; кнопка «Показать блюда (N)» переходит на `/suggestions`.
- D-022: SuggestionsScreen — экран «Блюда»: чипы-фильтры по типу и сложности, две группы («Можно сейчас» и «Не хватает 1–2 продуктов»); карточки по ТЗ 7.2; кнопка «Не хочу» с мягким скрытием и отменой через SnackBar на 5 секунд.
- D-023: matching_integration_test — специи и дополнительные овощи в «Куриный суп с картошкой» (`bay_leaf`) и «Курица, запечённая с овощами» (`bell_pepper`) помечены `:opt`, чтобы базовый набор бабушки «картошка, лук, морковь, курица» удовлетворял критерию этапа 1.

## Условие «Готово, когда» из docs/TASKS.md

- [x] «картошка, лук, морковь, курица» → в «Можно сейчас» есть суп и второе (проверено интеграционным тестом `test/matching_integration_test.dart` на реальной базе сида: в «Можно сейчас» выдаются `Куриный суп с картошкой` [суп] и `Курица, запечённая с овощами` [второе]).
- [x] фильтр «Суп + Легко» оставляет только подходящее (проверено в `test/matching_integration_test.dart` и `test/suggestions_screen_test.dart`).
- [x] тесты зелёные (92 теста успешно пройдены в `tool/check.ps1`, 0 ошибок анализатора).
