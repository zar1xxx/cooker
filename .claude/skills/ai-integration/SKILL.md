---
name: ai-integration
description: AiProvider, AiRouter, LM Studio на ПК, GigaChat, промпты и разбор JSON-ответов. Открывать для любой работы в lib/core/ai/.
---

# Интеграция ИИ

## Схема

```
AiService (suggest_dishes / full_recipe / month_plan)
   └─ AiRouter ── выбирает ──┬─ LmStudioProvider  (ПК в локальной сети)
                             ├─ GigaChatProvider  (запасной)
                             └─ null → только локальные данные
   └─ RecipeValidator, дедупликация, кэш ai_requests
```

Файлы: `lib/core/ai/ai_provider.dart`, `lm_studio_provider.dart`, `gigachat_provider.dart`, `fake_ai_provider.dart`, `pc_discovery.dart`, `ai_router.dart`, `ai_service.dart`, `prompts.dart`, `recipe_validator.dart`.

## LM Studio (OpenAI-совместимый API)

- Список моделей: `GET http://<host>:1234/v1/models` → `{"data":[{"id":"..."}]}`.
- Чат: `POST http://<host>:1234/v1/chat/completions`
  ```json
  {
    "model": "<id из настроек>",
    "messages": [{"role":"system","content":"..."},{"role":"user","content":"..."}],
    "temperature": 0.7,
    "stream": false,
    "response_format": {
      "type": "json_schema",
      "json_schema": {"name": "suggest_dishes", "strict": true, "schema": { ... }}
    }
  }
  ```
- Ответ: JSON строкой в `choices[0].message.content` → `jsonDecode`.
- Авторизация по умолчанию не нужна. Если в LM Studio включён токен — заголовок `Authorization: Bearer <token>` (поле в настройках, необязательное).
- Документация: https://lmstudio.ai/docs/developer/openai-compat/structured-output
- Модели < 7B плохо держат структурированный вывод — валидатор всё равно обязателен.
- Android блокирует `http://` по умолчанию. В `network_security_config.xml` нельзя задать диапазон IP, а адрес ПК заранее неизвестен. Поэтому: `cleartextTrafficPermitted="true"` в `<base-config>`, **и** код гарантирует, что `http://` используется только для частных адресов (`10.*`, `172.16–31.*`, `192.168.*`) — проверка в `LmStudioProvider` + юнит-тест; все облачные URL только `https://` (тест на конфиг GigaChat). Запиши это решение в DECISIONS.

## Поиск ПК (`PcDiscovery`)

1. IP телефона и маска — `network_info_plus` (`getWifiIP()`), подсеть считаем /24.
2. Сначала сохранённый адрес. Не ответил → скан 1..254, `GET /v1/models`, таймаут 300 мс, пул 32.
3. Ответ 200 с корректным JSON `data[]` → это LM Studio. Берём первый найденный.
4. Скан не чаще 1 раза в час в фоне; ручной — по кнопке.
5. Мобильные данные (не Wi-Fi) → ПК не ищем.

## GigaChat

- Токен: `POST https://ngw.devices.sberbank.ru:9443/api/v2/oauth`
  - заголовки: `Content-Type: application/x-www-form-urlencoded`, `Accept: application/json`, `RqUID: <uuid4 на каждый запрос>`, `Authorization: Basic <ключ авторизации>`
  - тело: `scope=GIGACHAT_API_PERS`
  - ответ: `access_token`, `expires_at` (ms). Токен живёт 30 мин. Кэшируй в памяти до `expires_at − 60 с`. 401 на чате → один раз обновить токен и повторить.
- Чат: `POST <base>/api/v1/chat/completions`, `Authorization: Bearer <access_token>`. Тело как у OpenAI (`model`, `messages`, `temperature`). Модель по умолчанию `GigaChat-2` (Lite), настраивается.
- `<base>` — настройка, по умолчанию `https://gigachat.devices.sberbank.ru`. В документации отмечено, что этот адрес сохранён для подключившихся до 17.07.2026 — сверь актуальный адрес на https://developers.sber.ru/docs/ru/gigachat/api/reference/rest/gigachat-api и запиши в DECISIONS.
- `response_format: json_schema` для GigaChat **не используй** (поддержка не подтверждена). Схема — текстом в системный промпт, ответ: вырезать JSON (первый `{` … последний `}`), `jsonDecode`, валидатор.
- TLS: сертификат «Russian Trusted Root CA» (файл `assets/certs/russian_trusted_root_ca.cer`, см. README там). Отдельный `Dio` с `HttpClient(context: SecurityContext(withTrustedRoots: true)..setTrustedCertificatesBytes(bytes))`. Не отключай проверку сертификата.
- Один поток генерации на Freemium → запросы к GigaChat ставь в очередь (не параллелить).
- Тарифы: https://developers.sber.ru/docs/ru/gigachat/tariffs/individual-tariffs

## AiRouter — правила (ТЗ 6.1.1)

| Ситуация | Действие |
| --- | --- |
| Wi-Fi, ПК проверен < 60 с назад | LM Studio |
| Wi-Fi, проверки нет или старая | health-check 1,5 с → LM Studio или GigaChat |
| Нет Wi-Fi | GigaChat |
| LM Studio: ошибка сети / таймаут | Тот же запрос → GigaChat; ПК «недоступен» 60 с |
| Невалидный JSON | 1 повтор на том же провайдере с текстом ошибки → потом GigaChat (если был LM Studio) → потом отказ |
| Нет ключа GigaChat и нет ПК | `null` — только локальные данные, без ошибки |

Таймауты: LM Studio 60 / 90 / 180 с (подборка / рецепт / неделя плана), GigaChat 30 / 45 / 90 с.

## Промпты и схемы

- Схемы: `spec/ai/schemas/*.schema.json` — копируй в `assets/ai/` и грузи в рантайме, не дублируй руками в Dart.
- Промпты: `spec/ai/prompts/*.md` — плейсхолдеры `{{...}}` подставляет `prompts.dart`.
- Ответ всегда проходит: JSON-схема → `RecipeValidator` → дедуп → сохранение.

## Тестирование

- Юнит-тесты — только `FakeAiProvider` и `MockAdapter` для `Dio` (`http_mock_adapter` или свой `HttpClientAdapter`).
- Ручная проверка с ПК: `tool\lmstudio_ping.ps1`, `tool\gigachat_ping.ps1`.
- В журнал `ai_requests` пиши: провайдер, модель, токены (`usage`), длительность, статус. Без текста ключа.
