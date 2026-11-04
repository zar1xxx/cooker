---
name: drift-database
description: Таблицы, миграции, DAO и кодогенерация drift в проекте «Что приготовить?».
---

# База данных (drift / SQLite)

## Где что

- `lib/core/db/tables/` — по файлу на таблицу (ТЗ 4.1).
- `lib/core/db/daos/` — DAO по фичам: `PantryDao`, `RecipeDao`, `HistoryDao`, `PlanDao`, `FeedbackDao`, `AiCacheDao`.
- `lib/core/db/app_database.dart` — `@DriftDatabase`, `schemaVersion`, `MigrationStrategy`.

## Соглашения

- Первичный ключ `id TEXT` = UUID v4 (`package:uuid`). Не автоинкремент.
- Каждая таблица: `createdAt`, `updatedAt`, `deletedAt` (nullable). Все выборки по умолчанию фильтруют `deletedAt IS NULL`.
- `updatedAt` обновляется в DAO при любом изменении (не триггером — так проще тестировать).
- Даты дня (`cooked_on`, `date` в плане) — строка `YYYY-MM-DD` в локальном времени устройства. Моменты (`at`, `created_at`) — UTC epoch ms.
- JSON-поля (`synonyms`, веса профиля) — `TextColumn` + `TypeConverter` на `freezed`-модель.
- Перечисления (`DishType`, `Difficulty`, `status`, `kind`) — `textEnum<...>()`, значения как в `spec/data/enums.json`.
- Поиск продуктов — FTS5 виртуальная таблица `ingredients_fts(name, synonyms)`, синхронизация в DAO.

## Миграции

- Любое изменение схемы = `schemaVersion + 1` + шаг в `onUpgrade` + тест миграции (`drift_dev schema dump` / `SchemaVerifier`).
- Схемы версий хранить в `drift_schemas/` (коммитить).
- Никогда не менять уже выпущенную миграцию.

## Seed

- Загрузка в `onCreate` после создания таблиц, одной транзакцией.
- Идемпотентно: повторный запуск не дублирует (ключ — `id` из seed-файла).
- Новая версия seed-файла → догружать новые id при апгрейде, существующие записи пользователя не трогать.

## Кодогенерация

```powershell
dart run build_runner build --delete-conflicting-outputs
```
