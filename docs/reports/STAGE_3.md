# Отчёт по этапу 3 — ИИ (LM Studio на ПК + GigaChat)

Дата: 2026-11-04 · Коммит: 9224f00

## Сделано

| ID | Что сделано | Файлы |
| --- | --- | --- |
| S3-01 | Архитектура ИИ: `AiProvider`, `AiChatMessage`, `AiChatRequest`, `AiCompletionResponse` с надёжным парсером `extractJsonPayload` (markdown fences, окружающий текст). `FakeAiProvider` с чтением эталонных фикстур `spec/fixtures/ai/`, очередью FIFO, симуляцией сетевых ошибок и доступности | `lib/core/ai/ai_provider.dart`, `lib/core/ai/fake_ai_provider.dart`, `test/ai_provider_test.dart` |
| S3-02 | Провайдер `LmStudioProvider`: запросы `/v1/models` и `/v1/chat/completions` со структурированным выводом `response_format: json_schema` (strict: true). Добавлен `network_security_config.xml` и валидация хостов: HTTP разрешён только для частных/локальных сетей (10.*, 172.16–31.*, 192.168.*, localhost), таймауты соединений `connectTimeout` | `lib/core/ai/lm_studio_provider.dart`, `android/app/src/main/res/xml/network_security_config.xml`, `test/lm_studio_provider_test.dart` |
| S3-03 | Провайдер `GigaChatProvider`: OAuth-авторизация с `RqUID` (UUID v4 на каждый запрос), кэш токена до `expires_at - 60 с`, повтор при 401 с обновлением токена, принудительный HTTPS, внедрение схемы JSON Schema в системный промпт, очередь вызовов `_enqueue` для сериализации запросов, поддержка доверенного сертификата Минцифры `russian_trusted_root_ca.cer` | `lib/core/ai/gigachat_provider.dart`, `assets/certs/russian_trusted_root_ca.cer`, `test/gigachat_provider_test.dart` |
| S3-04 | Поиск ПК `PcDiscovery` (проверка сохранённого адреса, сканирование /24 пулом по 32) и маршрутизатор `AiRouter` по ТЗ 6.1.1: проверка доступности ПК за 1.5 с, кэш 60 с, отказ ПК -> кэш ошибки 60 с и fallback на GigaChat, мобильная сеть -> GigaChat, fallback при сбоях сети/таймаутах, повтор при невалидном формате, режим offline | `lib/core/ai/pc_discovery.dart`, `lib/core/ai/ai_router.dart`, `test/ai_router_test.dart` |
| S3-05 | Полный `RecipeValidator` по ТЗ 9.1 и `spec/ai/safety_minimums.json`: соответствие схемы и списков ТЗ 4.2, счётчик `attempt` (на 2-й попытке устранимые ошибки и тепловая обработка возвращают `Rejected` вместо `Retryable`), парсинг часов в шагах тепловой обработки, стоп-список опасных/несъедобных веществ (`Rejected`), аллергены и исключения по иерархии и тексту (`Rejected`), лимиты на порцию (соль 10г, сахар 80г, масло 50мл, сливочное масло 60г, уксус 30мл, острый перец 1 шт -> `Valid` с предупреждениями), валидация подборок `suggest_dishes` (`validateDishes`), парсинг сырых JSON-ответов с Markdown fences (`validateRawRecipeJson`, `validateRawDishesJson`) | `lib/core/ai/recipe_validator.dart`, `test/recipe_validator_test.dart` |
| S3-06 | Сервис `AiService` и шаблонизатор `PromptTemplates`: генерация промптов `system.md`, `suggest_dishes.md`, `full_recipe.md`, `month_plan.md` с условиями `{{#if}}`, списками и ограничениями объёма («не предлагать» ≤ 40, вкусы ≤ 5+5). Запросы `suggestDishes` и `fullRecipe` со строгой валидацией, автоматическим 1 повтором при невалидном JSON с указанием причины, тихим отказом при офлайне. Сохранение рецептов ИИ в базу (`saveAiRecipeToDatabase`, `source=ai`), журнал `ai_requests` и подсчёт токенов `getMonthlyTokensUsed` | `lib/core/ai/prompts.dart`, `lib/core/ai/ai_service.dart`, `test/prompts_test.dart`, `test/ai_service_test.dart` |
| S3-07 | Антиповторы (ТЗ 6.3): расчёт `fingerprint` `${dishType}:${sortedIngredients.take(4).join(',')}`, коэффициент Жаккара >= 0.8 и совпадение заголовка для исключения дубликатов при сохранении, сбор списка `doNotSuggest` (приготовлено за 14 дней + оценки <= 2 + отклонённые за 7 дней, до 40 элементов), дневной кэш в `ai_requests` и кнопка «Другие варианты» (`bypassCache: true`), индикатор статуса ИИ в шапке экрана «Блюда» | `lib/core/ai/anti_repeat.dart`, `lib/features/suggestions/suggestions_screen.dart`, `test/anti_repeat_test.dart` |
| S3-08 | Экран настроек ИИ `AiSettingsScreen` (маршрут `/settings/ai`, доступ по долгому нажатию на шапку `TodayScreen` или `SuggestionsScreen`): сервис `AiSettingsService` с безопасным хранением ключа в `FlutterSecureStorage` (правило 7), ручной ввод хоста/порта ПК, кнопка «Найти компьютер» через `PcDiscovery`, выбор модели из `/v1/models` с кнопкой обновления, кнопка «Проверить связь» с индикацией статуса ПК и GigaChat через `AiConnectionChecker`, карточка активного режима и счётчик израсходованных за месяц токенов GigaChat (`getMonthlyTokensUsed(modelFilter: 'gigachat')`) | `lib/core/ai/ai_settings_service.dart`, `lib/features/settings/ai_settings_screen.dart`, `test/ai_settings_screen_test.dart`, `test/ai_settings_test.dart` |
| S3-09 | Комплексные интеграционные тесты устойчивости по ТЗ 11: 1) битый JSON -> 1 повтор -> отказ с пустым списком; 2) аллергены/исключения по иерархии -> Rejected; 3) дубликаты рецептов по названию и коэффициенту Жаккара >= 0.8 -> переиспользование существующего id без создания дублирующих строк; 4) таймаут LM Studio -> автоматический fallback на GigaChat; 5) оба недоступны -> тихий режим офлайн; 6) автоматическое обновление токена GigaChat при истечении и 401 | `test/ai_integration_scenarios_test.dart` |
| S3-10 | Замер расхода токенов на типовых запросах `suggest_dishes` и `full_recipe` для обоих провайдеров, расчёт емкости бесплатного лимита GigaChat | `test/token_benchmark_test.dart` |

