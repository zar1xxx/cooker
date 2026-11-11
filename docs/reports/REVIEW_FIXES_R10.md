# Отчёт R10 — расширение списка продуктов

Дата: 2026-11-11 · Коммиты: `4337e32` (продукты), `bc777d4` (фильтр в разделах), `1673f4b` (рецепты, часть 1), этот коммит (рецепты, часть 2 и отчёт)

## Сделано

| ID | Что сделано | Файлы |
| --- | --- | --- |
| R10-01 | 432 новых продукта, всего 716 | `assets/seed/ingredients.json`, `assets/seed/ingredient_info.json` |
| R10-02 | Дубли id и названий, существование родителей — тест | `test/r10_products_test.dart` |
| R10-03 | Правила нагрева `lamb_game`, `seafood`; перепёлка и цесарка в птице; копчёное, солёное, консервы — готовы к употреблению | `spec/ai/safety_minimums.json` |
| R10-04 | Калорийность 183 новых продуктов | `lib/core/catalog/nutrition_reference.dart` |
| R10-05 | 303 новых рецептов вручную, все `curated` | `assets/seed/recipes/r10_new.json`, `tool/add_r10_recipes.dart` |
| R10-06 | Фильтр «Найти в разделе» | `lib/features/pantry/pantry_screen.dart` |
| R10-07 | `schemaVersion` 5, справочник перечитывается при обновлении | `lib/core/db/app_database.dart` |

Новые рецепты по типам: {'main': 96, 'soup': 19, 'salad': 32, 'side': 21, 'snack': 21, 'baking': 21, 'breakfast': 23, 'dessert': 39, 'drink': 24, 'preserve': 7}.
Сложность новых рецептов (посчитана `DifficultyCalculator`): {'easy': 270, 'medium': 31, 'hard': 2}.
Каталог: 2342 рецептов, `curated` 2080, `template` 262.
В новых рецептах использовано 353 из 432 новых продуктов.

Как добавлялись рецепты: полная пересборка `compile_catalog.dart` начинает с `tool/generator/baseline_125.json` и потеряла бы отметки качества R9, которые хранятся только в `recipes.json`. Поэтому `tool/add_r10_recipes.dart` добавляет рецепты из `r10_new.json` в готовый `recipes.json` и считает калорийность, теги и сложность той же логикой.

## Как проверить вручную

1. `tool\run_check.bat` — `RESULT: GREEN`.
2. В приложении: «Продукты» → «Специи и соусы» → поле «Найти в разделе», ввести «терияки».
3. Отметить дома «горбуша» и открыть подбор блюд: должны найтись «Горбуша в фольге со сметаной» и «Сливочный суп с горбушей».

## Вывод проверок (после последней правки)

