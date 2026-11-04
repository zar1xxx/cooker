import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/db/daos/history_dao.dart';
import 'package:chto_prigotovit/core/db/enums.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late HistoryDao dao;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory(), seed: true);
    await db.customSelect('SELECT 1').get();
    dao = HistoryDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('HistoryDao (S2-04)', () {
    test('recordCooked creates cooked_entry and feedback_event', () async {
      final entry = await dao.recordCooked(
        recipeId: 'chicken_soup_potato',
        rating: 5,
        wouldRepeat: true,
        note: 'Очень вкусно получилось',
      );

      expect(entry.id, isNotEmpty);
      expect(entry.recipeId, 'chicken_soup_potato');
      expect(entry.rating, 5);
      expect(entry.wouldRepeat, isTrue);
      expect(entry.note, 'Очень вкусно получилось');

      // Check feedback_events table
      final feedbackList = await db.select(db.feedbackEvents).get();
      final feedback = feedbackList.firstWhere(
        (f) => f.recipeId == 'chicken_soup_potato',
      );
      expect(feedback.kind, FeedbackKind.cooked);
      expect(feedback.reason, 'rating: 5');

      // Check allWithRecipes
      final history = await dao.allWithRecipes();
      expect(history.length, 1);
      expect(history.first.entry.id, entry.id);
      expect(history.first.recipe?.title, 'Куриный суп с картошкой');
    });

    test('updateRating updates the rating in database', () async {
      final entry = await dao.recordCooked(
        recipeId: 'chicken_soup_potato',
        rating: 3,
      );

      await dao.updateRating(entry.id, 5);

      final history = await dao.allWithRecipes();
      expect(history.first.entry.rating, 5);
    });
  });
}
