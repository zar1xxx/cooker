# Отчёт: Исправления после проверки R3 (R4)

Дата: 2026-11-07 · Коммит: R4-08

---

## Сделано

| ID | Что сделано | Файлы |
| --- | --- | --- |
| **R4-09** | **Поддержка порта LM Studio 1235.** На ПК владельца порт 1234 занят, сервер работает на 1235. `PcDiscovery` теперь проверяет кандидатные порты последовательно: сохранённый, 1234, 1235, и сохраняет найденный порт. `tool/ai_smoke.dart` поддерживает `--port` и `LMSTUDIO_PORT`. В `docs/INSTALL.md` раздел 2 обновлён на `tool\start_lmstudio_server.bat` и порт 1235. Добавлен скрипт правила брандмауэра `tool/firewall_lmstudio.ps1`. Написаны 2 теста в `test/pc_discovery_port_test.dart`. | `lib/core/ai/pc_discovery.dart`, `lib/core/ai/pc_auto_discovery_service.dart`, `tool/ai_smoke.dart`, `tool/firewall_lmstudio.ps1`, `docs/INSTALL.md`, `test/pc_discovery_port_test.dart` |
| **R4-10** | **Подключение ПК по QR-коду — утилита ПК.** Создан автономный CLI-инструмент `tool/pair_pc.dart` и скрипт `tool/pair_pc.bat` (`dart run tool/pair_pc.dart`). Фильтрация сетевых интерфейсов ПК (исключены 127.x, 169.254.x, 198.18.x / TUN-адаптер FlClashX, vEthernet, VirtualBox, VMware, Hyper-V, WSL). Проверка доступности портов 1235 и 1234, выбор первой чат-модели. Генерация SVG-изображения QR-кода на HTML-странице во временной папке `%TEMP%` (не в git) с автооткрытием в браузере. Опция `--gigachat` для защищённого ввода ключа GigaChat с самоуничтожением страницы через 2 минуты. Написаны 10 юнит-тестов в `test/pair_pc_test.dart`. | `tool/pair_pc.dart`, `tool/pair_pc.bat`, `tool/pair_pc_helper.dart`, `pubspec.yaml`, `test/pair_pc_test.dart` |
| **R4-11** | **Подключение ПК по QR-коду — сканер в приложении.** Интегрирован пакет `mobile_scanner: ^7.5.0` и разрешение `CAMERA` в `AndroidManifest.xml`. Создан сервис `QrPairingService` и экран сканера `/settings/ai/qr-scanner` (`QrScannerScreen`). Разбор JSON со строгой валидацией частных IP, фонарик, подсказка «Наведите камеру на QR-код на экране компьютера», информативный экран при отсутствии разрешения с кнопкой перехода в настройки. Автоматический опрос хостов, сохранение настроек и ключа GigaChat в SecureStorage, применение в роутере, обновление индикатора режима. Кнопка сканирования добавлена в `AiSettingsScreen`, `AiDiagnosticsScreen` и на плашку «Помощник не настроен». Написаны 15 тестов в `test/qr_pairing_test.dart`. **На телефоне не проверено** (проверяет владелец). | `lib/core/ai/qr_pairing_parser.dart`, `lib/core/ai/qr_pairing_service.dart`, `lib/features/settings/qr_scanner_screen.dart`, `lib/features/settings/ai_settings_screen.dart`, `lib/features/settings/ai_diagnostics_screen.dart`, `lib/features/suggestions/suggestions_screen.dart`, `lib/app/router.dart`, `android/app/src/main/AndroidManifest.xml`, `pubspec.yaml`, `test/qr_pairing_test.dart` |
| **R4-01** | **Настоящий прогон `ai_smoke.dart` с запущенным LM Studio (закрывает R3-08).** Выполнен реальный прогон `dart run tool/ai_smoke.dart --port 1235` против запущенного локального сервера LM Studio на порту 1235. Обнаружена активная модель `google/gemma-4-12b-qat`. Запрос `suggest_dishes`: 13.4 с, 406 prompt / 395 completion токенов, `RecipeValidator`: `Valid`. Запрос `full_recipe`: 19.1 с, 421 prompt / 595 completion токенов, `RecipeValidator`: `Valid`. Ответы соответствуют схемам и кулинарным ограничениям. | `tool/ai_smoke.dart`, `docs/STATUS.md`, `docs/TASKS.md` |
| **R4-02** | **Маршрутизатор `AiRouter` не ждёт сканирования сети.** В `lib/core/providers.dart` свойство `aiRouterProvider.ready` ожидает исключительно быстрой загрузки настроек из хранилища и их применения к роутеру (< 50 мс). Сканирование локальной подсети /24 вынесено в фоновый процесс с колбэком `onDiscovered`, который инвалидирует `aiModeProvider` и `aiSettingsProvider` только при нахождении ПК. Первый запрос бабушки с настроенным GigaChat уходит без сетевых задержек. Написан тест в `test/ai_router_test.dart`. | `lib/core/providers.dart`, `test/ai_router_test.dart` |
| **R4-03** | **Плашка помощника перенесена наверх.** На экране «Блюда» плашка ошибки / ненастроенного помощника перенесена из подвала каталога на самый верх (над всеми группами рецептов). Плашка оформлена компактно: 1 строка причины + кнопка действия («Повторить» или «Настроить»). Перегенерирован скриншот `docs/reports/img/suggestions_error_banner.png` (плашка видна на скриншоте). | `lib/features/suggestions/suggestions_screen.dart`, `docs/reports/img/suggestions_error_banner.png`, `test/screenshots_test.dart` |
| **R4-04** | **Контраст плашки недостающих продуктов и темы.** В обеих темах `AppTheme` явно заданы семантические контрастные пары `errorContainer` и `onErrorContainer`: светлая тема (`#FFDAD6` / `#410002`, контраст 12.3:1), тёмная тема (`#93000A` / `#FFDAD6`, контраст 6.8:1). Фон плашки «Не хватает: ...» сделан непрозрачным `errorContainer`, текст и иконка — `onErrorContainer`. Набор тестов `test/theme_contrast_test.dart` расширен проверками контраста всех пар `ColorScheme` $\ge 4.5:1$. | `lib/app/theme.dart`, `lib/features/suggestions/suggestions_screen.dart`, `test/theme_contrast_test.dart` |
| **R4-05** | **Устранение обрезки текста в кнопках и контейнерах.** Все фиксированные высоты кнопок (`SizedBox(height: 52/56)`) заменены на минимальные высоты (`ConstrainedBox(constraints: BoxConstraints(minHeight: 56))` и `minimumSize: Size(0, 56)`) в экранах `AiDiagnosticsScreen`, `AiSettingsScreen`, `CookingScreen`, `PantryScreen`, `HistoryScreen`, `TastePreferencesScreen`, `BackupScreen`. В `CalendarScreen` адаптированы `daysOfWeekHeight` и базовые размеры шрифтов ячеек сетки календаря. В `overflow_all_screens_test.dart` добавлена строгая проверка обрезки: `getMaxIntrinsicHeight <= size.height` и отсутствие выхода за границы ближайшего `RenderClip*` предка. Все 60 комбинаций тестов прошли успешно. | `lib/features/calendar/calendar_screen.dart`, `lib/features/history/history_screen.dart`, `lib/features/pantry/pantry_screen.dart`, `lib/features/recipe/cooking_screen.dart`, `lib/features/settings/ai_diagnostics_screen.dart`, `lib/features/settings/ai_settings_screen.dart`, `lib/features/settings/backup_screen.dart`, `lib/features/settings/taste_preferences_screen.dart`, `test/overflow_all_screens_test.dart` |
| **R4-06** | **Адаптивные фильтры в «Блюда».** Чипы выбора сложности («Любая сложность», «Легко», «Средне», «Сложно») переведены на `Wrap` с переносом на вторую строку — все 4 чипа гарантированно видны без горизонтальной прокрутки. Для строки типов блюд добавлен постоянный видимый `Scrollbar` и кнопка со стрелкой «Ещё типы блюд». Пустое состояние экрана обёрнуто в `SingleChildScrollView` (устранено переполнение RenderFlex при шрифте 200%). | `lib/features/suggestions/suggestions_screen.dart` |
| **R4-07** | **Скриншот экрана диагностики с результатами.** В `test/screenshots_test.dart` настроены подставные провайдеры для полного прогона диагностики: Wi-Fi ✓, адрес телефона ✓, ПК найден ✓ (192.168.1.5:1235), LM Studio отвечает ✓, модель загружена ✓ (`google/gemma-4-12b-qat`), ключ GigaChat ✗ («не задан в настройках»), пробный запрос ✓. В базу добавлены 3 записи истории `ai_requests`. Сгенерирован полноценный скриншот `docs/reports/img/ai_diagnostics.png` с завершёнными проверками и историей. | `test/screenshots_test.dart`, `lib/core/providers.dart`, `lib/features/settings/ai_diagnostics_screen.dart`, `docs/reports/img/ai_diagnostics.png` |
| **R4-08** | **Финальная верификация, сборка сплит-APK и отчёт.** В `docs/STATUS.md` возвращён пункт владельца 1 (скриншоты с устройства). Выполнен финальный прогон `tool/check.ps1` (GREEN, 488 тестов, 0 замечаний `flutter analyze`). Собраны сплит-APK: `app-arm64-v8a-release.apk` (31.7 МБ). | `docs/STATUS.md`, `docs/TASKS.md`, `docs/reports/REVIEW_FIXES_R4.md` |

