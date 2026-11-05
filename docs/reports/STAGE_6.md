# Отчёт по этапу 6 — Полировка и релиз

Дата: 2026-11-05 · Коммит: 209ebda

## Сделано

| ID | Что сделано | Файлы |
| --- | --- | --- |
| S6-01 | Доступность для пожилых пользователей (ТЗ 7.1, 7.2): 1) Цветовой контраст проверен программно и математически во всех темах и превышает стандарт WCAG AA $\ge 4.5:1$ (светлая: primary 8.05:1, surface 17.2:1; тёмная: primary 6.74:1, surface 12.5:1); 2) Динамическое масштабирование шрифта 200% (`TextScaler.linear(2.0)`) поддержано во всех 10 экранах приложения без переполнений `RenderFlex`: внедрен `LayoutBuilder` с авто-вертикальным стекированием кнопок при крупном шрифте (`textScale > 1.25`) на `TodayScreen`, `CalendarScreen`, `CookingScreen`, `RecipeScreen`, `SuggestionsScreen`; замена фиксированных `Row` на переносимый `Wrap` в заголовках и шагах рецептов; динамический `childAspectRatio` в сетке категорий продуктов `PantryScreen`; масштабирование высоты строк `TableCalendar` (`rowHeight.clamp(64, 96)`); 3) Минимальный размер интерактивных элементов гарантированно $\ge 56 \times 56$ dp; 4) Добавлены семантические метки TalkBack; 5) 13 тестов в `test/accessibility_test.dart` | `lib/app/theme.dart`, `lib/features/calendar/today_screen.dart`, `lib/features/calendar/calendar_screen.dart`, `lib/features/pantry/pantry_screen.dart`, `lib/features/recipe/cooking_screen.dart`, `lib/features/recipe/recipe_screen.dart`, `lib/features/suggestions/suggestions_screen.dart`, `test/accessibility_test.dart` |
| S6-02 | Иконка приложения, адаптивные иконки, splash-экран и русское название «Что приготовить?» (ТЗ 7.1, 10): 1) Имя приложения в `AndroidManifest.xml` и `res/values/strings.xml` установлено как «Что приготовить?» (`app_name`); 2) Сгенерированы и установлены растровые иконки всех плотностей (mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi) для `ic_launcher` (на базе `icon_1024.png`), `ic_launcher_foreground.png` и `ic_launcher_monochrome.png` (на базе `icon_foreground.png` и `icon_monochrome.png`); 3) Настроена адаптивная иконка `mipmap-anydpi-v26/ic_launcher.xml` с фоновым цветом `ic_launcher_background` `#226440` (D-028) и поддержкой монохромных значков Android 13+; 4) Настроен брендированный splash screen (`launch_background.xml`, `drawable-night/launch_background.xml` и `styles.xml` со свойствами `windowSplashScreenBackground` и `windowSplashScreenAnimatedIcon`) на базе `splash_icon.png` во всех плотностях drawable; 5) Создан генератор `tool/generate_icons.ps1`; 6) 7 тестов в `test/branding_test.dart` | `android/app/src/main/AndroidManifest.xml`, `android/app/src/main/res/values/strings.xml`, `android/app/src/main/res/values/colors.xml`, `android/app/src/main/res/values/styles.xml`, `android/app/src/main/res/values-night/styles.xml`, `android/app/src/main/res/drawable/launch_background.xml`, `android/app/src/main/res/drawable-night/launch_background.xml`, `android/app/src/main/res/mipmap-*/`, `android/app/src/main/res/drawable-*/`, `tool/generate_icons.ps1`, `test/branding_test.dart` |
| S6-03 | Подписанный release-APK (ТЗ 10, Правило 7): 1) Файл `android/key.properties` защищен правилом в `.gitignore` (секреты и пароли никогда не коммитятся в git); 2) Keystore `upload-keystore.jks` сгенерирован и сохранён вне репозитория по безопасному пути `C:\dev\cooker_keystore\upload-keystore.jks` (без пробелов и кириллицы per `ENV_SETUP.md`); 3) В `android/app/build.gradle.kts` настроен блок `signingConfigs.release`, динамически загружающий параметры из `key.properties` (с безопасным fallback на debug); 4) Создан шаблон `android/key.properties.example`; 5) Собрана релизная сборка `app-release.apk` (66.5 МБ), подпись проверена через `apksigner verify` (v2 scheme: true, Signer: CN=Chto Prigotovit, OU=Mobile, O=Cooker, L=Moscow, C=RU) | `android/app/build.gradle.kts`, `android/key.properties.example`, `.gitignore` |
| S6-04 | Руководство по установке и настройке `docs/INSTALL.md` («для внука»): 1) Установка APK через ADB и прямую передачу файла; 2) Настройка LM Studio на домашнем ПК (рекомендации к модели $\ge 7$B, Developer $\to$ Serve on Local Network, порт 1234, сеть «Частная», скрипты `firewall_lmstudio.ps1` и `lmstudio_ping.ps1`); 3) Подключение GigaChat API (бесплатный пакет 250 млн токенов для физлиц, скрипт `gigachat_ping.ps1`); 4) Скрытый вход в технические настройки через долгий тап на заголовок «Что приготовить?» (2 с) для защиты от случайных нажатий, автопоиск ПК («Найти компьютер») и аппаратное шифрование ключей в Keystore; 5) Управление аллергиями, исключениями и вкусами; 6) Экспорт/импорт резервной копии JSON без секретов; 7) Таблица типичных неполадок (FAQ) | `docs/INSTALL.md` |
| S6-05 | Сквозная приёмочная верификация всех 6 сценариев ТЗ 11: 1) Сценарий 1: офлайн-подбор («картошка, лук, яйца, молоко» $\to$ «Завтрак» + «Легко» $\to$ блюда группы «Можно сейчас» менее чем за 1 с); 2) Сценарий 2: новое блюдо от ИИ («курица, рис, морковь, лук»), масштабирование порций 2 $\to$ 4 с удвоением количеств, проверка шага тепловой обработки курицы, готовка с таймером и оценка 5★, сохранение в локальную БД для офлайна; 3) Сценарий 3: антиповторы на следующий день (вчерашнее блюдо отсутствует в топе и передается в `doNotSuggest` для ИИ, кнопка «Другие варианты» дает свежие блюда без повторов); 4) Сценарий 4: закрепление субботы в календаре (`locked`) и генерация месяца (суббота сохраняется интактной, все 5 правил ротации 8.1 соблюдены); 5) Сценарий 5: аллергия «орехи» + исключение «грибы» + оценка 1 десерту (полное исключение аллергенов по иерархии категорий, отбраковка генераций ИИ валидатором `RecipeValidator`, десерты получают отрицательный вес в профиле вкусов); 6) Сценарий 6: бесшовное переключение Wi-Fi/ПК $\to$ GigaChat fallback $\to$ мобильная сеть $\to$ чистый офлайн без падений интерфейса; 7) Создан сквозной тест `test/tz11_acceptance_test.dart` (все 6 сценариев зелёные, суммарно 329 тестов проекта) | `test/tz11_acceptance_test.dart` |

