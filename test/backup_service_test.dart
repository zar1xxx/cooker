import 'dart:convert';

import 'package:chto_prigotovit/core/backup/backup_service.dart';
import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/db/daos/history_dao.dart';
import 'package:chto_prigotovit/core/preferences/preference_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late PreferenceService prefService;
  late HistoryDao historyDao;
  late BackupService backupService;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory(), seed: true);
    await db.customSelect('SELECT 1').get();
    prefService = PreferenceService(db);
    historyDao = HistoryDao(db, preferenceService: prefService);
    backupService = BackupService(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('BackupService (S4-05 / TZ 7.2, 8.2)', () {
    test(
      'exportBackupJson contains all tables and strictly zero keys/secrets',
      () async {
        // 1. Setup sample data
        await historyDao.recordCooked(
          recipeId: 'chicken_soup_potato',
          rating: 5,
          wouldRepeat: true,
          note: 'Бабушкин любимый суп',
        );
        await historyDao.recordCooked(
          recipeId: 'apple_bake',
          rating: 4,
          wouldRepeat: true,
          note: 'Сладкие яблоки',
        );
        await prefService.setAllergies(['nuts']);
        await prefService.setExcludedIngredients(['mushrooms']);
        await prefService.setServingsDefault(4);

        // Add a pantry item
        await db
            .into(db.pantryItems)
            .insert(PantryItemsCompanion.insert(ingredientId: 'chicken'));

        // 2. Export
        final jsonString = await backupService.exportBackupJson();
        expect(jsonString, isNotEmpty);

        final dynamic decoded = jsonDecode(jsonString);
        expect(decoded, isA<Map<String, dynamic>>());
        expect(decoded['version'], 1);
        expect(decoded['app'], 'chto_prigotovit');

        final data = decoded['data'] as Map<String, dynamic>;
        expect(data.containsKey('preference_profile'), isTrue);
        expect(data.containsKey('cooked_entries'), isTrue);
        expect(data.containsKey('feedback_events'), isTrue);
        expect(data.containsKey('recipes'), isTrue);
        expect(data.containsKey('pantry_items'), isTrue);

        final cooked = data['cooked_entries'] as List;
        expect(cooked.length, greaterThanOrEqualTo(2));

        // Rule 7 check: verify no secrets or private keys exist anywhere in the JSON
        expect(jsonString.toLowerCase().contains('gigachat_auth_key'), isFalse);
        expect(jsonString.toLowerCase().contains('authkey'), isFalse);
        expect(jsonString.toLowerCase().contains('bearer'), isFalse);
        expect(jsonString.toLowerCase().contains('secret'), isFalse);
        expect(jsonString.toLowerCase().contains('password'), isFalse);
      },
    );

    test('importBackupJson restores full history and preferences to a clean installation', () async {
      // 1. Prepare and export data on source DB
      await historyDao.recordCooked(
        recipeId: 'chicken_soup_potato',
        rating: 5,
        wouldRepeat: true,
        note: 'Идеально',
      );
      await historyDao.recordCooked(
        recipeId: 'apple_bake',
        rating: 1,
        wouldRepeat: false,
        note: 'Не понравилось',
      );
      await prefService.setAllergies(['nuts', 'honey']);
      await prefService.setExcludedIngredients(['onion']);
      await prefService.setServingsDefault(6);

      final exportedJson = await backupService.exportBackupJson();

      // 2. Clean target DB (simulate fresh installation on new device)
      final cleanDb = AppDatabase(NativeDatabase.memory(), seed: true);
      await cleanDb.customSelect('SELECT 1').get();
      final cleanBackupService = BackupService(cleanDb);
      final cleanPrefService = PreferenceService(cleanDb);

      try {
        // Verify cleanDb initially has no cooked entries
        final initialCooked = await cleanDb.select(cleanDb.cookedEntries).get();
        expect(initialCooked, isEmpty);

        // 3. Import
        final summary = await cleanBackupService.importBackupJson(exportedJson);
        expect(summary.cookedEntries, 2);
        expect(summary.preferenceProfiles, greaterThanOrEqualTo(1));

        // 4. Verify restored history
        final restoredCooked = await cleanDb
            .select(cleanDb.cookedEntries)
            .get();
        expect(restoredCooked.length, 2);
        final soupCooked = restoredCooked.firstWhere(
          (c) => c.recipeId == 'chicken_soup_potato',
        );
        expect(soupCooked.rating, 5);
        expect(soupCooked.note, 'Идеально');

        final appleCooked = restoredCooked.firstWhere(
          (c) => c.recipeId == 'apple_bake',
        );
        expect(appleCooked.rating, 1);
        expect(appleCooked.note, 'Не понравилось');

        // 5. Verify restored preference profile
        final restoredProfile = await cleanPrefService.getProfile();
        expect(restoredProfile.allergies, containsAll(['nuts', 'honey']));
        expect(restoredProfile.excludedIngredients, contains('onion'));
        expect(restoredProfile.servingsDefault, 6);
        expect(restoredProfile.dishTypeWeights.isNotEmpty, isTrue);
      } finally {
        await cleanDb.close();
      }
    });

    test('rejects broken or incompatible JSON gracefully', () async {
      // Invalid JSON syntax
      expect(
        () => backupService.importBackupJson('{ broken json'),
        throwsA(isA<FormatException>()),
      );

      // Incompatible version
      final wrongVersionJson = jsonEncode({
        'version': 99,
        'app': 'chto_prigotovit',
        'data': {},
      });
      expect(
        () => backupService.importBackupJson(wrongVersionJson),
        throwsA(isA<FormatException>()),
      );

      // Missing data block
      final noDataJson = jsonEncode({'version': 1, 'app': 'chto_prigotovit'});
      expect(
        () => backupService.importBackupJson(noDataJson),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
