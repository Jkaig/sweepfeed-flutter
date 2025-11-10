import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Email categories for automatic organization in the SweepFeed email inbox.
enum EmailCategory {
  /// General emails that don't fit other categories.
  general,

  /// Promotional emails advertising sweepstakes and contests.
  promo,

  /// Winner notification emails for successful contest entries.
  winner,
}

/// Extension providing utility methods for [EmailCategory] enum.
extension EmailCategoryExtension on EmailCategory {
  /// Returns the string representation of the category for storage.
  String get name {
    switch (this) {
      case EmailCategory.general:
        return 'general';
      case EmailCategory.promo:
        return 'promo';
      case EmailCategory.winner:
        return 'winner';
    }
  }

  /// Returns the user-friendly display name for the category.
  String get displayName {
    switch (this) {
      case EmailCategory.general:
        return 'General';
      case EmailCategory.promo:
        return 'Promos';
      case EmailCategory.winner:
        return 'Winners';
    }
  }

  /// Converts a string value to the corresponding [EmailCategory].
  ///
  /// Matches are case-insensitive. Returns [EmailCategory.general] for 
  /// unrecognized values.
  static EmailCategory fromString(String value) {
    switch (value.toLowerCase()) {
      case 'promo':
        return EmailCategory.promo;
      case 'winner':
        return EmailCategory.winner;
      default:
        return EmailCategory.general;
    }
  }
}

/// Email message data model for SweepFeed Premium users
@immutable
class EmailMessage {
  const EmailMessage({
    required this.id,
    required this.from,
    required this.subject,
    required this.body,
    required this.category,
    required this.timestamp,
    this.isRead = false,
    this.hasAttachments = false,
    this.importance = EmailImportance.normal,
    this.originalSender,
    this.sweepstakesName,
    this.prizeValue,
    this.entryDeadline,
    this.isStarred = false,
    this.tags = const [],
  });

  /// Unique identifier for the email message.
  final String id;

  /// Sender's email address and name.
  final String from;

  /// Subject line of the email.
  final String subject;

  /// Body content of the email (may contain HTML).
  final String body;

  /// Automatically determined category for organization.
  final EmailCategory category;

  /// When the email was received.
  final DateTime timestamp;
  /// Whether the email has been read by the user.
  final bool isRead;

  /// Whether the email contains attachments.
  final bool hasAttachments;

  /// Priority level of the email.
  final EmailImportance importance;
  final String? originalSender; // Original sender if forwarded
  final String? sweepstakesName; // Extracted sweepstakes name if applicable
  final String? prizeValue; // Extracted prize value for winner emails
  final DateTime? entryDeadline; // Extracted deadline for promo emails
  /// Whether the user has starred this email.
  final bool isStarred;

  /// User-defined tags for custom organization.
  final List<String> tags;

