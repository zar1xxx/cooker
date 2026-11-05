import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/db/app_database.dart';
import '../../core/db/daos/plan_dao.dart';
import '../../core/db/daos/recipe_dao.dart';
import '../../core/db/enums.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import 'recipe_picker_sheet.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-skip past planned entries on screen launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(planDaoProvider).autoSkipPastPlannedEntries();
    });
  }

  Future<void> _showRecipePicker(
    BuildContext context, {
    bool onlyFavorites = false,
    bool onlyAvailable = false,
  }) async {
    final allRecipes = await ref.read(recipeDaoProvider).allWithIngredients();
    final pantry = await ref
        .read(pantryProvider.future)
        .catchError((_) => <String>{});
    final today = clock.now();
    final todayKey = PlanDao.formatDate(today);
    final existingEntry =
        (await ref.read(planDaoProvider).getEntryForDate(todayKey))?.entry;

    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return RecipePickerSheet(
          recipes: allRecipes,
          selectedDate: today,
          pantry: pantry,
          initialOnlyFavorites: onlyFavorites,
          initialOnlyAvailable: onlyAvailable,
          onSelected: (recipeWithIng) async {
            final isLocked = existingEntry?.locked ?? false;
            await ref
                .read(planDaoProvider)
                .upsertEntry(
                  date: todayKey,
                  recipeId: recipeWithIng.recipe.id,
                  status: MealPlanStatus.planned,
                  locked: isLocked,
                );
            ref.invalidate(todayPlanEntryProvider);
            ref.invalidate(calendarPlanEntriesProvider);

            // Update daily notification if enabled
            try {
              final notifService = ref.read(dailyNotificationServiceProvider);
              final config = await notifService.getConfig();
              if (config.enabled) {
                await notifService.scheduleDaily(
                  config: config,
                  todayDishTitle: recipeWithIng.recipe.title,
                  recipeId: recipeWithIng.recipe.id,
                );
              }
            } catch (_) {}

            if (sheetContext.mounted) {
              Navigator.of(sheetContext).pop();
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final today = clock.now();
    final todayEntryAsync = ref.watch(todayPlanEntryProvider);
    final pantryAsync = ref.watch(pantryProvider);
    final pantry = pantryAsync.value ?? const <String>{};

    final dateFormatted = DateFormat('EEEE, d MMMM', 'ru').format(today);
    final capitalizedDate = dateFormatted.isNotEmpty
        ? '${dateFormatted[0].toUpperCase()}${dateFormatted.substring(1)}'
        : dateFormatted;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPress: () => context.push('/settings/ai'),
          child: Text(l10n.screenTodayTitle),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: l10n.tabCalendar,
            onPressed: () => context.go('/calendar'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todayPlanEntryProvider);
          ref.invalidate(calendarPlanEntriesProvider);
          await ref.read(planDaoProvider).autoSkipPastPlannedEntries();
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Date Card Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 22,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      capitalizedDate,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            todayEntryAsync.when(
              data: (entryWithRecipe) {
                if (entryWithRecipe != null && entryWithRecipe.recipe != null) {
                  return _buildDishOfTheDayCard(
                    context,
                    entryWithRecipe.entry,
                    entryWithRecipe.recipe!,
                    pantry,
                  );
                } else {
                  return _buildEmptyState(context);
                }
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, _) => _buildEmptyState(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDishOfTheDayCard(
    BuildContext context,
    MealPlanEntry entry,
    Recipe recipe,
    Set<String> pantry,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return FutureBuilder<RecipeDetail?>(
      future: ref.read(recipeDaoProvider).getRecipeDetail(recipe.id),
      builder: (context, snapshot) {
        final detail = snapshot.data;
        final missing = detail == null
            ? <String>[]
            : detail.ingredients
                  .where(
                    (i) =>
                        !i.recipeIngredient.isOptional &&
                        i.ingredient != null &&
                        !pantry.contains(i.ingredient!.id),
                  )
                  .map((i) => i.ingredient!.name)
                  .toList();

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Section Header Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        l10n.todayDishOfTheDay,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildStatusChip(entry.status, l10n),
                  ],
                ),

                const SizedBox(height: 12),

                // Dish Icon + Title
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        dishTypeIcon(recipe.dishType),
                        size: 32,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recipe.title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${dishTypeName(recipe.dishType, l10n)} · ${recipe.totalMinutes} мин · ${difficultyName(l10n, recipe.difficulty)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Pantry status indicator
                if (pantry.isNotEmpty && snapshot.hasData) ...[
                  if (missing.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.calendarAllIngredientsAvailable,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.green.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.shopping_basket_outlined,
                                color: Colors.orange,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l10n.calendarMissingIngredients(
                                    missing.take(3).join(', ') +
                                        (missing.length > 3
                                            ? ' и ещё ${missing.length - 3}'
                                            : ''),
                                  ),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.orange.shade900,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          OutlinedButton(
                            onPressed: () =>
                                _showRecipePicker(context, onlyAvailable: true),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 44),
                            ),
                            child: Text(
                              l10n.calendarReplaceWithAvailable,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                ],

                // Action 1: "Готовить" (56 dp)
                FilledButton.icon(
                  onPressed: () => context.push('/cooking/${recipe.id}'),
                  icon: const Icon(Icons.restaurant_menu, size: 24),
                  label: Text(
                    l10n.todayStartCooking,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Action 2: "Другое блюдо" and "Посмотреть рецепт"
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showRecipePicker(context),
                        icon: const Icon(Icons.swap_horiz, size: 20),
                        label: Text(l10n.todayAnotherDish),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/recipe/${recipe.id}'),
                        icon: const Icon(Icons.menu_book, size: 20),
                        label: Text(l10n.todayViewRecipe),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                // Action 3: "Подобрать из того, что есть" (56 dp)
                OutlinedButton.icon(
                  onPressed: () => context.go('/pantry'),
                  icon: const Icon(Icons.kitchen, size: 22),
                  label: Text(
                    l10n.todayPickFromPantry,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Column(
          children: [
            Icon(
              Icons.soup_kitchen_outlined,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.todayNoDishPlanned,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.todayNoDishPlannedSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Primary: "Подобрать из того, что есть" (56 dp)
            FilledButton.icon(
              onPressed: () => context.go('/pantry'),
              icon: const Icon(Icons.kitchen, size: 22),
              label: Text(
                l10n.todayPickFromPantry,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Secondary: "Выбрать блюдо" (56 dp)
            OutlinedButton.icon(
              onPressed: () => _showRecipePicker(context),
              icon: const Icon(Icons.menu_book, size: 22),
              label: Text(
                l10n.todayChooseDish,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Action 3: "Открыть календарь" (56 dp)
            OutlinedButton.icon(
              onPressed: () => context.go('/calendar'),
              icon: const Icon(Icons.calendar_month, size: 22),
              label: Text(
                l10n.todayOpenCalendar,
                style: theme.textTheme.bodyLarge,
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(MealPlanStatus status, AppLocalizations l10n) {
    switch (status) {
      case MealPlanStatus.cooked:
        return Chip(
          avatar: const Icon(Icons.check_circle, size: 16, color: Colors.green),
          label: Text(l10n.calendarStatusCooked),
          backgroundColor: Colors.green.withValues(alpha: 0.12),
        );
      case MealPlanStatus.skipped:
        return Chip(
          avatar: const Icon(
            Icons.remove_circle,
            size: 16,
            color: Colors.orange,
          ),
          label: Text(l10n.calendarStatusSkipped),
          backgroundColor: Colors.orange.withValues(alpha: 0.12),
        );
      case MealPlanStatus.planned:
        return Chip(
          avatar: const Icon(Icons.schedule, size: 16, color: Colors.blue),
          label: Text(l10n.calendarStatusPlanned),
          backgroundColor: Colors.blue.withValues(alpha: 0.12),
        );
    }
  }
}
