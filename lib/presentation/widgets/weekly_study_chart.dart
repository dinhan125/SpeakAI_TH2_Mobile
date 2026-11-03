import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:th2/core/constants/app_colors.dart';
import 'package:th2/core/constants/app_spacing.dart';
import 'package:th2/core/utils/date_time_helper.dart';
import 'package:th2/data/models/daily_log_model.dart';

/// Weekly Study Time Bar Chart powered by fl_chart.
class WeeklyStudyChart extends StatelessWidget {
  final List<DailyLogModel> past7DaysLogs;

  const WeeklyStudyChart({
    super.key,
    required this.past7DaysLogs,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todayIso = DateTimeHelper.todayIso();

    double maxMinutes = 20.0;
    for (final log in past7DaysLogs) {
      final mins = (log.studySeconds / 60.0).roundToDouble();
      if (mins > maxMinutes) {
        maxMinutes = mins + 5;
      }
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: AppSpacing.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Thời gian học 7 ngày qua',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
                child: const Text(
                  'Đơn vị: phút',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4F46E5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 180,
            child: past7DaysLogs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEEF2FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.bar_chart_rounded,
                            color: AppColors.primary,
                            size: 26,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Chưa có dữ liệu học tập 7 ngày qua',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                : BarChart(
                    BarChartData(
                      maxY: maxMinutes,
                      alignment: BarChartAlignment.spaceAround,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => const Color(0xFF1E1B4B),
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            if (group.x < 0 || group.x >= past7DaysLogs.length) return null;
                            final log = past7DaysLogs[group.x];
                            final mins = (log.studySeconds / 60.0).round();
                            return BarTooltipItem(
                              '$mins phút',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 5,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: AppColors.borderLight.withValues(alpha: 0.6),
                          strokeWidth: 1,
                          dashArray: [4, 4],
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) {
                              if (value % 5 != 0) return const SizedBox.shrink();
                              return Text(
                                '${value.toInt()}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF334155),
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= past7DaysLogs.length) {
                                return const SizedBox.shrink();
                              }
                              final log = past7DaysLogs[index];
                              final date = DateTimeHelper.fromIsoDate(log.date);
                              final label = (date != null)
                                  ? DateTimeHelper.getWeekdayShort(date)
                                  : '';
                              final isToday = (log.date == todayIso);

                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                                    color: isToday
                                        ? const Color(0xFF4338CA)
                                        : const Color(0xFF334155),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(past7DaysLogs.length, (index) {
                        final log = past7DaysLogs[index];
                        final minutes = (log.studySeconds / 60.0).roundToDouble();
                        final isToday = (log.date == todayIso);

                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: minutes,
                              gradient: isToday
                                  ? AppColors.vibrantGradient
                                  : const LinearGradient(
                                      colors: [
                                        Color(0xFF818CF8),
                                        Color(0xFF6366F1),
                                      ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                              width: 18,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
