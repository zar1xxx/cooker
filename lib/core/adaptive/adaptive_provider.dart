import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'adaptive_spec.dart';
import 'ui_profile.dart';
import 'ui_profile_service.dart';

final uiProfileServiceProvider = Provider<UiProfileService>((ref) {
  return UiProfileService();
});

class UiProfileNotifier extends Notifier<UiProfile> {
  late final UiProfileService _service;

  @override
  UiProfile build() {
    _service = ref.watch(uiProfileServiceProvider);
    // Asynchronously load saved profile
    _loadInitial();
    return _service.current;
  }

  Future<void> _loadInitial() async {
    final loaded = await _service.loadProfile();
    state = loaded;
  }

  Future<void> setMode(UiMode mode) async {
    final updated = mode == UiMode.simple
        ? state.copyWith(
            mode: UiMode.simple,
            density: UiDensity.spacious,
            cardGestures: false,
            showAiDetails: false,
            showStatistics: false,
            visibleTabs: const ['today', 'pantry', 'calendar', 'history'],
          )
        : state.copyWith(
            mode: UiMode.full,
            density: UiDensity.compact,
            cardGestures: true,
            showAiDetails: true,
            showStatistics: true,
            visibleTabs: const [
              'today',
              'pantry',
              'calendar',
              'history',
              'stats',
            ],
          );
    state = updated;
    await _service.saveProfile(updated);
  }

  Future<void> updateProfile(UiProfile updated) async {
    state = updated;
    await _service.saveProfile(updated);
  }

  Future<void> setFontScale(double scale) async {
    final updated = state.copyWith(fontScale: scale);
    state = updated;
    await _service.saveProfile(updated);
  }

  Future<void> setDensity(UiDensity density) async {
    final updated = state.copyWith(density: density);
    state = updated;
    await _service.saveProfile(updated);
  }

  Future<void> setCardGestures(bool enabled) async {
    final updated = state.copyWith(cardGestures: enabled);
    state = updated;
    await _service.saveProfile(updated);
  }

  Future<void> setHapticFeedback(bool enabled) async {
    final updated = state.copyWith(hapticFeedback: enabled);
    state = updated;
    await _service.saveProfile(updated);
  }

  Future<void> completeOnboarding(UiMode selectedMode) async {
    final base = selectedMode == UiMode.simple
        ? UiProfile.defaultSimple()
        : UiProfile.defaultFull();
    final updated = base.copyWith(hasCompletedOnboarding: true);
    state = updated;
    await _service.saveProfile(updated);
  }
}

final uiProfileProvider = NotifierProvider<UiProfileNotifier, UiProfile>(
  UiProfileNotifier.new,
);

final adaptiveSpecProvider = Provider<AdaptiveSpec>((ref) {
  final profile = ref.watch(uiProfileProvider);
  return AdaptiveSpec(profile: profile);
});

final isFullModeProvider = Provider<bool>((ref) {
  return ref.watch(uiProfileProvider).mode == UiMode.full;
});

final isSimpleModeProvider = Provider<bool>((ref) {
  return ref.watch(uiProfileProvider).mode == UiMode.simple;
});
