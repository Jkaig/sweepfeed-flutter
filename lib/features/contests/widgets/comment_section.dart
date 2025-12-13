import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/models/comment_model.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../profile/screens/profile_screen.dart';
import '../services/comment_service.dart';

final commentServiceProvider =
    Provider<CommentService>((ref) => CommentService());

final contestCommentsProvider =
    StreamProvider.family<List<Comment>, String>((ref, contestId) {
  final commentService = ref.watch(commentServiceProvider);
  return commentService.getContestComments(contestId);
});

final commentRepliesProvider =
    StreamProvider.family<List<Comment>, String>((ref, commentId) {
  final commentService = ref.watch(commentServiceProvider);
  return commentService.getCommentReplies(commentId);
});

class CommentSection extends ConsumerStatefulWidget {
  const CommentSection({required this.contestId, super.key});
  final String contestId;

  @override
  ConsumerState<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends ConsumerState<CommentSection> {
  final TextEditingController _commentController = TextEditingController();
  bool _isPosting = false;
  String? _replyingToCommentId;
  String? _replyingToUserName;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isPosting = true);

    try {
      final commentService = ref.read(commentServiceProvider);
      final analyticsService = ref.read(analyticsServiceProvider);

      await commentService.postComment(
        contestId: widget.contestId,
        content: _commentController.text.trim(),
        parentCommentId: _replyingToCommentId,
      );

      analyticsService.logCommentPosted(
        widget.contestId,
        _commentController.text,
      );

      _commentController.clear();
      _cancelReply();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Comment posted successfully'),
              ],
            ),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Failed to post comment: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  void _setReplyTarget(String commentId, String userName) {
    setState(() {
      _replyingToCommentId = commentId;
      _replyingToUserName = userName;
    });
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToUserName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(contestCommentsProvider(widget.contestId));
    final currentUser = FirebaseAuth.instance.currentUser;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Comments',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        commentsAsync.when(
          data: (comments) {
            if (comments.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 48,
                        color: AppColors.textMuted,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No comments yet',
                        style:
                            TextStyle(color: AppColors.textMuted, fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Be the first to share your thoughts!',
                        style:
                            TextStyle(color: AppColors.textLight, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              itemBuilder: (context, index) => CommentWidget(
                comment: comments[index],
                onReply: _setReplyTarget,
                currentUserId: currentUser?.uid,
              ),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          ),
          error: (error, stack) => const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Error loading comments',
              style: TextStyle(color: AppColors.errorRed),
            ),
          ),
        ),
        if (currentUser != null) _buildCommentInput(),
      ],
    );
  }

  Widget _buildCommentInput() => Container(
        padding: const EdgeInsets.all(16.0),
        decoration: const BoxDecoration(
          color: AppColors.primaryMedium,
          border: Border(top: BorderSide(color: AppColors.primaryLight)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_replyingToUserName != null) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.reply, size: 16, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Text(
                      'Replying to $_replyingToUserName',
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _cancelReply,
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    maxLines: null,
                    maxLength: CommentService.maxCommentLength,
                    style: const TextStyle(color: AppColors.textWhite),
                    decoration: InputDecoration(
                      hintText: 'Share your thoughts...',
                      hintStyle: const TextStyle(color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.primaryLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accent, AppColors.electricBlue],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: _isPosting ? null : _postComment,
                    icon: _isPosting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primaryDark,
                              ),
                            ),
                          )
                        : const Icon(Icons.send, color: AppColors.primaryDark),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

class CommentWidget extends ConsumerStatefulWidget {
  const CommentWidget({
    required this.comment,
    required this.onReply,
    super.key,
    this.currentUserId,
  });
  final Comment comment;
  final Function(String, String) onReply;
  final String? currentUserId;

  @override
  ConsumerState<CommentWidget> createState() => _CommentWidgetState();
}

class _CommentWidgetState extends ConsumerState<CommentWidget>
    with SingleTickerProviderStateMixin {
  bool _showReplies = false;
  late AnimationController _likeAnimationController;
  late Animation<double> _likeScaleAnimation;

  @override
  void initState() {
    super.initState();
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _likeScaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _likeAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    _likeAnimationController
        .forward()
        .then((_) => _likeAnimationController.reverse());

    try {
      final commentService = ref.read(commentServiceProvider);
      final analyticsService = ref.read(analyticsServiceProvider);

      await commentService.toggleLike(widget.comment.id);
      analyticsService.logCommentLiked(widget.comment.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to like comment: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _deleteComment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryMedium,
        title: const Text(
          'Delete Comment',
          style: TextStyle(color: AppColors.textWhite),
        ),
        content: const Text(
          'Are you sure you want to delete this comment?',
          style: TextStyle(color: AppColors.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final commentService = ref.read(commentServiceProvider);
        await commentService.deleteComment(widget.comment.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Comment deleted'),
              backgroundColor: AppColors.successGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: ${e.toString()}'),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
      }
    }
  }

  Future<void> _reportComment() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        var selectedReason = 'spam';
        return AlertDialog(
          backgroundColor: AppColors.primaryMedium,
          title: const Text(
            'Report Comment',
            style: TextStyle(color: AppColors.textWhite),
          ),
          content: StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: const Text(
                    'Spam',
                    style: TextStyle(color: AppColors.textLight),
                  ),
                  value: 'spam',
                  groupValue: selectedReason,
                  onChanged: (value) => setState(() => selectedReason = value!),
                  activeColor: AppColors.accent,
                ),
                RadioListTile<String>(
                  title: const Text(
                    'Harassment',
                    style: TextStyle(color: AppColors.textLight),
                  ),
                  value: 'harassment',
                  groupValue: selectedReason,
                  onChanged: (value) => setState(() => selectedReason = value!),
                  activeColor: AppColors.accent,
                ),
                RadioListTile<String>(
                  title: const Text(
                    'Inappropriate',
                    style: TextStyle(color: AppColors.textLight),
                  ),
                  value: 'inappropriate',
                  groupValue: selectedReason,
                  onChanged: (value) => setState(() => selectedReason = value!),
                  activeColor: AppColors.accent,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, selectedReason),
              child: const Text(
                'Report',
                style: TextStyle(color: AppColors.errorRed),
              ),
            ),
          ],
        );
      },
    );

    if (reason != null) {
      try {
        final commentService = ref.read(commentServiceProvider);
        await commentService.reportComment(widget.comment.id, reason);

        if (mounted) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppColors.primaryMedium,
              title: const Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppColors.successGreen,
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Report Submitted',
                    style: TextStyle(color: AppColors.textWhite),
                  ),
                ],
              ),
              content: const Text(
                'Thank you for helping keep SweepFeed safe! Our team will review this comment.',
                style: TextStyle(color: AppColors.textLight),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'OK',
                    style: TextStyle(color: AppColors.accent),
                  ),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to report: ${e.toString()}'),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwnComment = widget.comment.userId == widget.currentUserId;
    final hasLiked = widget.comment.likedBy.contains(widget.currentUserId);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.primaryLight, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryLight,
                backgroundImage: widget.comment.userPhotoUrl != null
                    ? NetworkImage(widget.comment.userPhotoUrl!)
                    : null,
                child: widget.comment.userPhotoUrl == null
                    ? Text(
                        widget.comment.userName.isNotEmpty
                            ? widget.comment.userName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppColors.textWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const ProfileScreen(),
                              ),
                            );
                          },
                          child: Text(
                            widget.comment.userName,
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.accent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeago.format(widget.comment.createdAt),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        if (widget.comment.isEdited) ...[
                          const SizedBox(width: 4),
                          const Text(
                            '(edited)',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.comment.content,
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _toggleLike,
                          child: Row(
                            children: [
                              ScaleTransition(
                                scale: _likeScaleAnimation,
                                child: Icon(
                                  hasLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  size: 18,
                                  color: hasLiked
                                      ? AppColors.errorRed
                                      : AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.comment.likes}',
                                style: TextStyle(
                                  color: hasLiked
                                      ? AppColors.errorRed
                                      : AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => widget.onReply(
                            widget.comment.id,
                            widget.comment.userName,
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.reply,
                                size: 18,
                                color: AppColors.textMuted,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Reply',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.comment.hasReplies) ...[
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _showReplies = !_showReplies),
                            child: Row(
                              children: [
                                Icon(
                                  _showReplies
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  size: 18,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.comment.replyCount} ${widget.comment.replyCount == 1 ? 'reply' : 'replies'}',
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const Spacer(),
                        PopupMenuButton<String>(
                          color: AppColors.primaryMedium,
                          icon: const Icon(
                            Icons.more_vert,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                          onSelected: (value) {
                            switch (value) {
                              case 'delete':
                                _deleteComment();
                                break;
                              case 'report':
                                _reportComment();
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            if (isOwnComment)
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      color: AppColors.errorRed,
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Delete',
                                      style: TextStyle(
                                        color: AppColors.errorRed,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (!isOwnComment)
                              const PopupMenuItem(
                                value: 'report',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.flag_outlined,
                                      color: AppColors.textLight,
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Report',
                                      style: TextStyle(
                                        color: AppColors.textLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_showReplies && widget.comment.hasReplies)
            Padding(
              padding: const EdgeInsets.only(left: 44, top: 12),
              child: CommentReplies(
                parentCommentId: widget.comment.id,
                onReply: widget.onReply,
                currentUserId: widget.currentUserId,
              ),
            ),
        ],
      ),
    );
  }
}

class CommentReplies extends ConsumerWidget {
  const CommentReplies({
    required this.parentCommentId,
    required this.onReply,
    super.key,
    this.currentUserId,
  });
  final String parentCommentId;
  final Function(String, String) onReply;
  final String? currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repliesAsync = ref.watch(commentRepliesProvider(parentCommentId));

    return repliesAsync.when(
      data: (replies) => ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: replies.length,
        itemBuilder: (context, index) => CommentWidget(
          comment: replies[index],
          onReply: onReply,
          currentUserId: currentUserId,
        ),
      ),
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(
            color: AppColors.accent,
            strokeWidth: 2,
          ),
        ),
      ),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}
