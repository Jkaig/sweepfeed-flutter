import 'package:cloud_firestore/cloud_firestore.dart';
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
        _ref.read(authStateChangesProvider).listen((user) {
      _user = user;
      _updateAuthState();
    });
  }

  final Ref _ref;
  User? _user;
  late final StreamSubscription<User?> _authStateChangesSubscription;

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
        final userData = userDoc.data() as Map<String, dynamic>?;
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