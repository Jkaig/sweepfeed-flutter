import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sweepfeed_app/core/models/user_profile.dart';
import 'package:sweepfeed_app/features/profile/screens/profile_settings_screen.dart';
import 'package:sweepfeed_app/features/profile/services/profile_service.dart';
import 'package:sweepfeed_app/core/providers/theme_provider.dart';

// Mocks
class MockProfileService extends Mock implements ProfileService {}
class MockUser extends Mock implements fb_auth.User {}

// Mock FirebaseAuth for testing purposes
class MockFirebaseAuth extends Mock implements fb_auth.FirebaseAuth {
  @override
  final fb_auth.User? currentUser;
  MockFirebaseAuth({this.currentUser});
}


Widget createProfileSettingsScreenWithThemeTestWidget({
  required MockProfileService mockProfileService,
  required fb_auth.User? mockCurrentUser, // Allow null for testing no-user scenario
  required ThemeProvider themeProvider,
}) {
   // If ProfileSettingsScreen uses FirebaseAuth.instance directly, this mock needs to be effective.
   // For robust testing, ProfileSettingsScreen should ideally get User via Provider or DI.
   // We assume here that the screen's FirebaseAuth.instance.currentUser will reflect mockCurrentUser.
   // This is hard to guarantee without more complex test setup or refactoring the screen.

  return MultiProvider(
    providers: [
      Provider<ProfileService>.value(value: mockProfileService),
      // If ProfileSettingsScreen uses Provider.of<User>(context), provide mockCurrentUser here.
      // Provider<fb_auth.User?>.value(value: mockCurrentUser), 
      ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
    ],
    child: MaterialApp(
      home: ProfileSettingsScreen(),
      // Need to wrap with MaterialApp to provide context for Theme, Directionality, etc.
      theme: ThemeData.light(), // Provide a basic theme for testing
      darkTheme: ThemeData.dark(),
      themeMode: themeProvider.themeMode, // Initial themeMode
    ),
  );
}

