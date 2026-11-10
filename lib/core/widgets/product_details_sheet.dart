import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../db/app_database.dart';
import '../providers.dart';

/// Helper knowledge base for culinary ingredients: storage, shelf life, allergens, substitutes.
class IngredientKnowledge {
  const IngredientKnowledge._();

  static String getStorageRecommendation(String category, String name) {
    final lower = name.toLowerCase();
    if (lower.contains('картоф') ||
        lower.contains('лук') ||
        lower.contains('чеснок')) {
      return 'В тёмном, сухом, прохладном месте (+5...+12°C), отдельно от других овощей.';
    }
    switch (category.toLowerCase()) {
      case 'meat':
      case 'poultry':
        return 'В холодильнике при 0...+2°C до 2–3 дней. Для долгого хранения — в морозилке до 6 месяцев.';
      case 'fish':
      case 'seafood':
        return 'В самой холодной зоне холодильника до 1–2 дней. В морозилке — до 3 месяцев.';
      case 'dairy':
        return 'В холодильнике при +2...+4°C на средней полке. После вскрытия — употребить за 3 дня.';
      case 'vegetables':
      case 'fruits':
        return 'В специальном отсеке холодильника (для зелени — в стакане с водой или влажном полотенце).';
      case 'grains':
      case 'grocery':
      case 'spices':
        return 'В сухом шкафу в герметичной стеклянной или жестяной банке при комнатной температуре.';
      case 'bakery':
        return 'В хлебнице или бумажном пакете при комнатной температуре.';
      default:
        return 'В прохладном сухом месте, защищённом от прямых солнечных лучей.';
    }
  }

  static String getShelfLife(String category, String name) {
    final lower = name.toLowerCase();
    if (lower.contains('яйц')) {
      return 'До 25 дней при температуре от 0 до +20°C.';
    }
    if (lower.contains('молок')) {
      return 'До 5–7 дней (после вскрытия 48–72 ч).';
    }
    if (lower.contains('масло сливоч')) {
      return 'До 35 дней в холодильнике.';
    }
    if (lower.contains('хлеб')) {
      return '3–4 дня при комнатной температуре.';
    }
    if (lower.contains('картоф')) {
      return 'До 2–3 месяцев в прохладном месте.';
    }
    switch (category.toLowerCase()) {
      case 'meat':
        return 'Охлаждённое — до 3 дней, замороженное — до 6 месяцев.';
      case 'fish':
        return 'Охлаждённая — 24–48 часов, замороженная — до 3 месяцев.';
      case 'dairy':
        return 'От 5 до 14 дней в зависимости от упаковки.';
      case 'grains':
        return '12–18 месяцев в сухом месте.';
      default:
        return 'Смотрите дату изготовления на заводской упаковке.';
    }
  }

  static String getAllergenInfo(String category, String name) {
    final lower = name.toLowerCase();
    if (lower.contains('молок') ||
        lower.contains('сыр') ||
        lower.contains('творог') ||
        lower.contains('сливк') ||
        lower.contains('сметан')) {
      return 'Внимание: содержит лактозу и молочный белок.';
    }
    if (lower.contains('мука') ||
        lower.contains('хлеб') ||
        lower.contains('макарон') ||
        lower.contains('манка') ||
        lower.contains('пшениц')) {
      return 'Внимание: содержит глютен.';
    }
    if (lower.contains('яйц')) {
      return 'Внимание: продукт содержит куриный белок (распространённый аллерген).';
    }
    if (lower.contains('орех') || lower.contains('арахис')) {
      return 'Высокая аллергенность: содержит орехи.';
    }
    if (lower.contains('рыб') ||
        lower.contains('креветк') ||
        lower.contains('кальмар')) {
      return 'Внимание: аллерген (рыба и морепродукты).';
    }
    if (lower.contains('мёд')) {
      return 'Продукт пчеловодства, возможна индивидуальная реакция.';
    }
    return 'Не входит в список наиболее частых пищевых аллергенов.';
  }

  static String getSubstitute(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('сметан')) {
      return 'Густой греческий йогурт или кефир.';
    }
    if (lower.contains('масло сливоч')) {
      return 'Растительное или кокосовое масло.';
    }
    if (lower.contains('сахар')) {
      return 'Мёд, сироп топинамбура или яблочное пюре.';
    }
    if (lower.contains('куриц') || lower.contains('курин')) {
      return 'Филе индейки или нежирная свинина.';
    }
    if (lower.contains('говядин')) {
      return 'Телятина или филе бедра индейки.';
    }
    if (lower.contains('картоф')) {
      return 'Кабачок, цветная капуста или батат.';
    }
    if (lower.contains('рис')) {
      return 'Булгур, гречка, кускус или перловка.';
    }
    if (lower.contains('мука пшенич')) {
      return 'Овсяная, рисовая или кукурузная мука.';
    }
    if (lower.contains('молок')) {
      return 'Овсяное, миндальное или безлактозное молоко.';
    }
    if (lower.contains('лимон')) {
      return 'Яблочный уксус или лайм.';
    }
    if (lower.contains('майонез')) {
      return 'Сметана с горчицей и каплей лимонного сока.';
    }
    return 'Аналогичных по кулинарным свойствам продуктов в этой категории.';
  }
}