```
check.ps1 started 2026-11-11T21:03:21

===== pub get: flutter pub get =====
Resolving dependencies...
Downloading packages...
  built_collection 5.1.2 (6.0.0 available)
  code_assets 1.2.1 (2.2.0 available)
  cross_file 0.3.5+5 (0.4.0 available)
  cupertino_icons 1.0.9 (2.0.0 available)
  drift 2.35.3 (2.35.4 available)
  drift_dev 2.35.2 (2.35.3 available)
  flutter_local_notifications 22.3.3 (23.0.0 available)
  flutter_local_notifications_linux 8.0.2 (9.0.0 available)
  flutter_local_notifications_platform_interface 12.2.0 (13.0.0 available)
  flutter_local_notifications_web 1.0.0 (2.0.0 available)
  flutter_local_notifications_windows 3.1.1 (4.0.0 available)
  flutter_riverpod 3.4.3 (3.5.0 available)
  go_router 18.1.2 (18.1.4 available)
  hooks 2.0.2 (2.2.0 available)
  material_color_utilities 0.13.0 (0.13.1 available)
  material_ui 1.10.0 (1.11.0 available)
  meta 1.18.3 (1.19.0 available)
  native_toolchain_c 0.19.2 (0.19.6 available)
  objective_c 9.5.0 (9.6.3 available)
  permission_handler 11.3.1 (13.0.2 available)
  permission_handler_android 12.1.0 (14.1.1 available)
  petitparser 7.0.2 (7.1.0 available)
  record_use 0.6.0 (1.1.1 available)
  riverpod 3.4.3 (3.5.0 available)
  sqlite3 3.5.2 (3.9.1 available)
  test_api 0.7.12 (0.7.15 available)
  vector_math 2.4.0 (2.4.4 available)
  xml 7.0.1 (7.1.0 available)
Got dependencies!
28 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
----- exit code: 0

===== gen-l10n: flutter gen-l10n =====
Because l10n.yaml exists, the options defined there will be used instead.
To use the command line arguments, delete the l10n.yaml file in the Flutter project.


----- exit code: 0

===== build_runner: dart run build_runner build =====
  0s freezed on 224 inputs; lib/app/app.dart
  0s freezed on 224 inputs: 224 skipped
  0s json_serializable on 448 inputs; lib/app/app.dart
  0s json_serializable on 448 inputs: 448 skipped
  0s drift_dev:preparing_builder on 1 input; lib/core/db/tables/ingredients_fts.drift
  0s drift_dev:preparing_builder on 1 input: 1 skipped
  0s drift_dev on 1799 inputs; lib/app/app.dart
  0s drift_dev on 1799 inputs: 1799 skipped
  0s source_gen:combining_builder on 899 inputs; lib/app/app.dart
  0s source_gen:combining_builder on 899 inputs: 899 skipped
  Built with build_runner/aot in 1s; wrote 0 outputs.
----- exit code: 0

===== format: dart format --output=none --set-exit-if-changed lib test =====
Formatted 200 files (0 changed) in 0.85 seconds.
----- exit code: 0

===== analyze: flutter analyze =====
Analyzing cooker...                                             
No issues found! (ran in 3.0s)
----- exit code: 0

… (имена 1078 тестов, все без [E]) …
00:55 +1078: All tests passed!
----- exit code: 0

RESULT: GREEN (2026-11-11T21:04:32)
```

## Не готово / известные проблемы

- 79 новых продуктов пока не встречаются ни в одном рецепте: adjika_green, anise, apple_puree, asafoetida, bamboo_shoots, beef_bones, beets_pickled, capelin_caviar, cayenne, celery_leaves, celery_seed, cherries_in_syrup, cherry_tomato_yellow, chicken_back, chicken_canned, chicken_spices, chives, coconut_cream, coconut_oil, condensed_cocoa, corn_baby, corn_oil, cucumber_salted, dandelion, dried_basil, dried_dill, dried_onion, dried_parsley, eel_smoked, eggplant_caviar, eggplant_white, essence_vinegar, fenugreek, fish_spices, frozen_broccoli, frozen_peas_carrot, garlic_sauce, gelatin_sugar, gherkin, ginger_ground, green_tomato, leaf_parsley, leek_young, linseed_oil, long_cucumber, lovage, melissa, milk_mushroom, miso, mustard_powder, pate_liver, pea_shoots, peaches_canned, pepper_mix, pickling_spice, pink_tomato, pork_ham_leg, pork_skin, pumpkin_oil, purslane, refined_oil, roasted_peppers, salt_iodized, salted_salmon, satsebeli, savory, seaweed_salad, sorrel_young, squash_caviar, sriracha, stewed_pork, sun_dried_tomato, tabasco, tartar_sauce, tomato_ketchup_spicy, wasabi, water_chestnut, worcestershire, zucchini_yellow.
- Критерий плана «≥ 2 рецепта на каждый новый продукт» не выполнен; выполнен критерий «новых рецептов не меньше 300».
- 262 шаблонных рецепта из R9 не трогал: их составы нужно править отдельно (`docs/reports/rewrite/needs_ingredients.md`).
- Новый APK не собирался; на телефоне не проверено.

## Условие приёмки из docs/R10_PRODUCT_EXPANSION.md

- [x] Продуктов не меньше 700 (716), у каждого категория, синонимы — тест. Единицы измерения задаются в рецептах, отдельного поля у продукта нет.
- [x] Нет дублей id и названий; все `parent_id` существуют — тест.
- [x] Для нового мяса, рыбы, птицы, грибов, яиц и бобовых есть правила нагрева — тест.
- [x] Новых рецептов 303; все проходят `RecipeValidator` (`seed_recipes_valid_test`) и проверки качества seed.
- [x] Все тесты проходят — прогон выше. Поиск по продуктам — FTS, как раньше; замер скорости на телефоне не делался.
