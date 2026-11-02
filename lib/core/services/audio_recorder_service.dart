import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_constants.dart';

/// Audio Recording Metadata containing VAD (Voice Activity Detection) metrics
class AudioRecordingMetadata {
  final String? path;
  final int durationSeconds;
  final double maxDecibels;
  final double averageDecibels;
  final double speechRatio;
  final bool hasVoiceActivity;
  final bool isSilent;
  final int speechFramesCount;
  final int totalFramesCount;

  const AudioRecordingMetadata({
    required this.path,
    required this.durationSeconds,
    required this.maxDecibels,
    required this.averageDecibels,
    required this.speechRatio,
    required this.hasVoiceActivity,
    required this.isSilent,
    required this.speechFramesCount,
    required this.totalFramesCount,
  });
}

/// Audio Recorder Service handling high-fidelity voice recording (16kHz, 16-bit PCM/WAV),
/// real-time VAD (Voice Activity Detection), and energy polling for audio waveform animation.
class AudioRecorderService {
  static final AudioRecorderService instance = AudioRecorderService._internal();

  AudioRecorder? _audioRecorder;
  Timer? _amplitudeTimer;
  final StreamController<double> _amplitudeController = StreamController<double>.broadcast();

  bool _isRecording = false;
  String? _currentRecordingPath;
  AudioRecordingMetadata? _lastRecordingMetadata;

  // Real-time VAD & energy statistics
  int _speechFramesCount = 0;
  int _totalFramesCount = 0;
  double _maxDecibels = -120.0;
  double _sumDecibels = 0.0;

  AudioRecorderService._internal() {
    _audioRecorder = AudioRecorder();
  }

  Stream<double> get amplitudeStream => _amplitudeController.stream;
  bool get isRecording => _isRecording;
  String? get currentRecordingPath => _currentRecordingPath;
  AudioRecordingMetadata? get lastRecordingMetadata => _lastRecordingMetadata;

