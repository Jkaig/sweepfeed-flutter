import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:math'; // For random code generation
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sweepfeed_app/core/services/gamification_service.dart'; // Import GamificationService
import '../../../core/theme/app_colors.dart';
import '../../onboarding/screens/prize_preferences_screen.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GamificationService _gamificationService = GamificationService(); // Add GamificationService instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
    signInOption: SignInOption.standard,
  );

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current user
  User? get currentUser => _auth.currentUser;

  // Create or update user profile
  Future<void> _createOrUpdateUserProfile(
    User user, {
    String? displayName,
    String? email,
    String? photoURL,
    String? provider,
    String? referralCode, // New parameter for the new user's own code
    String? referredByCode, // New parameter for the code they were referred by
    Map<String, dynamic>? additionalData,
  }) async {
    final userData = {
      'uid': user.uid,
      'email': email ?? user.email,
      'displayName': displayName ?? user.displayName,
      'photoURL': photoURL ?? user.photoURL,
      'provider': provider ?? 'email',
      'createdAt': FieldValue.serverTimestamp(),
      'lastSignIn': FieldValue.serverTimestamp(),
      'onboardingCompleted': false,
      
      // Referral Information
      'referralCode': referralCode, // Store the new user's own referral code
      'referredByCode': referredByCode, // Store the code of the user who referred them
      'referralCount': 0, // Initialize referral count

      // Subscription Information
      'subscription': {
        'status': 'trial', // trial, active, expired, cancelled
        'plan': 'free', // free, basic, premium
        'startDate': FieldValue.serverTimestamp(),
        'endDate': null,
        'autoRenew': false,
        'paymentMethod': null,
        'lastPaymentDate': null,
        'nextBillingDate': null,
      },

      // Sweepstake History
      'sweepstakes': {
        'entries': [], // Array of entry objects
        'history': [], // Array of historical entries
        'favorites': [], // Array of favorite sweepstakes IDs
        'wins': [], // Array of won sweepstakes
      },

      // Preferences
      'preferences': {
        'categories': [],
        'country': 'United States',
        'notificationPreferences': {
          'email': true,
          'push': true,
          'wins': true,
          'newSweepstakes': true,
          'reminders': true,
        },
      },

      // User Stats
      'stats': {
        'totalEntries': 0,
        'activeEntries': 0,
        'totalWins': 0,
        'winRate': 0.0,
        'points': 0,
        'streak': 0, // Daily entry streak
        'lastEntryDate': null,
      },

      // Account Status
      'account': {
        'status': 'active', // active, suspended, banned
        'verificationStatus': 'unverified', // unverified, pending, verified
        'trialEndDate': FieldValue.serverTimestamp(), // 7 days from creation
        'lastActivity': FieldValue.serverTimestamp(),
        'deviceTokens': [], // For push notifications
      },

      // Settings
      'settings': {
        'notifications': true,
        'emailUpdates': true,
        'privacy': {
          'showWins': true,
          'showEntries': true,
          'showProfile': true,
        },
        'theme': 'system', // system, light, dark
        'language': 'en',
      },

      // Interest Tracking
      'interests': {
        'categories': [], // Selected prize categories
        'priceRanges': {
          'min': 0,
          'max': 1000,
        },
        'frequency': 'daily', // daily, weekly, monthly
        'preferredEntryMethods': [], // instant, daily, weekly
        'excludedBrands': [], // Brands user doesn't want to see
        'favoriteBrands': [], // Brands user prefers
        'searchHistory': [], // Recent searches
        'viewedSweepstakes': [], // Recently viewed sweepstakes
        'engagement': {
          'lastCategoryView': {},
          'categoryClickCount': {},
          'timeSpent': 0, // in minutes
          'preferredTimeOfDay': 'any', // morning, afternoon, evening, any
        },
      },

      // Notification Settings
      'notifications': {
        'enabled': true,
        'channels': {
          'email': {
            'enabled': true,
            'frequency': 'daily', // instant, daily, weekly
            'types': {
              'newSweepstakes': true,
              'endingSoon': true,
              'wins': true,
              'reminders': true,
              'promotions': true,
              'newsletter': true,
            },
            'preferredTime': '09:00', // 24-hour format
          },
          'push': {
            'enabled': true,
            'types': {
              'newSweepstakes': true,
              'endingSoon': true,
              'wins': true,
              'reminders': true,
              'streakReminders': true,
            },
            'quietHours': {
              'enabled': false,
              'start': '22:00',
              'end': '07:00',
            },
          },
          'inApp': {
            'enabled': true,
            'types': {
              'newSweepstakes': true,
              'endingSoon': true,
              'wins': true,
              'streakUpdates': true,
              'pointsEarned': true,
            },
          },
        },
        'preferences': {
          'minimumPrizeValue': 10, // Minimum value to notify about
          'onlyFavorites': false, // Only notify about favorite brands
          'geographicRelevance': true, // Only relevant to user's location
          'frequencyCap': 3, // Max notifications per day
        },
      },

      // Gamification System
      'gamification': {
        'points': {
          'total': 0,
          'available': 0,
          'spent': 0,
          'history': [], // Array of point transactions
        },
        'level': {
          'current': 1,
          'experience': 0,
          'nextLevel': 100, // Points needed for next level
          'progress': 0.0, // Percentage to next level
        },
        'streaks': {
          'current': 0,
          'longest': 0,
          'lastEntryDate': null,
          'history': [], // Array of streak periods
        },
        'achievements': {
          'unlocked': [], // Array of achievement IDs
          'progress': {}, // Map of achievement ID to progress
          'rewards': [], // Array of claimed rewards
        },
        'badges': {
          'collected': [], // Array of badge IDs
          'displayed': [], // Array of badge IDs to show on profile
        },
        'dailyChallenges': {
          'current': [], // Array of active challenges
          'completed': [], // Array of completed challenge IDs
          'streak': 0, // Consecutive days completing challenges
        },
        'leaderboard': {
          'rank': 0,
          'categoryRanks': {}, // Ranks in different categories
          'lastUpdated': null,
        },
        'rewards': {
          'available': [], // Array of available rewards
          'claimed': [], // Array of claimed rewards
          'pending': [], // Array of pending rewards
        },
        'milestones': {
          'entries': 0,
          'wins': 0,
          'points': 0,
          'streak': 0,
          'achievements': 0,
        },
      },

      // Additional Profile Data
      if (additionalData != null) ...additionalData,
    };

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(userData, SetOptions(merge: true));
  }

  // Sign in with email and password
  Future<void> signInWithEmail(
      String email, String password, BuildContext context) async {
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await _createOrUpdateUserProfile(
          userCredential.user!,
          email: email,
          provider: 'email',
        );

        // Navigate to prize preferences screen
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const PrizePreferencesScreen()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled.';
          break;
        default:
          errorMessage = 'An error occurred: ${e.message}';
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // Sign in with Google
  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        await _createOrUpdateUserProfile(
          user,
          displayName: user.displayName,
          email: user.email,
          photoURL: user.photoURL,
          provider: 'google',
        );

        // Navigate to prize preferences screen
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const PrizePreferencesScreen()),
          );
        }
      }
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  // Sign in with Apple
  Future<void> signInWithApple(BuildContext context) async {
    try {
      // Check if the platform supports Apple Sign In
      if (!await SignInWithApple.isAvailable()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Apple Sign In is not available on this device'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: 'com.sweepfeed.app',
          redirectUri:
              Uri.parse('https://sweepfeed.com/callbacks/sign_in_with_apple'),
        ),
      );

      final oAuthProvider = OAuthProvider('apple.com');
      final credentialAuth = oAuthProvider.credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credentialAuth);
      final User? user = userCredential.user;

      if (user != null) {
        String? displayName =
            '${credential.givenName ?? ''} ${credential.familyName ?? ''}'
                .trim();
        if (displayName.isEmpty) displayName = null;

        await _createOrUpdateUserProfile(
          user,
          displayName: displayName ?? user.displayName,
          email: credential.email ?? user.email,
          provider: 'apple',
        );

        // Navigate to prize preferences screen
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const PrizePreferencesScreen()),
          );
        }
      }
    } catch (e) {
      print('Error signing in with Apple: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing in with Apple: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // Register with email and password
  Future<void> registerWithEmail(
    String email,
    String password,
    String name,
    Map<String, dynamic> userProfile, // This seems to be for other profile details
    String? referredByCode, // New parameter
  ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        final newUsersReferralCode = _generateReferralCode();
        // TODO: Add a check for referral code uniqueness in Firestore. 
        // This is complex client-side and prone to race conditions.
        // A Cloud Function is better for guaranteeing uniqueness at scale.
        // For now, we'll proceed without a client-side uniqueness check.

        await _createOrUpdateUserProfile(
          user,
          displayName: name,
          email: email,
          provider: 'email',
          referralCode: newUsersReferralCode, // Pass generated code for the new user
          referredByCode: referredByCode,   // Pass the code they were referred by
          additionalData: { 
            // Keep existing additionalData logic
            'preferences': userProfile['preferences'] ?? {},
            'country': userProfile['country'] ?? '',
            'state': userProfile['state'] ?? '',
            'age': userProfile['age'] ?? 0,
            // Note: referralCount is initialized to 0 directly in _createOrUpdateUserProfile
          },
        );

        // Process referral if a code was provided
        if (referredByCode != null && referredByCode.isNotEmpty) {
          await _processReferral(referredByCode, user.uid);
        }
        
        // Award "Welcome Aboard" badge
        await _gamificationService.checkAndAwardWelcomeAboard(user.uid);

      }
    } catch (e) {
      rethrow;
    }
  }

  String _generateReferralCode({int length = 7}) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  Future<void> _processReferral(String referredByCode, String newUserId) async {
    try {
      // Find the referring user by their referral code
      final querySnapshot = await _firestore
          .collection('users')
          .where('referralCode', isEqualTo: referredByCode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final referrerDoc = querySnapshot.docs.first;
        final referrerId = referrerDoc.id;
        final referrerData = referrerDoc.data() as Map<String, dynamic>?;

        // Update referrer's count and points
        await referrerDoc.reference.update({
          'referralCount': FieldValue.increment(1),
        });
        // Use existing addPoints method for the referrer
        await addPoints(100, 'Referred new user: $newUserId', referenceId: newUserId, userIdOverride: referrerId);

        // Award points to the new user
        // Use existing addPoints method for the new user
        await addPoints(100, 'Signed up with referral from: $referrerId', referenceId: referrerId, userIdOverride: newUserId);

        print('Referral processed for referrer: $referrerId and new user: $newUserId');

        // Check for Referral Rockstar badge for the referrer
        // Need to fetch the updated referral count, or pass it if available synchronously (which it isn't here directly)
        // For simplicity, triggering the check. GamificationService will fetch the latest count.
        await _gamificationService.checkAndAwardReferralRockstar(referrerId);

      } else {
        print('Referral code "$referredByCode" not found.');
        // Optionally, store the invalid code on the new user's profile for later analysis?
        // For now, we just log it.
      }
    } catch (e) {
      print('Error processing referral: $e');
      // Handle error (e.g., log to a monitoring service)
    }
  }


  // Sign out
  Future<void> signOut() async {
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  // Password reset
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Get user profile data
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      if (currentUser != null) {
        final doc =
            await _firestore.collection('users').doc(currentUser!.uid).get();
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> profileData) async {
    try {
      if (currentUser != null) {
        await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .update(profileData);
      }
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  // Update user preferences
  Future<void> updateUserPreferences(Map<String, dynamic> preferences) async {
    try {
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser!.uid).update({
          'preferences': preferences,
        });
      }
    } catch (e) {
      print('Error updating user preferences: $e');
      rethrow;
    }
  }

  // Store auth tokens securely (for potential refresh token usage)
  Future<void> storeAuthToken(String token) async {
    await _storage.write(key: 'authToken', value: token);
  }

  // Get stored auth token
  Future<String?> getAuthToken() async {
    return await _storage.read(key: 'authToken');
  }

  // Delete stored auth token
  Future<void> deleteAuthToken() async {
    await _storage.delete(key: 'authToken');
  }

  // Add a method to update sweepstake entry
  Future<void> addSweepstakeEntry(
      String sweepstakeId, Map<String, dynamic> entryData) async {
    if (currentUser == null) return;

    final entry = {
      'sweepstakeId': sweepstakeId,
      'entryDate': FieldValue.serverTimestamp(),
      'status': 'active', // active, won, lost, expired
      ...entryData,
    };

    await _firestore.collection('users').doc(currentUser!.uid).update({
      'sweepstakes.entries': FieldValue.arrayUnion([entry]),
      'stats.totalEntries': FieldValue.increment(1),
      'stats.activeEntries': FieldValue.increment(1),
      'lastActivity': FieldValue.serverTimestamp(),
    });

    // After successfully adding an entry, check for "Entry Enthusiast" badge
    await _gamificationService.checkAndAwardEntryEnthusiast(currentUser!.uid);
  }

  // Add a method to update subscription status
  Future<void> updateSubscriptionStatus({
    required String status,
    required String plan,
    DateTime? endDate,
    bool autoRenew = false,
  }) async {
    if (currentUser == null) return;

    await _firestore.collection('users').doc(currentUser!.uid).update({
      'subscription.status': status,
      'subscription.plan': plan,
      'subscription.endDate': endDate,
      'subscription.autoRenew': autoRenew,
      'lastActivity': FieldValue.serverTimestamp(),
    });
  }

  // Add a method to record a win
  Future<void> recordWin(
      String sweepstakeId, Map<String, dynamic> winData) async {
    if (currentUser == null) return;

    final win = {
      'sweepstakeId': sweepstakeId,
      'winDate': FieldValue.serverTimestamp(),
      ...winData,
    };

    await _firestore.collection('users').doc(currentUser!.uid).update({
      'sweepstakes.wins': FieldValue.arrayUnion([win]),
      'stats.totalWins': FieldValue.increment(1),
      'stats.winRate':
          FieldValue.increment(1), // This will need to be calculated properly
      'lastActivity': FieldValue.serverTimestamp(),
    });
  }

  // Add a method to update user interests
  Future<void> updateUserInterests({
    List<String>? categories,
    Map<String, dynamic>? priceRanges,
    String? frequency,
    List<String>? preferredEntryMethods,
    List<String>? excludedBrands,
    List<String>? favoriteBrands,
  }) async {
    if (currentUser == null) return;

    final updates = <String, dynamic>{};

    if (categories != null) updates['interests.categories'] = categories;
    if (priceRanges != null) updates['interests.priceRanges'] = priceRanges;
    if (frequency != null) updates['interests.frequency'] = frequency;
    if (preferredEntryMethods != null) {
      updates['interests.preferredEntryMethods'] = preferredEntryMethods;
    }
    if (excludedBrands != null) {
      updates['interests.excludedBrands'] = excludedBrands;
    }
    if (favoriteBrands != null) {
      updates['interests.favoriteBrands'] = favoriteBrands;
    }

    await _firestore.collection('users').doc(currentUser!.uid).update(updates);
  }

  // Add a method to update notification settings
  Future<void> updateNotificationSettings({
    bool? enabled,
    Map<String, dynamic>? emailSettings,
    Map<String, dynamic>? pushSettings,
    Map<String, dynamic>? inAppSettings,
    Map<String, dynamic>? preferences,
  }) async {
    if (currentUser == null) return;

    final updates = <String, dynamic>{};

    if (enabled != null) updates['notifications.enabled'] = enabled;
    if (emailSettings != null) {
      updates['notifications.channels.email'] = emailSettings;
    }
    if (pushSettings != null) {
      updates['notifications.channels.push'] = pushSettings;
    }
    if (inAppSettings != null) {
      updates['notifications.channels.inApp'] = inAppSettings;
    }
    if (preferences != null) updates['notifications.preferences'] = preferences;

    await _firestore.collection('users').doc(currentUser!.uid).update(updates);
  }

  // Add a method to track user engagement
  Future<void> trackEngagement({
    String? category,
    String? action,
    int? timeSpent,
  }) async {
    if (currentUser == null) return;

    final updates = <String, dynamic>{
      'interests.engagement.lastActivity': FieldValue.serverTimestamp(),
    };

    if (category != null) {
      updates['interests.engagement.lastCategoryView.$category'] =
          FieldValue.serverTimestamp();
      updates['interests.engagement.categoryClickCount.$category'] =
          FieldValue.increment(1);
    }

    if (timeSpent != null) {
      updates['interests.engagement.timeSpent'] =
          FieldValue.increment(timeSpent);
    }

    await _firestore.collection('users').doc(currentUser!.uid).update(updates);
  }

  // Add points to user's account
  Future<void> addPoints(int amount, String reason,
      {String? referenceId, String? userIdOverride}) async {
    // Allow overriding userId for referral processing
    final targetUserId = userIdOverride ?? currentUser?.uid; 
    if (targetUserId == null) return;

    final transaction = {
      'amount': amount,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
      if (referenceId != null) 'referenceId': referenceId,
    };

    await _firestore.collection('users').doc(targetUserId).update({
      'gamification.points.total': FieldValue.increment(amount),
      'gamification.points.available': FieldValue.increment(amount),
      'gamification.points.history': FieldValue.arrayUnion([transaction]),
    });

    // Check for level up, only for the current user, not the referred user if userIdOverride is used.
    if (userIdOverride == null || userIdOverride == currentUser?.uid) {
      await _checkLevelUp();
    }
  }

  // Spend points
  Future<void> spendPoints(int amount, String reason,
      {String? referenceId}) async {
    if (currentUser == null) return;

    final transaction = {
      'amount': -amount,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
      if (referenceId != null) 'referenceId': referenceId,
    };

    await _firestore.collection('users').doc(currentUser!.uid).update({
      'gamification.points.available': FieldValue.increment(-amount),
      'gamification.points.spent': FieldValue.increment(amount),
      'gamification.points.history': FieldValue.arrayUnion([transaction]),
    });
  }

  // Update streak
  Future<void> updateStreak() async {
    if (currentUser == null) return;

    final now = DateTime.now();
    final userDoc =
        await _firestore.collection('users').doc(currentUser!.uid).get();
    final lastEntryDate =
        userDoc.data()?['gamification']['streaks']['lastEntryDate']?.toDate();

    if (lastEntryDate == null || now.difference(lastEntryDate).inDays > 1) {
      // Reset streak
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'gamification.streaks.current': 1,
        'gamification.streaks.lastEntryDate': FieldValue.serverTimestamp(),
      });
    } else if (now.difference(lastEntryDate).inDays == 0) {
      // Already entered today
      return;
    } else {
      // Continue streak
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'gamification.streaks.current': FieldValue.increment(1),
        'gamification.streaks.lastEntryDate': FieldValue.serverTimestamp(),
      });

      // Update longest streak if needed
      final currentStreak =
          userDoc.data()?['gamification']['streaks']['current'] ?? 0;
      final longestStreak =
          userDoc.data()?['gamification']['streaks']['longest'] ?? 0;

      if (currentStreak + 1 > longestStreak) {
        await _firestore.collection('users').doc(currentUser!.uid).update({
          'gamification.streaks.longest': currentStreak + 1,
        });
      }
    }
  }

  // Check for level up
  Future<void> _checkLevelUp() async {
    if (currentUser == null) return;

    final userDoc =
        await _firestore.collection('users').doc(currentUser!.uid).get();
    final currentLevel =
        userDoc.data()?['gamification']['level']['current'] ?? 1;
    final currentExp =
        userDoc.data()?['gamification']['level']['experience'] ?? 0;
    final nextLevelExp =
        userDoc.data()?['gamification']['level']['nextLevel'] ?? 100;

    if (currentExp >= nextLevelExp) {
      // Level up
      final newLevel = currentLevel + 1;
      final newNextLevelExp = nextLevelExp * 1.5; // Exponential growth

      await _firestore.collection('users').doc(currentUser!.uid).update({
        'gamification.level.current': newLevel,
        'gamification.level.nextLevel': newNextLevelExp,
        'gamification.level.progress': 0.0,
      });

      // Award level up bonus
      await addPoints((100 * newLevel).toInt(), 'Level Up Bonus');
    }
  }

  // Unlock achievement
  Future<void> unlockAchievement(String achievementId,
      {int progress = 100}) async {
    if (currentUser == null) return;

    await _firestore.collection('users').doc(currentUser!.uid).update({
      'gamification.achievements.unlocked':
          FieldValue.arrayUnion([achievementId]),
      'gamification.achievements.progress.$achievementId': progress,
    });

    // Award achievement points
    await addPoints(50, 'Achievement Unlocked: $achievementId');
  }

  // Award badge
  Future<void> awardBadge(String badgeId) async {
    if (currentUser == null) return;

    await _firestore.collection('users').doc(currentUser!.uid).update({
      'gamification.badges.collected': FieldValue.arrayUnion([badgeId]),
    });

    // Award badge points
    await addPoints(25, 'Badge Awarded: $badgeId');
  }

  // Complete daily challenge
  Future<void> completeDailyChallenge(String challengeId) async {
    if (currentUser == null) return;

    await _firestore.collection('users').doc(currentUser!.uid).update({
      'gamification.dailyChallenges.completed':
          FieldValue.arrayUnion([challengeId]),
      'gamification.dailyChallenges.current':
          FieldValue.arrayRemove([challengeId]),
      'gamification.dailyChallenges.streak': FieldValue.increment(1),
    });

    // Award challenge completion points
    const int points = 10;
    await addPoints(points, 'Daily Challenge Completed: $challengeId');
  }

  // Check if user is admin
  Future<bool> isUserAdmin() async {
    try {
      if (currentUser != null) {
        final doc =
            await _firestore.collection('users').doc(currentUser!.uid).get();
        return doc.data()?['roles']?['admin'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }
}
