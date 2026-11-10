import 'package:flutter/material.dart';

import 'ui_profile.dart';

/// Adaptive interface specification derived from [UiProfile] and system metrics.
///
/// Implements D-057 and skills/senior-ux:
/// - In "simple" mode: fonts >= 18 sp, titles >= 24 sp, touch targets >= 56 dp.
/// - In "full" mode: fonts >= 16 sp, touch targets >= 48 dp, multi-filters, gestures, statistics.
class AdaptiveSpec extends ThemeExtension<AdaptiveSpec> {
  final UiProfile profile;
  final double systemFontScale;

  const AdaptiveSpec({required this.profile, this.systemFontScale = 1.0});

  static const defaultSimple = AdaptiveSpec(
    profile: UiProfile(
      mode: UiMode.simple,
      fontScale: 1.0,
      density: UiDensity.spacious,
      hapticFeedback: true,
      cardGestures: false,
      visibleTabs: ['today', 'pantry', 'calendar', 'history'],
      showAiDetails: false,
      showStatistics: false,
    ),
  );

  static const defaultFull = AdaptiveSpec(
    profile: UiProfile(
      mode: UiMode.full,
      fontScale: 1.0,
      density: UiDensity.compact,
      hapticFeedback: true,
      cardGestures: true,
      visibleTabs: ['today', 'pantry', 'calendar', 'history', 'stats'],
      showAiDetails: true,
      showStatistics: true,
    ),
  );

  UiMode get mode => profile.mode;
  bool get isSimple => profile.mode == UiMode.simple;
  bool get isFull => profile.mode == UiMode.full;

  double get minTouchTarget =>
      (isFull && profile.density == UiDensity.compact) ? 48.0 : 56.0;

  double get buttonMinHeight => minTouchTarget;

  double get spacing => profile.density == UiDensity.compact ? 12.0 : 16.0;

  EdgeInsets get cardPadding =>
      EdgeInsets.all(profile.density == UiDensity.compact ? 12.0 : 16.0);

  double get cardBorderRadius => 16.0;

  VisualDensity get visualDensity => profile.density == UiDensity.compact
      ? VisualDensity.compact
      : VisualDensity.standard;

  int columnsForWidth(double width) {
    if (isFull && width >= 600) return 2;
    return 1;
  }

  bool get cardGesturesEnabled => profile.cardGestures && isFull;
  bool get showAiDetails => profile.showAiDetails && isFull;
  bool get showStatistics => profile.showStatistics;
  bool get hapticEnabled => profile.hapticFeedback;
  bool get showMultiFilters => isFull;
  bool get showSortOptions => isFull;
  int get maxFilterRows => isSimple ? 1 : 4;

  double get fontScale => profile.fontScale;
  double get effectiveFontScale => profile.fontScale * systemFontScale;

  double get baseFontSize => (isSimple ? 18.0 : 16.0) * profile.fontScale;

  double get titleFontSize => (isSimple ? 24.0 : 20.0) * profile.fontScale;

  double get cookingStepFontSize => 28.0 * profile.fontScale;

  double get captionFontSize => (isSimple ? 16.0 : 14.0) * profile.fontScale;

  double get navBarLabelFontSize =>
      (isSimple ? 13.0 : 11.0) * profile.fontScale;

  double get headlineLargeFontSize =>
      (isSimple ? 32.0 : 28.0) * profile.fontScale;

  double get headlineMediumFontSize =>
      (isSimple ? 28.0 : 24.0) * profile.fontScale;

  double get headlineSmallFontSize =>
      (isSimple ? 24.0 : 20.0) * profile.fontScale;

  T adaptive<T>({required T simple, required T full}) =>
      isSimple ? simple : full;

  @override
  AdaptiveSpec copyWith({UiProfile? profile, double? systemFontScale}) {
    return AdaptiveSpec(
      profile: profile ?? this.profile,
      systemFontScale: systemFontScale ?? this.systemFontScale,
    );
  }

  @override
  ThemeExtension<AdaptiveSpec> lerp(
    covariant ThemeExtension<AdaptiveSpec>? other,
    double t,
  ) {
    if (other is! AdaptiveSpec) return this;
    return t < 0.5 ? this : other;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdaptiveSpec &&
          runtimeType == other.runtimeType &&
          profile == other.profile &&
          systemFontScale == other.systemFontScale;

  @override
  int get hashCode => Object.hash(profile, systemFontScale);
}

/// InheritedWidget providing [AdaptiveSpec] down the widget tree.
class AdaptiveScope extends InheritedWidget {
  final AdaptiveSpec spec;

  const AdaptiveScope({super.key, required this.spec, required super.child});

  static AdaptiveSpec of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AdaptiveScope>();
    if (scope != null) return scope.spec;
    final extension = Theme.of(context).extension<AdaptiveSpec>();
    if (extension != null) return extension;
    return AdaptiveSpec.defaultSimple;
  }

  static AdaptiveSpec? maybeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AdaptiveScope>();
    if (scope != null) return scope.spec;
    return Theme.of(context).extension<AdaptiveSpec>();
  }

  @override
  bool updateShouldNotify(AdaptiveScope oldWidget) => spec != oldWidget.spec;
}

/// Convenient extension on [BuildContext] to access [AdaptiveSpec].
extension AdaptiveContext on BuildContext {
  AdaptiveSpec get adaptive =>
      AdaptiveScope.maybeOf(this) ??
      Theme.of(this).extension<AdaptiveSpec>() ??
      AdaptiveSpec.defaultSimple;
}

/// Widget that only renders [child] when the interface is in Full mode.
class FullOnly extends StatelessWidget {
  final Widget child;
  final Widget fallback;

  const FullOnly({
    super.key,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  });

  @override
  Widget build(BuildContext context) {
    return context.adaptive.isFull ? child : fallback;
  }
}

/// Widget that only renders [child] when the interface is in Simple mode.
class SimpleOnly extends StatelessWidget {
  final Widget child;
  final Widget fallback;

  const SimpleOnly({
    super.key,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  });

  @override
  Widget build(BuildContext context) {
    return context.adaptive.isSimple ? child : fallback;
  }
}
