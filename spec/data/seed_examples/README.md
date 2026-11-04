# Формат seed-файлов

Эталонные записи. Полные файлы `assets/seed/ingredients.json` (≥ 250) и `assets/seed/recipes.json` (≥ 120) собираются по `skills/seed-data`.

- `ingredient_id` в рецептах ссылается на `id` из ingredients.
- `unit` — коды из `spec/data/enums.json → Unit` (на экране показываются русские подписи).
- `amount: null` допустим только с `unit: to_taste`.
- `parent_id` задаёт иерархию для аллергий и совпадений (`chicken_fillet` → `chicken`).
