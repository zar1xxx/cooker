import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_images.dart';
import '../../core/ai/ai_failure.dart';
import '../../core/ai/ai_router.dart';
import '../../core/ai/ai_service.dart';
import '../../core/ai/anti_repeat.dart';
import '../../core/db/app_database.dart';
import '../../core/db/enums.dart';
import '../../core/matching/recipe_scorer.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';

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
  final Set<String> _rejectedAiTitles = <String>{};

  void _rejectRecipe(Recipe recipe) {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _rejectedRecipeIds.add(recipe.id);
    });

    ref
        .read(preferenceServiceProvider)
        .recordEvent(
          recipeId: recipe.id,
          kind: FeedbackKind.rejected_suggestion,
          reason: 'rejected_suggestion',
        );

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

  void _rejectAiSuggestion(AiDishSuggestion suggestion) {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _rejectedAiTitles.add(suggestion.title.toLowerCase().trim());
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
              _rejectedAiTitles.remove(suggestion.title.toLowerCase().trim());
            });
          },
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _openRecipe(Recipe recipe) {
    context.push('/recipe/${recipe.id}');
  }

  Future<void> _openAiSuggestion(AiDishSuggestion suggestion) async {
    final l10n = AppLocalizations.of(context)!;
    final db = ref.read(databaseProvider);

    // Check if duplicate already exists in DB
    final existing = await AntiRepeat.findDuplicate(
      db,
      title: suggestion.title,
      dishType: suggestion.dishType,
      ingredientIds: suggestion.mainIngredients,
    );
    if (existing != null) {
      if (!mounted) return;
      unawaited(context.push('/recipe/${existing.id}'));
      return;
    }

    // Generate full recipe
    if (!mounted) return;
    unawaited(
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      ),
    );

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

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // dismiss dialog

      switch (result) {
        case AiSuccess(data: final fullRecipeJson):
          final saved = await aiService.saveAiRecipeToDatabase(fullRecipeJson);
          if (saved != null && mounted) {
            unawaited(context.push('/recipe/${saved.id}'));
            return;
          }
        case AiError(failure: final failure):
          if (!mounted) return;
          final dialogTheme = Theme.of(context);
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.aiErrorDialogTitle),
              content: Text(
                l10n.aiErrorDialogMessage(failure.message),
                style: dialogTheme.textTheme.bodyMedium,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(l10n.aiErrorDialogClose),
                ),
              ],
            ),
          );
          return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.dishesEmpty)));
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при загрузке рецепта: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final suggestionsAsync = ref.watch(suggestionsProvider);
    final aiDishesAsync = ref.watch(aiDishesProvider);
    final aiModeAsync = ref.watch(aiModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPress: () => context.push('/settings/ai'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.dishesScreenTitle),
              aiModeAsync.when(
                data: (mode) => InkWell(
                  onTap: () => context.push('/settings/ai'),
                  child: Text(
                    switch (mode) {
                      AiMode.localPc => l10n.aiAssistantPc,
                      AiMode.gigaChat => l10n.aiAssistantGigaChat,
                      AiMode.offline => l10n.aiAssistantOffline,
                    },
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            key: const Key('btn_ai_settings_appbar'),
            icon: const Icon(Icons.settings, size: 28),
            tooltip: l10n.aiSettingsTooltip,
            onPressed: () => context.push('/settings/ai'),
          ),
        ],
      ),
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
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppStateIllustration(
                        assetPath: AppImages.stateErrorGeneric,
                        height: 140,
                      ),
                      const SizedBox(height: 16),
                      Text(e.toString(), style: theme.textTheme.bodyLarge),
                    ],
                  ),
                ),
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

                final aiDishes =
                    aiDishesAsync.value?.dataOrNull ??
                    const <AiDishSuggestion>[];
                final filteredAiDishes = aiDishes.where((d) {
                  if (_rejectedAiTitles.contains(
                    d.title.toLowerCase().trim(),
                  )) {
                    return false;
                  }
                  if (_selectedDishType != null &&
                      d.dishType.toLowerCase().trim() !=
                          _selectedDishType!.name) {
                    return false;
                  }
                  if (_selectedDifficulty != null &&
                      d.difficulty.toLowerCase().trim() !=
                          _selectedDifficulty!.name) {
                    return false;
                  }
                  return true;
                }).toList();

                if (filteredReady.isEmpty &&
                    filteredAlmostReady.isEmpty &&
                    filteredAiDishes.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AppStateIllustration(
                            assetPath: AppImages.stateNoDishes,
                            height: 160,
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
                    // AI Failure Banner (R4-03: placed at top above recipe groups)
                    if (aiDishesAsync.value?.failureOrNull != null) ...[
                      Builder(
                        builder: (context) {
                          final failure = aiDishesAsync.value!.failureOrNull!;
                          final isNotConfigured =
                              failure is AiFailureNotConfigured;
                          return Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 12),
                            child: Card(
                              key: Key(
                                isNotConfigured
                                    ? 'ai_not_configured_banner'
                                    : 'ai_error_banner',
                              ),
                              color: theme.colorScheme.surfaceContainerHighest,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: theme.colorScheme.outlineVariant,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          isNotConfigured
                                              ? Icons.tune
                                              : Icons.info_outline,
                                          color: theme.colorScheme.primary,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                isNotConfigured
                                                    ? l10n.aiNotConfiguredTitle
                                                    : l10n.aiNotRespondingTitle,
                                                style: theme
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                isNotConfigured
                                                    ? l10n.aiNotConfiguredSubtitle
                                                    : failure.message,
                                                style: theme
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color: theme
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    if (isNotConfigured)
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          ElevatedButton.icon(
                                            key: const Key('btn_connect_qr_ai'),
                                            style: ElevatedButton.styleFrom(
                                              minimumSize: const Size(140, 48),
                                            ),
                                            icon: const Icon(
                                              Icons.qr_code_scanner,
                                              size: 20,
                                            ),
                                            label: Text(
                                              l10n.aiSettingsConnectQr,
                                              style:
                                                  theme.textTheme.titleMedium,
                                            ),
                                            onPressed: () => context.push(
                                              '/settings/ai/qr-scanner',
                                            ),
                                          ),
                                          FilledButton.tonal(
                                            key: const Key('btn_configure_ai'),
                                            style: FilledButton.styleFrom(
                                              minimumSize: const Size(110, 48),
                                            ),
                                            onPressed: () =>
                                                context.push('/settings/ai'),
                                            child: Text(
                                              l10n.aiConfigureButton,
                                              style:
                                                  theme.textTheme.titleMedium,
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              key: const Key('btn_retry_ai'),
                                              style: OutlinedButton.styleFrom(
                                                minimumSize:
                                                    const Size.fromHeight(48),
                                              ),
                                              icon: const Icon(
                                                Icons.refresh,
                                                size: 20,
                                              ),
                                              label: Text(
                                                l10n.aiRetryButton,
                                                style:
                                                    theme.textTheme.titleMedium,
                                              ),
                                              onPressed: () {
                                                ref.invalidate(
                                                  aiDishesProvider,
                                                );
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton.filledTonal(
                                            key: const Key(
                                              'btn_ai_banner_settings',
                                            ),
                                            style: IconButton.styleFrom(
                                              minimumSize: const Size(48, 48),
                                            ),
                                            icon: const Icon(Icons.settings),
                                            tooltip: l10n.aiSettingsTooltip,
                                            onPressed: () =>
                                                context.push('/settings/ai'),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],

                    // AI Suggestions Group (if available)
                    if (filteredAiDishes.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.dishesFromAssistant,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      for (final suggestion in filteredAiDishes)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _AiDishCard(
                            suggestion: suggestion,
                            onOpen: () => _openAiSuggestion(suggestion),
                            onReject: () => _rejectAiSuggestion(suggestion),
                          ),
                        ),
                    ],

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

                    // «Другие варианты» Button (ТЗ 6.3)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: OutlinedButton.icon(
                        key: const Key('btn_other_variants'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                        ),
                        onPressed: () {
                          final allShown = [
                            ...filteredReady.map((r) => r.entry.recipe.title),
                            ...filteredAlmostReady.map(
                              (r) => r.entry.recipe.title,
                            ),
                            ...filteredAiDishes.map((d) => d.title),
                          ];
                          unawaited(
                            ref
                                .read(aiDishesProvider.notifier)
                                .fetchOtherVariants(alreadyShown: allShown),
                          );
                        },
                        icon: const Icon(Icons.refresh, size: 28),
                        label: Text(
                          l10n.dishesOtherVariants,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ),
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
                    avatar: AppDishTypeIcon(dishType: type, size: 20),
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
                        AppDishTypeIcon(dishType: recipe.dishType, size: 24),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _dishTypeName(l10n, recipe.dishType),
                            style: theme.textTheme.bodyLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    // Difficulty (Chef hat icon repeated 1..3 times)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (int i = 0; i < capsCount; i++)
                          Padding(
                            padding: const EdgeInsets.only(right: 2),
                            child: Icon(
                              Icons.skateboarding,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _difficultyName(l10n, recipe.difficulty),
                            style: theme.textTheme.bodyLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
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
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            l10n.dishesMinutes(recipe.totalMinutes),
                            style: theme.textTheme.bodyLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
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
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 20,
                          color: theme.colorScheme.onErrorContainer,
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
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrowOrLargeFont =
                        constraints.maxWidth < 360 ||
                        MediaQuery.textScalerOf(context).scale(1) > 1.25;

                    final rejectBtn = ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 56),
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
                    );

                    final openBtn = ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 56),
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
                    );

                    if (isNarrowOrLargeFont) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          openBtn,
                          const SizedBox(height: 8),
                          rejectBtn,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(flex: 2, child: rejectBtn),
                        const SizedBox(width: 12),
                        Expanded(flex: 3, child: openBtn),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AiDishCard extends StatelessWidget {
  const _AiDishCard({
    required this.suggestion,
    required this.onOpen,
    required this.onReject,
  });

  final AiDishSuggestion suggestion;
  final VoidCallback onOpen;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final dishTypeEnum =
        DishType.values
            .where((e) => e.name == suggestion.dishType)
            .firstOrNull ??
        DishType.main;
    final diffEnum =
        Difficulty.values
            .where((e) => e.name == suggestion.difficulty)
            .firstOrNull ??
        Difficulty.easy;

    return Semantics(
      button: true,
      label: '${suggestion.title}, ${_dishTypeName(l10n, dishTypeEnum)}',
      child: Card(
        elevation: 2,
        color: theme.colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title & Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        suggestion.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 14,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.dishesBadgeNew,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Why phrase
                if (suggestion.why.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '«${suggestion.why}»',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),

                // Attributes
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppDishTypeIcon(dishType: dishTypeEnum, size: 24),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _dishTypeName(l10n, dishTypeEnum),
                            style: theme.textTheme.bodyLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _difficultyName(l10n, diffEnum),
                      style: theme.textTheme.bodyLarge,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            l10n.dishesMinutes(suggestion.totalMinutes),
                            style: theme.textTheme.bodyLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                if (suggestion.missing.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.dishesMissing(suggestion.missing.join(', ')),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Action buttons
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrowOrLargeFont =
                        constraints.maxWidth < 360 ||
                        MediaQuery.textScalerOf(context).scale(1) > 1.25;

                    final rejectBtn = ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 56),
                      child: OutlinedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.close, size: 24),
                        label: Text(
                          l10n.dishesActionReject,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                    );

                    final openBtn = ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 56),
                      child: FilledButton.icon(
                        onPressed: onOpen,
                        icon: const Icon(Icons.auto_awesome, size: 24),
                        label: Text(
                          l10n.dishesActionOpen,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );

                    if (isNarrowOrLargeFont) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          openBtn,
                          const SizedBox(height: 8),
                          rejectBtn,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(flex: 2, child: rejectBtn),
                        const SizedBox(width: 12),
                        Expanded(flex: 3, child: openBtn),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
