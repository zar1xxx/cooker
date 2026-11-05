import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../app/app_images.dart';
import '../../core/db/app_database.dart';
import '../../core/db/daos/plan_dao.dart';
import '../../core/db/daos/recipe_dao.dart';
import '../../core/db/enums.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import 'recipe_picker_sheet.dart';

String _dishTypeName(DishType type, AppLocalizations l10n) {
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

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key, this.initialDay});

  final DateTime? initialDay;

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialDay ?? clock.now();
    _selectedDay = widget.initialDay ?? clock.now();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final planAsync = ref.watch(calendarPlanEntriesProvider);
    final pantryAsync = ref.watch(pantryProvider);
    final pantry = pantryAsync.value ?? const <String>{};

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.screenCalendarTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: planAsync.when(
        data: (planEntries) {
          final entriesByDate = {
            for (final item in planEntries) item.entry.date: item,
          };
          final selectedKey = PlanDao.formatDate(_selectedDay);
          final selectedEntry = entriesByDate[selectedKey];

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Calendar Grid Card
                Card(
                  margin: const EdgeInsets.all(12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: TableCalendar<MealPlanEntryWithRecipe>(
                      firstDay: DateTime(2020, 1, 1),
                      lastDay: DateTime(2035, 12, 31),
                      focusedDay: _focusedDay,
                      locale: 'ru',
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      calendarFormat: CalendarFormat.month,
                      availableCalendarFormats: const {
                        CalendarFormat.month: 'Месяц',
                      },
                      rowHeight:
                          (64 * MediaQuery.textScalerOf(context).scale(1))
                              .clamp(64.0, 96.0),
                      daysOfWeekHeight:
                          (32 * MediaQuery.textScalerOf(context).scale(1))
                              .clamp(32.0, 48.0),
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDay, day),
                      eventLoader: (day) {
                        final key = PlanDao.formatDate(day);
                        final entry = entriesByDate[key];
                        return entry != null ? [entry] : const [];
                      },
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      onPageChanged: (focusedDay) {
                        setState(() {
                          _focusedDay = focusedDay;
                        });
                      },
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle:
                            theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ) ??
                            const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                        leftChevronIcon: const Icon(
                          Icons.chevron_left,
                          size: 32,
                        ),
                        rightChevronIcon: const Icon(
                          Icons.chevron_right,
                          size: 32,
                        ),
                        leftChevronPadding: const EdgeInsets.all(12),
                        rightChevronPadding: const EdgeInsets.all(12),
                      ),
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle:
                            theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ) ??
                            const TextStyle(fontWeight: FontWeight.bold),
                        weekendStyle:
                            theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ) ??
                            TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                      ),
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, day, events) {
                          if (events.isEmpty) return null;
                          final mealItem = events.first;
                          final recipe = mealItem.recipe;
                          final status = mealItem.entry.status;
                          final locked = mealItem.entry.locked;

                          return Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (recipe != null)
                                    AppDishTypeIcon(
                                      dishType: recipe.dishType,
                                      size: 16,
                                    ),
                                  const SizedBox(width: 3),
                                  _buildStatusBadge(status),
                                  if (locked) ...[
                                    const SizedBox(width: 3),
                                    Icon(
                                      Icons.lock,
                                      size: 13,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Selected Day Details Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _SelectedDayMealCard(
                    date: _selectedDay,
                    entryWithRecipe: selectedEntry,
                    pantry: pantry,
                    onLockToggle: (entry) async {
                      await ref
                          .read(planDaoProvider)
                          .setLocked(entry.id, !entry.locked);
                      ref.invalidate(calendarPlanEntriesProvider);
                    },
                    onStatusChange: (entry, newStatus) async {
                      await ref
                          .read(planDaoProvider)
                          .setStatus(entry.id, newStatus);
                      ref.invalidate(calendarPlanEntriesProvider);
                    },
                    onReplaceRecipe: () => _showRecipePicker(context),
                    onReplaceWithAvailable: () =>
                        _showRecipePicker(context, onlyAvailable: true),
                    onChooseRecipe: () => _showRecipePicker(context),
                  ),
                ),

                const SizedBox(height: 16),

                // Make month plan action button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FilledButton.icon(
                    key: const Key('calendar_make_month_plan_button'),
                    onPressed: _isGenerating
                        ? null
                        : () => _handleMakeMonthPlan(context),
                    icon: _isGenerating
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.auto_awesome, size: 28),
                    label: Text(
                      l10n.calendarMakeMonthPlan,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Ошибка загрузки календаря: $err',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(MealPlanStatus status) {
    switch (status) {
      case MealPlanStatus.cooked:
        return const Icon(Icons.check_circle, size: 14, color: Colors.green);
      case MealPlanStatus.skipped:
        return const Icon(Icons.remove_circle, size: 14, color: Colors.orange);
      case MealPlanStatus.planned:
        return Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue,
          ),
        );
    }
  }

  Future<void> _handleMakeMonthPlan(BuildContext context) async {
    setState(() => _isGenerating = true);
    try {
      final planner = ref.read(mealPlannerProvider);
      final planned = await planner.generateMonthPlan(fromDate: _focusedDay);
      ref.invalidate(calendarPlanEntriesProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'План составлен: ${planned.length} дней',
              style: const TextStyle(fontSize: 16),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
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
    final existingEntry =
        (await ref
                .read(planDaoProvider)
                .getEntryForDate(PlanDao.formatDate(_selectedDay)))
            ?.entry;

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
          selectedDate: _selectedDay,
          pantry: pantry,
          initialOnlyFavorites: onlyFavorites,
          initialOnlyAvailable: onlyAvailable,
          onSelected: (recipeWithIng) async {
            final dateStr = PlanDao.formatDate(_selectedDay);
            final isLocked = existingEntry?.locked ?? false;
            await ref
                .read(planDaoProvider)
                .upsertEntry(
                  date: dateStr,
                  recipeId: recipeWithIng.recipe.id,
                  status: MealPlanStatus.planned,
                  locked: isLocked,
                );
            ref.invalidate(calendarPlanEntriesProvider);
            if (sheetContext.mounted) {
              Navigator.of(sheetContext).pop();
            }
          },
        );
      },
    );
  }
}

