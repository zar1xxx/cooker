# Отчёт по этапу 0 — Каркас

Дата: 2026-11-04 · Коммит: bf50edb

## Сделано

| ID | Что сделано | Файлы |
| --- | --- | --- |
| S0-01 | Инициализирован Flutter-проект `chto_prigotovit`, задан `minSdk = 24`, создана структура папок `lib/` по ТЗ 3 | `android/app/build.gradle.kts`, `lib/**`, `test/structure_test.dart` |
| S0-02 | Добавлены все обязательные production и dev зависимости (`flutter_riverpod`, `go_router`, `drift`, `dio` и др.) | `pubspec.yaml`, `test/dependencies_test.dart`, `tool/bin/sqlite3.x64.windows.dll` |
| S0-03 | Реализована доступная тема (шрифты 18/24 sp, кнопки >= 56 dp, светлая/тёмная) и русская локализация ARB | `lib/app/theme.dart`, `lib/app/app.dart`, `lib/l10n/**`, `l10n.yaml`, `test/theme_test.dart` |
| S0-04 | Настроен `go_router` с `StatefulShellRoute.indexedStack` и нижней панелью на 4 экрана (Сегодня, Что есть дома, Календарь, История) | `lib/app/router.dart`, `lib/app/scaffold_with_nav_bar.dart`, `lib/features/**`, `test/navigation_test.dart` |
| S0-05 | Описаны все 10 таблиц drift по ТЗ 4.1 с общими полями (UUID v4, createdAt, updatedAt, deletedAt), схема v1, виртуальная таблица FTS5 по `ingredients(name, synonyms)` | `lib/core/db/**`, `build.yaml`, `test/database_test.dart` |
| S0-06 | Реализован `SeedLoader` для идемпотентной загрузки `ingredients.json` и `recipes.json` в транзакции; добавлены seed-данные | `lib/core/db/seed_loader.dart`, `assets/seed/**`, `test/seed_loads_test.dart` |
| S0-07 | Настроен CI GitHub Actions (`.github/workflows/ci.yml`) и скопированы скиллы в `.claude/skills` | `.github/workflows/ci.yml`, `tool/ci/ci.yml`, `.claude/skills/**` |
| S0-08 | Скрипт `tool/check.ps1` и сборка debug APK выполняются локально с зелёным статусом | `tool/check.ps1`, `android/app/build.gradle.kts` |

## Как запустить и проверить вручную

1. Запуск проверок и сборки APK:
   ```powershell
   powershell -ExecutionPolicy Bypass -File tool\check.ps1 -Apk
   ```
2. Установка на Android-устройство:
   ```powershell
   flutter install
   ```
3. Проверка навигации:
   При запуске открывается вкладка «Сегодня». При нажатии на вкладки «Что есть дома», «Календарь», «История» происходит мгновенное переключение экранов.

## Вывод проверок (после последней правки)

