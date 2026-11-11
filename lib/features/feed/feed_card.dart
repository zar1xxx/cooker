import 'package:flutter/material.dart';

import '../../core/catalog/dish_group.dart';
import '../../core/db/app_database.dart';
import '../../core/db/enums.dart';
import '../../core/feed/feed_ranker.dart';
import '../../core/widgets/assistant_badge.dart';
import '../../core/widgets/simplified_card_badge.dart';
import '../../l10n/app_localizations.dart';

/// One large feed card: title, time, reason and two clear actions (R7-07).
class FeedCard extends StatelessWidget {
  const FeedCard({
    super.key,
    required this.item,
    required this.recipe,
    required this.onCook,
    required this.onNotThis,
    required this.onToCalendar,
  });

  final FeedItem item;
  final Recipe? recipe;
  final VoidCallback onCook;
  final VoidCallback onNotThis;
  final VoidCallback onToCalendar;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final candidate = item.candidate;
    final group = DishGroup.tryFromId(candidate.groupId);
    final meta = [
      l10n.dishesMinutes(candidate.totalMinutes),
      if (group != null) group.titleRu,
    ].join(' · ');
    final source = recipe?.source;

    return Card(
      key: Key('feed_card_${candidate.id}'),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onCook,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (item.isExploration ||
                  source == RecipeSource.ai ||
                  recipe?.quality == 'template')
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (item.isExploration)
                        FeedPill(
                          icon: Icons.explore_outlined,
                          text: l10n.feedTryNew,
                        ),
                      if (source == RecipeSource.ai)
                        const AssistantBadge(isCompact: true),
                      if (recipe?.quality == 'template')
                        const SimplifiedCardBadge(isCompact: true),
                    ],
                  ),
                ),
              Text(
                candidate.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                meta,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 22,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(item.reason, style: theme.textTheme.bodyLarge),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: FilledButton.icon(
                      key: Key('feed_cook_${candidate.id}'),
                      icon: const Icon(Icons.restaurant_menu),
                      label: Text(l10n.feedCook),
                      onPressed: onCook,
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: OutlinedButton.icon(
                      key: Key('feed_not_this_${candidate.id}'),
                      icon: const Icon(Icons.thumb_down_alt_outlined),
                      label: Text(l10n.feedNotThis),
                      onPressed: onNotThis,
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: TextButton.icon(
                      key: Key('feed_calendar_${candidate.id}'),
                      icon: const Icon(Icons.calendar_month),
                      label: Text(l10n.feedToCalendar),
                      onPressed: onToCalendar,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small rounded label that wraps its text instead of overflowing.
class FeedPill extends StatelessWidget {
  const FeedPill({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSecondaryContainer),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