class _SelectedDayMealCard extends ConsumerWidget {
  const _SelectedDayMealCard({
    required this.date,
    required this.entryWithRecipe,
    required this.pantry,
    required this.onLockToggle,
    required this.onStatusChange,
    required this.onReplaceRecipe,
    required this.onChooseRecipe,
    this.onReplaceWithAvailable,
  });

  final DateTime date;
  final MealPlanEntryWithRecipe? entryWithRecipe;
  final Set<String> pantry;
  final ValueChanged<MealPlanEntry> onLockToggle;
  final void Function(MealPlanEntry, MealPlanStatus) onStatusChange;
  final VoidCallback onReplaceRecipe;
  final VoidCallback onChooseRecipe;
  final VoidCallback? onReplaceWithAvailable;

  String _formatDateHeader(DateTime date, AppLocalizations l10n) {
    final now = clock.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diffDays = target.difference(today).inDays;

    final dateFormatted = DateFormat('d MMMM, EEEE', 'ru').format(date);
    if (diffDays == 0) {
      return l10n.calendarTodayPrefix(dateFormatted);
    } else if (diffDays == 1) {
      return l10n.calendarTomorrowPrefix(dateFormatted);
    } else if (diffDays == -1) {
      return l10n.calendarYesterdayPrefix(dateFormatted);
    }
    return dateFormatted;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final item = entryWithRecipe;
    final recipe = item?.recipe;
    final entry = item?.entry;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date title
            Text(
              _formatDateHeader(date, l10n),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),

            if (recipe != null && entry != null) ...[
              // Recipe Title
              Text(
                recipe.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Badges Row
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  Chip(
                    avatar: AppDishTypeIcon(
                      dishType: recipe.dishType,
                      size: 18,
                    ),
                    label: Text(_dishTypeName(recipe.dishType, l10n)),
                  ),
                  Chip(
                    avatar: const Icon(Icons.timer_outlined, size: 18),
                    label: Text('${recipe.totalMinutes} мин'),
                  ),
                  Chip(
                    avatar: const Icon(Icons.speed, size: 18),
                    label: Text(_difficultyName(l10n, recipe.difficulty)),
                  ),
                  _buildStatusChip(entry.status, l10n),
                  if (entry.locked)
                    Chip(
                      avatar: const Icon(Icons.lock, size: 16),
                      label: Text(l10n.calendarLockedBadge),
                      backgroundColor: theme.colorScheme.secondaryContainer
                          .withValues(alpha: 0.4),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Ingredients availability check
              FutureBuilder<RecipeDetail?>(
                future: ref.read(recipeDaoProvider).getRecipeDetail(recipe.id),
                builder: (context, snapshot) {
                  final detail = snapshot.data;
                  if (detail == null) {
                    return const SizedBox.shrink();
                  }

                  final missing = detail.ingredients
                      .where(
                        (i) =>
                            i.ingredient != null &&
                            !pantry.contains(i.ingredient!.id),
                      )
                      .map((i) => i.ingredient!.name)
                      .toList();

                  if (missing.isEmpty) {
                    return Container(
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
                    );
                  } else {
                    return Container(
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
                            onPressed:
                                onReplaceWithAvailable ?? onReplaceRecipe,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 56),
                            ),
                            child: Text(
                              l10n.calendarReplaceWithAvailable,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),

              const SizedBox(height: 16),

              // Action Buttons
              FilledButton.icon(
                onPressed: () => context.push('/recipe/${recipe.id}'),
                icon: const Icon(Icons.restaurant_menu, size: 24),
                label: Text(
                  l10n.calendarViewRecipe,
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

              const SizedBox(height: 8),

              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrowOrLargeFont =
                      constraints.maxWidth < 340 ||
                      MediaQuery.textScalerOf(context).scale(1) > 1.25;

                  final lockButton = OutlinedButton.icon(
                    onPressed: () => onLockToggle(entry),
                    icon: Icon(
                      entry.locked ? Icons.lock_open : Icons.lock,
                      size: 20,
                    ),
                    label: Text(
                      entry.locked
                          ? l10n.calendarUnlockDish
                          : l10n.calendarLockDish,
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );

                  final replaceButton = OutlinedButton.icon(
                    onPressed: onReplaceRecipe,
                    icon: const Icon(Icons.swap_horiz, size: 20),
                    label: Text(l10n.calendarReplaceDish),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );

                  if (isNarrowOrLargeFont) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        lockButton,
                        const SizedBox(height: 8),
                        replaceButton,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: lockButton),
                      const SizedBox(width: 8),
                      Expanded(child: replaceButton),
                    ],
                  );
                },
              ),

              if (entry.status == MealPlanStatus.planned) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => onStatusChange(entry, MealPlanStatus.cooked),
                  icon: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 22,
                  ),
                  label: Text(
                    l10n.calendarMarkCooked,
                    style: const TextStyle(color: Colors.green),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    side: const BorderSide(color: Colors.green),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ] else ...[
              // Empty Day State
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  l10n.calendarEmptyDay,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              OutlinedButton.icon(
                onPressed: onChooseRecipe,
                icon: const Icon(Icons.add, size: 24),
                label: Text(
                  l10n.calendarChooseDish,
                  style: theme.textTheme.titleMedium?.copyWith(
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
