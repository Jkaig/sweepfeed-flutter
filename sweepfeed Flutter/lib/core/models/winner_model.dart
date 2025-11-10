import 'package:cloud_firestore/cloud_firestore.dart';

enum WinnerStatus {
  pending,
  verified,
  claimed,
  disputed,
  expired,
}

enum PrizeClaimMethod {
  digital,
  mail,
  pickup,
  directDeposit,
}

class Winner {
  Winner({
    required this.id,
    required this.userId,
    required this.contestId,
    required this.contestTitle,
    required this.prizeDescription,
    required this.prizeValue,
    required this.winDate,
    required this.status,
    required this.claimMethod,
    required this.createdAt,
    required this.updatedAt,
    this.claimDeadline,
    this.verificationData = const {},
    this.claimData = const {},
    this.requiredDocuments = const [],
    this.submittedDocuments = const [],
    this.rejectionReason,
  });

  factory Winner.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;

    return Winner(
      id: doc.id,
      userId: data['userId'] ?? '',
      contestId: data['contestId'] ?? '',
      contestTitle: data['contestTitle'] ?? '',
      prizeDescription: data['prizeDescription'] ?? '',
      prizeValue: (data['prizeValue'] ?? 0).toDouble(),
      winDate: (data['winDate'] as Timestamp).toDate(),
      claimDeadline: data['claimDeadline'] != null
          ? (data['claimDeadline'] as Timestamp).toDate()
          : null,
      status: WinnerStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => WinnerStatus.pending,
      ),
      claimMethod: PrizeClaimMethod.values.firstWhere(
        (e) => e.toString().split('.').last == data['claimMethod'],
        orElse: () => PrizeClaimMethod.digital,
      ),
      verificationData:
          Map<String, dynamic>.from(data['verificationData'] ?? {}),
      claimData: Map<String, dynamic>.from(data['claimData'] ?? {}),
      requiredDocuments: List<String>.from(data['requiredDocuments'] ?? []),
      submittedDocuments: List<String>.from(data['submittedDocuments'] ?? []),
      rejectionReason: data['rejectionReason'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
  final String id;
  final String userId;
  final String contestId;
  final String contestTitle;
  final String prizeDescription;
  final double prizeValue;
  final DateTime winDate;
  final DateTime? claimDeadline;
  final WinnerStatus status;
  final PrizeClaimMethod claimMethod;
  final Map<String, dynamic> verificationData;
  final Map<String, dynamic> claimData;
  final List<String> requiredDocuments;
  final List<String> submittedDocuments;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'contestId': contestId,
        'contestTitle': contestTitle,
        'prizeDescription': prizeDescription,
        'prizeValue': prizeValue,
        'winDate': Timestamp.fromDate(winDate),
        'claimDeadline':
            claimDeadline != null ? Timestamp.fromDate(claimDeadline!) : null,
        'status': status.toString().split('.').last,
        'claimMethod': claimMethod.toString().split('.').last,
        'verificationData': verificationData,
        'claimData': claimData,
        'requiredDocuments': requiredDocuments,
        'submittedDocuments': submittedDocuments,
        'rejectionReason': rejectionReason,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  Winner copyWith({
    String? id,
    String? userId,
    String? contestId,
    String? contestTitle,
    String? prizeDescription,
    double? prizeValue,
    DateTime? winDate,
    DateTime? claimDeadline,
    WinnerStatus? status,
    PrizeClaimMethod? claimMethod,
    Map<String, dynamic>? verificationData,
    Map<String, dynamic>? claimData,
    List<String>? requiredDocuments,
    List<String>? submittedDocuments,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Winner(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        contestId: contestId ?? this.contestId,
        contestTitle: contestTitle ?? this.contestTitle,
        prizeDescription: prizeDescription ?? this.prizeDescription,
        prizeValue: prizeValue ?? this.prizeValue,
        winDate: winDate ?? this.winDate,
        claimDeadline: claimDeadline ?? this.claimDeadline,
        status: status ?? this.status,
        claimMethod: claimMethod ?? this.claimMethod,
        verificationData: verificationData ?? this.verificationData,
        claimData: claimData ?? this.claimData,
        requiredDocuments: requiredDocuments ?? this.requiredDocuments,
        submittedDocuments: submittedDocuments ?? this.submittedDocuments,
        rejectionReason: rejectionReason ?? this.rejectionReason,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  bool get isPending => status == WinnerStatus.pending;
  bool get isVerified => status == WinnerStatus.verified;
  bool get isClaimed => status == WinnerStatus.claimed;
  bool get isDisputed => status == WinnerStatus.disputed;
  bool get isExpired => status == WinnerStatus.expired;

  bool get hasClaimDeadlinePassed {
    if (claimDeadline == null) return false;
    return DateTime.now().isAfter(claimDeadline!);
  }

  int get daysUntilDeadline {
    if (claimDeadline == null) return -1;
    return claimDeadline!.difference(DateTime.now()).inDays;
  }

  double get verificationProgress {
    if (requiredDocuments.isEmpty) return 1.0;
    return submittedDocuments.length / requiredDocuments.length;
  }

  bool get isVerificationComplete =>
      requiredDocuments.every(submittedDocuments.contains);
}
