import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:image_picker/image_picker.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:sweepfeed_app/core/models/user_profile.dart';
import 'package:sweepfeed_app/features/profile/screens/profile_settings_screen.dart';
import 'package:sweepfeed_app/features/profile/services/profile_service.dart';
import 'package:sweepfeed_app/core/providers/theme_provider.dart'; // For ThemeProvider if used directly in this screen for other things
import 'package:shared_preferences/shared_preferences.dart'; // For ThemeProvider mock

// Mocks
class MockProfileService extends Mock implements ProfileService {}
class MockUser extends Mock implements fb_auth.User {}
class MockImagePicker extends Mock implements ImagePicker {} // Standard mock
class MockImagePickerPlatform extends Mock with MockPlatformInterfaceMixin implements ImagePickerPlatform {
  PickPathProperties? pickPathProperties;

  @override
  Future<XFile?> pickImage({
    ImageSource source = ImageSource.gallery,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    if (pickPathProperties?.path != null) {
      return XFile(pickPathProperties!.path!);
    }
    return null;
  }
  // Mock other methods if needed, like pickMedia, pickMultipleMedia, etc.
}
class PickPathProperties {
  final String? path;
  PickPathProperties({this.path});
}

// Mock ThemeProvider
class MockThemeProvider extends Mock implements ThemeProvider {
  @override
  ThemeMode get themeMode => ThemeMode.system; // Default or make configurable
}


// Test App Wrapper
Widget createProfileSettingsScreenTestWidget({
  required MockProfileService mockProfileService,
  required MockUser mockCurrentUser,
  required MockThemeProvider mockThemeProvider, 
}) {
   // Mock FirebaseAuth instance
  final mockFirebaseAuth = MockFirebaseAuth(mockCurrentUser: mockCurrentUser);

  return MultiProvider(
    providers: [
      Provider<ProfileService>.value(value: mockProfileService),
      // Provide the MockFirebaseAuth instance if ProfileSettingsScreen uses FirebaseAuth.instance directly.
      // If it gets User from Provider, then that's covered by fb_auth.User provider.
      // ProfileSettingsScreen uses FirebaseAuth.instance.currentUser to get the UID.
      // So we need to ensure that call can be handled or the UID is available.
      // For simplicity, we assume _currentUserId is set based on a Provider<User?> or similar.
      // The screen's current implementation uses FirebaseAuth.instance.currentUser.
      // This is harder to mock directly in widget tests without a wrapper around FirebaseAuth.
      // Let's assume the _currentUserId is correctly fetched (e.g., 'testUserId' used in screen).
      ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
    ],
    child: MaterialApp(
      home: ProfileSettingsScreen(), // Directly use, assuming UID is handled
    ),
  );
}

// Mock FirebaseAuth for testing purposes
class MockFirebaseAuth extends Mock implements fb_auth.FirebaseAuth {
  final MockUser? mockCurrentUser;
  MockFirebaseAuth({this.mockCurrentUser});

