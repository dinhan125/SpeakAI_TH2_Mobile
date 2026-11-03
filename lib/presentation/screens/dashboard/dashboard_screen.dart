import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:th2/core/constants/app_colors.dart';
import 'package:th2/core/constants/app_spacing.dart';
import 'package:th2/core/utils/haptic_helper.dart';
import 'package:th2/data/datasources/local/sample_data.dart';
import 'package:th2/data/models/sentence_model.dart';
import 'package:th2/presentation/providers/curriculum_provider.dart';
import 'package:th2/presentation/providers/practice_provider.dart';
import 'package:th2/presentation/providers/streak_provider.dart';
import 'package:th2/presentation/providers/user_provider.dart';
import 'package:th2/presentation/widgets/daily_goal_progress_card.dart';
import 'package:th2/presentation/widgets/popular_exercise_card.dart';
import 'package:th2/presentation/widgets/recommendation_card.dart';
import 'package:th2/presentation/widgets/streak_flame_badge.dart';
import 'package:th2/presentation/widgets/weekly_study_chart.dart';

/// Home Dashboard Screen with vibrant light theme, streak flame badge,
/// daily goal progress, 7-day study chart, smart remedial recommendations,
/// and popular community exercises.
class DashboardScreen extends StatefulWidget {
  final Function(int tabIndex)? onNavigateTab;