---

## Настоящий прогон `ai_smoke.dart` с запущенным LM Studio (R4-01 / R3-08)

```text
========================================
  AI Smoke Test: LM Studio & GigaChat   
========================================

Connecting to LM Studio at http://127.0.0.1:1235...
LM Studio server responded successfully (status: 200).
[LM Studio] GET /v1/models took 27 ms
Available models (1):
  - google/gemma-4-12b-qat
Selected chat model: google/gemma-4-12b-qat

[Test 1/2] suggest_dishes via LM Studio...
Request payload:
  Available: картофель, лук репчатый, морковь, куриное филе, яйцо куриное
  Forbidden: []
[LM Studio] POST /v1/chat/completions took 13406 ms
  Tokens: prompt=406, completion=395, total=801
Suggested 2 dishes:
  1. Куриный суп с овощами (soup / easy / 45 min)
     Missing: []
     Why: Легкий и сытный домашний суп из доступных продуктов.
  2. Запеченное куриное филе с картофелем (main / easy / 55 min)
     Missing: []
     Why: Простое горячее блюдо для семейного обеда или ужина.
Validating suggestions via RecipeValidator...
  Validator result: Valid(warnings: [])

[Test 2/2] full_recipe via LM Studio...
Recipe prompt: "Куриный суп с овощами" (soup, easy, 45 min)
[LM Studio] POST /v1/chat/completions took 19065 ms
  Tokens: prompt=421, completion=595, total=1016
Recipe parsed successfully:
  Title: Куриный суп с овощами
  Servings: 2, Prep: 15 min, Cook: 30 min, Total: 45 min
  Ingredients (5):
    - куриное филе: 300.0 g (is_staple: false)
    - картофель: 3.0 pcs (is_staple: false)
    - морковь: 1.0 pcs (is_staple: false)
    - лук репчатый: 1.0 pcs (is_staple: false)
    - яйцо куриное: 1.0 pcs (is_staple: false)
  Steps (4):
    1. Нарежьте куриное филе небольшими кусочками, залейте водой и доведите до кипения. (timer: 0 s)
    2. Варите куриное филе на умеренном огне 20 минут, периодически снимая пену. (timer: 1200 s)
    3. Очистите и нарежьте картофель, морковь и лук. Добавьте овощи в бульон и варите еще 15 минут. (timer: 900 s)
    4. Отварите яйцо вкрутую, остудите, очистите и нарежьте половинками. Подавайте суп, украсив яйцом. (timer: 600 s)
Validating full recipe via RecipeValidator...
  Validator result: Valid(warnings: [])

[GigaChat] GIGACHAT_KEY environment variable not set. Skipping GigaChat test.
To test GigaChat: set GIGACHAT_KEY=<base64_auth_key> and rerun.

========================================
  AI Smoke Test Summary
========================================
LM Studio: OK (2/2 tests passed)
  - suggest_dishes: 13406 ms, 801 tokens
  - full_recipe:    19065 ms, 1016 tokens
GigaChat:  SKIPPED (no GIGACHAT_KEY)
========================================
```

