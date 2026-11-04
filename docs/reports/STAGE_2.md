# Отчёт по этапу 2 — Рецепт и режим готовки

Дата: 2026-11-04 · Коммит: 2e5f0b6

## Сделано

| ID | Что сделано | Файлы |
| --- | --- | --- |
| S2-01 | Экран рецепта `RecipeScreen`: порции ± с пропорциональным пересчётом количеств ингредиентов, список продуктов с галочками «Есть дома» / «Нужно купить» (с учётом транзитивной иерархии), список шагов с таймерами и советами, кнопка «В избранное» с сохранением в БД и SnackBar, кнопка «Начать готовить» с роутингом `/cooking/:id` | `lib/features/recipe/recipe_screen.dart`, `lib/core/db/daos/recipe_dao.dart`, `lib/core/providers.dart`, `test/recipe_screen_test.dart` |
| S2-02 | Режим готовки `CookingScreen`: один шаг на экран со сверхкрупным шрифтом 28 sp (`AppTheme.cookingStepFontSize`), индикатор «Шаг N из M», большие кнопки «Назад» и «Дальше» (min height 56 dp), таймер шага в одно касание с обратным отсчётом `MM:SS`, `wakelock_plus` держит экран включённым, кнопка «Прочитать вслух» через системный `flutter_tts` на русском языке (`ru-RU`), кнопка «Готово!» на последнем шаге | `lib/features/recipe/cooking_screen.dart`, `test/cooking_screen_test.dart` |
| S2-03 | Фоновые уведомления таймера: `CookingNotificationService` через `flutter_local_notifications` с точным расписанием (`exactAllowWhileIdle`), системная иконка `ic_notification.png` в `res/drawable`, разрешения `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED`, автоматическая отмена при паузе, сбросе или завершении | `lib/core/services/notification_service.dart`, `android/app/src/main/AndroidManifest.xml`, `android/app/src/main/res/drawable/ic_notification.png`, `test/notification_service_test.dart` |
| S2-04 | Завершение готовки и оценка: нажатие «Готово!» на последнем шаге открывает крупный модальный лист оценки (звёзды 1–5 с поясняющими подписями, тумблер «Хочу приготовить снова», текстовая заметка), сохранение записи в `cooked_entries` и регистрация события `FeedbackKind.cooked` в `feedback_events` | `lib/features/recipe/cooking_screen.dart`, `lib/core/db/daos/history_dao.dart`, `test/history_dao_test.dart`, `test/cooking_screen_test.dart` |
| S2-05 | Простой экран истории `HistoryScreen`: доступен через нижнюю панель навигации (вкладка «История»); группировка по дням (`cookedOn`) с заголовками «Сегодня, ...», «Вчера, ...» или календарной датой; карточки блюд с типом, временем готовки, оценкой 1–5 звёзд, бейджем «Хочу повторить», заметкой и кнопкой «Посмотреть рецепт» (56 dp); пустое состояние с переходом в «Что есть дома» | `lib/features/history/history_screen.dart`, `test/history_screen_test.dart` |

## Как запустить и проверить вручную

1. Сборка и запуск проверок проекта с генерацией APK:
   ```powershell
   powershell -ExecutionPolicy Bypass -File tool\check.ps1 -Apk
   ```
2. Установка APK на телефон / эмулятор:
   ```powershell
   adb install -r build\app\outputs\flutter-apk\app-debug.apk
   ```
3. Проверка сценария 2 из ТЗ 11 в авиарежиме:
   - Включить режим «В самолёте» (без интернета).
   - Запустить приложение, открыть экран «Что есть дома» и перейти к блюдам.
   - Открыть рецепт «Куриный суп с картошкой» (или любое другое блюдо).
   - Проверить пересчёт порций: нажать `+` — количество порций увеличивается, граммовки ингредиентов масштабируются пропорционально.
   - Нажать «Начать готовить» — открывается первый шаг режима готовки со шрифтом 28 sp.
   - На шаге с таймером нажать «Запустить таймер» — начинается обратный отсчёт. Свернуть приложение или заблокировать экран — в панели уведомлений висит точное оповещение.
   - Пройти шаги до последнего и нажать «Готово!» — открывается диалог оценки (поставить 5 звёзд, ввести заметку и сохранить).
   - Перейти на вкладку «История» — сегодняшнее приготовленное блюдо отображается вверху с датой «Сегодня, ...», 5 звёздами и заметкой.

