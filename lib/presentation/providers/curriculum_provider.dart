import 'package:flutter/foundation.dart';
import 'package:th2/data/datasources/local/database_helper.dart';
import 'package:th2/data/models/curriculum_model.dart';
import 'package:th2/data/seed/curriculum_seed_data.dart';

/// Provider managing the Pronunciation Curriculum, Roadmap progression,
/// and Remedial Exercise recommendations.
class CurriculumProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper;

  List<StageModel> _stages = CurriculumSeedData.stages;
  List<ExerciseModel> _allExercises = CurriculumSeedData.allExercises;
  List<ExerciseModel> _remedialExercises = CurriculumSeedData.allExercises.take(3).toList();
  ExerciseModel? _selectedExercise;
  bool _isLoading = false;

  CurriculumProvider({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance {
    // Immediate synchronous availability so UI never shows infinite spinner
    _stages = CurriculumSeedData.stages;
    _allExercises = CurriculumSeedData.allExercises;
    _remedialExercises = CurriculumSeedData.allExercises.take(3).toList();
  }

  List<StageModel> get stages => _stages;
  List<ExerciseModel> get allExercises => _allExercises;
  List<ExerciseModel> get remedialExercises => _remedialExercises;
  ExerciseModel? get selectedExercise => _selectedExercise;
  bool get isLoading => _isLoading;

  /// Load or refresh full curriculum from database
  Future<void> loadCurriculum() async {
    if (_stages.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final dbExercises = await _dbHelper.getAllExercises();

      // If DB is empty, use seed data directly
      final sourceExercises = dbExercises.isNotEmpty
          ? dbExercises
          : CurriculumSeedData.allExercises;

      _allExercises = sourceExercises;

      // Map back into StageModel structure with updated scores and completion statuses
      final Map<String, ExerciseModel> exerciseMap = {
        for (var e in sourceExercises) e.id: e,
      };

      _stages = CurriculumSeedData.stages.map((stage) {
        final updatedLessons = stage.lessons.map((lesson) {
          final updatedExercises = lesson.exercises.map((ex) {
            return exerciseMap[ex.id] ?? ex;
          }).toList();

          return LessonModel(
            id: lesson.id,
            stageId: lesson.stageId,
            title: lesson.title,
            subtitle: lesson.subtitle,
            focusPhonemes: lesson.focusPhonemes,
            exercises: updatedExercises,
          );
        }).toList();

        return StageModel(
          id: stage.id,
          stageNumber: stage.stageNumber,
          title: stage.title,
          subtitle: stage.subtitle,
          description: stage.description,
          badgeIconName: stage.badgeIconName,
          lessons: updatedLessons,
        );
      }).toList();

      await refreshRemedialExercises();
    } catch (e) {
      if (kDebugMode) print('Error loading curriculum: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Select an exercise to practice
  void selectExercise(ExerciseModel exercise) {
    _selectedExercise = exercise;
    notifyListeners();
  }

  /// Update exercise score and persist to SQLite
  Future<void> updateExerciseScore(String exerciseId, double score) async {
    try {
      await _dbHelper.updateExerciseScore(exerciseId, score);
      await loadCurriculum();
    } catch (e) {
      if (kDebugMode) print('Error updating exercise score: $e');
    }
  }

  /// Refresh remedial recommendations based on user's weak phonemes (< 65 score)
  Future<void> refreshRemedialExercises([List<String>? explicitWeakPhonemes]) async {
    try {
      List<String> phonemes = explicitWeakPhonemes ?? [];
      if (phonemes.isEmpty) {
        final topWeak = await _dbHelper.getTopWeakPhonemes(limit: 3);
        phonemes = topWeak.map((w) => w.phoneme).toList();
      }

      final results = await _dbHelper.getRecommendedCurriculumExercises(phonemes, limit: 3);
      _remedialExercises = results.isNotEmpty
          ? results
          : _allExercises.take(3).toList();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error refreshing remedial exercises: $e');
      if (_remedialExercises.isEmpty) {
        _remedialExercises = _allExercises.take(3).toList();
        notifyListeners();
      }
    }
  }
}

