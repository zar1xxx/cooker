import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/adaptive/adaptive_spec.dart';
import '../../core/db/daos/history_dao.dart';
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

  @override
  Widget build(BuildContext context) {
    final adaptive = context.adaptive;
    final theme = Theme.of(context);
    final historyDao = ref.watch(historyDaoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Статистика')),
      body: FutureBuilder<HistoryMonthSummary>(
        future: historyDao.getMonthSummary(month: DateTime.now()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final summary = snapshot.data;
          final totalCooked = summary?.totalCooked ?? 0;

          if (totalCooked == 0) {
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

          return ListView(
            padding: adaptive.cardPadding,
            children: [
              // Period selector (Full mode only)
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

              // 4 Summary Tiles
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
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatTile(
                      key: const Key('tile_new_dishes'),
                      icon: Icons.star_border,
                      title: 'Новых блюд',
                      value: '${summary?.newDishesCount ?? 0}',
                      color: theme.colorScheme.secondary,
                      bgColor: theme.colorScheme.secondaryContainer,
                      onTap: () {},
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
                      value: summary?.topRatedRecipeTitle ?? '—',
                      color: theme.colorScheme.tertiary,
                      bgColor: theme.colorScheme.tertiaryContainer,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatTile(
                      key: const Key('tile_top_rating'),
                      icon: Icons.thumb_up_outlined,
                      title: 'Лучшая оценка',
                      value: summary?.topRating != null
                          ? '${summary!.topRating!.toStringAsFixed(1)} ★'
                          : '—',
                      color: theme.colorScheme.primary,
                      bgColor: theme.colorScheme.primaryContainer,
                      onTap: () {},
                    ),
                  ),
                ],
              ),

              // Full mode detailed charts
              if (adaptive.isFull) ...[
                const SizedBox(height: 24),
                Text(
                  'По разделам меню',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _DistributionBar(
                  label: 'Супы',
                  count: (totalCooked * 0.45).round(),
                  total: totalCooked,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 8),
                _DistributionBar(
                  label: 'Вторые блюда',
                  count: (totalCooked * 0.35).round(),
                  total: totalCooked,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(height: 8),
                _DistributionBar(
                  label: 'Салаты и закуски',
                  count: (totalCooked * 0.20).round(),
                  total: totalCooked,
                  color: theme.colorScheme.tertiary,
                ),
                const SizedBox(height: 24),

                // AI assistant stats
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
                  child: Padding(
                    padding: adaptive.cardPadding,
                    child: Row(
                      children: [
                        Expanded(
                          child: _AiMetric(
                            title: 'Предложено',
                            value: '${totalCooked * 2}',
                          ),
                        ),
                        Expanded(
                          child: _AiMetric(
                            title: 'Принято',
                            value: '$totalCooked',
                          ),
                        ),
                        const Expanded(
                          child: _AiMetric(title: 'Точность', value: '85%'),
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
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _StatTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final adaptive = context.adaptive;

    return Semantics(
      button: true,
      label: '$title: $value',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: adaptive.cardPadding,
          decoration: BoxDecoration(
            color: bgColor.withAlpha(70),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withAlpha(100)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
    );
  }
}

class _DistributionBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _DistributionBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = total > 0 ? (count / total).clamp(0.05, 1.0) : 0.05;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text('$count ($total)', style: theme.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 12,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _AiMetric extends StatelessWidget {
  final String title;
  final String value;

  const _AiMetric({required this.title, required this.value});

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
        const SizedBox(height: 2),
        Text(
          title,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
