import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class DailyNotificationConfig {
  const DailyNotificationConfig({
    this.enabled = false,
    this.hour = 10,
    this.minute = 0,
  });

  final bool enabled;
  final int hour;
  final int minute;

  DailyNotificationConfig copyWith({bool? enabled, int? hour, int? minute}) {
    return DailyNotificationConfig(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }
}

class DailyNotificationService {
  DailyNotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    FlutterSecureStorage? storage,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _storage = storage ?? const FlutterSecureStorage();

  final FlutterLocalNotificationsPlugin _plugin;
  final FlutterSecureStorage _storage;

  static const int dailyNotificationId = 777001;
  static const String keyDailyEnabled = 'daily_notification_enabled';
  static const String keyDailyHour = 'daily_notification_hour';
  static const String keyDailyMinute = 'daily_notification_minute';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      tz.initializeTimeZones();
      const androidSettings = AndroidInitializationSettings(
        '@drawable/ic_notification',
      );
      const initSettings = InitializationSettings(android: androidSettings);
      await _plugin.initialize(settings: initSettings);

      final androidPlatform = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlatform != null) {
        await androidPlatform.requestNotificationsPermission();
        await androidPlatform.requestExactAlarmsPermission();
      }
      _initialized = true;
    } catch (_) {
      // Ignored in test environment
    }
  }

  Future<DailyNotificationConfig> getConfig() async {
    try {
      final enabledStr = await _storage.read(key: keyDailyEnabled);
      final hourStr = await _storage.read(key: keyDailyHour);
      final minuteStr = await _storage.read(key: keyDailyMinute);

      final enabled = enabledStr == 'true';
      final hour = int.tryParse(hourStr ?? '') ?? 10;
      final minute = int.tryParse(minuteStr ?? '') ?? 0;

      return DailyNotificationConfig(
        enabled: enabled,
        hour: hour,
        minute: minute,
      );
    } catch (_) {
      return const DailyNotificationConfig();
    }
  }

  Future<void> setConfig(DailyNotificationConfig config) async {
    try {
      await _storage.write(
        key: keyDailyEnabled,
        value: config.enabled.toString(),
      );
      await _storage.write(key: keyDailyHour, value: config.hour.toString());
      await _storage.write(
        key: keyDailyMinute,
        value: config.minute.toString(),
      );
    } catch (_) {}
  }

  Future<void> scheduleDaily({
    required DailyNotificationConfig config,
    String? todayDishTitle,
    String? recipeId,
  }) async {
    if (!config.enabled) {
      await cancelDaily();
      return;
    }

    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        config.hour,
        config.minute,
      );

      // If scheduled time has already passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final body = (todayDishTitle != null && todayDishTitle.trim().isNotEmpty)
          ? 'Сегодня по плану: $todayDishTitle'
          : 'Загляните в меню на сегодня!';

      const androidDetails = AndroidNotificationDetails(
        'daily_meal_channel',
        'Блюдо дня',
        channelDescription: 'Ежедневное напоминание о плане блюд',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );
      const notificationDetails = NotificationDetails(android: androidDetails);

      await _plugin.zonedSchedule(
        id: dailyNotificationId,
        title: 'Что приготовить?',
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        payload: recipeId != null ? '/recipe/$recipeId' : '/today',
        matchDateTimeComponents: DateTimeComponents.time,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (_) {
      // Graceful fallback for test/unsupported environments
    }
  }

  Future<void> cancelDaily() async {
    try {
      await _plugin.cancel(id: dailyNotificationId);
    } catch (_) {}
  }
}
