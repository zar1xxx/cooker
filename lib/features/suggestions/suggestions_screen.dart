import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/db/enums.dart';
import '../../core/matching/recipe_scorer.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';

IconData _dishTypeIcon(DishType type) {
  switch (type) {
    case DishType.soup:
      return Icons.soup_kitchen;
    case DishType.main:
      return Icons.dinner_dining;
    case DishType.side:
      return Icons.rice_bowl;
    case DishType.salad:
      return Icons.eco;
    case DishType.breakfast:
      return Icons.egg;
    case DishType.snack:
      return Icons.lunch_dining;
    case DishType.baking:
      return Icons.bakery_dining;
    case DishType.dessert:
      return Icons.cake;
    case DishType.drink:
      return Icons.local_drink;
    case DishType.preserve:
      return Icons.inventory_2;
  }
}

String _dishTypeName(AppLocalizations l10n, DishType type) {
  switch (type) {
    case DishType.soup:
      return l10n.dishTypeSoup;
    case DishType.main:
      return l10n.dishTypeMain;
    case DishType.side:
      return l10n.dishTypeSide;
    case DishType.salad:
      return l10n.dishTypeSalad;
    case DishType.breakfast:
      return l10n.dishTypeBreakfast;
    case DishType.snack:
      return l10n.dishTypeSnack;
    case DishType.baking:
      return l10n.dishTypeBaking;
    case DishType.dessert:
      return l10n.dishTypeDessert;
    case DishType.drink:
      return l10n.dishTypeDrink;
    case DishType.preserve:
      return l10n.dishTypePreserve;
  }
}

String _difficultyName(AppLocalizations l10n, Difficulty diff) {
  switch (diff) {
    case Difficulty.easy:
      return l10n.dishesFilterEasy;
    case Difficulty.medium:
      return l10n.dishesFilterMedium;
    case Difficulty.hard:
      return l10n.dishesFilterHard;
  }
}

int _difficultyCaps(Difficulty diff) {
  switch (diff) {
    case Difficulty.easy:
      return 1;
    case Difficulty.medium:
      return 2;
    case Difficulty.hard:
      return 3;
  }
}

class SuggestionsScreen extends ConsumerStatefulWidget {
  const SuggestionsScreen({super.key});

