import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_images.dart';
import '../../core/adaptive/adaptive_app_bar_title.dart';
import '../../core/ai/ai_failure.dart';
import '../../core/ai/ai_service.dart';
import '../../core/db/app_database.dart';
import '../../core/db/daos/recipe_dao.dart';
import '../../core/db/enums.dart';
import '../../core/providers.dart';
import '../../core/widgets/assistant_badge.dart';
import '../../l10n/app_localizations.dart';

class RecipeScreen extends ConsumerStatefulWidget {
  const RecipeScreen({
    super.key,
    required this.recipeId,
    this.initialSuggestion,
  });

  final String recipeId;
  final AiDishSuggestion? initialSuggestion;

  @override
  ConsumerState<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends ConsumerState<RecipeScreen> {
  int? _customServings;
  bool? _isFavorite;
  String? _savedRecipeId;
  bool _isGenerating = false;
  String? _generationError;

  @override
  void initState() {
    super.initState();
    if (widget.initialSuggestion != null && _savedRecipeId == null) {
      _startGeneratingFullRecipe(widget.initialSuggestion!);
    }
  }

  Future<void> _startGeneratingFullRecipe(AiDishSuggestion suggestion) async {
    setState(() {
      _isGenerating = true;
      _generationError = null;
    });

    try {
      final aiService = await ref.read(aiServiceProvider.future);
      final pantryIds = await ref.read(pantryProvider.future);
      final ingDao = ref.read(ingredientDaoProvider);
      final ings = await ingDao.byIds(pantryIds.toList());
      final availableNames = ings.map((i) => i.name).toList();

      final result = await aiService.fullRecipe(
        title: suggestion.title,
        dishType: suggestion.dishType,
        difficulty: suggestion.difficulty,
        mainIngredients: suggestion.mainIngredients,
        availableIngredients: availableNames,
      );

      switch (result) {
        case AiSuccess(data: final fullRecipeJson):
          final saved = await aiService.saveAiRecipeToDatabase(fullRecipeJson);
          if (saved != null && mounted) {
            setState(() {
              _savedRecipeId = saved.id;
              _isGenerating = false;
            });
            ref.invalidate(recipeDetailProvider(saved.id));
          }
        case AiError(failure: final failure):
          if (mounted) {
            setState(() {
              _generationError = failure.message;
              _isGenerating = false;
            });
          }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _generationError = e.toString();
          _isGenerating = false;
        });
      }
    }
  }

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

    final effectiveId = _savedRecipeId ?? widget.recipeId;
    if ((effectiveId == 'new' || effectiveId.startsWith('ai-')) &&
        _savedRecipeId == null &&
        widget.initialSuggestion != null) {
      return _buildGeneratingSuggestionView(
        theme,
        l10n,
        widget.initialSuggestion!,
      );
    }

    final detailAsync = ref.watch(recipeDetailProvider(effectiveId));
    final pantryAsync = ref.watch(pantryProvider);
    final hierarchyAsync = ref.watch(ingredientHierarchyProvider);

    return detailAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: AdaptiveAppBarTitle(l10n.recipeScreenTitle)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: AdaptiveAppBarTitle(l10n.recipeScreenTitle)),
        body: Center(
          child: Text(e.toString(), style: theme.textTheme.bodyLarge),
        ),
      ),
      data: (detail) {
        if (detail == null) {
          return Scaffold(
            appBar: AppBar(title: AdaptiveAppBarTitle(l10n.recipeScreenTitle)),
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
            title: AdaptiveAppBarTitle(l10n.recipeScreenTitle),
            actions: [
              IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? theme.colorScheme.error : null,
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
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 56),
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
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrowOrLargeFont =
                        constraints.maxWidth < 340 ||
                        MediaQuery.textScalerOf(context).scale(1) > 1.25;

                    final favButton = ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 56),
                      child: OutlinedButton.icon(
                        icon: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? theme.colorScheme.error : null,
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
                    );

                    final calendarButton = ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 56),
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_month, size: 24),
                        label: Text(
                          l10n.recipeAddToCalendar,
                          style: theme.textTheme.bodyLarge,
                        ),
                        onPressed: () => _addToCalendar(recipe, l10n),
                      ),
                    );

                    if (isNarrowOrLargeFont) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          favButton,
                          const SizedBox(height: 8),
                          calendarButton,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: favButton),
                        const SizedBox(width: 8),
                        Expanded(child: calendarButton),
                      ],
                    );
                  },
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
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppRecipePlaceholder(dishType: recipe.dishType, height: 160),
          Padding(
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
                    if (recipe.source == RecipeSource.ai)
                      const AssistantBadge(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer.withValues(
                          alpha: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppDishTypeIcon(dishType: recipe.dishType, size: 20),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _dishTypeName(l10n, recipe.dishType),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
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
                          Flexible(
                            child: Text(
                              _difficultyName(l10n, recipe.difficulty),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer_outlined, size: 20),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              l10n.dishesMinutes(recipe.totalMinutes),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (recipe.cuisine.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.public, size: 20),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                recipe.cuisine,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
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
        ],
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
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
          : theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isAvailable
              ? theme.colorScheme.primary.withValues(alpha: 0.4)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              isAvailable
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,
              color: isAvailable
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
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
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (quantityText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        quantityText,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                ],
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
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
                    Flexible(
                      child: Text(
                        l10n.recipeStepNumber(number),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (timerMinutes != null && timerMinutes > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined, size: 18),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            l10n.recipeStepTimer(timerMinutes),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
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
                  color: theme.colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: theme.colorScheme.onTertiaryContainer,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${l10n.recipeTipPrefix}$tip',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onTertiaryContainer,
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

  Widget _buildGeneratingSuggestionView(
    ThemeData theme,
    AppLocalizations l10n,
    AiDishSuggestion suggestion,
  ) {
    final dishType =
        DishType.values
            .where((e) => e.name == suggestion.dishType)
            .firstOrNull ??
        DishType.main;
    final difficulty =
        Difficulty.values
            .where((e) => e.name == suggestion.difficulty)
            .firstOrNull ??
        Difficulty.easy;

    return Scaffold(
      appBar: AppBar(title: AdaptiveAppBarTitle(l10n.recipeScreenTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 0,
              clipBehavior: Clip.antiAlias,
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppRecipePlaceholder(dishType: dishType, height: 160),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          suggestion.title,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            const AssistantBadge(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondaryContainer
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AppDishTypeIcon(dishType: dishType, size: 20),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      _dishTypeName(l10n, dishType),
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSecondaryContainer,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (int i = 0; i < 3; i++)
                                    Icon(
                                      Icons.cookie_outlined,
                                      size: 18,
                                      color: i < _difficultyCaps(difficulty)
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.outlineVariant,
                                    ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      _difficultyName(l10n, difficulty),
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.timer_outlined, size: 20),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      l10n.dishesMinutes(
                                        suggestion.totalMinutes,
                                      ),
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (suggestion.why.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            suggestion.why,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.3,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.recipeMainIngredientsHeader,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final ing in suggestion.mainIngredients)
                          Chip(
                            label: Text(ing),
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_isGenerating)
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const LinearProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        l10n.recipeGeneratingSteps,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.recipeGeneratingSubtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else if (_generationError != null)
              Card(
                elevation: 0,
                color: theme.colorScheme.errorContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        l10n.aiErrorDialogMessage(_generationError!),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      FilledButton.tonal(
                        onPressed: () => _startGeneratingFullRecipe(suggestion),
                        child: Text(l10n.recipeGenerationRetry),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