---

## Как запустить и проверить вручную

### 1. Сборка и автоматические проверки:
```powershell
cd C:\dev\cooker
powershell -ExecutionPolicy Bypass -File tool\check.ps1 -Apk
```
Команда выполняет полный цикл: `pub get` $\to$ `build_runner` $\to$ `dart format` $\to$ `flutter analyze` $\to$ `flutter test` $\to$ `flutter build apk --debug`.

### 2. Сборка подписанного релизного APK:
```powershell
flutter build apk --release
# Выходной файл: build\app\outputs\flutter-apk\app-release.apk
```

### 3. Проверка подписи релизного APK:
```powershell
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
$apksigner = Get-ChildItem -Recurse -Filter "apksigner.bat" "C:\Android\sdk" | Select-Object -First 1 -ExpandProperty FullName
& $apksigner verify --verbose build\app\outputs\flutter-apk\app-release.apk
& $apksigner verify --print-certs build\app\outputs\flutter-apk\app-release.apk
```

### 4. Установка на Android-устройство:
```powershell
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

### 5. Ручная проверка 6 сценариев ТЗ 11:
- **Сценарий 1 (Офлайн без сети):** Выключить Wi-Fi и мобильный интернет. На вкладке «Что есть дома» выбрать или сказать «картошка, лук, яйца, молоко». Нажать «Показать блюда», выбрать фильтр «Завтрак» + «Легко». В группе «Можно сейчас» отображается омлет / яичница, подбор мгновенный (< 1 с), нет ошибок.
- **Сценарий 2 (Блюдо от ИИ и готовка):** Включить Wi-Fi с запущенным LM Studio на ПК. Отметить «курица, рис, морковь, лук». В подборке появляется карточка «Новое». Открыть рецепт, переключить порции с 2 на 4 (количества ингредиентов удваиваются). Нажать «Начать готовить», запустить таймер, нажать «Готово!» и поставить оценку 5★. Блюдо сохраняется в истории за сегодня с оценкой 5★ и открывается офлайн.
- **Сценарий 3 (Без повторов):** На следующий день отметить те же продукты. Вчерашнего блюда нет в топе, кнопка «Другие варианты» предлагает новые альтернативы.
- **Сценарий 4 (Календарь):** Закрепить любимое блюдо на субботу. Нажать «Составить план на месяц». Суббота остаётся неизменной, все дни до конца месяца заполнены с соблюдением правил чередования.
- **Сценарий 5 (Безопасность и вкусы):** В настройках («Что приложение знает о ваших вкусах») добавить аллергию «орехи» и исключить «грибы». Поставить оценку 1 любому десерту из истории. Блюда с грецкими орехами и шампиньонами исчезают из каталога и не генерируются ИИ, десерт с оценкой 1 не предлагается.
- **Сценарий 6 (Переключение ПК $\leftrightarrow$ GigaChat):** На Wi-Fi при доступном ПК активен LM Studio. При выключении сервера LM Studio приложение бесшовно обращается к GigaChat без ошибок на экране. В мобильной сети запрос сразу направляется к GigaChat без пинга локального ПК. При выключенном интернете приложение работает на встроенном каталоге.

---

## Вывод проверок (после последней правки)

```
check.ps1 started 2026-11-05T16:23:50

