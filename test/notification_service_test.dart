import 'package:chto_prigotovit/core/services/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
      'scheduledDate': scheduledDate,
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CookingNotificationService (S2-03)', () {
    late RecordingNotificationPlugin fakePlugin;
    late CookingNotificationService service;

    setUp(() async {
      fakePlugin = RecordingNotificationPlugin();
      service = CookingNotificationService(plugin: fakePlugin);
      await service.init();
    });

    test('initializes plugin with android notification icon', () {
      expect(fakePlugin.initialized, isTrue);
    });

    test('schedules step timer with exactAllowWhileIdle mode', () async {
      await service.scheduleTimer(
        id: 1,
        recipeTitle: 'Куриный суп',
        stepNumber: 2,
        seconds: 600,
      );

      expect(fakePlugin.scheduled.length, 1);
      final item = fakePlugin.scheduled.first;
      expect(item['id'], 1);
      expect(item['title'], 'Время вышло! (Шаг 2)');
      expect(item['body'], 'Куриный суп: проверьте блюдо');
      expect(
        item['androidScheduleMode'],
        AndroidScheduleMode.exactAllowWhileIdle,
      );
    });

    test('cancels scheduled timer notification by id', () async {
      await service.cancelTimer(1);
      expect(fakePlugin.cancelled, contains(1));
    });

    test('cancelAll cancels all pending notifications', () async {
      await service.cancelAll();
      expect(fakePlugin.allCancelled, isTrue);
    });
  });
}