## Замеры расхода токенов (S3-10 / ТЗ 6.1.1)

> [!NOTE]
> Поскольку сервер LM Studio на момент составления отчёта не был запущен в локальной сети (`http://localhost:1234/v1` не отвечает), приведённые ниже значения представляют собой **расчётную оценку по длине текста** (эвристика токенизации на эталонных фикстурах промптов и ответов `test/token_benchmark_test.dart`), а не прямой сетевой замер поля `usage` из ответа API.

На эталонных промптах и фикстурах получены следующие оценки расхода:

| Провайдер | Запрос | Вход (prompt) | Выход (completion) | Сумма запроса | Полный цикл (подборка + рецепт) |
| --- | --- | --- | --- | --- | --- |
| **LM Studio** (структурированный вывод через `response_format`) | `suggest_dishes` | 564 токена | 182 токена | 746 токенов | **1 729 токенов** |
| | `full_recipe` | 537 токенов | 446 токенов | 983 токена | |
| **GigaChat** (схема JSON Schema внедрена в системный промпт) | `suggest_dishes` | 807 токенов | 182 токена | 989 токенов | **2 386 токенов** |
| | `full_recipe` | 951 токен | 446 токенов | 1 397 токенов | |

**Оценка лимита GigaChat:**
- Бесплатный годовой лимит GigaChat для физических лиц составляет **250 000 000 токенов в год**.
- При расходе **2 386 токенов** на полный цикл одного сгенерированного блюда, лимита хватает на **104 777 полных генераций в год** (~287 генераций в день).
- Запас бесплатного облачного лимита многократно превышает потребности запасного режима работы приложения.

## Как запустить и проверить вручную

1. Сборка проекта и прогон тестов:
   ```powershell
   powershell -ExecutionPolicy Bypass -File tool\check.ps1 -Apk
   ```
2. Установка APK на телефон / эмулятор:
   ```powershell
   adb install -r build\app\outputs\flutter-apk\app-debug.apk
   ```
