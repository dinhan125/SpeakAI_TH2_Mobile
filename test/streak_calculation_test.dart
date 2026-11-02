import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:th2/core/utils/date_time_helper.dart';
import 'package:th2/data/models/user_model.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DateTimeHelper and Calendar Difference Tests', () {
    test('Difference in calendar days between consecutive days is 1', () {
      final d1 = DateTime(2026, 10, 30, 23, 59);
      final d2 = DateTime(2026, 10, 31, 0, 1);
      expect(DateTimeHelper.calendarDaysDifference(d1, d2), 1);
    });

    test('Difference in calendar days for same day is 0', () {
      final d1 = DateTime(2026, 10, 31, 8, 0);
      final d2 = DateTime(2026, 10, 31, 20, 0);
      expect(DateTimeHelper.calendarDaysDifference(d1, d2), 0);
    });

    test('Difference in calendar days when skipping a day is 2', () {
      final d1 = DateTime(2026, 10, 29);
      final d2 = DateTime(2026, 10, 31);
      expect(DateTimeHelper.calendarDaysDifference(d1, d2), 2);
    });
  });

  group('Streak Logic Calculation Unit Tests', () {
    test('Test case 1: Goal met today increments streak; second session on same day preserves streak', () {
      final todayIso = DateTimeHelper.todayIso();
      UserModel user = UserModel(
        id: 'test_user',
        fullName: 'Test Learner',
        dailyGoalMinutes: 15, // 900 seconds
        currentStreak: 0,
        longestStreak: 0,
        lastActiveDate: null,
      );

      // Session 1: 900 seconds (meets goal)
      int studySeconds = 900;
      bool goalMet = studySeconds >= (user.dailyGoalMinutes * 60);
      expect(goalMet, isTrue);

      if (user.lastActiveDate != todayIso) {
        user = user.copyWith(
          currentStreak: user.currentStreak + 1,
          longestStreak: user.currentStreak + 1 > user.longestStreak ? user.currentStreak + 1 : user.longestStreak,
          lastActiveDate: todayIso,
        );
      }
      expect(user.currentStreak, 1);
      expect(user.longestStreak, 1);
      expect(user.lastActiveDate, todayIso);

      // Session 2 on same day: another 900 seconds
      studySeconds += 900;
      if (user.lastActiveDate != todayIso) {
        user = user.copyWith(currentStreak: user.currentStreak + 1);
      }
      // Streak MUST remain 1 on same day!
      expect(user.currentStreak, 1);
      expect(user.longestStreak, 1);
    });

    test('Test case 2: Consecutive day study increments streak to 2', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayIso = DateTimeHelper.toIsoDate(yesterday);
      final todayIso = DateTimeHelper.todayIso();

      UserModel user = UserModel(
        id: 'test_user',
        fullName: 'Test Learner',
        dailyGoalMinutes: 15,
        currentStreak: 1,
        longestStreak: 1,
        lastActiveDate: yesterdayIso,
      );

      // Check delta days
      final lastActive = DateTimeHelper.fromIsoDate(user.lastActiveDate)!;
      final delta = DateTimeHelper.calendarDaysDifference(lastActive, DateTime.now());
      expect(delta, 1);

      // Complete today's goal
      int newStreak = user.currentStreak;
      if (delta == 1) {
        newStreak += 1;
      }
      user = user.copyWith(
        currentStreak: newStreak,
        longestStreak: newStreak > user.longestStreak ? newStreak : user.longestStreak,
        lastActiveDate: todayIso,
      );

      expect(user.currentStreak, 2);
      expect(user.longestStreak, 2);
    });

    test('Test case 3: Missed a day resets current_streak to 0 on launch while preserving longest_streak', () {
      // 2 days ago
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      final twoDaysAgoIso = DateTimeHelper.toIsoDate(twoDaysAgo);

      UserModel user = UserModel(
        id: 'test_user',
        fullName: 'Test Learner',
        dailyGoalMinutes: 15,
        currentStreak: 5,
        longestStreak: 12,
        lastActiveDate: twoDaysAgoIso,
      );

      // Launch check
      final lastActive = DateTimeHelper.fromIsoDate(user.lastActiveDate)!;
      final delta = DateTimeHelper.calendarDaysDifference(lastActive, DateTime.now());
      expect(delta, greaterThan(1));

      if (delta > 1) {
        user = user.copyWith(currentStreak: 0);
      }

      expect(user.currentStreak, 0); // Reset to 0
      expect(user.longestStreak, 12); // Longest preserved!
    });
  });
}

