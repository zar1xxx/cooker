# Отчёт: Исправления после проверки R4 (R5)

Дата: 2026-11-08 · Задачи: R5-01…R5-08

---

## Сделано

| ID | Что сделано | Файлы |
| --- | --- | --- |
| **R5-02** | **Причина медленной работы LM Studio и рекомендации.** Зафиксирована причина проблемы (в памяти находились 3 копии модели с контекстом 262144, parallel 4; после перехода на 1 копию с контекстом 8192 время ответа сократилось до 0,55 с). В `docs/INSTALL.md` раздел 2 внесены рекомендации: строго одна загруженная модель, контекст 8192, команда `lms load google/gemma-4-12b-qat --context-length 8192`. Сервер и модели агентом не перезагружались согласно правилу 2. | `docs/INSTALL.md` |
| **R5-07** | **Ограничение `max_tokens`, повтор при превышении длины и сырой лог.** В `lib/core/ai/prompts.dart` добавлен класс `AiMaxTokens`: 1200 для подборки блюд, 2500 для полного рецепта, 2000 для плана недели, 100 для ping. Параметр `max_tokens` добавлен во все запросы LM Studio и GigaChat. При `finish_reason == 'length'` возвращается `AiFailure.badResponse`, выполняется 1 автоматический повтор с `temperature = 0.2`, затем fallback на GigaChat (R5-03) или плашка. В `tool/ai_smoke.dart` добавлено логирование сырого ответа в `docs/reports/last_ai_smoke_raw.json` и вывод первых 500 символов при ошибке. Написаны 3 теста в `test/ai_router_test.dart` и `test/prompts_test.dart`. | `lib/core/ai/prompts.dart`, `lib/core/ai/lmstudio_provider.dart`, `lib/core/ai/gigachat_provider.dart`, `lib/core/ai/ai_service.dart`, `tool/ai_smoke.dart`, `test/ai_router_test.dart`, `test/prompts_test.dart` |
| **R5-08** | **Отбраковка мусора в названиях (`RecipeValidator`).** В `RecipeValidator` добавлен метод `checkGarbageText`: проверка названий блюд, ингредиентов и шагов на наличие символов разметки `**`, повторений одного символа 4+ раз подряд (например, «Суп********»), а также символов вне кириллицы/латиницы/цифр/знаков пунктуации (например, японские символы «Дバイス**»). При обнаружении возвращается `ValidationResult.retryable` (или `rejected` при исчерпании попыток). Написаны 4 юнит-теста в `test/recipe_validator_test.dart`. | `lib/core/ai/recipe_validator.dart`, `test/recipe_validator_test.dart` |
| **R5-03** | **Таймаут ПК 45 с и fallback на GigaChat.** В `LmStudioProvider` и `AiSettingsService` таймауты запросов снижены до 45 с. В `AiRouter.executeChatWithFallback`: если LM Studio не ответил за 45 с (таймаут) или вернул ошибку сети, и GigaChat настроен — первая попытка фиксируется в `ai_requests` со статусом `error` (провайдер `lm_studio`), запрос повторяется через GigaChat и логируется вторая попытка (`status: 'ok'` или `'error'`). Если GigaChat не настроен — возвращается `AiFailureTimeout`. На экране «Блюда» (`SuggestionsScreen`) отображается плашка с заголовком «Компьютер долго отвечает» (`l10n.aiTimeoutTitle`), описанием превышения времени ожидания и кнопкой «Повторить». Написаны 2 теста в `test/ai_failures_test.dart` и `test/ai_banner_test.dart`. | `lib/core/ai/lmstudio_provider.dart`, `lib/core/ai/ai_settings_service.dart`, `lib/core/ai/ai_router.dart`, `lib/features/suggestions/suggestions_screen.dart`, `lib/l10n/app_ru.arb`, `test/ai_failures_test.dart`, `test/ai_banner_test.dart` |
| **R5-01** | **Статус `ai_smoke.dart` и прогон `tool\run_ai_smoke.bat`.** В `tool/ai_smoke.dart` исправлен код завершения: при любой ошибке (таймаут, сбой подключения, невалидный ответ валидатора) скрипт завершается с кодом 1 (`exit(1)`). Добавлен автоматический повтор при `finish_reason == 'length'`. Запущен `tool\run_ai_smoke.bat`, результат сохранён в `docs/reports/last_ai_smoke.txt` и `last_ai_smoke_raw.json`. Из-за перезагрузки ПК сервер LM Studio не был запущен (`TCP 127.0.0.1:1235` отклонил подключение). В соответствии с правилом 2 сервер агентом не перезапускался; задача R5-01 остаётся открытой с записью в «Блокерах» для запуска владельцем через `tool\start_lmstudio_server.bat`. | `tool/ai_smoke.dart`, `tool/run_ai_smoke.bat`, `docs/reports/last_ai_smoke.txt`, `docs/reports/last_ai_smoke_raw.json`, `docs/STATUS.md` |
| **R5-04** | **Безопасность и надёжность сопряжения `pair_pc`.** В `tool/pair_pc_helper.dart` и `tool/pair_pc.dart` флаг `--gigachat` переведён строго на скрытый ввод через `stdin.echoMode = false` (передача ключа через аргументы командной строки запрещена и вызывает ошибку). Если в системе нет приватных адресов локальной сети — скрипт выводит ошибку и завершается с кодом 1 без генерации QR для 127.0.0.1. Проверка доступности LM Studio по LAN-адресу выполняется до показа QR-кода: если сервер слушает только локальный адрес, выводится точное предупреждение с командой запуска `tool\start_lmstudio_server.bat`. Экземпляр `Dio` гарантированно закрывается в блоке `finally`. Написаны 2 теста в `test/pair_pc_test.dart`. | `tool/pair_pc.dart`, `tool/pair_pc_helper.dart`, `test/pair_pc_test.dart` |
| **R5-05** | **Экран сканера QR-кода сопряжения.** Подключена библиотека `permission_handler: ^11.3.1`. Кнопка «Открыть настройки» вызывает `openAppSettings()` (параметр `openSettings` проброшен в конструктор для тестируемости). Разделены тексты ошибок: для отказа в разрешении камеры и для физической недоступности камеры. При возникновении ошибки видоискатель и подсказка скрываются, отображается информативный блок ошибки. Сообщение об ошибке сохранения настроек вынесено в `app_ru.arb` без интерполяции исключения `$e`. Написаны 2 widget-теста в `test/qr_pairing_test.dart`. **На телефоне не проверено** (проверяет владелец). | `lib/features/settings/qr_scanner_screen.dart`, `lib/l10n/app_ru.arb`, `pubspec.yaml`, `test/qr_pairing_test.dart` |
| **R5-06** | **Проверки, релизная сборка и отчёт.** Запущен `tool\check.ps1` (500 тестов GREEN, 0 замечаний `flutter analyze`). Выполнена сборка сплит-APK `flutter build apk --release --split-per-abi`. Подготовлен отчёт `docs/reports/REVIEW_FIXES_R5.md` с точными выдержками из файлов логов. | `docs/reports/REVIEW_FIXES_R5.md`, `docs/TASKS.md`, `docs/STATUS.md` |

