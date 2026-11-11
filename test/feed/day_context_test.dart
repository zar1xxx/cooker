import 'dart:io';

import 'package:chto_prigotovit/core/calendar/holiday_calculator.dart';
import 'package:chto_prigotovit/core/catalog/recipe_tags.dart';
import 'package:chto_prigotovit/core/feed/day_context.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final calculator = HolidayCalculator.fromJsonString(
    File('assets/seed/holidays_ru.json').readAsStringSync(),
  );

  DayContext at(DateTime now) =>
      DayContext.build(now: now, calculator: calculator);

  group('day part and season', () {
    test('day part boundaries', () {
      expect(DayContext.dayPartOf(0), DayPart.night);
      expect(DayContext.dayPartOf(4), DayPart.night);
      expect(DayContext.dayPartOf(5), DayPart.morning);
      expect(DayContext.dayPartOf(10), DayPart.morning);
      expect(DayContext.dayPartOf(11), DayPart.day);
      expect(DayContext.dayPartOf(16), DayPart.day);
      expect(DayContext.dayPartOf(17), DayPart.evening);
      expect(DayContext.dayPartOf(22), DayPart.evening);
      expect(DayContext.dayPartOf(23), DayPart.night);
    });

    test('season by month', () {
      expect(DayContext.seasonOf(12), Season.winter);
      expect(DayContext.seasonOf(1), Season.winter);
      expect(DayContext.seasonOf(2), Season.winter);
      expect(DayContext.seasonOf(3), Season.spring);
      expect(DayContext.seasonOf(5), Season.spring);
      expect(DayContext.seasonOf(6), Season.summer);
      expect(DayContext.seasonOf(8), Season.summer);
      expect(DayContext.seasonOf(9), Season.autumn);
      expect(DayContext.seasonOf(11), Season.autumn);
    });
  });

  group('occasions', () {
    test(
      'two days before Meatfare Sunday 2026 it is the upcoming occasion',
      () {
        final context = at(DateTime(2026, 2, 13, 9));
        expect(context.upcomingOccasion?.code, 'meatfare_sunday');
        expect(context.featuredOccasion?.code, 'meatfare_sunday');
        expect(context.daysToFeaturedOccasion, 2);
        expect(context.isFastingDay, isFalse);
      },
    );

    test('during Maslenitsa week it is featured with zero days', () {
      final context = at(DateTime(2026, 2, 18, 12));
      expect(context.featuredOccasion?.code, 'maslenitsa');
      expect(context.daysToFeaturedOccasion, 0);
    });

    test('Great Lent is a fasting day but not a featured occasion', () {
      final context = at(DateTime(2026, 3, 10, 12));
      expect(context.isFastingDay, isTrue);
      expect(context.featuredOccasion, isNull);
      expect(context.daysToFeaturedOccasion, isNull);
    });

    test('three days before the New Year during the Nativity fast', () {
      final context = at(DateTime(2026, 12, 29, 18));
      expect(context.isFastingDay, isTrue);
      expect(context.featuredOccasion?.code, 'new_year');
      expect(context.daysToFeaturedOccasion, 3);
    });

    test('the window is configurable', () {
      final context = DayContext.build(
        now: DateTime(2026, 12, 29, 18),
        calculator: calculator,
        occasionWindowDays: 1,
      );
      expect(context.upcomingOccasion, isNull);
    });

    test('an ordinary day has no featured occasion', () {
      final context = at(DateTime(2026, 7, 15, 12));
      expect(context.featuredOccasion, isNull);
      expect(context.isFastingDay, isFalse);
    });
  });

  group('date handling', () {
    test('leap day', () {
      final context = at(DateTime(2028, 2, 29, 12));
      expect(context.date, DateTime.utc(2028, 2, 29));
      expect(context.weekday, DateTime.tuesday);
      expect(context.season, Season.winter);
    });

    test('weekend flag', () {
      expect(at(DateTime(2026, 3, 1, 12)).isWeekend, isTrue);
      expect(at(DateTime(2026, 3, 2, 12)).isWeekend, isFalse);
    });

    test('time of day does not change the calendar day', () {
      final late = at(DateTime(2026, 5, 4, 23, 59));
      final early = at(DateTime(2026, 5, 4, 0, 1));
      expect(late.date, early.date);
      expect(late.dayPart, DayPart.night);
      expect(early.dayPart, DayPart.night);
    });
  });

  group('manual choices', () {
    test('mood, cuisine and pantry are kept and can be cleared', () {
      final base = at(DateTime(2026, 7, 15, 12));
      final changed = base.copyWith(
        mood: MoodTag.cozy,
        cuisine: 'it',
        pantryIds: const {'potato'},
      );
      expect(changed.mood, MoodTag.cozy);
      expect(changed.cuisine, 'it');
      expect(changed.pantryIds, {'potato'});

      final cleared = changed.copyWith(clearMood: true, clearCuisine: true);
      expect(cleared.mood, isNull);
      expect(cleared.cuisine, isNull);
      expect(cleared.pantryIds, {'potato'});
    });
  });
}
