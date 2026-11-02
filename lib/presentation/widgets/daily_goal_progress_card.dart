import 'package:flutter/material.dart';
import 'package:th2/core/constants/app_colors.dart';
import 'package:th2/core/constants/app_spacing.dart';
import 'package:th2/core/utils/date_time_helper.dart';
import 'package:th2/domain/entities/streak_info.dart';

/// Card displaying today's study progress toward the daily target.
class DailyGoalProgressCard extends StatelessWidget {
  final StreakInfo streakInfo;
  final VoidCallback? onAdjustGoal;

  const DailyGoalProgressCard({
    super.key,
    required this.streakInfo,
    this.onAdjustGoal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = streakInfo.progressRatio;
    final percent = streakInfo.progressPercent;
    final isMet = streakInfo.isGoalMetToday;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: isMet ? AppSpacing.activeCardShadow : AppSpacing.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isMet
                          ? AppColors.phonemeGoodBg
                          : AppColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isMet
                          ? Icons.check_circle_rounded
                          : Icons.timer_outlined,
                      color: isMet
                          ? AppColors.phonemeGood
                          : AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mục tiêu học hôm nay',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        isMet
                            ? '🎉 Xuất sắc! Bạn đã đạt mục tiêu hôm nay'
                            : 'Còn ${DateTimeHelper.formatSecondsToMinutes(streakInfo.remainingSeconds)} để hoàn thành',
                        style: TextStyle(
                          fontSize: 13,
                          color: isMet
                              ? AppColors.phonemeGood
                              : AppColors.textSecondaryLight,
                          fontWeight: isMet ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (onAdjustGoal != null)
                IconButton(
                  onPressed: onAdjustGoal,
                  icon: const Icon(Icons.tune_rounded, size: 20, color: AppColors.primary),
                  tooltip: 'Điều chỉnh mục tiêu',
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: AppColors.primarySoft,
              valueColor: AlwaysStoppedAnimation<Color>(
                isMet ? AppColors.phonemeGood : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đã học: ${DateTimeHelper.formatSecondsToMinutes(streakInfo.todayStudySeconds)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondaryLight,
                ),
              ),
              Text(
                'Mục tiêu: ${DateTimeHelper.formatSecondsToMinutes(streakInfo.dailyGoalSeconds)} ($percent%)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isMet ? AppColors.phonemeGood : AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
