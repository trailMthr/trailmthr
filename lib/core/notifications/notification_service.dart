// lib/core/notifications/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:flutter/material.dart';   // <-- REQUIRED for Color()

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // ------------------------------------------------------------
  // INITIALIZE (CALL ON APP START)
  // ------------------------------------------------------------
  static Future<void> init() async {
    if (_initialized) return;

    // Required for accuracy on Samsung + Android 12–15
    tzdata.initializeTimeZones();

    // ---------------------------
    // ANDROID INITIALIZATION
    // ---------------------------
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    // ---------------------------
    // IOS INITIALIZATION
    // ---------------------------
    const ios = DarwinInitializationSettings(
      requestBadgePermission: true,
      requestAlertPermission: true,
      requestSoundPermission: true,
    );

    // ---------------------------
    // GLOBAL INIT
    // ---------------------------
    const settings = InitializationSettings(android: android, iOS: ios);
    await _notifications.initialize(settings);

    // ------------------------------------------------------------
    // ENSURE NOTIFICATION CHANNELS EXIST (FIX FOR SAMSUNG)
    // ------------------------------------------------------------
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'trailmthr_notes',
  'TrailMthr Notes',
  description: 'Reminders for notes and tasks',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
  showBadge: true,
  ledColor: Color(0xFFFFFFFF),
  enableLights: true,
);


    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  // ------------------------------------------------------------
  // SCHEDULE NOTIFICATION
  // ------------------------------------------------------------
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    await init(); // ensure everything is ready

    final now = DateTime.now();
    if (scheduledTime.isBefore(now)) {
      // Prevent past reminders
      return;
    }

    // Convert to timezone-safe timestamp
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    // ------------------------------------------------------------
    // MAIN SCHEDULER (EXACT ANDROID ALARM)
    // ------------------------------------------------------------
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'trailmthr_notes',
          'TrailMthr Notes',
          channelDescription: 'Reminders for notes and tasks',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );
  }

  // ------------------------------------------------------------
  // CANCEL SPECIFIC NOTIFICATION
  // ------------------------------------------------------------
  static Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }

  // ------------------------------------------------------------
  // CANCEL ALL NOTIFICATIONS
  // ------------------------------------------------------------
  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
