import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chto_prigotovit/app/theme.dart';
import 'package:chto_prigotovit/core/adaptive/adaptive_provider.dart';
import 'package:chto_prigotovit/core/adaptive/adaptive_spec.dart';
import 'package:chto_prigotovit/core/adaptive/mode_prompt_dialog.dart';
import 'package:chto_prigotovit/core/adaptive/ui_profile.dart';
import 'package:chto_prigotovit/core/adaptive/ui_profile_service.dart';
import 'package:chto_prigotovit/features/settings/appearance_settings_screen.dart';
import 'package:chto_prigotovit/features/settings/mode_onboarding_screen.dart';
import 'package:chto_prigotovit/l10n/app_localizations.dart';

Widget _buildWrapper({
  required Widget child,
  required ProviderContainer container,
  AdaptiveSpec spec = AdaptiveSpec.defaultSimple,
  double textScale = 1.0,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: AdaptiveScope(
      spec: spec,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        theme: AppTheme.lightFor(spec),
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  late ProviderContainer container;
  late UiProfileService service;

  setUp(() {
    service = UiProfileService();
    container = ProviderContainer(
      overrides: [uiProfileServiceProvider.overrideWithValue(service)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('ModeOnboardingScreen (R8-17 / D-057)', () {
    testWidgets('renders both mode cards and buttons', (tester) async {
      await tester.pumpWidget(
        _buildWrapper(
          container: container,
          child: const ModeOnboardingScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Как вам удобнее?'), findsOneWidget);
      expect(find.byKey(const Key('card_mode_simple')), findsOneWidget);
      expect(find.byKey(const Key('card_mode_full')), findsOneWidget);
      expect(find.byKey(const Key('btn_select_mode')), findsOneWidget);
      expect(find.byKey(const Key('btn_decide_later')), findsOneWidget);
    });

    testWidgets('selects full mode and completes onboarding', (tester) async {
      var completed = false;

      await tester.pumpWidget(
        _buildWrapper(
          container: container,
          child: ModeOnboardingScreen(onCompleted: () => completed = true),
        ),
      );
      await tester.pumpAndSettle();

      // Tap full mode card
      await tester.tap(find.byKey(const Key('card_mode_full')));
      await tester.pumpAndSettle();

      // Ensure select button is visible and tap
      final selectBtn = find.byKey(const Key('btn_select_mode'));
      await tester.ensureVisible(selectBtn);
      await tester.pumpAndSettle();
      await tester.tap(selectBtn);
      await tester.pumpAndSettle();

      expect(completed, isTrue);
      final profile = container.read(uiProfileProvider);
      expect(profile.mode, UiMode.full);
      expect(profile.hasCompletedOnboarding, isTrue);
    });

    testWidgets('decide later completes onboarding with simple mode', (
      tester,
    ) async {
      var completed = false;

      await tester.pumpWidget(
        _buildWrapper(
          container: container,
          child: ModeOnboardingScreen(onCompleted: () => completed = true),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure decide later button is visible and tap
      final laterBtn = find.byKey(const Key('btn_decide_later'));
      await tester.ensureVisible(laterBtn);
      await tester.pumpAndSettle();
      await tester.tap(laterBtn);
      await tester.pumpAndSettle();

      expect(completed, isTrue);
      final profile = container.read(uiProfileProvider);
      expect(profile.mode, UiMode.simple);
      expect(profile.hasCompletedOnboarding, isTrue);
    });

    testWidgets('defaults to simple mode when system text scale >= 1.3', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildWrapper(
          container: container,
          textScale: 1.5,
          child: const ModeOnboardingScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Select without changing
      final selectBtn = find.byKey(const Key('btn_select_mode'));
      await tester.ensureVisible(selectBtn);
      await tester.tap(selectBtn);
      await tester.pumpAndSettle();

      final profile = container.read(uiProfileProvider);
      expect(profile.mode, UiMode.simple);
    });
  });

  group('AppearanceSettingsScreen (R8-17 / D-057)', () {
    testWidgets('renders all sections and switches modes instantly', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildWrapper(
          container: container,
          child: const AppearanceSettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Внешний вид'), findsOneWidget);
      expect(find.text('Режим интерфейса'), findsOneWidget);
      expect(find.text('Размер текста'), findsOneWidget);
      expect(find.text('Плотность элементов'), findsOneWidget);
      expect(find.text('Вибрация при нажатии'), findsOneWidget);
      expect(find.text('Жесты на карточках (свайпы)'), findsOneWidget);
      expect(find.text('Образец карточки'), findsOneWidget);

      // Tap "Все возможности"
      await tester.tap(find.text('Все возможности'));
      await tester.pumpAndSettle();

      expect(container.read(uiProfileProvider).mode, UiMode.full);
      expect(container.read(adaptiveSpecProvider).isFull, isTrue);
    });

    testWidgets('changing font scale slider updates profile', (tester) async {
      await tester.pumpWidget(
        _buildWrapper(
          container: container,
          child: const AppearanceSettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Find slider and interact
      final slider = find.byType(Slider);
      expect(slider, findsOneWidget);

      // Slide to change
      await tester.drag(slider, const Offset(60, 0));
      await tester.pumpAndSettle();

      expect(container.read(uiProfileProvider).fontScale, greaterThan(1.0));
    });
  });

  group('Mode suggestion prompt dialog (R8-17)', () {
    testWidgets('shows try full mode dialog and handles switch action', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildWrapper(
          container: container,
          child: Builder(
            builder: (ctx) => Consumer(
              builder: (ctx, ref, _) => ElevatedButton(
                onPressed: () =>
                    showModeSuggestionPrompt(ctx, ref, toFull: true),
                child: const Text('Show Prompt'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Prompt'));
      await tester.pumpAndSettle();

      expect(find.text('Попробовать полный режим?'), findsOneWidget);
      expect(find.byKey(const Key('btn_mode_prompt_switch')), findsOneWidget);
      expect(find.byKey(const Key('btn_mode_prompt_never')), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_mode_prompt_switch')));
      await tester.pumpAndSettle();

      expect(container.read(uiProfileProvider).mode, UiMode.full);
    });

    testWidgets('never button suppresses future prompts', (tester) async {
      await tester.pumpWidget(
        _buildWrapper(
          container: container,
          child: Builder(
            builder: (ctx) => Consumer(
              builder: (ctx, ref, _) => ElevatedButton(
                onPressed: () =>
                    showModeSuggestionPrompt(ctx, ref, toFull: true),
                child: const Text('Show Prompt'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Prompt'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_mode_prompt_never')));
      await tester.pumpAndSettle();

      expect(service.current.suppressModePrompt, isTrue);
    });
  });
}
