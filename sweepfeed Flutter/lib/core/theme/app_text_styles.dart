import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Display Styles
  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'Inter', // Assuming Inter font, replace if different
    fontSize: 57,
    fontWeight: FontWeight.w800,
    color: AppColors.textWhite,
    letterSpacing: -0.25,
    height: 1.12, // 64px line height
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 45,
    fontWeight: FontWeight.w700,
    color: AppColors.textWhite,
    letterSpacing: 0,
    height: 1.15, // 52px line height
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 36,
    fontWeight: FontWeight.w600,
    color: AppColors.textWhite,
    letterSpacing: 0,
    height: 1.22, // 44px line height
  );

  // Headline Styles
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 32,
    fontWeight: FontWeight.w700, // Bold
    color: AppColors.textWhite,
    letterSpacing: 0,
    height: 1.25, // 40px line height
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 28,
    fontWeight: FontWeight.w600, // Semi-bold
    color: AppColors.textWhite,
    letterSpacing: 0,
    height: 1.28, // 36px line height
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 24,
    fontWeight: FontWeight.w500, // Medium
    color: AppColors.textWhite,
    letterSpacing: 0,
    height: 1.33, // 32px line height
  );

  // Title Styles
  static const TextStyle titleLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 22,
    fontWeight: FontWeight.w600, // Medium
    color: AppColors.textWhite,
    letterSpacing: 0.15,
    height: 1.27, // 28px line height
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w600, // Medium
    color: AppColors.textWhite, // Usually textWhite for titles
    letterSpacing: 0.15,
    height: 1.5, // 24px line height
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w500, // Medium
    color: AppColors.textWhite, // Usually textWhite for titles
    letterSpacing: 0.1,
    height: 1.42, // 20px line height
  );

  // Body Styles
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.normal, // Regular
    color: AppColors.textWhite,
    letterSpacing: 0.5,
    height: 1.5, // 24px line height
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.normal, // Regular
    color: AppColors.textLight, // Often a lighter color for secondary body text
    letterSpacing: 0.25,
    height: 1.42, // 20px line height
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.normal, // Regular
    color: AppColors.textMuted, // Muted for less emphasis
    letterSpacing: 0.4,
    height: 1.33, // 16px line height
  );

  // Label Styles (for buttons, captions, etc.)
  static const TextStyle labelLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16, // Adjusted from 14 based on plan
    fontWeight: FontWeight.w600, // Medium - good for buttons
    color: AppColors.primaryDark, // Text color on accent buttons
    letterSpacing: 0.1,
    height: 1.42, // 20px line height
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w500, // Medium
    color: AppColors.textWhite,
    letterSpacing: 0.5,
    height: 1.33, // 16px line height
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    fontWeight: FontWeight.w500, // Medium
    color: AppColors.textMuted,
    letterSpacing: 0.5,
    height: 1.45, // 16px line height
  );

  // For links or text buttons
  static const TextStyle linkStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14, // Or bodyMedium.fontSize
    fontWeight: FontWeight.w600, // Often bold or semi-bold
    color: AppColors.accent,
    letterSpacing: 0.25,
  );
}
