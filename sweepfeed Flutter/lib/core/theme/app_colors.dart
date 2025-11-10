import 'package:flutter/material.dart';

// App color scheme - Unified for the new dark theme focus
class AppColors {
  // --- Website Color Palette from Next.js ---
  static const primaryDark =
      Color(0xFF0A192F); // #0a192f - Deep navy from website
  static const primaryMedium =
      Color(0xFF112240); // #112240 - Navy blue for cards/surfaces
  static const primaryLight =
      Color(0xFF1F3A60); // #1f3a60 - Light navy for borders

  // Primary Brand Color - The signature cyan from website
  static const brandCyan =
      Color(0xFF64FFDA); // Website accent - main brand color
  static const brandCyanDark = Color(0xFF4DCFB5); // Darker shade for gradients

  // Action Colors - Distinct from brand cyan
  static const mangoTangoStart = Color(0xFFFF8A00); // True orange for energy
  static const mangoTangoEnd = Color(0xFFFF6B00); // Darker orange
  static const electricBlue = Color(0xFF007AFF); // True blue for variety

  // Legacy accent mapping (keep for backward compatibility)
  static const cyberYellow = brandCyan; // Deprecated - use brandCyan instead

  // Accent colors
  static const accent = brandCyan; // Primary brand color
  static const accentGlow = Color(0xFF8AFFE6); // Lighter cyan for glow effects

  static const textWhite = Color(0xFFE6F1FF); // #e6f1ff - Website text color
  static const textLight =
      Color(0xFF8892B0); // #8892b0 - Website secondary text
  static const textSecondary = Color(0xFF8892B0); // Alias for textLight
  static const textMuted = Color(0xFF495670); // Darker muted text

  // --- Status Colors ---
  static const successGreen = Color(0xFF30D158); // iOS-style green
  static const neonGreen = Color(0xFF32D74B); // Bright success green
  static const warningOrange = Color(0xFFFF9500); // Bright orange for warnings
  static const errorRed = Color(0xFFFF3B30); // Vibrant red for errors

  // --- Gradients ---
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [brandCyan, brandCyanDark], // Brand cyan gradient matching website
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glowGradient = LinearGradient(
    colors: [brandCyan, brandCyanDark], // Cyan glow matching website
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [primaryDark, Color(0xFF000000)], // Deep space gradient
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // --- Mapping existing theme colors to the new palette ---
  // These act as aliases or direct mappings to ensure components
  // that used the old names still work or can be easily updated.

  // Light Theme (Conceptual mapping - actual light theme might need distinct light palette if re-introduced)
  // For now, assuming the app is primarily dark themed as per new design.
  // If a true light theme is needed, these would be different.
  static const ltPrimary = accent; // Was 0xFF007AFF
  static const ltPrimaryLight = accentGlow; // Was 0xFF58AFFF
  static const ltPrimaryDark = accent; // Was 0xFF0056B3

  static const ltSecondary = primaryLight; // Was 0xFFF2F2F7
  static const ltSecondaryLight = primaryMedium; // Was 0xFFFFFFFF
  static const ltSecondaryDark = primaryDark; // Was 0xFFE5E5EA

  static const ltAccent = accent; // Was 0xFF34C759

  static const ltBackground = primaryDark; // Was 0xFFFFFFFF
  static const ltSurface = primaryMedium; // Was 0xFFF2F2F7
  static const ltCard = primaryMedium; // Was 0xFFFFFFFF

  static const ltTextPrimary = textWhite; // Was 0xFF000000
  static const ltTextSecondary = textLight; // Was 0xFF3C3C43
  static const ltTextHint = textMuted; // Was 0xFF3C3C43

  static const ltBorder = primaryLight; // Was 0xFFD1D1D6
  static const ltDivider = primaryLight; // Was 0xFFE5E5EA

  // Dark Theme (Direct mapping to new core palette)
  static const dtPrimary = accent; // Was 0xFF0A84FF
  static const dtPrimaryLight = accentGlow; // Was 0xFF64D2FF
  static const dtPrimaryDark =
      accent; // Was 0xFF0060DB (Using accent as primary interaction color)

  static const dtSecondary = primaryMedium; // Was 0xFF1C1C1E
  static const dtSecondaryLight = primaryLight; // Was 0xFF2C2C2E
  static const dtSecondaryDark = primaryDark; // Was 0xFF000000

  static const dtAccent = accent; // Was 0xFF30D158

  static const dtBackground = primaryDark; // Was 0xFF000000
  static const dtSurface = primaryMedium; // Was 0xFF1C1C1E
  static const dtCard = primaryMedium; // Was 0xFF1C1C1E

  static const dtTextPrimary = textWhite; // Was 0xFFFFFFFF
  static const dtTextSecondary = textLight; // Was 0xFFEBEBF5
  static const dtTextHint = textMuted; // Was 0xFFEBEBF5

  static const dtBorder = primaryLight; // Was 0xFF38383A
  static const dtDivider = primaryLight; // Was 0xFF2C2C2E

  // Common Status Colors (using new definitions)
  static const success = successGreen;
  static const error = errorRed;
  static const warning = warningOrange;
  static const info = accent; // Using accent for info, was ltPrimary

  // --- Legacy Aliases (mapped to new palette) ---
  // These help bridge old code. Gradually refactor direct use of these.
  static const primary =
      accent; // Was 0xFF64FFDA (Tealish) -> Now maps to new accent
  // primaryLight, primaryDark from legacy are now conceptually covered by the new primaryDark, Medium, Light set

  static const secondary =
      primaryMedium; // Was 0xFF112240 (Dark Blue) -> Mapped to new primaryMedium
  // secondaryLight, secondaryDark from legacy are now conceptually covered by new primaryDark, Medium, Light set

  // 'accent' is already defined in the new palette.

  static const background =
      primaryDark; // Was 0xFF030D19 -> Mapped to new primaryDark
  static const backgroundDark = primaryDark; // Alias for clarity
  static const backgroundLight =
      primaryMedium; // Conceptual mapping for a lighter background variant

  static const surface =
      primaryMedium; // Was 0xFF112240 -> Mapped to new primaryMedium
  static const card =
      primaryMedium; // Was 0xFF112240 -> Mapped to new primaryMedium

  static const textPrimary =
      textWhite; // Was 0xFFE6F1FF -> Mapped to new textWhite
  static const textSecondaryOld =
      textLight; // Was 0xFF8892B0 -> Mapped to new textLight (renamed to avoid clash)
  static const textHintOld =
      textMuted; // Was 0xFF8892B0 -> Mapped to new textMuted (renamed to avoid clash)

  static const border =
      primaryLight; // Was 0xFF334155 -> Mapped to new primaryLight
  static const divider =
      primaryLight; // Was 0xFF1F3A60 -> Mapped to new primaryLight

  // Removing fully redundant or superseded old definitions if their names don't conflict
  // For example, 'backgroundLightOld', 'surfaceLightOld' etc. are removed as their concepts
  // are covered by the new primaryDark/Medium/Light and their direct aliases.
}
