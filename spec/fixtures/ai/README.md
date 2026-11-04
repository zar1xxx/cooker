# Эталонные ответы ИИ

Скопируй в `test/fixtures/ai/`. `FakeAiProvider` отдаёт их по имени.

| Файл | Ожидаемое поведение |
| --- | --- |
| `suggest_dishes_ok.json` | Валиден, 2 карточки |
| `suggest_dishes_wrapped.txt` | JSON внутри текста и ```json — парсер должен вырезать объект и принять |
| `full_recipe_ok.json` | `Valid`, без предупреждений |
| `full_recipe_allergen.json` | При аллергии «орехи» → `Rejected` (грецкие орехи — потомок `nuts`) |
| `full_recipe_undercooked.json` | `Retryable`: курица 3 мин < минимума 20 мин |
| `full_recipe_broken.txt` | Обрезанный JSON → повтор → при повторной неудаче отказ |
| `month_plan_week_ok.json` | Валиден, 3 дня |
