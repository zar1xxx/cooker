import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/adaptive/adaptive_app_bar_title.dart';
import '../../core/catalog/cuisine.dart';
import '../../core/catalog/recipe_tags.dart';
import '../../core/feed/feed_ranker.dart';
import '../../core/feed/feed_service.dart';
import '../../core/feed/taste_profile.dart';
import '../../l10n/app_localizations.dart';
import 'feed_card.dart';
import 'feed_providers.dart';
import 'plan_recipe.dart';

/// Moods offered as big buttons (five, per the R7-07 layout).
const List<MoodTag> feedMoods = [
  MoodTag.cozy,
  MoodTag.light,
  MoodTag.hearty,
  MoodTag.onTheRun,
  MoodTag.treatYourself,
];

/// R7-07: «Может понравиться» and up to four more rows.
///
/// Rows: occasion (only before a holiday), mood buttons, world cuisines,
/// from the pantry. Everything is vertical so large fonts never clip.
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  MoodTag? _mood;
  String? _cuisine;

  FeedQuery get _query => FeedQuery(mood: _mood, cuisine: _cuisine);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final snapshot = ref.watch(feedSnapshotProvider(_query));

    return Scaffold(
      appBar: AppBar(
        title: AdaptiveAppBarTitle(l10n.feedScreenTitle),
        actions: [
          IconButton(
            key: const Key('feed_sections_button'),
            icon: const Icon(Icons.grid_view),
            tooltip: l10n.feedSections,
            onPressed: () => context.push('/feed/sections'),
          ),
          IconButton(
            key: const Key('feed_settings_button'),
            icon: const Icon(Icons.tune),
            tooltip: l10n.feedSettings,
            onPressed: () => context.push('/settings/feed'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(feedSnapshotProvider);
          await ref.read(feedSnapshotProvider(_query).future);
        },
        child: snapshot.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _Message(text: l10n.feedLoadError),
          data: (data) => _buildFeed(context, data),
        ),
      ),
    );
  }

  Widget _buildFeed(BuildContext context, FeedSnapshot data) {
    final l10n = AppLocalizations.of(context)!;
    final occasion = data.context.featuredOccasion;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        if (data.aiAdded > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FeedPill(
              icon: Icons.auto_awesome,
              text: l10n.feedAiAdded(data.aiAdded),
            ),
          ),
        _Header(text: l10n.feedMainHeader),
        if (data.main.isEmpty)
          _Message(text: l10n.feedEmpty)
        else
          ..._cards(data, data.main),
        if (occasion != null && data.occasion.isNotEmpty) ...[
          _Header(text: l10n.feedOccasionHeader(occasion.name)),
          if (occasion.hint.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                occasion.hint,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ..._cards(data, data.occasion.take(3)),
        ],
        _Header(text: l10n.feedMoodHeader),
        _ChoiceWrap(
          keyPrefix: 'feed_mood',
          options: {for (final mood in feedMoods) mood.id: mood.titleRu},
          selected: _mood?.id,
          onSelected: (id) => setState(() {
            _mood = id == null ? null : MoodTag.tryFromId(id);
          }),
        ),
        if (data.cuisines.isNotEmpty) ...[
          _Header(text: l10n.feedCuisineHeader),
          _ChoiceWrap(
            keyPrefix: 'feed_cuisine',
            options: {
              for (final code in data.cuisines)
                code: Cuisine.titleForCode(code),
            },
            selected: _cuisine,
            onSelected: (code) => setState(() => _cuisine = code),
          ),
        ],
        if (data.fromPantry.isNotEmpty) ...[
          _Header(text: l10n.feedPantryHeader),
          ..._cards(data, data.fromPantry.take(3)),
        ],
        if (data.toBuy.isNotEmpty) ...[
          _Header(text: l10n.feedToBuyHeader),
          Text(
            l10n.feedToBuyHint,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          for (final entry in data.toBuy)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                l10n.feedToBuyItem(entry.key, entry.value),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
        ],
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: OutlinedButton.icon(
            icon: const Icon(Icons.grid_view),
            label: Text(l10n.feedSections),
            onPressed: () => context.push('/feed/sections'),
          ),
        ),
      ],
    );
  }

  Iterable<Widget> _cards(FeedSnapshot data, Iterable<FeedItem> items) sync* {
    for (final item in items) {
      final id = item.candidate.id;
      yield Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: FeedCard(
          item: item,
          recipe: data.recipes[id],
          onCook: () => _open(id),
          onNotThis: () => _notThis(id),
          onToCalendar: () => _toCalendar(id),
        ),
      );
    }
  }

  Future<void> _open(String recipeId) async {
    await ref.read(feedEventDaoProvider).record(recipeId, FeedEventKind.opened);
    if (!mounted) return;
    await context.push('/recipe/$recipeId');
  }

  Future<void> _notThis(String recipeId) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    await ref
        .read(feedEventDaoProvider)
        .record(recipeId, FeedEventKind.skipped, context: {'screen': 'feed'});
    ref.invalidate(feedSnapshotProvider);
    messenger.showSnackBar(SnackBar(content: Text(l10n.feedSkipped)));
  }

  Future<void> _toCalendar(String recipeId) async {
    await planRecipeOnDate(context: context, ref: ref, recipeId: recipeId);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

/// Big toggle buttons in a wrap; tapping the selected one clears it.
class _ChoiceWrap extends StatelessWidget {
  const _ChoiceWrap({
    required this.keyPrefix,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String keyPrefix;
  final Map<String, String> options;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in options.entries)
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: entry.key == selected
                ? FilledButton(
                    key: Key('${keyPrefix}_${entry.key}'),
                    onPressed: () => onSelected(null),
                    child: Text(entry.value),
                  )
                : OutlinedButton(
                    key: Key('${keyPrefix}_${entry.key}'),
                    onPressed: () => onSelected(entry.key),
                    child: Text(entry.value),
                  ),
          ),
      ],
    );
  }
}
