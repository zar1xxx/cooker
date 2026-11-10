import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Reusable badge displaying «От помощника» for AI-generated recipes and suggestions.
/// Uses `tertiaryContainer` background and `onTertiaryContainer` foreground
/// guaranteeing WCAG AA contrast >= 4.5:1.
class AssistantBadge extends StatelessWidget {
  const AssistantBadge({super.key, this.isCompact = false});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 10,
        vertical: isCompact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome,
            size: isCompact ? 14 : 18,
            color: theme.colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              l10n.recipeFromAssistant,
              style:
                  (isCompact
                          ? theme.textTheme.labelSmall
                          : theme.textTheme.bodyMedium)
                      ?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