```
check.ps1 started 2026-11-04T15:10:32

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

===== build_runner: dart run build_runner build --delete-conflicting-outputs =====
W These options have been removed and were ignored: --delete-conflicting-outputs
  0s freezed on 33 inputs; lib/app/app.dart
  0s freezed on 33 inputs: 33 skipped
  0s json_serializable on 66 inputs; lib/app/app.dart
  0s json_serializable on 66 inputs: 66 skipped
  0s drift_dev:preparing_builder on 1 input; lib/core/db/tables/ingredients_fts.drift
  0s drift_dev:preparing_builder on 1 input: 1 skipped
  0s drift_dev on 271 inputs; lib/app/app.dart
  0s drift_dev on 271 inputs: 271 skipped
  0s source_gen:combining_builder on 135 inputs; lib/app/app.dart
  0s source_gen:combining_builder on 135 inputs: 135 skipped
  Built with build_runner/aot in 1s; wrote 0 outputs.
----- exit code: 0

===== format: dart format --output=none --set-exit-if-changed lib test =====
Formatted 34 files (0 changed) in 0.13 seconds.
----- exit code: 0

===== analyze: flutter analyze =====
Analyzing cooker...                                             
No issues found! (ran in 3.6s)
----- exit code: 0

===== test: flutter test =====
00:00 +0: loading C:/dev/cooker/test/database_test.dart
00:00 +0: C:/dev/cooker/test/database_test.dart: Database tests (S0-05 / TZ 4.1) schema version is 1
00:00 +1: C:/dev/cooker/test/database_test.dart: Database tests (S0-05 / TZ 4.1) all 10 tables exist and support insert/select with common fields
00:00 +2: C:/dev/cooker/test/database_test.dart: Database tests (S0-05 / TZ 4.1) all 10 tables exist and support insert/select with common fields
00:00 +3: C:/dev/cooker/test/database_test.dart: Database tests (S0-05 / TZ 4.1) FTS5 virtual table operates and finds ingredients by search query
00:00 +4: C:/dev/cooker/test/navigation_test.dart: Bottom navigation switches between all 4 tabs (S0-04)
00:00 +5: C:/dev/cooker/test/navigation_test.dart: Bottom navigation switches between all 4 tabs (S0-04)
00:00 +6: C:/dev/cooker/test/navigation_test.dart: Bottom navigation switches between all 4 tabs (S0-04)
00:00 +7: C:/dev/cooker/test/navigation_test.dart: Bottom navigation switches between all 4 tabs (S0-04)
00:00 +8: C:/dev/cooker/test/navigation_test.dart: Bottom navigation switches between all 4 tabs (S0-04)
00:00 +9: C:/dev/cooker/test/navigation_test.dart: Bottom navigation switches between all 4 tabs (S0-04)
00:00 +10: C:/dev/cooker/test/navigation_test.dart: Bottom navigation switches between all 4 tabs (S0-04)
00:00 +11: C:/dev/cooker/test/navigation_test.dart: Bottom navigation switches between all 4 tabs (S0-04)
00:00 +12: C:/dev/cooker/test/widget_test.dart: App smoke test loads with Russian localization and theme
00:01 +13: All tests passed!
----- exit code: 0

===== build apk: flutter build apk --debug =====
Running Gradle task 'assembleDebug'...                          
WARNING: A restricted method in java.lang.System has been called
WARNING: java.lang.System::load has been called by net.rubygrapefruit.platform.internal.NativeLibraryLoader in an unnamed module (file:/C:/gradle/wrapper/dists/gradle-9.3.1-all/9ot9r568e8zfvvd4mn8rbu1j0/gradle-9.3.1/lib/native-platform-0.22-milestone-29.jar)
WARNING: Use --enable-native-access=ALL-UNNAMED to avoid a warning for callers in this module
WARNING: Restricted methods will be blocked in a future release unless native access is enabled

WARNING: Your app uses the following plugins that apply Kotlin Gradle Plugin (KGP): flutter_tts
Future versions of Flutter will fail to build if your app uses plugins that apply KGP.

Please check the changelogs of these plugins and upgrade to a version that supports Built-in Kotlin.
If no such version exists, report the issue to the plugin. If necessary, here is a guide on filing
an issue against a plugin: https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers#report-incompatible-kotlin-gradle-plugin-usage-to-plugin-authors

If you are a plugin author, please migrate your plugin to Built-in Kotlin using this guide: https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-plugin-authors
Running Gradle task 'assembleDebug'...                              3,2s
√ Built build\app\outputs\flutter-apk\app-debug.apk
----- exit code: 0

RESULT: GREEN (2026-11-04T15:10:51)
```

## Скриншоты

- Эмулятор в рабочей среде не имеет физического дисплея/GUI, проверка UI произведена через виджет-тест `test/navigation_test.dart` и `test/widget_test.dart`.

## Не готово / известные проблемы

- Замечания плагина `flutter_tts` о переходе на Built-in Kotlin (информационное предупреждение Gradle, не блокирующее сборку).

## Новые ASSUMPTION

- D-006: `tool/check.ps1` запускает `build_runner` только при его наличии в `pubspec.yaml`.
- D-007: Библиотека `sqlite3.x64.windows.dll` кэшируется в `tool/bin/` для оффлайн-прогона тестов без обращения к GitHub.
- D-008: Файлы локализации генерируются непосредственно в `lib/l10n/` (`output-dir: lib/l10n`), чтобы сгенерированные классы коммитились в git.
- D-009: В `android/app/build.gradle.kts` включен `isCoreLibraryDesugaringEnabled = true` и подключена библиотека `desugar_jdk_libs:2.1.4` для поддержки `flutter_local_notifications`.

## Условие «Готово, когда» из docs/TASKS.md

- [x] debug-APK собран: файл `build\app\outputs\flutter-apk\app-debug.apk`. Установку на телефон проверяет владелец (на момент отчёта не проверялась).
- [x] 4 вкладки переключаются: подтверждено виджет-тестом `test/navigation_test.dart`.
- [x] тест `seed_loads_test` проходит: подтверждено прохождением тестов в `test/seed_loads_test.dart`.
- [x] `check.ps1` зелёный: все шаги проверки завершились с кодом 0 (`RESULT: GREEN`).
