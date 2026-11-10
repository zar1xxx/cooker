import 'package:flutter/material.dart';

import '../db/enums.dart';

enum ChipExplanationKind {
  difficulty,
  totalTime,
  cuisine,
  dishGroup,
  assistant,
  dietTag,
  planned,
}

/// Rich bottom sheet explaining badges and chips in plain language (R8-13).
class ChipExplanationSheet extends StatelessWidget {
  const ChipExplanationSheet({
    super.key,
    required this.kind,
    required this.title,
    required this.description,
    this.reasons = const [],
    this.filterActionLabel,
    this.onFilterAction,
  });

  final ChipExplanationKind kind;
  final String title;
  final String description;
  final List<String> reasons;
  final String? filterActionLabel;
  final VoidCallback? onFilterAction;

  static Future<void> show(
    BuildContext context, {
    required ChipExplanationKind kind,
    required String title,
    required String description,
    List<String> reasons = const [],
    String? filterActionLabel,
    VoidCallback? onFilterAction,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ChipExplanationSheet(
        kind: kind,
        title: title,
        description: description,
        reasons: reasons,
        filterActionLabel: filterActionLabel,
        onFilterAction: onFilterAction,
      ),
    );
  }

  static Future<void> showForDifficulty(
    BuildContext context, {
    required Difficulty difficulty,
    List<String> reasons = const [],
    VoidCallback? onShowSimilar,
  }) {
    String desc;
    switch (difficulty) {
      case Difficulty.easy:
        desc = 'Блюдо простое: мало шагов приготовления, минимум ингредиентов и нет сложных техник вроде замешивания и раскатки теста.';
      case Difficulty.medium:
        desc = 'Блюдо средней сложности: требует подготовки нескольких ингредиентов или параллельных процессов (например, варка и пассерование).';
      case Difficulty.hard:
        desc = 'Сложное блюдо: требует повышенного внимания, длительного активного времени или продвинутых кулинарных техник.';
    }

    final diffTitle = switch (difficulty) {
      Difficulty.easy => 'Сложность: Просто',
      Difficulty.medium => 'Сложность: Средне',
      Difficulty.hard => 'Сложность: Сложно',
    };

    return show(
      context,
      kind: ChipExplanationKind.difficulty,
      title: diffTitle,
      description: desc,
      reasons: reasons,
      filterActionLabel: 'Показать похожие по сложности',
      onFilterAction: onShowSimilar,
    );
  }

  static Future<void> showForAssistant(
    BuildContext context, {
    VoidCallback? onShowSimilar,
  }) {
    return show(
      context,
      kind: ChipExplanationKind.assistant,
      title: 'От помощника',
      description: 'Этот рецепт подобран или создан умным помощником (ИИ). Помощник учитывает продукты, которые есть у вас дома, время дня, праздники и ваши вкусовые предпочтения, стараясь не повторять недавние блюда.',
      filterActionLabel: 'Показать все блюда от помощника',
      onFilterAction: onShowSimilar,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                child: Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Закрыть',
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          // Reasons list (from R8-10 DifficultyCalculator)
          if (reasons.isNotEmpty) ...[
            Text(
              'Почему такая сложность:',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            for (final reason in reasons)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(reason, style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
          ],

          // Action button (e.g. "Показать похожие")
          if (filterActionLabel != null && onFilterAction != null)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.tonal(
                onPressed: () {
                  Navigator.of(context).pop();
                  onFilterAction!();
                },
                child: Text(
                  filterActionLabel!,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