void main() {
  late MockProfileService mockProfileService;
  late MockUser mockUser;
  late ThemeProvider themeProvider;
  late SharedPreferences sharedPreferences;

  setUp(() async {
    // Initialize SharedPreferences with mock values for testing
    SharedPreferences.setMockInitialValues({}); // Clear any existing mock values
    sharedPreferences = await SharedPreferences.getInstance();
    
    mockProfileService = MockProfileService();
    mockUser = MockUser();
    themeProvider = ThemeProvider(sharedPreferences); // Real ThemeProvider with mock SharedPreferences

    // Setup mock user details
    when(mockUser.uid).thenReturn('testUserIdForTheme');

    // Mock getUserProfile to prevent errors during widget build, as it's called in initState/didChangeDependencies
    when(mockProfileService.getUserProfile(any)).thenAnswer((_) async => 
      UserProfile(
        id: 'testUserIdForTheme', 
        bio: 'Test bio for theme settings',
        // other fields as needed
      )
    );
  });

  group('ProfileSettingsScreen Dark Mode UI Tests', () {
    testWidgets('RadioListTiles reflect initial themeMode from ThemeProvider', (WidgetTester tester) async {
      // Arrange: Set initial theme to dark in ThemeProvider
      await themeProvider.setThemeMode(ThemeMode.dark);
      
      await tester.pumpWidget(createProfileSettingsScreenWithThemeTestWidget(
        mockProfileService: mockProfileService,
        mockCurrentUser: mockUser, // Provide mockUser
        themeProvider: themeProvider,
      ));
      await tester.pumpAndSettle(); // Wait for ProfileSettingsScreen's futures to resolve

      // Assert
      final darkRadioTile = tester.widget<RadioListTile<ThemeMode>>(find.widgetWithText(RadioListTile<ThemeMode>, 'Dark Mode'));
      expect(darkRadioTile.groupValue, ThemeMode.dark);
      expect(darkRadioTile.value, ThemeMode.dark);
      expect(darkRadioTile.checked, isTrue);

      final lightRadioTile = tester.widget<RadioListTile<ThemeMode>>(find.widgetWithText(RadioListTile<ThemeMode>, 'Light Mode'));
      expect(lightRadioTile.checked, isFalse);

      final systemRadioTile = tester.widget<RadioListTile<ThemeMode>>(find.widgetWithText(RadioListTile<ThemeMode>, 'System Default'));
      expect(systemRadioTile.checked, isFalse);
    });

    testWidgets('tapping "Light Mode" RadioListTile updates ThemeProvider and UI', (WidgetTester tester) async {
      // Arrange: Start with a different theme (e.g., system or dark)
      await themeProvider.setThemeMode(ThemeMode.dark);

      await tester.pumpWidget(createProfileSettingsScreenWithThemeTestWidget(
        mockProfileService: mockProfileService,
        mockCurrentUser: mockUser,
        themeProvider: themeProvider,
      ));
      await tester.pumpAndSettle();

      // Act: Tap the "Light Mode" radio tile
      await tester.tap(find.widgetWithText(RadioListTile<ThemeMode>, 'Light Mode'));
      await tester.pumpAndSettle(); // Allow UI to rebuild

      // Assert: ThemeProvider's state updated
      expect(themeProvider.themeMode, ThemeMode.light);
      
      // Assert: UI updated - Light Mode radio is checked
      final lightRadioTile = tester.widget<RadioListTile<ThemeMode>>(find.widgetWithText(RadioListTile<ThemeMode>, 'Light Mode'));
      expect(lightRadioTile.checked, isTrue);
      expect(lightRadioTile.groupValue, ThemeMode.light);

      final darkRadioTile = tester.widget<RadioListTile<ThemeMode>>(find.widgetWithText(RadioListTile<ThemeMode>, 'Dark Mode'));
      expect(darkRadioTile.checked, isFalse);
    });

    testWidgets('tapping "Dark Mode" RadioListTile updates ThemeProvider and UI', (WidgetTester tester) async {
      await themeProvider.setThemeMode(ThemeMode.light); // Start with light

      await tester.pumpWidget(createProfileSettingsScreenWithThemeTestWidget(
        mockProfileService: mockProfileService,
        mockCurrentUser: mockUser,
        themeProvider: themeProvider,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(RadioListTile<ThemeMode>, 'Dark Mode'));
      await tester.pumpAndSettle();

      expect(themeProvider.themeMode, ThemeMode.dark);
      final darkRadioTile = tester.widget<RadioListTile<ThemeMode>>(find.widgetWithText(RadioListTile<ThemeMode>, 'Dark Mode'));
      expect(darkRadioTile.checked, isTrue);
    });

    testWidgets('tapping "System Default" RadioListTile updates ThemeProvider and UI', (WidgetTester tester) async {
      await themeProvider.setThemeMode(ThemeMode.light); // Start with light

      await tester.pumpWidget(createProfileSettingsScreenWithThemeTestWidget(
        mockProfileService: mockProfileService,
        mockCurrentUser: mockUser,
        themeProvider: themeProvider,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(RadioListTile<ThemeMode>, 'System Default'));
      await tester.pumpAndSettle();

      expect(themeProvider.themeMode, ThemeMode.system);
      final systemRadioTile = tester.widget<RadioListTile<ThemeMode>>(find.widgetWithText(RadioListTile<ThemeMode>, 'System Default'));
      expect(systemRadioTile.checked, isTrue);
    });
    
    testWidgets('theme selection persists in SharedPreferences', (WidgetTester tester) async {
      await themeProvider.setThemeMode(ThemeMode.system); // Initial state

      await tester.pumpWidget(createProfileSettingsScreenWithThemeTestWidget(
        mockProfileService: mockProfileService,
        mockCurrentUser: mockUser,
        themeProvider: themeProvider,
      ));
      await tester.pumpAndSettle();

      // Act: Tap the "Dark Mode" radio tile
      await tester.tap(find.widgetWithText(RadioListTile<ThemeMode>, 'Dark Mode'));
      await tester.pumpAndSettle();

      // Assert: Check SharedPreferences
      // The ThemeProvider saves the index.
      expect(sharedPreferences.getInt('app_theme_mode'), ThemeMode.dark.index);

      // Act: Tap the "Light Mode" radio tile
      await tester.tap(find.widgetWithText(RadioListTile<ThemeMode>, 'Light Mode'));
      await tester.pumpAndSettle();
      
      expect(sharedPreferences.getInt('app_theme_mode'), ThemeMode.light.index);
    });
  });
}
