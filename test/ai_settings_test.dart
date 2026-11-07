import 'dart:convert';

import 'package:chto_prigotovit/core/ai/ai_router.dart';
import 'package:chto_prigotovit/core/ai/ai_service.dart';
import 'package:chto_prigotovit/core/ai/ai_settings_service.dart';
import 'package:chto_prigotovit/core/ai/gigachat_cert.dart';
import 'package:chto_prigotovit/core/ai/gigachat_provider.dart';
import 'package:chto_prigotovit/core/ai/recipe_validator.dart';
import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/providers.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/io.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeConnectivity implements Connectivity {
  FakeConnectivity(this.current);
  List<ConnectivityResult> current;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => current;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      Stream.value(current);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AiSettingsService (S3-08)', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
    });

    test('loads default settings when storage is empty', () async {
      final service = AiSettingsService(storage: const FlutterSecureStorage());
      final settings = await service.loadSettings();

      expect(settings.lmStudioHost, isEmpty);
      expect(settings.lmStudioPort, equals(1234));
      expect(settings.gigaChatAuthKey, isEmpty);
      expect(settings.gigaChatModel, equals('GigaChat-2'));
    });

    test('persists and reloads updated settings', () async {
      final service = AiSettingsService(storage: const FlutterSecureStorage());
      const newSettings = AiSettings(
        lmStudioHost: '192.168.1.100',
        lmStudioPort: 1234,
        lmStudioModel: 'qwen2.5-7b-instruct',
        gigaChatAuthKey: 'secret_key_123',
        gigaChatModel: 'GigaChat-Pro',
      );

      await service.saveSettings(newSettings);
      final loaded = await service.loadSettings();

      expect(loaded.lmStudioHost, equals('192.168.1.100'));
      expect(loaded.lmStudioPort, equals(1234));
      expect(loaded.lmStudioModel, equals('qwen2.5-7b-instruct'));
      expect(loaded.gigaChatAuthKey, equals('secret_key_123'));
      expect(loaded.gigaChatModel, equals('GigaChat-Pro'));
    });

    test('applyToRouter updates router providers', () async {
      final service = AiSettingsService(storage: const FlutterSecureStorage());
      final router = AiRouter();

      expect(router.lmStudioProvider, isNull);
      expect(router.gigaChatProvider, isNull);

      const settings = AiSettings(
        lmStudioHost: '192.168.1.42',
        lmStudioPort: 1234,
        lmStudioModel: 'qwen-7b',
        gigaChatAuthKey: 'token_abc',
      );

      service.applyToRouter(router, settings);

      expect(router.lmStudioProvider, isNotNull);
      expect(
        router.lmStudioProvider!.baseUrl,
        equals('http://192.168.1.42:1234'),
      );
      expect(router.lmStudioProvider!.model, equals('qwen-7b'));

      expect(router.gigaChatProvider, isNotNull);
      expect(router.gigaChatProvider!.authKey, equals('token_abc'));
    });

    test('GigaChatCert.load() loads valid Russian Trusted Root CA certificate asset (R1-01)', () async {
      await GigaChatCert.load();
      expect(GigaChatCert.bytes, isNotNull);
      final pem = utf8.decode(GigaChatCert.bytes!);
      expect(pem, startsWith('-----BEGIN CERTIFICATE-----'));
      expect(pem, contains('-----END CERTIFICATE-----'));
    });

    test('applyToRouter without certBytes uses GigaChatCert.bytes to configure IOHttpClientAdapter (R1-01)', () async {
      await GigaChatCert.load();
      final service = AiSettingsService(storage: const FlutterSecureStorage());
      final router = AiRouter();

      const settings = AiSettings(gigaChatAuthKey: 'test_token');

      service.applyToRouter(router, settings);

      expect(router.gigaChatProvider, isNotNull);
      expect(
        router.gigaChatProvider!.dio.httpClientAdapter,
        isA<IOHttpClientAdapter>(),
      );
    });

    test('aiRouterProvider awaits settings so immediate request goes to configured provider rather than offline (R1-02)', () async {
      const storage = FlutterSecureStorage();
      await AiSettingsService(storage: storage).saveSettings(
        const AiSettings(
          gigaChatAuthKey: 'configured-key-xyz',
          gigaChatModel: 'GigaChat-2',
        ),
      );

      final memDb = AppDatabase(NativeDatabase.memory(), seed: false);
      addTearDown(memDb.close);

      final container = ProviderContainer(
        overrides: [
          connectivityProvider.overrideWithValue(
            FakeConnectivity([ConnectivityResult.wifi]),
          ),
          databaseProvider.overrideWithValue(memDb),
        ],
      );
      addTearDown(container.dispose);

      // Read router immediately upon creation
      final router = container.read(aiRouterProvider);

      // Even though loadSettings is asynchronous, getActiveProvider waits for router.ready
      final activeProvider = await router.getActiveProvider();
      expect(activeProvider, isNotNull);
      expect(activeProvider, isA<GigaChatProvider>());
      expect(
        (activeProvider as GigaChatProvider).authKey,
        equals('configured-key-xyz'),
      );

      final mode = await router.getMode();
      expect(mode, equals(AiMode.gigaChat));
    });

    test('aiServiceProvider immediately resolves with configured router and active provider (R1-02)', () async {
      const storage = FlutterSecureStorage();
      await AiSettingsService(storage: storage).saveSettings(
        const AiSettings(
          gigaChatAuthKey: 'configured-key-xyz',
          gigaChatModel: 'GigaChat-2',
        ),
      );

      final memDb = AppDatabase(NativeDatabase.memory(), seed: false);
      addTearDown(memDb.close);

      final container = ProviderContainer(
        overrides: [
          connectivityProvider.overrideWithValue(
            FakeConnectivity([ConnectivityResult.wifi]),
          ),
          databaseProvider.overrideWithValue(memDb),
        ],
      );
      addTearDown(container.dispose);

      final aiService = await container.read(aiServiceProvider.future);
      final activeProvider = await aiService.router.getActiveProvider();
      expect(activeProvider, isNotNull);
      expect(activeProvider, isA<GigaChatProvider>());

      final activeMode = await container.read(aiModeProvider.future);
      expect(activeMode, equals(AiMode.gigaChat));
    });
  });

  group('AiService.getMonthlyTokensUsed with filter (S3-08)', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory(), seed: false);
    });

    tearDown(() async {
      await db.close();
    });

    test('correctly filters tokens by provider/model name', () async {
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;

      // LM Studio entry
      await db
          .into(db.aiRequests)
          .insert(
            AiRequestsCompanion(
              id: const Value('req1'),
              kind: const Value('suggest_dishes'),
              promptHash: const Value('h1'),
              responseJson: const Value('{}'),
              status: const Value('ok'),
              at: Value(now),
              createdAt: Value(now),
              updatedAt: Value(now),
              model: const Value('lm_studio:qwen2.5-7b'),
              tokensIn: const Value(150),
              tokensOut: const Value(50),
            ),
          );

      // GigaChat entry
      await db
          .into(db.aiRequests)
          .insert(
            AiRequestsCompanion(
              id: const Value('req2'),
              kind: const Value('suggest_dishes'),
              promptHash: const Value('h2'),
              responseJson: const Value('{}'),
              status: const Value('ok'),
              at: Value(now),
              createdAt: Value(now),
              updatedAt: Value(now),
              model: const Value('GigaChat-2'),
              tokensIn: const Value(500),
              tokensOut: const Value(200),
            ),
          );

      final service = AiService(
        router: AiRouter(),
        validator: const RecipeValidator(safetyMinimums: {}),
        db: db,
      );

      final allTokens = await service.getMonthlyTokensUsed();
      expect(allTokens, equals(900)); // 200 + 700

      final gigaTokens = await service.getMonthlyTokensUsed(
        modelFilter: 'gigachat',
      );
      expect(gigaTokens, equals(700));

      final lmTokens = await service.getMonthlyTokensUsed(
        modelFilter: 'lm_studio',
      );
      expect(lmTokens, equals(200));
    });

    test('sanitizeGigaChatKey cleans spaces, newlines, quotes, and Basic prefix (R3-06)', () {
      expect(
        AiSettingsService.sanitizeGigaChatKey('   MDE5YzAw...==   \t'),
        equals('MDE5YzAw...=='),
      );
      expect(
        AiSettingsService.sanitizeGigaChatKey('"MDE5YzAw...=="'),
        equals('MDE5YzAw...=='),
      );
      expect(
        AiSettingsService.sanitizeGigaChatKey("'MDE5YzAw...=='"),
        equals('MDE5YzAw...=='),
      );
      expect(
        AiSettingsService.sanitizeGigaChatKey('`MDE5YzAw...==`'),
        equals('MDE5YzAw...=='),
      );
      expect(
        AiSettingsService.sanitizeGigaChatKey('Basic MDE5YzAw...=='),
        equals('MDE5YzAw...=='),
      );
      expect(
        AiSettingsService.sanitizeGigaChatKey('basic   MDE5YzAw...=='),
        equals('MDE5YzAw...=='),
      );
      expect(
        AiSettingsService.sanitizeGigaChatKey('MDE5\n\rYzAw\n...=='),
        equals('MDE5YzAw...=='),
      );
      expect(
        AiSettingsService.sanitizeGigaChatKey('  "Basic MDE5\n YzAw...==" '),
        equals('MDE5YzAw...=='),
      );
      expect(AiSettingsService.sanitizeGigaChatKey('   \n  '), isEmpty);
    });
  });
}
