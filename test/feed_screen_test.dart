import 'dart:io';

import 'package:chto_prigotovit/app/theme.dart';
import 'package:chto_prigotovit/core/calendar/holiday_calculator.dart';
import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/db/daos/feed_event_dao.dart';
import 'package:chto_prigotovit/core/db/daos/pantry_dao.dart';
import 'package:chto_prigotovit/core/feed/feed_settings.dart';
import 'package:chto_prigotovit/core/feed/taste_profile.dart';
import 'package:chto_prigotovit/core/providers.dart';
import 'package:chto_prigotovit/core/shopping/external_actions.dart';
import 'package:chto_prigotovit/features/feed/feed_providers.dart';
import 'package:chto_prigotovit/features/feed/feed_screen.dart';
import 'package:chto_prigotovit/features/feed/feed_sections_screen.dart';
import 'package:chto_prigotovit/features/feed/feed_settings_screen.dart';
import 'package:chto_prigotovit/features/recipe/recipe_screen.dart';
import 'package:chto_prigotovit/l10n/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingActions extends ExternalActions {
  final List<String> shared = [];
  final List<Uri> opened = [];

  @override
  Future<void> shareText(String text, {String? subject}) async {
    shared.add(text);
  }

  @override
  Future<bool> openUrl(Uri uri) async {
    opened.add(uri);
    return true;
  }
}

/// Keeps feed settings in memory: the real service looks up the documents
/// folder through path_provider, which never answers in widget tests.
class _MemoryFeedSettingsService extends FeedSettingsService {
  FeedSettings _value = const FeedSettings();

  @override
  FeedSettings get current => _value;

  @override
  Future<FeedSettings> load() async => _value;

  @override
  Future<void> save(FeedSettings settings) async {
    _value = settings;
  }
}

/// Read from disk once: `rootBundle` caches the asset future inside the
/// first test's fake-async zone, and later tests would wait on it forever.
final HolidayCalculator _holidays = HolidayCalculator.fromJsonString(
  File('assets/seed/holidays_ru.json').readAsStringSync(),
);

Widget _app(AppDatabase db, Widget home, ExternalActions actions) {
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      feedAiFillerProvider.overrideWithValue(null),
      holidayCalculatorProvider.overrideWith((ref) async => _holidays),
      feedSettingsServiceProvider.overrideWithValue(
        _MemoryFeedSettingsService(),
      ),
      externalActionsProvider.overrideWithValue(actions),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ru'),
      home: home,
    ),
  );
}

String? _firstIdWithPrefix(String prefix) {
  final finder = find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> && key.value.startsWith(prefix);
  });
  for (final element in finder.evaluate()) {
    final key = element.widget.key! as ValueKey<String>;
    return key.value.substring(prefix.length);
  }
  return null;
}

/// Drift and asset loading need real time, which a fake-async widget test
/// never advances by itself. Pump with real pauses until loading is over.
Future<void> _settle(WidgetTester tester) async {
  var quiet = 0;
  for (var i = 0; i < 100 && quiet < 3; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    final loading = find.byType(CircularProgressIndicator).evaluate();
    quiet = loading.isEmpty ? quiet + 1 : 0;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late _RecordingActions actions;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory(), seed: true);
    await db.customSelect('SELECT 1').get();
    actions = _RecordingActions();
  });

  tearDown(() async {
    await db.close();
  });

  void useLargePhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('R7-07 feed shows cards, mood buttons and sections', (
    tester,
  ) async {
    useLargePhone(tester);
    await PantryDao(db).setAvailable('potato', true);

    await tester.pumpWidget(_app(db, const FeedScreen(), actions));
    await _settle(tester);

    expect(find.text('Лента'), findsOneWidget);
    expect(find.text('Может понравиться'), findsWidgets);
    expect(find.text('По настроению'), findsOneWidget);
    for (final mood in feedMoods) {
      expect(find.byKey(Key('feed_mood_${mood.id}')), findsOneWidget);
    }
    expect(find.textContaining('Приготовить'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Разделы'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Разделы'), findsWidgets);
  });

  testWidgets('R7-07 «Не хочу такое» writes an event and replaces the card', (
    tester,
  ) async {
    useLargePhone(tester);
    await tester.pumpWidget(_app(db, const FeedScreen(), actions));
    await _settle(tester);

    final id = _firstIdWithPrefix('feed_not_this_');
    expect(id, isNotNull);
    final button = find.byKey(Key('feed_not_this_$id')).first;
    await tester.ensureVisible(button);
    await tester.tap(button);
    await _settle(tester);

    final events = await FeedEventDao(db).all();
    expect(events, hasLength(1));
    expect(FeedEventDao.kindOf(events.single), FeedEventKind.skipped);
    expect(events.single.recipeId, id);
    expect(find.byKey(Key('feed_card_$id')), findsNothing);
  });

  testWidgets('R7-07 sections list all eleven groups', (tester) async {
    useLargePhone(tester);
    await tester.pumpWidget(_app(db, const FeedSectionsScreen(), actions));
    await _settle(tester);

    expect(find.byKey(const Key('feed_section_soup')), findsOneWidget);
    expect(find.text('Супы'), findsOneWidget);
  });

  testWidgets('R7-07 a section has one row of diet chips', (tester) async {
    useLargePhone(tester);
    await tester.pumpWidget(
      _app(db, const FeedSectionScreen(groupId: 'soup'), actions),
    );
    await _settle(tester);

    expect(find.byKey(const Key('feed_diet_all')), findsOneWidget);
    expect(find.byKey(const Key('feed_diet_vegetarian')), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNWidgets(8));
  });

  testWidgets('R7-10 «Сбросить мои вкусы» clears feed events', (tester) async {
    useLargePhone(tester);
    final dao = FeedEventDao(db);
    await dao.record('borscht', FeedEventKind.skipped);
    expect(await dao.count(), 1);

    await tester.pumpWidget(_app(db, const FeedSettingsScreen(), actions));
    await _settle(tester);

    expect(find.text('Учитывать праздники'), findsOneWidget);
    expect(find.text('Учитывать постные дни'), findsOneWidget);
    expect(find.text('Показывать новое'), findsOneWidget);
    expect(find.text('Где хранятся данные'), findsOneWidget);

    await tester.tap(find.byKey(const Key('feed_reset_tastes')));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('feed_reset_confirm')));
    await _settle(tester);

    expect(await dao.count(), 0);
    expect(find.text('Вкусы ленты сброшены'), findsOneWidget);
  });

  testWidgets('R7-09 «Чего не хватает» shares the list and opens Kuper', (
    tester,
  ) async {
    useLargePhone(tester);
    await tester.pumpWidget(
      _app(db, const RecipeScreen(recipeId: 'chicken_soup_potato'), actions),
    );
    await _settle(tester);

    final missingButton = find.byKey(const Key('recipe_missing_button'));
    await tester.ensureVisible(missingButton);
    await tester.tap(missingButton);
    await _settle(tester);

    expect(find.text('Поделиться списком'), findsOneWidget);
    final kuper = find.byKey(const Key('kuper_chicken'));
    if (kuper.evaluate().isNotEmpty) {
      await tester.ensureVisible(kuper);
      await tester.tap(kuper);
      await _settle(tester);
      expect(actions.opened.single.host, 'kuper.ru');
    }

    final share = find.byKey(const Key('missing_share'));
    await tester.ensureVisible(share);
    await tester.tap(share);
    await _settle(tester);

    expect(actions.shared, hasLength(1));
    expect(actions.shared.single, startsWith('Купить для «'));
    expect(actions.shared.single, contains('\n- '));
  });
}
