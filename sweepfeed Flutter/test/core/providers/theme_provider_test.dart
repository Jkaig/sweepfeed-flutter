import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sweepfeed_app/core/providers/theme_provider.dart';

// Mock SharedPreferences
class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late ThemeProvider themeProvider;
  late MockSharedPreferences mockSharedPreferences;

  // Key used in ThemeProvider
  const String themePreferenceKey = 'app_theme_mode';

  setUp(() {
    mockSharedPreferences = MockSharedPreferences();
  });

  group('ThemeProvider Unit Tests', () {
    test('initializes with ThemeMode.system if no preference is stored', () {
      // Arrange: No preference stored
      when(mockSharedPreferences.getInt(themePreferenceKey)).thenReturn(null);

      // Act
      themeProvider = ThemeProvider(mockSharedPreferences);

      // Assert
      expect(themeProvider.themeMode, ThemeMode.system);
    });

    test('loads ThemeMode.light from SharedPreferences on initialization', () {
      // Arrange: Store ThemeMode.light.index
      when(mockSharedPreferences.getInt(themePreferenceKey)).thenReturn(ThemeMode.light.index);

      // Act
      themeProvider = ThemeProvider(mockSharedPreferences);

      // Assert
      expect(themeProvider.themeMode, ThemeMode.light);
    });

    test('loads ThemeMode.dark from SharedPreferences on initialization', () {
      // Arrange: Store ThemeMode.dark.index
      when(mockSharedPreferences.getInt(themePreferenceKey)).thenReturn(ThemeMode.dark.index);

      // Act
      themeProvider = ThemeProvider(mockSharedPreferences);

      // Assert
      expect(themeProvider.themeMode, ThemeMode.dark);
    });
    
    test('defaults to ThemeMode.system if stored preference is invalid', () {
      // Arrange: Store an invalid index
      when(mockSharedPreferences.getInt(themePreferenceKey)).thenReturn(99); // Invalid index

      // Act
      themeProvider = ThemeProvider(mockSharedPreferences);

      // Assert
      expect(themeProvider.themeMode, ThemeMode.system);
    });


    test('setThemeMode updates themeMode and saves to SharedPreferences', () async {
      // Arrange: Initialize with system theme
      when(mockSharedPreferences.getInt(themePreferenceKey)).thenReturn(ThemeMode.system.index);
      when(mockSharedPreferences.setInt(themePreferenceKey, ThemeMode.dark.index))
          .thenAnswer((_) async => true); // Mock successful save

      themeProvider = ThemeProvider(mockSharedPreferences);
      
      bool listenerCalled = false;
      themeProvider.addListener(() {
        listenerCalled = true;
      });

      // Act
      await themeProvider.setThemeMode(ThemeMode.dark);

      // Assert
      expect(themeProvider.themeMode, ThemeMode.dark);
      verify(mockSharedPreferences.setInt(themePreferenceKey, ThemeMode.dark.index)).called(1);
      expect(listenerCalled, isTrue);
    });

    test('setThemeMode does not notify listeners or save if mode is unchanged', () async {
      // Arrange: Initialize with dark theme
      when(mockSharedPreferences.getInt(themePreferenceKey)).thenReturn(ThemeMode.dark.index);
      themeProvider = ThemeProvider(mockSharedPreferences);
      
      bool listenerCalled = false;
      themeProvider.addListener(() {
        listenerCalled = true; // This should not be called
      });

      // Act: Try to set the same mode
      await themeProvider.setThemeMode(ThemeMode.dark);

      // Assert
      expect(themeProvider.themeMode, ThemeMode.dark); // Mode remains the same
      verifyNever(mockSharedPreferences.setInt(any, any)); // Should not attempt to save again
      expect(listenerCalled, isFalse); // Listeners should not be notified
    });
    
    test('setThemeMode handles SharedPreferences save failure gracefully', () async {
      // Arrange: Initialize with system theme
      when(mockSharedPreferences.getInt(themePreferenceKey)).thenReturn(ThemeMode.system.index);
      // Mock failed save
      when(mockSharedPreferences.setInt(themePreferenceKey, ThemeMode.light.index))
          .thenThrow(Exception("Failed to save preference")); 

      themeProvider = ThemeProvider(mockSharedPreferences);
      
      bool listenerCalled = false;
      themeProvider.addListener(() {
        listenerCalled = true;
      });

      // Act
      // We don't expect an exception to be thrown from setThemeMode itself, it should handle it.
      await themeProvider.setThemeMode(ThemeMode.light);

      // Assert
      expect(themeProvider.themeMode, ThemeMode.light); // State should still update
      verify(mockSharedPreferences.setInt(themePreferenceKey, ThemeMode.light.index)).called(1);
      expect(listenerCalled, isTrue); // Listener should still be called
      // Error handling would be internal (e.g., debugPrint as in current implementation)
    });
  });
}