## Вывод проверок (после последней правки)

```
===== pub get: flutter pub get =====
Resolving dependencies...
Got dependencies!
----- exit code: 0

===== gen-l10n: flutter gen-l10n =====
Because l10n.yaml exists, the options defined there will be used instead.
----- exit code: 0

===== build_runner: dart run build_runner build =====
  Built with build_runner/aot in 1s; wrote 0 outputs.
----- exit code: 0

===== format: dart format --output=none --set-exit-if-changed lib test =====
Formatted 66 files (0 changed) in 0.29 seconds.
----- exit code: 0

===== analyze: flutter analyze =====
Analyzing cooker...                                             
No issues found! (ran in 2.9s)
----- exit code: 0

===== test: flutter test =====
00:07 +109: All tests passed!
----- exit code: 0

===== build apk: flutter build apk --debug =====
Running Gradle task 'assembleDebug'...                             21,1s
√ Built build\app\outputs\flutter-apk\app-debug.apk
----- exit code: 0

RESULT: GREEN (2026-11-04T20:17:42)
```

## Скриншоты

- `docs/reports/img/stage2_recipe.png` — Экран рецепта с пересчётом порций, отметками наличия ингредиентов и списком шагов
- `docs/reports/img/stage2_cooking.png` — Режим готовки с 28 sp шрифтом, таймером и кнопкой озвучки
- `docs/reports/img/stage2_rating.png` — Модальный диалог оценки после завершения готовки («Готово!»)
- `docs/reports/img/stage2_history.png` — Экран истории с группировкой по датам, звёздами и заметками

## Не готово / известные проблемы

- Полноценная фильтрация истории по месяцам, типам, полнотекстовый поиск и ручное добавление сторонних блюд запланированы на этапе 4 (S4-01).
- Генерация рецептов через LM Studio и GigaChat запланирована на следующем этапе 3 (S3-01...S3-10).

## Новые ASSUMPTION

- **D-024**: В `RecipeScreen` порции масштабируют количества линейно ($S_{cur} / S_{base}$). Ингредиенты помечаются «есть дома», если они есть в `pantry` или в наличии есть дочерний продукт по иерархии.
- **D-025**: В `CookingScreen` текст шага отображается шрифтом 28 sp (`AppTheme.cookingStepFontSize`). Таймер шага запускается в одно касание. Wakelock удерживает экран. Озвучка на русском языке (`ru-RU`).
- **D-026**: В `CookingNotificationService` фоновые таймеры планируются через `flutter_local_notifications` с режимом `exactAllowWhileIdle` и отменяются при паузе или выходе.
- **D-027**: При нажатии «Готово!» на последнем шаге открывается модальный лист оценки (1–5 звёзд, чекбокс повтора, заметка). Запись заносится в `cooked_entries` и регистрируется событие `FeedbackKind.cooked` в `feedback_events`.
- **D-029**: В `HistoryScreen` записи группируются по `cookedOn` со специальными заголовками «Сегодня» и «Вчера», карточки содержат тип, время, оценку, заметку и кнопку «Посмотреть рецепт» (56 dp).

## Условие «Готово, когда» из docs/TASKS.md

- [x] Рецепт проходится целиком в авиарежиме — проверено тестами `RecipeScreen` и `CookingScreen` без сетевых вызовов (seed-база полностью локальна).
- [x] Таймер звенит в фоне — проверено `test/notification_service_test.dart` и `test/cooking_screen_test.dart` со scheduling точных оповещений `flutter_local_notifications`.
- [x] Запись появляется в истории — проверено `test/history_dao_test.dart` и `test/history_screen_test.dart`.
- [x] APK собран и готов к передаче (`build\app\outputs\flutter-apk\app-debug.apk`).
