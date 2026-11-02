import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../constants/app_constants.dart';

/// Notification Service managing daily study reminders and smart schedule cancellation
/// when today's goal has already been achieved.
class NotificationService {
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  NotificationService._internal();

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          if (kDebugMode) print('Notification clicked: ${response.payload}');
        },
      );

      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) print('NotificationService init error: $e');
    }
  }

  /// Request runtime permissions on Android 13+ and iOS
  Future<bool> requestPermissions() async {
    try {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        final granted = await androidImplementation.requestNotificationsPermission();
        return granted ?? true;
      }
      return true;
    } catch (_) {
      return true;
    }
  }

  /// Schedule daily study reminder at given hour and minute (e.g. 20:00)
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    bool isGoalAlreadyMetToday = false,
  }) async {
    if (kIsWeb) {
      if (kDebugMode) print('Daily reminder scheduled on Web (simulation): $hour:$minute');
      return;
    }
    try {
      await init();
      await cancelDailyReminder();

      // If goal is already met today, schedule starting tomorrow
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      if (isGoalAlreadyMetToday || scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      const androidDetails = AndroidNotificationDetails(
        AppConstants.notificationChannelId,
        AppConstants.notificationChannelName,
        channelDescription: AppConstants.notificationChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const darwinDetails = DarwinNotificationDetails();

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      await _notificationsPlugin.zonedSchedule(
        id: 0,
        title: 'Giữ vững chuỗi Streak luyện tập! 🔥',
        body: 'Đã đến giờ luyện nói tiếng Anh hôm nay rồi. Dành 15 phút để nâng cao phát âm nhé!',
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      if (kDebugMode) {
        print('Scheduled daily reminder for: $scheduledDate (Hour: $hour, Min: $minute)');
      }
    } catch (e) {
      if (kDebugMode) print('Error scheduling reminder: $e');
    }
  }

  /// Cancel daily reminder notification
  Future<void> cancelDailyReminder() async {
    try {
      await _notificationsPlugin.cancel(id: 0);
    } catch (_) {}
  }

  /// Trigger an immediate demonstration notification
  Future<void> showInstantTestNotification() async {
    try {
      await init();
      const androidDetails = AndroidNotificationDetails(
        AppConstants.notificationChannelId,
        AppConstants.notificationChannelName,
        channelDescription: AppConstants.notificationChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      await _notificationsPlugin.show(
        id: 99,
        title: 'SpeakAI Test Notification 🎯',
        body: 'Hệ thống nhắc nhở luyện tập SpeakAI đang hoạt động rất tốt!',
        notificationDetails: notificationDetails,
      );
    } catch (e) {
      if (kDebugMode) print('Error showing instant notification: $e');
    }
  }
}
