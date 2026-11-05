import 'dart:io';
import 'dart:ui' as ui;

import 'package:chto_prigotovit/app/theme.dart';
import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/db/daos/pantry_dao.dart';
import 'package:chto_prigotovit/core/db/daos/recipe_dao.dart';
import 'package:chto_prigotovit/core/providers.dart';
import 'package:chto_prigotovit/features/pantry/pantry_screen.dart';
import 'package:chto_prigotovit/features/recipe/cooking_screen.dart';
import 'package:chto_prigotovit/features/recipe/recipe_screen.dart';
import 'package:chto_prigotovit/features/suggestions/suggestions_screen.dart';
import 'package:chto_prigotovit/l10n/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _captureToPng(
  WidgetTester tester,
  Finder finder,
  String filename,
) async {
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(finder);
    final image = await boundary.toImage(pixelRatio: 1.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData != null) {
      final bytes = byteData.buffer.asUint8List();
      final file = File('docs/reports/img/$filename');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
    }
  });
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory(), seed: true);
    await db.customSelect('SELECT 1').get();
  });

  tearDown(() async {
    await db.close();
  });

  Widget wrapWithRepaintBoundary({
    required Widget child,
    required Key boundaryKey,
  }) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        recipeDaoProvider.overrideWithValue(RecipeDao(db)),
        pantryDaoProvider.overrideWithValue(PantryDao(db)),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ru')],
        locale: const Locale('ru'),
        home: RepaintBoundary(
          key: boundaryKey,
          child: Scaffold(body: child),
        ),
      ),
    );
  }

  group('A-01 / R1-04 Screenshot Generation into docs/reports/img/', () {
    testWidgets('captures pantry categories screen with assets', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const boundaryKey = ValueKey('pantry_boundary');
      await tester.pumpWidget(
        wrapWithRepaintBoundary(
          boundaryKey: boundaryKey,
          child: const PantryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await _captureToPng(tester, find.byKey(boundaryKey), 'pantry_screen.png');
      expect(File('docs/reports/img/pantry_screen.png').existsSync(), isTrue);
    });

    testWidgets('captures recipe details with placeholder header', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const boundaryKey = ValueKey('recipe_boundary');
      await tester.pumpWidget(
        wrapWithRepaintBoundary(
          boundaryKey: boundaryKey,
          child: const RecipeScreen(recipeId: 'chicken_soup_potato'),
        ),
      );
      await tester.pumpAndSettle();

      await _captureToPng(tester, find.byKey(boundaryKey), 'recipe_screen.png');
      expect(File('docs/reports/img/recipe_screen.png').existsSync(), isTrue);
    });

    testWidgets('captures cooking screen step 1 with step_start illustration', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const boundaryKey = ValueKey('cooking_boundary');
      await tester.pumpWidget(
        wrapWithRepaintBoundary(
          boundaryKey: boundaryKey,
          child: const CookingScreen(recipeId: 'chicken_soup_potato'),
        ),
      );
      await tester.pumpAndSettle();

      await _captureToPng(tester, find.byKey(boundaryKey), 'cooking_step1.png');
      expect(File('docs/reports/img/cooking_step1.png').existsSync(), isTrue);
    });

    testWidgets(
      'captures empty suggestions screen with no_dishes illustration',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const boundaryKey = ValueKey('suggestions_boundary');
        await tester.pumpWidget(
          wrapWithRepaintBoundary(
            boundaryKey: boundaryKey,
            child: const SuggestionsScreen(),
          ),
        );
        await tester.pumpAndSettle();

        await _captureToPng(
          tester,
          find.byKey(boundaryKey),
          'suggestions_empty.png',
        );
        expect(
          File('docs/reports/img/suggestions_empty.png').existsSync(),
          isTrue,
        );
      },
    );
  });
}