---

## Выдержки из файлов логов

### 1. Замер скорости LM Studio после оптимизации конфигурации модели
Файл: [`docs/reports/last_llm_speed.txt`](file:///c:/dev/cooker/docs/reports/last_llm_speed.txt)

Конфигурация модели: 1 копия `google/gemma-4-12b-qat`, контекст 8192 токенов, parallel 4.

Выдержка из файла:
```text
===== tiny request, max_tokens 40
{
  "id": "chatcmpl-9fkpujlas3wohqsr9m4tm",
  "object": "chat.completion",
  "created": 1794069077,
  "model": "google/gemma-4-12b-qat",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "OK",
        "reasoning_content": "\nThe user said \"Say OK\".\nThe user wants me to output the word \"OK\".\n\"OK\"\n\nPlan:\n1. Reply with \"OK\".",
        "tool_calls": []
      },
      "logprobs": null,
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 18,
    "completion_tokens": 40,
    "total_tokens": 58,
    "completion_tokens_details": {
      "reasoning_tokens": 35
    }
  },
  "stats": {},
  "system_fingerprint": "google/gemma-4-12b-qat"
}
HTTP 200 TIME 0.832987s

===== json_schema request, max_tokens 300
{
  "id": "chatcmpl-0syph2l6f23gq08v7ctroan",
  "object": "chat.completion",
  "created": 1794069078,
  "model": "google/gemma-4-12b-qat",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "{\"dishes\": [\"Картошка с луком\", \"Жареная картошка с луком\"]}\n    ",
        "reasoning_content": "",
        "tool_calls": []
      },
      "logprobs": null,
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 34,
    "completion_tokens": 27,
    "total_tokens": 61,
    "completion_tokens_details": {
      "reasoning_tokens": 0
    }
  },
  "stats": {},
  "system_fingerprint": "google/gemma-4-12b-qat"
}
HTTP 200 TIME 0.551216s

===== lms ps after

IDENTIFIER                MODEL                     STATUS    SIZE       CONTEXT    PARALLEL    DEVICE    TTL
google/gemma-4-12b-qat    google/gemma-4-12b-qat    IDLE      7.15 GB    8192       4           Local        
```

---

### 2. Результат прогона `tool\run_ai_smoke.bat`
Файл: [`docs/reports/last_ai_smoke.txt`](file:///c:/dev/cooker/docs/reports/last_ai_smoke.txt)

Выдержка из файла:
```text
Running build hooks...Running build hooks...========================================
  AI Smoke Test: LM Studio & GigaChat   
========================================

[LM Studio] Checking server at candidate ports: 1235 ...
[LM Studio] Probing http://127.0.0.1:1235 ...
[LM Studio] Port 1235 not answering / error: DioException [connection error]: The connection errored: Удаленный компьютер отклонил это сетевое подключение This indicates an error which most likely cannot be solved by the library.
Error: SocketException: Удаленный компьютер отклонил это сетевое подключение (OS Error: Удаленный компьютер отклонил это сетевое подключение, errno = 1225), address = 127.0.0.1, port = 58355
[LM Studio] NOT RUNNING / NOT REACHABLE on candidate ports: 1235
[LM Studio] (Start LM Studio on this PC, load a model, and start the local server via tool\start_lmstudio_server.bat)

[GigaChat] GIGACHAT_KEY environment variable is not set. Skipped.
[GigaChat] (To test GigaChat: set GIGACHAT_KEY=<auth_key> and rerun)

========================================
  AI Smoke Test Completed               
========================================
exit 1 
```

Сырой JSON лог: [`docs/reports/last_ai_smoke_raw.json`](file:///c:/dev/cooker/docs/reports/last_ai_smoke_raw.json)
```json
{
  "timestamp": "2026-11-08T10:01:11.770052",
  "candidate_ports": [
    1235
  ],
  "error": "LM Studio not reachable on ports: [1235]"
}
```

---

## Статус релизных APK (`flutter build apk --release --split-per-abi`)

Сборка выполнена успешно:
- `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (31.7 МБ, 33 254 755 байт)
- `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk` (28.0 МБ, 29 337 557 байт)
- `build/app/outputs/flutter-apk/app-x86_64-release.apk` (34.1 МБ, 35 777 886 байт)

---

## Проверить владельцу

1. **Запустить LM Studio на ПК (для закрытия R5-01):**
   - Убедиться, что в LM Studio загружена ровно одна копия модели `google/gemma-4-12b-qat` с контекстом 8192 (`lms load google/gemma-4-12b-qat --context-length 8192`).
   - Запустить сервер через `tool\start_lmstudio_server.bat` (порт 1235, прослушивание всех интерфейсов).
   - Запустить `tool\run_ai_smoke.bat` для подтверждения прохождения проверок `suggest_dishes` и `full_recipe` и закрытия R5-01.
2. **Проверить сопряжение по QR-коду:**
   - На ПК запустить `tool\pair_pc.bat` (или `tool\pair_pc.bat --gigachat` при желании передать ключ GigaChat со скрытым вводом).
   - В браузере откроется страница с QR-кодом и адресом ПК в локальной сети (`192.168.50.224:1235`).
3. **Проверить сканер на телефоне:**
   - Установить свежий `app-arm64-v8a-release.apk` на телефон (телефон должен быть в той же Wi-Fi сети).
   - Перейти в экран «Проверка помощника» или «Настройки помощника» и нажать «Подключить компьютер по QR-коду».
   - Проверить запрос разрешения камеры и корректную работу кнопки «Открыть настройки» при отказе.
   - Отсканировать QR-код с экрана ПК: проверить автоподключение, смену индикатора режима на «компьютер» и работу подбора блюд и полного рецепта от LM Studio.
