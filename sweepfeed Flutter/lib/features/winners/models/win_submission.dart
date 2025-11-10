import 'package:cloud_firestore/cloud_firestore.dart';

class WinSubmission {
  WinSubmission({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.contestId,
    required this.contestTitle,
    required this.prizeName,
    required this.prizeValue,
    required this.proofText,
    required this.timestamp,
    required this.status,
    this.proofImageUrl,
    this.adminNotes,
    this.reviewedBy,
    this.reviewedAt,
  });

  factory WinSubmission.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WinSubmission(
      id: doc.id,
      userId: data['userId'] as String,
      userName: data['userName'] as String,
      userEmail: data['userEmail'] as String,
      contestId: data['contestId'] as String,
      contestTitle: data['contestTitle'] as String,
      prizeName: data['prizeName'] as String,
      prizeValue: (data['prizeValue'] as num?)?.toDouble() ?? 0.0,
      proofText: data['proofText'] as String,
      timestamp: data['timestamp'] as Timestamp,
      status: data['status'] as String,
      proofImageUrl: data['proofImageUrl'] as String?,
      adminNotes: data['adminNotes'] as String?,
      reviewedBy: data['reviewedBy'] as String?,
      reviewedAt: data['reviewedAt'] as Timestamp?,
    );
  }
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String contestId;
  final String contestTitle;
  final String prizeName;
  final double prizeValue;
  final String proofText;
  final Timestamp timestamp;
  final String status;
  final String? proofImageUrl;
  final String? adminNotes;
  final String? reviewedBy;
  final Timestamp? reviewedAt;

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail,
        'contestId': contestId,
        'contestTitle': contestTitle,
        'prizeName': prizeName,
        'prizeValue': prizeValue,
        'proofText': proofText,
        'timestamp': timestamp,
        'status': status,
        if (proofImageUrl != null) 'proofImageUrl': proofImageUrl,
        if (adminNotes != null) 'adminNotes': adminNotes,
        if (reviewedBy != null) 'reviewedBy': reviewedBy,
        if (reviewedAt != null) 'reviewedAt': reviewedAt,
      };
}