  /// Create from Firestore document
  factory EmailMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EmailMessage(
      id: doc.id,
      from: data['from'] ?? '',
      subject: data['subject'] ?? '',
      body: data['body'] ?? '',
      category:
          EmailCategoryExtension.fromString(data['category'] ?? 'general'),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      hasAttachments: data['hasAttachments'] ?? false,
      importance:
          EmailImportanceExtension.fromString(data['importance'] ?? 'normal'),
      originalSender: data['originalSender'],
      sweepstakesName: data['sweepstakesName'],
      prizeValue: data['prizeValue'],
      entryDeadline: (data['entryDeadline'] as Timestamp?)?.toDate(),
      isStarred: data['isStarred'] ?? false,
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'from': from,
      'subject': subject,
      'body': body,
      'category': category.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'hasAttachments': hasAttachments,
      'importance': importance.name,
      'originalSender': originalSender,
      'sweepstakesName': sweepstakesName,
      'prizeValue': prizeValue,
      'entryDeadline':
          entryDeadline != null ? Timestamp.fromDate(entryDeadline!) : null,
      'isStarred': isStarred,
      'tags': tags,
    };
  }

  /// Get formatted preview text from body
  String get previewText {
    final cleanBody =
        body.replaceAll(RegExp(r'<[^>]*>'), ''); // Remove HTML tags
    if (cleanBody.length <= 100) return cleanBody;
    return '${cleanBody.substring(0, 100)}...';
  }

  /// Get display sender name (removes email format)
  String get displaySender {
    final regex = RegExp(r'^(.+?)\s*<.*>$');
    final match = regex.firstMatch(from);
    if (match != null) {
      return match.group(1)!.trim();
    }
    // If no name in email format, extract before @
    if (from.contains('@')) {
      return from.split('@')[0];
    }
    return from;
  }

  /// Check if email is from today
  bool get isFromToday {
    final now = DateTime.now();
    return timestamp.year == now.year &&
        timestamp.month == now.month &&
        timestamp.day == now.day;
  }

  /// Check if email is from this week
  bool get isFromThisWeek {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return timestamp.isAfter(weekAgo);
  }

  /// Copy with method for immutable updates
  EmailMessage copyWith({
    String? id,
    String? from,
    String? subject,
    String? body,
    EmailCategory? category,
    DateTime? timestamp,
    bool? isRead,
    bool? hasAttachments,
    EmailImportance? importance,
    String? originalSender,
    String? sweepstakesName,
    String? prizeValue,
    DateTime? entryDeadline,
    bool? isStarred,
    List<String>? tags,
  }) {
    return EmailMessage(
      id: id ?? this.id,
      from: from ?? this.from,
      subject: subject ?? this.subject,
      body: body ?? this.body,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      hasAttachments: hasAttachments ?? this.hasAttachments,
      importance: importance ?? this.importance,
      originalSender: originalSender ?? this.originalSender,
      sweepstakesName: sweepstakesName ?? this.sweepstakesName,
      prizeValue: prizeValue ?? this.prizeValue,
      entryDeadline: entryDeadline ?? this.entryDeadline,
      isStarred: isStarred ?? this.isStarred,
      tags: tags ?? this.tags,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmailMessage &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'EmailMessage{id: $id, from: $from, subject: $subject, category: $category, isRead: $isRead}';
  }
}

/// Email importance levels for prioritizing messages.
enum EmailImportance {
  /// Low priority emails that can be read later.
  low,

  /// Normal priority emails (default).
  normal,

  /// High priority emails that should be read soon.
  high,

  /// Urgent emails requiring immediate attention.
  urgent,
}

extension EmailImportanceExtension on EmailImportance {
  String get name {
    switch (this) {
      case EmailImportance.low:
        return 'low';
      case EmailImportance.normal:
        return 'normal';
      case EmailImportance.high:
        return 'high';
      case EmailImportance.urgent:
        return 'urgent';
    }
  }

  String get displayName {
    switch (this) {
      case EmailImportance.low:
        return 'Low';
      case EmailImportance.normal:
        return 'Normal';
      case EmailImportance.high:
        return 'High';
      case EmailImportance.urgent:
        return 'Urgent';
    }
  }

  /// Get importance from string
  static EmailImportance fromString(String value) {
    switch (value.toLowerCase()) {
      case 'low':
        return EmailImportance.low;
      case 'high':
        return EmailImportance.high;
      case 'urgent':
        return EmailImportance.urgent;
      default:
        return EmailImportance.normal;
    }
  }
}

/// Email settings model for user preferences
@immutable
class EmailSettings {
  const EmailSettings({
    this.showPromotionalEmails = true,
    this.notifyOnWinnerEmailsOnly = false,
    this.autoCategorizeEmails = true,
    this.forwardingAddress,
    this.enablePushNotifications = true,
    this.enableEmailSummary = false,
    this.summaryFrequency = EmailSummaryFrequency.daily,
  });

  final bool showPromotionalEmails;
  final bool notifyOnWinnerEmailsOnly;
  final bool autoCategorizeEmails;
  final String? forwardingAddress;
  final bool enablePushNotifications;
  final bool enableEmailSummary;
  final EmailSummaryFrequency summaryFrequency;

