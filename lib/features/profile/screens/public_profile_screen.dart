import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user_model.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/block_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../widgets/profile_picture_avatar.dart';
import '../widgets/user_analytics_charts.dart';

class PublicProfileScreen extends ConsumerWidget {
  const PublicProfileScreen({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider(userId));
    final dustBunniesAsync = ref.watch(dustBunniesProvider(userId));
    final currentUserID = ref.watch(authServiceProvider).currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: const Text('User Profile', style: AppTextStyles.titleLarge),
        backgroundColor: AppColors.primaryMedium,
        iconTheme: const IconThemeData(color: AppColors.textWhite),
        actions: [
          if (currentUserID != null && userId != currentUserID)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'block') {
                  final confirmed = await _showBlockConfirmDialog(
                    context,
                    userProfileAsync.asData?.value?.name ?? 'this user',
                  );
                  if (confirmed == true) {
                    await ref.read(blockServiceProvider).blockUser(userId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('User has been blocked.'),
                          backgroundColor: AppColors.successGreen,
                        ),
                      );
                    }
                  }
                } else if (value == 'report') {
                  _showReportUserDialog(context, ref, userId);
                }
              },
              itemBuilder: (context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'block',
                  child: Text('Block User'),
                ),
                const PopupMenuItem<String>(
                  value: 'report',
                  child: Text('Report User'),
                ),
              ],
            ),
        ],
      ),
      body: userProfileAsync.when(
        data: (userProfile) {
          if (userProfile == null) {
            return Center(
              child: Text(
                'User not found',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            );
          }
          return dustBunniesAsync.when(
            data: (dustBunnies) => SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header
                    Container(
                      padding: const EdgeInsets.all(24.0),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primaryMedium,
                            AppColors.primaryDark,
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          ProfilePictureAvatar(
                            user: userProfile,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            userProfile.name ?? 'Anonymous User',
                            style: AppTextStyles.headlineSmall.copyWith(
                              color: AppColors.textWhite,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (userProfile.bio != null &&
                              userProfile.bio!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              userProfile.bio!,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textLight,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          // Quick Stats Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildQuickStat(
                                'Level',
                                '${dustBunnies['level'] ?? 1}',
                                Icons.trending_up,
                                AppColors.brandCyan,
                              ),
                              _buildQuickStat(
                                'DustBunnies',
                                '${userProfile.dustBunnies}',
                                Icons.stars,
                                AppColors.accent,
                                imagePath: 'assets/images/dustbunnies/dustbunny_icon.png',
                              ),
                              _buildQuickStat(
                                'Streak',
                                '${userProfile.streak} days',
                                Icons.local_fire_department,
                                AppColors.mangoTangoStart,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Analytics Charts Section
                    UserAnalyticsCharts(userId: userId),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            loading: () => const Center(child: LoadingIndicator()),
            error: (error, stack) => Center(
              child: Text(
                'Error loading profile data',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.errorRed,
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: LoadingIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Error loading user profile',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.errorRed,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showReportUserDialog(
      BuildContext context, WidgetRef ref, String reportedUserId) async {
    final reportReasonController = TextEditingController();
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report User'),
        content: TextField(
          controller: reportReasonController,
          decoration: const InputDecoration(
            hintText: 'Enter reason for reporting',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final reason = reportReasonController.text;
              if (reason.isNotEmpty) {
                await ref
                    .read(friendServiceProvider)
                    .reportUser(userId: reportedUserId, reason: reason);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User reported')),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(
      String label, String value, IconData icon, Color color, {String? imagePath}) => Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: imagePath != null
              ? Image.asset(
                  imagePath,
                  width: 24,
                  height: 24,
                  errorBuilder: (context, error, stackTrace) => Icon(icon, color: color, size: 24),
                )
              : Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.textWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
}

Future<bool?> _showBlockConfirmDialog(BuildContext context, String userName) =>
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: Text('Are you sure you want to block $userName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Block'),
          ),
        ],
      ),
    );

final userProfileProvider =
    FutureProvider.family<UserProfile?, String>((ref, userId) async {
  final profileService = ref.watch(profileServiceProvider);
  return profileService.getUserProfile(userId);
});

final dustBunniesProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
  final dustBunniesService = ref.watch(dustBunniesServiceProvider);
  return dustBunniesService.getUserDustBunniesData(userId);
});
