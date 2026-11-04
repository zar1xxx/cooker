# Окружение разработки (Windows)

Сначала проверь, что уже стоит: `flutter doctor -v`. Ставь только то, чего не хватает.

## Требования

| Что | Где / как |
| --- | --- |
| Flutter stable | В `PATH`. Если официальная ссылка на архив не работает: `git clone -b stable https://github.com/flutter/flutter.git C:\flutter` и `C:\flutter\bin` в `PATH` |
| Android SDK | **`C:\Android\sdk`** (без пробелов и кириллицы). `flutter config --android-sdk C:\Android\sdk` |
| Android NDK | Версию, которую попросит Gradle при первой сборке, ставить через Android Studio → SDK Manager → SDK Tools → NDK (Side by side) → «Show Package Details» |
| Gradle cache | Переменная `GRADLE_USER_HOME=C:\gradle` |
| JDK | Тот, что идёт с Android Studio (`flutter doctor` покажет) |
| Проект | `C:\dev\cooker` |

## Почему пути важны

Имя пользователя Windows на этом ПК содержит пробел и кириллицу. Gradle, NDK и CMake на таких путях ломаются с невнятными ошибками. Поэтому **всё** — SDK, кэш Gradle, проект — живёт в путях из латиницы без пробелов.

## Известные проблемы

| Симптом | Причина | Решение |
| --- | --- | --- |
| Сборка падает с путём вида `C:\Users\Мой Компьютер\...` | SDK или кэш Gradle в профиле пользователя | Проверь `flutter config`, `GRADLE_USER_HOME`, `local.properties` (`sdk.dir=C:\\Android\\sdk`) |
| `NDK not configured` / просит конкретную версию NDK | Нет нужной версии NDK | Поставить ровно ту версию через SDK Manager |
| `adb.exe` занят при копировании/обновлении SDK | Запущен adb-сервер | `adb kill-server` |
| Плагин несовместим с compileSdk / AGP | Старая версия плагина | Обнови плагин до последней major-версии, проверь changelog |
| `flutter` не найден | Не в `PATH` | Перезапусти терминал после правки `PATH` |
| Телефон не видит ПК / LM Studio | Брандмауэр, сеть «Общедоступная», LM Studio слушает только localhost | `tool/firewall_lmstudio.ps1` от администратора; сеть Wi-Fi → «Частная»; в LM Studio включить «Serve on Local Network» |

## Быстрая проверка окружения

```powershell
flutter doctor -v
flutter config --list
echo $env:GRADLE_USER_HOME
adb devices
```

## Установка на телефон

```powershell
cd C:\dev\cooker
flutter build apk --debug
# файл: build\app\outputs\flutter-apk\app-debug.apk
flutter install   # если телефон подключён по USB с отладкой
```
