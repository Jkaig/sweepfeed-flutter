import 'package:cloud_firestore/cloud_firestore.dart';

class ContestComment {
  ContestComment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.text,
    required this.timestamp,
    this.userProfilePicture,
    this.upvotes = 0,
    this.upvotedBy = const [],
    this.reports = 0,
    this.reportedBy = const [],
    this.isHelpful = false,
  });

  factory ContestComment.fromMap(Map<String, dynamic> data, String id) =>
      ContestComment(
        id: id,
        userId: data['userId'] ?? '',
        userName: data['userName'] ?? 'Anonymous',
        userProfilePicture: data['userProfilePicture'],
        text: data['text'] ?? '',
        timestamp:
            (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        upvotes: data['upvotes'] ?? 0,
        upvotedBy: List<String>.from(data['upvotedBy'] ?? []),
        reports: data['reports'] ?? 0,
        reportedBy: List<String>.from(data['reportedBy'] ?? []),
        isHelpful: data['isHelpful'] ?? false,
      );
  final String id;
  final String userId;
  final String userName;
  final String? userProfilePicture;
  final String text;
  final DateTime timestamp;
  final int upvotes;
  final List<String> upvotedBy;
  final int reports;
  final List<String> reportedBy;
  final bool isHelpful;

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'userName': userName,
        'userProfilePicture': userProfilePicture,
        'text': text,
        'timestamp': Timestamp.fromDate(timestamp),
        'upvotes': upvotes,
        'upvotedBy': upvotedBy,
        'reports': reports,
        'reportedBy': reportedBy,
        'isHelpful': isHelpful,
      };

  ContestComment copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userProfilePicture,
    String? text,
    DateTime? timestamp,
    int? upvotes,
    List<String>? upvotedBy,
    int? reports,
    List<String>? reportedBy,
    bool? isHelpful,
  }) =>
      ContestComment(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        userName: userName ?? this.userName,
        userProfilePicture: userProfilePicture ?? this.userProfilePicture,
        text: text ?? this.text,
        timestamp: timestamp ?? this.timestamp,
        upvotes: upvotes ?? this.upvotes,
        upvotedBy: upvotedBy ?? this.upvotedBy,
        reports: reports ?? this.reports,
        reportedBy: reportedBy ?? this.reportedBy,
        isHelpful: isHelpful ?? this.isHelpful,
      );
}
