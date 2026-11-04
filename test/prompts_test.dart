import 'package:chto_prigotovit/core/ai/prompts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('renderTemplate', () {
    test('renders variables and handles null/empty lists with "нет"', () {
      const template =
          'Привет, {{name}}! Список: {{items}}. Запреты: {{empty_list}}. Значение: {{missing}}.';
      final result = renderTemplate(template, {
        'name': 'Бабушка',
        'items': ['картофель', 'морковь', 'лук'],
        'empty_list': <String>[],
        'missing': null,
      });

      expect(
        result,
        equals(
          'Привет, Бабушка! Список: картофель, морковь, лук. Запреты: нет. Значение: нет.',
        ),
      );
    });

    test('renders {{#if}} block when condition is truthy', () {
      const template =
          'Начало.{{#if show_extra}}\nДополнительный текст: {{extra}}.{{/if}}\nКонец.';
      final result = renderTemplate(template, {
        'show_extra': true,
        'extra': 'важная информация',
      });

      expect(
        result,
        equals('Начало.\nДополнительный текст: важная информация.\nКонец.'),
      );
    });

    test('omits {{#if}} block when condition is false or empty', () {
      const template =
          'Начало.{{#if show_extra}}\nДополнительный текст.{{/if}}\nКонец.';
      final result1 = renderTemplate(template, {'show_extra': false});
      expect(result1, equals('Начало.\nКонец.'));

      final result2 = renderTemplate(template, {'show_extra': null});
      expect(result2, equals('Начало.\nКонец.'));

      final result3 = renderTemplate(template, {'show_extra': ''});
      expect(result3, equals('Начало.\nКонец.'));
    });
  });

  group('PromptTemplates builders', () {
    final templates = PromptTemplates.defaults();

    test('buildSystem embeds schema only when schemaInPrompt is true', () {
      final promptNoSchema = templates.buildSystem(
        schemaJson: '{"type": "object"}',
        schemaInPrompt: false,
      );
      expect(promptNoSchema, isNot(contains('Схема ответа (JSON Schema)')));

      final promptWithSchema = templates.buildSystem(
        schemaJson: '{"type": "object"}',
        schemaInPrompt: true,
      );
      expect(promptWithSchema, contains('Схема ответа (JSON Schema)'));
      expect(promptWithSchema, contains('{"type": "object"}'));
    });

    test('buildSuggestDishes enforces limits: doNotSuggest <= 40, likes/dislikes <= 5', () {
      final longDoNotSuggest = List.generate(50, (i) => 'Блюдо $i');
      final longLikes = List.generate(10, (i) => 'Вкус $i');
      final longDislikes = List.generate(10, (i) => 'НеЛюблю $i');

      final prompt = templates.buildSuggestDishes(
        availableIngredients: ['картофель', 'курица'],
        doNotSuggest: longDoNotSuggest,
        likes: longLikes,
        dislikes: longDislikes,
      );

      expect(prompt, contains('Блюдо 39'));
      expect(prompt, isNot(contains('Блюдо 40'))); // capped at 40 (0..39)
      expect(prompt, contains('Вкус 4'));
      expect(prompt, isNot(contains('Вкус 5'))); // capped at 5 (0..4)
      expect(prompt, contains('НеЛюблю 4'));
      expect(prompt, isNot(contains('НеЛюблю 5')));
    });

    test(
      'buildFullRecipe includes retryReason if present and omits when null',
      () {
        final promptWithoutRetry = templates.buildFullRecipe(
          title: 'Борщ',
          dishType: 'soup',
          difficulty: 'medium',
          mainIngredients: ['свёкла', 'говядина'],
          availableIngredients: ['картофель', 'морковь'],
        );
        expect(
          promptWithoutRetry,
          isNot(contains('Предыдущий ответ отклонён')),
        );

        final promptWithRetry = templates.buildFullRecipe(
          title: 'Борщ',
          dishType: 'soup',
          difficulty: 'medium',
          mainIngredients: ['свёкла', 'говядина'],
          availableIngredients: ['картофель', 'морковь'],
          retryReason: 'В шаге 2 нет таймера варки',
        );
        expect(
          promptWithRetry,
          contains('Предыдущий ответ отклонён: В шаге 2 нет таймера варки'),
        );
      },
    );
  });
}
