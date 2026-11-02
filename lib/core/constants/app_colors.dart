import 'package:flutter/material.dart';

/// App color palette adhering to Vibrant Light Mode (Duolingo/Elsa Speak modern style),
/// Electric Indigo, Vibrant Cyan, Flame Orange Streak, and IPA Tri-color standard.
class AppColors {
  AppColors._();

  // Primary: Electric Indigo & Violet
  static const Color primary = Color(0xFF6366F1);       // Electric Indigo
  static const Color primaryDark = Color(0xFF4338CA);   // Deep Indigo
  static const Color primaryDeepDark = Color(0xFF1E1B4B);
  static const Color primaryMedium = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primarySoft = Color(0xFFEEF2FF);   // 50 Indigo pastel
  static const Color primarySoftBorder = Color(0xFFC7D2FE);

  // Secondary / Accent: Vibrant Cyan
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentCyanSoft = Color(0xFFECFEFF);
  static const Color accentCyanBorder = Color(0xFFA5F3FC);

  // Vibrant Gradient (Indigo to Purple)
  static const LinearGradient vibrantGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Streak: Flame Orange Vibrant Light
  static const Color streakFlame = Color(0xFFFF5722);
  static const Color streakFlameLight = Color(0xFFFF8A65);
  static const Color streakGold = Color(0xFFFF9800);
  static const Color streakOrangeBg = Color(0xFFFFF7ED);      // Soft pastel orange
  static const Color streakOrangeBorder = Color(0xFFFDBA74);  // Warm orange border
  static const Color streakOrangeText = Color(0xFFEA580C);    // Bold dark orange text
  static const LinearGradient streakGradient = LinearGradient(
    colors: [Color(0xFFFF5722), Color(0xFFFF9100)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // IPA Phoneme Assessment Colors
  // >= 80%: Excellent / Good (Green)
  static const Color phonemeGood = Color(0xFF10B981);
  static const Color phonemeGoodBg = Color(0xFFECFDF5);
  static const Color phonemeGoodBorder = Color(0xFFA7F3D0);

  // 50% - 79%: Fair / Warning (Amber / Yellow)
  static const Color phonemeWarning = Color(0xFFF59E0B);
  static const Color phonemeWarningBg = Color(0xFFFFFBEB);
  static const Color phonemeWarningBorder = Color(0xFFFDE68A);

  // < 50%: Poor / Error (Crimson Red)
  static const Color phonemeBad = Color(0xFFEF4444);
  static const Color phonemeBadBg = Color(0xFFFEF2F2);
  static const Color phonemeBadBorder = Color(0xFFFECACA);

  // Neutral Background & Surfaces (Vibrant Light Mode)
  static const Color backgroundLight = Color(0xFFF4F7FE); // Trắng ánh xanh pastel trẻ trung
  static const Color surfaceLight = Color(0xFFFFFFFF);    // Trắng tinh khiết
  static const Color surfaceMutedLight = Color(0xFFF8FAFC);
  static const Color borderLight = Color(0xFFE2E8F0);

  // Neutral Background & Surfaces (Dark)
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color surfaceMutedDark = Color(0xFF334155);
  static const Color borderDark = Color(0xFF475569);

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF0F172A);   // Đậm nét, sắc nét
  static const Color textSecondaryLight = Color(0xFF64748B); // Xám trung tính hiện đại
  static const Color textMutedLight = Color(0xFF94A3B8);

  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFFCBD5E1);
  static const Color textMutedDark = Color(0xFF64748B);

  // Functional Accents
  static const Color audioWaveform = Color(0xFF6366F1);
  static const Color audioListening = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color info = Color(0xFF3B82F6);

  /// Helper to get color by score
  static Color getScoreColor(double score) {
    if (score >= 80.0) return phonemeGood;
    if (score >= 50.0) return phonemeWarning;
    return phonemeBad;
  }

  /// Helper to get background color by score
  static Color getScoreBgColor(double score) {
    if (score >= 80.0) return phonemeGoodBg;
    if (score >= 50.0) return phonemeWarningBg;
    return phonemeBadBg;
  }

  /// Helper to get border color by score
  static Color getScoreBorderColor(double score) {
    if (score >= 80.0) return phonemeGoodBorder;
    if (score >= 50.0) return phonemeWarningBorder;
    return phonemeBadBorder;
  }
}