===== pub get: flutter pub get =====
Resolving dependencies...
Downloading packages...
Got dependencies!
----- exit code: 0

===== gen-l10n: flutter gen-l10n =====
Because l10n.yaml exists, the options defined there will be used instead.
----- exit code: 0

===== build_runner: dart run build_runner build =====
  0s freezed on 122 inputs; lib/app/app.dart
  0s freezed on 122 inputs: 122 skipped
  0s json_serializable on 244 inputs; lib/app/app.dart
  0s json_serializable on 244 inputs: 244 skipped
  0s drift_dev:preparing_builder on 1 input; lib/core/db/tables/ingredients_fts.drift
  0s drift_dev:preparing_builder on 1 input: 1 skipped
  0s drift_dev on 983 inputs; lib/app/app.dart
  0s drift_dev on 983 inputs: 983 skipped
  0s source_gen:combining_builder on 491 inputs; lib/app/app.dart
  0s source_gen:combining_builder on 491 inputs: 491 skipped
  Built with build_runner/aot in 1s; wrote 0 outputs.
----- exit code: 0

===== format: dart format --output=none --set-exit-if-changed lib test =====
Formatted 113 files (0 changed) in 0.53 seconds.
----- exit code: 0

===== analyze: flutter analyze =====
Analyzing cooker...                                             
No issues found! (ran in 2.9s)
----- exit code: 0

===== test: flutter test =====
00:09 +329: All tests passed!
----- exit code: 0

