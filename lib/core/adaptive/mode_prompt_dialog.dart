import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import 'adaptive_provider.dart';
import 'ui_profile.dart';

/// Shows a suggestion dialog to switch between Simple and Full modes (R8-17).
Future<void> showModeSuggestionPrompt(
  BuildContext context,
  WidgetRef ref, {
  required bool toFull,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final service = ref.read(uiProfileServiceProvider);
  final notifier = ref.read(uiProfileProvider.notifier);

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(
          toFull ? l10n.modePromptTryFullTitle : l10n.modePromptTrySimpleTitle,
        ),
        content: Text(
          toFull ? l10n.modePromptTryFullDesc : l10n.modePromptTrySimpleDesc,
        ),
        actions: [
          TextButton(
            key: const Key('btn_mode_prompt_never'),
            onPressed: () {
              service.recordModePromptPresented(
                now: DateTime.now(),
                suppressForever: true,
              );
              Navigator.of(ctx).pop();
            },
            child: Text(l10n.modePromptNever),
          ),
          TextButton(
            key: const Key('btn_mode_prompt_later'),
            onPressed: () {
              service.recordModePromptPresented(
                now: DateTime.now(),
                suppressForever: false,
              );
              Navigator.of(ctx).pop();
            },
            child: Text(l10n.modePromptLater),
          ),
          FilledButton(
            key: const Key('btn_mode_prompt_switch'),
            onPressed: () {
              notifier.setMode(toFull ? UiMode.full : UiMode.simple);
              service.recordModePromptPresented(
                now: DateTime.now(),
                suppressForever: false,
              );
              Navigator.of(ctx).pop();
            },
            child: Text(l10n.modePromptSwitch),
          ),
        ],
      );
    },
  );
}
