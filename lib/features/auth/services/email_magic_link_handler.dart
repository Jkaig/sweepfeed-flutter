import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/navigation/navigator_key.dart';
import '../../../core/utils/logger.dart';
import 'auth_service.dart';

/// Handles email magic link authentication when the app is opened via deep link
class EmailMagicLinkHandler {

  // Factory constructor
  factory EmailMagicLinkHandler() => _instance;
  // Private constructor
  EmailMagicLinkHandler._internal();

  // Singleton instance
  static final EmailMagicLinkHandler _instance = EmailMagicLinkHandler._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();
  final AppLinks _appLinks = AppLinks();
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  StreamSubscription<Uri>? _linkSubscription;
  bool _isInitialized = false;

  /// Initializes the email magic link handler
  /// This should be called in main() or during app initialization
  Future<void> initialize(BuildContext? context) async {
    if (_isInitialized) return;

    try {
      // Check for initial link (when app is opened from a closed state)
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        await _handleLink(initialLink, context);
      }

      // Listen for links when app is already running
      _linkSubscription = _appLinks.uriLinkStream.listen(
        (uri) => _handleLink(uri, context),
        onError: (err) {
          logger.e('Error in email magic link stream', error: err);
        },
      );
      
      _isInitialized = true;
      logger.i('EmailMagicLinkHandler initialized');
    } catch (e) {
      logger.e('Error initializing email magic link handler', error: e);
    }
  }

  /// Handles a deep link URL
  Future<void> _handleLink(Uri uri, BuildContext? context) async {
    try {
      logger.i('Handling deep link: $uri');

      // Check if this is an email magic link
      final isEmailLink = _auth.isSignInWithEmailLink(uri.toString());
      
      if (isEmailLink) {
        logger.i('Detected email magic link');
        await _processEmailMagicLink(uri.toString(), context);
      } else {
        // Check if it's a Firebase Dynamic Link that contains an email link
        final emailLink = _extractEmailLinkFromDynamicLink(uri);
        if (emailLink != null) {
          logger.i('Extracted email link from dynamic link');
          await _processEmailMagicLink(emailLink, context);
        }
      }
    } catch (e) {
      logger.e('Error handling deep link', error: e);
      _showError(context, 'Error processing sign-in link: ${e.toString()}');
      
      await _analytics.logEvent(
        name: 'magic_link_error',
        parameters: {
          'error': e.toString(),
          'uri': uri.toString(),
        },
      );
    }
  }

  /// Extracts the email link from a Firebase Dynamic Link
  String? _extractEmailLinkFromDynamicLink(Uri uri) {
    try {
      // Firebase Dynamic Links often have the actual email link in query parameters
      // Common patterns:
      // - link parameter contains the actual email link
      // - oobCode and mode parameters for Firebase Auth
      
      final linkParam = uri.queryParameters['link'];
      if (linkParam != null) {
        final decodedLink = Uri.decodeComponent(linkParam);
        if (_auth.isSignInWithEmailLink(decodedLink)) {
          return decodedLink;
        }
      }

      // Check for direct oobCode (Firebase Auth email link parameter)
      final oobCode = uri.queryParameters['oobCode'];
      final mode = uri.queryParameters['mode'];
      
      if (oobCode != null && mode == 'signIn') {
        // Reconstruct the email link URL
        final emailLink = uri.replace(
          queryParameters: {
            'mode': mode,
            'oobCode': oobCode,
            ...uri.queryParameters,
          },
        ).toString();
        
        if (_auth.isSignInWithEmailLink(emailLink)) {
          return emailLink;
        }
      }

      // If the URI itself looks like an email link, use it directly
      if (_auth.isSignInWithEmailLink(uri.toString())) {
        return uri.toString();
      }

      return null;
    } catch (e) {
      logger.e('Error extracting email link from dynamic link', error: e);
      return null;
    }
  }

  /// Processes the email magic link and signs in the user
  Future<void> _processEmailMagicLink(
    String emailLink,
    BuildContext? context,
  ) async {
    try {
      final navContext = context ?? navigatorKey.currentContext;
      
      // Get the email from SharedPreferences (stored when link was sent)
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('pendingAuthEmail');
      final sentTime = prefs.getInt('magicLinkSentTime');

      if (email == null || email.isEmpty) {
        logger.w('No pending email found for magic link');
        _showError(navContext, 'No pending sign-in found. Please request a new sign-in link.');
        
        await _analytics.logEvent(
          name: 'magic_link_no_email',
        );
        return;
      }

      // Check expiration (e.g., 15 minutes)
      if (sentTime != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final diff = now - sentTime;
        if (diff > 15 * 60 * 1000) { // 15 minutes
           logger.w('Magic link expired');
           _showError(navContext, 'This sign-in link has expired. Please request a new one.');
           await _clearPendingAuth(prefs);
           
           await _analytics.logEvent(
             name: 'magic_link_expired',
             parameters: {'diff_minutes': diff / 60000},
           );
           return;
        }
      }

      logger.i('Processing email magic link for: $email');

      if (navContext == null) {
        logger.w('No context available for email magic link sign-in');
        return;
      }
      
      // Show loading indicator
      if (navContext.mounted) {
        showDialog(
          context: navContext,
          barrierDismissible: false,
          builder: (c) => const Center(child: CircularProgressIndicator()),
        );
      }

      // Sign in with the email link
      await _authService.signInWithEmailLink(
        email,
        emailLink,
        navContext,
      );

      // Clear the pending email after successful sign-in
      await _clearPendingAuth(prefs);

      // Dismiss loading indicator
      if (navContext.mounted) {
        Navigator.of(navContext).pop(); 
      }

      logger.i('Successfully signed in with email magic link');
      
      await _analytics.logLogin(loginMethod: 'email_link');
      
    } catch (e) {
      final navContext = context ?? navigatorKey.currentContext;
      // Dismiss loading indicator if open
      if (navContext != null && navContext.mounted) {
         Navigator.of(navContext).pop();
      }
      
      logger.e('Error processing email magic link', error: e);
      _showError(navContext, 'Sign-in failed. The link may be invalid or expired.');
      
      await _analytics.logEvent(
        name: 'magic_link_processing_error',
        parameters: {'error': e.toString()},
      );
    }
  }
  
  Future<void> _clearPendingAuth(SharedPreferences prefs) async {
    await prefs.remove('pendingAuthEmail');
    await prefs.remove('magicLinkSentTime');
  }

  void _showError(BuildContext? context, String message) {
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Disposes the handler and cancels subscriptions
  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    _isInitialized = false;
  }
}
