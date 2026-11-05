import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../app/app_images.dart';
import '../../core/db/app_database.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';

extension _StringCapitalize on String {
  String capitalize() => isEmpty ? this : this[0].toUpperCase() + substring(1);
}

class PantryScreen extends ConsumerStatefulWidget {
  const PantryScreen({super.key});

  @override
  ConsumerState<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends ConsumerState<PantryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final text = _searchController.text;
      if (text != _searchQuery) {
        setState(() {
          _searchQuery = text;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleVoiceInput() async {
    final l10n = AppLocalizations.of(context)!;
    if (_isListening) {
      await _speech.stop();
      setState(() {
        _isListening = false;
      });
      return;
    }

    try {
      final available = await _speech.initialize(
        onError: (_) {
          if (mounted) {
            setState(() => _isListening = false);
            _showVoiceError(l10n.pantryVoiceUnavailable);
          }
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
      );

      if (available && mounted) {
        setState(() => _isListening = true);
        await _speech.listen(
          onResult: (result) {
            if (mounted) {
              _searchController.text = result.recognizedWords;
            }
          },
        );
      } else if (mounted) {
        _showVoiceError(l10n.pantryVoiceUnavailable);
      }
    } catch (_) {
      if (mounted) {
        _showVoiceError(l10n.pantryVoiceUnavailable);
      }
    }
  }

  void _showVoiceError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(color: Theme.of(context).colorScheme.onError),
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _addCustomIngredient(String name) async {
    final dao = ref.read(ingredientDaoProvider);
    final ingredient = await dao.addCustom(name);
    await ref.read(pantryProvider.notifier).toggle(ingredient.id);
    _searchController.clear();
  }

  void _openCategorySheet(
    BuildContext context,
    IngredientCategory category,
    Set<String> availableIds,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (bottomSheetContext) {
        return _CategoryIngredientsSheet(
          category: category,
          availableIds: availableIds,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final pantryAsync = ref.watch(pantryProvider);
    final availableIds = pantryAsync.value ?? const <String>{};
    final suggestionsAsync = ref.watch(suggestionsProvider);
    final dishCount = suggestionsAsync.value?.totalCount ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.screenPantryTitle)),
      body: Column(
        children: [
          // Search & Voice input bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: theme.textTheme.bodyLarge,
                    decoration: InputDecoration(
                      hintText: l10n.pantrySearchHint,
                      prefixIcon: const Icon(Icons.search, size: 28),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 28),
                              tooltip: l10n.pantryClearSearch,
                              onPressed: _searchController.clear,
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Semantics(
                  button: true,
                  label: l10n.pantryVoiceSearch,
                  child: SizedBox(
                    height: 56,
                    child: FilledButton.tonalIcon(
                      onPressed: _toggleVoiceInput,
                      icon: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                        size: 28,
                      ),
                      label: Text(
                        l10n.pantryVoiceSearch,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main body: Search results OR (Frequent + Categories)
          Expanded(
            child: _searchQuery.isNotEmpty
                ? _buildSearchResults(theme, l10n, availableIds)
                : _buildCategoriesView(theme, l10n, availableIds),
          ),

          // Bottom Action: «Показать блюда (N)»
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: () => context.push('/suggestions'),
                  icon: const Icon(Icons.restaurant_menu, size: 28),
                  label: Text(
                    l10n.pantryShowDishes(dishCount),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(
    ThemeData theme,
    AppLocalizations l10n,
    Set<String> availableIds,
  ) {
    final searchAsync = ref.watch(ingredientSearchProvider(_searchQuery));

    return searchAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          Center(child: Text(e.toString(), style: theme.textTheme.bodyLarge)),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.pantryNothingFound,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () => _addCustomIngredient(_searchQuery),
                      icon: const Icon(Icons.add, size: 28),
                      label: Text(
                        l10n.pantryAddCustom(_searchQuery.trim()),
                        style: theme.textTheme.bodyLarge,
                      ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = items[index];
            final isAvailable = availableIds.contains(item.id);

            return _IngredientCard(
              ingredient: item,
              isSelected: isAvailable,
              onToggle: () {
                ref.read(pantryProvider.notifier).toggle(item.id);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCategoriesView(
    ThemeData theme,
    AppLocalizations l10n,
    Set<String> availableIds,
  ) {
    final frequentAsync = ref.watch(frequentIngredientsProvider);
    final categories = ref.watch(categoriesProvider);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // «Часто выбираете»
        Text(
          l10n.pantryFrequentSection,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        frequentAsync.when(
          loading: () => const SizedBox(
            height: 56,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => const SizedBox.shrink(),
          data: (frequent) {
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in frequent)
                  _FrequentChip(
                    ingredient: item,
                    isSelected: availableIds.contains(item.id),
                    onToggle: () {
                      ref.read(pantryProvider.notifier).toggle(item.id);
                    },
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),

        // «Категории продуктов»
        Text(
          l10n.pantryCategoriesSection,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: categories.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: (1.35 / MediaQuery.textScalerOf(context).scale(1))
                .clamp(0.8, 1.35),
          ),
          itemBuilder: (context, index) {
            final category = categories[index];
            return _CategoryTile(
              category: category,
              onTap: () => _openCategorySheet(context, category, availableIds),
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _FrequentChip extends StatelessWidget {
  const _FrequentChip({
    required this.ingredient,
    required this.isSelected,
    required this.onToggle,
  });

  final Ingredient ingredient;
  final bool isSelected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FilterChip(
      selected: isSelected,
      onSelected: (_) => onToggle(),
      label: Text(
        ingredient.name.capitalize(),
        style: theme.textTheme.bodyLarge?.copyWith(
          color: isSelected
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      avatar: isSelected
          ? Icon(Icons.check, color: theme.colorScheme.onPrimary, size: 20)
          : null,
      selectedColor: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      visualDensity: VisualDensity.standard,
    );
  }
}

class _CategoryTile extends ConsumerWidget {
  const _CategoryTile({required this.category, required this.onTap});

  final IngredientCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final pantryAsync = ref.watch(pantryProvider);
    final availableIds = pantryAsync.value ?? const <String>{};
    final ingredientsAsync = ref.watch(
      ingredientsByCategoryProvider(category.id),
    );

    final count = ingredientsAsync.maybeWhen(
      data: (items) => items.where((i) => availableIds.contains(i.id)).length,
      orElse: () => 0,
    );

    final hasSelected = count > 0;

    return Semantics(
      button: true,
      label:
          '${category.name}, ${hasSelected ? l10n.pantrySelectedCount(count) : ""}',
      child: Material(
        color: hasSelected
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppCategoryIcon(
                      categoryId: category.id,
                      size: 40,
                      semanticLabel: category.name,
                    ),
                    if (hasSelected)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$count',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      category.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: hasSelected
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurface,
                      ),
                    ),
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

class _IngredientCard extends StatelessWidget {
  const _IngredientCard({
    required this.ingredient,
    required this.isSelected,
    required this.onToggle,
  });

  final Ingredient ingredient;
  final bool isSelected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label:
          '${ingredient.name.capitalize()}, ${isSelected ? "выбрано" : "не выбрано"}',
      child: Material(
        color: isSelected
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  size: 28,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    ingredient.name.capitalize(),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface,
                    ),
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

class _CategoryIngredientsSheet extends ConsumerWidget {
  const _CategoryIngredientsSheet({
    required this.category,
    required this.availableIds,
  });

  final IngredientCategory category;
  final Set<String> availableIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final pantryAsync = ref.watch(pantryProvider);
    final currentAvailable = pantryAsync.value ?? availableIds;
    final ingredientsAsync = ref.watch(
      ingredientsByCategoryProvider(category.id),
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Top bar with title and close button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  AppCategoryIcon(
                    categoryId: category.id,
                    size: 40,
                    semanticLabel: category.name,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      category.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 28),
                    tooltip: l10n.pantryClose,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(),

            // Ingredients list
            Expanded(
              child: ingredientsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text(e.toString(), style: theme.textTheme.bodyLarge),
                ),
                data: (items) {
                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isSelected = currentAvailable.contains(item.id);
                      return _IngredientCard(
                        ingredient: item,
                        isSelected: isSelected,
                        onToggle: () {
                          ref.read(pantryProvider.notifier).toggle(item.id);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
