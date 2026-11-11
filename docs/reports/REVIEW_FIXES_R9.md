# Отчёт R9 — переписывание шаблонных рецептов

Дата: 2026-11-11 · Коммиты: `0ad6975` (R9), `d437ee7` (R7-07..R7-10, исправления тестов ленты)

## Сделано

| Что | Итог | Файлы |
| --- | --- | --- |
| Ручная перепись шагов, описаний и времени | 1777 рецептов `quality: curated` из 2039 | `assets/seed/recipes.json`, `tool/seed_data/rewrite/batch_001..052.json`, `applied_ids.txt` |
| Пропуски с причиной | 262 рецепта остаются `template` | `tool/seed_data/rewrite/skipped_ids.txt`, `docs/reports/rewrite/needs_ingredients.md` |
| Сводка | счётчики и группы пропусков | `docs/reports/rewrite/PROGRESS.md` |
| Тесты ленты (R7) | зелёные; причины падений — в журнале `docs/STATUS.md` | `test/feed_screen_test.dart` |

Сложность после переписи (из `recipes.json`): curated — easy 1465, medium 292, hard 20; template — easy 240, medium 22.

Пропуски по группам: {'soup': 74, 'porridge': 37, 'fish': 33, 'veg': 25, 'meat': 20, 'salad': 17, 'ed': 15, 'pres': 15, 'bake': 12, 'des': 10, 'bev': 4}.
Главная причина (220 из 262): в названии есть продукт, которого нет в составе («с чесноком» без чеснока и т. п.). Такие рецепты нельзя честно переписать без правки состава — это задача R10.

## Как проверить вручную

1. `tool\run_check.bat` — должен быть `RESULT: GREEN`.
2. В приложении открыть несколько супов, салатов, десертов: у переписанных нет пометки «Упрощённая карточка», шаги конкретные, с временем.

## Вывод проверок (после последней правки)

Полный файл — `docs/reports/last_check.txt` (3055 строк, в `.gitignore`). Ниже всё, кроме списка имён тестов:

```
check.ps1 started 2026-11-11T18:21:39

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
  0s freezed on 222 inputs; lib/app/app.dart
  0s freezed on 222 inputs: 221 skipped, 1 no-op
  0s json_serializable on 444 inputs; lib/app/app.dart
  6s json_serializable on 444 inputs: 294 skipped, 1 no-op; spent 5s analyzing; test/feed_screen_test.freezed.dart
  6s json_serializable on 444 inputs: 443 skipped, 1 no-op; spent 5s analyzing
  0s drift_dev:preparing_builder on 1 input; lib/core/db/tables/ingredients_fts.drift
  0s drift_dev:preparing_builder on 1 input: 1 skipped
  0s drift_dev on 1783 inputs; lib/app/app.dart
  0s drift_dev on 1783 inputs: 1780 skipped, 2 output, 1 no-op
  0s source_gen:combining_builder on 891 inputs; lib/app/app.dart
  0s source_gen:combining_builder on 891 inputs: 891 skipped
  Built with build_runner/aot in 7s; wrote 2 outputs.
----- exit code: 0

===== format: dart format --output=none --set-exit-if-changed lib test =====
Formatted 199 files (0 changed) in 0.87 seconds.
----- exit code: 0

===== analyze: flutter analyze =====
Analyzing cooker...                                             
No issues found! (ran in 3.2s)
----- exit code: 0

… (строки 71–3051: имена 1071 теста, все без [E]) …
00:48 +1071: All tests passed!
----- exit code: 0

RESULT: GREEN (2026-11-11T18:22:48)
```

## Не готово / известные проблемы

- 262 рецепта остаются `template` (см. `needs_ingredients.md`).
- Выборки `sample_NNN.md` устарели; владелец ещё не просматривал рецепты (пункт 7 в «Проверить владельцу» `docs/STATUS.md`).
- Новый APK после R9 не собирался.

## Условие приёмки из docs/R9_RECIPE_REWRITE.md

- [x] `check.ps1` GREEN — прогон 2026-11-11 18:22:48.
- [x] Линтер curated зелёный — `curated_recipes_lint_test.dart` в прогоне.
- [x] Нет шага, повторяющегося более чем в 3 рецептах — правило линтера.
- [x] Распределение сложности не «всё easy» — см. выше.
- [ ] Выборки просмотрены владельцем — не сделано.
- [x] В отчёте указано, сколько переписано и пропущено и почему.
