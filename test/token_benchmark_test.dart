// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:chto_prigotovit/core/ai/prompts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Token consumption benchmark on sample requests (S3-10)', () async {
    final templates = PromptTemplates.defaults();

    final suggestSchemaFile = File(
      'spec/ai/schemas/suggest_dishes.schema.json',
    );
    final fullRecipeSchemaFile = File(
      'spec/ai/schemas/full_recipe.schema.json',
    );

    final suggestSchema = jsonDecode(await suggestSchemaFile.readAsString());
    final fullRecipeSchema = jsonDecode(
      await fullRecipeSchemaFile.readAsString(),
    );

    final suggestFixtureFile = File('spec/fixtures/ai/suggest_dishes_ok.json');
    final fullRecipeFixtureFile = File('spec/fixtures/ai/full_recipe_ok.json');

    final suggestFixture = await suggestFixtureFile.readAsString();
    final fullRecipeFixture = await fullRecipeFixtureFile.readAsString();

    // 1. LM STUDIO (Schema passed in response_format, not in prompt)
    final lmSuggestSystem = templates.buildSystem(
      schemaJson: jsonEncode(suggestSchema),
      schemaInPrompt: false,
    );
    final lmSuggestUser = templates.buildSuggestDishes(
      availableIngredients: [
        'картофель',
        'морковь',
        'лук репчатый',
        'куриное филе',
        'масло растительное',
        'соль',
      ],
      likes: ['домашняя кухня', 'супы'],
      dislikes: ['острое'],
      doNotSuggest: ['Борщ классический', 'Щи из свежей капусты'],
      count: 6,
    );

    final lmSuggestIn = _estimateTokens('$lmSuggestSystem\n$lmSuggestUser');
    final lmSuggestOut = _estimateTokens(suggestFixture);

    final lmRecipeSystem = templates.buildSystem(
      schemaJson: jsonEncode(fullRecipeSchema),
      schemaInPrompt: false,
    );
    final lmRecipeUser = templates.buildFullRecipe(
      title: 'Картофельные драники с луком',
      dishType: 'main',
      difficulty: 'easy',
      servings: 4,
      mainIngredients: ['картофель', 'лук репчатый', 'яйца'],
      availableIngredients: [
        'картофель',
        'лук репчатый',
        'яйца куриные',
        'мука пшеничная',
        'масло растительное',
        'соль',
      ],
    );

    final lmRecipeIn = _estimateTokens('$lmRecipeSystem\n$lmRecipeUser');
    final lmRecipeOut = _estimateTokens(fullRecipeFixture);

    // 2. GIGACHAT (Schema embedded into system prompt)
    final gigaSuggestSystem = templates.buildSystem(
      schemaJson: jsonEncode(suggestSchema),
      schemaInPrompt: true,
    );
    final gigaSuggestIn = _estimateTokens('$gigaSuggestSystem\n$lmSuggestUser');
    final gigaSuggestOut = lmSuggestOut;

    final gigaRecipeSystem = templates.buildSystem(
      schemaJson: jsonEncode(fullRecipeSchema),
      schemaInPrompt: true,
    );
    final gigaRecipeIn = _estimateTokens('$gigaRecipeSystem\n$lmRecipeUser');
    final gigaRecipeOut = lmRecipeOut;

    final lmTotalCycle = lmSuggestIn + lmSuggestOut + lmRecipeIn + lmRecipeOut;
    final gigaTotalCycle =
        gigaSuggestIn + gigaSuggestOut + gigaRecipeIn + gigaRecipeOut;

    // Verify estimates match expectations
    expect(lmSuggestIn, greaterThan(100));
    expect(lmSuggestOut, greaterThan(100));
    expect(lmRecipeIn, greaterThan(100));
    expect(lmRecipeOut, greaterThan(200));
    expect(lmTotalCycle, lessThan(5000));

    expect(
      gigaSuggestIn,
      greaterThan(lmSuggestIn),
    ); // embedded schema adds tokens
    expect(gigaRecipeIn, greaterThan(lmRecipeIn));
    expect(gigaTotalCycle, lessThan(10000)); // ТЗ 6.1.1 estimate: 5-10k

    // Output measurements for reporting
    print('\n============================================================');
    print('TOKEN CONSUMPTION REPORT (S3-10 / TZ 6.1.1):');
    print('1. LM Studio:');
    print(
      '   - suggest_dishes: in=$lmSuggestIn, out=$lmSuggestOut, total=${lmSuggestIn + lmSuggestOut}',
    );
    print(
      '   - full_recipe:    in=$lmRecipeIn, out=$lmRecipeOut, total=${lmRecipeIn + lmRecipeOut}',
    );
    print('   - 1 full cycle:   $lmTotalCycle tokens');
    print('2. GigaChat:');
    print(
      '   - suggest_dishes: in=$gigaSuggestIn, out=$gigaSuggestOut, total=${gigaSuggestIn + gigaSuggestOut}',
    );
    print(
      '   - full_recipe:    in=$gigaRecipeIn, out=$gigaRecipeOut, total=${gigaRecipeIn + gigaRecipeOut}',
    );
    print('   - 1 full cycle:   $gigaTotalCycle tokens');
    print('============================================================\n');
  });
}

int _estimateTokens(String text) {
  if (text.isEmpty) return 0;
  int cyrillicChars = 0;
  int asciiChars = 0;

  for (final codeUnit in text.codeUnits) {
    if (codeUnit >= 0x0400 && codeUnit <= 0x04FF) {
      cyrillicChars++;
    } else {
      asciiChars++;
    }
  }

  final cyrillicTokens = (cyrillicChars / 2.2).ceil();
  final asciiTokens = (asciiChars / 3.8).ceil();
  return cyrillicTokens + asciiTokens;
}
