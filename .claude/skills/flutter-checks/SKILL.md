---
name: flutter-checks
description: Запуск проверок, кодогенерации и сборки APK для проекта; разбор типичных ошибок сборки на Windows.
---

# Проверки и сборка

## Основная команда

```powershell
powershell -ExecutionPolicy Bypass -File tool\check.ps1
```

Делает по порядку: `flutter pub get` → `dart run build_runner build --delete-conflicting-outputs` → `dart format --set-exit-if-changed lib test` → `flutter analyze` → `flutter test`. Пишет полный вывод в `docs/reports/last_check.txt`. Код выхода 0 = всё зелёное.

Флаг `-Apk` дополнительно собирает `flutter build apk --debug`.

## Правила

- `flutter analyze` — ноль замечаний (включая info). Не глуши правила через `// ignore:` без комментария, почему.
- Сгенерированные файлы (`*.g.dart`, `*.freezed.dart`) коммитятся — так CI не зависит от кодогенерации. (`// ASSUMPTION:` — если решишь иначе, запиши в DECISIONS.)
- Тесты, которым нужна БД, используют `NativeDatabase.memory()` из drift.
- Тесты, которым нужен ИИ, используют `FakeAiProvider`. **Никаких сетевых вызовов в `flutter test`.**
- Время в тестах — через внедряемый `Clock` (`package:clock`), не `DateTime.now()` напрямую.

## Проверка на устройстве

```powershell
adb devices
flutter run               # отладка
flutter build apk --debug # файл для установки
```

## Ошибки сборки

Сначала `docs/ENV_SETUP.md` → «Известные проблемы». Далее:

1. Прочитай ошибку целиком, найди **первую** строку с `error`/`FAILURE`.
2. `flutter clean` + `flutter pub get` — только один раз, не по кругу.
3. Конфликт версий плагинов → `flutter pub outdated`, подними конкретный пакет, а не все сразу.
4. Запиши в отчёт точный текст ошибки и что помогло.
