import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Theme configuration for the app
class AppTheme {
  // Removing direct static getters for colors as they are now part of the theme itself.
  // Components should use Theme.of(context) to access theme properties.

  /// Gets the light theme with proper light colors
  static ThemeData lightTheme({
    Color accentColor = AppColors.brandCyan,
    double fontScale = 1.0,
  }) =>
      ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.grey[50], // Light background
        primaryColor: accentColor, // Keep cyan accent
        // primaryColorDark, primaryColorLight are less used with ColorScheme
        colorScheme: ColorScheme.light(
          primary: accentColor, // Keep cyan accent
          onPrimary: Colors.black, // Text on accent buttons
          secondary: AppColors.electricBlue, // Keep electric blue
          onSurface: Colors.grey[900]!, // Dark text on light surfaces
          error: AppColors.errorRed,
        ),
        textTheme: TextTheme(
          displayLarge: AppTextStyles.displayLarge.copyWith(
            color: Colors.grey[900],
            fontSize: AppTextStyles.displayLarge.fontSize! * fontScale,
          ),
          displayMedium: AppTextStyles.displayMedium.copyWith(
            color: Colors.grey[900],
            fontSize: AppTextStyles.displayMedium.fontSize! * fontScale,
          ),
          displaySmall: AppTextStyles.displaySmall.copyWith(
            color: Colors.grey[900],
            fontSize: AppTextStyles.displaySmall.fontSize! * fontScale,
          ),
          headlineLarge: AppTextStyles.headlineLarge.copyWith(
            color: Colors.grey[900],
            fontSize: AppTextStyles.headlineLarge.fontSize! * fontScale,
          ),
          headlineMedium: AppTextStyles.headlineMedium.copyWith(
            color: Colors.grey[900],
            fontSize: AppTextStyles.headlineMedium.fontSize! * fontScale,
          ),
          headlineSmall: AppTextStyles.headlineSmall.copyWith(
            color: Colors.grey[900],
            fontSize: AppTextStyles.headlineSmall.fontSize! * fontScale,
          ),
          titleLarge: AppTextStyles.titleLarge.copyWith(
            color: Colors.grey[900],
            fontSize: AppTextStyles.titleLarge.fontSize! * fontScale,
          ),
          titleMedium: AppTextStyles.titleMedium.copyWith(
            color: Colors.grey[900],
            fontSize: AppTextStyles.titleMedium.fontSize! * fontScale,
          ),
          titleSmall: AppTextStyles.titleSmall.copyWith(
            color: Colors.grey[900],
            fontSize: AppTextStyles.titleSmall.fontSize! * fontScale,
          ),
          bodyLarge: AppTextStyles.bodyLarge.copyWith(
            color: Colors.grey[800],
            fontSize: AppTextStyles.bodyLarge.fontSize! * fontScale,
          ),
          bodyMedium: AppTextStyles.bodyMedium.copyWith(
            color: Colors.grey[700],
            fontSize: AppTextStyles.bodyMedium.fontSize! * fontScale,
          ),
          bodySmall: AppTextStyles.bodySmall.copyWith(
            color: Colors.grey[600],
            fontSize: AppTextStyles.bodySmall.fontSize! * fontScale,
          ),
          labelLarge: AppTextStyles.labelLarge.copyWith(
            color: Colors.black, // For buttons
            fontSize: AppTextStyles.labelLarge.fontSize! * fontScale,
          ),
          labelMedium: AppTextStyles.labelMedium.copyWith(
            color: Colors.grey[700],
            fontSize: AppTextStyles.labelMedium.fontSize! * fontScale,
          ),
          labelSmall: AppTextStyles.labelSmall.copyWith(
            color: Colors.grey[600],
            fontSize: AppTextStyles.labelSmall.fontSize! * fontScale,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor, // Keep cyan accent
            foregroundColor: Colors.black, // Black text on cyan
            textStyle: AppTextStyles.labelLarge,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: accentColor, // cyan accent
            side: BorderSide(color: accentColor), // cyan accent
            textStyle: AppTextStyles.labelLarge.copyWith(color: accentColor),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: accentColor, // cyan accent
            textStyle: AppTextStyles.labelLarge.copyWith(color: accentColor),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white, // White cards
          elevation: 1, // Slight elevation
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[300]!), // Light border
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.ltDivider, // primaryLight
          thickness: 1,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white, // White background
          selectedItemColor: accentColor, // cyan accent
          unselectedItemColor: Colors.grey[600], // grey for unselected
          selectedLabelStyle:
              AppTextStyles.labelSmall.copyWith(color: accentColor),
          unselectedLabelStyle:
              AppTextStyles.labelSmall.copyWith(color: Colors.grey[600]),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white, // White app bar
          elevation: 0,
          foregroundColor: Colors.grey[900], // Dark text/icons
          titleTextStyle:
              AppTextStyles.titleLarge.copyWith(color: Colors.grey[900]),
          iconTheme: IconThemeData(color: Colors.grey[900]),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100], // Light grey fill
          labelStyle:
              AppTextStyles.bodyMedium.copyWith(color: Colors.grey[700]),
          hintStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[500]),
          prefixIconColor: Colors.grey[600], // grey icons
          suffixIconColor: Colors.grey[600], // grey icons
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                BorderSide(color: Colors.grey[400]!), // light grey border
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                BorderSide(color: Colors.grey[400]!), // light grey border
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: accentColor,
              width: 2,
            ), // cyan accent
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
        iconTheme: IconThemeData(color: Colors.grey[700]), // grey icons
        primaryIconTheme: IconThemeData(color: accentColor), // cyan accent
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return accentColor; // cyan accent
            }
            return Colors.grey[300]; // light grey for unchecked
          }),
          checkColor:
              WidgetStateProperty.all(Colors.black), // Black check mark on cyan
          side: BorderSide(color: Colors.grey[400]!), // light grey border
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      );

  /// Gets the dark theme (Primary theme for the app)
  static ThemeData darkTheme({
    Color accentColor = AppColors.brandCyan,
    double fontScale = 1.0,
  }) =>
      ThemeData(
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
          elevation: 0, // Flatter design consistent with the new UI
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(
              color: AppColors.primaryLight,
              width: 0.5,
            ), // Subtle border
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
            color: AppColors.textLight), // Default icon color
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
