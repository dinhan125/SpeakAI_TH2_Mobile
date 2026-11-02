import 'dart:async';
import 'package:flutter/material.dart';
import 'package:th2/core/constants/app_colors.dart';
import 'package:th2/core/constants/app_spacing.dart';
import 'package:th2/core/utils/haptic_helper.dart';

/// Waveform Recording Button with concentric ripple animation
/// and live amplitude bar visualization.
class AudioWaveformRecorder extends StatefulWidget {
  final bool isRecording;
  final Stream<double> amplitudeStream;
  final VoidCallback onStartRecording;
  final Function(int durationSeconds) onStopRecording;

  const AudioWaveformRecorder({
    super.key,
    required this.isRecording,
    required this.amplitudeStream,
    required this.onStartRecording,
    required this.onStopRecording,
  });

  @override
  State<AudioWaveformRecorder> createState() => _AudioWaveformRecorderState();
}

class _AudioWaveformRecorderState extends State<AudioWaveformRecorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _rippleController;
  Timer? _recordTimer;
  int _secondsRecorded = 0;
  double _currentAmplitude = 0.15;
  StreamSubscription<double>? _ampSub;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _ampSub = widget.amplitudeStream.listen((amp) {
      if (mounted && widget.isRecording) {
        setState(() {
          _currentAmplitude = amp;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant AudioWaveformRecorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !oldWidget.isRecording) {
      _startTimer();
      _rippleController.repeat();
    } else if (!widget.isRecording && oldWidget.isRecording) {
      _stopTimer();
      _rippleController.stop();
      _rippleController.reset();
    }
  }

  void _startTimer() {
    _secondsRecorded = 0;
    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _secondsRecorded++;
        });
      }
    });
  }

  void _stopTimer() {
    _recordTimer?.cancel();
    _recordTimer = null;
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _ampSub?.cancel();
    _rippleController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticHelper.mediumImpact();
    if (widget.isRecording) {
      final duration = _secondsRecorded;
      _stopTimer();
      widget.onStopRecording(duration > 0 ? duration : 1);
    } else {
      widget.onStartRecording();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Recording status & timer
        if (widget.isRecording) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.phonemeBadBg,
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              border: Border.all(color: AppColors.phonemeBad.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.phonemeBad,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Đang lắng nghe... 00:${_secondsRecorded.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.phonemeBad,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Real-time Waveform Bars
          SizedBox(
            height: 36,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(12, (index) {
                // Generate dynamic height variation based on amplitude
                final offset = (index - 6).abs();
                final barHeight = (10 + (_currentAmplitude * 26) - (offset * 2)).clamp(6.0, 32.0);

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 80),
                  width: 4,
                  height: barHeight,
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  decoration: BoxDecoration(
                    color: AppColors.primaryMedium,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // Circular Button with Ripple Animation
        Center(
          child: SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ripple Ring 1
                if (widget.isRecording)
                  AnimatedBuilder(
                    animation: _rippleController,
                    builder: (context, child) {
                      final scale = 1.0 + (_rippleController.value * 0.45);
                      final opacity = (1.0 - _rippleController.value).clamp(0.0, 1.0);
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.streakFlame.withValues(alpha: opacity * 0.5),
                              width: 3,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                // Main Button
                GestureDetector(
                  onTap: _handleTap,
                  child: Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: widget.isRecording
                          ? AppColors.streakGradient
                          : const LinearGradient(
                              colors: [Color(0xFF312E81), Color(0xFF4F46E5)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      boxShadow: widget.isRecording
                          ? AppSpacing.flameShadow
                          : AppSpacing.activeCardShadow,
                    ),
                    child: Icon(
                      widget.isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 6),
        Text(
          widget.isRecording
              ? 'Nhấn nút đỏ để hoàn thành và chấm điểm'
              : 'Nhấn mic để bắt đầu luyện đọc',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

