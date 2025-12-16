import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Theme configuration for the app
class AppTheme {
  // Removing direct static getters for colors as they are now part of the theme itself.
  // Components should use Theme.of(context) to access theme properties.

  /// Gets the light theme with proper light colors
  /// Gets the light theme (Now mapped to Dark Theme for consistent branding)
  /// The app uses a "Dark/Cyber" aesthetic exclusively. "Light Mode" settings
  /// on the device should still yield the dark app experience to prevent
  /// white-on-white text issues (since most widgets hardcode white text).
  static ThemeData lightTheme({
    Color accentColor = AppColors.brandCyan,
    double fontScale = 1.0,
  }) =>
      ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark, // Force dark brightness even in "light" theme
        scaffoldBackgroundColor: AppColors.primaryDark, // Dark background
        primaryColor: accentColor,
        colorScheme: ColorScheme.dark( // Use dark color scheme
          primary: accentColor,
          onPrimary: AppColors.primaryDark,
          secondary: AppColors.electricBlue,
          onSecondary: AppColors.primaryDark,
          surface: AppColors.primaryMedium,
          onSurface: AppColors.textWhite,
          error: AppColors.errorRed,
          onError: AppColors.textWhite,
          surfaceTint: AppColors.mangoTangoStart,
        ),
        textTheme: TextTheme(
          displayLarge: AppTextStyles.displayLarge.copyWith(
            color: AppColors.textWhite,
            fontSize: AppTextStyles.displayLarge.fontSize! * fontScale,
          ),
          displayMedium: AppTextStyles.displayMedium.copyWith(
            color: AppColors.textWhite,
            fontSize: AppTextStyles.displayMedium.fontSize! * fontScale,
          ),
          displaySmall: AppTextStyles.displaySmall.copyWith(
            color: AppColors.textWhite,
            fontSize: AppTextStyles.displaySmall.fontSize! * fontScale,
          ),
          headlineLarge: AppTextStyles.headlineLarge.copyWith(
            color: AppColors.textWhite,
            fontSize: AppTextStyles.headlineLarge.fontSize! * fontScale,
          ),
          headlineMedium: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.textWhite,
            fontSize: AppTextStyles.headlineMedium.fontSize! * fontScale,
          ),
          headlineSmall: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.textWhite,
            fontSize: AppTextStyles.headlineSmall.fontSize! * fontScale,
          ),
          titleLarge: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textWhite,
            fontSize: AppTextStyles.titleLarge.fontSize! * fontScale,
          ),
          titleMedium: AppTextStyles.titleMedium.copyWith(
            color: AppColors.textWhite,
            fontSize: AppTextStyles.titleMedium.fontSize! * fontScale,
          ),
          titleSmall: AppTextStyles.titleSmall.copyWith(
            color: AppColors.textWhite,
            fontSize: AppTextStyles.titleSmall.fontSize! * fontScale,
          ),
          bodyLarge: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textWhite,
            fontSize: AppTextStyles.bodyLarge.fontSize! * fontScale,
          ),
          bodyMedium: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textLight,
            fontSize: AppTextStyles.bodyMedium.fontSize! * fontScale,
          ),
          bodySmall: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textMuted,
            fontSize: AppTextStyles.bodySmall.fontSize! * fontScale,
          ),
          labelLarge: AppTextStyles.labelLarge.copyWith(
            color: AppColors.textWhite,
            fontSize: AppTextStyles.labelLarge.fontSize! * fontScale,
          ),
          labelMedium: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textLight,
            fontSize: AppTextStyles.labelMedium.fontSize! * fontScale,
          ),
          labelSmall: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textMuted,
            fontSize: AppTextStyles.labelSmall.fontSize! * fontScale,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(Colors.transparent),
            foregroundColor: WidgetStateProperty.all(AppColors.textWhite),
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return accentColor.withValues(alpha: 0.2);
              }
              return null;
            }),
            elevation: WidgetStateProperty.all(0),
            textStyle: WidgetStateProperty.all(
              AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w800),
            ),
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: accentColor,
            side: BorderSide(color: accentColor, width: 2),
            textStyle: AppTextStyles.labelLarge.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w700,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: accentColor,
            textStyle: AppTextStyles.labelLarge
                .copyWith(fontWeight: FontWeight.w700),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.primaryMedium,
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(
              color: AppColors.primaryLight,
            ),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.primaryMedium,
          disabledColor: AppColors.primaryLight,
          selectedColor: accentColor,
          secondarySelectedColor: accentColor,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          labelStyle: AppTextStyles.labelMedium.copyWith(color: AppColors.textLight),
          secondaryLabelStyle: AppTextStyles.labelMedium.copyWith(color: AppColors.primaryDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.primaryLight),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.primaryLight,
          thickness: 0.5,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.primaryMedium,
          selectedItemColor: accentColor,
          unselectedItemColor: AppColors.textLight,
          selectedLabelStyle:
              AppTextStyles.labelSmall.copyWith(color: accentColor),
          unselectedLabelStyle:
              AppTextStyles.labelSmall.copyWith(color: AppColors.textLight),
          type: BottomNavigationBarType.fixed,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primaryDark,
          elevation: 0,
          foregroundColor: AppColors.textWhite,
          titleTextStyle: AppTextStyles.titleLarge,
          iconTheme: IconThemeData(color: AppColors.textWhite),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.primaryMedium,
          labelStyle:
              AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
          hintStyle:
              AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
          prefixIconColor: AppColors.textLight,
          suffixIconColor: AppColors.textLight,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
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
            borderSide: BorderSide(color: accentColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.errorRed),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.errorRed, width: 2),
          ),
          errorStyle:
              AppTextStyles.bodySmall.copyWith(color: AppColors.errorRed),
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textLight,
        ),
        primaryIconTheme: IconThemeData(
          color: accentColor,
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return accentColor;
            }
            return AppColors.primaryMedium;
          }),
          checkColor: WidgetStateProperty.all(
            AppColors.primaryDark,
          ),
          side: const BorderSide(color: AppColors.primaryLight),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      );

  /// Gets the dark theme (Primary theme for the app)
  static ThemeData darkTheme({
    Color accentColor = AppColors.brandCyan,
    double fontScale = 1.0,
  }) =>
      ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.primaryDark,
        primaryColor: accentColor,
        // primaryColorDark, primaryColorLight are less critical with ColorScheme
        colorScheme: ColorScheme.dark(
          primary: accentColor,
          onPrimary: AppColors.primaryDark, // Text on accent buttons
          secondary: AppColors.electricBlue, // Electric blue for secondary
          onSecondary: AppColors.primaryDark,
          surface: AppColors.primaryMedium, // Cards, dialogs, sheets
          onSurface: AppColors.textWhite,
          error: AppColors.errorRed,
          onError: AppColors.textWhite, // Text on error color
          surfaceTint: AppColors.mangoTangoStart, // For elevated surfaces
        ),
        textTheme: TextTheme(
          displayLarge: AppTextStyles.displayLarge.copyWith(
            fontSize: AppTextStyles.displayLarge.fontSize! * fontScale,
          ),
          displayMedium: AppTextStyles.displayMedium.copyWith(
            fontSize: AppTextStyles.displayMedium.fontSize! * fontScale,
          ),
          displaySmall: AppTextStyles.displaySmall.copyWith(
            fontSize: AppTextStyles.displaySmall.fontSize! * fontScale,
          ),
          headlineLarge: AppTextStyles.headlineLarge.copyWith(
            fontSize: AppTextStyles.headlineLarge.fontSize! * fontScale,
          ),
          headlineMedium: AppTextStyles.headlineMedium.copyWith(
            fontSize: AppTextStyles.headlineMedium.fontSize! * fontScale,
          ),
          headlineSmall: AppTextStyles.headlineSmall.copyWith(
            fontSize: AppTextStyles.headlineSmall.fontSize! * fontScale,
          ),
          titleLarge: AppTextStyles.titleLarge.copyWith(
            fontSize: AppTextStyles.titleLarge.fontSize! * fontScale,
          ),
          titleMedium: AppTextStyles.titleMedium.copyWith(
            fontSize: AppTextStyles.titleMedium.fontSize! * fontScale,
          ),
          titleSmall: AppTextStyles.titleSmall.copyWith(
            fontSize: AppTextStyles.titleSmall.fontSize! * fontScale,
          ),
          bodyLarge: AppTextStyles.bodyLarge.copyWith(
            fontSize: AppTextStyles.bodyLarge.fontSize! * fontScale,
          ),
          bodyMedium: AppTextStyles.bodyMedium.copyWith(
            fontSize: AppTextStyles.bodyMedium.fontSize! * fontScale,
          ),
          bodySmall: AppTextStyles.bodySmall.copyWith(
            fontSize: AppTextStyles.bodySmall.fontSize! * fontScale,
          ),
          labelLarge: AppTextStyles.labelLarge.copyWith(
            // Used for button text
            fontSize: AppTextStyles.labelLarge.fontSize! * fontScale,
          ),
          labelMedium: AppTextStyles.labelMedium.copyWith(
            fontSize: AppTextStyles.labelMedium.fontSize! * fontScale,
          ),
          labelSmall: AppTextStyles.labelSmall.copyWith(
            fontSize: AppTextStyles.labelSmall.fontSize! * fontScale,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(Colors.transparent),
            foregroundColor: WidgetStateProperty.all(AppColors.textWhite),
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return accentColor.withValues(alpha: 0.2);
              }
              return null;
            }),
            elevation: WidgetStateProperty.all(0),
            textStyle: WidgetStateProperty.all(
              AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w800),
            ),
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: accentColor,
            side: BorderSide(color: accentColor, width: 2),
            textStyle: AppTextStyles.labelLarge.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w700,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: accentColor,
            textStyle: AppTextStyles.labelLarge
                .copyWith(fontWeight: FontWeight.w700), // Bold link-like
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.primaryMedium,
          elevation: 0, 
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // More rounded
            side: const BorderSide(
              color: AppColors.primaryLight,
            ),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.primaryMedium,
          disabledColor: AppColors.primaryLight,
          selectedColor: accentColor,
          secondarySelectedColor: accentColor,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          labelStyle: AppTextStyles.labelMedium.copyWith(color: AppColors.textLight),
          secondaryLabelStyle: AppTextStyles.labelMedium.copyWith(color: AppColors.primaryDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.primaryLight),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.primaryLight,
          thickness: 0.5, // Thinner divider
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor:
              AppColors.primaryMedium, // Slightly lighter than main background
          selectedItemColor: accentColor,
          unselectedItemColor: AppColors.textLight,
          selectedLabelStyle:
              AppTextStyles.labelSmall.copyWith(color: accentColor),
          unselectedLabelStyle:
              AppTextStyles.labelSmall.copyWith(color: AppColors.textLight),
          type:
              BottomNavigationBarType.fixed, // Ensure labels are always visible
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor:
              AppColors.primaryDark, // Consistent with scaffold background
          elevation: 0, // No shadow for a flatter look
          foregroundColor: AppColors.textWhite, // For icons and text
          titleTextStyle: AppTextStyles.titleLarge, // Default title style
          iconTheme: IconThemeData(color: AppColors.textWhite),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.primaryMedium,
          labelStyle:
              AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
          hintStyle:
              AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
          prefixIconColor: AppColors.textLight,
          suffixIconColor: AppColors.textLight,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ), // Standard padding
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
            borderSide: BorderSide(color: accentColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.errorRed),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.errorRed, width: 2),
          ),
          errorStyle:
              AppTextStyles.bodySmall.copyWith(color: AppColors.errorRed),
        ),
        iconTheme: const IconThemeData(
            color: AppColors.textLight,), // Default icon color
        primaryIconTheme: IconThemeData(
          color: accentColor,
        ), // Icons on accent color elements
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return accentColor;
            }
            return AppColors.primaryMedium; // Or textMuted for the box fill
          }),
          checkColor: WidgetStateProperty.all(
            AppColors.primaryDark,
          ), // Check mark color on accent
          side: const BorderSide(color: AppColors.primaryLight),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      );
}
