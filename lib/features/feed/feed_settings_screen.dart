import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/adaptive/adaptive_app_bar_title.dart';
import '../../core/feed/feed_settings.dart';
import '../../l10n/app_localizations.dart';
import 'feed_providers.dart';

/// R7-10: feed switches, «Сбросить мои вкусы» and the privacy note.
class FeedSettingsScreen extends ConsumerWidget {
  const FeedSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final settings =
        ref.watch(feedSettingsProvider).value ??
        ref.read(feedSettingsServiceProvider).current;

    Future<void> update(FeedSettings next) async {
      await ref.read(feedSettingsServiceProvider).save(next);
      ref.invalidate(feedSettingsProvider);
    }

    return Scaffold(
      appBar: AppBar(title: AdaptiveAppBarTitle(l10n.feedSettings)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          SwitchListTile(
            key: const Key('feed_switch_holidays'),
            title: Text(l10n.feedSettingsHolidays),
            subtitle: Text(l10n.feedSettingsHolidaysHint),
            value: settings.considerHolidays,
            onChanged: (value) =>
                update(settings.copyWith(considerHolidays: value)),
          ),
          SwitchListTile(
            key: const Key('feed_switch_fasts'),
            title: Text(l10n.feedSettingsFasts),
            subtitle: Text(l10n.feedSettingsFastsHint),
            value: settings.considerFasts,
            onChanged: (value) =>
                update(settings.copyWith(considerFasts: value)),
          ),
          SwitchListTile(
            key: const Key('feed_switch_new'),
            title: Text(l10n.feedSettingsNew),
            subtitle: Text(l10n.feedSettingsNewHint),
            value: settings.showNew,
            onChanged: (value) => update(settings.copyWith(showNew: value)),
          ),
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: OutlinedButton.icon(
                key: const Key('feed_reset_tastes'),
                icon: const Icon(Icons.restart_alt),
                label: Text(
                  l10n.feedResetTastes,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                ),
                onPressed: () => _confirmReset(context, ref),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_outline, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.feedPrivacyTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(l10n.feedPrivacyBody, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.feedResetConfirmTitle),
        content: Text(l10n.feedResetConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.feedResetCancel),
          ),
          FilledButton(
            key: const Key('feed_reset_confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.feedResetConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(feedEventDaoProvider).clear();
    ref.invalidate(feedSnapshotProvider);
    messenger.showSnackBar(SnackBar(content: Text(l10n.feedResetDone)));
  }
}
