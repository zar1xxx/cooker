import 'package:chto_prigotovit/core/services/daily_notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class RecordingNotificationPlugin extends Fake
    implements FlutterLocalNotificationsPlugin {
  final List<Map<String, dynamic>> scheduled = [];
  final List<int> cancelled = [];
  bool allCancelled = false;
  bool initialized = false;

  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
    onDidReceiveBackgroundNotificationResponse,
  }) async {
    initialized = true;
    return true;
  }

  @override
  Future<void> zonedSchedule({
    required int id,
    required dynamic scheduledDate,
    required NotificationDetails notificationDetails,
    required AndroidScheduleMode androidScheduleMode,
    String? title,
    String? body,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    scheduled.add({
      'id': id,
      'title': title,
      'body': body,
      'payload': payload,
      'scheduledDate': scheduledDate,
      'matchDateTimeComponents': matchDateTimeComponents,
      'androidScheduleMode': androidScheduleMode,
    });
  }

  @override
  Future<void> cancel({required int id, String? tag}) async {
    cancelled.add(id);
  }

  @override
  Future<void> cancelAll() async {
    allCancelled = true;
  }
}

class FakeSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _data[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _data[key] = value;
    } else {
      _data.remove(key);
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DailyNotificationService (S5-05 / TZ 7.3)', () {
    late RecordingNotificationPlugin fakePlugin;
    late FakeSecureStorage fakeStorage;
    late DailyNotificationService service;

    setUp(() async {
      fakePlugin = RecordingNotificationPlugin();
      fakeStorage = FakeSecureStorage();
      service = DailyNotificationService(
        plugin: fakePlugin,
        storage: fakeStorage,
      );
      await service.init();
    });

    test('default configuration is disabled and 10:00 AM', () async {
      final config = await service.getConfig();
      expect(config.enabled, isFalse);
      expect(config.hour, 10);
      expect(config.minute, 0);
    });

    test('persists and retrieves updated notification config', () async {
      await service.setConfig(
        const DailyNotificationConfig(enabled: true, hour: 11, minute: 30),
      );

      final updated = await service.getConfig();
      expect(updated.enabled, isTrue);
      expect(updated.hour, 11);
      expect(updated.minute, 30);
    });

    test('scheduleDaily schedules repeating notification with dish title and payload', () async {
      await service.scheduleDaily(
        config: const DailyNotificationConfig(
          enabled: true,
          hour: 10,
          minute: 0,
        ),
        todayDishTitle: 'Борщ с говядиной',
        recipeId: 'borscht',
      );

      expect(fakePlugin.scheduled.length, 1);
      final item = fakePlugin.scheduled.first;
      expect(item['id'], DailyNotificationService.dailyNotificationId);
      expect(item['title'], 'Что приготовить?');
      expect(item['body'], 'Сегодня по плану: Борщ с говядиной');
      expect(item['payload'], '/recipe/borscht');
      expect(item['matchDateTimeComponents'], DateTimeComponents.time);
      expect(
        item['androidScheduleMode'],
        AndroidScheduleMode.exactAllowWhileIdle,
      );
    });

    test(
      'scheduleDaily when disabled cancels existing scheduled notification',
      () async {
        await service.scheduleDaily(
          config: const DailyNotificationConfig(enabled: false),
        );

        expect(
          fakePlugin.cancelled,
          contains(DailyNotificationService.dailyNotificationId),
        );
      },
    );

    test('cancelDaily cancels daily notification', () async {
      await service.cancelDaily();
      expect(
        fakePlugin.cancelled,
        contains(DailyNotificationService.dailyNotificationId),
      );
    });
  });
}
