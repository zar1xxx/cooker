import 'dart:io';

import 'package:chto_prigotovit/core/calendar/holiday_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime _d(int year, int month, int day) => DateTime.utc(year, month, day);

void main() {
  final calculator = HolidayCalculator.fromJsonString(
    File('assets/seed/holidays_ru.json').readAsStringSync(),
  );

  Set<String> codes(DateTime date) =>
      calculator.occasionsOn(date).map((o) => o.code).toSet();

  group('Orthodox Easter (algorithm, Gregorian date)', () {
    // Dates of the Russian Orthodox Church calendar (patriarchia.ru).
    final expected = <int, DateTime>{
      2024: _d(2024, 5, 5),
      2025: _d(2025, 4, 20),
      2026: _d(2026, 4, 12),
      2027: _d(2027, 5, 2),
      2028: _d(2028, 4, 16),
      2029: _d(2029, 4, 8),
      2030: _d(2030, 4, 28),
    };
    expected.forEach((year, date) {
      test('$year', () {
        expect(HolidayCalculator.orthodoxEaster(year), date);
      });
    });

    test('rejects years where the +13 days shift is wrong', () {
      expect(() => HolidayCalculator.orthodoxEaster(1899), throwsArgumentError);
      expect(() => HolidayCalculator.orthodoxEaster(2100), throwsArgumentError);
    });
  });

  group('Fixed state holidays (Labour Code art. 112)', () {
    final fixed = <String, DateTime>{
      'new_year': _d(2026, 1, 1),
      'christmas': _d(2026, 1, 7),
      'defender_day': _d(2026, 2, 23),
      'womens_day': _d(2026, 3, 8),
      'labour_day': _d(2026, 5, 1),
      'victory_day': _d(2026, 5, 9),
      'russia_day': _d(2026, 6, 12),
      'unity_day': _d(2026, 11, 4),
    };
    fixed.forEach((code, date) {
      test(code, () {
        expect(codes(date), contains(code));
        final previous = date.subtract(const Duration(days: 1));
        expect(codes(previous), isNot(contains(code)));
      });
    });
  });

  group('Floating occasions around Easter 2026 (Easter on April 12)', () {
    test('meatfare Sunday is a separate day before Maslenitsa', () {
      expect(codes(_d(2026, 2, 15)), contains('meatfare_sunday'));
      expect(codes(_d(2026, 2, 15)), isNot(contains('maslenitsa')));
      expect(codes(_d(2026, 2, 14)), isNot(contains('meatfare_sunday')));
    });

    test('Maslenitsa lasts from Monday P-55 to Sunday P-49', () {
      expect(codes(_d(2026, 2, 16)), contains('maslenitsa'));
      expect(codes(_d(2026, 2, 22)), contains('maslenitsa'));
      expect(codes(_d(2026, 2, 23)), isNot(contains('maslenitsa')));
    });

    test('Great Lent lasts from P-48 to P-1', () {
      expect(codes(_d(2026, 2, 22)), isNot(contains('great_lent')));
      expect(codes(_d(2026, 2, 23)), contains('great_lent'));
      expect(codes(_d(2026, 4, 11)), contains('great_lent'));
      expect(codes(_d(2026, 4, 12)), isNot(contains('great_lent')));
    });

    test('Palm Sunday, Easter, Bright Week, Trinity', () {
      expect(codes(_d(2026, 4, 5)), contains('palm_sunday'));
      expect(codes(_d(2026, 4, 12)), contains('easter'));
      expect(codes(_d(2026, 4, 13)), contains('bright_week'));
      expect(codes(_d(2026, 4, 18)), contains('bright_week'));
      expect(codes(_d(2026, 4, 19)), isNot(contains('bright_week')));
      expect(codes(_d(2026, 5, 31)), contains('trinity'));
    });

    test('Peter fast lasts from P+57 to July 11', () {
      expect(codes(_d(2026, 6, 7)), isNot(contains('peter_fast')));
      expect(codes(_d(2026, 6, 8)), contains('peter_fast'));
      expect(codes(_d(2026, 7, 11)), contains('peter_fast'));
      expect(codes(_d(2026, 7, 12)), isNot(contains('peter_fast')));
    });
  });

  group('Other years', () {
    test('Maslenitsa 2025: February 24 - March 2', () {
      expect(codes(_d(2025, 2, 23)), contains('meatfare_sunday'));
      expect(codes(_d(2025, 2, 24)), contains('maslenitsa'));
      expect(codes(_d(2025, 3, 2)), contains('maslenitsa'));
      expect(codes(_d(2025, 3, 3)), contains('great_lent'));
    });

    test('leap year 2028: February 29 is inside Great Lent', () {
      expect(codes(_d(2028, 2, 27)), contains('maslenitsa'));
      expect(codes(_d(2028, 2, 28)), contains('great_lent'));
      expect(codes(_d(2028, 2, 28)), isNot(contains('maslenitsa')));
      expect(codes(_d(2028, 2, 29)), contains('great_lent'));
      expect(codes(_d(2028, 3, 1)), contains('great_lent'));
    });

    test('Trinity and Peter fast in 2024', () {
      expect(codes(_d(2024, 6, 23)), contains('trinity'));
      expect(codes(_d(2024, 7, 1)), contains('peter_fast'));
    });
  });

  group('Fixed fasts', () {
    test('Dormition fast August 14-27, Apple Spas on August 19', () {
      expect(codes(_d(2026, 8, 13)), isNot(contains('dormition_fast')));
      expect(codes(_d(2026, 8, 14)), contains('dormition_fast'));
      expect(
        codes(_d(2026, 8, 19)),
        containsAll(['dormition_fast', 'apple_spas']),
      );
      expect(codes(_d(2026, 8, 27)), contains('dormition_fast'));
      expect(codes(_d(2026, 8, 28)), isNot(contains('dormition_fast')));
    });

    test('Nativity fast November 28 - January 6 crosses the new year', () {
      expect(codes(_d(2026, 11, 27)), isNot(contains('nativity_fast')));
      expect(codes(_d(2026, 11, 28)), contains('nativity_fast'));
      expect(codes(_d(2026, 12, 31)), contains('nativity_fast'));
      expect(codes(_d(2027, 1, 1)), contains('nativity_fast'));
      expect(codes(_d(2027, 1, 6)), contains('nativity_fast'));
      expect(codes(_d(2027, 1, 7)), isNot(contains('nativity_fast')));
      expect(codes(_d(2027, 1, 7)), contains('christmas'));
    });
  });

  group('occasionsOn', () {
    test('sorts holidays before feasts before fasts', () {
      // Aug 19: Apple Spas (feast) and Dormition fast.
      final list = calculator.occasionsOn(_d(2026, 8, 19));
      expect(list.first.type, OccasionType.feast);
      expect(list.last.type, OccasionType.fast);
      // Feb 23, 2026: Defender day (holiday) and the first day of Great Lent.
      final feb23 = calculator.occasionsOn(_d(2026, 2, 23));
      expect(feb23.first.code, 'defender_day');
    });

    test('ignores the time of day and the time zone flag', () {
      final noon = DateTime(2026, 2, 16, 12, 30);
      expect(
        calculator.occasionsOn(noon).map((o) => o.code),
        contains('maslenitsa'),
      );
    });

    test('an ordinary day has no occasions', () {
      expect(calculator.occasionsOn(_d(2026, 10, 15)), isEmpty);
    });
  });

  group('nextOccasion', () {
    test('finds an occasion that starts within the window', () {
      final found = calculator.nextOccasion(_d(2026, 2, 12));
      expect(found?.code, 'meatfare_sunday');
    });

    test('window 0 means only the day itself', () {
      expect(calculator.nextOccasion(_d(2026, 2, 12), windowDays: 0), isNull);
      expect(
        calculator.nextOccasion(_d(2026, 2, 15), windowDays: 0)?.code,
        'meatfare_sunday',
      );
    });

    test('returns null when nothing starts in the window', () {
      expect(calculator.nextOccasion(_d(2026, 10, 10)), isNull);
    });

    test('a holiday wins over a fast that starts the same day', () {
      final found = calculator.nextOccasion(_d(2026, 2, 20));
      expect(found?.code, 'defender_day');
    });

    test('looks across the new year', () {
      final found = calculator.nextOccasion(_d(2026, 12, 30));
      expect(found?.code, 'new_year');
    });

    test('an occasion already in progress is not "next"', () {
      // Great Lent started on Feb 23 and is active on Mar 1.
      final found = calculator.nextOccasion(_d(2026, 3, 1), windowDays: 1);
      expect(found, isNull);
    });
  });
}
