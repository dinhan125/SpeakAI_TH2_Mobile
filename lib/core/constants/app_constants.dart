/// Core Application Constants
class AppConstants {
  AppConstants._();

  static const String appName = 'SpeakAI';
  static const String appVersion = '1.0.0';

  // Default User settings
  static const String defaultUserId = 'default_user_1';
  static const String defaultUserName = 'English Learner';
  static const int defaultDailyGoalMinutes = 15;
  static const String defaultReminderTime = '20:00';
  static const String defaultAccent = 'en-US';

  // Scoring Thresholds
  static const double scoreExcellent = 80.0;
  static const double scoreWarning = 50.0;
  static const double weakPhonemeThreshold = 65.0;

  // EMA smoothing factor
  static const double emaAlpha = 0.3;

  // Audio recording config (PCM 16-bit, 16kHz Mono)
  static const int audioSampleRate = 16000;
  static const int audioChannels = 1;
  static const int audioBitDepth = 16;

  // Notification Channel
  static const String notificationChannelId = 'speakai_daily_reminder';
  static const String notificationChannelName = 'SpeakAI Daily Goal Reminder';
  static const String notificationChannelDesc = 'Reminds you to keep your study streak alive';
}