  /// Create from Firestore document
  factory EmailSettings.fromFirestore(Map<String, dynamic> data) {
    return EmailSettings(
      showPromotionalEmails: data['showPromotionalEmails'] ?? true,
      notifyOnWinnerEmailsOnly: data['notifyOnWinnerEmailsOnly'] ?? false,
      autoCategorizeEmails: data['autoCategorizeEmails'] ?? true,
      forwardingAddress: data['forwardingAddress'],
      enablePushNotifications: data['enablePushNotifications'] ?? true,
      enableEmailSummary: data['enableEmailSummary'] ?? false,
      summaryFrequency: EmailSummaryFrequencyExtension.fromString(
        data['summaryFrequency'] ?? 'daily',
      ),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'showPromotionalEmails': showPromotionalEmails,
      'notifyOnWinnerEmailsOnly': notifyOnWinnerEmailsOnly,
      'autoCategorizeEmails': autoCategorizeEmails,
      'forwardingAddress': forwardingAddress,
      'enablePushNotifications': enablePushNotifications,
      'enableEmailSummary': enableEmailSummary,
      'summaryFrequency': summaryFrequency.name,
    };
  }

  /// Copy with method for immutable updates
  EmailSettings copyWith({
    bool? showPromotionalEmails,
    bool? notifyOnWinnerEmailsOnly,
    bool? autoCategorizeEmails,
    String? forwardingAddress,
    bool? enablePushNotifications,
    bool? enableEmailSummary,
    EmailSummaryFrequency? summaryFrequency,
  }) {
    return EmailSettings(
      showPromotionalEmails:
          showPromotionalEmails ?? this.showPromotionalEmails,
      notifyOnWinnerEmailsOnly:
          notifyOnWinnerEmailsOnly ?? this.notifyOnWinnerEmailsOnly,
      autoCategorizeEmails: autoCategorizeEmails ?? this.autoCategorizeEmails,
      forwardingAddress: forwardingAddress ?? this.forwardingAddress,
      enablePushNotifications:
          enablePushNotifications ?? this.enablePushNotifications,
      enableEmailSummary: enableEmailSummary ?? this.enableEmailSummary,
      summaryFrequency: summaryFrequency ?? this.summaryFrequency,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmailSettings &&
          runtimeType == other.runtimeType &&
          showPromotionalEmails == other.showPromotionalEmails &&
          notifyOnWinnerEmailsOnly == other.notifyOnWinnerEmailsOnly &&
          autoCategorizeEmails == other.autoCategorizeEmails &&
          forwardingAddress == other.forwardingAddress &&
          enablePushNotifications == other.enablePushNotifications &&
          enableEmailSummary == other.enableEmailSummary &&
          summaryFrequency == other.summaryFrequency;

  @override
  int get hashCode => Object.hash(
        showPromotionalEmails,
        notifyOnWinnerEmailsOnly,
        autoCategorizeEmails,
        forwardingAddress,
        enablePushNotifications,
        enableEmailSummary,
        summaryFrequency,
      );
}

/// Email summary frequency options
enum EmailSummaryFrequency {
  daily,
  weekly,
  monthly,
}

extension EmailSummaryFrequencyExtension on EmailSummaryFrequency {
  String get name {
    switch (this) {
      case EmailSummaryFrequency.daily:
        return 'daily';
      case EmailSummaryFrequency.weekly:
        return 'weekly';
      case EmailSummaryFrequency.monthly:
        return 'monthly';
    }
  }

  String get displayName {
    switch (this) {
      case EmailSummaryFrequency.daily:
        return 'Daily';
      case EmailSummaryFrequency.weekly:
        return 'Weekly';
      case EmailSummaryFrequency.monthly:
        return 'Monthly';
    }
  }

  /// Get frequency from string
  static EmailSummaryFrequency fromString(String value) {
    switch (value.toLowerCase()) {
      case 'weekly':
        return EmailSummaryFrequency.weekly;
      case 'monthly':
        return EmailSummaryFrequency.monthly;
      default:
        return EmailSummaryFrequency.daily;
    }
  }
}
