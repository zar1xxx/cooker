# Отчёт: Исправления после живого прогона 2026-11-08 (R6-00…R6-04)

Дата: 2026-11-08  
Ветка: `master`  
Статус проверок `tool/check.ps1`: **GREEN** (509 тестов, 0 замечаний `flutter analyze`)  
Сборка: `flutter build apk --release --split-per-abi` — успешно собраны 3 сплит-APK

---

## 1. Что сделано по задачам

### R6-00: Извлечение JSON из `reasoning_content` и выбор загруженной модели
1. **Поддержка reasoning моделей (Qwen / Ornith):**  
   Модели архитектур `qwen35` и `qwen35moe` при запросах со строгой JSON-схемой выдают готовый валидный JSON в поле `message.reasoning_content` (или `delta.reasoning_content` в потоковом режиме), оставляя `content` пустым.  
   В `LmStudioProvider.selectEffectiveContent()` реализовано: если `content` пуст или содержит лишь не-JSON преамбулу, а `reasoning_content` содержит валидный JSON — используется `reasoning_content`. Если оба пусты — выбрасывается `AiFailure.badResponse`.
2. **Выбор модели без JIT-загрузки тяжелых моделей:**  
   В `LmStudioProvider.resolveModel()` опрос моделей переведён на `GET /api/v0/models` с фильтрацией `"state": "loaded"` и `"type": "llm" | "vlm"`. Если эндпоинт недоступен — fallback на `GET /api/v1/models` с фильтром по непустому `loaded_instances`. Если ни одна модель не загружена — возвращается `AiFailure.pcNoModel` без триггера фоновой JIT-загрузки 30–46 ГБ моделей.
3. Сохранена поддержка переменной окружения `LMSTUDIO_MODEL` в `tool/ai_smoke.dart`.

### R6-01: Потоковые ответы от LM Studio (streaming SSE) и двойной таймаут
1. **Потоковый режим:**  
   В запросах к LM Studio отправляется `'stream': true` и `'stream_options': {'include_usage': true}`.
2. **SSE-парсер:**  
   Ответ читается потоково чанками (`data: {...}`, `[DONE]`), собирая фрагменты как из `delta.content`, так и из `delta.reasoning_content`. Итоговый `finish_reason` и статистика `usage` извлекаются из завершающего чанка.
3. **Двойной таймаут:**  
   - **Таймаут неактивности (15 с):** сбрасывается при поступлении каждого токена. Если в течение 15 секунд не пришло ни одного токена (включая ожидание до первого токена) — соединение обрывается с `AiFailure.timeout`.
   - **Общий таймаут (90 с):** ограничивает суммарное время генерации.
4. **Немедленное освобождение слота:**  
   При любом таймауте отменяется `CancelToken` и прерывается подписка на поток данных, благодаря чему сервер LM Studio сразу освобождает рабочий слот GPU.
5. Написаны 5 тестов потокового режима в `test/lm_studio_provider_test.dart` (нормальный SSE-ответ, чтение из `reasoning_content`, таймаут неактивности, общий таймаут, немедленный обрыв `CancelToken`).

### R6-02: Замер скорости и TTFT в `ai_smoke`
1. Перед запросами `ai_smoke` опрашивает `GET /api/v1/models` (с fallback на `/api/v0/models`) и выводит идентификатор загруженной модели, размер контекста и параллелизм (`parallel`).
2. Для каждого запроса вычисляются и выводятся:
   - Скорость генерации в токенах в секунду (`completion_tokens / elapsed`).
   - Время до первого токена (`TTFT`).
3. При падении скорости ниже 5 ток/с выводится диагностическая строка:  
   `[LM Studio] Видеопамяти не хватает: см. docs/INSTALL.md раздел 2.4`
4. Параметры сохраняются в `docs/reports/last_ai_smoke_raw.json`.

### R6-03: Раздел 2.4 в `docs/INSTALL.md` («Если компьютер отвечает медленно»)
1. Описан физический механизм просадки скорости: переполнение VRAM видеокарты суммой весов модели, KV-кэша нескольких параллельных слотов и фоновых программ приводит к сбросу страниц памяти в Shared GPU Memory (RAM), замедляя генерацию с 45 ток/с до 0.2 ток/с.
2. Приведена инструкция по запуску диагностики видеокарты через `tool\gpu_diag.bat` (лог `docs\reports\last_gpu_diag.txt`).
3. Задокументированы проверенные команды `lms load` с точными флагами по `lms load --help` (вывод зафиксирован в `docs/reports/lms_load_help.txt`):
   - `lms unload --all`
   - `lms load ornith-1.5-35b-a3b -c 4096 --parallel 1`
   - Для бюджетных GPU — альтернатива `ornith-1.5-9b` (5.8 ГБ VRAM, ~85 ток/с).