  @override
  ConsumerState<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends ConsumerState<SuggestionsScreen> {
  DishType? _selectedDishType;
  Difficulty? _selectedDifficulty;
  final Set<String> _rejectedRecipeIds = <String>{};

  void _rejectRecipe(Recipe recipe) {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _rejectedRecipeIds.add(recipe.id);
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.dishesRejectedSnackbar,
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(color: Theme.of(context).colorScheme.onInverseSurface),
        ),
        action: SnackBarAction(
          label: l10n.dishesUndoReject,
          onPressed: () {
            setState(() {
              _rejectedRecipeIds.remove(recipe.id);
            });
          },
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _openRecipe(Recipe recipe) {
    // In Stage 1, recipe screen is not yet built (comes in Stage 2 / S2-01).
    // Show a clean snackbar confirming recipe selection.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          recipe.title,
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(color: Theme.of(context).colorScheme.onInverseSurface),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final suggestionsAsync = ref.watch(suggestionsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.dishesScreenTitle)),
      body: Column(
        children: [
          // Filter Chips (DishType & Difficulty)
          _buildFilterBar(theme, l10n),
          const Divider(height: 1),

          // Main content: Two groups or empty state
          Expanded(
            child: suggestionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(e.toString(), style: theme.textTheme.bodyLarge),
              ),
              data: (data) {
                final filteredReady = data.ready.where((s) {
                  if (_rejectedRecipeIds.contains(s.entry.recipe.id)) {
                    return false;
                  }
                  if (_selectedDishType != null &&
                      s.entry.recipe.dishType != _selectedDishType) {
                    return false;
                  }
                  if (_selectedDifficulty != null &&
                      s.entry.recipe.difficulty != _selectedDifficulty) {
                    return false;
                  }
                  return true;
                }).toList();

                final filteredAlmostReady = data.almostReady.where((s) {
                  if (_rejectedRecipeIds.contains(s.entry.recipe.id)) {
                    return false;
                  }
                  if (_selectedDishType != null &&
                      s.entry.recipe.dishType != _selectedDishType) {
                    return false;
                  }
                  if (_selectedDifficulty != null &&
                      s.entry.recipe.difficulty != _selectedDifficulty) {
                    return false;
                  }
                  return true;
                }).toList();

                if (filteredReady.isEmpty && filteredAlmostReady.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.restaurant_outlined,
                            size: 64,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.dishesEmpty,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  children: [
                    // Group 1: «Можно приготовить сейчас»
                    if (filteredReady.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          l10n.dishesCanCookNow,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      for (final scored in filteredReady)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _RecipeCard(
                            scored: scored,
                            onOpen: () => _openRecipe(scored.entry.recipe),
                            onReject: () => _rejectRecipe(scored.entry.recipe),
                          ),
                        ),
                    ],

                    // Group 2: «Не хватает 1–2 продуктов»
                    if (filteredAlmostReady.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          l10n.dishesMissingFew,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      for (final scored in filteredAlmostReady)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _RecipeCard(
                            scored: scored,
                            onOpen: () => _openRecipe(scored.entry.recipe),
                            onReject: () => _rejectRecipe(scored.entry.recipe),
                          ),
                        ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(ThemeData theme, AppLocalizations l10n) {
    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // Dish types row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                FilterChip(
                  selected: _selectedDishType == null,
                  onSelected: (_) {
                    setState(() => _selectedDishType = null);
                  },
                  label: Text(
                    l10n.dishesFilterAllTypes,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: _selectedDishType == null
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                for (final type in DishType.values) ...[
                  FilterChip(
                    selected: _selectedDishType == type,
                    onSelected: (selected) {
                      setState(() {
                        _selectedDishType = selected ? type : null;
                      });
                    },
                    avatar: Icon(_dishTypeIcon(type), size: 20),
                    label: Text(
                      _dishTypeName(l10n, type),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: _selectedDishType == type
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Difficulty row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                FilterChip(
                  selected: _selectedDifficulty == null,
                  onSelected: (_) {
                    setState(() => _selectedDifficulty = null);
                  },
                  label: Text(
                    l10n.dishesFilterAllDifficulties,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: _selectedDifficulty == null
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                for (final diff in Difficulty.values) ...[
                  FilterChip(
                    selected: _selectedDifficulty == diff,
                    onSelected: (selected) {
                      setState(() {
                        _selectedDifficulty = selected ? diff : null;
                      });
                    },
                    label: Text(
                      _difficultyName(l10n, diff),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: _selectedDifficulty == diff
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({
    required this.scored,
    required this.onOpen,
    required this.onReject,
  });

  final ScoredRecipe scored;
  final VoidCallback onOpen;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final recipe = scored.entry.recipe;
    final match = scored.match;
    final capsCount = _difficultyCaps(recipe.difficulty);
    final isNewAi = recipe.source == RecipeSource.ai;

    return Semantics(
      button: true,
      label: '${recipe.title}, ${_dishTypeName(l10n, recipe.dishType)}',
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        recipe.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isNewAi) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          l10n.dishesBadgeNew,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onTertiaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // Attributes row: Dish type, Difficulty (1-3 caps), Total time
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Dish type
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _dishTypeIcon(recipe.dishType),
                          size: 22,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _dishTypeName(l10n, recipe.dishType),
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),

                    // Difficulty (1-3 caps with text)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (int i = 0; i < 3; i++)
                          Icon(
                            Icons.soup_kitchen,
                            size: 18,
                            color: i < capsCount
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outlineVariant,
                          ),
                        const SizedBox(width: 4),
                        Text(
                          _difficultyName(l10n, recipe.difficulty),
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),

                    // Total time
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.dishesMinutes(recipe.totalMinutes),
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ],
                ),

                // Missing ingredients (for «Не хватает 1–2 продуктов»)
                if (match.missingCount > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 20,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.dishesMissing(match.missingNames.join(', ')),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Actions: «Не хочу» + «Открыть рецепт»
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: onReject,
                          icon: const Icon(Icons.close, size: 24),
                          label: Text(
                            l10n.dishesActionReject,
                            style: theme.textTheme.bodyLarge,
                          ),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 56,
                        child: FilledButton.icon(
                          onPressed: onOpen,
                          icon: const Icon(Icons.menu_book, size: 24),
                          label: Text(
                            l10n.dishesActionOpen,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
