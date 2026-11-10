import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/db/daos/history_dao.dart';
import '../../core/providers.dart';
import '../../core/services/feedback_service.dart';
import '../../core/widgets/assistant_badge.dart';
import '../../core/db/enums.dart';

/// Bottom sheet showing full details for a history cooked entry (R8-13).
class HistoryDetailsSheet extends ConsumerStatefulWidget {
  const HistoryDetailsSheet({
    super.key,
    required this.item,
    required this.onDeleted,
  });

  final CookedEntryWithRecipe item;
  final VoidCallback onDeleted;

  static Future<void> show(
    BuildContext context, {
    required CookedEntryWithRecipe item,
    required VoidCallback onDeleted,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => HistoryDetailsSheet(item: item, onDeleted: onDeleted),
    );
  }

  @override
  ConsumerState<HistoryDetailsSheet> createState() =>
      _HistoryDetailsSheetState();
}

class _HistoryDetailsSheetState extends ConsumerState<HistoryDetailsSheet> {
  late int _rating;
  late TextEditingController _noteController;
  bool _isSavingNote = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.item.entry.rating ?? 5;
    _noteController = TextEditingController(text: widget.item.entry.note ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _updateRating(int newRating) async {
    setState(() => _rating = newRating);
    await FeedbackService.triggerHaptic(HapticFeedbackType.selection);
    await ref
        .read(historyDaoProvider)
        .updateEntry(widget.item.entry.id, rating: newRating);
    ref.invalidate(historyEntriesProvider);
    ref.invalidate(historyMonthSummaryProvider);
  }

  Future<void> _saveNote() async {
    setState(() => _isSavingNote = true);
    await ref
        .read(historyDaoProvider)
        .updateEntry(widget.item.entry.id, note: _noteController.text.trim());
    ref.invalidate(historyEntriesProvider);
    if (mounted) {
      setState(() => _isSavingNote = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Заметка сохранена')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entry = widget.item.entry;
    final recipe = widget.item.recipe;
    final title = recipe?.title ?? entry.recipeId;

    DateTime? cookedDate;
    try {
      cookedDate = DateTime.parse(entry.cookedOn);
    } catch (_) {}
    final dateFormatted = cookedDate != null
        ? DateFormat('d MMMM yyyy, EEEE', 'ru').format(cookedDate)
        : entry.cookedOn;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormatted,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (recipe?.source == RecipeSource.ai)
                const AssistantBadge(isCompact: true),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Закрыть',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Rating section (1-5 stars)
          Text(
            'Оценка блюда',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starVal = index + 1;
              final filled = starVal <= _rating;
              return IconButton(
                iconSize: 36,
                icon: Icon(
                  filled ? Icons.star : Icons.star_border,
                  color: filled
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.outlineVariant,
                ),
                tooltip: '$starVal из 5',
                onPressed: () => _updateRating(starVal),
              );
            }),
          ),
          const SizedBox(height: 16),

          // Note field
          Text(
            'Заметка к блюду',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Например: «пересолила», «детям очень понравилось»',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: IconButton(
                icon: _isSavingNote
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                tooltip: 'Сохранить заметку',
                onPressed: _saveNote,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action buttons: "Приготовить снова" & "Удалить"
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onDeleted();
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Удалить'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error),
                  minimumSize: const Size(0, 48),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (recipe != null) {
                      context.push('/recipe/${recipe.id}');
                    }
                  },
                  icon: const Icon(Icons.replay),
                  label: const Text('Приготовить снова'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
