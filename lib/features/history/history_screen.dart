import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/db/daos/history_dao.dart';
import '../../core/db/enums.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final historyAsync = ref.watch(historyEntriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.screenHistoryTitle)),
      body: historyAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return _EmptyHistoryView(l10n: l10n);
          }
          return _HistoryListView(entries: entries, l10n: l10n);
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
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 16),
                Text(
                  'Не удалось загрузить историю',
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 56,
                  child: FilledButton(
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

class _EmptyHistoryView extends StatelessWidget {
  const _EmptyHistoryView({required this.l10n});

  final AppLocalizations l10n;

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
            SizedBox(
              height: 56,
              child: FilledButton.icon(
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
          ],
        ),
      ),
    );
  }
}

class _HistoryListView extends StatelessWidget {
  const _HistoryListView({required this.entries, required this.l10n});

  final List<CookedEntryWithRecipe> entries;
  final AppLocalizations l10n;

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

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final dateKey = grouped.keys.elementAt(index);
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
              (item) => _HistoryEntryCard(item: item, l10n: l10n),
            ),
          ],
        );
      },
    );
  }
}

class _HistoryEntryCard extends StatelessWidget {
  const _HistoryEntryCard({required this.item, required this.l10n});

  final CookedEntryWithRecipe item;
  final AppLocalizations l10n;

  String _dishTypeName(DishType type) {
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
        return Icons.egg;
      case DishType.snack:
        return Icons.lunch_dining;
      case DishType.baking:
        return Icons.bakery_dining;
      case DishType.dessert:
        return Icons.cake;
      case DishType.drink:
        return Icons.local_drink;
      case DishType.preserve:
        return Icons.inventory_2;
    }
  }

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
      child: InkWell(
        onTap: () => context.push('/recipe/${entry.recipeId}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Dish type & cooking time
              Row(
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
                          Icon(
                            _dishTypeIcon(recipe.dishType),
                            size: 18,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _dishTypeName(recipe.dishType),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
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
                        Text(
                          l10n.historyCookingTime(recipe.totalMinutes),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
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
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              // Rating row
              Row(
                children: [
                  if (rating != null) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (starIdx) {
                        final filled = starIdx < rating;
                        return Icon(
                          filled ? Icons.star : Icons.star_border,
                          size: 24,
                          color: filled ? Colors.amber[700] : Colors.grey[400],
                        );
                      }),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.historyRatingStars(rating),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ] else ...[
                    Text(
                      l10n.historyRatingUnrated,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const Spacer(),
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
                          Text(
                            l10n.historyWouldRepeat,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
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

              // Cook again / View recipe button (min height 56 dp)
              SizedBox(
                height: 56,
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
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
                  onPressed: () => context.push('/recipe/${entry.recipeId}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
