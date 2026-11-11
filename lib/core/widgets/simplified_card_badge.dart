import 'package:flutter/material.dart';

import 'chip_explanation_sheet.dart';

/// Marker for recipes whose steps are still short (R9-04).
///
/// Shown on the card and on the recipe screen when `recipes.quality` is
/// `template`. Tapping explains in plain words what it means.
class SimplifiedCardBadge extends StatelessWidget {
  const SimplifiedCardBadge({super.key, this.isCompact = false});

  /// Text of the badge.
  static const label = 'Упрощённая карточка';

  /// Text of the explanation sheet.
  static const explanation =
      'Шаги для этого блюда описаны кратко. Продукты и время указаны верно, '
      'но подробный рецепт мы ещё пишем. Если что-то непонятно, откройте '
      'блюдо и спросите помощника.';

  /// `true` for the recipes that carry the «template» marker.
  static bool appliesTo(String? quality) => quality == 'template';

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = isCompact
        ? theme.textTheme.labelSmall
        : theme.textTheme.bodyMedium;

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => ChipExplanationSheet.show(
            context,
            kind: ChipExplanationKind.dishGroup,
            title: label,
            description: explanation,
          ),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 8 : 10,
              vertical: isCompact ? 4 : 6,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.short_text,
                  size: isCompact ? 14 : 18,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    style: style?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
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
