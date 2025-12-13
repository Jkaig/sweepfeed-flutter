import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  Comment({
    required this.id,
    required this.contestId,
    required this.userId,
    required this.userName,
    required this.content,
    required this.createdAt,
    this.userPhotoUrl,
    this.editedAt,
    this.likes = 0,
    this.likedBy = const [],
    this.isReported = false,
    this.isModerated = false,
    this.moderationReason,
    this.parentCommentId,
    this.replyCount = 0,
  });

  factory Comment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Comment(
      id: doc.id,
      contestId: data['contestId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      userPhotoUrl: data['userPhotoUrl'],
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      editedAt: data['editedAt'] != null
          ? (data['editedAt'] as Timestamp).toDate()
          : null,
      likes: data['likes'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      isReported: data['isReported'] ?? false,
      isModerated: data['isModerated'] ?? false,
      moderationReason: data['moderationReason'],
      parentCommentId: data['parentCommentId'],
      replyCount: data['replyCount'] ?? 0,
    );
  }
  final String id;
  final String contestId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String content;
  final DateTime createdAt;
  final DateTime? editedAt;
  final int likes;
  final List<String> likedBy;
  final bool isReported;
  final bool isModerated;
  final String? moderationReason;
  final String? parentCommentId;
  final int replyCount;

  Map<String, dynamic> toFirestore() => {
        'contestId': contestId,
        'userId': userId,
        'userName': userName,
        'userPhotoUrl': userPhotoUrl,
        'content': content,
        'createdAt': Timestamp.fromDate(createdAt),
        'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
        'likes': likes,
        'likedBy': likedBy,
        'isReported': isReported,
        'isModerated': isModerated,
        'moderationReason': moderationReason,
        'parentCommentId': parentCommentId,
        'replyCount': replyCount,
      };

  Comment copyWith({
    String? id,
    String? contestId,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    String? content,
    DateTime? createdAt,
    DateTime? editedAt,
    int? likes,
    List<String>? likedBy,
    bool? isReported,
    bool? isModerated,
    String? moderationReason,
    String? parentCommentId,
    int? replyCount,
  }) =>
      Comment(
        id: id ?? this.id,
        contestId: contestId ?? this.contestId,
        userId: userId ?? this.userId,
        userName: userName ?? this.userName,
        userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
        content: content ?? this.content,
        createdAt: createdAt ?? this.createdAt,
        editedAt: editedAt ?? this.editedAt,
        likes: likes ?? this.likes,
        likedBy: likedBy ?? this.likedBy,
        isReported: isReported ?? this.isReported,
        isModerated: isModerated ?? this.isModerated,
        moderationReason: moderationReason ?? this.moderationReason,
        parentCommentId: parentCommentId ?? this.parentCommentId,
        replyCount: replyCount ?? this.replyCount,
      );

  bool get isTopLevel => parentCommentId == null;
  bool get hasReplies => replyCount > 0;
  bool get isEdited => editedAt != null;
}
