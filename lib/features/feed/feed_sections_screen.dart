import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/adaptive/adaptive_app_bar_title.dart';
import '../../core/catalog/dish_group.dart';
import '../../core/catalog/recipe_tags.dart';
import '../../core/feed/feed_service.dart';
import '../../core/feed/taste_profile.dart';
import '../../l10n/app_localizations.dart';
import 'feed_card.dart';
import 'feed_providers.dart';
import 'plan_recipe.dart';

IconData dishGroupIcon(DishGroup group) {
  switch (group) {
    case DishGroup.baking:
      return Icons.bakery_dining;
    case DishGroup.meat:
      return Icons.kebab_dining;
    case DishGroup.fishSeafood:
      return Icons.set_meal;
    case DishGroup.vegetable:
      return Icons.eco;
    case DishGroup.soup:
      return Icons.soup_kitchen;
    case DishGroup.porridgeSide:
      return Icons.rice_bowl;
    case DishGroup.saladSnack:
      return Icons.local_dining;
    case DishGroup.eggDairy:
      return Icons.egg_alt;
    case DishGroup.dessert:
      return Icons.cake;
    case DishGroup.beverage:
      return Icons.local_cafe;
    case DishGroup.preserves:
      return Icons.kitchen;
  }
}

/// R7-07: the list of dish groups with the number of dishes in each.
class FeedSectionsScreen extends ConsumerWidget {
  const FeedSectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final snapshot = ref.watch(feedSnapshotProvider(const FeedQuery()));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: AdaptiveAppBarTitle(l10n.feedSections)),
      body: snapshot.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.feedLoadError)),
        data: (data) => ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            for (final group in DishGroup.values)
              ListTile(
                key: Key('feed_section_${group.id}'),
                minVerticalPadding: 12,
                leading: Icon(
                  dishGroupIcon(group),
                  size: 32,
                  color: theme.colorScheme.primary,
                ),
                title: Text(group.titleRu, style: theme.textTheme.titleMedium),
                subtitle: Text(
                  l10n.feedSectionCount(data.groupCounts[group.id] ?? 0),
                  style: theme.textTheme.bodyMedium,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/feed/section/${group.id}'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Dishes of one group with one row of diet chips.
class FeedSectionScreen extends ConsumerStatefulWidget {
  const FeedSectionScreen({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<FeedSectionScreen> createState() => _FeedSectionScreenState();
}

class _FeedSectionScreenState extends ConsumerState<FeedSectionScreen> {
  DietaryTag? _diet;

  static const List<DietaryTag> _diets = [
    DietaryTag.vegetarian,
    DietaryTag.vegan,
    DietaryTag.lenten,
    DietaryTag.lowCalorie,
    DietaryTag.glutenFree,
    DietaryTag.lactoseFree,
    DietaryTag.highProtein,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final group = DishGroup.tryFromId(widget.groupId);
    final diet = _diet;
    final query = FeedQuery(
      groupId: widget.groupId,
      requiredTags: diet == null ? const <String>{} : {'dietary:${diet.id}'},
    );
    final snapshot = ref.watch(feedSnapshotProvider(query));

    return Scaffold(
      appBar: AppBar(
        title: AdaptiveAppBarTitle(group?.titleRu ?? l10n.feedSections),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    key: const Key('feed_diet_all'),
                    label: Text(l10n.feedAllDiets),
                    selected: diet == null,
                    onSelected: (_) => setState(() => _diet = null),
                  ),
                ),
                for (final tag in _diets)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      key: Key('feed_diet_${tag.id}'),
                      label: Text(tag.titleRu),
                      selected: diet == tag,
                      onSelected: (_) => setState(() => _diet = tag),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: snapshot.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(child: Text(l10n.feedLoadError)),
              data: (data) {
                if (data.main.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(
                        l10n.feedSectionEmpty,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: data.main.length,
                  itemBuilder: (context, index) {
                    final item = data.main[index];
                    final id = item.candidate.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: FeedCard(
                        item: item,
                        recipe: data.recipes[id],
                        onCook: () => _open(id),
                        onNotThis: () => _notThis(id),
                        onToCalendar: () => planRecipeOnDate(
                          context: context,
                          ref: ref,
                          recipeId: id,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _open(String recipeId) async {
    await ref.read(feedEventDaoProvider).record(recipeId, FeedEventKind.opened);
    if (!mounted) return;
    await context.push('/recipe/$recipeId');
  }

  Future<void> _notThis(String recipeId) async {
    await ref
        .read(feedEventDaoProvider)
        .record(
          recipeId,
          FeedEventKind.skipped,
          context: {'screen': 'section'},
        );
    ref.invalidate(feedSnapshotProvider);
  }
}
