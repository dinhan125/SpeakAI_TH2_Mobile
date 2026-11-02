import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Audio Player Service responsible for:
/// 1. Native reference text-to-speech (US / UK accents).
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

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.45); // natural pacing for language learners
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

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

  /// Play standard native speech using TTS
  Future<void> speakNativeText(String text, {String accent = 'en-US', double rate = 0.45}) async {
    try {
      await stop();
      await _flutterTts.setLanguage(accent);
      await _flutterTts.setSpeechRate(rate);
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
