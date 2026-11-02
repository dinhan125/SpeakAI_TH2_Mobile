/// Single phoneme assessment result
class PhonemeModel {
  final String phoneme;
  final String actualSpoken;
  final double score;
  final String status; // 'good', 'warning', 'bad'
  final String errorType; // 'None', 'Mispronunciation', 'Omission', 'Insertion'

  PhonemeModel({
    required this.phoneme,
    required this.actualSpoken,
    required this.score,
    required this.status,
    this.errorType = 'None',
  });

  Map<String, dynamic> toMap() {
    return {
      'phoneme': phoneme,
      'actual_spoken': actualSpoken,
      'score': score,
      'status': status,
      'error_type': errorType,
    };
  }

  factory PhonemeModel.fromMap(Map<String, dynamic> map) {
    return PhonemeModel(
      phoneme: map['phoneme'] as String? ?? '',
      actualSpoken: map['actual_spoken'] as String? ?? '',
      score: (map['score'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] as String? ?? 'good',
      errorType: map['error_type'] as String? ?? 'None',
    );
  }
}

/// Word-level assessment result containing multiple phonemes
class WordAssessmentModel {
  final String word;
  final String ipa;
  final double score;
  final String errorType;
  final List<PhonemeModel> phonemes;

  WordAssessmentModel({
    required this.word,
    required this.ipa,
    required this.score,
    required this.errorType,
    required this.phonemes,
  });

  Map<String, dynamic> toMap() {
    return {
      'word': word,
      'ipa': ipa,
      'score': score,
      'error_type': errorType,
      'phonemes': phonemes.map((p) => p.toMap()).toList(),
    };
  }

  factory WordAssessmentModel.fromMap(Map<String, dynamic> map) {
    var rawPhonemes = map['phonemes'];
    List<PhonemeModel> list = [];
    if (rawPhonemes is List) {
      list = rawPhonemes
          .whereType<Map<String, dynamic>>()
          .map((m) => PhonemeModel.fromMap(m))
          .toList();
    }

    return WordAssessmentModel(
      word: map['word'] as String? ?? '',
      ipa: map['ipa'] as String? ?? '',
      score: (map['score'] as num?)?.toDouble() ?? 0.0,
      errorType: map['error_type'] as String? ?? 'None',
      phonemes: list,
    );
  }
}

