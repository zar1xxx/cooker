import 'dart:convert';
import 'dart:io';

import 'package:chto_prigotovit/app/app_images.dart';
import 'package:chto_prigotovit/core/db/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppImages asset registry checks (A-01 / R1-04)', () {
    test('all 15 categories from ingredient_categories.json resolve to existing assets', () {
      final jsonFile = File('spec/data/ingredient_categories.json');
      expect(
        jsonFile.existsSync(),
        isTrue,
        reason: 'ingredient_categories.json must exist',
      );

      final rawCategories = jsonDecode(jsonFile.readAsStringSync()) as List;
      expect(rawCategories.length, 15);

      for (final item in rawCategories) {
        final id = (item as Map)['id'] as String;
        final assetPath = AppImages.categoryIconPath(id);

        expect(
          assetPath,
          isNotNull,
          reason: 'Missing category asset mapping for "$id"',
        );
        final file = File(assetPath!);
        expect(
          file.existsSync(),
          isTrue,
          reason: 'Asset file does not exist: $assetPath',
        );
      }
    });

    test('all 10 DishType values resolve to existing assets', () {
      for (final type in DishType.values) {
        final assetPath = AppImages.dishTypeIconPath(type);
        final file = File(assetPath);
        expect(
          file.existsSync(),
          isTrue,
          reason:
              'Asset file does not exist for DishType.${type.name}: $assetPath',
        );
      }
    });

    test('all 4 recipe placeholders exist on disk', () {
      final placeholders = [
        AppImages.placeholderSoup,
        AppImages.placeholderMain,
        AppImages.placeholderSide,
        AppImages.placeholderSalad,
      ];
      for (final path in placeholders) {
        final file = File(path);
        expect(
          file.existsSync(),
          isTrue,
          reason: 'Placeholder file does not exist: $path',
        );
      }
    });

    test('state illustrations exist on disk', () {
      expect(File(AppImages.stateNoDishes).existsSync(), isTrue);
      expect(File(AppImages.stateErrorGeneric).existsSync(), isTrue);
    });

    test('cooking illustrations exist on disk', () {
      expect(File(AppImages.cookingStepStart).existsSync(), isTrue);
      expect(File(AppImages.cookingTimerRing).existsSync(), isTrue);
    });

    testWidgets(
      'AppCategoryIcon, AppDishTypeIcon and AppRecipePlaceholder render without exceptions',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  AppCategoryIcon(
                    categoryId: 'vegetables',
                    size: 48,
                    semanticLabel: 'Овощи',
                  ),
                  AppDishTypeIcon(
                    dishType: DishType.soup,
                    size: 40,
                    semanticLabel: 'Суп',
                  ),
                  AppRecipePlaceholder(dishType: DishType.soup, height: 100),
                  AppRecipePlaceholder(
                    dishType: DishType.breakfast,
                    height: 100,
                  ),
                  AppStateIllustration(
                    assetPath: AppImages.stateNoDishes,
                    height: 100,
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AppCategoryIcon), findsOneWidget);
        expect(find.byType(AppDishTypeIcon), findsWidgets);
        expect(find.byType(AppRecipePlaceholder), findsNWidgets(2));
        expect(find.byType(AppStateIllustration), findsOneWidget);
      },
    );
  });
}
