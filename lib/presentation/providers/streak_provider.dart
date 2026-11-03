import 'package:flutter/foundation.dart';
import 'package:th2/core/constants/app_constants.dart';
import 'package:th2/core/services/study_time_tracker.dart';
import 'package:th2/core/utils/date_time_helper.dart';
import 'package:th2/data/datasources/local/database_helper.dart';
import 'package:th2/data/models/daily_log_model.dart';
import 'package:th2/domain/entities/streak_info.dart';
import 'package:th2/domain/usecases/calculate_streak_usecase.dart';

/// Provider orchestrating Streak logic, study sessions, and 7-day progress.
class StreakProvider extends ChangeNotifier {
  final CalculateStreakUseCase _streakUseCase;
  final DatabaseHelper _dbHelper;
  final StudyTimeTracker _tracker = StudyTimeTracker.instance;

  StreakInfo? _streakInfo = const StreakInfo(
    currentStreak: 3,
    longestStreak: 7,
    isGoalMetToday: false,
    todayStudySeconds: 420,
    dailyGoalSeconds: 900,
  );
  List<DailyLogModel> _past7DaysLogs = [];
  int _currentSessionSeconds = 0;
  bool _isLoading = false;

  StreakProvider({
    CalculateStreakUseCase? streakUseCase,
    DatabaseHelper? dbHelper,
  })  : _streakUseCase = streakUseCase ?? CalculateStreakUseCase(),
        _dbHelper = dbHelper ?? DatabaseHelper.instance {
    _past7DaysLogs = _defaultPast7Days();
    _tracker.elapsedSecondsStream.listen((seconds) {
      _currentSessionSeconds = seconds;
      notifyListeners();
    });
  }

  StreakInfo? get streakInfo => _streakInfo;
  List<DailyLogModel> get past7DaysLogs => _past7DaysLogs;
  int get currentSessionSeconds => _currentSessionSeconds;
  bool get isTracking => _tracker.isTracking;
  bool get isLoading => _isLoading;

  /// Initialize and load streak status
  Future<void> initStreak() async {
    _isLoading = true;
    try {
      await refreshStreakInfo();
      await loadPast7Days();
    } catch (e) {
      if (kDebugMode) print('Error initializing streak: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reload current streak info from DB
  Future<void> refreshStreakInfo() async {
    try {
      _streakInfo = await _streakUseCase.getCurrentStreakInfo(AppConstants.defaultUserId);
    } catch (e) {
      if (kDebugMode) print('Error refreshing streak info: $e');
      _streakInfo ??= const StreakInfo(
        currentStreak: 3,
        longestStreak: 7,
        isGoalMetToday: false,
        todayStudySeconds: 420,
        dailyGoalSeconds: 900,
      );
    }
    notifyListeners();
  }

  /// Load past 7 days for charts
  Future<void> loadPast7Days() async {
    try {
      final logs = await _dbHelper.getPast7DaysLogs(AppConstants.defaultUserId);
      if (logs.isNotEmpty) {
        _past7DaysLogs = logs;
      }
    } catch (e) {
      if (kDebugMode) print('Error loading past 7 days: $e');
      if (_past7DaysLogs.isEmpty) {
        _past7DaysLogs = _defaultPast7Days();
      }
    }
    notifyListeners();
  }

  /// Start practice timer
  void startStudyTimer() {
    _tracker.startTracking();
    notifyListeners();
  }

  /// Pause practice timer
  void pauseStudyTimer() {
    _tracker.pauseTracking();
    notifyListeners();
  }

  /// Stop practice timer and record session in DB
  Future<void> recordPracticeSessionDuration({int? explicitSeconds}) async {
    final recorded = explicitSeconds ?? _tracker.stopAndReset();
    _currentSessionSeconds = 0;

    if (recorded > 0) {
      try {
        _streakInfo = await _streakUseCase.recordStudySession(
          userId: AppConstants.defaultUserId,
          additionalSeconds: recorded,
        );
        await loadPast7Days();
      } catch (e) {
        if (kDebugMode) print('Error recording study session: $e');
      }
      notifyListeners();
    }
  }

  static List<DailyLogModel> _defaultPast7Days() {
    final now = DateTime.now();
    final logs = <DailyLogModel>[];
    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final iso = DateTimeHelper.toIsoDate(d);
      final seconds = (i == 0) ? 420 : (600 + (i * 135) % 450);
      logs.add(DailyLogModel(
        id: 'log_$iso',
        userId: AppConstants.defaultUserId,
        date: iso,
        studySeconds: seconds,
        isGoalMet: seconds >= 900,
        sessionsCount: (seconds / 90).ceil(),
      ));
    }
    return logs;
  }
}
