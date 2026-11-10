import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/app_images.dart';

import '../../core/db/daos/recipe_dao.dart';
import '../../core/db/enums.dart';
import '../../core/widgets/assistant_badge.dart';
import '../../l10n/app_localizations.dart';

IconData dishTypeIcon(DishType type) {
  switch (type) {
    case DishType.soup:
      return Icons.soup_kitchen;
    case DishType.main:
      return Icons.dinner_dining;
    case DishType.side:
      return Icons.rice_bowl;
    case DishType.salad:
      return Icons.eco;
    case DishType.dessert:
      return Icons.cake;
    case DishType.breakfast:
      return Icons.egg_alt;
    case DishType.drink:
      return Icons.local_cafe;
    case DishType.snack:
      return Icons.tapas;
    case DishType.baking:
      return Icons.bakery_dining;
    case DishType.preserve:
      return Icons.takeout_dining;
  }
}

String dishTypeName(DishType type, AppLocalizations l10n) {
  switch (type) {
    case DishType.soup:
      return l10n.dishTypeSoup;
    case DishType.main:
      return l10n.dishTypeMain;
    case DishType.side:
      return l10n.dishTypeSide;
    case DishType.salad:
      return l10n.dishTypeSalad;
    case DishType.dessert:
      return l10n.dishTypeDessert;
    case DishType.breakfast:
      return l10n.dishTypeBreakfast;
    case DishType.drink:
      return l10n.dishTypeDrink;
    case DishType.snack:
      return l10n.dishTypeSnack;
    case DishType.baking:
      return l10n.dishTypeBaking;
    case DishType.preserve:
      return l10n.dishTypePreserve;
  }
}

String difficultyName(AppLocalizations l10n, Difficulty difficulty) {
  switch (difficulty) {
    case Difficulty.easy:
      return l10n.dishesFilterEasy;
    case Difficulty.medium:
      return l10n.dishesFilterMedium;
    case Difficulty.hard:
      return l10n.dishesFilterHard;
  }
}

class RecipePickerSheet extends StatefulWidget {
  const RecipePickerSheet({
    required this.recipes,
    required this.selectedDate,
    required this.onSelected,
    this.pantry = const {},
    this.initialOnlyFavorites = false,
    this.initialOnlyAvailable = false,
    super.key,
  });

  final List<RecipeWithIngredients> recipes;
  final DateTime selectedDate;
  final ValueChanged<RecipeWithIngredients> onSelected;
  final Set<String> pantry;
  final bool initialOnlyFavorites;
  final bool initialOnlyAvailable;

  @override
  State<RecipePickerSheet> createState() => _RecipePickerSheetState();
}

class _RecipePickerSheetState extends State<RecipePickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  late bool _filterFavorites;
  late bool _filterAvailable;

  @override
  void initState() {
    super.initState();
    _filterFavorites = widget.initialOnlyFavorites;
    _filterAvailable = widget.initialOnlyAvailable;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isRecipeAvailable(RecipeWithIngredients r) {
    if (widget.pantry.isEmpty) return false;
    for (final line in r.ingredients) {
      if (line.recipeIngredient.isOptional ||
          line.ingredient?.isStaple == true) {
        continue;
      }
      final ingId = line.recipeIngredient.ingredientId;
      if (!widget.pantry.contains(ingId)) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final filtered = widget.recipes.where((r) {
      if (_filterFavorites && !r.recipe.isFavorite) return false;
      if (_filterAvailable && !_isRecipeAvailable(r)) return false;
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return r.recipe.title.toLowerCase().contains(q) ||
          r.recipe.description.toLowerCase().contains(q);
    }).toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 16,
        left: 16,
        right: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Выберите блюдо на ${DateFormat('d MMMM', 'ru').format(widget.selectedDate)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Поиск рецепта...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              isDense: true,
            ),
            onChanged: (val) => setState(() => _query = val.trim()),
          ),
          const SizedBox(height: 8),
          // Quick filter chips
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('Все'),
                selected: !_filterFavorites && !_filterAvailable,
                onSelected: (val) {
                  if (val) {
                    setState(() {
                      _filterFavorites = false;
                      _filterAvailable = false;
                    });
                  }
                },
              ),
              FilterChip(
                avatar: Icon(
                  Icons.star,
                  size: 16,
                  color: theme.colorScheme.secondary,
                ),
                label: const Text('Избранные'),
                selected: _filterFavorites,
                onSelected: (val) {
                  setState(() {
                    _filterFavorites = val;
                    if (val) _filterAvailable = false;
                  });
                },
              ),
              if (widget.pantry.isNotEmpty)
                FilterChip(
                  avatar: Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  label: const Text('Есть дома'),
                  selected: _filterAvailable,
                  onSelected: (val) {
                    setState(() {
                      _filterAvailable = val;
                      if (val) _filterFavorites = false;
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Ничего не найдено',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final recipe = item.recipe;
                      return ListTile(
                        leading: AppDishTypeIcon(
                          dishType: recipe.dishType,
                          size: 28,
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                recipe.title,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (recipe.source == RecipeSource.ai) ...[
                              const SizedBox(width: 6),
                              const AssistantBadge(isCompact: true),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          '${dishTypeName(recipe.dishType, l10n)} · ${recipe.totalMinutes} мин · ${difficultyName(l10n, recipe.difficulty)}',
                        ),
                        trailing: recipe.isFavorite
                            ? Icon(
                                Icons.star,
                                color: theme.colorScheme.secondary,
                                size: 22,
                              )
                            : null,
                        onTap: () => widget.onSelected(item),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
