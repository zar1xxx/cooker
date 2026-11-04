---
name: recipe-safety
description: Правила RecipeValidator и безопасности рецептов (аллергены, тепловая обработка, количества). Открывать при работе с валидатором, seed-рецептами и ответами ИИ.
---

# Безопасность рецептов

Любой рецепт — из seed, от ИИ или введённый вручную — сохраняется только после `RecipeValidator.validate(recipe, profile)`.

## Результат валидации

```dart
sealed class ValidationResult {}
class Valid extends ValidationResult { final List<Warning> warnings; }
class Retryable extends ValidationResult { final String reasonForModel; }  // можно переспросить ИИ
class Rejected extends ValidationResult { final String reason; }           // выбросить без повтора
```

`reasonForModel` — короткий текст на русском, который подставляется в повторный запрос («В шаге 3 нет времени обжарки курицы»).

## Проверки (ТЗ 9.1)

1. **Схема** — `spec/ai/schemas/full_recipe.schema.json`. Нарушение → `Retryable`.
2. **Аллергены и исключения** — по `ingredient_id` с учётом синонимов **и потомков** (аллергия «орехи» ловит «грецкие орехи», «фундук»; исключение «грибы» ловит «шампиньоны»). Также поиск по тексту шагов. Нарушение → `Rejected`.
3. **Тепловая обработка** — для категорий из `spec/ai/safety_minimums.json`: в рецепте должен быть шаг с ключевым словом обработки и временем (`timer_seconds` или число минут в тексте) не меньше минимума. Нарушение → `Retryable`, после второго раза → `Rejected`.
4. **Структура** — ≥ 2 шагов; сумма `timer_seconds` ≤ `total_minutes × 60 × 1.1`; `servings` 1–12. Нарушение → `Retryable`.
5. **Количества** — лимиты на порцию из `safety_minimums.json → per_serving_limits`. Нарушение → `Valid` с `Warning` («проверьте количество»), не отказ.
6. **Стоп-список** — `safety_minimums.json → stop_list` (несъедобное и опасное). Совпадение → `Rejected`.

## Правила для seed-рецептов

- Валидатор прогоняется по всему `recipes.json` в тесте `seed_recipes_valid_test`. Падение = задача S1-01 не закрыта.
- Сложность пересчитывается по правилам ТЗ 4.2, а не берётся из файла на веру. Расхождение → тест падает.

## UI

- Рецепт от ИИ: подпись «Рецепт придуман помощником. Проверяйте готовность мяса и рыбы».
- `Warning` по количеству — значок у ингредиента и подсказка при нажатии.
