/// Domain entity representing user's streak status and daily goal progress.
class StreakInfo {
  final int currentStreak;
  final int longestStreak;
  final bool isGoalMetToday;
  final int todayStudySeconds;
  final int dailyGoalSeconds;
  final String? lastActiveDate;

  const StreakInfo({
    required this.currentStreak,
    required this.longestStreak,
    required this.isGoalMetToday,
    required this.todayStudySeconds,
    required this.dailyGoalSeconds,
    this.lastActiveDate,
  });

  /// Progress ratio towards today's goal (0.0 to 1.0+)
  double get progressRatio {
    if (dailyGoalSeconds <= 0) return 0.0;
    final ratio = todayStudySeconds / dailyGoalSeconds;
    return ratio.clamp(0.0, 1.0);
  }

  /// Remaining seconds to reach goal
  int get remainingSeconds {
    final remaining = dailyGoalSeconds - todayStudySeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Percentage (0 - 100%)
  int get progressPercent {
    return (progressRatio * 100).round();
  }
}

