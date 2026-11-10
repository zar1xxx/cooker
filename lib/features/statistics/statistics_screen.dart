import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/adaptive/adaptive_app_bar_title.dart';
import '../../core/adaptive/adaptive_spec.dart';
import '../../core/db/app_database.dart';
import '../../core/db/daos/history_dao.dart';
import '../../core/db/enums.dart';
import '../../core/providers.dart';

enum StatsPeriod {
  week,
  month,
  year,
  allTime;

  String get label {
    switch (this) {
      case StatsPeriod.week:
        return 'Неделя';
      case StatsPeriod.month:
        return 'Месяц';
      case StatsPeriod.year:
        return 'Год';
      case StatsPeriod.allTime:
        return 'Всё время';
    }
  }
}

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  StatsPeriod _selectedPeriod = StatsPeriod.month;

  List<CookedEntryWithRecipe> _filterByPeriod(
    List<CookedEntryWithRecipe> entries,
  ) {
    final now = DateTime.now();
    DateTime cutoff;

    switch (_selectedPeriod) {
      case StatsPeriod.week:
        cutoff = now.subtract(const Duration(days: 7));
      case StatsPeriod.month:
        cutoff = DateTime(now.year, now.month, 1);
      case StatsPeriod.year:
        cutoff = DateTime(now.year, 1, 1);
      case StatsPeriod.allTime:
        return entries;
    }

    final cutoffStr = DateFormat('yyyy-MM-dd').format(cutoff);
    return entries
        .where((e) => e.entry.cookedOn.compareTo(cutoffStr) >= 0)
        .toList();
  }

  void _showDishesListSheet({
    required BuildContext context,
    required String title,
    required List<CookedEntryWithRecipe> items,
  }) {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
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
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('Нет записей за выбранный период'),
                  )
                else
                  for (final item in items)
                    Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(item.recipe?.title ?? item.entry.recipeId),
                        subtitle: Text(
                          '${item.entry.cookedOn} • ${item.entry.rating != null ? "${item.entry.rating} ★" : "без оценки"}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          if (item.recipe != null) {
                            context.push('/recipe/${item.recipe!.id}');
                          }
                        },
                      ),
                    ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final adaptive = context.adaptive;
    final theme = Theme.of(context);
    final historyDao = ref.watch(historyDaoProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const AdaptiveAppBarTitle('Статистика'),
      ),
      body: FutureBuilder<List<CookedEntryWithRecipe>>(
        future: historyDao.allWithRecipes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allEntries = snapshot.data ?? const <CookedEntryWithRecipe>[];
          final periodEntries = _filterByPeriod(allEntries);

          // If empty across entire history
          if (allEntries.isEmpty) {
            return Center(
              child: Padding(
                padding: adaptive.cardPadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.insights,
                      size: adaptive.isSimple ? 64 : 48,
                      color: theme.colorScheme.outlineVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Приготовьте и оцените пару блюд — здесь появится статистика',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final totalCooked = periodEntries.length;

          // 1. New dishes count (cooked for the first time in this period)
          final cookedBeforePeriod = <String>{};
          if (_selectedPeriod != StatsPeriod.allTime) {
            final now = DateTime.now();
            final cutoff = switch (_selectedPeriod) {
              StatsPeriod.week => now.subtract(const Duration(days: 7)),
              StatsPeriod.month => DateTime(now.year, now.month, 1),
              StatsPeriod.year => DateTime(now.year, 1, 1),
              StatsPeriod.allTime => DateTime(1970),
            };
            final cutoffStr = DateFormat('yyyy-MM-dd').format(cutoff);
            for (final e in allEntries) {
              if (e.entry.cookedOn.compareTo(cutoffStr) < 0) {
                cookedBeforePeriod.add(e.entry.recipeId);
              }
            }
          }
          final distinctPeriodRecipes = periodEntries
              .map((e) => e.entry.recipeId)
              .toSet();
          final newDishes = distinctPeriodRecipes
              .where((r) => !cookedBeforePeriod.contains(r))
              .toList();
          final newDishesCount = newDishes.length;

          // 2. Favorite dish (most cooked, highest rated)
          final recipeCounts = <String, int>{};
          final recipeRatings = <String, List<int>>{};
          final recipeObjMap = <String, Recipe>{};
          for (final it in periodEntries) {
            final rId = it.entry.recipeId;
            recipeCounts[rId] = (recipeCounts[rId] ?? 0) + 1;
            if (it.entry.rating != null) {
              recipeRatings.putIfAbsent(rId, () => []).add(it.entry.rating!);
            }
            if (it.recipe != null) {
              recipeObjMap[rId] = it.recipe!;
            }
          }

          String favoriteDishTitle = '—';
          String? favoriteRecipeId;
          int maxCooked = 0;
          for (final entry in recipeCounts.entries) {
            if (entry.value > maxCooked) {
              maxCooked = entry.value;
              favoriteRecipeId = entry.key;
              favoriteDishTitle = recipeObjMap[entry.key]?.title ?? entry.key;
            }
          }

          // 3. Top rating
          final ratedEntries = periodEntries
              .where((e) => e.entry.rating != null)
              .toList();
          final topRating = ratedEntries.isNotEmpty
              ? ratedEntries
                    .map((e) => e.entry.rating!)
                    .reduce((a, b) => a > b ? a : b)
                    .toDouble()
              : null;

          // 4. Kitchen active time
          final totalActiveMinutes = periodEntries.fold<int>(
            0,
            (sum, it) => sum + (it.recipe?.activeMinutes ?? 15),
          );
          final hours = totalActiveMinutes ~/ 60;
          final mins = totalActiveMinutes % 60;
          final activeTimeString = hours > 0
              ? '$hours ч $mins мин'
              : '$mins мин';

          // 5. Category breakdown
          final categoryCounts = <String, int>{
            'Супы': 0,
            'Вторые блюда': 0,
            'Салаты и закуски': 0,
            'Выпечка и десерты': 0,
            'Другое': 0,
          };
          for (final it in periodEntries) {
            final dt = it.recipe?.dishType;
            if (dt == DishType.soup) {
              categoryCounts['Супы'] = categoryCounts['Супы']! + 1;
            } else if (dt == DishType.main || dt == DishType.side) {
              categoryCounts['Вторые блюда'] =
                  categoryCounts['Вторые блюда']! + 1;
            } else if (dt == DishType.salad || dt == DishType.snack) {
              categoryCounts['Салаты и закуски'] =
                  categoryCounts['Салаты и закуски']! + 1;
            } else if (dt == DishType.baking || dt == DishType.dessert) {
              categoryCounts['Выпечка и десерты'] =
                  categoryCounts['Выпечка и десерты']! + 1;
            } else {
              categoryCounts['Другое'] = categoryCounts['Другое']! + 1;
            }
          }

          // 6. AI Assistant metrics
          final aiEntries = periodEntries
              .where((e) => e.recipe?.source == RecipeSource.ai)
              .toList();
          final aiCooked = aiEntries.length;
          final aiRatings = aiEntries
              .where((e) => e.entry.rating != null)
              .map((e) => e.entry.rating!)
              .toList();
          final aiAvgRating = aiRatings.isNotEmpty
              ? (aiRatings.reduce((a, b) => a + b) / aiRatings.length)
                    .toStringAsFixed(1)
              : '—';

          return ListView(
            padding: adaptive.cardPadding,
            children: [
              // Period selector (Full mode)
              if (adaptive.isFull) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<StatsPeriod>(
                    segments: StatsPeriod.values.map((p) {
                      return ButtonSegment<StatsPeriod>(
                        value: p,
                        label: Text(p.label),
                      );
                    }).toList(),
                    selected: {_selectedPeriod},
                    onSelectionChanged: (set) {
                      if (set.isNotEmpty) {
                        setState(() => _selectedPeriod = set.first);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 4 Summary Tiles (Clickable per R8-14)
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      key: const Key('tile_total_cooked'),
                      icon: Icons.check_circle_outline,
                      title: 'Приготовлено',
                      value: '$totalCooked',
                      color: theme.colorScheme.primary,
                      bgColor: theme.colorScheme.primaryContainer,
                      onTap: () {
                        _showDishesListSheet(
                          context: context,
                          title: 'Приготовленные блюда ($totalCooked)',
                          items: periodEntries,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatTile(
                      key: const Key('tile_new_dishes'),
                      icon: Icons.star_border,
                      title: 'Новых блюд',
                      value: '$newDishesCount',
                      color: theme.colorScheme.secondary,
                      bgColor: theme.colorScheme.secondaryContainer,
                      onTap: () {
                        final newItems = periodEntries
                            .where((e) => newDishes.contains(e.entry.recipeId))
                            .toList();
                        _showDishesListSheet(
                          context: context,
                          title: 'Новые блюда ($newDishesCount)',
                          items: newItems,
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      key: const Key('tile_favorite_dish'),
                      icon: Icons.favorite_border,
                      title: 'Любимое блюдо',
                      value: favoriteDishTitle,
                      color: theme.colorScheme.tertiary,
                      bgColor: theme.colorScheme.tertiaryContainer,
                      onTap: () {
                        if (favoriteRecipeId != null &&
                            recipeObjMap.containsKey(favoriteRecipeId)) {
                          context.push('/recipe/$favoriteRecipeId');
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatTile(
                      key: const Key('tile_top_rating'),
                      icon: Icons.thumb_up_outlined,
                      title: 'Лучшая оценка',
                      value: topRating != null
                          ? '${topRating.toStringAsFixed(1)} ★'
                          : '—',
                      color: theme.colorScheme.primary,
                      bgColor: theme.colorScheme.primaryContainer,
                      onTap: () {
                        final topItems = periodEntries
                            .where((e) => e.entry.rating == 5)
                            .toList();
                        _showDishesListSheet(
                          context: context,
                          title: 'Блюда с оценкой 5 ★ (${topItems.length})',
                          items: topItems,
                        );
                      },
                    ),
                  ),
                ],
              ),

              // Full mode detailed charts and widgets
              if (adaptive.isFull) ...[
                const SizedBox(height: 24),

                // Kitchen Active Time Tile
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 36,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Время на кухне',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Суммарное активное время готовки за период: $activeTimeString',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 3-Month Heatmap Calendar
                Text(
                  'Активность готовки (последние 3 месяца)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _ThreeMonthHeatmap(
                  allEntries: allEntries,
                  onDayTapped: (date, dishes) {
                    _showDishesListSheet(
                      context: context,
                      title:
                          'Готовка ${DateFormat("d MMMM", "ru").format(date)}',
                      items: dishes,
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Menu Category Breakdown (Horizontal Bars)
                Text(
                  'По разделам меню',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                for (final cat in categoryCounts.entries)
                  if (cat.value > 0 ||
                      cat.key == 'Супы' ||
                      cat.key == 'Вторые блюда') ...[
                    _DistributionBar(
                      label: cat.key,
                      count: cat.value,
                      total: totalCooked > 0 ? totalCooked : 1,
                      color: theme.colorScheme.primary,
                      onTap: () {
                        final catItems = periodEntries.where((e) {
                          final dt = e.recipe?.dishType;
                          if (cat.key == 'Супы') {
                            return dt == DishType.soup;
                          }
                          if (cat.key == 'Вторые блюда') {
                            return dt == DishType.main || dt == DishType.side;
                          }
                          if (cat.key == 'Салаты и закуски') {
                            return dt == DishType.salad || dt == DishType.snack;
                          }
                          if (cat.key == 'Выпечка и десерты') {
                            return dt == DishType.baking ||
                                dt == DishType.dessert;
                          }
                          return true;
                        }).toList();
                        _showDishesListSheet(
                          context: context,
                          title: '${cat.key} (${catItems.length})',
                          items: catItems,
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                  ],

                const SizedBox(height: 20),

                // AI Assistant Stats
                Text(
                  'Помощник ИИ',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: adaptive.cardPadding,
                    child: Row(
                      children: [
                        Expanded(
                          child: _AiMetric(
                            title: 'Приготовлено ИИ',
                            value: '$aiCooked',
                          ),
                        ),
                        Expanded(
                          child: _AiMetric(
                            title: 'Ср. оценка ИИ',
                            value: aiAvgRating,
                          ),
                        ),
                        Expanded(
                          child: _AiMetric(
                            title: 'Доля в меню',
                            value: totalCooked > 0
                                ? '${((aiCooked / totalCooked) * 100).round()}%'
                                : '0%',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final adaptive = context.adaptive;

    return Semantics(
      button: true,
      label: '$title: $value',
      child: Material(
        color: bgColor.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 80),
            padding: adaptive.cardPadding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DistributionBar extends StatelessWidget {
  const _DistributionBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
    this.onTap,
  });

  final String label;
  final int count;
  final int total;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = total > 0 ? (count / total).clamp(0.0, 1.0) : 0.0;
    final percentStr = '${(ratio * 100).round()}%';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$count блюд ($percentStr)',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: ratio > 0 ? ratio : 0.02,
                  minHeight: 14,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiMetric extends StatelessWidget {
  const _AiMetric({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// 3-Month Activity Heatmap widget (R8-14)
class _ThreeMonthHeatmap extends StatelessWidget {
  const _ThreeMonthHeatmap({
    required this.allEntries,
    required this.onDayTapped,
  });

  final List<CookedEntryWithRecipe> allEntries;
  final void Function(DateTime date, List<CookedEntryWithRecipe> dishes)
  onDayTapped;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    // Map date string -> list of dishes
    final entriesByDate = <String, List<CookedEntryWithRecipe>>{};
    for (final it in allEntries) {
      entriesByDate.putIfAbsent(it.entry.cookedOn, () => []).add(it);
    }

    // Last 12 weeks (84 days)
    final days = <DateTime>[];
    for (int i = 83; i >= 0; i--) {
      days.add(
        DateTime(now.year, now.month, now.day).subtract(Duration(days: i)),
      );
    }

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(12, (weekIdx) {
              return Column(
                children: List.generate(7, (dayIdx) {
                  final idx = weekIdx * 7 + dayIdx;
                  if (idx >= days.length) {
                    return const SizedBox(width: 18, height: 18);
                  }
                  final d = days[idx];
                  final dStr = DateFormat('yyyy-MM-dd').format(d);
                  final dishes = entriesByDate[dStr] ?? const [];
                  final count = dishes.length;

                  Color cellColor;
                  if (count == 0) {
                    cellColor = theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5);
                  } else if (count == 1) {
                    cellColor = theme.colorScheme.primaryContainer;
                  } else if (count == 2) {
                    cellColor = theme.colorScheme.primary.withValues(
                      alpha: 0.7,
                    );
                  } else {
                    cellColor = theme.colorScheme.primary;
                  }

                  return Semantics(
                    button: true,
                    label:
                        '${DateFormat("d MMMM", "ru").format(d)}: $count блюд',
                    child: InkWell(
                      onTap: () => onDayTapped(d, dishes),
                      child: Container(
                        width: 18,
                        height: 18,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: cellColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  );
                }),
              );
            }),
          ),
        ),
      ),
    );
  }
}
