/// Daily Log Model for tracking daily progress, time studied, and goal completion.
class DailyLogModel {
  final String id;
  final String userId;
  final String date; // YYYY-MM-DD
  final int studySeconds;
  final bool isGoalMet;
  final int sessionsCount;

  DailyLogModel({
    required this.id,
    required this.userId,
    required this.date,
    this.studySeconds = 0,
    this.isGoalMet = false,
    this.sessionsCount = 0,
  });

  DailyLogModel copyWith({
    String? id,
    String? userId,
    String? date,
    int? studySeconds,
    bool? isGoalMet,
    int? sessionsCount,
  }) {
    return DailyLogModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      studySeconds: studySeconds ?? this.studySeconds,
      isGoalMet: isGoalMet ?? this.isGoalMet,
      sessionsCount: sessionsCount ?? this.sessionsCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'date': date,
      'study_seconds': studySeconds,
      'is_goal_met': isGoalMet ? 1 : 0,
      'sessions_count': sessionsCount,
    };
  }

  factory DailyLogModel.fromMap(Map<String, dynamic> map) {
    return DailyLogModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      date: map['date'] as String,
      studySeconds: (map['study_seconds'] as int?) ?? 0,
      isGoalMet: (map['is_goal_met'] as int? ?? 0) == 1,
      sessionsCount: (map['sessions_count'] as int?) ?? 0,
    );
  }
}