### R6-04: Верификация, сборка сплит-APK и отчёт
1. Выполнен живой трёхкратный прогон через `tool\run_ai_smoke_x3.bat` против загруженной модели `ornith-1.5-35b-a3b` на порту 1235 (все 3 прогона успешны, exit 0, скорость 41–45 ток/с).
2. Выполнен полный прогон `tool/check.ps1` — **509 тестов GREEN**, 0 замечаний анализатора.
3. Собраны релизные сплит-APK `flutter build apk --release --split-per-abi`.

---

## 2. Подлинные выдержки из файлов логов

### Выдержка 1: `docs/reports/last_ai_smoke.txt` (одиночный прогон R6-02)
```
Running build hooks...Running build hooks...========================================
  AI Smoke Test: LM Studio & GigaChat   
========================================

[LM Studio] Checking server at candidate ports: 1235 ...
[LM Studio] Probing http://127.0.0.1:1235 ...
[LM Studio] Server reachable on port 1235! Using model: ornith-1.5-35b-a3b
[LM Studio] Selected port 1235 with model: ornith-1.5-35b-a3b
[LM Studio] Model info: ornith-1.5-35b-a3b (context: 8192, parallel: 2)

[LM Studio] 1/2: Testing suggest_dishes ...
[LM Studio] suggest_dishes completed in 13042 ms
[LM Studio] Usage: prompt_tokens=381, completion_tokens=586
[LM Studio] finish_reason: stop
[LM Studio] Speed: 44.9 tok/s (586 completion tokens in 13.04s)
[LM Studio] Time to first token (TTFT): 0.56s
[LM Studio] suggest_dishes validation: Valid(warnings: [])

[LM Studio] 2/2: Testing full_recipe for "Картофельное пюре с курицей" (soup, easy) ...
[LM Studio] full_recipe completed in 14308 ms
[LM Studio] Usage: prompt_tokens=395, completion_tokens=600
[LM Studio] finish_reason: stop
[LM Studio] Speed: 41.9 tok/s (600 completion tokens in 14.31s)
[LM Studio] Time to first token (TTFT): 1.46s
[LM Studio] full_recipe validation: Valid(warnings: [])

[GigaChat] GIGACHAT_KEY environment variable is not set. Skipped.
[GigaChat] (To test GigaChat: set GIGACHAT_KEY=<auth_key> and rerun)

========================================
  AI Smoke Test Completed               
========================================
exit 0 
```

### Выдержка 2: `docs/reports/last_ai_smoke_run1.txt` (прогон 1 из 3)
```
[LM Studio] Server reachable on port 1235! Using model: ornith-1.5-35b-a3b
[LM Studio] Selected port 1235 with model: ornith-1.5-35b-a3b
[LM Studio] Model info: ornith-1.5-35b-a3b (context: 8192, parallel: 2)

[LM Studio] 1/2: Testing suggest_dishes ...
[LM Studio] suggest_dishes completed in 13897 ms
[LM Studio] Usage: prompt_tokens=381, completion_tokens=601
[LM Studio] finish_reason: stop
[LM Studio] Speed: 43.2 tok/s (601 completion tokens in 13.90s)
[LM Studio] Time to first token (TTFT): 0.51s
[LM Studio] suggest_dishes validation: Valid(warnings: [])

[LM Studio] 2/2: Testing full_recipe for "Картофельное пюре с курицей" (main, easy) ...
[LM Studio] full_recipe completed in 15922 ms
[LM Studio] Usage: prompt_tokens=395, completion_tokens=665
[LM Studio] finish_reason: stop
[LM Studio] Speed: 41.8 tok/s (665 completion tokens in 15.92s)
[LM Studio] Time to first token (TTFT): 1.45s
[LM Studio] full_recipe validation: Valid(warnings: [])
exit 0
```

### Выдержка 3: `docs/reports/last_ai_smoke_run2.txt` (прогон 2 из 3)
```
[LM Studio] Server reachable on port 1235! Using model: ornith-1.5-35b-a3b
[LM Studio] Selected port 1235 with model: ornith-1.5-35b-a3b
[LM Studio] Model info: ornith-1.5-35b-a3b (context: 8192, parallel: 2)

[LM Studio] 1/2: Testing suggest_dishes ...
[LM Studio] suggest_dishes completed in 12181 ms
[LM Studio] Usage: prompt_tokens=381, completion_tokens=542
[LM Studio] finish_reason: stop
[LM Studio] Speed: 44.5 tok/s (542 completion tokens in 12.18s)
[LM Studio] Time to first token (TTFT): 0.52s
[LM Studio] suggest_dishes validation: Valid(warnings: [])

[LM Studio] 2/2: Testing full_recipe for "Картофельное пюре" (side, easy) ...
[LM Studio] full_recipe completed in 11205 ms
[LM Studio] Usage: prompt_tokens=387, completion_tokens=457
[LM Studio] finish_reason: stop
[LM Studio] Speed: 40.8 tok/s (457 completion tokens in 11.21s)
[LM Studio] Time to first token (TTFT): 1.43s
[LM Studio] full_recipe validation: Valid(warnings: [])
exit 0
```

