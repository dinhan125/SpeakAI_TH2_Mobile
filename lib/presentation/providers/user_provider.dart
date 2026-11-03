import 'package:flutter/foundation.dart';
import 'package:th2/core/constants/app_constants.dart';
import 'package:th2/data/datasources/local/database_helper.dart';
import 'package:th2/data/datasources/local/sample_data.dart';
import 'package:th2/data/models/user_model.dart';

/// Provider managing user profile and settings.
class UserProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper;
  UserModel? _user = SampleData.defaultUser;
  bool _isLoading = false;

  UserProvider({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;

  Future<void> loadUser() async {
    _isLoading = true;
    try {
      _user = await _dbHelper.getUser(AppConstants.defaultUserId);
    } catch (e) {
      if (kDebugMode) print('Error loading user: $e');
      _user ??= SampleData.defaultUser;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateDailyGoal(int minutes) async {
    _user = (_user ?? SampleData.defaultUser).copyWith(dailyGoalMinutes: minutes);
    notifyListeners();
    try {
      await _dbHelper.updateUser(_user!);
    } catch (e) {
      if (kDebugMode) print('Error updating daily goal: $e');
    }
  }

  Future<void> updateReminderTime(String time) async {
    _user = (_user ?? SampleData.defaultUser).copyWith(reminderTime: time);
    notifyListeners();
    try {
      await _dbHelper.updateUser(_user!);
    } catch (e) {
      if (kDebugMode) print('Error updating reminder time: $e');
    }
  }

  Future<void> toggleNotification(bool enabled) async {
    _user = (_user ?? SampleData.defaultUser).copyWith(isNotificationEnabled: enabled);
    notifyListeners();
    try {
      await _dbHelper.updateUser(_user!);
    } catch (e) {
      if (kDebugMode) print('Error saving notification setting: $e');
    }
  }

  Future<void> updatePreferredAccent(String accent) async {
    _user = (_user ?? SampleData.defaultUser).copyWith(preferredAccent: accent);
    notifyListeners();
    try {
      await _dbHelper.updateUser(_user!);
    } catch (e) {
      if (kDebugMode) print('Error saving preferred accent: $e');
    }
  }
}
