import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:local_auth/local_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/config/secure_config.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/services/dust_bunnies_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/logger.dart';
import '../../onboarding/screens/prize_preferences_screen.dart';
import '../screens/otp_screen.dart';

/// A comprehensive authentication service for managing user authentication,
/// profile data, and related features.
///
/// This service provides methods for:
///   - Signing in and signing up users with Google, Apple, phone number, and email/password.
///   - Managing user profiles, including creation, updates, and profile picture uploads.
///   - Implementing biometric authentication for enhanced security.
///   - Integrating gamification features like points, streaks, and achievements.
///   - Handling subscription management.
///   - Managing user preferences and notification settings.
///   - Managing referral codes.
///
/// The service utilizes Firebase Authentication, Firestore, and Storage for its
/// backend functionality. It also integrates with local_auth for biometric
/// authentication and flutter_secure_storage for secure storage of sensitive data.
class AuthService {
  AuthService() {
    _gamificationService = DustBunniesService();
    // GoogleSignIn will be configured with clientId during sign-in
    _googleSignIn = GoogleSignIn();
  }
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  late final DustBunniesService _gamificationService;
  final NotificationService _notificationService = NotificationService();

  /// Returns a stream of [User] objects representing the authentication state changes.
  ///
  /// This stream emits a new [User] object whenever the authentication state changes,
  /// such as when a user signs in or signs out. It emits `null` when there is no
  /// currently signed-in user.
  ///
  /// @returns A [Stream] of [User?] objects representing the authentication state.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Returns the currently signed-in [User] object, or `null` if no user is signed in.
  ///
  /// This getter provides access to the current user's information, such as their
  /// user ID, email address, and display name.
  ///
  /// @returns The current [User] object, or `null` if no user is signed in.
  User? get currentUser => _auth.currentUser;

  Future<String?> _uploadProfileImageToStorage(
    String userId,
    String photoURL,
  ) async {
    try {
      final response = await http.get(Uri.parse(photoURL));
      if (response.statusCode != 200) {
        logger.e('Failed to download profile image: ${response.statusCode}');
        return null;
      }

      final imageData = response.bodyBytes;

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users/$userId/profile_picture.jpg');

      final uploadTask = await storageRef.putData(
        imageData,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final downloadURL = await uploadTask.ref.getDownloadURL();
      logger.i('Profile image uploaded successfully: $downloadURL');
      return downloadURL;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        logger.e('Permission denied uploading profile image', error: e);
      } else if (e.code == 'quota-exceeded') {
        logger.e('Storage quota exceeded uploading profile image', error: e);
      } else {
        logger.e(
            'Firebase error uploading profile image: ${e.code} - ${e.message}',
            error: e);
      }
      return null;
    } catch (e) {
      logger.e('Unexpected error uploading profile image to storage', error: e);
      return null;
    }
  }