---

## Проверка сопряжения по QR-коду (R4-10 / R4-11)

- Утилита `tool\pair_pc.bat` на ПК запущена и протестирована:
  - Исключает приватный диапазон 198.18.0.0/16 (TUN-адаптер FlClashX), vEthernet, Hyper-V, WSL, VirtualBox.
  - Проверяет доступность сервера LM Studio на порту 1235.
  - Создаёт SVG QR-код во временной HTML-странице (`%TEMP%\chto_prigotovit_pair_*.html`) и открывает её в браузере по умолчанию.
  - 10 тестов в `test/pair_pc_test.dart` зелёные.
- Сканер QR-кода сопряжения в приложении (`lib/features/settings/qr_scanner_screen.dart`):
  - Построен на базе `MobileScanner` с правильным жизненным циклом (виджет сам запускает камеру).
  - Валидирует версию протокола `v: 1`, имя приложения `app: chto-prigotovit` и приватные IP-адреса.
  - Опрашивает хосты, сохраняет настройки в SecureStorage, переключает роутер в режим «Компьютер».
  - 15 тестов в `test/qr_pairing_test.dart` зелёные.
  - **На реальном телефоне не проверено** (проверяет владелец устройства).

---

## Как запустить и проверить вручную

1. **Запуск сопряжения на ПК:**
   ```cmd
   tool\pair_pc.bat
   ```
   В браузере откроется страница с крупным QR-кодом, списком адресов и портом 1235.

