import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:th2/core/constants/app_colors.dart';
import 'package:th2/core/constants/app_spacing.dart';
import 'package:th2/core/utils/haptic_helper.dart';
import 'package:th2/data/models/curriculum_model.dart';
import 'package:th2/presentation/providers/curriculum_provider.dart';
import 'package:th2/presentation/providers/practice_provider.dart';

/// Roadmap Screen presenting gamified stages, lessons, and exercises (Duolingo / Elsa style).
class RoadmapScreen extends StatefulWidget {
  final Function(int tabIndex)? onNavigateTab;

  const RoadmapScreen({super.key, this.onNavigateTab});

  @override
  State<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen> {
  String? _expandedStageId;

  @override
  void initState() {
    super.initState();
    final cur = context.read<CurriculumProvider>();
    if (cur.stages.isNotEmpty) {
      _expandedStageId = cur.stages.first.id;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final curriculum = context.read<CurriculumProvider>();
        if (curriculum.stages.isEmpty) {
          curriculum.loadCurriculum();
        } else if (_expandedStageId == null) {
          setState(() {
            _expandedStageId = curriculum.stages.first.id;
          });
        }
      }
    });
  }

  IconData _getStageIcon(String iconName) {
    switch (iconName) {
      case 'bolt':
        return Icons.bolt_rounded;
      case 'auto_awesome':
        return Icons.auto_awesome_rounded;
      case 'trophy':
        return Icons.emoji_events_rounded;
      case 'mic':
      default:
        return Icons.record_voice_over_rounded;
    }
  }

  void _startExercise(ExerciseModel exercise) {
    HapticHelper.mediumImpact();
    final practice = context.read<PracticeProvider>();
    context.read<CurriculumProvider>().selectExercise(exercise);
    practice.selectSentence(exercise.toSentenceModel());
    widget.onNavigateTab?.call(2); // Jump to Practice Tab
  }

  @override
  Widget build(BuildContext context) {
    final curriculum = context.watch<CurriculumProvider>();
    final stages = curriculum.stages;
    final activeExpandedId = _expandedStageId ?? (stages.isNotEmpty ? stages.first.id : null);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Lộ trình phát âm chuẩn IPA'),
        actions: [
          IconButton(
            onPressed: () {
              HapticHelper.lightImpact();
              curriculum.loadCurriculum();
            },
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới lộ trình',
          ),
        ],
      ),
      body: SafeArea(
        child: (curriculum.isLoading && stages.isEmpty)
            ? const Center(child: CircularProgressIndicator())
            : stages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: AppColors.primarySoft,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.school_rounded, color: AppColors.primary, size: 28),
                        ),
                        const SizedBox(height: 12),
                        const Text('Đang tải kho bài tập...', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      if (curriculum.isLoading)
                        const LinearProgressIndicator(
                          minHeight: 2,
                          backgroundColor: AppColors.primarySoft,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.md,
                          ),
                          itemCount: stages.length,
                          itemBuilder: (context, index) {
                            final stage = stages[index];
                            final isExpanded = (activeExpandedId == stage.id);

                            return _buildStageCard(context, stage, isExpanded);
                          },
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildStageCard(BuildContext context, StageModel stage, bool isExpanded) {
    final theme = Theme.of(context);
    final icon = _getStageIcon(stage.badgeIconName);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: AppSpacing.cardShadow,
      ),
      child: Column(
        children: [
          // Stage Header Tap Area
          InkWell(
            onTap: () {
              HapticHelper.lightImpact();
              setState(() {
                _expandedStageId = isExpanded ? null : stage.id;
              });
            },
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppColors.vibrantGradient,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(icon, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySoft,
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                                  ),
                                  child: Text(
                                    'CHẶNG ${stage.stageNumber}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${stage.progressPercent}% Hoàn thành',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: stage.progressPercent >= 100
                                        ? AppColors.phonemeGood
                                        : AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              stage.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              stage.subtitle,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondaryLight,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    child: LinearProgressIndicator(
                      value: stage.progressRatio,
                      minHeight: 8,
                      backgroundColor: AppColors.primarySoft,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        stage.progressPercent >= 100 ? AppColors.phonemeGood : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded Lessons List
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: stage.lessons.map((lesson) {
                  return _buildLessonSection(context, lesson);
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLessonSection(BuildContext context, LessonModel lesson) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lesson.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: lesson.focusPhonemes.map((p) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.streakOrangeBg,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.streakOrangeBorder, width: 0.8),
                    ),
                    child: Text(
                      '/$p/',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.streakOrangeText,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Exercise Items in Lesson
          ...lesson.exercises.map((ex) {
            final hasScore = ex.bestScore > 0;
            final scoreColor = AppColors.getScoreColor(ex.bestScore);

            return InkWell(
              onTap: () => _startExercise(ex),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: ex.isCompleted
                        ? AppColors.phonemeGood.withValues(alpha: 0.4)
                        : AppColors.borderLight,
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: ex.isCompleted
                            ? AppColors.phonemeGoodBg
                            : AppColors.primarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        ex.isCompleted ? Icons.check_circle_rounded : Icons.play_arrow_rounded,
                        color: ex.isCompleted ? AppColors.phonemeGood : AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ex.targetText,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.textPrimaryLight,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ex.ipaTranscription,
                            style: const TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 12,
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ex.vietnameseMeaning,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondaryLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    if (hasScore)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.getScoreBgColor(ex.bestScore),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                        ),
                        child: Text(
                          '⭐ ${ex.bestScore.round()}đ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: scoreColor,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                        ),
                        child: const Text(
                          'Luyện ngay',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
