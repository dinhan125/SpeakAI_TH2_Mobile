import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:th2/core/constants/app_colors.dart';
import 'package:th2/core/constants/app_spacing.dart';
import 'package:th2/core/utils/date_time_helper.dart';
import 'package:th2/core/utils/haptic_helper.dart';
import 'package:th2/data/datasources/local/database_helper.dart';
import 'package:th2/data/models/practice_session_model.dart';
import 'package:th2/data/models/weak_phoneme_model.dart';
import 'package:th2/presentation/providers/practice_provider.dart';
import 'package:th2/presentation/providers/streak_provider.dart';
import 'package:th2/presentation/widgets/streak_flame_badge.dart';

/// Analytics & Progress Screen displaying streak calendar,
/// weak/strong phoneme leaderboard, and practice history.
class AnalyticsScreen extends StatefulWidget {
  final Function(int tabIndex)? onNavigateTab;

  const AnalyticsScreen({super.key, this.onNavigateTab});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<WeakPhonemeModel> _allPhonemes = [];
  List<PracticeSessionModel> _recentSessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final db = DatabaseHelper.instance;
    final phonemes = await db.getAllWeakPhonemes();
    final sessions = await db.getRecentSessions(limit: 10);

    if (mounted) {
      setState(() {
        _allPhonemes = phonemes;
        _recentSessions = sessions;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final streakProvider = context.watch<StreakProvider>();
    final streakInfo = streakProvider.streakInfo;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê & Tiến độ'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Streak Stats Card
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    boxShadow: AppSpacing.activeCardShadow,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Chuỗi ngày học liên tiếp',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${streakInfo?.currentStreak ?? 0} Ngày 🔥',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          StreakFlameBadge(
                            streakDays: streakInfo?.currentStreak ?? 0,
                            longestStreak: streakInfo?.longestStreak ?? 0,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Divider(color: Colors.white24),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildDarkStat('Kỷ lục dài nhất', '${streakInfo?.longestStreak ?? 0} ngày'),
                          _buildDarkStat(
                            'Hôm nay',
                            DateTimeHelper.formatSecondsToMinutes(
                              streakInfo?.todayStudySeconds ?? 0,
                            ),
                          ),
                          _buildDarkStat(
                            'Trạng thái',
                            (streakInfo?.isGoalMetToday ?? false) ? 'Đạt mục tiêu ✅' : 'Chưa đạt ⏳',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Section: Phoneme Mastery Leaderboard
                Text(
                  'Bảng xếp hạng năng lực âm vị (IPA)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Cập nhật tự động sau mỗi phiên bằng công thức EMA (α = 0.3)',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                ),
                const SizedBox(height: AppSpacing.md),

                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_allPhonemes.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    ),
                    child: const Center(child: Text('Chưa có dữ liệu âm vị')),
                  )
                else
                  ..._allPhonemes.map((p) {
                    final color = AppColors.getScoreColor(p.averageScore);
                    final bg = AppColors.getScoreBgColor(p.averageScore);

                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                        border: Border.all(color: theme.colorScheme.outline),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              border: Border.all(color: color, width: 1.2),
                            ),
                            child: Text(
                              '/${p.phoneme}/',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: color,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      p.needPractice
                                          ? 'Âm cần ưu tiên cải thiện'
                                          : 'Âm vị đã thành thạo',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: p.needPractice
                                            ? AppColors.phonemeBad
                                            : AppColors.phonemeGood,
                                      ),
                                    ),
                                    Text(
                                      '${p.averageScore.toStringAsFixed(1)}/100',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: color,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                                  child: LinearProgressIndicator(
                                    value: (p.averageScore / 100.0).clamp(0.0, 1.0),
                                    minHeight: 6,
                                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                    valueColor: AlwaysStoppedAnimation<Color>(color),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Đã luyện tập ${p.totalAttempts} lần • Cập nhật: ${p.lastUpdated}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                const SizedBox(height: AppSpacing.xl),

                // Section: Practice History
                Text(
                  'Lịch sử bài luyện gần đây',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                if (_recentSessions.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    ),
                    child: const Center(child: Text('Chưa có lịch sử bài tập')),
                  )
                else
                  ..._recentSessions.map((session) {
                    final color = AppColors.getScoreColor(session.overallScore);

                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                        border: Border.all(color: theme.colorScheme.outline),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.getScoreBgColor(session.overallScore),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${session.overallScore.round()}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: color,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Độ chính xác: ${session.accuracyScore}% • Trôi chảy: ${session.fluencyScore}%',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Thời lượng: ${session.durationSeconds}s • ${session.createdAt.hour}:${session.createdAt.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (session.userAudioPath != null)
                            IconButton(
                              onPressed: () {
                                HapticHelper.lightImpact();
                                context.read<PracticeProvider>().playUserRecording();
                              },
                              icon: const Icon(Icons.play_circle_fill_rounded,
                                  color: AppColors.primaryMedium),
                              tooltip: 'Phát lại bản ghi',
                            ),
                        ],
                      ),
                    );
                  }),

                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDarkStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

