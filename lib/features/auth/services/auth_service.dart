import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';

enum AuthState {
  authenticated,
  unauthenticated,
  onboarding,
  loading,
  error,
}

class AuthService {
  AuthService(this._ref) {
    _authStateChangesSubscription =
        _ref.read(firebaseAuthProvider).authStateChanges().listen((user) {
      _user = user;
      _updateAuthState();
    });
  }

  final Ref _ref;
  User? _user;
  late final StreamSubscription<User?> _authStateChangesSubscription;
  
  User? get currentUser => _user;

  final StateController<AuthState> _authStateController =
      StateController(AuthState.loading);

  Stream<AuthState> get authState => _authStateController.stream;

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

      if (userDoc.exists) {
        final userData = userDoc.data();
        final onboardingCompleted =
            userData?['onboardingCompleted'] as bool? ?? false;
        if (onboardingCompleted) {
          _authStateController.state = AuthState.authenticated;
        } else {
          _authStateController.state = AuthState.onboarding;
        }
      } else {
        _authStateController.state = AuthState.onboarding;
      }
    } catch (e) {
      _authStateController.state = AuthState.error;
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