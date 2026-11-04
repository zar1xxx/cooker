import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/db/app_database.dart';
import '../../core/db/daos/plan_dao.dart';
import '../../core/db/daos/recipe_dao.dart';
import '../../core/db/enums.dart';
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
      return Icons.breakfast_dining;
    case DishType.snack:
      return Icons.cookie;
    case DishType.baking:
      return Icons.bakery_dining;
    case DishType.dessert:
      return Icons.cake;
    case DishType.drink:
      return Icons.local_cafe;
    case DishType.preserve:
      return Icons.takeout_dining;
  }
}

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
                      rowHeight: 64,
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
                                    Icon(
                                      _dishTypeIcon(recipe.dishType),
                                      size: 16,
                                      color: theme.colorScheme.primary,
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
                    onChooseRecipe: () => _showRecipePicker(context),
                  ),
                ),

                const SizedBox(height: 16),

                // Make month plan action button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FilledButton.icon(
                    key: const Key('calendar_make_month_plan_button'),
                    onPressed: () => _handleMakeMonthPlan(context),
                    icon: const Icon(Icons.auto_awesome, size: 28),
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

  void _handleMakeMonthPlan(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${l10n.calendarMakeMonthPlan}...',
          style: const TextStyle(fontSize: 16),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showRecipePicker(BuildContext context) async {
    final allRecipes = await ref.read(recipeDaoProvider).all();

    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return _RecipePickerSheet(
          recipes: allRecipes,
          selectedDate: _selectedDay,
          onSelected: (recipe) async {
            final dateStr = PlanDao.formatDate(_selectedDay);
            await ref
                .read(planDaoProvider)
                .upsertEntry(
                  date: dateStr,
                  recipeId: recipe.id,
                  status: MealPlanStatus.planned,
                  locked: false,
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
  });

  final DateTime date;
  final MealPlanEntryWithRecipe? entryWithRecipe;
  final Set<String> pantry;
  final ValueChanged<MealPlanEntry> onLockToggle;
  final void Function(MealPlanEntry, MealPlanStatus) onStatusChange;
  final VoidCallback onReplaceRecipe;
  final VoidCallback onChooseRecipe;

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
                    avatar: Icon(_dishTypeIcon(recipe.dishType), size: 18),
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
                            onPressed: onReplaceRecipe,
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

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
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
                      onPressed: onReplaceRecipe,
                      icon: const Icon(Icons.swap_horiz, size: 20),
                      label: Text(l10n.calendarReplaceDish),
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
                    minimumSize: const Size(double.infinity, 52),
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

class _RecipePickerSheet extends StatefulWidget {
  const _RecipePickerSheet({
    required this.recipes,
    required this.selectedDate,
    required this.onSelected,
  });

  final List<Recipe> recipes;
  final DateTime selectedDate;
  final ValueChanged<Recipe> onSelected;

  @override
  State<_RecipePickerSheet> createState() => _RecipePickerSheetState();
}

class _RecipePickerSheetState extends State<_RecipePickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final filtered = widget.recipes.where((r) {
      if (_query.isEmpty) return true;
      return r.title.toLowerCase().contains(_query.toLowerCase()) ||
          r.description.toLowerCase().contains(_query.toLowerCase());
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
              Text(
                'Выберите блюдо на ${DateFormat('d MMMM', 'ru').format(widget.selectedDate)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
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
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final recipe = filtered[index];
                return ListTile(
                  leading: Icon(_dishTypeIcon(recipe.dishType), size: 28),
                  title: Text(
                    recipe.title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${_dishTypeName(recipe.dishType, l10n)} · ${recipe.totalMinutes} мин · ${_difficultyName(l10n, recipe.difficulty)}',
                  ),
                  onTap: () => widget.onSelected(recipe),
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
