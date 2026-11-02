import 'package:flutter/material.dart';
import 'package:th2/core/constants/app_colors.dart';
import 'package:th2/core/constants/app_spacing.dart';
import 'package:th2/core/services/audio_player_service.dart';
import 'package:th2/core/services/phonetic_dictionary.dart';
import 'package:th2/core/utils/haptic_helper.dart';
import 'package:th2/data/models/phoneme_assessment_model.dart';

/// Modal BottomSheet presenting detailed phoneme analysis,
/// mouth/tongue position guides, and targeted correction advice.
class PhonemeInspectorBottomSheet extends StatelessWidget {
  final String word;
  final PhonemeModel phoneme;
  final VoidCallback? onPracticePhoneme;

  const PhonemeInspectorBottomSheet({
    super.key,
    required this.word,
    required this.phoneme,
    this.onPracticePhoneme,
  });

  static Future<void> show(
    BuildContext context, {
    required String word,
    required PhonemeModel phoneme,
    VoidCallback? onPracticePhoneme,
  }) {
    HapticHelper.mediumImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PhonemeInspectorBottomSheet(
        word: word,
        phoneme: phoneme,
        onPracticePhoneme: onPracticePhoneme,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final guide = PhoneticDictionary.getGuide(phoneme.phoneme);
    final scoreColor = AppColors.getScoreColor(phoneme.score);
    final scoreBg = AppColors.getScoreBgColor(phoneme.score);
    final isPoor = phoneme.score < 50;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      padding: EdgeInsets.only(
        top: AppSpacing.md,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Header with Phoneme Symbol & Score Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: scoreBg,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: scoreColor, width: 1.5),
                    ),
                    child: Text(
                      '/${phoneme.phoneme}/',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: scoreColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Từ: "$word"',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        guide?.descriptionVi ?? 'Âm vị tiếng Anh IPA',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: scoreBg,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
                child: Text(
                  '${phoneme.score.round()}/100',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: scoreColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Comparison Alert Box (DACTA Section 4.3.A)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isPoor
                  ? const Color(0xFFFEF2F2)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: isPoor
                    ? const Color(0xFFFCA5A5)
                    : theme.colorScheme.outline,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isPoor
                          ? Icons.warning_amber_rounded
                          : Icons.info_outline_rounded,
                      color: isPoor ? AppColors.phonemeBad : AppColors.primaryMedium,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isPoor
                          ? 'Phát hiện lệch âm vị cần sửa:'
                          : 'Đánh giá phát âm âm vị:',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isPoor
                            ? AppColors.phonemeBad
                            : theme.colorScheme.onSurface,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  phoneme.actualSpoken != phoneme.phoneme
                      ? 'Bạn đã đọc âm /${phoneme.phoneme}/ nghe giống như âm /${phoneme.actualSpoken}/ (${phoneme.errorType}).'
                      : 'Bạn đã phát âm chính xác âm vị /${phoneme.phoneme}/!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                if (guide != null && isPoor) ...[
                  const SizedBox(height: 4),
                  Text(
                    '⚠️ Lỗi thường gặp: ${guide.commonVietnameseError}',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Mouth & Tongue Position Guide (Mục 05 DACTA)
          if (guide != null) ...[
            Text(
              '💡 Hướng dẫn khẩu hình miệng chuẩn:',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.face_retouching_natural_rounded,
                    color: AppColors.primaryMedium,
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      guide.mouthPositionVi,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: Color(0xFF1E1B4B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Practice words chips
            Text(
              'Từ vựng chứa âm /${phoneme.phoneme}/ để rèn luyện:',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: guide.practiceWords.map((pw) {
                return ActionChip(
                  label: Text(pw),
                  avatar: const Icon(Icons.volume_up_rounded, size: 16),
                  onPressed: () {
                    HapticHelper.lightImpact();
                    AudioPlayerService.instance.speakNativeText(pw);
                  },
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: AppSpacing.lg),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticHelper.lightImpact();
                    AudioPlayerService.instance.speakNativeText(word);
                  },
                  icon: const Icon(Icons.volume_up_rounded, size: 18),
                  label: const Text('Nghe mẫu từ'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onPracticePhoneme?.call();
                  },
                  icon: const Icon(Icons.school_rounded, size: 18),
                  label: const Text('Luyện tập âm này'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

