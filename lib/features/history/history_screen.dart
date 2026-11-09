import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/app_images.dart';
import '../../core/db/daos/history_dao.dart';
import '../../core/db/enums.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';

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

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  DishType? _selectedDishType;
  bool _onlyFavorites = false;
  bool _filterByMonth = false;
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = clock.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _prevMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  Future<void> _softDeleteEntry(CookedEntryWithRecipe item) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final entryId = item.entry.id;

    await ref.read(historyDaoProvider).softDelete(entryId);
    ref.invalidate(historyEntriesProvider);
    ref.invalidate(historyMonthSummaryProvider);

    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        content: Text(
          l10n.historyDeletedSnackbar,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onInverseSurface,
          ),
        ),
        action: SnackBarAction(
          label: l10n.historyUndoDelete,
          onPressed: () async {
            await ref.read(historyDaoProvider).restore(entryId);
            ref.invalidate(historyEntriesProvider);
            ref.invalidate(historyMonthSummaryProvider);
          },
        ),
      ),
    );
  }

  Future<void> _showEditRatingDialog(CookedEntryWithRecipe item) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    int currentRating = item.entry.rating ?? 5;

    final selected = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                l10n.historyEditRating,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.recipe?.title ?? item.entry.recipeId,
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (starIdx) {
                      final starValue = starIdx + 1;
                      final filled = starValue <= currentRating;
                      return SizedBox(
                        width: 52,
                        height: 52,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            filled ? Icons.star : Icons.star_border,
                            size: 38,
                            color: filled
                                ? theme.colorScheme.secondary
                                : theme.colorScheme.outlineVariant,
                          ),
                          tooltip: '$starValue',
                          onPressed: () {
                            setDialogState(() {
                              currentRating = starValue;
                            });
                          },
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.historyRatingStars(currentRating),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  child: Text(
                    l10n.historyAddCancelButton,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(currentRating),
                  child: Text(
                    l10n.historyAddSaveButton,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (selected != null && mounted) {
      await ref.read(historyDaoProvider).updateRating(item.entry.id, selected);
      ref.invalidate(historyEntriesProvider);
      ref.invalidate(historyMonthSummaryProvider);
    }
  }

  Future<void> _showAddDishDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return _AddCookedDishSheet(
          l10n: l10n,
          theme: theme,
          onSave:
              ({
                required String title,
                required DishType dishType,
                required DateTime date,
                required int? rating,
                required bool wouldRepeat,
                required String? note,
              }) async {
                await ref
                    .read(historyDaoProvider)
                    .addManualEntry(
                      title: title,
                      dishType: dishType,
                      date: date,
                      rating: rating,
                      wouldRepeat: wouldRepeat,
                      note: note,
                    );
                ref.invalidate(historyEntriesProvider);
                ref.invalidate(historyMonthSummaryProvider);

                if (mounted) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.cookingSavedToHistory)),
                  );
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
    final historyAsync = ref.watch(historyEntriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.screenHistoryTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDishDialog,
        icon: const Icon(Icons.add, size: 28),
        label: Text(
          l10n.historyAddButton,
          // The explicit text style overrides the FAB foreground, so the
          // color must be set here, or the label is dark on dark green.
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ),
      body: historyAsync.when(
        data: (allEntries) {
          if (allEntries.isEmpty) {
            return _EmptyHistoryView(l10n: l10n, onAddDish: _showAddDishDialog);
          }

          final query = _searchController.text.trim().toLowerCase();
          final monthPrefix = DateFormat('yyyy-MM').format(_selectedMonth);

          final filtered = allEntries.where((item) {
            if (query.isNotEmpty) {
              final title = item.recipe?.title.toLowerCase() ?? '';
              final note = item.entry.note?.toLowerCase() ?? '';
              if (!title.contains(query) && !note.contains(query)) {
                return false;
              }
            }

            if (_selectedDishType != null) {
              if (item.recipe?.dishType != _selectedDishType) {
                return false;
              }
            }

            if (_onlyFavorites) {
              final isFav =
                  (item.entry.rating != null && item.entry.rating! >= 4) ||
                  item.entry.wouldRepeat == true;
              if (!isFav) {
                return false;
              }
            }

            if (_filterByMonth) {
              if (!item.entry.cookedOn.startsWith(monthPrefix)) {
                return false;
              }
            }

            return true;
          }).toList();

          return CustomScrollView(
            slivers: [
              // 1. Month Summary Card
              SliverToBoxAdapter(
                child: _MonthSummaryCard(
                  selectedMonth: _selectedMonth,
                  onPrevMonth: _prevMonth,
                  onNextMonth: _nextMonth,
                  l10n: l10n,
                ),
              ),

              // 2. Search bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: theme.textTheme.bodyLarge,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, size: 24),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              tooltip: l10n.historySearchClear,
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      hintText: l10n.historySearchHint,
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.35),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 3. Filter chips
              SliverToBoxAdapter(
                child: _HistoryFiltersRow(
                  selectedDishType: _selectedDishType,
                  onlyFavorites: _onlyFavorites,
                  filterByMonth: _filterByMonth,
                  selectedMonth: _selectedMonth,
                  l10n: l10n,
                  onResetFilters: () {
                    setState(() {
                      _selectedDishType = null;
                      _onlyFavorites = false;
                      _filterByMonth = false;
                    });
                  },
                  onToggleMonth: (val) {
                    setState(() {
                      _filterByMonth = val;
                    });
                  },
                  onToggleFavorites: (val) {
                    setState(() {
                      _onlyFavorites = val;
                    });
                  },
                  onSelectDishType: (type) {
                    setState(() {
                      _selectedDishType = type;
                    });
                  },
                ),
              ),

              // 4. Entries list or empty search result
              if (filtered.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 56,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.historyNoFilteredResults,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 56),
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(56),
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _selectedDishType = null;
                                _onlyFavorites = false;
                                _filterByMonth = false;
                              });
                            },
                            child: const Text('Сбросить фильтры'),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                _HistoryGroupedSliverList(
                  entries: filtered,
                  l10n: l10n,
                  onDelete: _softDeleteEntry,
                  onEditRating: _showEditRatingDialog,
                ),

              // Bottom padding for FAB
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(semanticsLabel: 'Загрузка истории'),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Не удалось загрузить историю',
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 56),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                    ),
                    onPressed: () => ref.invalidate(historyEntriesProvider),
                    child: const Text('Повторить'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthSummaryCard extends ConsumerWidget {
  const _MonthSummaryCard({
    required this.selectedMonth,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.l10n,
  });

  final DateTime selectedMonth;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summaryAsync = ref.watch(historyMonthSummaryProvider(selectedMonth));
    final monthRaw = DateFormat('LLLL yyyy', 'ru').format(selectedMonth);
    final monthTitle = monthRaw.isNotEmpty
        ? monthRaw[0].toUpperCase() + monthRaw.substring(1)
        : monthRaw;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left, size: 30),
                    tooltip: l10n.historyPreviousMonth,
                    onPressed: onPrevMonth,
                  ),
                ),
                Expanded(
                  child: Text(
                    l10n.historyMonthSummaryTitle(monthTitle),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  width: 52,
                  height: 52,
                  child: IconButton(
                    icon: const Icon(Icons.chevron_right, size: 30),
                    tooltip: l10n.historyNextMonth,
                    onPressed: onNextMonth,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            summaryAsync.when(
              data: (summary) => Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          icon: Icons.soup_kitchen,
                          label: l10n.historySummaryCooked(summary.totalCooked),
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MetricCard(
                          icon: Icons.auto_awesome,
                          label: l10n.historySummaryNew(summary.newDishesCount),
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 20,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            summary.topRatedRecipeTitle != null
                                ? l10n.historySummaryTopRated(
                                    '${summary.topRatedRecipeTitle!} (${summary.topRating!.toStringAsFixed(1)}★)',
                                  )
                                : l10n.historySummaryNoRatings,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (err, stack) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryFiltersRow extends StatelessWidget {
  const _HistoryFiltersRow({
    required this.selectedDishType,
    required this.onlyFavorites,
    required this.filterByMonth,
    required this.selectedMonth,
    required this.l10n,
    required this.onResetFilters,
    required this.onToggleMonth,
    required this.onToggleFavorites,
    required this.onSelectDishType,
  });

  final DishType? selectedDishType;
  final bool onlyFavorites;
  final bool filterByMonth;
  final DateTime selectedMonth;
  final AppLocalizations l10n;
  final VoidCallback onResetFilters;
  final ValueChanged<bool> onToggleMonth;
  final ValueChanged<bool> onToggleFavorites;
  final ValueChanged<DishType?> onSelectDishType;

  @override
  Widget build(BuildContext context) {
    final monthRaw = DateFormat('LLLL', 'ru').format(selectedMonth);
    final monthTitle = monthRaw.isNotEmpty
        ? monthRaw[0].toUpperCase() + monthRaw.substring(1)
        : monthRaw;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          FilterChip(
            label: Text(l10n.historyFilterAll),
            selected:
                selectedDishType == null && !onlyFavorites && !filterByMonth,
            onSelected: (_) => onResetFilters(),
          ),
          const SizedBox(width: 8),
          FilterChip(
            avatar: const Icon(Icons.calendar_month, size: 18),
            label: Text('За $monthTitle'),
            selected: filterByMonth,
            onSelected: onToggleMonth,
          ),
          const SizedBox(width: 8),
          FilterChip(
            avatar: const Icon(Icons.star, size: 18),
            label: Text(l10n.historyFilterFavorites),
            selected: onlyFavorites,
            onSelected: onToggleFavorites,
          ),
          const SizedBox(width: 8),
          for (final type in DishType.values) ...[
            FilterChip(
              avatar: AppDishTypeIcon(dishType: type, size: 18),
              label: Text(_dishTypeName(type, l10n)),
              selected: selectedDishType == type,
              onSelected: (val) => onSelectDishType(val ? type : null),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _HistoryGroupedSliverList extends StatelessWidget {
  const _HistoryGroupedSliverList({
    required this.entries,
    required this.l10n,
    required this.onDelete,
    required this.onEditRating,
  });

  final List<CookedEntryWithRecipe> entries;
  final AppLocalizations l10n;
  final Future<void> Function(CookedEntryWithRecipe) onDelete;
  final Future<void> Function(CookedEntryWithRecipe) onEditRating;

  String _formatGroupDate(String cookedOnIso) {
    try {
      final parts = cookedOnIso.split('-');
      if (parts.length != 3) return cookedOnIso;
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      final now = clock.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final itemDate = DateTime(date.year, date.month, date.day);

      final dateFormatted = DateFormat('d MMMM', 'ru').format(date);
      if (itemDate == today) {
        return l10n.historyDateToday(dateFormatted);
      } else if (itemDate == yesterday) {
        return l10n.historyDateYesterday(dateFormatted);
      } else if (itemDate.year == today.year) {
        return DateFormat('d MMMM, EEEE', 'ru').format(date);
      } else {
        return DateFormat('d MMMM yyyy г.', 'ru').format(date);
      }
    } catch (_) {
      return cookedOnIso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Group items by cookedOn date (preserving order)
    final Map<String, List<CookedEntryWithRecipe>> grouped = {};
    for (final item in entries) {
      grouped.putIfAbsent(item.entry.cookedOn, () => []).add(item);
    }

    final dateKeys = grouped.keys.toList();

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final dateKey = dateKeys[index];
        final dayItems = grouped[dateKey]!;
        final headerTitle = _formatGroupDate(dateKey);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                headerTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            ...dayItems.map(
              (item) => _HistoryEntryCard(
                item: item,
                l10n: l10n,
                onDelete: () => onDelete(item),
                onEditRating: () => onEditRating(item),
              ),
            ),
          ],
        );
      }, childCount: dateKeys.length),
    );
  }
}

class _HistoryEntryCard extends StatelessWidget {
  const _HistoryEntryCard({
    required this.item,
    required this.l10n,
    required this.onDelete,
    required this.onEditRating,
  });

  final CookedEntryWithRecipe item;
  final AppLocalizations l10n;
  final VoidCallback onDelete;
  final VoidCallback onEditRating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entry = item.entry;
    final recipe = item.recipe;
    final title = recipe?.title ?? entry.recipeId;
    final rating = entry.rating;
    final wouldRepeat = entry.wouldRepeat;
    final note = entry.note;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Dish type & cooking time
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                if (recipe != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
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
                        AppDishTypeIcon(dishType: recipe.dishType, size: 18),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _dishTypeName(recipe.dishType, l10n),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (recipe != null) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          l10n.historyCookingTime(recipe.totalMinutes),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            // Rating row (tappable to edit rating)
            InkWell(
              onTap: onEditRating,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (rating != null) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(5, (starIdx) {
                              final filled = starIdx < rating;
                              return Icon(
                                filled ? Icons.star : Icons.star_border,
                                size: 24,
                                color: filled
                                    ? theme.colorScheme.secondary
                                    : theme.colorScheme.outlineVariant,
                              );
                            }),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              l10n.historyRatingStars(rating),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        l10n.historyRatingUnrated,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (wouldRepeat == true) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.4,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.thumb_up_alt_outlined,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                l10n.historyWouldRepeat,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
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
            ),

            // Note
            if (note != null && note.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border(
                    left: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  note,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),

            // Bottom actions: View Recipe + Soft Delete
            Row(
              children: [
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 56),
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.menu_book),
                      label: Text(
                        l10n.historyCookAgain,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () =>
                          context.push('/recipe/${entry.recipeId}'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 56,
                  height: 56,
                  child: IconButton.outlined(
                    style: IconButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline, size: 28),
                    tooltip: l10n.historyDeleteButton,
                    onPressed: onDelete,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHistoryView extends StatelessWidget {
  const _EmptyHistoryView({required this.l10n, required this.onAddDish});

  final AppLocalizations l10n;
  final VoidCallback onAddDish;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.35,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_stories_outlined,
                size: 56,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.historyEmptyTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.historyEmptySubtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: 56,
                minWidth: double.infinity,
              ),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                icon: const Icon(Icons.search),
                label: Text(
                  l10n.historyEmptyAction,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () => context.go('/pantry'),
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: 56,
                minWidth: double.infinity,
              ),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                icon: const Icon(Icons.add),
                label: Text(
                  l10n.historyAddButton,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: onAddDish,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddCookedDishSheet extends StatefulWidget {
  const _AddCookedDishSheet({
    required this.l10n,
    required this.theme,
    required this.onSave,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final Future<void> Function({
    required String title,
    required DishType dishType,
    required DateTime date,
    required int? rating,
    required bool wouldRepeat,
    required String? note,
  })
  onSave;

  @override
  State<_AddCookedDishSheet> createState() => _AddCookedDishSheetState();
}

class _AddCookedDishSheetState extends State<_AddCookedDishSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  DishType _selectedDishType = DishType.main;
  late DateTime _selectedDate;
  int _rating = 5;
  bool _wouldRepeat = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = clock.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: clock.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() {
      _isSaving = true;
    });

    final note = _noteController.text.trim();
    await widget.onSave(
      title: title,
      dishType: _selectedDishType,
      date: _selectedDate,
      rating: _rating,
      wouldRepeat: _wouldRepeat,
      note: note.isNotEmpty ? note : null,
    );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final theme = widget.theme;

    final now = clock.now();
    final isToday =
        _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday =
        _selectedDate.year == yesterday.year &&
        _selectedDate.month == yesterday.month &&
        _selectedDate.day == yesterday.day;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.historyAddModalTitle,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: l10n.historyAddCancelButton,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Dish Name
            Text(
              l10n.historyAddDishNameLabel,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              autofocus: true,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: l10n.historyAddDishNameHint,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Dish Type
            Text(
              l10n.historyAddDishTypeLabel,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final type in DishType.values) ...[
                    ChoiceChip(
                      avatar: AppDishTypeIcon(dishType: type, size: 18),
                      label: Text(_dishTypeName(type, l10n)),
                      selected: _selectedDishType == type,
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _selectedDishType = type;
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Date
            Text(
              l10n.historyAddDateLabel,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Сегодня'),
                  selected: isToday,
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _selectedDate = clock.now();
                      });
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Вчера'),
                  selected: isYesterday,
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _selectedDate = clock.now().subtract(
                          const Duration(days: 1),
                        );
                      });
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  avatar: const Icon(Icons.edit_calendar, size: 18),
                  label: Text(
                    !isToday && !isYesterday
                        ? DateFormat('d MMMM', 'ru').format(_selectedDate)
                        : 'Другая дата',
                  ),
                  selected: !isToday && !isYesterday,
                  onSelected: (_) => _pickDate(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Rating
            Text(
              l10n.historyAddRatingLabel,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: List.generate(5, (starIdx) {
                final starValue = starIdx + 1;
                final filled = starValue <= _rating;
                return SizedBox(
                  width: 52,
                  height: 52,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      filled ? Icons.star : Icons.star_border,
                      size: 38,
                      color: filled
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.outlineVariant,
                    ),
                    tooltip: '$starValue',
                    onPressed: () {
                      setState(() {
                        _rating = starValue;
                      });
                    },
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),

            // Would repeat switch
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                l10n.historyAddWouldRepeatLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              value: _wouldRepeat,
              onChanged: (val) {
                setState(() {
                  _wouldRepeat = val;
                });
              },
            ),
            const SizedBox(height: 12),

            // Note
            Text(
              l10n.historyAddNoteLabel,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _noteController,
              maxLines: 2,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: l10n.historyAddNoteHint,
                filled: true,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: 56,
                minWidth: double.infinity,
              ),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                onPressed: _titleController.text.trim().isNotEmpty && !_isSaving
                    ? _submit
                    : null,
                child: _isSaving
                    ? const CircularProgressIndicator()
                    : Text(
                        l10n.historyAddSaveButton,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