  /// Start voice recording with 16kHz sample rate mono WAV
  Future<bool> startRecording() async {
    try {
      _audioRecorder ??= AudioRecorder();

      // Reset VAD stats
      _speechFramesCount = 0;
      _totalFramesCount = 0;
      _maxDecibels = -120.0;
      _sumDecibels = 0.0;

      // Check and request microphone permission with timeout
      bool hasPermission = false;
      try {
        hasPermission = await _audioRecorder!.hasPermission().timeout(
          const Duration(milliseconds: 2500),
          onTimeout: () => false,
        );
      } catch (e) {
        if (kDebugMode) print('Microphone permission check error: $e');
        hasPermission = false;
      }

      String filePath = '';
      if (!kIsWeb) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'rec_${const Uuid().v4()}.wav';
        filePath = p.join(appDir.path, fileName);
      } else {
        filePath = 'web_rec_${const Uuid().v4()}.wav';
      }
      _currentRecordingPath = filePath;

      if (!hasPermission) {
        if (kDebugMode) print('Microphone permission denied or unavailable');
        _isRecording = true;
        // Keep baseline flatline when mic permission is missing (do not fake human voice)
        _amplitudeTimer?.cancel();
        _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
          if (_isRecording) {
            _amplitudeController.add(0.02);
          }
        });
        return true;
      }

      // Configure recording: 16-bit PCM, 16,000 Hz, 1 channel (Mono)
      const config = RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: AppConstants.audioSampleRate,
        numChannels: AppConstants.audioChannels,
        bitRate: 256000,
      );

      await _audioRecorder!.start(config, path: filePath).timeout(
        const Duration(milliseconds: 2000),
        onTimeout: () {
          if (kDebugMode) print('AudioRecorder start timed out');
        },
      );
      _isRecording = true;

      // Start periodic amplitude & VAD polling (50ms interval)
      _amplitudeTimer?.cancel();
      _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 50), (_) async {
        if (_isRecording && _audioRecorder != null) {
          try {
            final amp = await _audioRecorder!.getAmplitude();
            final db = amp.current;

            _totalFramesCount++;
            if (db.isFinite) {
              if (db > _maxDecibels) _maxDecibels = db;
              _sumDecibels += db;

              // Voice activity threshold: Near-field human speech is typically -35 dB to -8 dB
              // Silence or room background noise is typically below -45 dB
              if (db > -35.0) {
                _speechFramesCount++;
              }
            }

            // Calculate normalized visual amplitude 0.02 -> 1.0 for the waveform animation
            double normalized = 0.02; // flat baseline when silent
            if (db.isFinite && db > -55.0) {
              normalized = ((db + 55.0) / 55.0).clamp(0.04, 1.0);
            }
            _amplitudeController.add(normalized);
          } catch (_) {
            _amplitudeController.add(0.02);
          }
        }
      });

      return true;
    } catch (e) {
      if (kDebugMode) print('Error starting recording: $e');
      _isRecording = true;
      _amplitudeTimer?.cancel();
      _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
        if (_isRecording) {
          _amplitudeController.add(0.02);
        }
      });
      return true;
    }
  }

  /// Stop voice recording and compile VAD metadata
  Future<String?> stopRecording() async {
    _amplitudeTimer?.cancel();
    _amplitudeTimer = null;

    if (!_isRecording) {
      return _currentRecordingPath ?? 'recorded_sample.wav';
    }

    _isRecording = false;

    // Calculate real VAD stats from audio frames
    final avgDb = _totalFramesCount > 0 ? (_sumDecibels / _totalFramesCount) : -120.0;
    final speechRatio = _totalFramesCount > 0 ? (_speechFramesCount / _totalFramesCount) : 0.0;

    // Human voice detection criteria:
    // Requires at least 3 speech frames (~150ms of audio) with peak dB >= -36.0 dB
    final bool hasVoice = (_speechFramesCount >= 3) && (_maxDecibels >= -36.0);
    final bool isSilent = !hasVoice;

    _lastRecordingMetadata = AudioRecordingMetadata(
      path: _currentRecordingPath,
      durationSeconds: (_totalFramesCount * 0.05).round(),
      maxDecibels: _maxDecibels,
      averageDecibels: avgDb,
      speechRatio: speechRatio,
      hasVoiceActivity: hasVoice,
      isSilent: isSilent,
      speechFramesCount: _speechFramesCount,
      totalFramesCount: _totalFramesCount,
    );

    if (kDebugMode) {
      print('VAD Summary: frames=$_totalFramesCount, speechFrames=$_speechFramesCount, '
          'maxDb=$_maxDecibels, avgDb=$avgDb, speechRatio=$speechRatio, isSilent=$isSilent');
    }

    if (_audioRecorder != null) {
      try {
        final path = await _audioRecorder!.stop().timeout(
          const Duration(milliseconds: 1200),
          onTimeout: () {
            if (kDebugMode) print('AudioRecorder.stop timed out on web, returning fallback path');
            return _currentRecordingPath ?? 'recorded_sample.wav';
          },
        );
        _currentRecordingPath = path ?? _currentRecordingPath ?? 'recorded_sample.wav';
        return _currentRecordingPath;
      } catch (e) {
        if (kDebugMode) print('Error stopping recording: $e');
        return _currentRecordingPath ?? 'recorded_sample.wav';
      }
    }

    return _currentRecordingPath ?? 'recorded_sample.wav';
  }

  /// Cancel current recording without saving
  Future<void> cancelRecording() async {
    _amplitudeTimer?.cancel();
    _amplitudeTimer = null;

    if (_isRecording && _audioRecorder != null) {
      try {
        final path = await _audioRecorder!.stop();
        if (path != null && !kIsWeb) {
          final file = File(path);
          if (await file.exists()) {
            await file.delete();
          }
        }
      } catch (_) {}
    }
    _isRecording = false;
    _currentRecordingPath = null;
    _lastRecordingMetadata = null;
  }

  void dispose() {
    _amplitudeTimer?.cancel();
    _audioRecorder?.dispose();
    _amplitudeController.close();
  }
}
