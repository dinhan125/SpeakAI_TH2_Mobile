import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
    if (kIsWeb) return true;
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

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      try {
        await _notificationsPlugin.zonedSchedule(
          id: 0,
          title: 'Đến giờ luyện phát âm tiếng Anh rồi! 🔥',
          body: 'Duy trì chuỗi Streak hôm nay bằng 15 phút luyện chuẩn âm vị nhé!',
          scheduledDate: scheduledDate,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } on PlatformException catch (pe) {
        if (kDebugMode) print('PlatformException scheduling reminder, retrying inexact: $pe');
        await _notificationsPlugin.zonedSchedule(
          id: 0,
          title: 'Đến giờ luyện phát âm tiếng Anh rồi! 🔥',
          body: 'Duy trì chuỗi Streak hôm nay bằng 15 phút luyện chuẩn âm vị nhé!',
          scheduledDate: scheduledDate,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexact,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }

      if (kDebugMode) {
        print('Scheduled daily study reminder at $hour:$minute');
      }
    } catch (e) {
      if (kDebugMode) print('Error scheduling notification: $e');
    }
  }

  /// Cancel daily reminder notification
  Future<void> cancelDailyReminder() async {
    if (kIsWeb) return;
    try {
      await _notificationsPlugin.cancel(id: 0);
    } catch (_) {}
  }

  /// Trigger an immediate demonstration notification
  Future<void> showInstantTestNotification() async {
    if (kIsWeb) {
      if (kDebugMode) print('Web test notification simulated');
      return;
    }
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