  const DashboardScreen({super.key, this.onNavigateTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedCategoryIndex = 0;

  static const List<String> _popularCategories = [
    '🔥 Tất cả',
    '🎯 Cặp âm tối thiểu',
    '⚡ Trọng âm & Phụ âm',
    '🌊 Nối âm câu',
    '🌀 Xoắn lưỡi',
  ];

  static final List<({SentenceModel sentence, String popularity, String categoryKey})> _popularData = [
    (
      sentence: SentenceModel(
        id: 'pop_1',
        text: 'She sells seashells by the seashore',
        ipaTranscription: '/ʃiː sɛlz ˈsiːˌʃɛlz baɪ ðə ˈsiːˌʃɔːr/',
        focusPhonemes: ['ʃ', 's', 'z'],
        level: 2,
        topic: 'Thử thách phát âm',
        translation: 'Cô ấy bán vỏ sò bên bờ biển',
      ),
      popularity: '2.4k lượt luyện',
      categoryKey: 'tongue_twister',
    ),
    (
      sentence: SentenceModel(
        id: 'pop_2',
        text: 'I think the sink is full of water',
        ipaTranscription: '/aɪ θɪŋk ðə sɪŋk ɪz fʊl ʌv ˈwɔːtər/',
        focusPhonemes: ['θ', 's', 'ŋ'],
        level: 1,
        topic: 'Cặp âm tối thiểu (/θ/ - /s/)',
        translation: 'Tôi nghĩ bồn rửa đã đầy nước',
      ),
      popularity: '1.9k lượt luyện',
      categoryKey: 'minimal_pairs',
    ),
    (
      sentence: SentenceModel(
        id: 'pop_3',
        text: 'The sheep sleeps on the big green ship',
        ipaTranscription: '/ðə ʃiːp sliːps ɑːn ðə bɪɡ ɡriːn ʃɪp/',
        focusPhonemes: ['iː', 'ɪ', 'ʃ'],
        level: 1,
        topic: 'Nguyên âm (/iː/ - /ɪ/)',
        translation: 'Con cừu ngủ trên con tàu xanh lớn',
      ),
      popularity: '1.8k lượt luyện',
      categoryKey: 'minimal_pairs',
    ),
    (
      sentence: SentenceModel(
        id: 'pop_4',
        text: 'These three brothers think together',
        ipaTranscription: '/ðiːz θriː ˈbrʌðərz θɪŋk təˈɡɛðər/',
        focusPhonemes: ['ð', 'θ', 'ʌ'],
        level: 2,
        topic: 'Phụ âm răng (/ð/ - /θ/)',
        translation: 'Ba người anh em này cùng suy nghĩ',
      ),
      popularity: '1.6k lượt luyện',
      categoryKey: 'clusters',
    ),
    (
      sentence: SentenceModel(
        id: 'pop_5',
        text: 'Thank you very much for your wonderful support',
        ipaTranscription: '/θæŋk juː ˈvɛri mʌtʃ fɔːr jɔːr ˈwʌndərfʊl səˈpɔːrt/',
        focusPhonemes: ['θ', 'v', 'tʃ'],
        level: 1,
        topic: 'Nối âm & Giao tiếp',
        translation: 'Cảm ơn bạn rất nhiều vì sự hỗ trợ tuyệt vời',
      ),
      popularity: '2.1k lượt luyện',
      categoryKey: 'connected',
    ),
    (
      sentence: SentenceModel(
        id: 'pop_6',
        text: 'She had a strong street strategy',
        ipaTranscription: '/ʃiː hæd ə strɔːŋ striːt ˈstrætədʒi/',
        focusPhonemes: ['str', 'ʃ', 'dʒ'],
        level: 2,
        topic: 'Cụm phụ âm (/str/)',
        translation: 'Cô ấy có một chiến lược đường phố mạnh mẽ',
      ),
      popularity: '1.2k lượt luyện',
      categoryKey: 'clusters',
    ),
    (
      sentence: SentenceModel(
        id: 'pop_7',
        text: 'Victor bought a very best violin',
        ipaTranscription: '/ˈvɪktər bɔːt ə ˈvɛri bɛst ˌvaɪəˈlɪn/',
        focusPhonemes: ['v', 'b', 'ɔː'],
        level: 1,
        topic: 'Cặp âm tối thiểu (/v/ - /b/)',
        translation: 'Victor đã mua một cây vĩ cầm tốt nhất',
      ),
      popularity: '1.4k lượt luyện',
      categoryKey: 'minimal_pairs',
    ),
    (
      sentence: SentenceModel(
        id: 'pop_8',
        text: 'Red lorry yellow lorry roll along',
        ipaTranscription: '/rɛd ˈlɔːri ˈjɛloʊ ˈlɔːri roʊl əˈlɔːŋ/',
        focusPhonemes: ['r', 'l', 'ɔː'],
        level: 2,
        topic: 'Xoắn lưỡi lỏng (/r/ - /l/)',
        translation: 'Xe tải đỏ xe tải vàng lăn bánh',
      ),
      popularity: '1.5k lượt luyện',
      categoryKey: 'tongue_twister',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StreakProvider>().initStreak();
      context.read<PracticeProvider>().refreshRecommendations();
      context.read<CurriculumProvider>().loadCurriculum();
    });
  }

  List<({SentenceModel sentence, String popularity, String categoryKey})> _getFilteredPopular() {
    switch (_selectedCategoryIndex) {
      case 1:
        return _popularData.where((item) => item.categoryKey == 'minimal_pairs').toList();
      case 2:
        return _popularData.where((item) => item.categoryKey == 'clusters').toList();
      case 3:
        return _popularData.where((item) => item.categoryKey == 'connected').toList();
      case 4:
        return _popularData.where((item) => item.categoryKey == 'tongue_twister').toList();
      case 0:
      default:
        return _popularData;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = context.watch<UserProvider>();
    final streakProvider = context.watch<StreakProvider>();
    final practiceProvider = context.watch<PracticeProvider>();
    final curriculumProvider = context.watch<CurriculumProvider>();

    final user = userProvider.user;
    final streakInfo = streakProvider.streakInfo;

    // Guaranteed non-empty recommendations
    final recommendations = practiceProvider.recommendedSentences.isNotEmpty
        ? practiceProvider.recommendedSentences
        : SampleData.initialSentences.take(3).toList();

    final filteredPopular = _getFilteredPopular();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await streakProvider.initStreak();
            await practiceProvider.refreshRecommendations();
            await curriculumProvider.loadCurriculum();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: User Greeting & Streak Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Xin chào, ${user?.fullName ?? "Bạn học"} 👋',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: AppColors.textPrimaryLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Cùng rèn luyện chuẩn IPA hôm nay',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondaryLight,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    StreakFlameBadge(
                      streakDays: streakInfo?.currentStreak ?? 0,
                      longestStreak: streakInfo?.longestStreak ?? 0,
                      onTap: () {
                        widget.onNavigateTab?.call(3); // Go to Analytics
                      },
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // Daily Goal Progress Card
                if (streakInfo != null)
                  DailyGoalProgressCard(
                    streakInfo: streakInfo,
                    onAdjustGoal: () {
                      widget.onNavigateTab?.call(4); // Go to Settings
                    },
                  ),

                const SizedBox(height: AppSpacing.lg),

                // Vibrant Banner: "Sẵn sàng bứt phá phát âm?"
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: AppColors.vibrantGradient,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.record_voice_over_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sẵn sàng bứt phá phát âm?',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'AI phân tích GOP theo thời gian thực',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          HapticHelper.lightImpact();
                          widget.onNavigateTab?.call(2); // Jump to Practice
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                          ),
                        ),
                        child: const Text('Luyện ngay', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Weekly 7-day Study Chart
                WeeklyStudyChart(past7DaysLogs: streakProvider.past7DaysLogs),

                const SizedBox(height: AppSpacing.xl),

                // ================= SECTION 1: BÀI TẬP GỢI Ý =================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bài tập gợi ý cho bạn',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Text(
                                  'Đề xuất rèn luyện âm vị cần cải thiện',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondaryLight,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        widget.onNavigateTab?.call(1); // Go to Roadmap
                      },
                      icon: const Icon(Icons.map_rounded, size: 16),
                      label: const Text('Lộ trình'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // List of Recommendation Cards
                ...recommendations.map((sentence) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: RecommendationCard(
                      sentence: sentence,
                      onTap: () {
                        HapticHelper.mediumImpact();
                        practiceProvider.selectSentence(sentence);
                        widget.onNavigateTab?.call(2); // Jump to Practice screen
                      },
                    ),
                  );
                }),

                const SizedBox(height: AppSpacing.xl),

                // ================= SECTION 2: BÀI TẬP PHỔ BIẾN =================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.streakOrangeBg,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                              border: Border.all(color: AppColors.streakOrangeBorder, width: 0.8),
                            ),
                            child: const Icon(
                              Icons.local_fire_department_rounded,
                              size: 18,
                              color: AppColors.streakOrangeText,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kho bài tập phổ biến',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Text(
                                  'Được cộng đồng SpeakAI luyện tập nhiều nhất',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondaryLight,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                      ),
                      child: Text(
                        '${filteredPopular.length} bài',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                // Horizontal Category Filter Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_popularCategories.length, (index) {
                      final isSelected = (_selectedCategoryIndex == index);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(_popularCategories[index]),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surfaceLight,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : AppColors.textSecondaryLight,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.borderLight,
                            ),
                          ),
                          showCheckmark: false,
                          onSelected: (val) {
                            if (val) {
                              HapticHelper.selectionClick();
                              setState(() {
                                _selectedCategoryIndex = index;
                              });
                            }
                          },
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Popular Cards List
                ...filteredPopular.map((item) {
                  return PopularExerciseCard(
                    sentence: item.sentence,
                    popularityText: item.popularity,
                    onPractice: () {
                      practiceProvider.selectSentence(item.sentence);
                      widget.onNavigateTab?.call(2); // Jump to Practice
                    },
                  );
                }),

                const SizedBox(height: AppSpacing.sm),

                // Bottom Callout to Roadmap
                InkWell(
                  onTap: () {
                    HapticHelper.lightImpact();
                    widget.onNavigateTab?.call(1); // Jump to Roadmap
                  },
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.explore_rounded, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Khám phá toàn bộ 80+ bài tập trong Lộ trình học',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, color: AppColors.primary, size: 16),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
