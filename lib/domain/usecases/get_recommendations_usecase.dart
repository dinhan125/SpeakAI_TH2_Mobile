import 'package:th2/data/datasources/local/database_helper.dart';
import 'package:th2/data/datasources/local/sample_data.dart';
import 'package:th2/data/models/sentence_model.dart';
import 'package:th2/data/models/weak_phoneme_model.dart';

/// Recommendation Engine as specified in DACTA.md (Section 4.3.B)
/// Identifies the user's top weak phonemes (< 65 score) and recommends
/// targeted minimal pairs and practice sentences from the database.
class GetRecommendationsUseCase {
  final DatabaseHelper _dbHelper;

  GetRecommendationsUseCase({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<SentenceModel>> getRecommendedExercises({int maxExercises = 3}) async {
    // 1. Get top weak phonemes needing practice
    final List<WeakPhonemeModel> weakPhonemes = await _dbHelper.getTopWeakPhonemes(limit: 3);

    final rawSentences = await _dbHelper.getAllSentences();
    final allSentences = rawSentences.isNotEmpty
        ? rawSentences
        : SampleData.initialSentences;

    if (weakPhonemes.isEmpty) {
      // If no weak phonemes recorded yet, return introductory minimal pairs
      return allSentences.take(maxExercises).toList();
    }

    final weakSymbols = weakPhonemes.map((w) => w.phoneme).toSet();

    // 2. Score and sort sentences based on relevance to weak phonemes
    // Sentences with topic 'Minimal Pairs' get an extra boost
    final List<MapEntry<SentenceModel, int>> scored = [];

    for (final sentence in allSentences) {
      int score = 0;
      for (final p in sentence.focusPhonemes) {
        if (weakSymbols.contains(p)) {
          score += 2;
        }
      }
      if (sentence.topic.contains('Minimal Pairs') && score > 0) {
        score += 3;
      }
      if (score > 0) {
        scored.add(MapEntry(sentence, score));
      }
    }

    scored.sort((a, b) => b.value.compareTo(a.value));

    final recommendations = scored.map((e) => e.key).take(maxExercises).toList();

    // If fewer than maxExercises matched, pad with first available sentences
    if (recommendations.length < maxExercises) {
      for (final s in allSentences) {
        if (!recommendations.contains(s)) {
          recommendations.add(s);
          if (recommendations.length == maxExercises) break;
        }
      }
    }

    return recommendations;
  }
}

