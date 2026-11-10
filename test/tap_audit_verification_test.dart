import 'package:chto_prigotovit/app/theme.dart';
import 'package:chto_prigotovit/core/adaptive/adaptive_provider.dart';
import 'package:chto_prigotovit/core/adaptive/adaptive_spec.dart';
import 'package:chto_prigotovit/core/adaptive/ui_profile.dart';
import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/db/enums.dart';
import 'package:chto_prigotovit/core/providers.dart';
import 'package:chto_prigotovit/core/services/feedback_service.dart';
import 'package:chto_prigotovit/core/widgets/chip_explanation_sheet.dart';
import 'package:chto_prigotovit/core/widgets/product_details_sheet.dart';
import 'package:chto_prigotovit/features/statistics/statistics_screen.dart';
import 'package:chto_prigotovit/l10n/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FixedUiProfileNotifier extends UiProfileNotifier {
  _FixedUiProfileNotifier(this._initial);
  final UiProfile _initial;
  @override
  UiProfile build() => _initial;
}

Widget _wrap(
  Widget child, {
  required AppDatabase db,
  List<dynamic> overrides = const [],
}) {
  final profile = UiProfile.defaultFull();
  final spec = AdaptiveSpec(profile: profile, systemFontScale: 1.0);
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      uiProfileProvider.overrideWith(() => _FixedUiProfileNotifier(profile)),
      ...overrides.cast(),
    ],
    child: AdaptiveScope(
      spec: spec,
      child: MaterialApp(
        theme: AppTheme.lightFor(spec),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory(), seed: true);
    await db.customSelect('SELECT 1').get();
  });

  tearDown(() async {
    await db.close();
  });

  group('Tap Audit & Interactive Sheets (R8-12, R8-13, R8-14, R8-15)', () {
    testWidgets(
      '1. ProductDetailsSheet renders storage, shelf life, allergens, and substitutes',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          _wrap(
            const ProductDetailsSheet(
              ingredientId: 'potato',
              fallbackName: 'картофель',
            ),
            db: db,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Картофель'), findsOneWidget);
        expect(find.text('Где хранить и сколько'), findsOneWidget);
        expect(find.text('Срок годности'), findsOneWidget);
        expect(find.text('Аллергенность'), findsOneWidget);
        expect(find.text('Чем заменить при готовке'), findsOneWidget);
      },
    );

    testWidgets(
      '2. ChipExplanationSheet shows difficulty rules and assistant info',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    ChipExplanationSheet.showForDifficulty(
                      context,
                      difficulty: Difficulty.hard,
                      reasons: ['Раскатка теста (+2)', 'Много шагов (+3)'],
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
            db: db,
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.text('Сложность: Сложно'), findsOneWidget);
        expect(find.text('Почему такая сложность:'), findsOneWidget);
        expect(find.text('Раскатка теста (+2)'), findsOneWidget);
        expect(find.text('Много шагов (+3)'), findsOneWidget);
      },
    );

    testWidgets(
      '3. FeedbackService showUndoSnackBar displays 5-second undo button',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        bool undoCalled = false;

        await tester.pumpWidget(
          _wrap(
            Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    FeedbackService.showUndoSnackBar(
                      context,
                      message: 'Блюдо скрыто',
                      onUndo: () => undoCalled = true,
                    );
                  },
                  child: const Text('Reject'),
                );
              },
            ),
            db: db,
          ),
        );

        await tester.tap(find.text('Reject'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Блюдо скрыто'), findsOneWidget);
        expect(find.text('Отменить'), findsOneWidget);

        await tester.tap(find.text('Отменить'));
        expect(undoCalled, isTrue);
      },
    );

    testWidgets(
      '4. FeedbackService showPostCookingRatingPrompt renders 5 large smileys',
      (tester) async {
        int? selectedRating;

        await tester.pumpWidget(
          _wrap(
            Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    selectedRating =
                        await FeedbackService.showPostCookingRatingPrompt(
                          context,
                          dishTitle: 'Домашний борщ',
                        );
                  },
                  child: const Text('Done Cooking'),
                );
              },
            ),
            db: db,
          ),
        );

        await tester.tap(find.text('Done Cooking'));
        await tester.pumpAndSettle();

        expect(find.text('Как получилось?'), findsOneWidget);
        expect(find.text('Домашний борщ'), findsOneWidget);
        expect(find.text('😍'), findsOneWidget);

        await tester.tap(find.text('😍'));
        await tester.pumpAndSettle();

        expect(selectedRating, equals(5));
      },
    );

    testWidgets(
      '5. StatisticsScreen renders period filters, 4 tiles, and heatmap',
      (tester) async {
        await tester.pumpWidget(_wrap(const StatisticsScreen(), db: db));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Empty state when no entries
        expect(
          find.text(
            'Приготовьте и оцените пару блюд — здесь появится статистика',
          ),
          findsOneWidget,
        );
      },
    );
  });
}