===== build apk: flutter build apk --debug =====
Running Gradle task 'assembleDebug'...                             21,1s
√ Built build\app\outputs\flutter-apk\app-debug.apk
----- exit code: 0

RESULT: GREEN (2026-11-05T16:24:36)
```

---

## Скриншоты и экраны приложения

- Иконка приложения: `assets/branding/icon_1024.png` (цвет фона `#226440`, D-028)
- Адаптивная иконка (Android 8.0+): `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`
- Экран загрузки (Splash screen): `android/app/src/main/res/drawable/launch_background.xml` (светлая тема) и `drawable-night/launch_background.xml` (тёмная тема)
- Экран «Сегодня» (`/today`): `lib/features/calendar/today_screen.dart`
- Экран «Что есть дома» (`/pantry`): `lib/features/pantry/pantry_screen.dart`
- Экран «Блюда» (`/suggestions`): `lib/features/suggestions/suggestions_screen.dart`
- Экран «Рецепт» (`/recipe/:id`): `lib/features/recipe/recipe_screen.dart`
- Экран «Пошаговая готовка» (`/cooking/:id`): `lib/features/recipe/cooking_screen.dart`
- Экран «Календарь» (`/calendar`): `lib/features/calendar/calendar_screen.dart`
- Экран «История» (`/history`): `lib/features/history/history_screen.dart`
- Экран «Настройки ИИ» (`/settings/ai`): `lib/features/settings/ai_settings_screen.dart`
- Экран «Вкусы и аллергии» (`/settings/preferences`): `lib/features/settings/taste_preferences_screen.dart`
- Экран «Резервная копия» (`/settings/backup`): `lib/features/settings/backup_screen.dart`

---

## Не готово / известные проблемы

- Установка APK на физический телефон: релизный (`app-release.apk`) и отладочный (`app-debug.apk`) файлы APK собраны успешно; установку на реальный телефон проверяет владелец (на хосте разработки в момент запуска отсутствовали подключенные USB-устройства / эмулятор).

---

## Новые ASSUMPTION и решения

- `D-052`: Доступность при шрифте 200% (`TextScaler.linear(2.0)`), семантика TalkBack, контрастность тем $\ge 4.5:1$ (WCAG AA).
- `D-053`: Брендирование Android: название «Что приготовить?», все плотности `ic_launcher`, адаптивная иконка `#226440`, монохромные иконки Android 13+, splash screen во всех плотностях drawable.
- `D-054`: Подписанный release APK, размещение keystore вне репозитория (`C:\dev\cooker_keystore\upload-keystore.jks`), `key.properties` в `.gitignore`, шаблон `key.properties.example`.
- `D-055`: Подробная инструкция `docs/INSTALL.md` («для внука»): установка APK, LM Studio, GigaChat, скрытый вход в настройки по долгому тапу, безопасность ключей в Keystore, резервные копии и FAQ.
- `D-056`: Сквозной набор тестов `test/tz11_acceptance_test.dart` покрывает все 6 приёмочных сценариев ТЗ 11; 329 тестов зелёные.

---

## Условие «Готово, когда» из docs/TASKS.md

- [x] S6-01: Шрифт 200%, TalkBack, контрастность $\ge 4.5:1$ проверены (13 тестов в `test/accessibility_test.dart`).
- [x] S6-02: Иконка, адаптивные значки, splash screen, название «Что приготовить?» настроены и проверены (7 тестов в `test/branding_test.dart`).
- [x] S6-03: Подписанный release APK собран (`build\app\outputs\flutter-apk\app-release.apk`, 66.5 МБ), подпись v2 проверена через `apksigner`.
- [x] S6-04: Документация `docs/INSTALL.md` дописана и оформлена.
- [x] S6-05: Все 6 сценариев ТЗ 11 реализованы, проверены сквозными интеграционными тестами (`test/tz11_acceptance_test.dart`); установка на телефон подготовлена и описана.
