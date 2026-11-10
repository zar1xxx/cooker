import 'dart:convert';

/// Kind of a calendar occasion.
///
/// The order matters: it is used to sort occasions that fall on one day
/// (state holidays first, then church feasts, then fasts).
enum OccasionType { holiday, feast, fast }

/// One occasion with a concrete inclusive date range (date-only, UTC).
class Occasion {
  const Occasion({
    required this.code,
    required this.name,
    required this.type,
    required this.hint,
    required this.start,
    required this.end,
  });

  /// Stable machine code, for example `maslenitsa`.
  final String code;

  /// Russian display name.
  final String name;

  final OccasionType type;

  /// Short culinary hint in Russian, for example "Блины, сыр, творог".
  final String hint;

  /// First day of the occasion (UTC midnight).
  final DateTime start;

  /// Last day of the occasion (UTC midnight), equal to [start] for one day.
  final DateTime end;

  bool get isSingleDay => start == end;

  /// Whether [date] (date-only, UTC) is inside this occasion.
  bool covers(DateTime date) => !date.isBefore(start) && !date.isAfter(end);

  @override
  String toString() => 'Occasion($code, $start..$end)';
}

/// Offline calculator of Russian state holidays, church feasts and fasts.
///
/// Rules come from `assets/seed/holidays_ru.json`; the date of Orthodox Easter
/// is calculated here (Alexandrian paschalion, Julian date + 13 days, valid for
/// the years 1900-2099). Floating occasions are offsets in days from Easter.
/// No network access, no Flutter dependencies.
class HolidayCalculator {
  HolidayCalculator(List<Map<String, dynamic>> rules)
    : _rules = List.unmodifiable(rules.map(_Rule.fromJson));

  /// Creates a calculator from the content of `holidays_ru.json`.
  factory HolidayCalculator.fromJsonString(String source) {
    final decoded = jsonDecode(source) as Map<String, dynamic>;
    final list = (decoded['occasions'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    return HolidayCalculator(list);
  }

  final List<_Rule> _rules;

  /// Orthodox Easter in the Gregorian calendar (UTC midnight).
  ///
  /// Throws [ArgumentError] outside 1900-2099, where the Julian to Gregorian
  /// shift is not 13 days.
  static DateTime orthodoxEaster(int year) {
    if (year < 1900 || year > 2099) {
      throw ArgumentError.value(year, 'year', 'must be in 1900..2099');
    }
    final a = year % 4;
    final b = year % 7;
    final c = year % 19;
    final d = (19 * c + 15) % 30;
    final e = (2 * a + 4 * b - d + 34) % 7;
    final sum = d + e + 114;
    final julianMonth = sum ~/ 31;
    final julianDay = sum % 31 + 1;
    // DateTime.utc normalises a day overflow (for example April 38 -> May 8).
    return DateTime.utc(year, julianMonth, julianDay + 13);
  }

  /// All occasions active on [date], sorted: holidays, feasts, fasts.
  List<Occasion> occasionsOn(DateTime date) {
    final day = _dateOnly(date);
    final result = <Occasion>[];
    for (final rule in _rules) {
      // A fast can start in the previous year (Nov 28 - Jan 6).
      for (final year in [day.year - 1, day.year]) {
        final occasion = rule.occasion(year);
        if (occasion.covers(day)) {
          result.add(occasion);
          break;
        }
      }
    }
    result.sort(_byTypeThenCode);
    return result;
  }

  /// The nearest occasion that **starts** from [from] up to [windowDays] days
  /// later (0 means only [from] itself). If several start on the same day,
  /// holidays win over feasts and feasts over fasts. Returns null if none.
  Occasion? nextOccasion(DateTime from, {int windowDays = 3}) {
    final first = _dateOnly(from);
    for (var offset = 0; offset <= windowDays; offset++) {
      final day = _shift(first, offset);
      final starting = <Occasion>[];
      for (final rule in _rules) {
        final occasion = rule.occasion(day.year);
        if (occasion.start == day) {
          starting.add(occasion);
        }
      }
      if (starting.isNotEmpty) {
        starting.sort(_byTypeThenCode);
        return starting.first;
      }
    }
    return null;
  }

  static int _byTypeThenCode(Occasion a, Occasion b) {
    final byType = a.type.index.compareTo(b.type.index);
    return byType != 0 ? byType : a.code.compareTo(b.code);
  }
}

DateTime _dateOnly(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day);

DateTime _shift(DateTime date, int days) =>
    DateTime.utc(date.year, date.month, date.day + days);

enum _Kind { fixed, easter, easterToFixed, fixedRange }

class _Rule {
  const _Rule({
    required this.code,
    required this.name,
    required this.type,
    required this.hint,
    required this.kind,
    required this.month,
    required this.day,
    required this.startOffset,
    required this.endOffset,
    required this.startMonth,
    required this.startDay,
    required this.endMonth,
    required this.endDay,
  });

  factory _Rule.fromJson(Map<String, dynamic> json) {
    int number(String key) => (json[key] as int?) ?? 0;
    final kindName = json['kind'] as String;
    final kind = switch (kindName) {
      'fixed' => _Kind.fixed,
      'easter' => _Kind.easter,
      'easter_to_fixed' => _Kind.easterToFixed,
      'fixed_range' => _Kind.fixedRange,
      _ => throw FormatException('Unknown occasion kind: $kindName'),
    };
    final typeName = json['type'] as String;
    final type = switch (typeName) {
      'holiday' => OccasionType.holiday,
      'feast' => OccasionType.feast,
      'fast' => OccasionType.fast,
      _ => throw FormatException('Unknown occasion type: $typeName'),
    };
    return _Rule(
      code: json['code'] as String,
      name: json['name'] as String,
      type: type,
      hint: json['hint'] as String,
      kind: kind,
      month: number('month'),
      day: number('day'),
      startOffset: number('start_offset'),
      endOffset: number('end_offset'),
      startMonth: number('start_month'),
      startDay: number('start_day'),
      endMonth: number('end_month'),
      endDay: number('end_day'),
    );
  }

  final String code;
  final String name;
  final OccasionType type;
  final String hint;
  final _Kind kind;
  final int month;
  final int day;
  final int startOffset;
  final int endOffset;
  final int startMonth;
  final int startDay;
  final int endMonth;
  final int endDay;

  /// The occasion instance that **starts** in [year].
  Occasion occasion(int year) {
    final (start, end) = _range(year);
    return Occasion(
      code: code,
      name: name,
      type: type,
      hint: hint,
      start: start,
      end: end,
    );
  }

  (DateTime, DateTime) _range(int year) {
    switch (kind) {
      case _Kind.fixed:
        final date = DateTime.utc(year, month, day);
        return (date, date);
      case _Kind.easter:
        final easter = HolidayCalculator.orthodoxEaster(year);
        return (_shift(easter, startOffset), _shift(easter, endOffset));
      case _Kind.easterToFixed:
        final easter = HolidayCalculator.orthodoxEaster(year);
        return (
          _shift(easter, startOffset),
          DateTime.utc(year, endMonth, endDay),
        );
      case _Kind.fixedRange:
        final start = DateTime.utc(year, startMonth, startDay);
        final endYear = endMonth < startMonth ? year + 1 : year;
        return (start, DateTime.utc(endYear, endMonth, endDay));
    }
  }
}
