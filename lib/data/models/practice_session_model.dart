import 'dart:convert';
import 'phoneme_assessment_model.dart';

/// Practice Session record capturing full evaluation breakdown.
class PracticeSessionModel {
  final String id;
  final String userId;
  final String sentenceId;
  final String? userAudioPath;
  final double overallScore;
  final double accuracyScore;
  final double fluencyScore;
  final double completenessScore;
  final List<WordAssessmentModel> wordDetails;
  final int durationSeconds;
  final DateTime createdAt;

  PracticeSessionModel({
    required this.id,
    required this.userId,
    required this.sentenceId,
    this.userAudioPath,
    required this.overallScore,
    required this.accuracyScore,
    required this.fluencyScore,
    required this.completenessScore,
    required this.wordDetails,
    required this.durationSeconds,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'sentence_id': sentenceId,
      'user_audio_path': userAudioPath,
      'overall_score': overallScore,
      'accuracy_score': accuracyScore,
      'fluency_score': fluencyScore,
      'completeness_score': completenessScore,
      'word_details_json': jsonEncode(wordDetails.map((w) => w.toMap()).toList()),
      'duration_seconds': durationSeconds,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PracticeSessionModel.fromMap(Map<String, dynamic> map) {
    List<WordAssessmentModel> words = [];
    final rawJson = map['word_details_json'];
    if (rawJson is String && rawJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawJson);
        if (decoded is List) {
          words = decoded
              .whereType<Map<String, dynamic>>()
              .map((m) => WordAssessmentModel.fromMap(m))
              .toList();
        }
      } catch (_) {}
    }

    return PracticeSessionModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      sentenceId: map['sentence_id'] as String,
      userAudioPath: map['user_audio_path'] as String?,
      overallScore: (map['overall_score'] as num?)?.toDouble() ?? 0.0,
      accuracyScore: (map['accuracy_score'] as num?)?.toDouble() ?? 0.0,
      fluencyScore: (map['fluency_score'] as num?)?.toDouble() ?? 0.0,
      completenessScore: (map['completeness_score'] as num?)?.toDouble() ?? 0.0,
      wordDetails: words,
      durationSeconds: (map['duration_seconds'] as int?) ?? 0,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

