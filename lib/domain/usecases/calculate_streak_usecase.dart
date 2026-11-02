import 'package:th2/core/utils/date_time_helper.dart';
import 'package:th2/data/datasources/local/database_helper.dart';
import 'package:th2/data/models/daily_log_model.dart';
import 'package:th2/data/models/user_model.dart';
import 'package:th2/domain/entities/streak_info.dart';

/// Use case implementing the exact Streak Calculation Specification in DACTA.md (4.1.A).
class CalculateStreakUseCase {
  final DatabaseHelper _dbHelper;

  CalculateStreakUseCase({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// 1. App Launch Check:
  /// - If ΔD > 1: User missed yesterday -> reset current_streak = 0.
  /// - If ΔD <= 1: Keep current_streak.
  Future<UserModel> checkStreakOnLaunch(UserModel user) async {
    final today = DateTime.now();

    if (user.lastActiveDate == null) {
      return user;
    }

    final lastActive = DateTimeHelper.fromIsoDate(user.lastActiveDate);
    if (lastActive == null) {
      return user;
    }

    final deltaDays = DateTimeHelper.calendarDaysDifference(lastActive, today);

    // If deltaDays > 1, streak is broken
    if (deltaDays > 1 && user.currentStreak > 0) {
      final updatedUser = user.copyWith(currentStreak: 0);
      await _dbHelper.updateUser(updatedUser);
      return updatedUser;
    }

    return user;
  }

  /// 2. Session Completed or Study Time Added:
  /// - Accumulates duration_seconds into daily_logs.
  /// - Checks if study_seconds >= daily_goal_minutes * 60.
  /// - If goal met and not credited today:
  ///     - If ΔD == 1 or lastActiveDate == null: current_streak += 1
  ///     - If ΔD > 1: current_streak = 1
  ///     - Update last_active_date = todayIso
  ///     - If current_streak > longest_streak: longest_streak = current_streak
  Future<StreakInfo> recordStudySession({
    required String userId,
    required int additionalSeconds,
  }) async {
    final today = DateTime.now();
    final todayIso = DateTimeHelper.toIsoDate(today);

    // Get current user
    UserModel user = await _dbHelper.getUser(userId);

    // Get or create today's daily log
    DailyLogModel log = await _dbHelper.getOrCreateDailyLog(userId, todayIso);

    // Update study seconds & session count
    final newStudySeconds = log.studySeconds + additionalSeconds;
    final newSessionsCount = log.sessionsCount + 1;
    final goalSeconds = user.dailyGoalMinutes * 60;
    final isGoalMetNow = newStudySeconds >= goalSeconds;

    // Check if goal was newly met or streak needs updating
    if (isGoalMetNow) {
      final lastActive = DateTimeHelper.fromIsoDate(user.lastActiveDate);
      final alreadyCreditedToday = (user.lastActiveDate == todayIso);

      if (!alreadyCreditedToday) {
        int newCurrentStreak;
        if (lastActive == null) {
          // First time ever achieving goal
          newCurrentStreak = 1;
        } else {
          final deltaDays = DateTimeHelper.calendarDaysDifference(lastActive, today);
          if (deltaDays == 1) {
            // Consecutive day
            newCurrentStreak = user.currentStreak + 1;
          } else if (deltaDays > 1) {
            // Streak broken, restarting
            newCurrentStreak = 1;
          } else {
            newCurrentStreak = user.currentStreak;
          }
        }

        final newLongest = (newCurrentStreak > user.longestStreak)
            ? newCurrentStreak
            : user.longestStreak;

        user = user.copyWith(
          currentStreak: newCurrentStreak,
          longestStreak: newLongest,
          lastActiveDate: todayIso,
        );

        await _dbHelper.updateUser(user);
      }
    }

    // Save updated log
    final updatedLog = log.copyWith(
      studySeconds: newStudySeconds,
      isGoalMet: isGoalMetNow || log.isGoalMet,
      sessionsCount: newSessionsCount,
    );
    await _dbHelper.updateDailyLog(updatedLog);

    return StreakInfo(
      currentStreak: user.currentStreak,
      longestStreak: user.longestStreak,
      isGoalMetToday: updatedLog.isGoalMet,
      todayStudySeconds: updatedLog.studySeconds,
      dailyGoalSeconds: goalSeconds,
      lastActiveDate: user.lastActiveDate,
    );
  }

  /// Get current streak info without modifying state
  Future<StreakInfo> getCurrentStreakInfo(String userId) async {
    final todayIso = DateTimeHelper.todayIso();
    UserModel user = await _dbHelper.getUser(userId);

    // Run launch check to ensure streak reflects today's date
    user = await checkStreakOnLaunch(user);

    final log = await _dbHelper.getOrCreateDailyLog(userId, todayIso);
    final goalSeconds = user.dailyGoalMinutes * 60;

    return StreakInfo(
      currentStreak: user.currentStreak,
      longestStreak: user.longestStreak,
      isGoalMetToday: log.isGoalMet,
      todayStudySeconds: log.studySeconds,
      dailyGoalSeconds: goalSeconds,
      lastActiveDate: user.lastActiveDate,
    );
  }
}
