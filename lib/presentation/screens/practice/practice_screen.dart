import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:th2/core/constants/app_colors.dart';
import 'package:th2/core/constants/app_spacing.dart';
import 'package:th2/core/services/phonetic_dictionary.dart';
import 'package:th2/core/services/speech_assessment_service.dart';
import 'package:th2/core/utils/haptic_helper.dart';
import 'package:th2/data/datasources/local/sample_data.dart';
import 'package:th2/data/models/phoneme_assessment_model.dart';
import 'package:th2/presentation/providers/practice_provider.dart';
import 'package:th2/presentation/providers/streak_provider.dart';
import 'package:th2/presentation/widgets/audio_waveform_recorder.dart';
import 'package:th2/presentation/widgets/phoneme_colored_text.dart';
import 'package:th2/presentation/widgets/phoneme_inspector_bottom_sheet.dart';

/// Full-featured Practice & AI Pronunciation Feedback Screen (DACTA Sections 03, 04, 05, 07).
/// Provides:
/// - Step-by-step navigation & progress bar
/// - Interactive Word Chips with individual audio playback
/// - Standard IPA transcription with focus phoneme highlights
/// - Articulation mouth & tongue posture tip from PhoneticDictionary
/// - 3-speed audio listening (1.0x, 0.7x Slow, User Recording)
/// - Waveform audio recorder with timer
/// - Instant AI assessment simulation buttons (Native, Vietnamese Accented, Slow)
/// - Tri-color phoneme breakdown with interactive BottomSheet inspector
/// - Weak phoneme action alert
class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  bool _isMouthTipExpanded = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final practice = context.read<PracticeProvider>();
      if (practice.sentences.isEmpty) {
        practice.loadSentences();
      }
      context.read<StreakProvider>().startStudyTimer();
    });
  }

  @override
  void deactivate() {
    context.read<StreakProvider>().pauseStudyTimer();
    super.deactivate();
  }

  void _showTestingProfilePicker() {
    final practice = context.read<PracticeProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (ctx) {
        return Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Kịch bản kiểm thử AI (Mục 07)',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ],
                ),
                const Text(
                  'Chọn kịch bản mẫu để kiểm tra khả năng bắt lỗi và chấm điểm GOP:',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                ),
                const SizedBox(height: AppSpacing.md),
                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                  tileColor: practice.testingProfile == SpeechTestingProfile.realistic ? AppColors.primarySoft : null,
                  title: const Text('Thực tế (Realistic Voice Analysis)', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Đánh giá giọng tự nhiên theo luồng thu âm micro'),
                  leading: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
                  onTap: () {
                    practice.setTestingProfile(SpeechTestingProfile.realistic);
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                  tileColor: practice.testingProfile == SpeechTestingProfile.nativeFluent ? AppColors.phonemeGoodBg : null,
                  title: const Text('Giọng chuẩn bản xứ (Native Fluent ~95đ)', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Phát âm chuẩn xác, nối âm mượt mà'),
                  leading: const Icon(Icons.verified_rounded, color: AppColors.phonemeGood),
                  onTap: () {
                    practice.setTestingProfile(SpeechTestingProfile.nativeFluent);
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                  tileColor: practice.testingProfile == SpeechTestingProfile.vietnameseAccented ? AppColors.phonemeBadBg : null,
                  title: const Text('Lỗi người Việt điển hình (/θ/->/s/, nuốt âm cuối)', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Cố tình đọc lệch âm răng và nuốt âm cuối'),
                  leading: const Icon(Icons.error_outline_rounded, color: AppColors.phonemeBad),
                  onTap: () {
                    practice.setTestingProfile(SpeechTestingProfile.vietnameseAccented);
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                  tileColor: practice.testingProfile == SpeechTestingProfile.hesitantSlow ? AppColors.phonemeWarningBg : null,
                  title: const Text('Tốc độ chậm / Ngắt quãng (Fluency thấp ~62đ)', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Đọc đúng từng từ nhưng ngập ngừng nhiều'),
                  leading: const Icon(Icons.hourglass_bottom_rounded, color: AppColors.phonemeWarning),
                  onTap: () {
                    practice.setTestingProfile(SpeechTestingProfile.hesitantSlow);
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                  tileColor: practice.testingProfile == SpeechTestingProfile.silentNoSpeech ? const Color(0xFFFEF2F2) : null,
                  title: const Text('Không nói gì / Im lặng (Negative Test 0đ)', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Mục 07: Không phát hiện giọng nói hoặc âm lượng < 30dB'),
                  leading: const Icon(Icons.mic_off_rounded, color: AppColors.phonemeBad),
                  onTap: () {
                    practice.setTestingProfile(SpeechTestingProfile.silentNoSpeech);
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCustomPracticeDialog() async {
    final controller = TextEditingController();
    String? errorText;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Custom Practice'),
          content: SizedBox(
            width: 480,
            child: TextField(
              controller: controller,
              autofocus: true,
              minLines: 5,
              maxLines: 10,
              textCapitalization: TextCapitalization.sentences,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                hintText: 'Enter an English sentence or paste a passage here...',
                helperText: 'Long passages are split into sentences for practice.',
                errorText: errorText,
                alignLabelWithHint: true,
                filled: true,
                fillColor: AppColors.backgroundLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                controller.clear();
                setDialogState(() => errorText = null);
              },
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Clear'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                final input = controller.text.trim();
                if (input.isEmpty) {
                  setDialogState(() => errorText = 'Please enter a sentence or passage.');
                  return;
                }
                final sentences = input
                    .replaceAll(RegExp(r'\s+'), ' ')
                    .split(RegExp(r'(?<=[.!?])\s+'))
                    .map((sentence) => sentence.trim())
                    .where((sentence) => sentence.isNotEmpty)
                    .toList();
                context.read<PracticeProvider>().startCustomPractice(sentences);
                Navigator.pop(dialogContext);
              },
              icon: const Icon(Icons.mic_rounded),
              label: const Text('Start Practice'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }

  void _showSentenceSelector() {
    final practice = context.read<PracticeProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          builder: (_, scrollController) {
            return Material(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Chọn bài luyện phát âm',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                          ),
                          child: Text(
                            '${practice.sentences.length} câu',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.primaryDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      itemCount: practice.sentences.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, index) {
                        final sentence = practice.sentences[index];
                        final isSelected = (sentence.id == practice.currentSentence?.id);

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          leading: Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : AppColors.primarySoft,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: isSelected ? Colors.white : AppColors.primaryDark,
                              ),
                            ),
                          ),
                          title: Text(
                            sentence.text,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? AppColors.primary : AppColors.textPrimaryLight,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            '${sentence.topic} • ${sentence.translation}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
                              : null,
                          onTap: () {
                            practice.selectSentence(sentence);
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final practice = context.watch<PracticeProvider>();
    final streak = context.read<StreakProvider>();

    // Guaranteed fallback: Never null or barren screen
    final sentence = practice.currentSentence ??
        (practice.sentences.isNotEmpty
            ? practice.sentences.first
            : SampleData.initialSentences.first);

    final result = practice.lastResult;
    final List<WordAssessmentModel>? words =
        result != null ? (result['words'] as List<WordAssessmentModel>?) : null;

    final firstFocus = sentence.focusPhonemes.isNotEmpty ? sentence.focusPhonemes.first : 'θ';
    final guide = PhoneticDictionary.getGuide(firstFocus);

    final wordsList = sentence.text.split(RegExp(r'\s+'));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Luyện phát âm AI'),
        actions: [
          IconButton(
            onPressed: _showTestingProfilePicker,
            icon: const Icon(Icons.science_outlined),
            tooltip: 'Kịch bản kiểm thử AI',
          ),
          IconButton(
            onPressed: _showSentenceSelector,
            icon: const Icon(Icons.format_list_bulleted_rounded),
            tooltip: 'Kho bài luyện tập',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit_note_rounded, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    const Expanded(
                      child: Text('Practice with your own sentence or passage', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                    TextButton(
                      onPressed: _showCustomPracticeDialog,
                      child: const Text('Custom Practice'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // 1. Navigation & Progress Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton.filledTonal(
                    onPressed: () {
                      HapticHelper.lightImpact();
                      practice.previousSentence();
                    },
                    icon: const Icon(Icons.chevron_left_rounded, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      elevation: 1,
                    ),
                    tooltip: 'Câu trước',
                  ),
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: AppColors.vibrantGradient,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          'Câu ${practice.currentSentenceIndex + 1} / ${practice.totalSentencesCount}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sentence.topic,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                  IconButton.filledTonal(
                    onPressed: () {
                      HapticHelper.lightImpact();
                      practice.nextSentence();
                    },
                    icon: const Icon(Icons.chevron_right_rounded, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      elevation: 1,
                    ),
                    tooltip: 'Câu tiếp theo',
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // 2. Main Interactive Pronunciation Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  boxShadow: AppSpacing.cardShadow,
                  border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.8)),
                ),
                child: Column(
                  children: [
                    // Top Tags: Level & Focus Phonemes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.phonemeGoodBg,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                            border: Border.all(color: AppColors.phonemeGoodBorder),
                          ),
                          child: const Text(
                            'Cấp độ: Tiêu chuẩn',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.phonemeGood,
                            ),
                          ),
                        ),
                        Wrap(
                          spacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              'Trọng tâm:',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight, fontWeight: FontWeight.w600),
                            ),
                            ...sentence.focusPhonemes.map((p) {
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
                            }),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Main English Target Text
                    Text(
                      sentence.text,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        letterSpacing: -0.5,
                        color: AppColors.textPrimaryLight,
                        height: 1.3,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // Interactive Word Bubbles (Tap any word to hear & inspect)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: wordsList.map((rawWord) {
                        final cleanWord = rawWord.replaceAll(RegExp(r'[^\w\s]'), '');
                        return InkWell(
                          onTap: () {
                            HapticHelper.lightImpact();
                            practice.playSpecificWord(cleanWord);
                          },
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.volume_up_rounded, size: 12, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  rawWord,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: AppColors.textPrimaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // IPA Full Transcription
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Text(
                        sentence.ipaTranscription,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'Courier',
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Vietnamese Translation
                    Text(
                      sentence.translation,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondaryLight,
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Multi-Speed Audio Playback Controls
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // 1.0x Normal Speed
                        ElevatedButton.icon(
                          onPressed: () {
                            HapticHelper.lightImpact();
                            practice.playSampleNativeAudio();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: practice.playbackSpeed == 1.0
                                ? AppColors.primary
                                : AppColors.primarySoft,
                            foregroundColor: practice.playbackSpeed == 1.0
                                ? Colors.white
                                : AppColors.primaryDark,
                            elevation: practice.playbackSpeed == 1.0 ? 1 : 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
                          ),
                          icon: const Icon(Icons.volume_up_rounded, size: 16),
                          label: const Text('Chuẩn (1.0x)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                        ),
                        // 0.75x Slow Speed
                        ElevatedButton.icon(
                          onPressed: () {
                            HapticHelper.lightImpact();
                            practice.playSampleNativeAudioSlow();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: practice.playbackSpeed == 0.75
                                ? AppColors.primary
                                : AppColors.primarySoft,
                            foregroundColor: practice.playbackSpeed == 0.75
                                ? Colors.white
                                : AppColors.primaryDark,
                            elevation: practice.playbackSpeed == 0.75 ? 1 : 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
                          ),
                          icon: const Icon(Icons.speed_rounded, size: 16),
                          label: const Text('Chậm (0.75x)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                        ),
                        // 0.5x Very Slow Speed (Clearly audible & distinct phonemes)
                        ElevatedButton.icon(
                          onPressed: () {
                            HapticHelper.lightImpact();
                            practice.playSampleNativeAudioVerySlow();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: practice.playbackSpeed == 0.5
                                ? AppColors.primary
                                : AppColors.primarySoft,
                            foregroundColor: practice.playbackSpeed == 0.5
                                ? Colors.white
                                : AppColors.primaryDark,
                            elevation: practice.playbackSpeed == 0.5 ? 1 : 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
                          ),
                          icon: const Icon(Icons.slow_motion_video_rounded, size: 16),
                          label: const Text('Rất chậm (0.5x)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                        ),
                        if (practice.lastRecordedAudioPath != null) ...[
                          ElevatedButton.icon(
                            onPressed: () {
                              HapticHelper.lightImpact();
                              practice.playUserRecording();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.streakOrangeBg,
                              foregroundColor: AppColors.streakOrangeText,
                              elevation: 0,
                              side: const BorderSide(color: AppColors.streakOrangeBorder),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
                            ),
                            icon: const Icon(Icons.headphones_rounded, size: 16),
                            label: const Text('Giọng bạn', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // 3. Articulation & Mouth Posture Tip Card
              if (guide != null)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB), // Soft warm amber
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(color: const Color(0xFFFDE68A)),
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
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFEF3C7),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.lightbulb_rounded, color: Color(0xFFD97706), size: 16),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Mẹo khẩu hình âm /${guide.phoneme}/',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _isMouthTipExpanded = !_isMouthTipExpanded;
                              });
                            },
                            child: Icon(
                              _isMouthTipExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                              color: const Color(0xFFB45309),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      if (_isMouthTipExpanded) ...[
                        const SizedBox(height: 6),
                        Text(
                          guide.mouthPositionVi,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF78350F),
                            height: 1.35,
                          ),
                        ),
                        if (guide.commonVietnameseError.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '⚠️ Lưu ý: ${guide.commonVietnameseError}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9A3412),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),

              const SizedBox(height: AppSpacing.md),

              // 4. AI Feedback Breakdown Section (Results after recording/simulation)
              if (practice.isAssessing)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    boxShadow: AppSpacing.cardShadow,
                  ),
                  child: const Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: AppSpacing.md),
                        Text(
                          'AI đang căn chỉnh forced alignment và phân tích GOP...',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              else if (result != null && words != null) ...[
                // Silence Warning Banner (DACTA Section 4.2 & Section 7.1)
                if (result['is_silent'] == true) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                      border: Border.all(color: const Color(0xFFFECACA), width: 1.5),
                      boxShadow: AppSpacing.cardShadow,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFEE2E2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.mic_off_rounded, color: AppColors.phonemeBad, size: 26),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Không phát hiện giọng nói',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF991B1B),
                                    ),
                                  ),
                                  Text(
                                    '0/100đ',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFFDC2626),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                result['feedback_message'] as String? ??
                                    'Hệ thống không thu được âm thanh (hoặc âm lượng < 30dB). Hãy nói to, rõ ràng và thử lại!',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFB91C1C),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Overall Score Banner Card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                      boxShadow: AppSpacing.cardShadow,
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Điểm phát âm: ${result['overall_score'].round()}/100',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.getScoreColor(result['overall_score']),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  (result['overall_score'] >= 80)
                                      ? '🎉 Xuất sắc! Phát âm rất chuẩn'
                                      : ((result['overall_score'] >= 60)
                                          ? '👍 Khá tốt! Cần chú ý một số âm vị'
                                          : '⚠️ Cần cải thiện khẩu hình các âm đỏ'),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondaryLight),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.getScoreBgColor(result['overall_score']),
                                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                              ),
                              child: Text(
                                (result['overall_score'] >= 80)
                                    ? 'ĐẠT'
                                    : ((result['overall_score'] >= 60) ? 'KHÁ' : 'CẦN SỬA'),
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  color: AppColors.getScoreColor(result['overall_score']),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const Divider(height: 1),
                        const SizedBox(height: AppSpacing.md),

                        // Metrics Breakdown (Accuracy, Fluency, Completeness)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildScoreStat('Chính xác', '${result['accuracy_score'].round()}%',
                                AppColors.getScoreColor(result['accuracy_score'])),
                            _buildScoreStat('Trôi chảy', '${result['fluency_score'].round()}%',
                                AppColors.getScoreColor(result['fluency_score'])),
                            _buildScoreStat('Hoàn thiện', '${result['completeness_score'].round()}%',
                                AppColors.phonemeGood),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.md),

                // Phoneme Tri-Color Breakdown Text
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    boxShadow: AppSpacing.cardShadow,
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.touch_app_rounded, size: 16, color: AppColors.primary),
                          SizedBox(width: 6),
                          Text(
                            'Chạm vào từng từ để xem chi tiết âm vị & khẩu hình:',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondaryLight,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      PhonemeColoredText(
                        words: words,
                        onSelectPhonemeToPractice: (p) {
                          final match = practice.sentences.firstWhere(
                            (s) => s.focusPhonemes.contains(p),
                            orElse: () => practice.sentences.first,
                          );
                          practice.selectSentence(match);
                        },
                      ),
                    ],
                  ),
                ),

                // Weak phoneme callout alert
                _buildWeakPhonemeCallout(context, words),

                const SizedBox(height: AppSpacing.md),
              ],

              // 5. Recording Button with Waveform Animation
              AudioWaveformRecorder(
                isRecording: practice.isRecording,
                amplitudeStream: practice.amplitudeStream,
                onStartRecording: () {
                  practice.startRecording();
                },
                onStopRecording: (durationSeconds) async {
                  final res = await practice.stopAndEvaluate(durationSeconds: durationSeconds);
                  // Only record streak practice duration if user actually spoke (not silent)
                  if (res != null && res['is_silent'] != true) {
                    streak.recordPracticeSessionDuration(explicitSeconds: durationSeconds);
                  }
                },
              ),

              const SizedBox(height: AppSpacing.md),

              // 6. Quick AI Testing Bar (DACTA Section 7.1 Multi-Voice Scenarios)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  boxShadow: AppSpacing.cardShadow,
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.science_rounded, size: 16, color: AppColors.primary),
                            SizedBox(width: 6),
                            Text(
                              'Thử nghiệm kịch bản giọng AI (Mục 07):',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: AppColors.textPrimaryLight,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: _showTestingProfilePicker,
                          child: const Text(
                            'Xem tất cả',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.verified_rounded, size: 14, color: AppColors.phonemeGood),
                          label: const Text('Bản xứ (~95đ)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                          backgroundColor: AppColors.phonemeGoodBg,
                          side: const BorderSide(color: AppColors.phonemeGoodBorder),
                          onPressed: () {
                            HapticHelper.mediumImpact();
                            practice.simulateAssessment(SpeechTestingProfile.nativeFluent);
                          },
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.error_outline_rounded, size: 14, color: AppColors.phonemeBad),
                          label: const Text('Lỗi người Việt (~45đ)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                          backgroundColor: AppColors.phonemeBadBg,
                          side: const BorderSide(color: AppColors.phonemeBadBorder),
                          onPressed: () {
                            HapticHelper.mediumImpact();
                            practice.simulateAssessment(SpeechTestingProfile.vietnameseAccented);
                          },
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.hourglass_bottom_rounded, size: 14, color: AppColors.phonemeWarning),
                          label: const Text('Ngập ngừng (~62đ)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                          backgroundColor: AppColors.phonemeWarningBg,
                          side: const BorderSide(color: AppColors.phonemeWarningBorder),
                          onPressed: () {
                            HapticHelper.mediumImpact();
                            practice.simulateAssessment(SpeechTestingProfile.hesitantSlow);
                          },
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.mic_off_rounded, size: 14, color: AppColors.phonemeBad),
                          label: const Text('Không nói / Im lặng (0đ)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                          backgroundColor: const Color(0xFFFEF2F2),
                          side: const BorderSide(color: Color(0xFFFECACA)),
                          onPressed: () {
                            HapticHelper.mediumImpact();
                            practice.simulateAssessment(SpeechTestingProfile.silentNoSpeech);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildWeakPhonemeCallout(BuildContext context, List<WordAssessmentModel> words) {
    PhonemeModel? worst;
    String worstWord = '';

    for (final w in words) {
      for (final p in w.phonemes) {
        if (worst == null || p.score < worst.score) {
          worst = p;
          worstWord = w.word;
        }
      }
    }

    if (worst == null || worst.score >= 70) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_rounded, color: AppColors.phonemeBad, size: 24),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cần sửa âm /${worst.phoneme}/ trong từ "$worstWord"',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF991B1B),
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Âm này đạt ${worst.score.round()}%. Nhấn để xem hướng dẫn sửa khẩu hình.',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF7F1D1D)),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              PhonemeInspectorBottomSheet.show(
                context,
                word: worstWord,
                phoneme: worst!,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.phonemeBad,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
            ),
            child: const Text('Xem mẹo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
