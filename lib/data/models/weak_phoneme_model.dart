/// Model tracking user performance on specific phonemes (EMA update).
class WeakPhonemeModel {
  final String phoneme;
  final int totalAttempts;
  final double averageScore;
  final bool needPractice;
  final String lastUpdated;

  WeakPhonemeModel({
    required this.phoneme,
    this.totalAttempts = 0,
    this.averageScore = 0.0,
    this.needPractice = false,
    required this.lastUpdated,
  });

  WeakPhonemeModel copyWith({
    String? phoneme,
    int? totalAttempts,
    double? averageScore,
    bool? needPractice,
    String? lastUpdated,
  }) {
    return WeakPhonemeModel(
      phoneme: phoneme ?? this.phoneme,
      totalAttempts: totalAttempts ?? this.totalAttempts,
      averageScore: averageScore ?? this.averageScore,
      needPractice: needPractice ?? this.needPractice,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phoneme': phoneme,
      'total_attempts': totalAttempts,
      'average_score': averageScore,
      'need_practice': needPractice ? 1 : 0,
      'last_updated': lastUpdated,
    };
  }

  factory WeakPhonemeModel.fromMap(Map<String, dynamic> map) {
    return WeakPhonemeModel(
      phoneme: map['phoneme'] as String,
      totalAttempts: (map['total_attempts'] as int?) ?? 0,
      averageScore: (map['average_score'] as num?)?.toDouble() ?? 0.0,
      needPractice: (map['need_practice'] as int? ?? 0) == 1,
      lastUpdated: map['last_updated'] as String? ?? '',
    );
  }
}

