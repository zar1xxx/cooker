import '../../core/ai/ai_service.dart';
import '../../core/matching/recipe_scorer.dart';

sealed class FeedCardItem {
  const FeedCardItem();
}

class CatalogCardItem extends FeedCardItem {
  final ScoredRecipe scored;
  const CatalogCardItem(this.scored);

  @override
  String toString() => 'CatalogCardItem(${scored.entry.recipe.title})';
}

class AiCardItem extends FeedCardItem {
  final AiDishSuggestion suggestion;
  const AiCardItem(this.suggestion);

  @override
  String toString() => 'AiCardItem(${suggestion.title})';
}

class AiPlaceholderCardItem extends FeedCardItem {
  final int slotIndex;
  const AiPlaceholderCardItem(this.slotIndex);

  @override
  String toString() => 'AiPlaceholderCardItem(slot: $slotIndex)';
}

/// Coordinates the infinite feed (R8-08):
/// - Initial list built immediately from catalog without waiting for AI (first 3 cards from catalog).
/// - Subsequent pages append 9 catalog items + 1-2 AI suggestions.
/// - AI cards placed at positions 4, 8, 12, 16...
/// - At most 1 concurrent AI request; placeholders collapse gracefully on error/duplicate.
/// - Offline mode runs purely on catalog with 0 placeholders.
class FeedCoordinator {
  FeedCoordinator({
    required this.allCatalogRecipes,
    required this.isAiAvailable,
    required this.fetchAiDishes,
    this.existingCatalogTitles = const {},
    this.onItemsUpdated,
  });

  final List<ScoredRecipe> allCatalogRecipes;
  final bool isAiAvailable;
  final Future<List<AiDishSuggestion>> Function({
    required List<String> alreadyShownTitles,
  })
  fetchAiDishes;
  final Set<String> existingCatalogTitles;
  final void Function()? onItemsUpdated;

  final List<FeedCardItem> items = [];
  int _catalogIndex = 0;
  bool _isAiRequestInProgress = false;
  final List<AiDishSuggestion> _aiPool = [];
  final Set<String> _shownTitles = {};

  bool get isAiRequestInProgress => _isAiRequestInProgress;
  int get catalogItemsRemaining => allCatalogRecipes.length - _catalogIndex;

  /// Initializes the first page of cards.
  void initialize() {
    items.clear();
    _catalogIndex = 0;
    _shownTitles.clear();
    _aiPool.clear();
    _loadNextPage();
    onItemsUpdated?.call();
  }

  /// Triggers pagination when remaining items until end of feed <= 6.
  void onScrollNearEnd(int remainingItems) {
    if (remainingItems <= 6 && catalogItemsRemaining > 0) {
      _loadNextPage();
      onItemsUpdated?.call();
    }
  }

  void _loadNextPage() {
    int catalogAdded = 0;
    while (_catalogIndex < allCatalogRecipes.length && catalogAdded < 9) {
      final next1BasedPos = items.length + 1;
      if (isAiAvailable && next1BasedPos % 4 == 0 && _canInsertAiSlot()) {
        _insertAiSlot();
      } else {
        final scored = allCatalogRecipes[_catalogIndex++];
        items.add(CatalogCardItem(scored));
        _shownTitles.add(scored.entry.recipe.normalizedTitle);
        catalogAdded++;
      }
    }

    if (isAiAvailable &&
        items.length >= 3 &&
        (items.length + 1) % 4 == 0 &&
        _canInsertAiSlot() &&
        catalogItemsRemaining > 0) {
      _insertAiSlot();
    }
  }

  int get _placeholderCount => items.whereType<AiPlaceholderCardItem>().length;

  bool _canInsertAiSlot() {
    if (!isAiAvailable) return false;
    if (_aiPool.isNotEmpty) return true;
    return _placeholderCount < 2;
  }

  void _insertAiSlot() {
    final nextSlotIdx = items.length;
    if (_aiPool.isNotEmpty) {
      final suggestion = _aiPool.removeAt(0);
      items.add(AiCardItem(suggestion));
      _shownTitles.add(suggestion.title.toLowerCase().trim());
    } else if (_placeholderCount < 2) {
      items.add(AiPlaceholderCardItem(nextSlotIdx));
      if (!_isAiRequestInProgress) {
        _triggerAiGeneration();
      }
    }
  }

  Future<void> _triggerAiGeneration() async {
    if (_isAiRequestInProgress || !isAiAvailable) return;
    _isAiRequestInProgress = true;

    try {
      final results = await fetchAiDishes(
        alreadyShownTitles: _shownTitles.toList(),
      );

      final validDishes = <AiDishSuggestion>[];
      for (final dish in results) {
        final norm = dish.title.toLowerCase().trim();
        if (norm.isEmpty) continue;
        if (existingCatalogTitles.contains(norm)) continue;
        if (_shownTitles.contains(norm)) continue;
        validDishes.add(dish);
      }

      // Fill existing placeholders in order
      while (validDishes.isNotEmpty && _placeholderCount > 0) {
        final firstPlaceholderIdx = items.indexWhere(
          (it) => it is AiPlaceholderCardItem,
        );
        if (firstPlaceholderIdx == -1) break;
        final dish = validDishes.removeAt(0);
        items[firstPlaceholderIdx] = AiCardItem(dish);
        _shownTitles.add(dish.title.toLowerCase().trim());
      }

      // Any remaining placeholders that were not filled collapse smoothly
      items.removeWhere((it) => it is AiPlaceholderCardItem);

      // Remaining valid dishes stay in pool for next slots
      _aiPool.addAll(validDishes);
    } catch (_) {
      // Smooth collapse on error without crashing or leaving placeholders
      items.removeWhere((it) => it is AiPlaceholderCardItem);
    } finally {
      _isAiRequestInProgress = false;
      onItemsUpdated?.call();
    }
  }
}
