import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/comment_model.dart';
import '../models/referral_code_model.dart';
import '../services/social_service.dart';

class ContestSocialSection extends StatefulWidget {
  const ContestSocialSection({
    required this.contestId,
    super.key,
  });
  final String contestId;

  @override
  State<ContestSocialSection> createState() =>
      _ContestSocialSectionState();
}

class _ContestSocialSectionState extends State<ContestSocialSection>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _referralCodeController = TextEditingController();
  bool _isPostingComment = false;
  bool _isPostingCode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primaryMedium],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Tab bar
            Container(
              color: AppColors.primaryMedium.withValues(alpha: 0.3),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.brandCyan,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.chat_bubble_outline),
                    text: 'Comments',
                  ),
                  Tab(
                    icon: Icon(Icons.share),
                    text: 'Referral Codes',
                  ),
                ],
              ),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCommentsTab(),
                  _buildReferralCodesTab(),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildCommentsTab() => Column(
        children: [
          // Post comment section
          _buildPostComment(),

          // Comments list
          Expanded(
            child: StreamBuilder<List<ContestComment>>(
              stream: socialService.getComments(widget.contestId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading comments',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: Colors.white70),
                    ),
                  );
                }

                final comments = snapshot.data ?? [];

                if (comments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.white30,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No comments yet',
                          style: AppTextStyles.bodyLarge
                              .copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Be the first to share your thoughts!',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: Colors.white54),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  itemBuilder: (context, index) =>
                      _buildCommentCard(comments[index]),
                );
              },
            ),
          ),
        ],
      );

  Widget _buildPostComment() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryMedium.withValues(alpha: 0.3),
          border: Border(
            bottom: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                maxLines: null,
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Share your tips and experiences...',
                  hintStyle:
                      AppTextStyles.bodyMedium.copyWith(color: Colors.white54),
                  filled: true,
                  fillColor: AppColors.primaryDark.withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.3),),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.3),),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.brandCyan),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: _isPostingComment ? null : _postComment,
              icon: _isPostingComment
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send, color: AppColors.brandCyan),
            ),
          ],
        ),
      );

  Widget _buildCommentCard(ContestComment comment) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isUpvoted =
        currentUser != null && comment.upvotedBy.contains(currentUser.uid);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryMedium.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: comment.isHelpful
              ? Colors.orange.withValues(alpha: 0.5)
              : AppColors.primary.withValues(alpha: 0.3),
          width: comment.isHelpful ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary,
                backgroundImage: comment.userProfilePicture != null
                    ? CachedNetworkImageProvider(comment.userProfilePicture!)
                    : null,
                child: comment.userProfilePicture == null
                    ? Text(
                        comment.userName[0].toUpperCase(),
                        style: AppTextStyles.bodySmall
                            .copyWith(color: Colors.white),
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
                        Text(
                          comment.userName,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (comment.isHelpful) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.orange, Colors.deepOrange],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Helpful',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      timeago.format(comment.timestamp),
                      style: AppTextStyles.bodySmall
                          .copyWith(color: Colors.white54),
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert, color: Colors.white54),
                color: AppColors.primaryMedium,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'report',
                    child: Row(
                      children: [
                        const Icon(Icons.flag, color: Colors.red, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Report',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'report') {
                    _reportComment(comment.id);
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Comment text
          Text(
            comment.text,
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
          ),

          const SizedBox(height: 12),

          // Upvote button
          InkWell(
            onTap: () => _upvoteComment(comment.id),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isUpvoted
                    ? AppColors.brandCyan.withValues(alpha: 0.3)
                    : AppColors.primaryDark.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isUpvoted
                      ? AppColors.brandCyan
                      : AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isUpvoted ? Icons.thumb_up : Icons.thumb_up_outlined,
                    color: isUpvoted ? AppColors.brandCyan : Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${comment.upvotes}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isUpvoted ? AppColors.brandCyan : Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralCodesTab() => Column(
        children: [
          // Post referral code section
          _buildPostReferralCode(),

          // Referral codes list
          Expanded(
            child: StreamBuilder<List<ReferralCode>>(
              stream: socialService.getReferralCodes(widget.contestId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading referral codes',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: Colors.white70),
                    ),
                  );
                }

                final codes = snapshot.data ?? [];

                if (codes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.share,
                            size: 64, color: Colors.white30,),
                        const SizedBox(height: 16),
                        Text(
                          'No referral codes yet',
                          style: AppTextStyles.bodyLarge
                              .copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Share your code and help others!',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: Colors.white54),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: codes.length,
                  itemBuilder: (context, index) =>
                      _buildReferralCodeCard(codes[index]),
                );
              },
            ),
          ),
        ],
      );

  Widget _buildPostReferralCode() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryMedium.withValues(alpha: 0.3),
          border: Border(
            bottom: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share Your Referral Code',
              style: AppTextStyles.bodyLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Get notified when others use your code!',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _referralCodeController,
                    style:
                        AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter your referral code...',
                      hintStyle: AppTextStyles.bodyMedium
                          .copyWith(color: Colors.white54),
                      filled: true,
                      fillColor: AppColors.primaryDark.withValues(alpha: 0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.3),),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.3),),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.brandCyan),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _isPostingCode ? null : _postReferralCode,
                  icon: _isPostingCode
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send, color: AppColors.brandCyan),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildReferralCodeCard(ReferralCode code) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwnCode = currentUser != null && code.userId == currentUser.uid;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.3),
            AppColors.primaryMedium.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOwnCode
              ? Colors.orange.withValues(alpha: 0.5)
              : AppColors.brandCyan.withValues(alpha: 0.3),
          width: isOwnCode ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary,
                backgroundImage: code.userProfilePicture != null
                    ? CachedNetworkImageProvider(code.userProfilePicture!)
                    : null,
                child: code.userProfilePicture == null
                    ? Text(
                        code.userName[0].toUpperCase(),
                        style: AppTextStyles.bodySmall
                            .copyWith(color: Colors.white),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      code.userName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      timeago.format(code.timestamp),
                      style: AppTextStyles.bodySmall
                          .copyWith(color: Colors.white54),
                    ),
                  ],
                ),
              ),
              if (!isOwnCode)
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white54),
                  color: AppColors.primaryMedium,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          const Icon(Icons.flag, color: Colors.red, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            'Report',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'report') {
                      _reportReferralCode(code.id);
                    }
                  },
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Referral code display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: AppColors.brandCyan.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    code.code,
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: AppColors.brandCyan,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _copyReferralCode(code),
                  icon: const Icon(Icons.copy, color: AppColors.brandCyan),
                  tooltip: 'Copy code',
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Stats
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.green.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people, color: Colors.green, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '${code.uses} uses',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (isOwnCode) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.orange, Colors.deepOrange],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Your Code',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isPostingComment = true);

    try {
      await socialService.postComment(
        contestId: widget.contestId,
        text: _commentController.text.trim(),
      );

      _commentController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment posted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPostingComment = false);
      }
    }
  }

  Future<void> _upvoteComment(String commentId) async {
    try {
      await socialService.upvoteComment(
        contestId: widget.contestId,
        commentId: commentId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _reportComment(String commentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryMedium,
        title: Text(
          'Report Comment',
          style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to report this comment?',
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Report',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await socialService.reportComment(
          contestId: widget.contestId,
          commentId: commentId,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Comment reported. Thank you for keeping our community safe.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _postReferralCode() async {
    if (_referralCodeController.text.trim().isEmpty) return;

    setState(() => _isPostingCode = true);

    try {
      await socialService.postReferralCode(
        contestId: widget.contestId,
        code: _referralCodeController.text.trim(),
      );

      _referralCodeController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Referral code posted! You'll be notified when someone uses it.",
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPostingCode = false);
      }
    }
  }

  Future<void> _copyReferralCode(ReferralCode code) async {
    await Clipboard.setData(ClipboardData(text: code.code));

    // Track the copy
    try {
      await socialService.useReferralCode(
        contestId: widget.contestId,
        referralCodeId: code.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Code copied! The owner has been notified.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Still copy to clipboard even if tracking fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('already used')
                  ? 'Code copied! (You already used this code before)'
                  : 'Code copied to clipboard!',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _reportReferralCode(String codeId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryMedium,
        title: Text(
          'Report Referral Code',
          style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to report this referral code?',
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Report',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await socialService.reportReferralCode(
          contestId: widget.contestId,
          referralCodeId: codeId,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Referral code reported. Thank you for keeping our community safe.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
