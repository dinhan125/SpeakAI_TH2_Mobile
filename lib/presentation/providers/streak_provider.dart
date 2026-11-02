import 'package:flutter/foundation.dart';
import 'package:th2/core/constants/app_constants.dart';
import 'package:th2/core/services/study_time_tracker.dart';
import 'package:th2/data/datasources/local/database_helper.dart';
import 'package:th2/data/models/daily_log_model.dart';
import 'package:th2/domain/entities/streak_info.dart';
import 'package:th2/domain/usecases/calculate_streak_usecase.dart';

/// Provider orchestrating Streak logic, study sessions, and 7-day progress.
class StreakProvider extends ChangeNotifier {
  final CalculateStreakUseCase _streakUseCase;
  final DatabaseHelper _dbHelper;
  final StudyTimeTracker _tracker = StudyTimeTracker.instance;

  StreakInfo? _streakInfo;
  List<DailyLogModel> _past7DaysLogs = [];
  int _currentSessionSeconds = 0;
  bool _isLoading = true;

  StreakProvider({
    CalculateStreakUseCase? streakUseCase,
    DatabaseHelper? dbHelper,
  })  : _streakUseCase = streakUseCase ?? CalculateStreakUseCase(),
        _dbHelper = dbHelper ?? DatabaseHelper.instance {
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
    notifyListeners();
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
    _streakInfo = await _streakUseCase.getCurrentStreakInfo(AppConstants.defaultUserId);
    notifyListeners();
  }

  /// Load past 7 days for charts
  Future<void> loadPast7Days() async {
    _past7DaysLogs = await _dbHelper.getPast7DaysLogs(AppConstants.defaultUserId);
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
      _streakInfo = await _streakUseCase.recordStudySession(
        userId: AppConstants.defaultUserId,
        additionalSeconds: recorded,
      );
      await loadPast7Days();
      notifyListeners();
    }
  }
}

