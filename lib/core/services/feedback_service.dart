import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Centralized feedback service for haptics, undo snackbars, and post-cooking rating prompts (R8-15).
class FeedbackService {
  const FeedbackService._();

  /// Triggers a subtle tactile haptic vibration if supported by platform.
  static Future<void> triggerHaptic([
    HapticFeedbackType type = HapticFeedbackType.light,
  ]) async {
    try {
      switch (type) {
        case HapticFeedbackType.light:
          await HapticFeedback.lightImpact();
        case HapticFeedbackType.medium:
          await HapticFeedback.mediumImpact();
        case HapticFeedbackType.selection:
          await HapticFeedback.selectionClick();
        case HapticFeedbackType.success:
          await HapticFeedback.mediumImpact();
      }
    } catch (_) {
      // Ignore if platform doesn't support haptics
    }
  }

  /// Shows a SnackBar with a prominent "Отменить" (Undo) button for 5 seconds.
  static void showUndoSnackBar(
    BuildContext context, {
    required String message,
    required VoidCallback onUndo,
    Duration duration = const Duration(seconds: 5),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        duration: duration,
        action: SnackBarAction(
          label: 'Отменить',
          onPressed: () {
            triggerHaptic(HapticFeedbackType.medium);
            onUndo();
          },
        ),
      ),
    );
  }

  /// Shows soft post-cooking evaluation dialog ("Как получилось?") with 5 large smileys.
  static Future<int?> showPostCookingRatingPrompt(
    BuildContext context, {
    required String dishTitle,
  }) {
    final theme = Theme.of(context);

    final smileys = [
      (1, '😞', 'Не понравилось'),
      (2, '😐', 'Так себе'),
      (3, '🙂', 'Нормально'),
      (4, '😋', 'Вкусно!'),
      (5, '😍', 'Пальчики оближешь!'),
    ];

    return showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Как получилось?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                dishTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final (star, emoji, tooltip) in smileys)
                    Semantics(
                      button: true,
                      label: tooltip,
                      child: InkWell(
                        onTap: () {
                          triggerHaptic(HapticFeedbackType.selection);
                          Navigator.of(ctx).pop(star);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 48,
                          height: 54,
                          alignment: Alignment.center,
                          child: Text(
                            emoji,
                            style: theme.textTheme.headlineLarge,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: Text('Пропустить', style: theme.textTheme.labelLarge),
            ),
          ],
        );
      },
    );
  }
}

enum HapticFeedbackType { light, medium, selection, success }
