import 'dart:io';
import 'dart:ui' as ui;

import 'package:chto_prigotovit/app/theme.dart';
import 'package:chto_prigotovit/core/ai/ai_failure.dart';
import 'package:chto_prigotovit/core/ai/ai_service.dart';
import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/db/daos/pantry_dao.dart';
import 'package:chto_prigotovit/core/providers.dart';
import 'package:chto_prigotovit/features/calendar/calendar_screen.dart';
import 'package:chto_prigotovit/features/calendar/today_screen.dart';
import 'package:chto_prigotovit/features/history/history_screen.dart';
import 'package:chto_prigotovit/features/pantry/pantry_screen.dart';
import 'package:chto_prigotovit/features/recipe/cooking_screen.dart';
import 'package:chto_prigotovit/features/recipe/recipe_screen.dart';
import 'package:chto_prigotovit/features/settings/ai_diagnostics_screen.dart';
import 'package:chto_prigotovit/features/suggestions/suggestions_screen.dart';
import 'package:chto_prigotovit/l10n/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

// R2-03: screenshots for reports. Widget tests render text with the Ahem
// test font (boxes instead of letters) and do not wait for asset images, so
// this file loads real fonts from the Flutter SDK and precaches every image
// before capturing. Fonts are loaded only here, so other tests keep Ahem.

Future<void> _loadFont(String family, List<String> files) async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) return;
  final dir = '$root/bin/cache/artifacts/material_fonts';
  final loader = FontLoader(family);
  var added = false;
  for (final name in files) {
    final file = File('$dir/$name');
    if (file.existsSync()) {
      final bytes = file.readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
      added = true;
    }
  }
  if (added) await loader.load();
}

Future<void> _precacheImages(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      final image = element.widget as Image;
      await precacheImage(image.image, element);
    }
  });
  await tester.pumpAndSettle();
}

Future<void> _capture(
  WidgetTester tester,
  Key key,
  String filename, {
  bool precache = true,
}) async {
  if (precache) {
    await _precacheImages(tester);
  }
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(key),
    );
    final image = await boundary.toImage(pixelRatio: 2.0);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) return;
    final file = File('docs/reports/img/$filename');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(data.buffer.asUint8List());
  });
}

class _FakeAiDishesNotifier extends AiDishesNotifier {
  _FakeAiDishesNotifier(this._initialResult);
  final AiResult<List<AiDishSuggestion>> _initialResult;

  @override
  Future<AiResult<List<AiDishSuggestion>>> build() async => _initialResult;
}

void main() {
  late AppDatabase db;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('ru', null);
    await _loadFont('Roboto', const [
      'Roboto-Regular.ttf',
      'Roboto-Medium.ttf',
      'Roboto-Bold.ttf',
    ]);
    await _loadFont('MaterialIcons', const ['MaterialIcons-Regular.otf']);
  });

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory(), seed: true);
    await db.customSelect('SELECT 1').get();
  });

  tearDown(() async {
    await db.close();
  });

  Widget app(Widget screen, Key key) {
    return ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ru')],
        locale: const Locale('ru'),
        home: RepaintBoundary(key: key, child: screen),
      ),
    );
  }

  final screens = <String, Widget>{
    'today_screen.png': const TodayScreen(),
    'pantry_screen.png': const PantryScreen(),
    'suggestions_empty.png': const SuggestionsScreen(),
    'recipe_screen.png': const RecipeScreen(recipeId: 'chicken_soup_potato'),
    'cooking_step1.png': const CookingScreen(recipeId: 'chicken_soup_potato'),
    'calendar_screen.png': const CalendarScreen(),
    'history_screen.png': const HistoryScreen(),
  };

  group('R2-03 readable screenshots in docs/reports/img/', () {
    for (final entry in screens.entries) {
      testWidgets('captures ${entry.key}', (tester) async {
        tester.view.physicalSize = const Size(412 * 2, 915 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final key = ValueKey(entry.key);
        await tester.pumpWidget(app(entry.value, key));
        await tester.pumpAndSettle();
        await _capture(tester, key, entry.key);

        expect(File('docs/reports/img/${entry.key}').existsSync(), isTrue);
      });
    }

    testWidgets('captures suggestions_error_banner.png', (tester) async {
      tester.view.physicalSize = const Size(412 * 2, 915 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final pantryDao = PantryDao(db);
      await pantryDao.setAvailable('chicken_breast', true);
      await pantryDao.setAvailable('potato', true);

      const key = ValueKey('suggestions_error_banner.png');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            pantryDaoProvider.overrideWithValue(pantryDao),
            aiDishesProvider.overrideWith(
              () => _FakeAiDishesNotifier(
                const AiResult.failure(AiFailure.timeout()),
              ),
            ),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('ru')],
            locale: const Locale('ru'),
            home: const RepaintBoundary(key: key, child: SuggestionsScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _capture(tester, key, 'suggestions_error_banner.png');
      expect(
        File('docs/reports/img/suggestions_error_banner.png').existsSync(),
        isTrue,
      );
    });

    testWidgets('captures ai_diagnostics.png', (tester) async {
      tester.view.physicalSize = const Size(412 * 2, 915 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const key = ValueKey('ai_diagnostics.png');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('ru')],
            locale: const Locale('ru'),
            home: const RepaintBoundary(key: key, child: AiDiagnosticsScreen()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await _capture(tester, key, 'ai_diagnostics.png', precache: false);
      expect(File('docs/reports/img/ai_diagnostics.png').existsSync(), isTrue);
    });
  });
}
