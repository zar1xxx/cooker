import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class CookingNotificationService {
  CookingNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
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

  Future<void> scheduleTimer({
    required int id,
    required String recipeTitle,
    required int stepNumber,
    required int seconds,
  }) async {
    if (seconds <= 0) return;
    try {
      final scheduledDate = tz.TZDateTime.now(tz.local)
          .add(Duration(seconds: seconds));
      const androidDetails = AndroidNotificationDetails(
        'cooking_timer_channel',
        'Таймер приготовления',
        channelDescription: 'Оповещения таймера в режиме готовки',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );
      const notificationDetails = NotificationDetails(android: androidDetails);

      await _plugin.zonedSchedule(
        id: id,
        title: 'Время вышло! (Шаг $stepNumber)',
        body: '$recipeTitle: проверьте блюдо',
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (_) {
      // Graceful fallback if scheduling fails on unsupported platforms/tests
    }
  }

  Future<void> cancelTimer(int id) async {
    try {
      await _plugin.cancel(id: id);
    } catch (_) {}
  }

  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}

final notificationServiceProvider = Provider<CookingNotificationService>((ref) {
  final service = CookingNotificationService();
  service.init();
  return service;
});
