import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:io';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // Pengaturan untuk Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(initializationSettings);

    // Minta izin untuk Android 13 ke atas
    _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    if (Platform.isAndroid) {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.requestExactAlarmsPermission();
    }
  }

  static Future<void> scheduleDailySevenAM() async {
    await _notificationsPlugin.zonedSchedule(
      0,
      'Lingua-Go: Tantangan Hari Ini!',
      'Yuk selesaikan Daily Challenge kamu dan dapatkan +50 XP! 🔥',
      _nextInstanceOfSevenAM(),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminders',
          'Daily Reminders',
          channelDescription: 'Notifikasi pengingat tantangan harian',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents:
          DateTimeComponents.time, // Agar berulang tiap hari
    );
  }

  static tz.TZDateTime _nextInstanceOfSevenAM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      12,
      02,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  static Future<void> showTestNotification() async {
    await _notificationsPlugin.show(
      99,
      'Lingua-Go: Tantangan Hari Ini!',
      'Yuk selesaikan Daily Challenge kamu dan dapatkan +50 XP! 🔥',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminders',
          'Daily Reminders',
          channelDescription: 'Notifikasi pengingat tantangan harian',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
}
