/// User Model representing application profile and streak settings.
class UserModel {
  final String id;
  final String fullName;
  final int dailyGoalMinutes;
  final String reminderTime;
  final int currentStreak;
  final int longestStreak;
  final String? lastActiveDate;
  final bool isNotificationEnabled;
  final String preferredAccent;

  UserModel({
    required this.id,
    required this.fullName,
    this.dailyGoalMinutes = 15,
    this.reminderTime = '20:00',
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActiveDate,
    this.isNotificationEnabled = true,
    this.preferredAccent = 'en-US',
  });

  UserModel copyWith({
    String? id,
    String? fullName,
    int? dailyGoalMinutes,
    String? reminderTime,
    int? currentStreak,
    int? longestStreak,
    String? lastActiveDate,
    bool? isNotificationEnabled,
    String? preferredAccent,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      reminderTime: reminderTime ?? this.reminderTime,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      isNotificationEnabled: isNotificationEnabled ?? this.isNotificationEnabled,
      preferredAccent: preferredAccent ?? this.preferredAccent,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'daily_goal_minutes': dailyGoalMinutes,
      'reminder_time': reminderTime,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'last_active_date': lastActiveDate,
      'is_notification_enabled': isNotificationEnabled ? 1 : 0,
      'preferred_accent': preferredAccent,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      fullName: map['full_name'] as String? ?? 'English Learner',
      dailyGoalMinutes: (map['daily_goal_minutes'] as int?) ?? 15,
      reminderTime: map['reminder_time'] as String? ?? '20:00',
      currentStreak: (map['current_streak'] as int?) ?? 0,
      longestStreak: (map['longest_streak'] as int?) ?? 0,
      lastActiveDate: map['last_active_date'] as String?,
      isNotificationEnabled: (map['is_notification_enabled'] as int? ?? 1) == 1,
      preferredAccent: map['preferred_accent'] as String? ?? 'en-US',
    );
  }
}