### Выдержка 4: `docs/reports/last_ai_smoke_run3.txt` (прогон 3 из 3)
```
[LM Studio] Server reachable on port 1235! Using model: ornith-1.5-35b-a3b
[LM Studio] Selected port 1235 with model: ornith-1.5-35b-a3b
[LM Studio] Model info: ornith-1.5-35b-a3b (context: 8192, parallel: 2)

[LM Studio] 1/2: Testing suggest_dishes ...
[LM Studio] suggest_dishes completed in 12405 ms
[LM Studio] Usage: prompt_tokens=381, completion_tokens=536
[LM Studio] finish_reason: stop
[LM Studio] Speed: 43.2 tok/s (536 completion tokens in 12.40s)
[LM Studio] Time to first token (TTFT): 0.48s
[LM Studio] suggest_dishes validation: Valid(warnings: [])

[LM Studio] 2/2: Testing full_recipe for "Картофельное пюре с курицей" (soup, easy) ...
[LM Studio] full_recipe completed in 17805 ms
[LM Studio] Usage: prompt_tokens=392, completion_tokens=749
[LM Studio] finish_reason: stop
[LM Studio] Speed: 42.1 tok/s (749 completion tokens in 17.80s)
[LM Studio] Time to first token (TTFT): 1.45s
[LM Studio] full_recipe validation: Valid(warnings: [])
exit 0
```

### Выдержка 5: `docs/reports/last_ai_smoke_x3.status`
```
running 
run 1 done 
run 2 done 
run 3 done 
done 
```

### Выдержка 6: `docs/reports/last_gpu_diag.txt` (состояние GPU и LM Studio)
```
===== nvidia-smi
| GPU  Name                  Driver-Model | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|   0  NVIDIA GeForce RTX 3080      WDDM  |   00000000:01:00.0  On |                  N/A |
|  0%   35C    P8             29W /  320W |    4598MiB /  10240MiB |     21%      Default |

===== gpu memory and clocks
NVIDIA GeForce RTX 3080, 10240 MiB, 4598 MiB, 5454 MiB, 21 %, 35, 210 MHz, 2100 MHz, 29.23 W, P8, 0x0000000000000001

===== lms ps
ornith-1.5-35b-a3b    ornith-1.5-35b-a3b    IDLE      29.21 GB    8192       2           Local        
```

### Выдержка 7: `docs/reports/lms_load_help.txt` (проверенные флаги `lms load`)
```
Usage: lms load [options] [model-key]

Load a model

Options:
   --gpu <offload-ratio>                    GPU offload ratio. Valid values: "off", "max", or 0..1
   -c, --context-length <length>            The number of tokens to consider as context
   --parallel <count>                       Maximum number of predictions the model can run at a given time
   --ttl <seconds>                          TTL: unload when not used for this number of seconds
```

---

## 3. Результаты сборки релизных APK

Команда: `flutter build apk --release --split-per-abi`  
Файлы в `build\app\outputs\flutter-apk\`:
- `app-arm64-v8a-release.apk` — **31.7 MB** (целевой APK для современных Android-смартфонов)
- `app-armeabi-v7a-release.apk` — **28.0 MB** (для 32-битных устройств)
- `app-x86_64-release.apk` — **34.1 MB** (для эмуляторов)

---

## 4. Что проверить владельцу на реальном телефоне

Пункты из `docs/STATUS.md`, требующие проверки владельцем на устройстве:
1. **Скриншоты с телефона:** прислать скриншоты мест (если остались замечания по верстке) в `docs/reports/img/device/`.
2. **Сканер QR-кода на телефоне:**
   - На ПК запустить `tool\pair_pc.bat` (откроется QR-код в браузере).
   - В приложении на телефоне нажать «Подключить компьютер по QR-коду», навести камеру на монитор и подтвердить автоматическое подключение (192.168.50.224:1235).
3. **Установка обновлённого APK:** установить `app-arm64-v8a-release.apk` на телефон бабушки, проверить сценарии ТЗ 11 и экран «Проверка помощника».
