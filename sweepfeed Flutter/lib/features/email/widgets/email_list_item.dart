import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/email_message.dart';
import '../services/email_service.dart';

/// A tile widget for displaying an email in the inbox list
class EmailListItem extends ConsumerWidget {
  const EmailListItem({
    super.key,
    required this.email,
    this.onTap,
    this.onDelete,
    this.onToggleRead,
    this.onToggleStar,
    this.showActions = true,
  });

  final EmailMessage email;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleRead;
  final VoidCallback? onToggleStar;
  final bool showActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: email.isRead
            ? AppColors.primaryMedium.withValues(alpha: 0.3)
            : AppColors.primaryMedium.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: email.isRead
              ? AppColors.primaryLight.withValues(alpha: 0.2)
              : AppColors.brandCyan.withValues(alpha: 0.3),
          width: email.isRead ? 1 : 1.5,
        ),
        boxShadow: email.isRead
            ? null
            : [
                BoxShadow(
                  color: AppColors.brandCyan.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with sender, category badge, and timestamp
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Unread indicator
                    if (!email.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 8, top: 6),
                        decoration: const BoxDecoration(
                          color: AppColors.brandCyan,
                          shape: BoxShape.circle,
                        ),
                      ),

                    // Sender name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            email.displaySender,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textWhite,
                              fontWeight: email.isRead
                                  ? FontWeight.normal
                                  : FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (email.sweepstakesName != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                email.sweepstakesName!,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textLight,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Category badge
                    _buildCategoryBadge(email.category),

                    const SizedBox(width: 8),

                    // Star button
                    if (showActions)
                      GestureDetector(
                        onTap: onToggleStar,
                        child: Icon(
                          email.isStarred ? Icons.star : Icons.star_border,
                          color: email.isStarred
                              ? AppColors.warningOrange
                              : AppColors.textLight,
                          size: 20,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 8),

                // Subject line
                Text(
                  email.subject,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textWhite,
                    fontWeight:
                        email.isRead ? FontWeight.normal : FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // Preview text
                Text(
                  email.previewText,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                // Footer row with additional info and actions
                Row(
                  children: [
                    // Timestamp
                    Text(
                      _formatTimestamp(email.timestamp),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),

                    // Prize value for winner emails
                    if (email.prizeValue != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.successGreen.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color:
                                AppColors.successGreen.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          email.prizeValue!,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.successGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],

                    // Entry deadline for promo emails
                    if (email.entryDeadline != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warningOrange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color:
                                AppColors.warningOrange.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          'Deadline: ${DateFormat('MMM d').format(email.entryDeadline!)}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.warningOrange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],

                    const Spacer(),

                    // Action buttons
                    if (showActions) ...[
                      // Mark as read/unread
                      GestureDetector(
                        onTap: onToggleRead,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            email.isRead
                                ? Icons.mark_email_unread_outlined
                                : Icons.mark_email_read_outlined,
                            color: AppColors.textLight,
                            size: 18,
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Delete button
                      GestureDetector(
                        onTap: onDelete,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: const Icon(
                            Icons.delete_outline,
                            color: AppColors.errorRed,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // Attachments indicator
                if (email.hasAttachments)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.attach_file,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Has attachments',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build category badge widget
  Widget _buildCategoryBadge(EmailCategory category) {
    Color badgeColor;
    IconData icon;

    switch (category) {
      case EmailCategory.winner:
        badgeColor = AppColors.successGreen;
        icon = Icons.emoji_events;
        break;
      case EmailCategory.promo:
        badgeColor = AppColors.brandCyan;
        icon = Icons.local_offer;
        break;
      case EmailCategory.general:
        badgeColor = AppColors.textMuted;
        icon = Icons.mail_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: badgeColor,
          ),
          const SizedBox(width: 4),
          Text(
            category.displayName,
            style: AppTextStyles.labelSmall.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Format timestamp for display
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      // Today - show time
      return DateFormat('h:mm a').format(timestamp);
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // This week - show day
      return DateFormat('E').format(timestamp);
    } else if (timestamp.year == now.year) {
      // This year - show month and day
      return DateFormat('MMM d').format(timestamp);
    } else {
      // Different year - show full date
      return DateFormat('MMM d, yyyy').format(timestamp);
    }
  }
}

/// Swipeable email list item with action options
class SwipeableEmailListItem extends ConsumerWidget {
  const SwipeableEmailListItem({
    super.key,
    required this.email,
    this.onTap,
    this.showActions = true,
  });

  final EmailMessage email;
  final VoidCallback? onTap;
  final bool showActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailService = ref.read(emailServiceProvider);

    return Dismissible(
      key: Key(email.id),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: AppColors.brandCyan.withValues(alpha: 0.2),
        child: const Icon(
          Icons.mark_email_read,
          color: AppColors.brandCyan,
          size: 24,
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.errorRed.withValues(alpha: 0.2),
        child: const Icon(
          Icons.delete,
          color: AppColors.errorRed,
          size: 24,
        ),
      ),
      onDismissed: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Mark as read/unread
          await emailService.markAsRead(email.id, isRead: !email.isRead);
        } else {
          // Delete email
          await emailService.deleteEmail(email.id);
        }
      },
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Confirm delete action
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppColors.primaryMedium,
              title: Text(
                'Delete Email',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textWhite,
                ),
              ),
              content: Text(
                'Are you sure you want to delete this email?',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textLight,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancel',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    'Delete',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.errorRed,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return true; // Allow mark as read/unread without confirmation
      },
      child: EmailListItem(
        email: email,
        onTap: onTap,
        onDelete: showActions
            ? () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppColors.primaryMedium,
                    title: Text(
                      'Delete Email',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textWhite,
                      ),
                    ),
                    content: Text(
                      'Are you sure you want to delete this email?',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(
                          'Cancel',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.textLight,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(
                          'Delete',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.errorRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await emailService.deleteEmail(email.id);
                }
              }
            : null,
        onToggleRead: showActions
            ? () => emailService.markAsRead(email.id, isRead: !email.isRead)
            : null,
        onToggleStar: showActions
            ? () =>
                emailService.toggleStar(email.id, isStarred: !email.isStarred)
            : null,
        showActions: showActions,
      ),
    );
  }
}
