import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/adaptive/adaptive_app_bar_title.dart';
import '../../core/adaptive/adaptive_provider.dart';
import '../../core/adaptive/adaptive_spec.dart';
import '../../core/adaptive/ui_profile.dart';
import '../../l10n/app_localizations.dart';

/// Screen presented on first launch to choose interface mode (R8-17 / D-057).
class ModeOnboardingScreen extends ConsumerStatefulWidget {
  final VoidCallback? onCompleted;

  const ModeOnboardingScreen({super.key, this.onCompleted});

  @override
  ConsumerState<ModeOnboardingScreen> createState() =>
      _ModeOnboardingScreenState();
}

class _ModeOnboardingScreenState extends ConsumerState<ModeOnboardingScreen> {
  UiMode _selectedMode = UiMode.simple;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final systemScale = MediaQuery.textScalerOf(context).scale(1.0);
      // If system font is >= 1.3, simple mode is selected by default;
      // otherwise default is also simple per R8-17.
      _selectedMode = systemScale >= 1.3 ? UiMode.simple : UiMode.simple;
    }
  }

  void _finish(UiMode mode) async {
    await ref.read(uiProfileProvider.notifier).completeOnboarding(mode);
    if (widget.onCompleted != null) {
      widget.onCompleted!();
    } else if (mounted) {
      try {
        if (context.canPop()) {
          context.pop();
          return;
        }
      } catch (_) {}
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        try {
          context.go('/today');
        } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final adaptive = context.adaptive;

    return Scaffold(
      appBar: AppBar(
        title: AdaptiveAppBarTitle(l10n.modeOnboardingTitle),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: adaptive.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.modeOnboardingSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Card 1: Simple Mode
              _ModeSelectionCard(
                key: const Key('card_mode_simple'),
                title: l10n.modeSimpleTitle,
                subtitle: l10n.modeSimpleSubtitle,
                icon: Icons.accessibility_new,
                isSelected: _selectedMode == UiMode.simple,
                onTap: () => setState(() => _selectedMode = UiMode.simple),
                previewText: 'Борщ домашний • 40 мин',
                isSimplePreview: true,
                buttonHeight: 56,
              ),

              const SizedBox(height: 16),

              // Card 2: Full Mode
              _ModeSelectionCard(
                key: const Key('card_mode_full'),
                title: l10n.modeFullTitle,
                subtitle: l10n.modeFullSubtitle,
                icon: Icons.tune,
                isSelected: _selectedMode == UiMode.full,
                onTap: () => setState(() => _selectedMode = UiMode.full),
                previewText: 'Борщ домашний • 40 мин • Супы • 320 ккал',
                isSimplePreview: false,
                buttonHeight: 48,
              ),

              const SizedBox(height: 32),

              // Select button
              FilledButton(
                key: const Key('btn_select_mode'),
                onPressed: () => _finish(_selectedMode),
                child: Text(l10n.modeSelectButton),
              ),

              const SizedBox(height: 12),

              // Decide later button
              TextButton(
                key: const Key('btn_decide_later'),
                onPressed: () => _finish(UiMode.simple),
                child: Text(l10n.modeDecideLater),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeSelectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final String previewText;
  final bool isSimplePreview;
  final double buttonHeight;

  const _ModeSelectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.previewText,
    required this.isSimplePreview,
    required this.buttonHeight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer.withAlpha(80)
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: isSelected ? 2.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  const Icon(Icons.restaurant, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      previewText,
                      style: isSimplePreview
                          ? theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            )
                          : theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
