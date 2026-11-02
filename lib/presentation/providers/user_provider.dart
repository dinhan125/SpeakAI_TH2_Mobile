import 'package:flutter/foundation.dart';
import 'package:th2/core/constants/app_constants.dart';
import 'package:th2/data/datasources/local/database_helper.dart';
import 'package:th2/data/models/user_model.dart';

/// Provider managing user profile and settings.
class UserProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper;
  UserModel? _user;
  bool _isLoading = true;

  UserProvider({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;

  Future<void> loadUser() async {
    _isLoading = true;
    notifyListeners();
    try {
      _user = await _dbHelper.getUser(AppConstants.defaultUserId);
    } catch (e) {
      if (kDebugMode) print('Error loading user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateDailyGoal(int minutes) async {
    if (_user == null) return;
    _user = _user!.copyWith(dailyGoalMinutes: minutes);
    await _dbHelper.updateUser(_user!);
    notifyListeners();
  }

  Future<void> updateReminderTime(String time) async {
    if (_user == null) return;
    _user = _user!.copyWith(reminderTime: time);
    await _dbHelper.updateUser(_user!);
    notifyListeners();
  }

  Future<void> toggleNotification(bool enabled) async {
    if (_user == null) return;
    _user = _user!.copyWith(isNotificationEnabled: enabled);
    await _dbHelper.updateUser(_user!);
    notifyListeners();
  }

  Future<void> updatePreferredAccent(String accent) async {
    if (_user == null) return;
    _user = _user!.copyWith(preferredAccent: accent);
    await _dbHelper.updateUser(_user!);
    notifyListeners();
  }
}

