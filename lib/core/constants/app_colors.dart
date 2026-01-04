import 'package:flutter/material.dart';

/// Design tokens for Invoicely Pro
/// Premium color palette inspired by Linear/Apple aesthetic
class AppColors {
  // Primary Brand Colors
  static const Color primary = Color(0xFF5048E5); // HTML Primary
  static const Color primaryLight = Color(0xFF818CF8); // Indigo-400
  static const Color primaryDark = Color(0xFF4038C5); // HTML Primary Dark

  // Background Colors
  static const Color background = Color(0xFFF6F6F8); // HTML Background Light
  static const Color surface = Color(0xFFFFFFFF); // White
  static const Color surfaceVariant = Color(0xFFF3F4F6); // Neutral-100

  // Text Colors
  static const Color textPrimary = Color(0xFF121117); // HTML Text Main
  static const Color textSecondary = Color(0xFF656487); // HTML Text Muted
  static const Color textTertiary = Color(0xFF9CA3AF); // Gray-400
  static const Color textOnPrimary = Color(0xFFFFFFFF); // White

  // Semantic Colors
  static const Color success = Color(0xFF10B981); // Emerald-500
  static const Color successLight = Color(0xFFD1FAE5); // Emerald-100
  static const Color warning = Color(0xFFF59E0B); // Amber-500
  static const Color warningLight = Color(0xFFFEF3C7); // Amber-100
  static const Color error = Color(0xFFEF4444); // Red-500
  static const Color errorLight = Color(0xFFFEE2E2); // Red-100
  static const Color info = Color(0xFF3B82F6); // Blue-500
  static const Color infoLight = Color(0xFFDBEAFE); // Blue-100

  // Border Colors
  static const Color border = Color(0xFFE5E7EB); // Gray-200
  static const Color borderLight = Color(0xFFF3F4F6); // Gray-100

  // Invoice Status Colors
  static const Color statusPaid = Color(0xFF10B981); // Emerald-500
  static const Color statusPending = Color(0xFFF59E0B); // Amber-500
  static const Color statusOverdue = Color(0xFFEF4444); // Red-500
  static const Color statusDraft = Color(0xFF6B7280); // Gray-500
  static const Color statusCancelled = Color(0xFF9CA3AF); // Gray-400

  // Overlay Colors
  static const Color overlay = Color(0x66000000); // Black 40%
  static const Color overlayLight = Color(0x33000000); // Black 20%

  // Shadow Colors
  static const Color shadow = Color(
    0x0D000000,
  ); // HTML Shadow Soft (0.05 opacity approx)
  static const Color shadowMedium = Color(0x26000000); // Black 15%
  static const Color shadowHeavy = Color(0x33000000); // Black 20%

  // Quick Action Button Colors
  static const Color indigoBackground = Color(0xFFEEF2FF); // Indigo-50
  static const Color purpleBackground = Color(0xFFFAF5FF); // Purple-50
  static const Color purpleIcon = Color(0xFF9333EA); // Purple-600
  static const Color blueBackground = Color(0xFFEFF6FF); // Blue-50
  static const Color blueIcon = Color(0xFF2563EB); // Blue-600

  // Dark Mode Colors
  static const Color backgroundDark = Color(0xFF121121); // HTML Background Dark
  static const Color surfaceDark = Color(0xFF1E1E2D); // HTML Surface Dark
  static const Color textPrimaryDark = Color(
    0xFFE0E0E0,
  ); // High contrast light gray
  static const Color textSecondaryDark = Color(0xFFB0B0B0); // Medium gray
  static const Color accentTextDark = Color(
    0xFF9FA8DA,
  ); // Light Blue accent text
  static const Color primaryDarkAccent = Color(
    0xFF8B7DFF,
  ); // Modern Indigo (Vibrant)
  static const Color borderDark = Color(0xFF404060); // Dark gray border
  static const Color shadowDark = Color(0x66000000); // Soft depth shadow (40%)

  static const Color successDark = Color(0xFF8BC34A); // Light Green
  static const Color errorDark = Color(0xFFEF5350); // Light Red

  // Smart Invoice Specific
  static const Color errorBg = Color(0xFFFEF2F2); // Red-50
  static const Color indigo50 = Color(0xFFEEF2FF);
  static const Color purple500 = Color(0xFFA855F7);
  static const Color gray100 = Color(0xFFF3F4F6); // Gray-100
  static const Color gray800 = Color(0xFF1F2937); // Gray-800
  static const Color gray900 = Color(0xFF111827); // Gray-900
}
