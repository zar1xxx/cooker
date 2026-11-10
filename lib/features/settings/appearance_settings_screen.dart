import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/adaptive/adaptive_app_bar_title.dart';
import '../../core/adaptive/adaptive_provider.dart';
import '../../core/adaptive/adaptive_spec.dart';
import '../../core/adaptive/ui_profile.dart';
import '../../l10n/app_localizations.dart';

/// Screen managing interface appearance and mode switching (R8-17 / D-057).
class AppearanceSettingsScreen extends ConsumerWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(uiProfileProvider);
    final notifier = ref.read(uiProfileProvider.notifier);
    final adaptive = context.adaptive;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: AdaptiveAppBarTitle(l10n.appearanceTitle)),
      body: ListView(
        padding: adaptive.cardPadding,
        children: [
          // Section 1: Mode
          Text(
            l10n.appearanceModeSection,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<UiMode>(
              segments: [
                ButtonSegment<UiMode>(
                  value: UiMode.simple,
                  label: Text(l10n.modeSimpleTitle),
                  icon: const Icon(Icons.accessibility_new),
                ),
                ButtonSegment<UiMode>(
                  value: UiMode.full,
                  label: Text(l10n.modeFullTitle),
                  icon: const Icon(Icons.tune),
                ),
              ],
              selected: {profile.mode},
              onSelectionChanged: (set) {
                if (set.isNotEmpty) {
                  notifier.setMode(set.first);
                }
              },
            ),
          ),
          const SizedBox(height: 24),

          // Section 2: Text Scale Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  l10n.appearanceFontScaleSection,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(profile.fontScale * 100).round()}%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          Slider(
            value: profile.fontScale,
            min: 0.9,
            max: 1.6,
            divisions: 14,
            label: '${(profile.fontScale * 100).round()}%',
            onChanged: (val) {
              notifier.setFontScale(val);
            },
          ),
          const SizedBox(height: 24),

          // Section 3: Density
          Text(
            l10n.appearanceDensitySection,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<UiDensity>(
              segments: [
                ButtonSegment<UiDensity>(
                  value: UiDensity.spacious,
                  label: Text(l10n.appearanceDensitySpacious),
                  icon: const Icon(Icons.view_agenda_outlined),
                ),
                ButtonSegment<UiDensity>(
                  value: UiDensity.compact,
                  label: Text(l10n.appearanceDensityCompact),
                  icon: const Icon(Icons.view_compact_outlined),
                ),
              ],
              selected: {profile.density},
              onSelectionChanged: (set) {
                if (set.isNotEmpty) {
                  notifier.setDensity(set.first);
                }
              },
            ),
          ),
          const SizedBox(height: 24),

          // Section 4: Switches
          SwitchListTile(
            title: Text(l10n.appearanceHaptic),
            value: profile.hapticFeedback,
            onChanged: (val) => notifier.setHapticFeedback(val),
          ),
          SwitchListTile(
            title: Text(l10n.appearanceGestures),
            subtitle: Text(
              adaptive.isSimple
                  ? 'Доступно в режиме «Полный»'
                  : 'Свайп вправо — календарь, влево — не хочу',
            ),
            value: profile.cardGestures,
            onChanged: adaptive.isSimple
                ? null
                : (val) => notifier.setCardGestures(val),
          ),
          const SizedBox(height: 24),

          // Section 5: Live Preview
          Text(
            l10n.appearancePreview,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(adaptive.cardBorderRadius),
            ),
            child: Padding(
              padding: adaptive.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.soup_kitchen,
                          color: theme.colorScheme.onPrimaryContainer,
                          size: adaptive.isSimple ? 28 : 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Куриный суп с картошкой',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '40 мин • Легко • Все продукты есть дома',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Приготовить'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
