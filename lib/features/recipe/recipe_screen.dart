import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/app_database.dart';
import '../../core/db/daos/recipe_dao.dart';
import '../../core/db/enums.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';

class RecipeScreen extends ConsumerStatefulWidget {
  const RecipeScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  ConsumerState<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends ConsumerState<RecipeScreen> {
  static const Color _favoriteRed = Color(0xFFC0392B);
  static const Color _availableGreen = Color(0xFF2E7D32);
  static const Color _tipYellow = Color(0xFFF9A825);
  static const Color _tipIconOrange = Color(0xFFD84315);

  int? _customServings;
  bool? _isFavorite;

  void _onServingsChanged(int delta, int baseServings) {
    final current = _customServings ?? baseServings;
    final next = (current + delta).clamp(1, 20);
    setState(() {
      _customServings = next;
    });
  }

  Future<void> _toggleFavorite(Recipe recipe, AppLocalizations l10n) async {
    final current = _isFavorite ?? recipe.isFavorite;
    final next = !current;
    setState(() {
      _isFavorite = next;
    });

    await ref.read(recipeDaoProvider).setFavorite(recipe.id, next);
    ref.invalidate(recipeDetailProvider(recipe.id));
    ref.invalidate(suggestionsProvider);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          next ? l10n.recipeFavoriteAdded : l10n.recipeFavoriteRemoved,
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(color: Theme.of(context).colorScheme.onInverseSurface),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _addToCalendar(Recipe recipe, AppLocalizations l10n) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.recipeAddedToCalendar,
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(color: Theme.of(context).colorScheme.onInverseSurface),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _startCooking(Recipe recipe) {
    context.push('/cooking/${recipe.id}');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final detailAsync = ref.watch(recipeDetailProvider(widget.recipeId));
    final pantryAsync = ref.watch(pantryProvider);
    final hierarchyAsync = ref.watch(ingredientHierarchyProvider);

    return detailAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.recipeScreenTitle)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.recipeScreenTitle)),
        body: Center(
          child: Text(e.toString(), style: theme.textTheme.bodyLarge),
        ),
      ),
      data: (detail) {
        if (detail == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.recipeScreenTitle)),
            body: Center(
              child: Text(
                l10n.recipeNotFound,
                style: theme.textTheme.titleLarge,
              ),
            ),
          );
        }

        final recipe = detail.recipe;
        final isFav = _isFavorite ?? recipe.isFavorite;
        final currentServings = _customServings ?? recipe.servings;
        final pantryIds = pantryAsync.value ?? const <String>{};
        final hierarchy =
            hierarchyAsync.value ?? const <String, List<String>>{};

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.recipeScreenTitle),
            actions: [
              IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? _favoriteRed : null,
                  size: 28,
                ),
                tooltip: isFav ? l10n.recipeFavoriteIn : l10n.recipeFavoriteAdd,
                onPressed: () => _toggleFavorite(recipe, l10n),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header: Title & Meta chips
                _buildHeaderCard(theme, l10n, recipe),
                const SizedBox(height: 16),

                // Servings adjuster
                _buildServingsCard(
                  theme: theme,
                  l10n: l10n,
                  currentServings: currentServings,
                  baseServings: recipe.servings,
                ),
                const SizedBox(height: 20),

                // Ingredients list with pantry checkmark
                _buildIngredientsSection(
                  theme: theme,
                  l10n: l10n,
                  ingredients: detail.ingredients,
                  currentServings: currentServings,
                  baseServings: recipe.servings,
                  pantryIds: pantryIds,
                  hierarchy: hierarchy,
                ),
                const SizedBox(height: 24),

                // Steps list
                _buildStepsSection(
                  theme: theme,
                  l10n: l10n,
                  steps: detail.steps,
                ),
                const SizedBox(height: 24),

                // Main action: «Начать готовить»
                SizedBox(
                  height: 60,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 32),
                    label: Text(
                      l10n.recipeStartCooking,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () => _startCooking(recipe),
                  ),
                ),
                const SizedBox(height: 12),

                // Secondary actions: Favorite & Calendar
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: OutlinedButton.icon(
                          icon: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? _favoriteRed : null,
                            size: 24,
                          ),
                          label: Text(
                            isFav
                                ? l10n.recipeFavoriteIn
                                : l10n.recipeFavoriteAdd,
                            style: theme.textTheme.bodyLarge,
                          ),
                          onPressed: () => _toggleFavorite(recipe, l10n),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_month, size: 24),
                          label: Text(
                            l10n.recipeAddToCalendar,
                            style: theme.textTheme.bodyLarge,
                          ),
                          onPressed: () => _addToCalendar(recipe, l10n),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderCard(
    ThemeData theme,
    AppLocalizations l10n,
    Recipe recipe,
  ) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              recipe.title,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: Icon(_dishTypeIcon(recipe.dishType), size: 20),
                  label: Text(_dishTypeName(l10n, recipe.dishType)),
                ),
                Chip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < 3; i++)
                        Icon(
                          Icons.cookie_outlined,
                          size: 18,
                          color: i < _difficultyCaps(recipe.difficulty)
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                        ),
                      const SizedBox(width: 4),
                      Text(_difficultyName(l10n, recipe.difficulty)),
                    ],
                  ),
                ),
                Chip(
                  avatar: const Icon(Icons.timer_outlined, size: 20),
                  label: Text(l10n.dishesMinutes(recipe.totalMinutes)),
                ),
                if (recipe.cuisine.isNotEmpty)
                  Chip(
                    avatar: const Icon(Icons.public, size: 20),
                    label: Text(recipe.cuisine),
                  ),
              ],
            ),
            if (recipe.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                recipe.description,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildServingsCard({
    required ThemeData theme,
    required AppLocalizations l10n,
    required int currentServings,
    required int baseServings,
  }) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.recipeServingsLabel(currentServings),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (currentServings != baseServings)
                    Text(
                      'Базовый рецепт: $baseServings',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            // Decrease button
            Semantics(
              label: l10n.recipeServingsDecrease,
              button: true,
              child: SizedBox(
                width: 56,
                height: 56,
                child: IconButton.filledTonal(
                  icon: const Icon(Icons.remove, size: 28),
                  onPressed: currentServings > 1
                      ? () => _onServingsChanged(-1, baseServings)
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Increase button
            Semantics(
              label: l10n.recipeServingsIncrease,
              button: true,
              child: SizedBox(
                width: 56,
                height: 56,
                child: IconButton.filledTonal(
                  icon: const Icon(Icons.add, size: 28),
                  onPressed: currentServings < 20
                      ? () => _onServingsChanged(1, baseServings)
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientsSection({
    required ThemeData theme,
    required AppLocalizations l10n,
    required List<RecipeIngredientLine> ingredients,
    required int currentServings,
    required int baseServings,
    required Set<String> pantryIds,
    required Map<String, List<String>> hierarchy,
  }) {
    final scaleFactor = currentServings / baseServings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.recipeIngredientsHeader,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.recipeIngredientsSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        for (final line in ingredients) ...[
          _buildIngredientRow(
            theme: theme,
            l10n: l10n,
            line: line,
            scaleFactor: scaleFactor,
            isAvailable: _isIngredientAvailable(
              line.recipeIngredient.ingredientId,
              pantryIds,
              hierarchy,
            ),
          ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }

  bool _isIngredientAvailable(
    String ingredientId,
    Set<String> pantryIds,
    Map<String, List<String>> hierarchy,
  ) {
    if (pantryIds.contains(ingredientId)) return true;
    for (final pantryId in pantryIds) {
      final ancestors = hierarchy[pantryId];
      if (ancestors != null && ancestors.contains(ingredientId)) {
        return true;
      }
    }
    return false;
  }

  Widget _buildIngredientRow({
    required ThemeData theme,
    required AppLocalizations l10n,
    required RecipeIngredientLine line,
    required double scaleFactor,
    required bool isAvailable,
  }) {
    final rawName = line.ingredient?.name ?? line.recipeIngredient.ingredientId;
    final name = rawName.isNotEmpty
        ? rawName[0].toUpperCase() + rawName.substring(1)
        : rawName;
    final isOptional = line.recipeIngredient.isOptional;
    final amount = line.recipeIngredient.amount;
    final unit = line.recipeIngredient.unit;

    final String quantityText;
    if (amount != null) {
      final scaledAmount = amount * scaleFactor;
      quantityText =
          '${_formatAmount(scaledAmount)} ${_formatUnit(l10n, unit)}';
    } else {
      quantityText = _formatUnit(l10n, unit);
    }

    final statusText = isAvailable
        ? l10n.recipeIngredientInPantry
        : l10n.recipeIngredientMissing;

    return Card(
      elevation: 0,
      color: isAvailable
          ? _availableGreen.withValues(alpha: 0.1)
          : theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isAvailable
              ? _availableGreen.withValues(alpha: 0.4)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(
              isAvailable
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,
              color: isAvailable ? _availableGreen : theme.colorScheme.outline,
              size: 26,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name + (isOptional ? ' ${l10n.recipeOptional}' : ''),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    statusText,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isAvailable
                          ? _availableGreen
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              quantityText,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsSection({
    required ThemeData theme,
    required AppLocalizations l10n,
    required List<RecipeStep> steps,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.recipeStepsHeader,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        for (int i = 0; i < steps.length; i++) ...[
          _buildStepCard(
            theme: theme,
            l10n: l10n,
            step: steps[i],
            number: i + 1,
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildStepCard({
    required ThemeData theme,
    required AppLocalizations l10n,
    required RecipeStep step,
    required int number,
  }) {
    final timerSeconds = step.timerSeconds;
    final timerMinutes = timerSeconds != null
        ? (timerSeconds / 60).round()
        : null;
    final tip = step.tip;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    '$number',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.recipeStepNumber(number),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (timerMinutes != null && timerMinutes > 0)
                  Chip(
                    avatar: const Icon(Icons.timer_outlined, size: 18),
                    label: Text(l10n.recipeStepTimer(timerMinutes)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              step.textContent,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
            ),
            if (tip != null && tip.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _tipYellow.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _tipYellow.withValues(alpha: 0.5)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      color: _tipIconOrange,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${l10n.recipeTipPrefix}$tip',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toInt().toString();
    }
    final formatted = amount.toStringAsFixed(1);
    return formatted.endsWith('.0')
        ? formatted.substring(0, formatted.length - 2)
        : formatted;
  }

  String _formatUnit(AppLocalizations l10n, String? unit) {
    switch (unit) {
      case 'g':
        return l10n.recipeUnitGram;
      case 'kg':
        return l10n.recipeUnitKilogram;
      case 'ml':
        return l10n.recipeUnitMilliliter;
      case 'l':
        return l10n.recipeUnitLiter;
      case 'pcs':
        return l10n.recipeUnitPieces;
      case 'tbsp':
        return l10n.recipeUnitTbsp;
      case 'tsp':
        return l10n.recipeUnitTsp;
      case 'to_taste':
        return l10n.recipeUnitToTaste;
      case 'pinch':
        return l10n.recipeUnitPinch;
      case 'clove':
        return l10n.recipeUnitClove;
      default:
        return unit ?? '';
    }
  }

  IconData _dishTypeIcon(DishType type) {
    switch (type) {
      case DishType.soup:
        return Icons.soup_kitchen;
      case DishType.main:
        return Icons.restaurant;
      case DishType.side:
        return Icons.rice_bowl;
      case DishType.salad:
        return Icons.eco;
      case DishType.breakfast:
        return Icons.free_breakfast;
      case DishType.snack:
        return Icons.tapas;
      case DishType.baking:
        return Icons.bakery_dining;
      case DishType.dessert:
        return Icons.cake;
      case DishType.drink:
        return Icons.local_cafe;
      case DishType.preserve:
        return Icons.kitchen;
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

  int _difficultyCaps(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return 1;
      case Difficulty.medium:
        return 2;
      case Difficulty.hard:
        return 3;
    }
  }

  String _difficultyName(AppLocalizations l10n, Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return l10n.dishesFilterEasy;
      case Difficulty.medium:
        return l10n.dishesFilterMedium;
      case Difficulty.hard:
        return l10n.dishesFilterHard;
    }
  }
}
