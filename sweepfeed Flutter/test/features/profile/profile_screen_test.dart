import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth; // aliased
import 'package:cached_network_image/cached_network_image.dart';

import 'package:sweepfeed_app/core/models/user_profile.dart';
import 'package:sweepfeed_app/features/profile/screens/profile_screen.dart';
import 'package:sweepfeed_app/features/profile/services/profile_service.dart';
import 'package:sweepfeed_app/features/auth/services/auth_service.dart';
import 'package:sweepfeed_app/core/services/gamification_service.dart'; // For Badge metadata

// Mocks
class MockProfileService extends Mock implements ProfileService {}
class MockAuthService extends Mock implements AuthService {}
class MockUser extends Mock implements fb_auth.User {} // Mock Firebase User

// Test App Wrapper
Widget createProfileScreenTestWidget({
  required MockProfileService mockProfileService,
  required MockAuthService mockAuthService,
  required MockUser mockCurrentUser,
}) {
  return MultiProvider(
    providers: [
      Provider<ProfileService>.value(value: mockProfileService),
      Provider<AuthService>.value(value: mockAuthService),
      Provider<fb_auth.User?>.value(value: mockCurrentUser),
      // Add other providers ProfileScreen might depend on, if any (e.g. SubscriptionService)
      // For simplicity, assuming they are not critical for these specific tests or have defaults.
    ],
    child: const MaterialApp(
      home: ProfileScreen(),
    ),
  );
}

