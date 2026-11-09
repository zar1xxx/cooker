enum UiMode {
  simple,
  full;

  String get id => name;

  static UiMode fromString(String? value) {
    if (value == 'full') return UiMode.full;
    return UiMode.simple;
  }
}

enum UiDensity {
  spacious,
  compact;

  String get id => name;

  static UiDensity fromString(String? value) {
    if (value == 'compact') return UiDensity.compact;
    return UiDensity.spacious;
  }
}

class UiProfile {
  final UiMode mode;
  final double fontScale;
  final UiDensity density;
  final bool hapticFeedback;
  final bool cardGestures;
  final List<String> visibleTabs;
  final bool showAiDetails;
  final bool showStatistics;
  final bool hasCompletedOnboarding;
  final DateTime? lastModePromptDate;
  final bool suppressModePrompt;

  const UiProfile({
    this.mode = UiMode.simple,
    this.fontScale = 1.0,
    this.density = UiDensity.spacious,
    this.hapticFeedback = true,
    this.cardGestures = false,
    this.visibleTabs = const ['today', 'pantry', 'calendar', 'history'],
    this.showAiDetails = false,
    this.showStatistics = false,
    this.hasCompletedOnboarding = false,
    this.lastModePromptDate,
    this.suppressModePrompt = false,
  });

  factory UiProfile.defaultSimple() => const UiProfile(
    mode: UiMode.simple,
    fontScale: 1.0,
    density: UiDensity.spacious,
    hapticFeedback: true,
    cardGestures: false,
    visibleTabs: ['today', 'pantry', 'calendar', 'history'],
    showAiDetails: false,
    showStatistics: false,
    hasCompletedOnboarding: false,
  );

  factory UiProfile.defaultFull() => const UiProfile(
    mode: UiMode.full,
    fontScale: 1.0,
    density: UiDensity.compact,
    hapticFeedback: true,
    cardGestures: true,
    visibleTabs: ['today', 'pantry', 'calendar', 'history', 'stats'],
    showAiDetails: true,
    showStatistics: true,
    hasCompletedOnboarding: true,
  );

  UiProfile copyWith({
    UiMode? mode,
    double? fontScale,
    UiDensity? density,
    bool? hapticFeedback,
    bool? cardGestures,
    List<String>? visibleTabs,
    bool? showAiDetails,
    bool? showStatistics,
    bool? hasCompletedOnboarding,
    DateTime? lastModePromptDate,
    bool? suppressModePrompt,
  }) {
    return UiProfile(
      mode: mode ?? this.mode,
      fontScale: fontScale != null ? fontScale.clamp(0.9, 1.6) : this.fontScale,
      density: density ?? this.density,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      cardGestures: cardGestures ?? this.cardGestures,
      visibleTabs: visibleTabs ?? this.visibleTabs,
      showAiDetails: showAiDetails ?? this.showAiDetails,
      showStatistics: showStatistics ?? this.showStatistics,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      lastModePromptDate: lastModePromptDate ?? this.lastModePromptDate,
      suppressModePrompt: suppressModePrompt ?? this.suppressModePrompt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mode': mode.name,
      'font_scale': fontScale,
      'density': density.name,
      'haptic_feedback': hapticFeedback,
      'card_gestures': cardGestures,
      'visible_tabs': visibleTabs,
      'show_ai_details': showAiDetails,
      'show_statistics': showStatistics,
      'has_completed_onboarding': hasCompletedOnboarding,
      'last_mode_prompt_date': lastModePromptDate?.toIso8601String(),
      'suppress_mode_prompt': suppressModePrompt,
    };
  }

  factory UiProfile.fromJson(Map<String, dynamic> json) {
    final mode = UiMode.fromString(json['mode'] as String?);
    final density = UiDensity.fromString(json['density'] as String?);
    final scaleRaw = json['font_scale'];
    final fontScale = (scaleRaw is num ? scaleRaw.toDouble() : 1.0).clamp(
      0.9,
      1.6,
    );
    final visibleTabsRaw = json['visible_tabs'];
    final visibleTabs = visibleTabsRaw is List
        ? visibleTabsRaw.map((e) => e.toString()).toList()
        : (mode == UiMode.simple
              ? const ['today', 'pantry', 'calendar', 'history']
              : const ['today', 'pantry', 'calendar', 'history', 'stats']);

    return UiProfile(
      mode: mode,
      fontScale: fontScale,
      density: density,
      hapticFeedback: json['haptic_feedback'] as bool? ?? true,
      cardGestures: json['card_gestures'] as bool? ?? (mode == UiMode.full),
      visibleTabs: visibleTabs,
      showAiDetails: json['show_ai_details'] as bool? ?? (mode == UiMode.full),
      showStatistics: json['show_statistics'] as bool? ?? (mode == UiMode.full),
      hasCompletedOnboarding:
          json['has_completed_onboarding'] as bool? ?? false,
      lastModePromptDate: json['last_mode_prompt_date'] != null
          ? DateTime.tryParse(json['last_mode_prompt_date'] as String)
          : null,
      suppressModePrompt: json['suppress_mode_prompt'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UiProfile &&
          runtimeType == other.runtimeType &&
          mode == other.mode &&
          fontScale == other.fontScale &&
          density == other.density &&
          hapticFeedback == other.hapticFeedback &&
          cardGestures == other.cardGestures &&
          showAiDetails == other.showAiDetails &&
          showStatistics == other.showStatistics &&
          hasCompletedOnboarding == other.hasCompletedOnboarding &&
          suppressModePrompt == other.suppressModePrompt;

  @override
  int get hashCode => Object.hash(
    mode,
    fontScale,
    density,
    hapticFeedback,
    cardGestures,
    showAiDetails,
    showStatistics,
    hasCompletedOnboarding,
    suppressModePrompt,
  );
}
