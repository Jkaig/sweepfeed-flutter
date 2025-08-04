import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import 'package:sweepfeed_app/core/models/user_profile.dart';
import 'package:sweepfeed_app/features/profile/screens/profile_screen.dart';
import 'package:sweepfeed_app/features/profile/services/profile_service.dart';
import 'package:sweepfeed_app/features/auth/services/auth_service.dart';
import 'package:sweepfeed_app/core/services/gamification_service.dart';

// Mocks
class MockProfileService extends Mock implements ProfileService {}
class MockAuthService extends Mock implements AuthService {}
class MockUser extends Mock implements fb_auth.User {}

// Test App Wrapper
Widget createProfileScreenBadgesTestWidget({
  required MockProfileService mockProfileService,
  required MockAuthService mockAuthService,
  required MockUser mockCurrentUser,
  required Map<String, dynamic> authUserDocData, // For 'users' collection data
}) {
  // Mock service calls for ProfileScreen dependencies
  when(mockProfileService.getUserProfile(any)).thenAnswer((_) async => UserProfile(id: mockCurrentUser.uid, bio: 'Mock Bio'));
  when(mockProfileService.getUserEntriesWithContestDetails(any)).thenAnswer((_) async => []);
  when(mockAuthService.getUserProfile()).thenAnswer((_) async => authUserDocData);


  return MultiProvider(
    providers: [
      Provider<ProfileService>.value(value: mockProfileService),
      Provider<AuthService>.value(value: mockAuthService),
      Provider<fb_auth.User?>.value(value: mockCurrentUser),
      // Add other providers ProfileScreen might depend on with default/mock values
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

  const String testUserId = 'badgeTestUser';

  setUp(() {
    mockProfileService = MockProfileService();
    mockAuthService = MockAuthService();
    mockCurrentUser = MockUser();

    // Mock current user details
    when(mockCurrentUser.uid).thenReturn(testUserId);
    when(mockCurrentUser.email).thenReturn('badgetest@example.com');
    when(mockCurrentUser.displayName).thenReturn('Badge Test User');
  });

  group('ProfileScreen Badges Display Tests', () {
    testWidgets('displays "My Achievements" section and earned badges correctly', (WidgetTester tester) async {
      final authUserDocData = {
        'uid': testUserId,
        'displayName': 'Badge Test User',
        'email': 'badgetest@example.com',
        'gamification': {
          'badges': {
            'collected': [BadgeIds.welcomeAboard, BadgeIds.entryEnthusiast],
          }
        }
      };

      await tester.pumpWidget(createProfileScreenBadgesTestWidget(
        mockProfileService: mockProfileService,
        mockAuthService: mockAuthService,
        mockCurrentUser: mockCurrentUser,
        authUserDocData: authUserDocData,
      ));
      await tester.pumpAndSettle();

      expect(find.text('My Achievements'), findsOneWidget);

      // Check for Welcome Aboard badge
      final welcomeBadgeMeta = GamificationService.getBadgeById(BadgeIds.welcomeAboard)!;
      expect(find.widgetWithText(Chip, welcomeBadgeMeta.name), findsOneWidget);
      expect(find.byIcon(welcomeBadgeMeta.icon), findsOneWidget);
      
      // Check for Entry Enthusiast badge
      final entryBadgeMeta = GamificationService.getBadgeById(BadgeIds.entryEnthusiast)!;
      expect(find.widgetWithText(Chip, entryBadgeMeta.name), findsOneWidget);
      expect(find.byIcon(entryBadgeMeta.icon), findsOneWidget);

      // Tap a badge and check for SnackBar
      await tester.tap(find.widgetWithText(Chip, welcomeBadgeMeta.name));
      await tester.pumpAndSettle(); // For SnackBar animation

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('${welcomeBadgeMeta.name}: ${welcomeBadgeMeta.description}'), findsOneWidget);
      
      // Ensure SnackBar disappears
      await tester.pump(const Duration(seconds: 4)); // Default SnackBar duration is 4s
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('displays "No badges earned yet" message when no badges are collected', (WidgetTester tester) async {
      final authUserDocData = {
        'uid': testUserId,
        'gamification': {
          'badges': {'collected': []} // Empty list
        }
      };

      await tester.pumpWidget(createProfileScreenBadgesTestWidget(
        mockProfileService: mockProfileService,
        mockAuthService: mockAuthService,
        mockCurrentUser: mockCurrentUser,
        authUserDocData: authUserDocData,
      ));
      await tester.pumpAndSettle();

      expect(find.text('My Achievements'), findsOneWidget);
      expect(find.text('No badges earned yet. Keep exploring!'), findsOneWidget);
    });

    testWidgets('handles null or missing gamification data gracefully for badges', (WidgetTester tester) async {
      final authUserDocDataMissingGamification = {'uid': testUserId}; // No gamification map
      final authUserDocDataMissingBadges = {'uid': testUserId, 'gamification': {}}; // No badges map
      final authUserDocDataMissingCollected = {'uid': testUserId, 'gamification': {'badges': {}}}; // No collected list

      // Test 1: Missing 'gamification'
      await tester.pumpWidget(createProfileScreenBadgesTestWidget(
        mockProfileService: mockProfileService,
        mockAuthService: mockAuthService,
        mockCurrentUser: mockCurrentUser,
        authUserDocData: authUserDocDataMissingGamification,
      ));
      await tester.pumpAndSettle();
      expect(find.text('No badges earned yet. Keep exploring!'), findsOneWidget);

      // Test 2: Missing 'badges'
      await tester.pumpWidget(createProfileScreenBadgesTestWidget(
        mockProfileService: mockProfileService,
        mockAuthService: mockAuthService,
        mockCurrentUser: mockCurrentUser,
        authUserDocData: authUserDocDataMissingBadges,
      ));
      await tester.pumpAndSettle();
      expect(find.text('No badges earned yet. Keep exploring!'), findsOneWidget);
      
      // Test 3: Missing 'collected'
       await tester.pumpWidget(createProfileScreenBadgesTestWidget(
        mockProfileService: mockProfileService,
        mockAuthService: mockAuthService,
        mockCurrentUser: mockCurrentUser,
        authUserDocData: authUserDocDataMissingCollected,
      ));
      await tester.pumpAndSettle();
      expect(find.text('No badges earned yet. Keep exploring!'), findsOneWidget);
    });

    testWidgets('ignores unknown badge IDs gracefully', (WidgetTester tester) async {
      final authUserDocData = {
        'uid': testUserId,
        'gamification': {
          'badges': {
            'collected': [BadgeIds.welcomeAboard, 'unknown_badge_id'],
          }
        }
      };

      await tester.pumpWidget(createProfileScreenBadgesTestWidget(
        mockProfileService: mockProfileService,
        mockAuthService: mockAuthService,
        mockCurrentUser: mockCurrentUser,
        authUserDocData: authUserDocData,
      ));
      await tester.pumpAndSettle();

      // Should display Welcome Aboard
      final welcomeBadgeMeta = GamificationService.getBadgeById(BadgeIds.welcomeAboard)!;
      expect(find.widgetWithText(Chip, welcomeBadgeMeta.name), findsOneWidget);

      // Should not find any chip for 'unknown_badge_id' and not crash
      expect(find.widgetWithText(Chip, 'unknown_badge_id'), findsNothing);
    });
  });
}
