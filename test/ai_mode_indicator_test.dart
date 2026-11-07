import 'dart:async';

import 'package:chto_prigotovit/core/ai/ai_failure.dart';
import 'package:chto_prigotovit/core/ai/ai_router.dart';
import 'package:chto_prigotovit/core/ai/ai_service.dart';
import 'package:chto_prigotovit/core/ai/ai_settings_service.dart';
import 'package:chto_prigotovit/core/ai/gigachat_provider.dart';
import 'package:chto_prigotovit/core/ai/lm_studio_provider.dart';
import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/providers.dart';
import 'package:chto_prigotovit/features/suggestions/suggestions_screen.dart';
import 'package:chto_prigotovit/l10n/app_localizations.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeConnectivity extends Fake implements Connectivity {
  _FakeConnectivity(this.current);
  List<ConnectivityResult> current;
  final _controller = StreamController<List<ConnectivityResult>>.broadcast();

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => current;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _controller.stream;

  void emit(List<ConnectivityResult> results) {
    current = results;
    _controller.add(results);
  }

  void close() {
    _controller.close();
  }
}

class _MockLmStudio extends Fake implements LmStudioProvider {
  @override
  String get name => 'lm_studio';

  @override
  Future<List<String>> getModels({
    Duration timeout = const Duration(seconds: 3),
  }) async => ['qwen2.5-7b'];

  @override
  Future<bool> isAvailable() async => true;
}

class _MockGigaChat extends Fake implements GigaChatProvider {
  @override
  String get name => 'gigachat';

  @override
  String get authKey => 'mock-key';

  @override
  Future<String> getToken({bool forceRefresh = false}) async => 'mock-token';

  @override
  Future<bool> isAvailable() async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late _FakeConnectivity fakeConnectivity;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory(), seed: false);
    fakeConnectivity = _FakeConnectivity([ConnectivityResult.wifi]);
  });

  tearDown(() async {
    fakeConnectivity.close();
    await db.close();
  });

  Widget buildSuggestionsScreen({required AiMode mode}) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        aiModeProvider.overrideWith((ref) => Future.value(mode)),
        suggestionsProvider.overrideWith(
          (ref) => const SuggestionsState(ready: [], almostReady: []),
        ),
        aiDishesProvider.overrideWith(
          () => _StaticAiDishesNotifier(const AiResult.success([])),
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('ru'),
        home: SuggestionsScreen(),
      ),
    );
  }

  group('SuggestionsScreen Subtitle (R3-07)', () {
    testWidgets('displays "Помощник: компьютер" when active mode is localPc', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildSuggestionsScreen(mode: AiMode.localPc));
      await tester.pumpAndSettle();

      expect(find.text('Подходящие блюда'), findsOneWidget);
      expect(find.text('Помощник: компьютер'), findsOneWidget);
    });

    testWidgets('displays "Помощник: GigaChat" when active mode is gigaChat', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildSuggestionsScreen(mode: AiMode.gigaChat));
      await tester.pumpAndSettle();

      expect(find.text('Подходящие блюда'), findsOneWidget);
      expect(find.text('Помощник: GigaChat'), findsOneWidget);
    });

    testWidgets(
      'displays "Помощник: не подключён" when active mode is offline',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(buildSuggestionsScreen(mode: AiMode.offline));
        await tester.pumpAndSettle();

        expect(find.text('Подходящие блюда'), findsOneWidget);
        expect(find.text('Помощник: не подключён'), findsOneWidget);
      },
    );
  });

  group('aiModeProvider dynamic recalculation (R3-07)', () {
    test('recalculates when network connectivity changes', () async {
      final router = AiRouter(
        lmStudioProvider: _MockLmStudio(),
        gigaChatProvider: _MockGigaChat(),
        connectivity: fakeConnectivity,
      );

      final container = ProviderContainer(
        overrides: [
          connectivityProvider.overrideWithValue(fakeConnectivity),
          aiRouterProvider.overrideWithValue(router),
        ],
      );
      addTearDown(container.dispose);

      // Listen to aiModeProvider so Riverpod keeps the provider alive and active
      final modes = <AiMode>[];
      container.listen<AsyncValue<AiMode>>(aiModeProvider, (_, next) {
        if (next.hasValue) modes.add(next.value!);
      }, fireImmediately: true);

      // 1. Initial on Wi-Fi: LM Studio is selected
      var mode = await container.read(aiModeProvider.future);
      expect(mode, equals(AiMode.localPc));

      // 2. Switch to Mobile network: emits event
      fakeConnectivity.emit([ConnectivityResult.mobile]);
      await pumpEventQueue();

      mode = await container.read(aiModeProvider.future);
      expect(mode, equals(AiMode.gigaChat));

      // 3. Switch back to Wi-Fi
      fakeConnectivity.emit([ConnectivityResult.wifi]);
      await pumpEventQueue();

      mode = await container.read(aiModeProvider.future);
      expect(mode, equals(AiMode.localPc));
    });

    test('recalculates when settings change / are invalidated', () async {
      final storage = const FlutterSecureStorage();
      final settingsService = AiSettingsService(storage: storage);
      final router = AiRouter(connectivity: fakeConnectivity);

      final container = ProviderContainer(
        overrides: [
          connectivityProvider.overrideWithValue(fakeConnectivity),
          aiSettingsServiceProvider.overrideWithValue(settingsService),
          aiRouterProvider.overrideWithValue(router),
        ],
      );
      addTearDown(container.dispose);

      // 1. Empty settings -> offline
      var mode = await container.read(aiModeProvider.future);
      expect(mode, equals(AiMode.offline));

      // 2. Save GigaChat key in settings and apply
      const updated = AiSettings(gigaChatAuthKey: 'new-key');
      await settingsService.saveSettings(updated);
      settingsService.applyToRouter(router, updated);
      router.gigaChatProvider = _MockGigaChat();

      container.invalidate(aiSettingsProvider);
      container.invalidate(aiModeProvider);

      mode = await container.read(aiModeProvider.future);
      expect(mode, equals(AiMode.gigaChat));
    });
  });
}

class _StaticAiDishesNotifier
    extends AsyncNotifier<AiResult<List<AiDishSuggestion>>>
    implements AiDishesNotifier {
  _StaticAiDishesNotifier(this._result);
  final AiResult<List<AiDishSuggestion>> _result;

  @override
  Future<AiResult<List<AiDishSuggestion>>> build() async => _result;

  Future<void> refresh() async {}

  Future<void> retry() async {}

  @override
  Future<void> fetchOtherVariants({
    List<String> alreadyShown = const [],
  }) async {}
}
