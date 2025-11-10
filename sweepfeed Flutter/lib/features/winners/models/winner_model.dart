import 'package:cloud_firestore/cloud_firestore.dart';

class Winner {
  Winner({
    required this.id,
    required this.contestId,
    required this.contestTitle,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.prizeValue,
    required this.wonDate,
    required this.status,
    required this.verificationSteps,
    this.isVerified = false,
    this.verificationCode,
    this.verificationDeadline,
    this.claimDetails,
    this.imageUrl,
  });

  factory Winner.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Winner(
      id: doc.id,
      contestId: data['contestId'] ?? '',
      contestTitle: data['contestTitle'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      prizeValue: data['prizeValue'] ?? '0',
      wonDate: (data['wonDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isVerified: data['isVerified'] ?? false,
      verificationCode: data['verificationCode'],
      verificationDeadline:
          (data['verificationDeadline'] as Timestamp?)?.toDate(),
      status: data['status'] ?? 'pending',
      claimDetails: data['claimDetails'],
      verificationSteps: List<String>.from(data['verificationSteps'] ?? []),
      imageUrl: data['imageUrl'],
    );
  }
  final String id;
  final String contestId;
  final String contestTitle;
  final String userId;
  final String userName;
  final String userEmail;
  final String prizeValue;
  final DateTime wonDate;
  final bool isVerified;
  final String? verificationCode;
  final DateTime? verificationDeadline;
  final String status; // pending, verified, expired, claimed
  final Map<String, dynamic>? claimDetails;
  final List<String> verificationSteps;
  final String? imageUrl;

  Map<String, dynamic> toFirestore() => {
        'contestId': contestId,
        'contestTitle': contestTitle,
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail,
        'prizeValue': prizeValue,
        'wonDate': Timestamp.fromDate(wonDate),
        'isVerified': isVerified,
        'verificationCode': verificationCode,
        'verificationDeadline': verificationDeadline != null
            ? Timestamp.fromDate(verificationDeadline!)
            : null,
        'status': status,
        'claimDetails': claimDetails,
        'verificationSteps': verificationSteps,
        'imageUrl': imageUrl,
      };

  Winner copyWith({
    String? id,
    String? contestId,
    String? contestTitle,
    String? userId,
    String? userName,
    String? userEmail,
    String? prizeValue,
    DateTime? wonDate,
    bool? isVerified,
    String? verificationCode,
    DateTime? verificationDeadline,
    String? status,
    Map<String, dynamic>? claimDetails,
    List<String>? verificationSteps,
    String? imageUrl,
  }) =>
      Winner(
        id: id ?? this.id,
        contestId: contestId ?? this.contestId,
        contestTitle: contestTitle ?? this.contestTitle,
        userId: userId ?? this.userId,
        userName: userName ?? this.userName,
        userEmail: userEmail ?? this.userEmail,
        prizeValue: prizeValue ?? this.prizeValue,
        wonDate: wonDate ?? this.wonDate,
        isVerified: isVerified ?? this.isVerified,
        verificationCode: verificationCode ?? this.verificationCode,
        verificationDeadline: verificationDeadline ?? this.verificationDeadline,
        status: status ?? this.status,
        claimDetails: claimDetails ?? this.claimDetails,
        verificationSteps: verificationSteps ?? this.verificationSteps,
        imageUrl: imageUrl ?? this.imageUrl,
      );
}
