import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'package:th2/core/constants/app_constants.dart';
import 'package:th2/core/utils/date_time_helper.dart';
import 'package:th2/data/models/curriculum_model.dart';
import 'package:th2/data/models/daily_log_model.dart';
import 'package:th2/data/models/practice_session_model.dart';
import 'package:th2/data/models/sentence_model.dart';
import 'package:th2/data/models/user_model.dart';
import 'package:th2/data/models/weak_phoneme_model.dart';
import 'package:th2/data/datasources/local/sample_data.dart';
import 'package:th2/data/seed/curriculum_seed_data.dart';

/// Database Helper managing local SQLite database with multi-platform Web & Desktop FFI support.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      return await _initWebDatabase();
    }

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      final appDocDir = await getApplicationDocumentsDirectory();
      final path = join(appDocDir.path, 'speakai_app.db');
      return await openDatabase(
        path,
        version: 2,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } else {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'speakai_app.db');
      return await openDatabase(
        path,
        version: 2,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }
  }

  Future<Database> _initWebDatabase() async {
    Database db;
    try {
      db = await databaseFactoryFfiWeb.openDatabase(
        'speakai_app.db',
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      if (kDebugMode) print('Web SQLite openDatabase fallback to inMemory: $e');
      db = await databaseFactoryFfiWeb.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    }

    try {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='users'",
      );
      if (tables.isEmpty) {
        await _onCreate(db, 2);
      }
    } catch (_) {
      try {
        await _onCreate(db, 2);
      } catch (_) {}
    }

    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Table users
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        full_name TEXT NOT NULL,
        daily_goal_minutes INTEGER NOT NULL DEFAULT 15,
        reminder_time TEXT NOT NULL DEFAULT '20:00',
        current_streak INTEGER NOT NULL DEFAULT 0,
        longest_streak INTEGER NOT NULL DEFAULT 0,
        last_active_date TEXT,
        is_notification_enabled INTEGER NOT NULL DEFAULT 1,
        preferred_accent TEXT NOT NULL DEFAULT 'en-US'
      )
    ''');

    // 2. Table sentences
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sentences (
        id TEXT PRIMARY KEY,
        text TEXT NOT NULL,
        ipa_transcription TEXT NOT NULL,
        sample_audio_url TEXT,
        focus_phonemes TEXT NOT NULL,
        level INTEGER NOT NULL DEFAULT 1,
        topic TEXT NOT NULL DEFAULT 'General',
        translation TEXT NOT NULL DEFAULT ''
      )
    ''');

    // 3. Table practice_sessions
    await db.execute('''
      CREATE TABLE IF NOT EXISTS practice_sessions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        sentence_id TEXT NOT NULL,
        user_audio_path TEXT,
        overall_score REAL NOT NULL,
        accuracy_score REAL NOT NULL,
        fluency_score REAL NOT NULL,
        completeness_score REAL NOT NULL,
        word_details_json TEXT NOT NULL,
        duration_seconds INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // 4. Table phoneme_assessments
    await db.execute('''
      CREATE TABLE IF NOT EXISTS phoneme_assessments (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        word TEXT NOT NULL,
        phoneme_expected TEXT NOT NULL,
        phoneme_actual TEXT NOT NULL,
        score REAL NOT NULL,
        error_type TEXT NOT NULL
      )
    ''');

    // 5. Table daily_logs
    await db.execute('''
      CREATE TABLE IF NOT EXISTS daily_logs (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        date TEXT NOT NULL,
        study_seconds INTEGER NOT NULL DEFAULT 0,
        is_goal_met INTEGER NOT NULL DEFAULT 0,
        sessions_count INTEGER NOT NULL DEFAULT 0,
        UNIQUE(user_id, date)
      )
    ''');

    // 6. Table weak_phonemes
    await db.execute('''
      CREATE TABLE IF NOT EXISTS weak_phonemes (
        phoneme TEXT PRIMARY KEY,
        total_attempts INTEGER NOT NULL DEFAULT 0,
        average_score REAL NOT NULL DEFAULT 0.0,
        need_practice INTEGER NOT NULL DEFAULT 0,
        last_updated TEXT NOT NULL
      )
    ''');

    // 7. Table exercises (Curriculum & Roadmap)
    await _createExercisesTable(db);

    // Seed Initial Data
    await _seedDatabase(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createExercisesTable(db);
      await _seedCurriculum(db);
    }
  }

  Future<void> _createExercisesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS exercises (
        id TEXT PRIMARY KEY,
        stage_id TEXT NOT NULL,
        stage_title TEXT NOT NULL,
        lesson_id TEXT NOT NULL,
        lesson_title TEXT NOT NULL,
        level TEXT NOT NULL,
        target_text TEXT NOT NULL,
        ipa_transcription TEXT NOT NULL,
        phoneme_breakdown TEXT NOT NULL,
        target_phonemes TEXT NOT NULL,
        articulation_tip_vi TEXT NOT NULL,
        vietnamese_meaning TEXT NOT NULL,
        sample_audio_url TEXT,
        best_score REAL NOT NULL DEFAULT 0.0,
        is_completed INTEGER NOT NULL DEFAULT 0,
        is_locked INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _seedDatabase(Database db) async {
    final batch = db.batch();

    // Insert default user
    final user = SampleData.defaultUser;
    batch.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

    // Insert curated sentences
    for (final sentence in SampleData.initialSentences) {
      batch.insert('sentences', sentence.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // Insert curriculum seed exercises
    for (final ex in CurriculumSeedData.allExercises) {
      batch.insert('exercises', ex.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // Seed initial weak phonemes
    final initialWeak = _initialWeakPhonemesList();
    for (final item in initialWeak) {
      batch.insert('weak_phonemes', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // Seed recent 7 days activity
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateIso = DateTimeHelper.toIsoDate(date);
      final seconds = (i == 0) ? 420 : (600 + (i * 135) % 450);
      final isGoalMet = seconds >= (user.dailyGoalMinutes * 60);

      batch.insert('daily_logs', {
        'id': 'log_$dateIso',
        'user_id': user.id,
        'date': dateIso,
        'study_seconds': seconds,
        'is_goal_met': isGoalMet ? 1 : 0,
        'sessions_count': (seconds / 90).ceil(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // Seed initial practice history
    for (final session in _initialPracticeSessionsList()) {
      batch.insert(
        'practice_sessions',
        session.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Public getters for seed/fallback data, enabling instant zero-latency UI rendering
  static List<WeakPhonemeModel> get initialWeakPhonemes => _initialWeakPhonemesList();
  static List<PracticeSessionModel> get initialPracticeSessions => _initialPracticeSessionsList();

  static List<WeakPhonemeModel> _initialWeakPhonemesList() => [
    WeakPhonemeModel(
      phoneme: 'θ',
      totalAttempts: 5,
      averageScore: 48.0,
      needPractice: true,
      lastUpdated: DateTimeHelper.todayIso(),
    ),
    WeakPhonemeModel(
      phoneme: 'ʃ',
      totalAttempts: 4,
      averageScore: 55.0,
      needPractice: true,
      lastUpdated: DateTimeHelper.todayIso(),
    ),
    WeakPhonemeModel(
      phoneme: 'ð',
      totalAttempts: 3,
      averageScore: 62.0,
      needPractice: true,
      lastUpdated: DateTimeHelper.todayIso(),
    ),
  ];

  static List<PracticeSessionModel> _initialPracticeSessionsList() {
    final now = DateTime.now();
    return [
      PracticeSessionModel(
        id: 'session_init_1',
        userId: AppConstants.defaultUserId,
        sentenceId: 'sen_2',
        userAudioPath: null,
        overallScore: 82.5,
        accuracyScore: 80.0,
        fluencyScore: 86.0,
        completenessScore: 100.0,
        wordDetails: [],
        durationSeconds: 120,
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      PracticeSessionModel(
        id: 'session_init_2',
        userId: AppConstants.defaultUserId,
        sentenceId: 'sen_1',
        userAudioPath: null,
        overallScore: 78.0,
        accuracyScore: 74.0,
        fluencyScore: 82.0,
        completenessScore: 100.0,
        wordDetails: [],
        durationSeconds: 95,
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
      ),
    ];
  }

  Future<void> _seedCurriculum(Database db) async {
    final batch = db.batch();
    for (final ex in CurriculumSeedData.allExercises) {
      batch.insert('exercises', ex.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  // ================= EXERCISES & CURRICULUM =================

  Future<List<ExerciseModel>> getAllExercises() async {
    try {
      final db = await database;
      final maps = await db.query('exercises');
      if (maps.isEmpty) {
        return CurriculumSeedData.allExercises;
      }
      return maps.map((m) => ExerciseModel.fromMap(m)).toList();
    } catch (e) {
      if (kDebugMode) print('getAllExercises error fallback: $e');
      return CurriculumSeedData.allExercises;
    }
  }

  Future<List<ExerciseModel>> getExercisesByStage(String stageId) async {
    try {
      final db = await database;
      final maps = await db.query(
        'exercises',
        where: 'stage_id = ?',
        whereArgs: [stageId],
      );
      if (maps.isEmpty) {
        return CurriculumSeedData.allExercises.where((e) => e.stageId == stageId).toList();
      }
      return maps.map((m) => ExerciseModel.fromMap(m)).toList();
    } catch (e) {
      return CurriculumSeedData.allExercises.where((e) => e.stageId == stageId).toList();
    }
  }

  Future<List<ExerciseModel>> getExercisesByLesson(String lessonId) async {
    try {
      final db = await database;
      final maps = await db.query(
        'exercises',
        where: 'lesson_id = ?',
        whereArgs: [lessonId],
      );
      if (maps.isEmpty) {
        return CurriculumSeedData.allExercises.where((e) => e.lessonId == lessonId).toList();
      }
      return maps.map((m) => ExerciseModel.fromMap(m)).toList();
    } catch (e) {
      return CurriculumSeedData.allExercises.where((e) => e.lessonId == lessonId).toList();
    }
  }

  Future<void> updateExerciseScore(String id, double score) async {
    try {
      final db = await database;
      final isCompleted = score >= 70.0;
      await db.rawUpdate('''
        UPDATE exercises
        SET best_score = CASE WHEN ? > best_score THEN ? ELSE best_score END,
            is_completed = CASE WHEN ? = 1 THEN 1 ELSE is_completed END
        WHERE id = ?
      ''', [score, score, isCompleted ? 1 : 0, id]);
    } catch (e) {
      if (kDebugMode) print('updateExerciseScore error: $e');
    }
  }

  /// Remedial Exercise Recommendation (DACTA Mục 05):
  /// Automatically recommends 3 curriculum exercises matching the user's weak phonemes (<50% score).
  Future<List<ExerciseModel>> getRecommendedCurriculumExercises(List<String> weakPhonemes, {int limit = 3}) async {
    final all = await getAllExercises();
    if (weakPhonemes.isEmpty) {
      return all.take(limit).toList();
    }

    final cleanWeak = weakPhonemes.map((p) => p.replaceAll('/', '').trim()).toSet();

    final List<MapEntry<ExerciseModel, int>> scored = [];
    for (final ex in all) {
      int matchCount = 0;
      for (final target in ex.targetPhonemes) {
        final cleanTarget = target.replaceAll('/', '').trim();
        if (cleanWeak.contains(cleanTarget)) {
          matchCount += 3;
        }
      }
      for (final pb in ex.phonemeBreakdown) {
        final cleanPb = pb.replaceAll('/', '').trim();
        if (cleanWeak.contains(cleanPb)) {
          matchCount += 1;
        }
      }
      if (matchCount > 0) {
        scored.add(MapEntry(ex, matchCount));
      }
    }

    scored.sort((a, b) => b.value.compareTo(a.value));
    final result = scored.map((e) => e.key).take(limit).toList();

    // Fallback if fewer than limit
    if (result.length < limit) {
      for (final ex in all) {
        if (!result.contains(ex)) {
          result.add(ex);
          if (result.length == limit) break;
        }
      }
    }
    return result;
  }

  // ================= USERS CRUD =================

  Future<UserModel> getUser(String userId) async {
    try {
      final db = await database;
      final maps = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return UserModel.fromMap(maps.first);
      }
      final user = SampleData.defaultUser;
      await db.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      return user;
    } catch (e) {
      if (kDebugMode) print('getUser error: $e');
      return SampleData.defaultUser;
    }
  }

  Future<int> updateUser(UserModel user) async {
    try {
      final db = await database;
      return await db.update(
        'users',
        user.toMap(),
        where: 'id = ?',
        whereArgs: [user.id],
      );
    } catch (e) {
      if (kDebugMode) print('updateUser error: $e');
      return 0;
    }
  }

  // ================= SENTENCES CRUD =================

  Future<List<SentenceModel>> getAllSentences() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('sentences');
      if (maps.isEmpty) {
        return SampleData.initialSentences;
      }
      return maps.map((m) => SentenceModel.fromMap(m)).toList();
    } catch (e) {
      if (kDebugMode) print('getAllSentences error fallback: $e');
      return SampleData.initialSentences;
    }
  }

  Future<SentenceModel?> getSentenceById(String id) async {
    try {
      final db = await database;
      final maps = await db.query(
        'sentences',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        return SentenceModel.fromMap(maps.first);
      }
    } catch (e) {
      if (kDebugMode) print('getSentenceById error: $e');
    }
    return null;
  }

  Future<List<SentenceModel>> getSentencesForPhonemes(List<String> phonemes) async {
    final all = await getAllSentences();
    if (phonemes.isEmpty) return all;

    return all.where((sentence) {
      return sentence.focusPhonemes.any((p) => phonemes.contains(p));
    }).toList();
  }

  // ================= PRACTICE SESSIONS =================

  Future<int> insertPracticeSession(PracticeSessionModel session) async {
    try {
      final db = await database;
      return await db.insert(
        'practice_sessions',
        session.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      if (kDebugMode) print('insertPracticeSession error: $e');
      return 0;
    }
  }

  Future<List<PracticeSessionModel>> getRecentSessions({int limit = 20}) async {
    try {
      final db = await database;
      final maps = await db.query(
        'practice_sessions',
        orderBy: 'created_at DESC',
        limit: limit,
      );
      if (maps.isNotEmpty) {
        return maps.map((m) => PracticeSessionModel.fromMap(m)).toList();
      }
    } catch (e) {
      if (kDebugMode) print('getRecentSessions error: $e');
    }
    return _initialPracticeSessionsList();
  }

  // ================= DAILY LOGS & STREAK =================

  Future<DailyLogModel?> getDailyLog(String userId, String dateIso) async {
    try {
      final db = await database;
      final maps = await db.query(
        'daily_logs',
        where: 'user_id = ? AND date = ?',
        whereArgs: [userId, dateIso],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        return DailyLogModel.fromMap(maps.first);
      }
    } catch (e) {
      if (kDebugMode) print('getDailyLog error: $e');
    }
    return null;
  }

  Future<DailyLogModel> getOrCreateDailyLog(String userId, String dateIso) async {
    final existing = await getDailyLog(userId, dateIso);
    if (existing != null) return existing;

    final newLog = DailyLogModel(
      id: 'log_${userId}_$dateIso',
      userId: userId,
      date: dateIso,
      studySeconds: 0,
      isGoalMet: false,
      sessionsCount: 0,
    );
    try {
      final db = await database;
      await db.insert(
        'daily_logs',
        newLog.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      if (kDebugMode) print('getOrCreateDailyLog insert error: $e');
    }
    return newLog;
  }

  Future<int> updateDailyLog(DailyLogModel log) async {
    try {
      final db = await database;
      return await db.update(
        'daily_logs',
        log.toMap(),
        where: 'id = ?',
        whereArgs: [log.id],
      );
    } catch (e) {
      if (kDebugMode) print('updateDailyLog error: $e');
      return 0;
    }
  }

  Future<List<DailyLogModel>> getPast7DaysLogs(String userId) async {
    try {
      final pastDays = DateTimeHelper.getPast7Days();
      final List<DailyLogModel> result = [];

      for (final day in pastDays) {
        final iso = DateTimeHelper.toIsoDate(day);
        final log = await getOrCreateDailyLog(userId, iso);
        result.add(log);
      }
      if (result.isNotEmpty) {
        return result;
      }
    } catch (e) {
      if (kDebugMode) print('getPast7DaysLogs error: $e');
    }
    return _generateDefaultPast7Days(userId);
  }

  static List<DailyLogModel> _generateDefaultPast7Days(String userId) {
    final now = DateTime.now();
    final logs = <DailyLogModel>[];
    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final iso = DateTimeHelper.toIsoDate(d);
      final seconds = (i == 0) ? 420 : (600 + (i * 135) % 450);
      logs.add(DailyLogModel(
        id: 'log_$iso',
        userId: userId,
        date: iso,
        studySeconds: seconds,
        isGoalMet: seconds >= 900,
        sessionsCount: (seconds / 90).ceil(),
      ));
    }
    return logs;
  }

  // ================= WEAK PHONEMES =================

  Future<List<WeakPhonemeModel>> getAllWeakPhonemes() async {
    try {
      final db = await database;
      final maps = await db.query('weak_phonemes', orderBy: 'average_score ASC');
      if (maps.isNotEmpty) {
        return maps.map((m) => WeakPhonemeModel.fromMap(m)).toList();
      }
    } catch (e) {
      if (kDebugMode) print('getAllWeakPhonemes error: $e');
    }
    return _initialWeakPhonemesList();
  }

  Future<List<WeakPhonemeModel>> getTopWeakPhonemes({int limit = 3}) async {
    try {
      final db = await database;
      final maps = await db.query(
        'weak_phonemes',
        where: 'need_practice = 1',
        orderBy: 'average_score ASC',
        limit: limit,
      );
      if (maps.isNotEmpty) {
        return maps.map((m) => WeakPhonemeModel.fromMap(m)).toList();
      }
    } catch (e) {
      if (kDebugMode) print('getTopWeakPhonemes error: $e');
    }
    return _initialWeakPhonemesList();
  }

  Future<void> updatePhonemeScore(String phoneme, double currentScore) async {
    try {
      final db = await database;
      final existing = await db.query(
        'weak_phonemes',
        where: 'phoneme = ?',
        whereArgs: [phoneme],
        limit: 1,
      );

      const alpha = AppConstants.emaAlpha;
      double newAverage;
      int newAttempts;

      if (existing.isNotEmpty) {
        final oldModel = WeakPhonemeModel.fromMap(existing.first);
        newAttempts = oldModel.totalAttempts + 1;
        newAverage = (alpha * currentScore) + ((1 - alpha) * oldModel.averageScore);
      } else {
        newAttempts = 1;
        newAverage = currentScore;
      }

      final needPractice = newAverage < AppConstants.weakPhonemeThreshold;
      final updatedModel = WeakPhonemeModel(
        phoneme: phoneme,
        totalAttempts: newAttempts,
        averageScore: double.parse(newAverage.toStringAsFixed(1)),
        needPractice: needPractice,
        lastUpdated: DateTimeHelper.todayIso(),
      );

      await db.insert(
        'weak_phonemes',
        updatedModel.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      if (kDebugMode) print('updatePhonemeScore error: $e');
    }
  }
}
