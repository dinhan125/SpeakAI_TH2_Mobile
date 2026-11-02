import 'package:flutter/services.dart';

/// Helper for clean tactile feedback across key interactions.
class HapticHelper {
  HapticHelper._();

  /// Light tap for buttons, chips, tabs
  static Future<void> lightImpact() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Medium tap for recording start/stop
  static Future<void> mediumImpact() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Heavy impact for completing a goal or scoring 100%
  static Future<void> heavyImpact() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Selection click for switching values
  static Future<void> selectionClick() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }
}

