import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/preferences/preference_service.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';

/// Screen displaying learned taste profile, reset capability, allergies,
/// and excluded ingredients per ТЗ 6.4, 7.2, 9.1 and task S4-04.
class TastePreferencesScreen extends ConsumerStatefulWidget {
  const TastePreferencesScreen({super.key});

  @override
  ConsumerState<TastePreferencesScreen> createState() =>
      _TastePreferencesScreenState();
}

class _TastePreferencesScreenState
    extends ConsumerState<TastePreferencesScreen> {
  bool _isLoading = true;
  TasteProfile? _profile;
  CompressedProfile? _compressed;
  List<Ingredient> _allIngredients = [];
  Map<String, String> _ingredientNamesById = {};
  int _servingsDefault = 2;

  // Popular allergens quick-picks
  static const List<(String, String)> _popularAllergens = [
    ('Орехи', 'nuts'),
    ('Молоко', 'milk'),
    ('Рыба', 'fish'),
    ('Яйца', 'egg'),
    ('Мёд', 'honey'),
    ('Глютен', 'wheat_flour'),
    ('Цитрусовые', 'citrus'),
    ('Соя', 'soy'),
  ];

  // Popular exclusion quick-picks
  static const List<(String, String)> _popularExclusions = [
    ('Грибы', 'mushrooms'),
    ('Лук', 'onion'),
    ('Чеснок', 'garlic'),
    ('Кинза', 'coriander_herb'),
    ('Майонез', 'mayonnaise'),
    ('Свинина', 'pork'),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefService = ref.read(preferenceServiceProvider);
    final ingDao = ref.read(ingredientDaoProvider);

    final profile = await prefService.getProfile();
    final compressed = await prefService.getCompressedProfile();
    final ingredients = await ingDao.all();

    if (!mounted) return;

    setState(() {
      _profile = profile;
      _compressed = compressed;
      _allIngredients = ingredients;
      _ingredientNamesById = {for (final i in ingredients) i.id: i.name};
      _servingsDefault = profile.servingsDefault;
      _isLoading = false;
    });
  }

  String _formatFeature(String key) {
    switch (key.toLowerCase()) {
      case 'soup':
        return 'Супы';
      case 'main':
        return 'Вторые блюда';
      case 'breakfast':
        return 'Завтраки';
      case 'salad':
        return 'Салаты';
      case 'dessert':
        return 'Десерты';
      case 'snack':
        return 'Закуски';
      case 'drink':
        return 'Напитки';
      case 'baking':
        return 'Выпечка';
      case 'easy':
        return 'Простые блюда';
      case 'medium':
        return 'Средняя сложность';
      case 'hard':
        return 'Сложные блюда';
      case 'russian':
        return 'Русская кухня';
      case 'caucasian':
        return 'Кавказская кухня';
      case 'italian':
        return 'Итальянская кухня';
      case 'asian':
        return 'Азиатская кухня';
    }

    if (_ingredientNamesById.containsKey(key)) {
      final name = _ingredientNamesById[key]!;
      return name.isEmpty ? key : name[0].toUpperCase() + name.substring(1);
    }

    return key.isEmpty ? key : key[0].toUpperCase() + key.substring(1);
  }

  String _displayItemName(String item) {
    if (_ingredientNamesById.containsKey(item)) {
      final name = _ingredientNamesById[item]!;
      return name.isEmpty ? item : name[0].toUpperCase() + name.substring(1);
    }
    return item.isEmpty ? item : item[0].toUpperCase() + item.substring(1);
  }

  Future<void> _resetTasteProfile() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.tasteResetDialogTitle),
        content: Text(l10n.tasteResetDialogMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.tasteResetDialogCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.tasteResetDialogConfirm),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final prefService = ref.read(preferenceServiceProvider);
    await prefService.resetProfile();
    ref.invalidate(preferenceProfileProvider);
    ref.invalidate(compressedProfileProvider);
    ref.invalidate(suggestionsProvider);

    await _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.tasteResetSuccess)));
    }
  }

  Future<void> _removeAllergy(String item) async {
    if (_profile == null) return;
    final updated = List<String>.from(_profile!.allergies)..remove(item);
    final prefService = ref.read(preferenceServiceProvider);
    await prefService.setAllergies(updated);
    ref.invalidate(preferenceProfileProvider);
    ref.invalidate(suggestionsProvider);
    await _loadData();
  }

  Future<void> _addAllergy(String item) async {
    if (_profile == null) return;
    final clean = item.trim().toLowerCase();
    if (clean.isEmpty) return;
    if (_profile!.allergies.contains(clean)) return;

    final updated = List<String>.from(_profile!.allergies)..add(clean);
    final prefService = ref.read(preferenceServiceProvider);
    await prefService.setAllergies(updated);
    ref.invalidate(preferenceProfileProvider);
    ref.invalidate(suggestionsProvider);
    await _loadData();
  }

  Future<void> _removeExclusion(String item) async {
    if (_profile == null) return;
    final updated = List<String>.from(_profile!.excludedIngredients)
      ..remove(item);
    final prefService = ref.read(preferenceServiceProvider);
    await prefService.setExcludedIngredients(updated);
    ref.invalidate(preferenceProfileProvider);
    ref.invalidate(suggestionsProvider);
    await _loadData();
  }

  Future<void> _addExclusion(String item) async {
    if (_profile == null) return;
    final clean = item.trim().toLowerCase();
    if (clean.isEmpty) return;
    if (_profile!.excludedIngredients.contains(clean)) return;

    final updated = List<String>.from(_profile!.excludedIngredients)
      ..add(clean);
    final prefService = ref.read(preferenceServiceProvider);
    await prefService.setExcludedIngredients(updated);
    ref.invalidate(preferenceProfileProvider);
    ref.invalidate(suggestionsProvider);
    await _loadData();
  }

  Future<void> _changeServings(int servings) async {
    final prefService = ref.read(preferenceServiceProvider);
    await prefService.setServingsDefault(servings);
    ref.invalidate(preferenceProfileProvider);
    setState(() {
      _servingsDefault = servings;
    });
  }

  void _openIngredientPicker({
    required String title,
    required List<(String, String)> quickPicks,
    required ValueChanged<String> onSelected,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return _IngredientPickerSheet(
          title: title,
          quickPicks: quickPicks,
          allIngredients: _allIngredients,
          onSelected: (val) {
            Navigator.of(ctx).pop();
            onSelected(val);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.tasteScreenTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final compressed = _compressed;
    final liked = compressed?.topLikedFeatures ?? const [];
    final disliked = compressed?.topDislikedFeatures ?? const [];
    final topDishes = compressed?.topRatedRecipeTitles ?? const [];
    final allergies = _profile?.allergies ?? const [];
    final exclusions = _profile?.excludedIngredients ?? const [];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tasteScreenTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // Explanation Card
          Card(
            color: theme.colorScheme.surfaceContainerHighest,
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 32,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.tasteAboutCard,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Liked features
          Text(
            l10n.tasteLikedSectionTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
          const SizedBox(height: 8),
          if (liked.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                l10n.tasteLikedEmpty,
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: liked.map((e) {
                final weightStr = '+${e.value.toStringAsFixed(2)}';
                return Chip(
                  avatar: const Icon(
                    Icons.thumb_up_alt_outlined,
                    size: 18,
                    color: Colors.green,
                  ),
                  label: Text(
                    '${_formatFeature(e.key)} ($weightStr)',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: Colors.green.shade50,
                  side: BorderSide(color: Colors.green.shade200),
                );
              }).toList(),
            ),
          const SizedBox(height: 20),

          // Disliked features
          Text(
            l10n.tasteDislikedSectionTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.deepOrange.shade800,
            ),
          ),
          const SizedBox(height: 8),
          if (disliked.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                l10n.tasteDislikedEmpty,
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: disliked.map((e) {
                final weightStr = e.value.toStringAsFixed(2);
                return Chip(
                  avatar: const Icon(
                    Icons.thumb_down_alt_outlined,
                    size: 18,
                    color: Colors.deepOrange,
                  ),
                  label: Text(
                    '${_formatFeature(e.key)} ($weightStr)',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: Colors.deepOrange.shade50,
                  side: BorderSide(color: Colors.deepOrange.shade200),
                );
              }).toList(),
            ),
          const SizedBox(height: 20),

          // Top rated dishes
          Text(
            l10n.tasteTopDishesTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (topDishes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                l10n.tasteTopDishesEmpty,
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: topDishes.map((title) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 16),

          // Reset Taste Profile Button
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              onPressed: _resetTasteProfile,
              icon: const Icon(Icons.restart_alt),
              label: Text(
                l10n.tasteResetButton,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // Allergies Section
          Text(
            l10n.tasteAllergiesTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.tasteAllergiesSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
          ),
          const SizedBox(height: 12),
          if (allergies.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                l10n.tasteAllergiesEmpty,
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allergies.map((item) {
                return InputChip(
                  label: Text(
                    _displayItemName(item),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onDeleted: () => _removeAllergy(item),
                  deleteIcon: const Icon(Icons.close, size: 20),
                  backgroundColor: theme.colorScheme.errorContainer,
                  labelStyle: TextStyle(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              onPressed: () {
                _openIngredientPicker(
                  title: l10n.tasteAddAllergyButton,
                  quickPicks: _popularAllergens,
                  onSelected: _addAllergy,
                );
              },
              icon: const Icon(Icons.add),
              label: Text(
                l10n.tasteAddAllergyButton,
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // Exclusions Section
          Text(
            l10n.tasteExclusionsTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.tasteExclusionsSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
          ),
          const SizedBox(height: 12),
          if (exclusions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                l10n.tasteExclusionsEmpty,
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: exclusions.map((item) {
                return InputChip(
                  label: Text(
                    _displayItemName(item),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onDeleted: () => _removeExclusion(item),
                  deleteIcon: const Icon(Icons.close, size: 20),
                );
              }).toList(),
            ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              onPressed: () {
                _openIngredientPicker(
                  title: l10n.tasteAddExclusionButton,
                  quickPicks: _popularExclusions,
                  onSelected: _addExclusion,
                );
              },
              icon: const Icon(Icons.add),
              label: Text(
                l10n.tasteAddExclusionButton,
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // Default Servings Section (ТЗ 7.2)
          Text(
            l10n.tasteServingsTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.tasteServingsSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 56,
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('1')),
                ButtonSegment(value: 2, label: Text('2')),
                ButtonSegment(value: 3, label: Text('3')),
                ButtonSegment(value: 4, label: Text('4')),
                ButtonSegment(value: 6, label: Text('6')),
              ],
              selected: {_servingsDefault},
              onSelectionChanged: (newVal) {
                if (newVal.isNotEmpty) {
                  _changeServings(newVal.first);
                }
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _IngredientPickerSheet extends StatefulWidget {
  final String title;
  final List<(String, String)> quickPicks;
  final List<Ingredient> allIngredients;
  final ValueChanged<String> onSelected;

  const _IngredientPickerSheet({
    required this.title,
    required this.quickPicks,
    required this.allIngredients,
    required this.onSelected,
  });

  @override
  State<_IngredientPickerSheet> createState() => _IngredientPickerSheetState();
}

class _IngredientPickerSheetState extends State<_IngredientPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final filtered = widget.allIngredients
        .where((i) {
          if (_query.isEmpty) return true;
          final q = _query.toLowerCase();
          return i.name.toLowerCase().contains(q) ||
              i.synonyms.any((s) => s.toLowerCase().contains(q)) ||
              i.id.toLowerCase().contains(q);
        })
        .take(20)
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search Field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n.tasteSearchIngredientHint,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            onChanged: (val) {
              setState(() {
                _query = val.trim();
              });
            },
          ),
          const SizedBox(height: 12),

          // Quick Picks (when no search query)
          if (_query.isEmpty && widget.quickPicks.isNotEmpty) ...[
            Text(
              l10n.tastePopularSection,
              style: theme.textTheme.titleSmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.quickPicks.map((pick) {
                return ActionChip(
                  label: Text(
                    pick.$1,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () => widget.onSelected(pick.$2),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],

          // Search Results
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: filtered.length + (_query.isNotEmpty ? 1 : 0),
              itemBuilder: (ctx, idx) {
                if (_query.isNotEmpty && idx == filtered.length) {
                  return ListTile(
                    leading: const Icon(Icons.add_circle_outline),
                    title: Text(l10n.tasteAddCustomItem(_query)),
                    onTap: () => widget.onSelected(_query),
                  );
                }
                final ing = filtered[idx];
                return ListTile(
                  title: Text(
                    ing.name.isEmpty
                        ? ing.id
                        : ing.name[0].toUpperCase() + ing.name.substring(1),
                    style: theme.textTheme.bodyLarge,
                  ),
                  onTap: () => widget.onSelected(ing.id),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
