import 'sentence_model.dart';

/// Exercise item model matching all 7 required attributes in prompt.
class ExerciseModel {
  final String id;
  final String stageId;
  final String stageTitle;
  final String lessonId;
  final String lessonTitle;
  final String level; // 'Easy', 'Medium', 'Hard'
  final String targetText;
  final String ipaTranscription;
  final List<String> phonemeBreakdown;
  final List<String> targetPhonemes;
  final String articulationTipVi;
  final String vietnameseMeaning;
  final String? sampleAudioUrl;
  final double bestScore;
  final bool isCompleted;
  final bool isLocked;

  const ExerciseModel({
    required this.id,
    required this.stageId,
    this.stageTitle = '',
    required this.lessonId,
    this.lessonTitle = '',
    required this.level,
    required this.targetText,
    required this.ipaTranscription,
    required this.phonemeBreakdown,
    required this.targetPhonemes,
    required this.articulationTipVi,
    required this.vietnameseMeaning,
    this.sampleAudioUrl,
    this.bestScore = 0.0,
    this.isCompleted = false,
    this.isLocked = false,
  });

  ExerciseModel copyWith({
    String? id,
    String? stageId,
    String? stageTitle,
    String? lessonId,
    String? lessonTitle,
    String? level,
    String? targetText,
    String? ipaTranscription,
    List<String>? phonemeBreakdown,
    List<String>? targetPhonemes,
    String? articulationTipVi,
    String? vietnameseMeaning,
    String? sampleAudioUrl,
    double? bestScore,
    bool? isCompleted,
    bool? isLocked,
  }) {
    return ExerciseModel(
      id: id ?? this.id,
      stageId: stageId ?? this.stageId,
      stageTitle: stageTitle ?? this.stageTitle,
      lessonId: lessonId ?? this.lessonId,
      lessonTitle: lessonTitle ?? this.lessonTitle,
      level: level ?? this.level,
      targetText: targetText ?? this.targetText,
      ipaTranscription: ipaTranscription ?? this.ipaTranscription,
      phonemeBreakdown: phonemeBreakdown ?? this.phonemeBreakdown,
      targetPhonemes: targetPhonemes ?? this.targetPhonemes,
      articulationTipVi: articulationTipVi ?? this.articulationTipVi,
      vietnameseMeaning: vietnameseMeaning ?? this.vietnameseMeaning,
      sampleAudioUrl: sampleAudioUrl ?? this.sampleAudioUrl,
      bestScore: bestScore ?? this.bestScore,
      isCompleted: isCompleted ?? this.isCompleted,
      isLocked: isLocked ?? this.isLocked,
    );
  }

  SentenceModel toSentenceModel() {
    return SentenceModel(
      id: id,
      text: targetText,
      ipaTranscription: ipaTranscription,
      sampleAudioUrl: sampleAudioUrl,
      focusPhonemes: targetPhonemes,
      level: level == 'Easy' ? 1 : (level == 'Medium' ? 2 : 3),
      topic: '$stageTitle • $lessonTitle',
      translation: vietnameseMeaning,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'stage_id': stageId,
      'stage_title': stageTitle,
      'lesson_id': lessonId,
      'lesson_title': lessonTitle,
      'level': level,
      'target_text': targetText,
      'ipa_transcription': ipaTranscription,
      'phoneme_breakdown': phonemeBreakdown.join(','),
      'target_phonemes': targetPhonemes.join(','),
      'articulation_tip_vi': articulationTipVi,
      'vietnamese_meaning': vietnameseMeaning,
      'sample_audio_url': sampleAudioUrl,
      'best_score': bestScore,
      'is_completed': isCompleted ? 1 : 0,
      'is_locked': isLocked ? 1 : 0,
    };
  }

  factory ExerciseModel.fromMap(Map<String, dynamic> map) {
    return ExerciseModel(
      id: map['id'] as String,
      stageId: map['stage_id'] as String? ?? 'stage_1',
      stageTitle: map['stage_title'] as String? ?? '',
      lessonId: map['lesson_id'] as String? ?? 'lesson_1_1',
      lessonTitle: map['lesson_title'] as String? ?? '',
      level: map['level'] as String? ?? 'Easy',
      targetText: map['target_text'] as String,
      ipaTranscription: map['ipa_transcription'] as String,
      phonemeBreakdown: (map['phoneme_breakdown'] as String? ?? '')
          .split(',')
          .where((s) => s.isNotEmpty)
          .toList(),
      targetPhonemes: (map['target_phonemes'] as String? ?? '')
          .split(',')
          .where((s) => s.isNotEmpty)
          .toList(),
      articulationTipVi: map['articulation_tip_vi'] as String? ?? '',
      vietnameseMeaning: map['vietnamese_meaning'] as String? ?? '',
      sampleAudioUrl: map['sample_audio_url'] as String?,
      bestScore: (map['best_score'] as num?)?.toDouble() ?? 0.0,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      isLocked: (map['is_locked'] as int? ?? 0) == 1,
    );
  }
}

/// Lesson grouping a set of related exercises under a stage
class LessonModel {
  final String id;
  final String stageId;
  final String title;
  final String subtitle;
  final List<String> focusPhonemes;
  final List<ExerciseModel> exercises;

  const LessonModel({
    required this.id,
    required this.stageId,
    required this.title,
    required this.subtitle,
    required this.focusPhonemes,
    required this.exercises,
  });

  int get completedCount => exercises.where((e) => e.isCompleted).length;
  double get progressRatio =>
      exercises.isEmpty ? 0.0 : completedCount / exercises.length;
}

/// Stage representing a core milestone in the curriculum roadmap
class StageModel {
  final String id;
  final int stageNumber;
  final String title;
  final String subtitle;
  final String description;
  final String badgeIconName;
  final List<LessonModel> lessons;

  const StageModel({
    required this.id,
    required this.stageNumber,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.badgeIconName,
    required this.lessons,
  });

  int get totalExercises =>
      lessons.fold(0, (sum, l) => sum + l.exercises.length);
  int get completedExercises =>
      lessons.fold(0, (sum, l) => sum + l.completedCount);
  double get progressRatio =>
      totalExercises == 0 ? 0.0 : completedExercises / totalExercises;
  int get progressPercent => (progressRatio * 100).round();
}
