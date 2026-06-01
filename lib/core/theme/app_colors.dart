import 'package:flutter/material.dart';

/// Premium automotive color palette for AI Auto Doctor
class AppColors {
  AppColors._();

  // === Primary Brand ===
  static const Color primary = Color(0xFF00D4FF);
  static const Color primaryDark = Color(0xFF0098CC);
  static const Color primaryLight = Color(0xFF66E5FF);

  // === Backgrounds ===
  static const Color backgroundDark = Color(0xFF0A0E1A);
  static const Color backgroundSecondary = Color(0xFF101529);
  static const Color surface = Color(0xFF141828);
  static const Color surfaceLight = Color(0xFF1C2240);
  static const Color surfaceHighlight = Color(0xFF242B4A);

  // === Status Colors ===
  static const Color success = Color(0xFF2ED573);
  static const Color successDark = Color(0xFF1FA558);
  static const Color warning = Color(0xFFFFA502);
  static const Color warningDark = Color(0xFFCC8400);
  static const Color error = Color(0xFFFF4757);
  static const Color errorDark = Color(0xFFCC3844);
  static const Color critical = Color(0xFFFF2D3B);

  // === Text ===
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B8D1);
  static const Color textTertiary = Color(0xFF6B7394);
  static const Color textDisabled = Color(0xFF4A5068);

  // === Gauge & Chart Gradients ===
  static const Color gaugeGreen = Color(0xFF2ED573);
  static const Color gaugeYellow = Color(0xFFFFC107);
  static const Color gaugeOrange = Color(0xFFFF9500);
  static const Color gaugeRed = Color(0xFFFF4757);

  // === Accent ===
  static const Color accentPurple = Color(0xFF7C4DFF);
  static const Color accentBlue = Color(0xFF448AFF);
  static const Color accentCyan = Color(0xFF00BCD4);

  // === Borders & Dividers ===
  static const Color border = Color(0xFF1E2545);
  static const Color divider = Color(0xFF1A1F3A);

  // === Card Overlay / Glass ===
  static const Color glassWhite = Color(0x12FFFFFF);
  static const Color glassBorder = Color(0x20FFFFFF);

  // === Gradients ===
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00D4FF), Color(0xFF7C4DFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0A0E1A), Color(0xFF101529)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF2ED573), Color(0xFF1FA558)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFFFA502), Color(0xFFFF6B00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient errorGradient = LinearGradient(
    colors: [Color(0xFFFF4757), Color(0xFFFF2D3B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gaugeGradient = LinearGradient(
    colors: [Color(0xFF2ED573), Color(0xFFFFC107), Color(0xFFFF4757)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Get color for health score value (0-100)
  static Color healthScoreColor(int score) {
    if (score >= 80) return success;
    if (score >= 50) return warning;
    return error;
  }

  /// Get color for severity level
  static Color severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'low':
      case 'низкая':
        return success;
      case 'medium':
      case 'средняя':
        return warning;
      case 'high':
      case 'высокая':
        return error;
      case 'critical':
      case 'критическая':
        return critical;
      default:
        return textSecondary;
    }
  }
}
