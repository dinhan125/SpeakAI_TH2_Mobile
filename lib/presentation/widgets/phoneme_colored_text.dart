import 'package:flutter/material.dart';
import 'package:th2/core/constants/app_colors.dart';
import 'package:th2/core/constants/app_spacing.dart';
import 'package:th2/core/utils/haptic_helper.dart';
import 'package:th2/data/models/phoneme_assessment_model.dart';
import 'phoneme_inspector_bottom_sheet.dart';

/// Interactive RichText widget rendering words and their phoneme breakdowns
/// dynamically colored in Green (>=80), Yellow (50-79), and Red (<50).
class PhonemeColoredText extends StatelessWidget {
  final List<WordAssessmentModel> words;
  final Function(String phoneme)? onSelectPhonemeToPractice;

  const PhonemeColoredText({
    super.key,
    required this.words,
    this.onSelectPhonemeToPractice,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 12,
      runSpacing: 14,
      alignment: WrapAlignment.center,
      children: words.map((wordItem) {
        final wordScoreColor = AppColors.getScoreColor(wordItem.score);
        final wordBg = AppColors.getScoreBgColor(wordItem.score);

        return InkWell(
          onTap: () {
            HapticHelper.lightImpact();
            // Pick lowest scoring phoneme in the word for inspection
            PhonemeModel targetPhoneme = wordItem.phonemes.isNotEmpty
                ? wordItem.phonemes.reduce((a, b) => a.score < b.score ? a : b)
                : PhonemeModel(
                    phoneme: wordItem.word,
                    actualSpoken: wordItem.word,
                    score: wordItem.score,
                    status: 'good',
                  );

            PhonemeInspectorBottomSheet.show(
              context,
              word: wordItem.word,
              phoneme: targetPhoneme,
              onPracticePhoneme: () {
                onSelectPhonemeToPractice?.call(targetPhoneme.phoneme);
              },
            );
          },
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: wordBg,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: wordScoreColor.withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Text word
                Text(
                  wordItem.word,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: wordScoreColor,
                  ),
                ),
                const SizedBox(height: 4),

                // IPA Phonemes individual colors
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('/', style: TextStyle(fontSize: 12, color: AppColors.textMutedLight)),
                    ...wordItem.phonemes.map((p) {
                      final pColor = AppColors.getScoreColor(p.score);
                      return Text(
                        p.phoneme,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: pColor,
                        ),
                      );
                    }),
                    const Text('/', style: TextStyle(fontSize: 12, color: AppColors.textMutedLight)),
                  ],
                ),
                const SizedBox(height: 2),

                // Score pill
                Text(
                  '${wordItem.score.round()}%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: wordScoreColor,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

