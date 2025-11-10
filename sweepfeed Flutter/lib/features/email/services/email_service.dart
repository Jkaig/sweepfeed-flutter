import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/email_message.dart';

/// Service for managing email inbox functionality for Premium users
class EmailService with ChangeNotifier {
  EmailService(this._ref);

  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Email settings cache
  EmailSettings? _cachedSettings;
  DateTime? _settingsLastUpdated;
  static const Duration _cacheTimeout = Duration(minutes: 5);

  /// Get emails stream for the current user, optionally filtered by category
  Stream<List<EmailMessage>> getEmailsStream({
    EmailCategory? category,
    int limit = 50,
    bool unreadOnly = false,
  }) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    Query query = _firestore
        .collection('users')
        .doc(userId)
        .collection('emails')
        .orderBy('timestamp', descending: true);

    // Apply category filter if specified
    if (category != null) {
      query = query.where('category', isEqualTo: category.name);
    }

    // Apply unread filter if specified
    if (unreadOnly) {
      query = query.where('isRead', isEqualTo: false);
    }

    // Apply limit
    query = query.limit(limit);

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => EmailMessage.fromFirestore(doc)).toList());
  }

  /// Get unread count for a specific category
  Stream<int> getUnreadCountStream({EmailCategory? category}) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value(0);
    }

    Query query = _firestore
        .collection('users')
        .doc(userId)
        .collection('emails')
        .where('isRead', isEqualTo: false);

    if (category != null) {
      query = query.where('category', isEqualTo: category.name);
    }

    return query.snapshots().map((snapshot) => snapshot.docs.length);
  }

  /// Get total unread count across all categories
  Stream<int> getTotalUnreadCountStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('emails')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark email as read/unread
  Future<void> markAsRead(String emailId, {bool isRead = true}) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('emails')
          .doc(emailId)
          .update({'isRead': isRead});

      await _trackEmailAction('mark_as_${isRead ? 'read' : 'unread'}', {
        'email_id': emailId,
      });
    } catch (e) {
      debugPrint('Error marking email as read: $e');
      rethrow;
    }
  }

  /// Mark multiple emails as read/unread
  Future<void> markMultipleAsRead(List<String> emailIds,
      {bool isRead = true}) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final batch = _firestore.batch();
      for (final emailId in emailIds) {
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('emails')
            .doc(emailId);
        batch.update(docRef, {'isRead': isRead});
      }

      await batch.commit();

      await _trackEmailAction('bulk_mark_as_${isRead ? 'read' : 'unread'}', {
        'email_count': emailIds.length,
      });
    } catch (e) {
      debugPrint('Error marking multiple emails as read: $e');
      rethrow;
    }
  }

  /// Star/unstar email
  Future<void> toggleStar(String emailId, {required bool isStarred}) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('emails')
          .doc(emailId)
          .update({'isStarred': isStarred});

      await _trackEmailAction('toggle_star', {
        'email_id': emailId,
        'starred': isStarred,
      });
    } catch (e) {
      debugPrint('Error toggling star: $e');
      rethrow;
    }
  }

  /// Delete email
  Future<void> deleteEmail(String emailId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('emails')
          .doc(emailId)
          .delete();

      await _trackEmailAction('delete_email', {
        'email_id': emailId,
      });
    } catch (e) {
      debugPrint('Error deleting email: $e');
      rethrow;
    }
  }

  /// Delete multiple emails
  Future<void> deleteMultipleEmails(List<String> emailIds) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final batch = _firestore.batch();
      for (final emailId in emailIds) {
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('emails')
            .doc(emailId);
        batch.delete(docRef);
      }

      await batch.commit();

      await _trackEmailAction('bulk_delete', {
        'email_count': emailIds.length,
      });
    } catch (e) {
      debugPrint('Error deleting multiple emails: $e');
      rethrow;
    }
  }

  /// Search emails by subject, sender, or content
  Future<List<EmailMessage>> searchEmails(
    String query, {
    EmailCategory? category,
    int limit = 20,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      // Note: Firestore doesn't support full-text search natively
      // This is a simplified search implementation
      // For production, consider using Algolia or Elasticsearch

      Query firestoreQuery = _firestore
          .collection('users')
          .doc(userId)
          .collection('emails')
          .orderBy('timestamp', descending: true)
          .limit(limit * 3); // Get more to filter locally

      if (category != null) {
        firestoreQuery =
            firestoreQuery.where('category', isEqualTo: category.name);
      }

      final snapshot = await firestoreQuery.get();
      final allEmails =
          snapshot.docs.map((doc) => EmailMessage.fromFirestore(doc)).toList();

      // Filter emails locally based on search query
      final searchTerms = query.toLowerCase().split(' ');
      final filteredEmails = allEmails
          .where((email) {
            final searchableText =
                '${email.subject} ${email.from} ${email.body}'.toLowerCase();

            return searchTerms.every((term) => searchableText.contains(term));
          })
          .take(limit)
          .toList();

      await _trackEmailAction('search', {
        'query': query,
        'results_count': filteredEmails.length,
        'category': category?.name,
      });

      return filteredEmails;
    } catch (e) {
      debugPrint('Error searching emails: $e');
      return [];
    }
  }

  /// Add new email to user's inbox (typically called from email processing service)
  Future<void> addEmail(EmailMessage email) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Auto-categorize if enabled
      final settings = await getEmailSettings();
      EmailMessage processedEmail = email;

      if (settings.autoCategorizeEmails) {
        processedEmail = await _categorizeEmail(email);
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('emails')
          .doc(email.id)
          .set(processedEmail.toFirestore());

      await _trackEmailAction('email_received', {
        'category': processedEmail.category.name,
        'auto_categorized': settings.autoCategorizeEmails,
      });

      // Send notification if enabled
      if (settings.enablePushNotifications) {
        await _sendEmailNotification(processedEmail, settings);
      }
    } catch (e) {
      debugPrint('Error adding email: $e');
      rethrow;
    }
  }

  /// Get email settings for the current user
  Future<EmailSettings> getEmailSettings() async {
    try {
      // Check cache first
      if (_cachedSettings != null &&
          _settingsLastUpdated != null &&
          DateTime.now().difference(_settingsLastUpdated!) < _cacheTimeout) {
        return _cachedSettings!;
      }

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return const EmailSettings(); // Default settings
      }

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('email')
          .get();

      final settings = doc.exists
          ? EmailSettings.fromFirestore(doc.data()!)
          : const EmailSettings();

      // Update cache
      _cachedSettings = settings;
      _settingsLastUpdated = DateTime.now();

      return settings;
    } catch (e) {
      debugPrint('Error getting email settings: $e');
      return const EmailSettings(); // Return default settings on error
    }
  }

  /// Update email settings
  Future<void> updateEmailSettings(EmailSettings settings) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('email')
          .set(settings.toFirestore(), SetOptions(merge: true));

      // Update cache
      _cachedSettings = settings;
      _settingsLastUpdated = DateTime.now();

      await _trackEmailAction('settings_updated', {
        'show_promos': settings.showPromotionalEmails,
        'winner_only_notifications': settings.notifyOnWinnerEmailsOnly,
        'auto_categorize': settings.autoCategorizeEmails,
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating email settings: $e');
      rethrow;
    }
  }

  /// Generate user's SweepFeed email address
  String generateSweepFeedEmailAddress(String userId) {
    // Create a unique, readable email address
    // Format: user123@sweepfeed.com
    final cleanUserId = userId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final shortId =
        cleanUserId.length > 8 ? cleanUserId.substring(0, 8) : cleanUserId;

    return 'user$shortId@sweepfeed.com';
  }

  /// Get user's SweepFeed email address
  Future<String> getUserSweepFeedEmail() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return '';

    final settings = await getEmailSettings();
    if (settings.forwardingAddress != null) {
      return settings.forwardingAddress!;
    }

    return generateSweepFeedEmailAddress(userId);
  }

  /// Private helper methods

  /// Automatically categorize email based on content analysis
  Future<EmailMessage> _categorizeEmail(EmailMessage email) async {
    try {
      final category = _analyzeEmailCategory(email);

      // Extract additional metadata based on category
      final extractedData = _extractEmailMetadata(email, category);

      return email.copyWith(
        category: category,
        sweepstakesName: extractedData['sweepstakesName'],
        prizeValue: extractedData['prizeValue'],
        entryDeadline: extractedData['entryDeadline'],
        importance: extractedData['importance'] ?? email.importance,
      );
    } catch (e) {
      debugPrint('Error categorizing email: $e');
      return email; // Return original email if categorization fails
    }
  }

  /// Analyze email content to determine category
  EmailCategory _analyzeEmailCategory(EmailMessage email) {
    final subject = email.subject.toLowerCase();
    final body = email.body.toLowerCase();
    final sender = email.from.toLowerCase();

    // Winner email patterns
    final winnerPatterns = [
      'congratulations',
      'you won',
      'you\'re a winner',
      'winner',
      'prize',
      'you have won',
      'claiming your prize',
      'prize notification',
      'sweepstakes winner',
      'contest winner',
      'lucky winner',
      'grand prize',
      'first place',
      'winning entry',
    ];

    // Promotional email patterns
    final promoPatterns = [
      'enter now',
      'limited time',
      'enter to win',
      'sweepstakes',
      'giveaway',
      'contest',
      'prize drawing',
      'enter today',
      'last chance',
      'deadline',
      'expires',
      'register now',
      'sign up',
      'promotional',
      'special offer',
      'exclusive',
    ];

    // Check for winner patterns first (higher priority)
    for (final pattern in winnerPatterns) {
      if (subject.contains(pattern) || body.contains(pattern)) {
        return EmailCategory.winner;
      }
    }

    // Check for promotional patterns
    for (final pattern in promoPatterns) {
      if (subject.contains(pattern) || body.contains(pattern)) {
        return EmailCategory.promo;
      }
    }

    // Check sender domains for known sweepstakes companies
    final knownSweepstakesDomains = [
      'sweepstakes',
      'contest',
      'giveaway',
      'prize',
      'lottery',
      'drawing',
      'instant',
      'promotion',
    ];

    for (final domain in knownSweepstakesDomains) {
      if (sender.contains(domain)) {
        return EmailCategory.promo;
      }
    }

    return EmailCategory.general;
  }

  /// Extract metadata from email based on category
  Map<String, dynamic> _extractEmailMetadata(
      EmailMessage email, EmailCategory category) {
    final metadata = <String, dynamic>{};

    switch (category) {
      case EmailCategory.winner:
        metadata['importance'] = EmailImportance.high;
        metadata['prizeValue'] = _extractPrizeValue(email);
        metadata['sweepstakesName'] = _extractSweepstakesName(email);
        break;

      case EmailCategory.promo:
        metadata['entryDeadline'] = _extractDeadline(email);
        metadata['sweepstakesName'] = _extractSweepstakesName(email);
        break;

      case EmailCategory.general:
        // No special metadata for general emails
        break;
    }

    return metadata;
  }

  /// Extract prize value from winner emails
  String? _extractPrizeValue(EmailMessage email) {
    final text = '${email.subject} ${email.body}';

    // Patterns for prize values
    final patterns = [
      RegExp(r'\$([0-9,]+(?:\.[0-9]{2})?)', caseSensitive: false),
      RegExp(r'([0-9,]+(?:\.[0-9]{2})?) dollars?', caseSensitive: false),
      RegExp(r'worth \$?([0-9,]+(?:\.[0-9]{2})?)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return '\$${match.group(1)}';
      }
    }

    return null;
  }

  /// Extract sweepstakes name from email
  String? _extractSweepstakesName(EmailMessage email) {
    final subject = email.subject;

    // Try to extract sweepstakes name from subject
    // This is a simplified implementation
    final patterns = [
      RegExp(r'(.+?) sweepstakes', caseSensitive: false),
      RegExp(r'(.+?) giveaway', caseSensitive: false),
      RegExp(r'(.+?) contest', caseSensitive: false),
      RegExp(r'win (.+?) prize', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(subject);
      if (match != null) {
        return match.group(1)?.trim();
      }
    }

    return null;
  }

  /// Extract entry deadline from promotional emails
  DateTime? _extractDeadline(EmailMessage email) {
    final text = '${email.subject} ${email.body}';

    // This is a simplified implementation
    // In production, you'd want more sophisticated date extraction
    final patterns = [
      RegExp(r'deadline:?\s*([^.!]+)', caseSensitive: false),
      RegExp(r'expires?:?\s*([^.!]+)', caseSensitive: false),
      RegExp(r'ends?:?\s*([^.!]+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        // Try to parse the extracted date string
        // This would need more sophisticated date parsing in production
        return _parseFlexibleDate(match.group(1)?.trim());
      }
    }

    return null;
  }

  /// Parse various date formats
  DateTime? _parseFlexibleDate(String? dateString) {
    if (dateString == null) return null;

    try {
      // This is a simplified date parser
      // In production, use a more robust date parsing library
      return DateTime.tryParse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Send push notification for new email
  Future<void> _sendEmailNotification(
      EmailMessage email, EmailSettings settings) async {
    try {
      // Only send notification if conditions are met
      if (settings.notifyOnWinnerEmailsOnly &&
          email.category != EmailCategory.winner) {
        return;
      }

      // Don't notify for promotional emails if user disabled them
      if (!settings.showPromotionalEmails &&
          email.category == EmailCategory.promo) {
        return;
      }

      // TODO: Implement push notification logic
      // This would integrate with Firebase Cloud Messaging or similar service
      debugPrint('Would send notification for email: ${email.subject}');
    } catch (e) {
      debugPrint('Error sending email notification: $e');
    }
  }

  /// Track email-related analytics
  Future<void> _trackEmailAction(
      String action, Map<String, dynamic> properties) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore.collection('analytics').doc().set({
        'userId': userId,
        'event': 'email_$action',
        'properties': properties,
        'timestamp': FieldValue.serverTimestamp(),
        'feature': 'email_inbox',
      });
    } catch (e) {
      debugPrint('Error tracking email action: $e');
    }
  }
}

