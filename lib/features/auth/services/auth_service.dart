import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/utils/logger.dart';

enum AuthState {
  authenticated,
  unauthenticated,
  onboarding,
  loading,
  error,
}

class AuthService {
  AuthService(this._ref) {
    // Listen to auth state changes and update accordingly
    _authStateChangesSubscription =
        _ref.read(firebaseAuthProvider).authStateChanges().listen((user) {
      _user = user;
      _updateAuthState();
    });
    
    // Also check initial state if user is already logged in
    final currentUser = _ref.read(firebaseAuthProvider).currentUser;
    if (currentUser != null) {
      _user = currentUser;
      _updateAuthState();
    }
  }

  final Ref _ref;
  User? _user;
  late final StreamSubscription<User?> _authStateChangesSubscription;
  
  User? get currentUser => _user;

  final StateController<AuthState> _authStateController =
      StateController(AuthState.loading);

  Stream<AuthState> get authState => _authStateController.stream;

  /// Manually refresh the auth state (useful after onboarding completion)
  Future<void> refreshAuthState() async {
    await _updateAuthState();
  }

  Future<void> _updateAuthState() async {
    if (_user == null) {
      _authStateController.state = AuthState.unauthenticated;
      return;
    }

    try {
      final userDoc = await _ref
          .read(firestoreProvider)
          .collection('users')
          .doc(_user!.uid)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data()!;
        // Check onboardingCompleted field - default to false if not set
        final onboardingCompleted = userData['onboardingCompleted'] as bool? ?? false;
        
        if (onboardingCompleted) {
          _authStateController.state = AuthState.authenticated;
        } else {
          // User exists but onboarding not completed
          _authStateController.state = AuthState.onboarding;
        }
      } else {
        // User document doesn't exist yet - they need onboarding
        _authStateController.state = AuthState.onboarding;
      }
    } catch (e) {
      // On error, default to authenticated to prevent onboarding loop
      // But log the error for debugging
      logger.w('Error checking auth state, defaulting to authenticated: $e');
      _authStateController.state = AuthState.authenticated;
    }
  }

  Future<void> signOut() async {
    await _ref.read(firebaseAuthProvider).signOut();
  }

  Future<void> signInWithGoogle(context) async {
    // proportional implementation
    try {
      final googleProvider = GoogleAuthProvider();
      await _ref.read(firebaseAuthProvider).signInWithProvider(googleProvider);
    } catch (e) {
      // Handle error
      rethrow;
    }
  }

  Future<void> signInWithApple(context) async {
     try {
      final appleProvider = AppleAuthProvider();
      await _ref.read(firebaseAuthProvider).signInWithProvider(appleProvider);
    } catch (e) {
      // Handle error
      rethrow;
    }
  }

  Future<void> sendSignInLinkToEmail(String email, context) async {
     try {
      var acs = ActionCodeSettings(
        url: 'https://sweepfeed.page.link/email-login',
        handleCodeInApp: true,
        iOSBundleId: 'com.sweepfeed.app',
        androidPackageName: 'com.sweepfeed.app',
        androidInstallApp: true,
        androidMinimumVersion: '12',
      );
      await _ref.read(firebaseAuthProvider).sendSignInLinkToEmail(
        email: email, 
        actionCodeSettings: acs
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> linkPhoneNumberForBackup(String phone, context) async {
    // Implementation for phone linking
  }

  void dispose() {
    _authStateChangesSubscription.cancel();
    _authStateController.dispose();
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  final authService = AuthService(ref);
  ref.onDispose(() => authService.dispose());
  return authService;
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).authState;
});