  // Create or update user profile
  Future<void> _createOrUpdateUserProfile(
    User user, {
    String? displayName,
    String? email,
    String? photoURL,
    String? provider,
    String? referralCode,
    String? referredByCode,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Validate required user data
      if (user.uid.isEmpty) {
        throw const ValidationError('User ID is required');
      }

      var finalPhotoURL = photoURL ?? user.photoURL;

      // Handle profile image upload with error handling
      if (finalPhotoURL != null && finalPhotoURL.isNotEmpty) {
        try {
          final uploadedURL =
              await _uploadProfileImageToStorage(user.uid, finalPhotoURL);
          if (uploadedURL != null) {
            finalPhotoURL = uploadedURL;
          }
        } on FirebaseException catch (e) {
          logger.w(
              'Firebase error during profile image upload, continuing without image: ${e.code}',
              error: e);
          finalPhotoURL = null;
        } catch (e) {
          logger.w(
              'Unexpected error during profile image upload, continuing without image',
              error: e);
          finalPhotoURL = null;
        }
      }

      final userData = {
        'uid': user.uid,
        'email': email ?? user.email,
        'name': displayName ?? user.displayName,
        'profilePictureUrl': finalPhotoURL,
        'signInProvider': provider ?? 'email',
        'createdAt': FieldValue.serverTimestamp(),
        'lastSignIn': FieldValue.serverTimestamp(),
        'onboardingCompleted': false,

        // Referral Information
        'referralCode': referralCode, // Store the new user's own referral code
        'referredByCode':
            referredByCode, // Store the code of the user who referred them
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

      // Attempt to create/update user profile in Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userData, SetOptions(merge: true));

      logger
          .i('User profile created/updated successfully for user: ${user.uid}');
    } on FirebaseException catch (e) {
      logger.e('Firebase error creating user profile', error: e);
      throw FirestoreError(
        'Failed to create user profile. Please try again.',
        rawError: e,
        context: '_createOrUpdateUserProfile',
      );
    } catch (e) {
      logger.e('Unexpected error creating user profile', error: e);
      throw AppError.fromException(
        e,
        context: '_createOrUpdateUserProfile',
        customMessage: 'Failed to set up your account. Please try again.',
      );
    }
  }

  /// Sends a sign-in link to the specified email address.
  ///
  /// This method triggers the process of sending a magic link to the provided
  /// email. The user can then click on this link to sign in or register.
  ///
  /// @param email The email address to send the sign-in link to. Must be a valid email format.
  /// @param context The BuildContext of the current widget tree. Used for displaying UI messages.
  /// @throws [FirebaseAuthException] if there's an issue sending the link.
  /// @throws [Exception] for other unexpected errors during the process.
  Future<void> sendSignInLinkToEmail(String email, BuildContext context) async {
    try {
      await _auth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: ActionCodeSettings(
          url: 'https://sweepfeed.page.link/signIn',
          handleCodeInApp: true,
          iOSBundleId: 'com.sweepfeed.app',
          androidPackageName: 'com.sweepfeed.app',
          androidInstallApp: true,
          androidMinimumVersion: '12',
        ),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A sign-in link has been sent to your email.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'invalid-email') {
        message = 'Invalid email address provided.';
      } else if (e.code == 'user-not-found') {
        message = 'No account found with this email.';
      } else {
        message = 'Error sending email link: ${e.message}';
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.error,
          ),
        );
      }
      logger.e('Firebase Auth error sending email link: ${e.code}', error: e);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unexpected error sending email link'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      logger.e('Unexpected error sending email link', error: e);
    }
  }

  /// Signs in the user using a sign-in link received via email.
  ///
  /// This method completes the sign-in process after the user clicks on the
  /// magic link sent to their email. It validates the link and signs in the user.
  ///
  /// @param email The email address the sign-in link was sent to.
  /// @param emailLink The sign-in link extracted from the email.
  /// @param context The BuildContext of the current widget tree.
  /// @throws [FirebaseAuthException] if the sign-in fails.
  /// @throws [Exception] for other unexpected errors during the process.
  Future<void> signInWithEmailLink(
    String email,
    String emailLink,
    BuildContext context,
  ) async {
    try {
      final userCredential =
          await _auth.signInWithEmailLink(email: email, emailLink: emailLink);

      if (userCredential.user != null) {
        await _createOrUpdateUserProfile(
          userCredential.user!,
          email: email,
          provider: 'email_link',
        );

        // Navigate to prize preferences screen
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const PrizePreferencesScreen(),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing in with email link: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Signs in the user anonymously.
  ///
  /// This method allows users to access the app without providing any
  /// personal information. Useful for allowing users to explore the app
  /// before creating an account. Anonymous users can be upgraded to regular
  /// accounts later.
  ///
  /// @param context The BuildContext of the current widget tree.
  /// @throws [FirebaseAuthException] if the anonymous sign-in fails.
  /// @throws [Exception] for other unexpected errors during the process.
  Future<void> signInAnonymously(BuildContext context) async {
    try {
      final userCredential = await _auth.signInAnonymously();
      final user = userCredential.user;
      if (user != null) {
        await _createOrUpdateUserProfile(
          user,
          displayName: 'Test User',
          email: 'tester@sweepfeed.app',
          provider: 'anonymous',
        );

        // Check if user needs onboarding
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists &&
            doc.data()?['onboardingCompleted'] != true &&
            context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const PrizePreferencesScreen()),
          );
        }
      }
    } catch (e) {
      logger.e('Anonymous sign in failed', error: e);
      rethrow;
    }
  }

  /// Signs in the user as a demo user, bypassing authentication.
  ///
  /// This method provides a way to sign in as a predefined demo user for
  /// testing and demonstration purposes. No actual authentication is
  /// performed. This method should not be used in production.
  ///
  /// @param context The BuildContext of the current widget tree.
  /// @throws [Exception] if there is an issue with the demo sign-in process.
  Future<void> signInAsDemo(BuildContext context) async {
    try {
      // Sign in anonymously for demo mode
      final userCredential = await _auth.signInAnonymously();
      final user = userCredential.user;

      if (user != null) {
        // Create demo user profile with test role
        await _firestore.collection('users').doc(user.uid).set(
          {
            'uid': user.uid,
            'email': 'demo@sweepfeed.app',
            'displayName': 'Demo User',
            'photoURL': null,
            'provider': 'demo',
            'role': 'tester', // Special role for demo users
            'isDemo': true,
            'createdAt': FieldValue.serverTimestamp(),
            'lastSignIn': FieldValue.serverTimestamp(),
            'onboardingCompleted': false, // Always show onboarding for demo

            // Demo subscription (premium features enabled)
            'subscription': {
              'status': 'active',
              'plan': 'premium', // Give demo users premium access
              'startDate': FieldValue.serverTimestamp(),
              'endDate': null,
              'autoRenew': false,
              'paymentMethod': 'demo',
              'lastPaymentDate': null,
              'nextBillingDate': null,
              'isDemo': true,
            },

            // Demo stats and features
            'sweepstakes': {
              'entries': [],
              'history': [],
              'favorites': [],
              'wins': [],
            },

            'preferences': {
              'categories': [],
              'country': 'United States',
              'notificationPreferences': {
                'email': false,
                'push': false,
                'wins': false,
                'newSweepstakes': false,
                'reminders': false,
              },
            },

            'stats': {
              'totalEntries': 0,
              'activeEntries': 0,
              'totalWins': 0,
              'winRate': 0,
              'lastEntryDate': null,
            },

            'gamification': {
              'level': 1,
              'experience': 0,
              'totalPoints': 0,
              'badges': {
                'collected': [],
                'totalUnlocked': 0,
              },
              'streaks': {
                'current': 0,
                'longest': 0,
                'lastCheckIn': null,
                'freezesAvailable': 0,
                'freezeUsedToday': false,
              },
            },
          },
          SetOptions(
            merge: false,
          ),
        ); // Don't merge, overwrite for clean demo state

        // Navigate to onboarding for demo users
        if (context.mounted) {
          // Import needed at top of file
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const PrizePreferencesScreen(),
            ),
            (route) => false,
          );
        }
      }
    } catch (e) {
      logger.e('Demo sign in failed', error: e);
      rethrow;
    }
  }

  /// Signs in the user using their Google account.
  ///
  /// This method initiates the Google sign-in flow, allowing users to
  /// authenticate with their Google credentials.
  ///
  /// @param context The BuildContext of the current widget tree.
  /// @throws [FirebaseAuthException] if the Google sign-in fails.
  /// @throws [Exception] for other unexpected errors during the process.
  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      // Get secure client ID from configuration
      final clientId = SecureConfig.googleSignInClientId;

      // Create GoogleSignIn instance with secure serverClientId
      final googleSignIn = GoogleSignIn(
        clientId: clientId,
        scopes: ['email', 'profile'],
      );

      // Trigger the authentication flow using signIn()
      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in flow
        throw Exception('Google sign-in was cancelled by user');
      }

      // Get the authentication details
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Failed to get ID token from Google');
      }

      // Create a new credential (Firebase Auth only needs idToken for Google)
      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
      );

      // Once signed in, return the UserCredential
      final userCredential = await _auth.signInWithCredential(credential);

      // Create or update user profile with Google info
      await _createOrUpdateUserProfile(
        userCredential.user!,
        displayName: googleUser.displayName,
        email: googleUser.email,
        photoURL: googleUser.photoUrl,
        provider: 'google.com',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully signed in with Google!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      logger.e('Error with Google sign-in', error: e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      rethrow;
    }
  }

  /// Signs in the user using their Apple account.
  ///
  /// This method initiates the Apple sign-in flow, allowing users to
  /// authenticate with their Apple ID.
  ///
  /// @param context The BuildContext of the current widget tree.
  /// @throws [FirebaseAuthException] if the Apple sign-in fails.
  /// @throws [Exception] for other unexpected errors during the process.
  Future<void> signInWithApple(BuildContext context) async {
    try {
      // Check if Apple Sign In is available
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        throw Exception('Apple Sign-In is not available on this device');
      }

      // Generate state parameter for CSRF protection
      final state = _generateNonce();
      await _secureStorage.write(key: 'apple_signin_state', value: state);

      // Request credential for the user with state parameter
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        state: state,
      );

      // Verify state parameter to prevent CSRF attacks
      final storedState = await _secureStorage.read(key: 'apple_signin_state');
      if (storedState != state) {
        await _secureStorage.delete(key: 'apple_signin_state');
        throw Exception('CSRF Attack Detected!');
      }
      await _secureStorage.delete(key: 'apple_signin_state');

      // Create an `OAuthCredential` from the credential returned by Apple.
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in the user with Firebase
      final userCredential = await _auth.signInWithCredential(oauthCredential);

      String? displayName;
      if (appleCredential.givenName != null &&
          appleCredential.familyName != null) {
        final sanitizedGivenName = _sanitizeInput(appleCredential.givenName!);
        final sanitizedFamilyName = _sanitizeInput(appleCredential.familyName!);
        displayName = '$sanitizedGivenName $sanitizedFamilyName';
        await userCredential.user?.updateDisplayName(displayName);
      }

      await _createOrUpdateUserProfile(
        userCredential.user!,
        displayName: displayName ?? userCredential.user?.displayName,
        email: appleCredential.email ?? userCredential.user?.email,
        provider: 'apple.com',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully signed in with Apple!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      logger.e('Error with Apple sign-in', error: e);
      rethrow;
    }
  }

  String _generateNonce([int length = 32]) {
    final random = Random.secure();
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  String _sanitizeInput(String input) {
    // Remove HTML tags and special characters to prevent XSS
    var sanitized = input.replaceAll(RegExp('<[^>]*>'), '');
    sanitized = sanitized.replaceAll(RegExp(r'[^\w\s]+'), '');
    return sanitized.trim();
  }

  /// Verifies the user's phone number and sends a One-Time Password (OTP) via SMS.
  ///
  /// This method initiates the phone number verification process, sending an OTP
  /// to the provided phone number. The user must then enter the OTP to complete
  /// the verification.
  ///
  /// @param phoneNumber The phone number to verify. Must be a valid phone number format.
  /// @param context The BuildContext of the current widget tree.
  /// @throws [FirebaseAuthException] if the phone number verification fails.
  /// @throws [Exception] for other unexpected errors during the process.
  Future<void> verifyPhoneNumber(
    String phoneNumber,
    BuildContext context,
  ) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (credential) async {
          // Auto-retrieval or instant verification
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Phone number verification failed: ${e.message}'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        codeSent: (verificationId, resendToken) {
          // Navigate to OTP screen
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OTPScreen(verificationId: verificationId),
              ),
            );
          }
        },
        codeAutoRetrievalTimeout: (verificationId) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Auto retrieval timed out. Please enter the code manually.',
                ),
                backgroundColor: AppColors.warning,
              ),
            );
          }
        },
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error verifying phone number: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Signs in the user using a verified phone number and the received OTP.
  ///
  /// This method completes the phone number sign-in process after the user
  /// has entered the OTP.
  ///
  /// @param verificationId The verification ID received after calling [verifyPhoneNumber].
  /// @param smsCode The OTP (SMS code) entered by the user.
  /// @param context The BuildContext of the current widget tree.
  /// @throws [FirebaseAuthException] if the sign-in fails.
  /// @throws [Exception] for other unexpected errors during the process.
  Future<void> signInWithPhoneNumber(
    String verificationId,
    String smsCode,
    BuildContext context,
  ) async {
    try {
      final AuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        await _createOrUpdateUserProfile(
          userCredential.user!,
          provider: 'phone',
        );

        // Navigate to prize preferences screen
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const PrizePreferencesScreen(),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing in with phone number: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Retrieves the user's profile data.
  ///
  /// This method fetches the user's profile information from Firestore.
  ///
  /// @returns A [Map<String, dynamic>] containing the user's profile data,
  /// or `null` if the user is not signed in or the profile data is not found.
  /// @throws [Exception] if there's an error retrieving the profile data.
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      if (currentUser != null) {
        final doc =
            await _firestore.collection('users').doc(currentUser!.uid).get();
        return doc.data();
      }
      return null;
    } catch (e) {
      logger.e('Error fetching user profile', error: e);
      return null;
    }
  }

  /// Updates the user's profile data.
  ///
  /// This method updates the user's profile information in Firestore.
  ///
  /// @param profileData A [Map<String, dynamic>] containing the profile data to update.
  /// @throws [Exception] if there's an error updating the profile data.
  Future<void> updateUserProfile(Map<String, dynamic> profileData) async {
    try {
      if (currentUser != null) {
        await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .update(profileData);
      }
    } catch (e) {
      logger.e('Error updating user profile', error: e);
      rethrow;
    }
  }

  /// Updates the user's preferences.
  ///
  /// This method updates the user's preference settings in Firestore.
  ///
  /// @param preferences A [Map<String, dynamic>] containing the preferences to update.
  /// @throws [Exception] if there's an error updating the preferences.
  Future<void> updateUserPreferences(Map<String, dynamic> preferences) async {
    try {
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser!.uid).update({
          'preferences': preferences,
        });
      }
    } catch (e) {
      logger.e('Error updating user preferences', error: e);
      rethrow;
    }
  }

  /// Stores an authentication token securely.
  ///
  /// This method stores the authentication token in secure storage for
  /// potential refresh token usage.
  ///
  /// @param token The authentication token to store.
  Future<void> storeAuthToken(String token) async {
    await _secureStorage.write(key: 'authToken', value: token);
  }

  /// Retrieves the stored authentication token.
  ///
  /// This method retrieves the authentication token from secure storage.
  ///
  /// @returns The stored authentication token, or `null` if no token is stored.
  Future<String?> getAuthToken() async => _secureStorage.read(key: 'authToken');

  /// Deletes the stored authentication token.
  ///
  /// This method removes the authentication token from secure storage.
  Future<void> deleteAuthToken() async {
    await _secureStorage.delete(key: 'authToken');
  }

  // Add a method to update sweepstake entry
  Future<void> addSweepstakeEntry(
    String sweepstakeId,
    Map<String, dynamic> entryData,
  ) async {
    try {
      // Validate inputs
      if (currentUser == null) {
        throw const AuthenticationError(
            'User must be logged in to enter sweepstakes');
      }

      if (sweepstakeId.isEmpty) {
        throw const ValidationError('Sweepstake ID is required');
      }

      final entry = {
        'sweepstakeId': sweepstakeId,
        'entryDate': FieldValue.serverTimestamp(),
        'status': 'active', // active, won, lost, expired
        ...entryData,
      };

      // Update user document with entry
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'sweepstakes.entries': FieldValue.arrayUnion([entry]),
        'stats.totalEntries': FieldValue.increment(1),
        'stats.activeEntries': FieldValue.increment(1),
        'lastActivity': FieldValue.serverTimestamp(),
      });

      logger.i(
          'Sweepstake entry added successfully. userId: ${currentUser!.uid}, sweepstakeId: $sweepstakeId');

      // After successfully adding an entry, check for "Entry Enthusiast" badge
      try {
        await _gamificationService
            .checkAndAwardEntryEnthusiast(currentUser!.uid);
      } catch (e) {
        // Don't fail the entry if gamification fails
        logger.w('Gamification service failed after entry', error: e);
      }
    } on FirebaseException catch (e) {
      logger.e('Firebase error adding sweepstake entry', error: e);
      throw FirestoreError(
        'Failed to record your entry. Please try again.',
        rawError: e,
        context: 'addSweepstakeEntry',
      );
    } catch (e) {
      logger.e('Unexpected error adding sweepstake entry', error: e);
      throw AppError.fromException(
        e,
        context: 'addSweepstakeEntry',
        customMessage: 'Failed to enter sweepstake. Please try again.',
      );
    }
  }

  // Add a method to update subscription status
  Future<void> updateSubscriptionStatus({
    required String status,
    required String plan,
    DateTime? endDate,
    bool autoRenew = false,
  }) async {
    try {
      // Validate inputs
      if (currentUser == null) {
        throw const AuthenticationError(
            'User must be logged in to update subscription');
      }

      if (status.isEmpty || plan.isEmpty) {
        throw const ValidationError(
            'Subscription status and plan are required');
      }

      // Validate status values
      const validStatuses = ['trial', 'active', 'expired', 'cancelled'];
      if (!validStatuses.contains(status)) {
        throw ValidationError('Invalid subscription status: $status');
      }

      // Validate plan values
      const validPlans = ['free', 'basic', 'premium'];
      if (!validPlans.contains(plan)) {
        throw ValidationError('Invalid subscription plan: $plan');
      }

      await _firestore.collection('users').doc(currentUser!.uid).update({
        'subscription.status': status,
        'subscription.plan': plan,
        'subscription.endDate': endDate,
        'subscription.autoRenew': autoRenew,
        'lastActivity': FieldValue.serverTimestamp(),
      });

      logger.i(
          'Subscription status updated successfully. userId: ${currentUser!.uid}, status: $status, plan: $plan');
    } on FirebaseException catch (e) {
      logger.e('Firebase error updating subscription status', error: e);
      throw FirestoreError(
        'Failed to update subscription. Please try again.',
        rawError: e,
        context: 'updateSubscriptionStatus',
      );
    } catch (e) {
      logger.e('Unexpected error updating subscription status', error: e);
      throw AppError.fromException(
        e,
        context: 'updateSubscriptionStatus',
        customMessage: 'Failed to update subscription. Please try again.',
      );
    }
  }

  // Add a method to record a win
  Future<void> recordWin(
    String sweepstakeId,
    Map<String, dynamic> winData,
  ) async {
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
  Future<void> addPoints(
    int amount,
    String reason, {
    String? referenceId,
    String? userIdOverride,
  }) async {
    try {
      // Validate inputs
      if (amount <= 0) {
        throw const ValidationError('Points amount must be positive');
      }

      if (reason.isEmpty) {
        throw const ValidationError('Reason for points is required');
      }

      // Allow overriding userId for referral processing
      final targetUserId = userIdOverride ?? currentUser?.uid;
      if (targetUserId == null) {
        throw const AuthenticationError('User must be logged in to add points');
      }

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

      logger.i(
          'Points added successfully. targetUserId: $targetUserId, amount: $amount, reason: $reason');

      // Check for level up, only for the current user, not the referred user if userIdOverride is used.
      if (userIdOverride == null || userIdOverride == currentUser?.uid) {
        try {
          await _checkLevelUp();
        } catch (e) {
          // Don't fail points addition if level up check fails
          logger.w('Level up check failed after adding points', error: e);
        }
      }
    } on FirebaseException catch (e) {
      logger.e('Firebase error adding points', error: e);
      throw FirestoreError(
        'Failed to add points. Please try again.',
        rawError: e,
        context: 'addPoints',
      );
    } catch (e) {
      logger.e('Unexpected error adding points', error: e);
      throw AppError.fromException(
        e,
        context: 'addPoints',
        customMessage: 'Failed to add points. Please try again.',
      );
    }
  }

  // Spend points
  Future<void> spendPoints(
    int amount,
    String reason, {
    String? referenceId,
  }) async {
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
  Future<void> unlockAchievement(
    String achievementId, {
    int progress = 100,
  }) async {
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
    const points = 10;
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
      logger.e('Error checking admin status', error: e);
      return false;
    }
  }

  // Register with email and password
  Future<void> registerWithEmail(
    String email,
    String password,
    String displayName,
    Map<String, dynamic> userProfile,
    String? referralCode,
  ) async {
    try {
      // Create Firebase Auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('User creation failed');
      }

      // Update the user's display name
      await user.updateDisplayName(displayName);

      // Create user profile with additional data
      await _createOrUpdateUserProfile(
        user,
        displayName: displayName,
        email: email,
        provider: 'email',
        referredByCode: referralCode,
        additionalData: userProfile,
      );
    } catch (e) {
      logger.e('Error registering with email', error: e);
      rethrow;
    }
  }

  /// Signs out the current user.
  ///
  /// This method signs out the currently authenticated user, clearing their
  /// authentication state.
  ///
  /// @throws [FirebaseAuthException] if the sign-out fails.
  /// @throws [Exception] for other unexpected errors during the process.
  Future<void> signOut() async {
    try {
      // await _googleSignIn.signOut(); // Temporarily disabled - using fallback
      await _auth.signOut();
      await deleteAuthToken();
    } catch (e) {
      logger.e('Error signing out', error: e);
      rethrow;
    }
  }

  Future<void> _handleSuccessfulSignIn(
    BuildContext context,
    UserCredential userCredential,
  ) async {
    if (userCredential.user != null) {
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _createOrUpdateUserProfile(userCredential.user!);
      }
      await _notificationService.saveTokenToDatabase(userCredential.user!.uid);
      // After any successful sign in, prompt to enable biometrics
      await _promptToEnableBiometrics(context, userCredential.user!.email!);
    }
  }

  Future<void> deleteAccount() async {
    // Implement account deletion logic here
    // This might involve deleting user data from Firestore and then deleting the auth user.
  }

  /// Checks if biometric authentication is available on the device.
  Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }

  /// Attempts to sign in the user using biometric authentication.
  Future<bool> signInWithBiometrics() async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) return false;

      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to sign in to SweepFeed',
        options: const AuthenticationOptions(biometricOnly: true),
      );

      if (isAuthenticated) {
        final email = await _secureStorage.read(key: 'biometric_email');
        final token = await _secureStorage.read(
          key: 'biometric_token',
        ); // Example: using a refresh token

        if (email != null && token != null) {
          // Here, you would use the token to re-authenticate with Firebase.
          // This is a placeholder for the actual re-authentication logic.
          return true;
        }
      }
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// Shows a dialog prompting the user to enable biometric login for the future.
  Future<void> _promptToEnableBiometrics(
    BuildContext context,
    String email,
  ) async {
    final isAvailable = await isBiometricAvailable();
    if (isAvailable && context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Enable Biometric Sign-In?'),
          content: const Text(
            'Would you like to use your fingerprint or Face ID to sign in next time?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('No, thanks'),
            ),
            TextButton(
              onPressed: () async {
                // Save credentials to secure storage
                await _secureStorage.write(
                  key: 'biometric_email',
                  value: email,
                );
                await _secureStorage.write(
                  key: 'biometric_token',
                  value: await _auth.currentUser!.getIdToken(),
                ); // Example
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Biometric sign-in enabled!')),
                );
              },
              child: const Text('Enable'),
            ),
          ],
        ),
      );
    }
  }
}
