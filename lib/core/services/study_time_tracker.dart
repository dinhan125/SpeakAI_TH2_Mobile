import 'dart:async';
import 'package:flutter/widgets.dart';

/// Tracks active user study time using a Stopwatch and WidgetsBindingObserver.
/// Automatically pauses when the app goes into the background and resumes when active.
class StudyTimeTracker with WidgetsBindingObserver {
  static final StudyTimeTracker instance = StudyTimeTracker._internal();

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;
  bool _isTracking = false;

  final StreamController<int> _secondsController = StreamController<int>.broadcast();

  StudyTimeTracker._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

  Stream<int> get elapsedSecondsStream => _secondsController.stream;
  int get elapsedSeconds => _stopwatch.elapsed.inSeconds;
  bool get isTracking => _isTracking;

  /// Start or resume tracking practice duration
  void startTracking() {
    if (_isTracking) return;
    _isTracking = true;
    _stopwatch.start();

    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isTracking && _stopwatch.isRunning) {
        _secondsController.add(_stopwatch.elapsed.inSeconds);
      }
    });
  }

  /// Pause tracking (e.g., when audio is paused or user navigates away)
  void pauseTracking() {
    _ticker?.cancel();
    _ticker = null;
    _stopwatch.stop();
  }

  /// Resume tracking
  void resumeTracking() {
    if (!_isTracking) return;
    _stopwatch.start();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isTracking && _stopwatch.isRunning) {
        _secondsController.add(_stopwatch.elapsed.inSeconds);
      }
    });
  }

  /// Stop tracking and return total elapsed seconds accumulated in this session
  int stopAndReset() {
    _ticker?.cancel();
    _ticker = null;
    _stopwatch.stop();
    final elapsed = _stopwatch.elapsed.inSeconds;
    _stopwatch.reset();
    _isTracking = false;
    return elapsed;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isTracking) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      pauseTracking();
    } else if (state == AppLifecycleState.resumed) {
      resumeTracking();
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _stopwatch.stop();
    _secondsController.close();
  }
}

