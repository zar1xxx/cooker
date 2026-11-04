import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/app_database.dart';

/// Summary of elements restored from a backup file.
class BackupRestoreSummary {
  final int cookedEntries;
  final int recipes;
  final int feedbackEvents;
  final int mealPlanEntries;
  final int pantryItems;
  final int preferenceProfiles;
  final int customIngredients;
  final int aiRequests;

  const BackupRestoreSummary({
    this.cookedEntries = 0,
    this.recipes = 0,
    this.feedbackEvents = 0,
    this.mealPlanEntries = 0,
    this.pantryItems = 0,
    this.preferenceProfiles = 0,
    this.customIngredients = 0,
    this.aiRequests = 0,
  });
}

/// Service managing export and import of application database backups.
///
/// Guaranteed to never export API keys or secrets (ТЗ 7.2, 8.2, S4-05, Правило 7).
class BackupService {
  final AppDatabase db;

  BackupService(this.db);

  /// Exports all user data into a clean JSON string, strictly excluding secrets.
  Future<String> exportBackupJson() async {
    final profiles = await db.select(db.preferenceProfile).get();
    final pantry = await db.select(db.pantryItems).get();
    final cooked = await db.select(db.cookedEntries).get();
    final mealPlans = await db.select(db.mealPlanEntries).get();
    final feedback = await db.select(db.feedbackEvents).get();
    final recipes = await db.select(db.recipes).get();
    final recipeIngredients = await db.select(db.recipeIngredients).get();
    final recipeSteps = await db.select(db.recipeSteps).get();
    final ingredients = await db.select(db.ingredients).get();
    final aiRequests = await db.select(db.aiRequests).get();

    final payload = {
      'version': 1,
      'app': 'chto_prigotovit',
      'exported_at': DateTime.now().toUtc().millisecondsSinceEpoch,
      'data': {
        'preference_profile': profiles.map((p) => p.toJson()).toList(),
        'pantry_items': pantry.map((p) => p.toJson()).toList(),
        'cooked_entries': cooked.map((c) => c.toJson()).toList(),
        'meal_plan_entries': mealPlans.map((m) => m.toJson()).toList(),
        'feedback_events': feedback.map((f) => f.toJson()).toList(),
        'recipes': recipes.map((r) => r.toJson()).toList(),
        'recipe_ingredients': recipeIngredients
            .map((ri) => ri.toJson())
            .toList(),
        'recipe_steps': recipeSteps.map((rs) => rs.toJson()).toList(),
        'ingredients': ingredients.map((i) => i.toJson()).toList(),
        'ai_requests': aiRequests.map((a) => a.toJson()).toList(),
      },
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Map<String, dynamic> _sanitizeForDrift(Map<String, dynamic> raw) {
    final copy = Map<String, dynamic>.from(raw);
    for (final key in copy.keys.toList()) {
      final val = copy[key];
      if (val is List) {
        copy[key] = val.map((e) => e.toString()).toList();
      }
    }
    return copy;
  }

  /// Restores database state from a backup JSON string within a single transaction.
  Future<BackupRestoreSummary> importBackupJson(
    String jsonString, {
    bool clearExisting = false,
  }) async {
    final dynamic decoded;
    try {
      decoded = jsonDecode(jsonString);
    } catch (e) {
      throw FormatException('Некорректный JSON файл резервной копии: $e');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Неверная структура резервной копии: ожидается JSON объект',
      );
    }

    final version = decoded['version'];
    if (version != 1) {
      throw FormatException(
        'Неподдерживаемая версия резервной копии: $version',
      );
    }

    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException(
        'Секция данных "data" отсутствует в резервной копии',
      );
    }

    var cookedCount = 0;
    var recipesCount = 0;
    var feedbackCount = 0;
    var mealPlanCount = 0;
    var pantryCount = 0;
    var profileCount = 0;
    var customIngCount = 0;
    var aiReqCount = 0;

    await db.transaction(() async {
      if (clearExisting) {
        await db.delete(db.cookedEntries).go();
        await db.delete(db.feedbackEvents).go();
        await db.delete(db.mealPlanEntries).go();
        await db.delete(db.pantryItems).go();
        await db.delete(db.aiRequests).go();
      }

      // 1. Preference Profile
      final rawProfiles =
          (data['preference_profile'] as List?)?.cast<Map<String, dynamic>>() ??
          [];
      for (final raw in rawProfiles) {
        final profile = PreferenceProfileData.fromJson(_sanitizeForDrift(raw));
        await db
            .into(db.preferenceProfile)
            .insert(
              profile.toCompanion(false),
              mode: InsertMode.insertOrReplace,
            );
        profileCount++;
      }

      // 2. Ingredients (custom or restored)
      final rawIngredients =
          (data['ingredients'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (final raw in rawIngredients) {
        final ing = Ingredient.fromJson(_sanitizeForDrift(raw));
        await db
            .into(db.ingredients)
            .insert(ing.toCompanion(false), mode: InsertMode.insertOrReplace);
        customIngCount++;
      }

      // 3. Recipes
      final rawRecipes =
          (data['recipes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (final raw in rawRecipes) {
        final rec = Recipe.fromJson(raw);
        await db
            .into(db.recipes)
            .insert(rec.toCompanion(false), mode: InsertMode.insertOrReplace);
        recipesCount++;
      }

      // 4. Recipe Ingredients
      final rawRecipeIngs =
          (data['recipe_ingredients'] as List?)?.cast<Map<String, dynamic>>() ??
          [];
      for (final raw in rawRecipeIngs) {
        final line = RecipeIngredient.fromJson(raw);
        await db
            .into(db.recipeIngredients)
            .insert(line.toCompanion(false), mode: InsertMode.insertOrReplace);
      }

      // 5. Recipe Steps
      final rawSteps =
          (data['recipe_steps'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (final raw in rawSteps) {
        final step = RecipeStep.fromJson(raw);
        await db
            .into(db.recipeSteps)
            .insert(step.toCompanion(false), mode: InsertMode.insertOrReplace);
      }

      // 6. Cooked Entries (History)
      final rawCooked =
          (data['cooked_entries'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (final raw in rawCooked) {
        final entry = CookedEntry.fromJson(raw);
        await db
            .into(db.cookedEntries)
            .insert(entry.toCompanion(false), mode: InsertMode.insertOrReplace);
        cookedCount++;
      }

      // 7. Meal Plan Entries (Calendar)
      final rawMealPlans =
          (data['meal_plan_entries'] as List?)?.cast<Map<String, dynamic>>() ??
          [];
      for (final raw in rawMealPlans) {
        final plan = MealPlanEntry.fromJson(raw);
        await db
            .into(db.mealPlanEntries)
            .insert(plan.toCompanion(false), mode: InsertMode.insertOrReplace);
        mealPlanCount++;
      }

      // 8. Feedback Events
      final rawFeedback =
          (data['feedback_events'] as List?)?.cast<Map<String, dynamic>>() ??
          [];
      for (final raw in rawFeedback) {
        final event = FeedbackEvent.fromJson(raw);
        await db
            .into(db.feedbackEvents)
            .insert(event.toCompanion(false), mode: InsertMode.insertOrReplace);
        feedbackCount++;
      }

      // 9. Pantry Items
      final rawPantry =
          (data['pantry_items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (final raw in rawPantry) {
        final item = PantryItem.fromJson(raw);
        await db
            .into(db.pantryItems)
            .insert(item.toCompanion(false), mode: InsertMode.insertOrReplace);
        pantryCount++;
      }

      // 10. AI Requests
      final rawAiRequests =
          (data['ai_requests'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (final raw in rawAiRequests) {
        final req = AiRequest.fromJson(raw);
        await db
            .into(db.aiRequests)
            .insert(req.toCompanion(false), mode: InsertMode.insertOrReplace);
        aiReqCount++;
      }
    });

    return BackupRestoreSummary(
      cookedEntries: cookedCount,
      recipes: recipesCount,
      feedbackEvents: feedbackCount,
      mealPlanEntries: mealPlanCount,
      pantryItems: pantryCount,
      preferenceProfiles: profileCount,
      customIngredients: customIngCount,
      aiRequests: aiReqCount,
    );
  }
}
