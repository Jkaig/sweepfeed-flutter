import 'package:cloud_firestore/cloud_firestore.dart';

class ReferralCode {
  ReferralCode({
    required this.id,
    required this.userId,
    required this.userName,
    required this.code,
    required this.timestamp,
    this.userProfilePicture,
    this.uses = 0,
    this.reports = 0,
    this.reportedBy = const [],
    this.usedBy = const [],
  });

  factory ReferralCode.fromMap(Map<String, dynamic> data, String id) =>
      ReferralCode(
        id: id,
        userId: data['userId'] ?? '',
        userName: data['userName'] ?? 'Anonymous',
        userProfilePicture: data['userProfilePicture'],
        code: data['code'] ?? '',
        timestamp:
            (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        uses: data['uses'] ?? 0,
        reports: data['reports'] ?? 0,
        reportedBy: List<String>.from(data['reportedBy'] ?? []),
        usedBy: List<String>.from(data['usedBy'] ?? []),
      );
  final String id;
  final String userId;
  final String userName;
  final String? userProfilePicture;
  final String code;
  final DateTime timestamp;
  final int uses;
  final int reports;
  final List<String> reportedBy;
  final List<String> usedBy;

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'userName': userName,
        'userProfilePicture': userProfilePicture,
        'code': code,
        'timestamp': Timestamp.fromDate(timestamp),
        'uses': uses,
        'reports': reports,
        'reportedBy': reportedBy,
        'usedBy': usedBy,
      };

  ReferralCode copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userProfilePicture,
    String? code,
    DateTime? timestamp,
    int? uses,
    int? reports,
    List<String>? reportedBy,
    List<String>? usedBy,
  }) =>
      ReferralCode(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        userName: userName ?? this.userName,
        userProfilePicture: userProfilePicture ?? this.userProfilePicture,
        code: code ?? this.code,
        timestamp: timestamp ?? this.timestamp,
        uses: uses ?? this.uses,
        reports: reports ?? this.reports,
        reportedBy: reportedBy ?? this.reportedBy,
        usedBy: usedBy ?? this.usedBy,
      );
}

class ReferralChain {
  ReferralChain({
    required this.referralCodeId,
    required this.parentUserId,
    this.children = const [],
  });

  factory ReferralChain.fromMap(Map<String, dynamic> data, String id) {
    final childrenData = data['children'] as Map<String, dynamic>? ?? {};
    final children = childrenData.entries
        .map(
          (entry) => ReferralChild(
            userId: entry.key,
            timestamp: (entry.value['timestamp'] as Timestamp?)?.toDate() ??
                DateTime.now(),
          ),
        )
        .toList();

    return ReferralChain(
      referralCodeId: id,
      parentUserId: data['parentUserId'] ?? '',
      children: children,
    );
  }
  final String referralCodeId;
  final String parentUserId;
  final List<ReferralChild> children;

  Map<String, dynamic> toMap() {
    final childrenMap = <String, dynamic>{};
    for (final child in children) {
      childrenMap[child.userId] = {
        'timestamp': Timestamp.fromDate(child.timestamp),
      };
    }

    return {
      'parentUserId': parentUserId,
      'children': childrenMap,
    };
  }
}

class ReferralChild {
  ReferralChild({
    required this.userId,
    required this.timestamp,
  });
  final String userId;
  final DateTime timestamp;
}