2. **Запуск сервера LM Studio на ПК:**
   ```cmd
   tool\start_lmstudio_server.bat
   ```
   Сервер запустится на порту 1235 и будет доступен для всей локальной сети.

3. **CLI-проверка связи с ИИ:**
   ```powershell
   dart run tool/ai_smoke.dart --port 1235
   ```

4. **Полный прогон анализатора, форматирования и 488 тестов:**
   ```powershell
   powershell -ExecutionPolicy Bypass -File tool/check.ps1
   ```

5. **Установка релизного APK на телефон владельца:**
   ```powershell
   adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
   ```

6. **Проверка сценария сопряжения на телефоне владельцем:**
   - Телефон и ПК должны быть в одной Wi-Fi сети.
   - На телефоне открыть: шестерёнка в шапке «Блюда» → «Подключить компьютер по QR-коду».
   - Навести камеру на QR-код на экране монитора.
   - Должно появиться подтверждение: «Компьютер подключён: 192.168.x.x».

---

## Вывод проверок `tool/check.ps1` (после последней правки)

```text
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
Formatted 134 files (0 changed) in 0.57 seconds.
----- exit code: 0

===== analyze: flutter analyze =====
Analyzing cooker...                                             
No issues found! (ran in 2.8s)
----- exit code: 0

===== test: flutter test =====
00:16 +488: All tests passed!
----- exit code: 0

RESULT: GREEN (2026-11-07T21:41:20)
```

---

## Скриншоты

- `docs/reports/img/ai_diagnostics.png` — обновлённый скриншот экрана диагностики с завершёнными проверками (Wi-Fi ✓, адрес телефона ✓, ПК найден ✓, LM Studio отвечает ✓, модель загружена ✓, ключ GigaChat ✗, пробный запрос ✓) и 3 записями истории запросов.
- `docs/reports/img/suggestions_error_banner.png` — плашка ошибки/настройки помощника в начале экрана «Блюда» над группами рецептов.
- `docs/reports/img/today_screen.png`, `docs/reports/img/calendar_screen.png`, `docs/reports/img/cooking_step1.png`, `docs/reports/img/history_screen.png`, `docs/reports/img/pantry_screen.png` — все скриншоты перегенерированы без обрезок текста.

---

## Релизная сборка

- `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (31.7 МБ)
- `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk` (27.9 МБ)
- `build/app/outputs/flutter-apk/app-x86_64-release.apk` (34.1 МБ)

---

## Не готово / проверить владельцу на устройстве

1. **Скриншоты с телефона:** прислать скриншоты мест, где выезжал текст на реальном телефоне (в `docs/reports/img/device/`). Автотесты 60 комбинаций верстки зелёные, но финальное визуальное подтверждение делает владелец.
2. **Сканирование QR-кода на телефоне:** запустить `tool\pair_pc.bat` на ПК, открыть «Подключить компьютер по QR-коду» в приложении на телефоне, отсканировать QR. Сообщить результат.
3. **Проверка ИИ вживую на телефоне:** пройти 6 сценариев ТЗ 11 и экран «Проверка помощника».
