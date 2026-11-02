import 'package:flutter/material.dart';
import 'package:th2/core/constants/app_colors.dart';
import 'package:th2/core/constants/app_spacing.dart';
import 'package:th2/core/utils/haptic_helper.dart';
import 'package:th2/data/models/sentence_model.dart';

/// Popular Practice Exercise Card for Dashboard.
/// Displays target text, IPA, translation, focus phonemes, popularity badge, and quick practice button.
class PopularExerciseCard extends StatelessWidget {
  final SentenceModel sentence;
  final String popularityText;
  final VoidCallback onPractice;

  const PopularExerciseCard({
    super.key,
    required this.sentence,
    required this.popularityText,
    required this.onPractice,
  });

  String _getLevelText(int level) {
    switch (level) {
      case 1:
        return 'Cơ bản';
      case 2:
        return 'Trung bình';
      case 3:
      default:
        return 'Nâng cao';
    }
  }

  Color _getLevelColor(int level) {
    switch (level) {
      case 1:
        return AppColors.phonemeGood;
      case 2:
        return AppColors.streakOrangeText;
      case 3:
      default:
        return const Color(0xFFEF4444);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final levelText = _getLevelText(sentence.level);
    final levelColor = _getLevelColor(sentence.level);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: AppSpacing.cardShadow,
        border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Topic, Level pill & Popularity Fire badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                      ),
                      child: Text(
                        sentence.topic,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: levelColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                      ),
                      child: Text(
                        levelText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: levelColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.streakOrangeBg,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  border: Border.all(color: AppColors.streakOrangeBorder, width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department_rounded, size: 13, color: AppColors.streakOrangeText),
                    const SizedBox(width: 3),
                    Text(
                      popularityText,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.streakOrangeText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Main English Sentence
          Text(
            sentence.text,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppColors.textPrimaryLight,
              height: 1.25,
            ),
          ),

          const SizedBox(height: 4),

          // IPA transcription
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Text(
              sentence.ipaTranscription,
              style: const TextStyle(
                fontFamily: 'Courier',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),

          const SizedBox(height: 4),

          // Vietnamese Translation
          if (sentence.translation.isNotEmpty)
            Text(
              sentence.translation,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondaryLight,
                fontStyle: FontStyle.italic,
              ),
            ),

          const SizedBox(height: AppSpacing.sm),

          // Bottom Row: Target Phoneme Tags & "Luyện ngay" Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 4,
                children: sentence.focusPhonemes.map((phoneme) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '/$phoneme/',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  );
                }).toList(),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  HapticHelper.mediumImpact();
                  onPractice();
                },
                icon: const Icon(Icons.mic_rounded, size: 15),
                label: const Text('Luyện ngay', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
