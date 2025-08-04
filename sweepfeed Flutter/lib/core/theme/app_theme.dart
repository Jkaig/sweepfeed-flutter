import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Theme configuration for the app
class AppTheme {
  // Removing direct static getters for colors as they are now part of the theme itself.
  // Components should use Theme.of(context) to access theme properties.

  /// Gets the light theme (Conceptual - app is primarily dark)
  /// This light theme is a basic setup and might need further refinement
  /// if a full light mode is to be supported.
  static ThemeData lightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.ltBackground, // Mapped to primaryDark (0xFF0A192F)
      primaryColor: AppColors.ltPrimary, // Mapped to accent (0xFF64FFDA)
      // primaryColorDark, primaryColorLight are less used with ColorScheme
      colorScheme: const ColorScheme.light(
        primary: AppColors.ltPrimary, // accent
        onPrimary: AppColors.primaryDark, // Text on accent buttons (e.g. primaryDark)
        secondary: AppColors.ltSecondary, // primaryLight
        onSecondary: AppColors.textWhite, // Text on secondary elements
        surface: AppColors.ltSurface, // primaryMedium
        onSurface: AppColors.textWhite, 
        background: AppColors.ltBackground, // primaryDark
        onBackground: AppColors.textWhite,
        error: AppColors.errorRed,
        onError: AppColors.textWhite,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge.copyWith(color: AppColors.ltTextPrimary),
        displayMedium: AppTextStyles.displayMedium.copyWith(color: AppColors.ltTextPrimary),
        displaySmall: AppTextStyles.displaySmall.copyWith(color: AppColors.ltTextPrimary),
        headlineLarge: AppTextStyles.headlineLarge.copyWith(color: AppColors.ltTextPrimary),
        headlineMedium: AppTextStyles.headlineMedium.copyWith(color: AppColors.ltTextPrimary),
        headlineSmall: AppTextStyles.headlineSmall.copyWith(color: AppColors.ltTextPrimary),
        titleLarge: AppTextStyles.titleLarge.copyWith(color: AppColors.ltTextPrimary),
        titleMedium: AppTextStyles.titleMedium.copyWith(color: AppColors.ltTextPrimary),
        titleSmall: AppTextStyles.titleSmall.copyWith(color: AppColors.ltTextPrimary),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: AppColors.ltTextPrimary),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: AppColors.ltTextSecondary),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: AppColors.ltTextHint),
        labelLarge: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryDark), // For buttons on accent
        labelMedium: AppTextStyles.labelMedium.copyWith(color: AppColors.ltTextSecondary),
        labelSmall: AppTextStyles.labelSmall.copyWith(color: AppColors.ltTextHint),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ltPrimary, // accent
          foregroundColor: AppColors.primaryDark, // Text on accent buttons
          textStyle: AppTextStyles.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ltPrimary, // accent
          side: const BorderSide(color: AppColors.ltPrimary), // accent
          textStyle: AppTextStyles.labelLarge.copyWith(color: AppColors.ltPrimary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.ltPrimary, // accent
          textStyle: AppTextStyles.labelLarge.copyWith(color: AppColors.ltPrimary),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Adjusted padding
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.ltCard, // primaryMedium
        elevation: 0, // Flatter design
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.ltBorder), // primaryLight
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.ltDivider, // primaryLight
        thickness: 1,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.ltSurface, // primaryMedium
        selectedItemColor: AppColors.ltPrimary, // accent
        unselectedItemColor: AppColors.ltTextSecondary, // textLight
        selectedLabelStyle: AppTextStyles.labelSmall.copyWith(color: AppColors.ltPrimary),
        unselectedLabelStyle: AppTextStyles.labelSmall.copyWith(color: AppColors.ltTextSecondary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.ltBackground, // primaryDark
        elevation: 0,
        foregroundColor: AppColors.ltTextPrimary, // textWhite
        titleTextStyle: AppTextStyles.titleLarge.copyWith(color: AppColors.ltTextPrimary),
        iconTheme: const IconThemeData(color: AppColors.ltTextPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.ltSurface, // primaryMedium
        labelStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.ltTextSecondary), // textLight
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.ltTextHint), // textMuted
        prefixIconColor: AppColors.ltTextSecondary, // textLight
        suffixIconColor: AppColors.ltTextSecondary, // textLight
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.ltBorder), // primaryLight
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.ltBorder), // primaryLight
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.ltPrimary, width: 2), // accent
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.errorRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.errorRed, width: 2),
        ),
        errorStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.errorRed),
      ),
      iconTheme: IconThemeData(color: AppColors.ltTextSecondary), // textLight
      primaryIconTheme: IconThemeData(color: AppColors.ltPrimary), // accent
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.ltPrimary; // accent
          }
          return AppColors.ltSurface; // primaryMedium or textMuted for unchecked box fill
        }),
        checkColor: MaterialStateProperty.all(AppColors.primaryDark), // Check mark color on accent
        side: BorderSide(color: AppColors.ltBorder), // primaryLight
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }

  /// Gets the dark theme (Primary theme for the app)
  static ThemeData darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.primaryDark,
      primaryColor: AppColors.accent, 
      // primaryColorDark, primaryColorLight are less critical with ColorScheme
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        onPrimary: AppColors.primaryDark, // Text on accent buttons
        secondary: AppColors.primaryLight, // A lighter navy for secondary elements
        onSecondary: AppColors.textWhite,
        surface: AppColors.primaryMedium, // Cards, dialogs, sheets
        onSurface: AppColors.textWhite,
        background: AppColors.primaryDark, // Main background
        onBackground: AppColors.textWhite,
        error: AppColors.errorRed,
        onError: AppColors.textWhite, // Text on error color
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        displaySmall: AppTextStyles.displaySmall,
        headlineLarge: AppTextStyles.headlineLarge,
        headlineMedium: AppTextStyles.headlineMedium,
        headlineSmall: AppTextStyles.headlineSmall,
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        titleSmall: AppTextStyles.titleSmall,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge, // Used for button text
        labelMedium: AppTextStyles.labelMedium,
        labelSmall: AppTextStyles.labelSmall,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.primaryDark, // Text color for primary buttons
          textStyle: AppTextStyles.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: const BorderSide(color: AppColors.accent),
          textStyle: AppTextStyles.labelLarge.copyWith(color: AppColors.accent),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600), // Link-like
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.primaryMedium,
        elevation: 0, // Flatter design consistent with the new UI
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.primaryLight, width: 0.5), // Subtle border
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.primaryLight,
        thickness: 0.5, // Thinner divider
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.primaryMedium, // Slightly lighter than main background
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textLight,
        selectedLabelStyle: AppTextStyles.labelSmall.copyWith(color: AppColors.accent),
        unselectedLabelStyle: AppTextStyles.labelSmall.copyWith(color: AppColors.textLight),
        type: BottomNavigationBarType.fixed, // Ensure labels are always visible
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryDark, // Consistent with scaffold background
        elevation: 0, // No shadow for a flatter look
        foregroundColor: AppColors.textWhite, // For icons and text
        titleTextStyle: AppTextStyles.titleLarge, // Default title style
        iconTheme: const IconThemeData(color: AppColors.textWhite),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.primaryMedium,
        labelStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
        prefixIconColor: AppColors.textLight,
        suffixIconColor: AppColors.textLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Standard padding
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primaryLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primaryLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.errorRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.errorRed, width: 2),
        ),
        errorStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.errorRed),
      ),
      iconTheme: const IconThemeData(color: AppColors.textLight), // Default icon color
      primaryIconTheme: const IconThemeData(color: AppColors.accent), // Icons on accent color elements
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.accent;
          }
          return AppColors.primaryMedium; // Or textMuted for the box fill
        }),
        checkColor: MaterialStateProperty.all(AppColors.primaryDark), // Check mark color on accent
        side: const BorderSide(color: AppColors.primaryLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }
}
