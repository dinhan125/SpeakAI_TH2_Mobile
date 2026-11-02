import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:th2/core/constants/app_colors.dart';
import 'package:th2/core/constants/app_constants.dart';
import 'package:th2/core/constants/app_spacing.dart';
import 'package:th2/core/services/notification_service.dart';
import 'package:th2/core/utils/date_time_helper.dart';
import 'package:th2/core/utils/haptic_helper.dart';
import 'package:th2/presentation/providers/streak_provider.dart';
import 'package:th2/presentation/providers/user_provider.dart';
import 'package:th2/presentation/widgets/daily_goal_selector.dart';

/// Profile & Goal Setting Screen (DACTA Sections 01, 02, 06).
class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({super.key});

  Future<void> _selectReminderTime(BuildContext context) async {
    final userProvider = context.read<UserProvider>();
    final streakProvider = context.read<StreakProvider>();
    final currentTime = DateTimeHelper.parseTimeOfDay(
      userProvider.user?.reminderTime ?? '20:00',
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
      helpText: 'CHỌN GIỜ NHẮC NHỞ HÀNG NGÀY',
    );

    if (picked != null) {
      HapticHelper.lightImpact();
      final timeStr = DateTimeHelper.formatTimeOfDay(picked);
      await userProvider.updateReminderTime(timeStr);

      // Reschedule notification
      if (userProvider.user?.isNotificationEnabled ?? true) {
        final isMet = streakProvider.streakInfo?.isGoalMetToday ?? false;
        await NotificationService.instance.scheduleDailyReminder(
          hour: picked.hour,
          minute: picked.minute,
          isGoalAlreadyMetToday: isMet,
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã cập nhật giờ nhắc nhở thành $timeStr')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = context.watch<UserProvider>();
    final streakProvider = context.watch<StreakProvider>();
    final user = userProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cá nhân & Cài đặt'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Profile Header Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  border: Border.all(color: theme.colorScheme.outline),
                  boxShadow: AppSpacing.cardShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF4338CA), Color(0xFF6366F1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? AppConstants.defaultUserName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'speakAI Student • Cấp độ Luyện IPA',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Section 1: Daily Goal Setting (Exact Time Selection)
              Text(
                'Mục tiêu học mỗi ngày (Kỷ luật & Streak)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Đặt số phút cụ thể để rèn luyện mỗi ngày và duy trì ngọn lửa Streak.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
              ),
              const SizedBox(height: AppSpacing.md),

              DailyGoalSelector(
                currentMinutes: user?.dailyGoalMinutes ?? 15,
                onGoalChanged: (newMinutes) async {
                  await userProvider.updateDailyGoal(newMinutes);
                  await streakProvider.refreshStreakInfo();
                },
              ),

              const SizedBox(height: AppSpacing.xl),

              // Section 2: Notifications & Reminders
              Text(
                'Thông báo nhắc nhở hàng ngày',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tự động hủy thông báo trong ngày nếu bạn đã hoàn thành mục tiêu.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
              ),
              const SizedBox(height: AppSpacing.md),

              Material(
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  side: BorderSide(color: theme.colorScheme.outline),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Bật thông báo nhắc nhở', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Nhắc giữ vững chuỗi Streak mỗi tối'),
                      value: user?.isNotificationEnabled ?? true,
                      onChanged: (val) async {
                        HapticHelper.lightImpact();
                        await userProvider.toggleNotification(val);
                        if (val) {
                          await NotificationService.instance.requestPermissions();
                          final time = DateTimeHelper.parseTimeOfDay(user?.reminderTime ?? '20:00');
                          await NotificationService.instance.scheduleDailyReminder(
                            hour: time.hour,
                            minute: time.minute,
                          );
                        } else {
                          await NotificationService.instance.cancelDailyReminder();
                        }
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.access_time_rounded, color: AppColors.primaryMedium),
                      title: const Text('Giờ nhắc nhở', style: TextStyle(fontWeight: FontWeight.w600)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                        ),
                        child: Text(
                          user?.reminderTime ?? '20:00',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryMedium,
                          ),
                        ),
                      ),
                      onTap: () => _selectReminderTime(context),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.notifications_active_outlined, color: AppColors.streakFlame),
                      title: const Text('Gửi thông báo kiểm tra ngay', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Kiểm tra xem hệ thống chuông báo có hoạt động không'),
                      onTap: () async {
                        HapticHelper.lightImpact();
                        await NotificationService.instance.showInstantTestNotification();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã gửi thông báo kiểm tra 🎯')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Section 3: Pronunciation & Accent Preference
              Text(
                'Cấu hình giọng đọc chuẩn',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              Material(
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  side: BorderSide(color: theme.colorScheme.outline),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                        ),
                        tileColor: (user?.preferredAccent ?? 'en-US') == 'en-US'
                            ? AppColors.primarySoft
                            : null,
                        leading: const Icon(Icons.language_rounded, color: AppColors.primaryMedium),
                        title: const Text('Tiếng Anh - Mỹ (en-US)', style: TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: const Text('Giọng chuẩn phổ biến General American'),
                        trailing: (user?.preferredAccent ?? 'en-US') == 'en-US'
                            ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryMedium)
                            : null,
                        onTap: () {
                          HapticHelper.selectionClick();
                          userProvider.updatePreferredAccent('en-US');
                        },
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                        ),
                        tileColor: (user?.preferredAccent ?? 'en-US') == 'en-GB'
                            ? AppColors.primarySoft
                            : null,
                        leading: const Icon(Icons.language_rounded, color: AppColors.primaryMedium),
                        title: const Text('Tiếng Anh - Anh (en-GB)', style: TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: const Text('Giọng chuẩn Anh Received Pronunciation'),
                        trailing: (user?.preferredAccent ?? 'en-US') == 'en-GB'
                            ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryMedium)
                            : null,
                        onTap: () {
                          HapticHelper.selectionClick();
                          userProvider.updatePreferredAccent('en-GB');
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // App Version footer
              Center(
                child: Text(
                  '${AppConstants.appName} v${AppConstants.appVersion} • Clean Architecture & AI GOP Engine',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMutedLight,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
