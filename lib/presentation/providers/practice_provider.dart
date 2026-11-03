import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:th2/core/constants/app_constants.dart';
import 'package:th2/core/services/audio_player_service.dart';
import 'package:th2/core/services/audio_recorder_service.dart';
import 'package:th2/core/services/speech_assessment_service.dart';
import 'package:th2/data/datasources/local/database_helper.dart';
import 'package:th2/data/models/practice_session_model.dart';
import 'package:th2/data/models/sentence_model.dart';
import 'package:th2/data/models/phoneme_assessment_model.dart';
import 'package:th2/data/datasources/local/sample_data.dart';
import 'package:th2/domain/usecases/get_recommendations_usecase.dart';

/// Provider orchestrating the Practice flow: Recording, Audio Playback,
/// AI Speech Assessment, and History Persistence.
class PracticeProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper;
  final AudioRecorderService _recorder = AudioRecorderService.instance;
  final AudioPlayerService _player = AudioPlayerService.instance;
  final SpeechAssessmentService _assessmentService = SpeechAssessmentService.instance;
  final GetRecommendationsUseCase _recommendationsUseCase;

  List<SentenceModel> _sentences = SampleData.initialSentences;
  List<SentenceModel> _recommendedSentences = SampleData.initialSentences.take(3).toList();
  SentenceModel? _currentSentence = SampleData.initialSentences.first;

  bool _isLoading = false;
  bool _isAssessing = false;
  String? _lastRecordedAudioPath;
  Map<String, dynamic>? _lastResult;

  // Active testing profile (Section 7.1)
  SpeechTestingProfile _testingProfile = SpeechTestingProfile.realistic;

  PracticeProvider({
    DatabaseHelper? dbHelper,
    GetRecommendationsUseCase? recommendationsUseCase,
  })  : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _recommendationsUseCase =
            recommendationsUseCase ?? GetRecommendationsUseCase() {
    _sentences = SampleData.initialSentences;
    _currentSentence = SampleData.initialSentences.first;
    _recommendedSentences = SampleData.initialSentences.take(3).toList();
  }

  List<SentenceModel> get sentences => _sentences;
  List<SentenceModel> get recommendedSentences => _recommendedSentences;
  SentenceModel? get currentSentence => _currentSentence;
  bool get isLoading => _isLoading;
  bool get isRecording => _recorder.isRecording;
  bool get isAssessing => _isAssessing;
  bool get isPlayingAudio => _player.isPlaying;
  String? get lastRecordedAudioPath => _lastRecordedAudioPath;
  Map<String, dynamic>? get lastResult => _lastResult;
  SpeechTestingProfile get testingProfile => _testingProfile;
  Stream<double> get amplitudeStream => _recorder.amplitudeStream;
  double _playbackSpeed = 1.0;
  double get playbackSpeed => _playbackSpeed;

  void setPlaybackSpeed(double speed) {
    _playbackSpeed = speed;
    notifyListeners();
  }

  /// Load all sentences and recommendations
  Future<void> loadSentences() async {
    _isLoading = true;
    notifyListeners();

    try {
      _sentences = await _dbHelper.getAllSentences();
      if (_sentences.isNotEmpty && _currentSentence == null) {
        _currentSentence = _sentences.first;
      }
      await refreshRecommendations();
    } catch (e) {
      if (kDebugMode) print('Error loading sentences: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Select a specific sentence to practice
  void selectSentence(SentenceModel sentence) {
    _currentSentence = sentence;
    _lastResult = null;
    _lastRecordedAudioPath = null;
    notifyListeners();
  }

  /// Refresh personalized recommendations based on weak phonemes
  Future<void> refreshRecommendations() async {
    try {
      _recommendedSentences =
          await _recommendationsUseCase.getRecommendedExercises(maxExercises: 3);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error refreshing recommendations: $e');
    }
  }

  /// Change testing profile (Multi-accent / Negative testing)
  void setTestingProfile(SpeechTestingProfile profile) {
    _testingProfile = profile;
    notifyListeners();
  }

  /// Start voice recording
  Future<bool> startRecording() async {
    _lastResult = null;
    notifyListeners();
    final started = await _recorder.startRecording();
    notifyListeners();
    return started;
  }

  /// Stop recording and trigger AI pronunciation assessment
  Future<Map<String, dynamic>?> stopAndEvaluate({required int durationSeconds}) async {
    _isAssessing = true;
    notifyListeners();

    try {
      String? audioPath;
      try {
        audioPath = await _recorder.stopRecording().timeout(
          const Duration(milliseconds: 1500),
          onTimeout: () => _recorder.currentRecordingPath ?? 'recorded_sample.wav',
        );
      } catch (e) {
        audioPath = _recorder.currentRecordingPath ?? 'recorded_sample.wav';
      }
      _lastRecordedAudioPath = audioPath;

      if (_currentSentence == null) {
        _isAssessing = false;
        notifyListeners();
        return null;
      }

      // Extract VAD (Voice Activity Detection) metrics from recording
      final meta = _recorder.lastRecordingMetadata;
      final isSilence = (meta != null && meta.isSilent) || durationSeconds < 1;

      // Assess pronunciation via AI service (~320ms)
      final result = await _assessmentService.assessPronunciation(
        referenceText: _currentSentence!.text,
        audioPath: audioPath,
        durationSeconds: durationSeconds,
        profile: _testingProfile,
        isSilence: isSilence,
        speechRatio: meta?.speechRatio ?? 0.0,
        maxDecibels: meta?.maxDecibels ?? -60.0,
      );

      // Immediately publish result and dismiss loading spinner so UI is instant!
      _lastResult = result;
      _isAssessing = false;
      notifyListeners();

      // Persist session to local SQLite database ONLY if real voice was detected!
      if (result['is_silent'] != true) {
        _persistSessionInBackground(result, audioPath, durationSeconds);
      }

      return result;
    } catch (e) {
      if (kDebugMode) print('Error during assessment: $e');
      _isAssessing = false;
      notifyListeners();
      return null;
    } finally {
      if (_isAssessing) {
        _isAssessing = false;
        notifyListeners();
      }
    }
  }

  /// Persist practice session, update phoneme scores & exercise scores in background
  void _persistSessionInBackground(
    Map<String, dynamic> result,
    String? audioPath,
    int durationSeconds,
  ) {
    Future(() async {
      try {
        final words = result['words'] as List<WordAssessmentModel>;
        final overallScore = (result['overall_score'] as num).toDouble();
        final accuracyScore = (result['accuracy_score'] as num).toDouble();
        final fluencyScore = (result['fluency_score'] as num).toDouble();
        final completenessScore = (result['completeness_score'] as num).toDouble();

        final session = PracticeSessionModel(
          id: 'sess_${const Uuid().v4()}',
          userId: AppConstants.defaultUserId,
          sentenceId: _currentSentence?.id ?? 'custom',
          userAudioPath: audioPath,
          overallScore: overallScore,
          accuracyScore: accuracyScore,
          fluencyScore: fluencyScore,
          completenessScore: completenessScore,
          wordDetails: words,
          durationSeconds: durationSeconds,
          createdAt: DateTime.now(),
        );
        await _dbHelper.insertPracticeSession(session);

        // Update weak phonemes in database using EMA formula
        for (final word in words) {
          for (final phoneme in word.phonemes) {
            await _dbHelper.updatePhonemeScore(phoneme.phoneme, phoneme.score);
          }
        }

        // If practicing a roadmap exercise, update exercise's best score
        if (_currentSentence != null) {
          await _dbHelper.updateExerciseScore(_currentSentence!.id, overallScore);
        }

        // Refresh recommendations with newly updated weak phonemes
        await refreshRecommendations();
      } catch (e) {
        if (kDebugMode) print('Background persistence error (non-fatal): $e');
      }
    });
  }

  int get currentSentenceIndex {
    if (_currentSentence == null || _sentences.isEmpty) return 0;
    final idx = _sentences.indexWhere((s) => s.id == _currentSentence!.id);
    return idx >= 0 ? idx : 0;
  }

  int get totalSentencesCount => _sentences.length;

  void nextSentence() {
    if (_sentences.isEmpty) return;
    final nextIdx = (currentSentenceIndex + 1) % _sentences.length;
    selectSentence(_sentences[nextIdx]);
  }

  void previousSentence() {
    if (_sentences.isEmpty) return;
    final prevIdx = (currentSentenceIndex - 1 + _sentences.length) % _sentences.length;
    selectSentence(_sentences[prevIdx]);
  }

  Future<String> _getUserAccent() async {
    try {
      final user = await _dbHelper.getUser(AppConstants.defaultUserId);
      return user.preferredAccent;
    } catch (_) {
      return AppConstants.defaultAccent;
    }
  }

  /// Play native standard pronunciation at normal speed (1.0x)
  Future<void> playSampleNativeAudio({String? accent}) async {
    if (_currentSentence == null) return;
    _playbackSpeed = 1.0;
    final target = accent ?? await _getUserAccent();
    await _player.speakNativeWithSpeed(_currentSentence!.text, accent: target, speed: 1.0);
    notifyListeners();
  }

  /// Play native pronunciation slowly (0.75x) for clear phoneme dissection
  Future<void> playSampleNativeAudioSlow({String? accent}) async {
    if (_currentSentence == null) return;
    _playbackSpeed = 0.75;
    final target = accent ?? await _getUserAccent();
    await _player.speakNativeWithSpeed(_currentSentence!.text, accent: target, speed: 0.75);
    notifyListeners();
  }

  /// Play native pronunciation very slowly (0.5x) with guaranteed clear audio and no cutoffs
  Future<void> playSampleNativeAudioVerySlow({String? accent}) async {
    if (_currentSentence == null) return;
    _playbackSpeed = 0.5;
    final target = accent ?? await _getUserAccent();
    await _player.speakNativeWithSpeed(_currentSentence!.text, accent: target, speed: 0.5);
    notifyListeners();
  }

  /// Play pronunciation of an individual word
  Future<void> playSpecificWord(String word, {String? accent}) async {
    final target = accent ?? await _getUserAccent();
    await _player.speakNativeWithSpeed(word, accent: target, speed: 0.85);
    notifyListeners();
  }

  /// Direct AI assessment simulation for testing/demo (Section 7.1)
  Future<Map<String, dynamic>?> simulateAssessment([SpeechTestingProfile? profile]) async {
    if (profile != null) {
      _testingProfile = profile;
    }
    _isAssessing = true;
    _lastResult = null;
    notifyListeners();

    try {
      if (_currentSentence == null) {
        _isAssessing = false;
        notifyListeners();
        return null;
      }

      final isSilence = (_testingProfile == SpeechTestingProfile.silentNoSpeech);

      final result = await _assessmentService.assessPronunciation(
        referenceText: _currentSentence!.text,
        audioPath: 'simulated_audio.wav',
        durationSeconds: isSilence ? 1 : 3,
        profile: _testingProfile,
        isSilence: isSilence,
        speechRatio: isSilence ? 0.0 : 0.72,
        maxDecibels: isSilence ? -65.0 : -18.0,
      );

      // Immediately publish result and dismiss loading spinner
      _lastResult = result;
      _lastRecordedAudioPath = 'simulated_audio.wav';
      _isAssessing = false;
      notifyListeners();

      // Persist session to local SQLite database in background ONLY if voice is present
      if (!isSilence) {
        _persistSessionInBackground(result, 'simulated_audio.wav', 3);
      }

      return result;
    } catch (e) {
      if (kDebugMode) print('Simulation error: $e');
      _isAssessing = false;
      notifyListeners();
      return null;
    } finally {
      if (_isAssessing) {
        _isAssessing = false;
        notifyListeners();
      }
    }
  }

  /// Play back user's recorded audio
  Future<void> playUserRecording() async {
    if (_lastRecordedAudioPath == null) return;
    await _player.playAudioFile(_lastRecordedAudioPath!);
    notifyListeners();
  }

  /// Stop any running audio playback
  Future<void> stopAudioPlayback() async {
    await _player.stop();
    notifyListeners();
  }
}
