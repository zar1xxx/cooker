import '../calendar/holiday_calculator.dart';
import '../catalog/recipe_tags.dart';

/// Part of the day, from the local hour.
enum DayPart { morning, day, evening, night }

/// Meteorological season of the northern hemisphere.
enum Season { winter, spring, summer, autumn }

/// Everything the feed needs to know about "now", without network access.
///
/// Built once per feed refresh by [DayContext.build]; all fields are plain
/// values, so the ranker stays deterministic and easy to test.
class DayContext {
  const DayContext({
    required this.now,
    required this.date,
    required this.weekday,
    required this.dayPart,
    required this.season,
    this.activeOccasions = const <Occasion>[],
    this.upcomingOccasion,
    this.mood,
    this.cuisine,
    this.pantryIds = const <String>{},
  });

  /// Builds the context for [now] (local time of the device).
  ///
  /// [occasionWindowDays] is the "N days before" window: an occasion that
  /// starts within this many days becomes [upcomingOccasion].
  factory DayContext.build({
    required DateTime now,
    required HolidayCalculator calculator,
    MoodTag? mood,
    String? cuisine,
    Set<String> pantryIds = const <String>{},
    int occasionWindowDays = 3,
  }) {
    final date = DateTime.utc(now.year, now.month, now.day);
    return DayContext(
      now: now,
      date: date,
      weekday: now.weekday,
      dayPart: dayPartOf(now.hour),
      season: seasonOf(now.month),
      activeOccasions: calculator.occasionsOn(date),
      upcomingOccasion: calculator.nextOccasion(
        date,
        windowDays: occasionWindowDays,
      ),
      mood: mood,
      cuisine: cuisine,
      pantryIds: pantryIds,
    );
  }

  /// Local moment of the request.
  final DateTime now;

  /// Calendar day (UTC midnight), the key for holiday lookups.
  final DateTime date;

  /// 1 = Monday ... 7 = Sunday, as in [DateTime.weekday].
  final int weekday;

  final DayPart dayPart;

  final Season season;

  /// Occasions that cover [date] (state holidays, feasts, fasts).
  final List<Occasion> activeOccasions;

  /// The nearest occasion that starts from [date] up to the window later.
  final Occasion? upcomingOccasion;

  /// Mood chosen by hand; null by default.
  final MoodTag? mood;

  /// Cuisine code chosen by hand (for example `it`); null by default.
  final String? cuisine;

  /// Ingredient ids the user has at home.
  final Set<String> pantryIds;

  bool get isWeekend =>
      weekday == DateTime.saturday || weekday == DateTime.sunday;

  /// Whether a fast covers today.
  bool get isFastingDay =>
      activeOccasions.any((occasion) => occasion.type == OccasionType.fast);

  /// The occasion the feed should talk about, or null.
  ///
  /// An occasion that starts within the window wins; otherwise a non-fast
  /// occasion that is active today (for example Maslenitsa week); fasts are
  /// handled through [isFastingDay] and never become the featured occasion.
  Occasion? get featuredOccasion {
    final upcoming = upcomingOccasion;
    if (upcoming != null && upcoming.type != OccasionType.fast) {
      return upcoming;
    }
    for (final occasion in activeOccasions) {
      if (occasion.type != OccasionType.fast) return occasion;
    }
    return null;
  }

  /// Days from [date] until the featured occasion starts; 0 if it is already
  /// going on. Null without a featured occasion.
  int? get daysToFeaturedOccasion {
    final occasion = featuredOccasion;
    if (occasion == null) return null;
    final days = occasion.start.difference(date).inDays;
    return days < 0 ? 0 : days;
  }

  DayContext copyWith({
    MoodTag? mood,
    String? cuisine,
    Set<String>? pantryIds,
    bool clearMood = false,
    bool clearCuisine = false,
  }) {
    return DayContext(
      now: now,
      date: date,
      weekday: weekday,
      dayPart: dayPart,
      season: season,
      activeOccasions: activeOccasions,
      upcomingOccasion: upcomingOccasion,
      mood: clearMood ? null : (mood ?? this.mood),
      cuisine: clearCuisine ? null : (cuisine ?? this.cuisine),
      pantryIds: pantryIds ?? this.pantryIds,
    );
  }

  /// 05-10 morning, 11-16 day, 17-22 evening, otherwise night.
  static DayPart dayPartOf(int hour) {
    if (hour >= 5 && hour <= 10) return DayPart.morning;
    if (hour >= 11 && hour <= 16) return DayPart.day;
    if (hour >= 17 && hour <= 22) return DayPart.evening;
    return DayPart.night;
  }

  /// December-February winter, March-May spring, June-August summer.
  static Season seasonOf(int month) {
    if (month == 12 || month <= 2) return Season.winter;
    if (month <= 5) return Season.spring;
    if (month <= 8) return Season.summer;
    return Season.autumn;
  }
}
