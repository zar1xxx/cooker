Напиши полный рецепт блюда «{{title}}» ({{dish_type}}, сложность {{difficulty}}) на {{servings}} порц.
Главные продукты: {{main_ingredients}}. Есть дома: {{available_ingredients}}.
Нельзя: {{forbidden_ingredients}}.

Требования:
- Количества — на {{servings}} порц., единицы только из схемы (g, kg, ml, l, pcs, tbsp, tsp, cup, pinch, to_taste).
- Шаг — не больше 2 предложений. Для каждого шага с ожиданием укажи timer_seconds.
- Сумма времени шагов не должна превышать total_minutes.
{{#if retry_reason}}

Предыдущий ответ отклонён: {{retry_reason}}. Исправь это.
{{/if}}
