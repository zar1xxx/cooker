import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/db/daos/history_dao.dart';
import '../../core/db/daos/plan_dao.dart';
import '../../core/db/enums.dart';
import '../../core/providers.dart';
import '../../core/widgets/assistant_badge.dart';

/// Bottom sheet showing planned and cooked dishes for a selected calendar day (R8-13).
class DayDetailsSheet extends ConsumerWidget {
  const DayDetailsSheet({
    super.key,
    required this.date,
    required this.onPlanAnother,
    this.planEntry,
  });

  final DateTime date;
  final VoidCallback onPlanAnother;
  final MealPlanEntryWithRecipe? planEntry;

  static Future<void> show(
    BuildContext context, {
    required DateTime date,
    required VoidCallback onPlanAnother,
    MealPlanEntryWithRecipe? planEntry,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DayDetailsSheet(
        date: date,
        onPlanAnother: onPlanAnother,
        planEntry: planEntry,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final historyDao = ref.watch(historyDaoProvider);
    final dateStr = PlanDao.formatDate(date);
    final dateFormatted = DateFormat('d MMMM, EEEE', 'ru').format(date);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            // Drag handle
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

            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateFormatted[0].toUpperCase() +
                            dateFormatted.substring(1),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Календарь питания',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Закрыть',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Planned Section
            Text(
              'Запланировано на этот день',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            if (planEntry != null && planEntry!.recipe != null) ...[
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              planEntry!.recipe!.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (planEntry!.recipe!.source == RecipeSource.ai)
                            const AssistantBadge(isCompact: true),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${planEntry!.recipe!.totalMinutes} мин • ${planEntry!.recipe!.cuisine} кухня',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                onPlanAnother();
                              },
                              child: const Text('Запланировать другое'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                context.push(
                                  '/recipe/${planEntry!.recipe!.id}',
                                );
                              },
                              child: const Text('Рецепт'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.event_busy, color: theme.colorScheme.outline),
                      const SizedBox(width: 12),
                      const Expanded(child: Text('Ничего не запланировано')),
                      FilledButton.tonal(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onPlanAnother();
                        },
                        child: const Text('Запланировать'),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Cooked Section (from History)
            Text(
              'Приготовлено в этот день',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            FutureBuilder<List<CookedEntryWithRecipe>>(
              future: historyDao.allWithRecipes(),
              builder: (context, snapshot) {
                final historyEntries = (snapshot.data ?? const [])
                    .where((h) => h.entry.cookedOn.startsWith(dateStr))
                    .toList();

                if (historyEntries.isEmpty) {
                  return Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'В этот день ещё не было отмечено приготовленных блюд.',
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    for (final item in historyEntries)
                      Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            item.recipe?.title ?? item.entry.recipeId,
                          ),
                          subtitle: Text(
                            item.entry.rating != null
                                ? 'Оценка: ${'★' * item.entry.rating!} (${item.entry.rating}/5)'
                                : 'Без оценки',
                          ),
                          trailing: FilledButton.tonal(
                            onPressed: () {
                              Navigator.of(context).pop();
                              if (item.recipe != null) {
                                context.push('/recipe/${item.recipe!.id}');
                              }
                            },
                            child: const Text('Повторить блюдо'),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}