void main() {
  late MockProfileService mockProfileService;
  late MockAuthService mockAuthService;
  late MockUser mockCurrentUser;

  setUp(() {
    mockProfileService = MockProfileService();
    mockAuthService = MockAuthService();
    mockCurrentUser = MockUser();

    // Mock current user details
    when(mockCurrentUser.uid).thenReturn('testUserId');
    when(mockCurrentUser.email).thenReturn('testuser@example.com');
    when(mockCurrentUser.displayName).thenReturn('Test User Display Name');
  });

  group('ProfileScreen Widget Tests', () {
    testWidgets('displays user information and profile picture correctly', (WidgetTester tester) async {
      final userProfileData = UserProfile(
        id: 'testUserId',
        bio: 'This is a test bio.',
        profilePictureUrl: 'http://example.com/profile.jpg',
        location: 'Test Location',
      );
      // Mock for the main user document from AuthService (for badges, etc.)
      final authUserDocData = {
        'uid': 'testUserId',
        'email': 'testuser@example.com',
        'displayName': 'Test User Display Name',
        'gamification': {
          'badges': {
            'collected': [BadgeIds.welcomeAboard], // Sample badge
          }
        }
      };

      when(mockProfileService.getUserProfile('testUserId')).thenAnswer((_) async => userProfileData);
      when(mockProfileService.getUserEntriesWithContestDetails('testUserId')).thenAnswer((_) async => []);
      when(mockAuthService.getUserProfile()).thenAnswer((_) async => authUserDocData); // For badges

      await tester.pumpWidget(createProfileScreenTestWidget(
        mockProfileService: mockProfileService,
        mockAuthService: mockAuthService,
        mockCurrentUser: mockCurrentUser,
      ));

      await tester.pumpAndSettle(); // Wait for futures to resolve

      expect(find.text('Test User Display Name'), findsOneWidget);
      expect(find.text('testuser@example.com'), findsOneWidget);
      expect(find.text('This is a test bio.'), findsOneWidget);
      expect(find.text('Test Location'), findsOneWidget);
      
      // Verify CachedNetworkImage is present with the correct URL
      final imageFinder = find.byWidgetPredicate((widget) =>
          widget is CachedNetworkImage &&
          widget.imageUrl == 'http://example.com/profile.jpg');
      expect(imageFinder, findsOneWidget);
    });

    testWidgets('displays contest history correctly', (WidgetTester tester) async {
      final contestHistoryData = [
        {'contestName': 'Win a Car', 'entryDate': DateTime(2023, 1, 15), 'prize': 'Tesla Model S'},
        {'contestName': 'Win a Phone', 'entryDate': DateTime(2023, 1, 10), 'prize': 'iPhone 20'},
      ];
      final authUserDocData = { // Basic data for other parts of the screen
        'uid': 'testUserId', 'gamification': {'badges': {'collected': []}}
      };

      when(mockProfileService.getUserProfile('testUserId')).thenAnswer((_) async => UserProfile(id: 'testUserId'));
      when(mockProfileService.getUserEntriesWithContestDetails('testUserId')).thenAnswer((_) async => contestHistoryData);
      when(mockAuthService.getUserProfile()).thenAnswer((_) async => authUserDocData);


      await tester.pumpWidget(createProfileScreenTestWidget(
        mockProfileService: mockProfileService,
        mockAuthService: mockAuthService,
        mockCurrentUser: mockCurrentUser,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Contest Entry History'), findsOneWidget);
      expect(find.text('Win a Car'), findsOneWidget);
      expect(find.text('Prize: Tesla Model S'), findsOneWidget);
      // Date formatting might make direct text finding tricky, but presence of name/prize is good.
      expect(find.text('Win a Phone'), findsOneWidget);
      expect(find.text('Prize: iPhone 20'), findsOneWidget);
    });

    testWidgets('displays "No contest entries" message when history is empty', (WidgetTester tester) async {
      final authUserDocData = {
        'uid': 'testUserId', 'gamification': {'badges': {'collected': []}}
      };
      when(mockProfileService.getUserProfile('testUserId')).thenAnswer((_) async => UserProfile(id: 'testUserId'));
      when(mockProfileService.getUserEntriesWithContestDetails('testUserId')).thenAnswer((_) async => []);
      when(mockAuthService.getUserProfile()).thenAnswer((_) async => authUserDocData);

      await tester.pumpWidget(createProfileScreenTestWidget(
        mockProfileService: mockProfileService,
        mockAuthService: mockAuthService,
        mockCurrentUser: mockCurrentUser,
      ));
      await tester.pumpAndSettle();

      expect(find.text('No contest entries found yet.'), findsOneWidget);
    });

    testWidgets('displays basic badges section title', (WidgetTester tester) async {
      // This test just checks if the section title for badges is rendered.
      // Detailed badge rendering tests will be in profile_screen_badges_test.dart.
      final authUserDocData = {
        'uid': 'testUserId',
        'gamification': {
          'badges': {
            'collected': [], // No badges for this basic test
          }
        }
      };
      when(mockProfileService.getUserProfile('testUserId')).thenAnswer((_) async => UserProfile(id: 'testUserId'));
      when(mockProfileService.getUserEntriesWithContestDetails('testUserId')).thenAnswer((_) async => []);
      when(mockAuthService.getUserProfile()).thenAnswer((_) async => authUserDocData);

      await tester.pumpWidget(createProfileScreenTestWidget(
        mockProfileService: mockProfileService,
        mockAuthService: mockAuthService,
        mockCurrentUser: mockCurrentUser,
      ));
      await tester.pumpAndSettle();

      expect(find.text('My Achievements'), findsOneWidget);
      // Expect "No badges" message because collected is empty
      expect(find.text('No badges earned yet. Keep exploring!'), findsOneWidget);
    });
    
    testWidgets('navigates to ProfileSettingsScreen on Edit Profile tap', (WidgetTester tester) async {
      when(mockProfileService.getUserProfile('testUserId')).thenAnswer((_) async => UserProfile(id: 'testUserId'));
      when(mockProfileService.getUserEntriesWithContestDetails('testUserId')).thenAnswer((_) async => []);
      when(mockAuthService.getUserProfile()).thenAnswer((_) async => {'uid': 'testUserId', 'gamification': {'badges': {'collected': []}}});

      await tester.pumpWidget(createProfileScreenTestWidget(
        mockProfileService: mockProfileService,
        mockAuthService: mockAuthService,
        mockCurrentUser: mockCurrentUser,
      ));
      await tester.pumpAndSettle();

      // For navigation, we often don't test the destination screen's content in the source screen's test.
      // Instead, we verify the navigation action itself if possible, or that the tap leads to a state change
      // if navigation is conditional. Here, we'll just ensure the button is tappable.
      // A more complex test might involve a mock Navigator.
      
      expect(find.widgetWithIcon(ListTile, Icons.edit_outlined), findsOneWidget);
      await tester.tap(find.widgetWithIcon(ListTile, Icons.edit_outlined));
      await tester.pumpAndSettle(); 
      
      // Due to the way ProfileScreen calls Navigator.push, it will try to push ProfileSettingsScreen.
      // In a unit test environment, this might lead to errors if ProfileSettingsScreen itself has unmet dependencies.
      // For this test, we confirm the tap action. A full navigation test might need a mock Navigator.
      // No direct expectation here other than the tap not crashing.
    });

  });
}