  @override
  fb_auth.User? get currentUser => mockCurrentUser;
}


void main() {
  late MockProfileService mockProfileService;
  late MockUser mockCurrentUser;
  late MockImagePickerPlatform mockImagePickerPlatform;
  late MockThemeProvider mockThemeProvider;

  setUp(() async {
    mockProfileService = MockProfileService();
    mockCurrentUser = MockUser();
    mockImagePickerPlatform = MockImagePickerPlatform();
    ImagePickerPlatform.instance = mockImagePickerPlatform; // Mock the platform instance
    
    // Setup SharedPreferences mock for ThemeProvider
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    mockThemeProvider = ThemeProvider(prefs); // Use real ThemeProvider with mock SharedPreferences

    // Mock current user details
    when(mockCurrentUser.uid).thenReturn('testUserId'); // Crucial for the screen's logic
    
    // Mock FirebaseAuth.instance.currentUser
    // This is tricky. Widget tests run in a real Flutter environment.
    // Overriding FirebaseAuth.instance is not straightforward without a DI/service locator for auth.
    // The ProfileSettingsScreen directly calls FirebaseAuth.instance.currentUser.
    // For this test, we'll rely on the screen's _currentUserId being correctly populated by its own logic.
    // The screen initializes _currentUserId in didChangeDependencies via FirebaseAuth.instance.currentUser.
    // To make this testable, we often wrap FirebaseAuth.
    // Given the setup, we ensure mockCurrentUser.uid is used.
  });

  tearDown(() {
    // Reset ImagePickerPlatform.instance to the default after tests
    // This might require knowing the original instance or a more complex setup.
    // For now, this simple assignment is often sufficient for test suites.
    // ImagePickerPlatform.instance = MethodChannelImagePicker(); // Or some default
  });


  final initialUserProfile = UserProfile(
    id: 'testUserId',
    bio: 'Initial Bio',
    location: 'Initial Location',
    profilePictureUrl: 'http://example.com/initial.jpg',
    interests: ['Tech', 'Music'],
    favoriteBrands: ['BrandA'],
  );

  group('ProfileSettingsScreen Widget Tests', () {
    testWidgets('displays initial profile data correctly', (WidgetTester tester) async {
      // Arrange: Mock service calls
      when(mockProfileService.getUserProfile('testUserId')).thenAnswer((_) async => initialUserProfile);
      // Mock FirebaseAuth.instance.currentUser for the screen's internal fetch
      final auth = MockFirebaseAuth(mockCurrentUser: mockCurrentUser);
      // This direct mocking of FirebaseAuth.instance is not standard.
      // Usually, you'd provide User via Provider, and the screen would consume that.
      // However, ProfileSettingsScreen uses FirebaseAuth.instance.currentUser in didChangeDependencies.
      // This test will proceed assuming that mechanism works and _currentUserId gets set.

      await tester.pumpWidget(createProfileSettingsTestWidget(
        mockProfileService: mockProfileService,
        mockCurrentUser: mockCurrentUser, // This user's UID needs to match what the screen expects
        mockThemeProvider: mockThemeProvider,
      ));

      await tester.pumpAndSettle(); // Wait for futures (getUserProfile)

      expect(find.widgetWithText(TextField, 'Initial Bio'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Initial Location'), findsOneWidget);
      
      // Check profile picture
      final imageFinder = find.byWidgetPredicate((widget) =>
          widget is CachedNetworkImage &&
          widget.imageUrl == 'http://example.com/initial.jpg');
      expect(imageFinder, findsOneWidget);

      // Check interests and brands (ensure chips are found)
      expect(find.widgetWithText(FilterChip, 'Tech'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'BrandA'), findsOneWidget);
    });

    testWidgets('picks an image and updates preview', (WidgetTester tester) async {
      when(mockProfileService.getUserProfile('testUserId')).thenAnswer((_) async => initialUserProfile);
      mockImagePickerPlatform.pickPathProperties = PickPathProperties(path: '/mock/image.jpg');
      
      // Stub the file system entity for FileImage
      final mockImageFile = File('/mock/image.jpg');
      // This might require more setup if FileImage tries to actually load the file.
      // For widget tests, often just checking the state change is enough.

      await tester.pumpWidget(createProfileSettingsTestWidget(
        mockProfileService: mockProfileService,
        mockCurrentUser: mockCurrentUser,
        mockThemeProvider: mockThemeProvider,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Change Profile Picture'));
      await tester.pumpAndSettle();

      // Verify that CircleAvatar shows the new image (FileImage)
      // This is hard to verify directly without actually rendering the image.
      // We can check if the _selectedImageFile state variable in the widget was set.
      // Accessing state directly is not standard; better to check for UI changes.
      // For now, we assume the UI updates if _selectedImageFile is set.
      // A more robust test might involve a custom FakeImageProvider.
      
      // We expect the CachedNetworkImage to disappear or be replaced if a new file is picked.
      // If _selectedImageFile is not null, backgroundImage should be FileImage.
      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(avatar.backgroundImage, isA<FileImage>());
      expect((avatar.backgroundImage as FileImage).file.path, '/mock/image.jpg');
    });

    testWidgets('saves profile data with new image', (WidgetTester tester) async {
      final newBio = 'Updated Bio';
      final newImageUrl = 'http://example.com/new_uploaded_image.jpg';

      when(mockProfileService.getUserProfile('testUserId')).thenAnswer((_) async => initialUserProfile);
      when(mockProfileService.uploadProfilePicture('testUserId', any)).thenAnswer((_) async => newImageUrl);
      when(mockProfileService.updateUserProfile(any)).thenAnswer((_) async => Future.value());
      
      mockImagePickerPlatform.pickPathProperties = PickPathProperties(path: '/mock/new_image.jpg');


      await tester.pumpWidget(createProfileSettingsTestWidget(
        mockProfileService: mockProfileService,
        mockCurrentUser: mockCurrentUser,
        mockThemeProvider: mockThemeProvider,
      ));
      await tester.pumpAndSettle();

      // Change bio
      await tester.enterText(find.widgetWithText(TextField, 'Initial Bio'), newBio);
      // Pick new image
      await tester.tap(find.text('Change Profile Picture'));
      await tester.pumpAndSettle();
      
      // Tap save
      await tester.tap(find.widgetWithIcon(IconButton, Icons.save)); // Or find.text('Save Profile') if it's an ElevatedButton
      await tester.pumpAndSettle(); // For SnackBar and navigation

      // Verify uploadProfilePicture was called
      verify(mockProfileService.uploadProfilePicture('testUserId', any)).called(1);
      
      // Verify updateUserProfile was called with correct data
      final captured = verify(mockProfileService.updateUserProfile(captureAny)).captured;
      expect(captured.single, isA<UserProfile>());
      final UserProfile savedProfile = captured.single;
      expect(savedProfile.id, 'testUserId');
      expect(savedProfile.bio, newBio);
      expect(savedProfile.profilePictureUrl, newImageUrl); // Check if new URL is saved
      
      expect(find.text('Profile saved successfully!'), findsOneWidget); // Check SnackBar
    });

    testWidgets('saves profile data without changing image', (WidgetTester tester) async {
      final newBio = 'Bio updated, no image change.';
      when(mockProfileService.getUserProfile('testUserId')).thenAnswer((_) async => initialUserProfile);
      when(mockProfileService.updateUserProfile(any)).thenAnswer((_) async => Future.value());

      await tester.pumpWidget(createProfileSettingsTestWidget(
        mockProfileService: mockProfileService,
        mockCurrentUser: mockCurrentUser,
        mockThemeProvider: mockThemeProvider,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Initial Bio'), newBio);
      await tester.tap(find.widgetWithIcon(IconButton, Icons.save));
      await tester.pumpAndSettle();

      // Verify uploadProfilePicture was NOT called
      verifyNever(mockProfileService.uploadProfilePicture(any, any));
      
      final captured = verify(mockProfileService.updateUserProfile(captureAny)).captured;
      expect(captured.single, isA<UserProfile>());
      final UserProfile savedProfile = captured.single;
      expect(savedProfile.bio, newBio);
      expect(savedProfile.profilePictureUrl, initialUserProfile.profilePictureUrl); // Should be initial URL

      expect(find.text('Profile saved successfully!'), findsOneWidget);
    });
  });
}