/// Rich bottom sheet showing details for a culinary ingredient (R8-13).
class ProductDetailsSheet extends ConsumerStatefulWidget {
  const ProductDetailsSheet({
    super.key,
    required this.ingredientId,
    this.fallbackName,
  });

  final String ingredientId;
  final String? fallbackName;

  static Future<void> show(
    BuildContext context, {
    required String ingredientId,
    String? fallbackName,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ProductDetailsSheet(
        ingredientId: ingredientId,
        fallbackName: fallbackName,
      ),
    );
  }

  @override
  ConsumerState<ProductDetailsSheet> createState() =>
      _ProductDetailsSheetState();
}

class _ProductDetailsSheetState extends ConsumerState<ProductDetailsSheet> {
  Ingredient? _ingredient;
  List<Recipe> _matchingRecipes = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = ref.read(databaseProvider);
    final ing = await (db.select(
      db.ingredients,
    )..where((tbl) => tbl.id.equals(widget.ingredientId))).getSingleOrNull();

    // Find recipes containing this ingredient
    final recIngredients = await (db.select(
      db.recipeIngredients,
    )..where((tbl) => tbl.ingredientId.equals(widget.ingredientId))).get();

    final recipeIds = recIngredients.map((ri) => ri.recipeId).toSet();

    List<Recipe> recipes = [];
    if (recipeIds.isNotEmpty) {
      recipes =
          await (db.select(db.recipes)
                ..where((tbl) => tbl.id.isIn(recipeIds))
                ..limit(5))
              .get();
    }

    if (mounted) {
      setState(() {
        _ingredient = ing;
        _matchingRecipes = recipes;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pantryAsync = ref.watch(pantryProvider);
    final isAvailable =
        pantryAsync.value?.contains(widget.ingredientId) ?? false;

    final displayName =
        _ingredient?.name ?? widget.fallbackName ?? widget.ingredientId;
    final category = _ingredient?.category ?? 'other';

    final storage = IngredientKnowledge.getStorageRecommendation(
      category,
      displayName,
    );
    final shelfLife = IngredientKnowledge.getShelfLife(category, displayName);
    final allergen = IngredientKnowledge.getAllergenInfo(category, displayName);
    final substitute = IngredientKnowledge.getSubstitute(displayName);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Row: Title & Close
            Row(
              children: [
                Expanded(
                  child: Text(
                    displayName[0].toUpperCase() + displayName.substring(1),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Закрыть',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Pantry Availability Toggle Button
            FilledButton.tonalIcon(
              onPressed: () {
                ref.read(pantryProvider.notifier).toggle(widget.ingredientId);
              },
              icon: Icon(
                isAvailable ? Icons.check_circle : Icons.add_circle_outline,
                color: isAvailable
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              label: Text(
                isAvailable
                    ? 'Есть дома (нажмите, чтобы убрать)'
                    : 'Нет дома (нажмите, чтобы добавить)',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: isAvailable
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 16),

            // Storage Recommendation Tile
            _InfoSectionTile(
              icon: Icons.inventory_2_outlined,
              title: 'Где хранить и сколько',
              content: storage,
              theme: theme,
            ),
            const SizedBox(height: 12),

            // Shelf Life Tile
            _InfoSectionTile(
              icon: Icons.timer_outlined,
              title: 'Срок годности',
              content: shelfLife,
              theme: theme,
            ),
            const SizedBox(height: 12),

            // Allergen Tile
            _InfoSectionTile(
              icon: Icons.health_and_safety_outlined,
              title: 'Аллергенность',
              content: allergen,
              theme: theme,
            ),
            const SizedBox(height: 12),

            // Substitute Tile
            _InfoSectionTile(
              icon: Icons.swap_horiz,
              title: 'Чем заменить при готовке',
              content: substitute,
              theme: theme,
            ),
            const SizedBox(height: 20),

            // Matching Dishes
            if (_matchingRecipes.isNotEmpty) ...[
              Text(
                'Блюда с этим продуктом (${_matchingRecipes.length})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              for (final recipe in _matchingRecipes)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(recipe.title),
                    subtitle: Text(
                      '${recipe.totalMinutes} мин • ${recipe.cuisine} кухня',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/recipe/${recipe.id}');
                    },
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

class _InfoSectionTile extends StatelessWidget {
  const _InfoSectionTile({
    required this.icon,
    required this.title,
    required this.content,
    required this.theme,
  });

  final IconData icon;
  final String title;
  final String content;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