/// Provider for EmailService
final emailServiceProvider = ChangeNotifierProvider<EmailService>((ref) {
  return EmailService(ref);
});

/// Provider for email settings
final emailSettingsProvider = FutureProvider<EmailSettings>((ref) async {
  final emailService = ref.watch(emailServiceProvider);
  return await emailService.getEmailSettings();
});

/// Provider for user's SweepFeed email address
final userSweepFeedEmailProvider = FutureProvider<String>((ref) async {
  final emailService = ref.watch(emailServiceProvider);
  return await emailService.getUserSweepFeedEmail();
});

/// Provider for total unread email count
final totalUnreadEmailCountProvider = StreamProvider<int>((ref) {
  final emailService = ref.watch(emailServiceProvider);
  return emailService.getTotalUnreadCountStream();
});

/// Provider for emails stream with category filter
final emailsStreamProvider =
    StreamProvider.family<List<EmailMessage>, EmailCategory?>((ref, category) {
  final emailService = ref.watch(emailServiceProvider);
  return emailService.getEmailsStream(category: category);
});

/// Provider for unread count by category
final unreadCountProvider =
    StreamProvider.family<int, EmailCategory?>((ref, category) {
  final emailService = ref.watch(emailServiceProvider);
  return emailService.getUnreadCountStream(category: category);
});
