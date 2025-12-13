import 'package:cloud_firestore/cloud_firestore.dart';

class Reminder {
  // Optional, store as Timestamp

  Reminder({
    required this.contestId,
    required this.reminderTimestamp,
    required this.createdAt,
    this.contestTitle,
    this.contestEndDate,
  });

  factory Reminder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Reminder(
      contestId: data['contestId'] ?? '',
      reminderTimestamp: data['reminderTimestamp'] ?? Timestamp.now(),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      contestTitle: data['contestTitle'] as String?,
      contestEndDate: data['contestEndDate'] as Timestamp?,
    );
  }
  final String contestId;
  final Timestamp reminderTimestamp;
  final Timestamp createdAt;
  final String? contestTitle; // Optional
  final Timestamp? contestEndDate;

  Map<String, dynamic> toJson() => {
        'contestId': contestId,
        'reminderTimestamp': reminderTimestamp,
        'createdAt': createdAt,
        if (contestTitle != null) 'contestTitle': contestTitle,
        if (contestEndDate != null) 'contestEndDate': contestEndDate,
      };
}
