import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import firebase_auth
import 'package:intl/intl.dart'; // Import intl for date formatting
import 'package:sweep_feed/core/models/comment.dart';
import 'package:sweep_feed/features/comments/services/comment_service.dart';
import 'package:sweep_feed/core/theme/app_colors.dart'; // Import AppColors
import 'package:sweep_feed/core/theme/app_text_styles.dart'; // Import AppTextStyles
import 'package:sweep_feed/core/widgets/loading_indicator.dart'; // Import LoadingIndicator

class CommentSection extends StatefulWidget {
  final String sweepstakeId;

  const CommentSection({super.key, required this.sweepstakeId});

  @override
  _CommentSectionState createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final CommentService _commentService = CommentService();
  final TextEditingController _commentController = TextEditingController();
  late Future<List<Comment>> _commentsFuture;
  // Removed: final String _userId = 'testUserId';

  @override
  void initState() {
    super.initState();
    _commentsFuture = _commentService.getCommentsForSweepstake(widget.sweepstakeId);
  }

  Future<void> _postComment() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) { // Check if widget is still in the tree
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to comment.')),
        );
      }
      return;
    }
    final userId = currentUser.uid;

    if (_commentController.text.isNotEmpty) {
      try {
        await _commentService.postComment(
          userId, // Use real userId
          widget.sweepstakeId,
          _commentController.text,
        );
        _commentController.clear();
        // Refresh comments after posting
        if (mounted) { // Check if widget is still in the tree
          setState(() {
            _commentsFuture = _commentService.getCommentsForSweepstake(widget.sweepstakeId);
          });
        }
      } catch (e) {
        if (mounted) { // Check if widget is still in the tree
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to post comment: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // Align children to the start
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0), // Adjusted padding
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textWhite), // Use new AppTextStyles
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted), // Use new AppColors
                    filled: true,
                    fillColor: AppColors.primaryMedium, // Use new AppColors
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.accent), // Use new AppColors
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Added content padding
                  ),
                ),
              ),
              const SizedBox(width: 8), // Spacing between TextField and Button
              IconButton(
                icon: const Icon(Icons.send, color: AppColors.accent), // Styled send button
                onPressed: _postComment,
                splashRadius: 24, // Standard splash radius
              ),
            ],
          ),
        ),
        // Removed Expanded widget from here
        FutureBuilder<List<Comment>>(
          future: _commentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: LoadingIndicator(size: 24)); // Adjusted size
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.errorRed)));
            } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              return ListView.builder(
                shrinkWrap: true, // Added shrinkWrap
                physics: const NeverScrollableScrollPhysics(), // Added physics
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final comment = snapshot.data![index];
                  return Padding( // Added padding around each comment tile
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: Icon(Icons.account_circle, color: AppColors.textLight, size: 36), // Styled leading icon
                      title: Text(
                        comment.userName ?? 'Anonymous User', // Display userName if available, else default
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textWhite, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        comment.text,
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textWhite),
                      ),
                      trailing: Text( // Added timestamp
                        DateFormat('MMM d, hh:mm a').format(comment.timestamp.toDate()),
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                      ),
                      tileColor: AppColors.primaryMedium.withOpacity(0.5), // Subtle background for tile
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // Rounded corners
                    ),
                  );
                },
              );
            } else {
              return Center(child: Text('No comments yet. Be the first!', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textMuted)));
            }
          },
        ),
      ],
    );
  }
}