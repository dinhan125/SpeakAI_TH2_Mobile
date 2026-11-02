import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Audio Player Service responsible for:
/// 1. Native reference text-to-speech (US / UK accents) with multi-speed tuning.
/// 2. Playing back user's recorded audio files.
class AudioPlayerService {
  static final AudioPlayerService instance = AudioPlayerService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  AudioPlayerService._internal() {
    _initTts();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying = (state == PlayerState.playing);
    });
  }

  /// Map user-friendly speed multiplier (1.0x, 0.75x, 0.5x) to platform TTS engine rate.
  ///
  /// - Web Speech API: 1.0 is normal rate. 0.55 is half rate.
  /// - Mobile (iOS, Android) & Windows: flutter_tts maps ~0.50 to normal 1.0x.
  ///   - 1.0x: 0.53 (fluent, natural conversational speed; fixes the "hơi chậm" issue)
  ///   - 0.75x: 0.43 (clear, comfortable slow speed)
  ///   - 0.5x: 0.35 (clearly audible half speed without stutter or engine cutoff; fixes "không nghe được")
  static double getEngineSpeechRate(double speedMultiplier) {
    if (kIsWeb) {
      if (speedMultiplier <= 0.5) return 0.55;
      if (speedMultiplier <= 0.75) return 0.75;
      return 1.0 * speedMultiplier;
    }

    // Android / iOS / Windows:
    if (speedMultiplier >= 1.0) {
      return 0.53; // Standard fluent conversational speed (previous 0.45 was noticeably sluggish)
    } else if (speedMultiplier >= 0.7) {
      return 0.43; // Moderate slow speed for comfortable phoneme following
    } else {
      // 0.5x speed: 0.35 guarantees clear vocalization on Android/SAPI/WinRT without clipping
      return 0.35;
    }
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(getEngineSpeechRate(1.0));
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      try {
        await _flutterTts.awaitSpeakCompletion(true);
      } catch (_) {
        // Not all platforms support awaitSpeakCompletion
      }

      _flutterTts.setCompletionHandler(() {
        _isPlaying = false;
      });
      _flutterTts.setErrorHandler((msg) {
        _isPlaying = false;
        if (kDebugMode) print('TTS Error: $msg');
      });
    } catch (e) {
      if (kDebugMode) print('Error initializing TTS: $e');
    }
  }

  /// Play standard native speech using TTS with user-facing speed multiplier (1.0, 0.75, 0.5)
  Future<void> speakNativeWithSpeed(
    String text, {
    String accent = 'en-US',
    double speed = 1.0,
  }) async {
    final double engineRate = getEngineSpeechRate(speed);
    await speakNativeText(text, accent: accent, rate: engineRate);
  }

  /// Play standard native speech using TTS with direct engine rate
  Future<void> speakNativeText(
    String text, {
    String accent = 'en-US',
    double? rate,
  }) async {
    try {
      if (_isPlaying) {
        await stop();
        await Future.delayed(const Duration(milliseconds: 50));
      }
      final double targetRate = rate ?? getEngineSpeechRate(1.0);
      await _flutterTts.setLanguage(accent);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(targetRate);
      _isPlaying = true;
      await _flutterTts.speak(text);
    } catch (e) {
      if (kDebugMode) print('TTS speak error: $e');
      _isPlaying = false;
    }
  }

  /// Play user's recorded audio file
  Future<void> playAudioFile(String filePath) async {
    try {
      await stop();
      if (!kIsWeb) {
        final file = File(filePath);
        if (await file.exists()) {
          _isPlaying = true;
          await _audioPlayer.play(DeviceFileSource(filePath));
        } else {
          if (kDebugMode) print('Audio file does not exist: $filePath');
        }
      } else {
        _isPlaying = true;
        await _audioPlayer.play(UrlSource(filePath));
      }
    } catch (e) {
      if (kDebugMode) print('Error playing audio file: $e');
      _isPlaying = false;
    }
  }

  /// Stop both TTS and audio player
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      await _audioPlayer.stop();
      _isPlaying = false;
    } catch (_) {}
  }

  void dispose() {
    _flutterTts.stop();
    _audioPlayer.dispose();
  }
}