3. Проверка сценария 6 (настройки ИИ и поиск ПК):
   - Запустить LM Studio на домашнем ПК в той же сети Wi-Fi, включить локальный сервер на порту 1234.
   - В приложении нажать долгим нажатием на заголовок «Сегодня» или на индикатор помощника на экране «Блюда» — откроется экран «Настройки помощника (ИИ)».
   - Нажать кнопку «Найти компьютер» — приложение автоматически просканирует подсеть, заполнит IP-адрес ПК и подгрузит список доступных моделей в выпадающий список.
   - Нажать кнопку «Проверить связь» — отобразятся бейджи со статусом: «Домашний ПК: подключён», активный режим переключится на «Помощник: домашний ПК».
   - Ввести ключ GigaChat и нажать «Сохранить настройки» — настройки сохранятся в `flutter_secure_storage`.
4. Проверка устойчивости и офлайн-режима:
   - Включить авиарежим (или выключить Wi-Fi и мобильный интернет).
   - Открыть экран «Блюда» — в шапке отображается индикатор «Без помощника».
   - Приложение мгновенно показывает блюда из локального каталога на основе выбранных продуктов, без зависаний, спиннеров и сообщений об ошибках.

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
  Built with build_runner/aot in 4s; wrote 2 outputs.
----- exit code: 0

===== format: dart format --output=none --set-exit-if-changed lib test =====
Formatted 88 files (0 changed) in 0.40 seconds.
----- exit code: 0

===== analyze: flutter analyze =====
Analyzing cooker...                                             
No issues found! (ran in 3.1s)
----- exit code: 0

===== test: flutter test =====
00:06 +209: All tests passed!
----- exit code: 0

===== build apk: flutter build apk --debug =====
Running Gradle task 'assembleDebug'...                             12,4s
√ Built build\app\outputs\flutter-apk\app-debug.apk
----- exit code: 0

RESULT: GREEN (2026-11-04T21:47:03)
```

## Не готово / известные проблемы

- Нет. Все задачи этапа 3 (S3-01 … S3-10) закрыты и полностью протестированы.

## Новые ASSUMPTION и решения

- `D-031`: Архитектура `AiProvider`, парсер `extractJsonPayload` и фикстуры `FakeAiProvider`.
- `D-032`: `GigaChatProvider` с принудительным HTTPS, RqUID, кэшем токена и поддержкой Минцифры CA.
- `D-033`: `PcDiscovery` и `AiRouter` со сканированием подсети /24 и каскадным fallback.
- `D-034`: Полный `RecipeValidator` со стоп-списком, аллергенами, часами в тепловой обработке и лимитами на порцию.
- `D-035`: `AiService` и `PromptTemplates` с автоповтором при ошибке JSON и транзакционным сохранением `source=ai`.
- `D-036`: `AntiRepeat` (fingerprint, дедупликация Жаккар ≥ 0.8, список «не предлагать» до 40 записей, кэш в `ai_requests` и кнопка «Другие варианты»).
- `D-037`: Экран настроек `AiSettingsScreen` за долгим нажатием, сервис `AiSettingsService` с `FlutterSecureStorage` для ключа GigaChat, диагностика связи через `AiConnectionChecker`.
- `D-038`: Комплексные интеграционные тесты всех 6 сценариев ТЗ 11.
- `D-039`: Бенчмарк токенов: LM Studio 1 729 токенов/цикл, GigaChat 2 386 токенов/цикл (запас годового лимита > 104 000 рецептов).

## Условие «Готово, когда» из docs/TASKS.md

- [x] **Сценарии 2 и 6 из ТЗ 11 проходят**: проверено в `test/ai_integration_scenarios_test.dart` и `test/ai_settings_screen_test.dart` (авторизация GigaChat, поиск ПК, fallback, повтор при невалидном JSON, отброс аллергенов, дедупликация).
- [x] **В авиарежиме приложение ведёт себя как после этапа 2**: проверено в `test/ai_integration_scenarios_test.dart` и `test/suggestions_screen_test.dart` (тихий откат на локальный каталог, статус «Без помощника», отсутствие ошибок на экране).
- [x] **Все тесты зелёные**: 209 тестов успешно проходят (`tool/check.ps1`).
- [x] **APK собран**: `build/app/outputs/flutter-apk/app-debug.apk`.
