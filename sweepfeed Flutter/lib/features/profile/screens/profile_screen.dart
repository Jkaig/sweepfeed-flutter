import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/user_model.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/gamification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_back_button.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../email/screens/email_inbox_screen.dart';
import '../../email/services/email_service.dart';
import '../../gamification/screens/achievements_screen.dart';
import '../../notifications/screens/notification_preferences_screen.dart';
import '../../settings/screens/help_support_screen.dart';
import '../../subscription/screens/subscription_screen.dart';
import '../../subscription/services/tier_management_service.dart';
import '../widgets/profile_picture_avatar.dart';
import 'profile_settings_screen.dart';
import 'referral_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider);
    final currentUser = ref.watch(authServiceProvider).currentUser;
    final tierManagement = ref.watch(tierManagementServiceProvider);
    final currentTier = tierManagement.getCurrentTier();

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: AppColors.primaryDark,
        appBar: AppBar(
            title: const Text('Profile', style: AppTextStyles.titleLarge)),
        body: const Center(
          child: Text('Please log in.', style: AppTextStyles.bodyLarge),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: CustomAppBar(
        title: 'My Profile',
        leading: const CustomBackButton(),
        actions: [
          // Show inbox icon for Premium users, settings cog for others
          if (currentTier.hasEmailInbox)
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryMedium.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.brandCyan.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandCyan.withValues(alpha: 0.2),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.mail_outline, color: Colors.white),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const EmailInboxScreen(),
                      ),
                    ),
                  ),
                  // Unread count badge
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Consumer(
                      builder: (context, ref, child) {
                        final unreadCountAsync =
                            ref.watch(totalUnreadEmailCountProvider);
                        return unreadCountAsync.when(
                          data: (unreadCount) {
                            if (unreadCount > 0) {
                              return Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: AppColors.errorRed,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  unreadCount > 9
                                      ? '9+'
                                      : unreadCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryMedium.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.brandCyan.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandCyan.withValues(alpha: 0.2),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ProfileSettingsScreen(),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(userProfileProvider),
        color: AppColors.accent,
        backgroundColor: AppColors.primaryMedium,
        child: userProfile.when(
          data: (userProfile) {
            final displayName = currentUser.displayName ??
                userProfile?.name ??
                'Sweepstakes User';
            final email = currentUser.email ?? 'No email provided';

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Profile Header
                Column(
                  children: [
                    ProfilePictureAvatar(
                      user: userProfile ??
                          UserProfile(
                            id: currentUser.uid,
                            reference: FirebaseFirestore.instance
                                .collection('users')
                                .doc(currentUser.uid),
                          ),
                      radius: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      displayName,
                      style: AppTextStyles.headlineSmall
                          .copyWith(color: AppColors.textWhite),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textLight),
                    ),
                    if (userProfile?.bio != null &&
                        userProfile!.bio!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Text(
                          userProfile.bio!,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textWhite),
                        ),
                      ),
                    if (userProfile?.location != null &&
                        (userProfile?.location?.isNotEmpty ?? false))
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              userProfile?.location ?? '',
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Divider(color: AppColors.primaryLight.withValues(alpha: 0.5)),

                // Menu Items
                _buildMenuTile(
                  context: context,
                  icon: Icons.edit_outlined,
                  title: 'Edit Profile',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ProfileSettingsScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _buildMenuTile(
                  context: context,
                  icon: Icons.notifications_outlined,
                  title: 'Notification Preferences',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationPreferencesScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _buildMenuTile(
                  context: context,
                  icon: Icons.star_outline_rounded,
                  title: 'Subscription',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SubscriptionScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _buildMenuTile(
                  context: context,
                  icon: Icons.people_alt_outlined,
                  title: 'Refer a Friend',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ReferralScreen()),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _buildMenuTile(
                  context: context,
                  icon: Icons.stars,
                  title: 'Upgrade to Pro',
                  highlight: true,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SubscriptionScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _buildMenuTile(
                  context: context,
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const HelpSupportScreen(),
                      ),
                    );
                  },
                ),

                // Achievements Section
                Padding(
                  padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
                  child: Text(
                    'My Achievements',
                    style: AppTextStyles.titleLarge
                        .copyWith(color: AppColors.textWhite),
                  ),
                ),
                _BadgesSection(userId: currentUser.uid),
                Divider(color: AppColors.primaryLight.withValues(alpha: 0.5)),

                // Stats Section
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                  child: Text(
                    'My Stats',
                    style: AppTextStyles.titleLarge
                        .copyWith(color: AppColors.textWhite),
                  ),
                ),
                _StatsSection(userProfile: userProfile),
                Divider(color: AppColors.primaryLight.withValues(alpha: 0.5)),

                // Contest History Section
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                  child: Text(
                    'Contest Entry History',
                    style: AppTextStyles.titleLarge
                        .copyWith(color: AppColors.textWhite),
                  ),
                ),
                _ContestHistorySection(userId: currentUser.uid),
                const SizedBox(height: 8),
                Text(
                  'Note: Contest win/loss status is not currently tracked.',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Sign Out Button
                Center(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          AppColors.errorRed.withValues(alpha: 0.15),
                      foregroundColor: AppColors.errorRed,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                      textStyle: AppTextStyles.labelLarge
                          .copyWith(color: AppColors.errorRed),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: AppColors.primaryMedium,
                          title: Text(
                            'Confirm Sign Out',
                            style: AppTextStyles.titleMedium
                                .copyWith(color: AppColors.textWhite),
                          ),
                          content: Text(
                            'Are you sure you want to sign out?',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textLight),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text(
                                'Cancel',
                                style: AppTextStyles.labelLarge
                                    .copyWith(color: AppColors.textLight),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text(
                                'Sign Out',
                                style: AppTextStyles.labelLarge
                                    .copyWith(color: AppColors.errorRed),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && context.mounted) {
                        await FirebaseAuth.instance.signOut();
                        // Navigation handled by AuthWrapper
                      }
                    },
                  ),
                ),
                const SizedBox(height: 30),
              ],
            );
          },
          loading: () => const Center(child: LoadingIndicator()),
          error: (error, stackTrace) => Center(
            child: Text(
              'Error: $error',
              style:
                  AppTextStyles.bodyMedium.copyWith(color: AppColors.errorRed),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildMenuTile({
  required BuildContext context,
  required IconData icon,
  required String title,
  required VoidCallback onTap,
  bool highlight = false,
}) =>
    Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        gradient: highlight
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.brandCyan.withValues(alpha: 0.15),
                  AppColors.primary.withValues(alpha: 0.15),
                ],
              )
            : null,
        color:
            highlight ? null : AppColors.primaryMedium.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight
              ? AppColors.brandCyan.withValues(alpha: 0.3)
              : AppColors.primaryLight.withValues(alpha: 0.2),
        ),
        boxShadow: highlight
            ? [
                BoxShadow(
                  color: AppColors.brandCyan.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: highlight
                ? AppColors.brandCyan.withValues(alpha: 0.2)
                : AppColors.primaryLight.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: highlight ? AppColors.brandCyan : AppColors.textLight,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: AppTextStyles.bodyLarge.copyWith(
            color: Colors.white,
            fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: highlight ? AppColors.brandCyan : AppColors.textLight,
        ),
        onTap: onTap,
      ),
    );

// Badges Section Widget
class _BadgesSection extends StatelessWidget {
  const _BadgesSection({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context) => StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: LoadingIndicator(size: 20));
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              !snapshot.data!.exists) {
            return Center(
              child: Text(
                'Could not load badges.',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textMuted),
              ),
            );
          }

          final userData = snapshot.data!.data()! as Map<String, dynamic>;
          final gamificationData =
              userData['gamification'] as Map<String, dynamic>?;
          final badgesData =
              gamificationData?['badges'] as Map<String, dynamic>?;
          final collectedBadgeIds = (badgesData?['collected'] as List<dynamic>?)
                  ?.map((id) => id.toString())
                  .toList() ??
              [];

          if (collectedBadgeIds.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'No badges earned yet. Keep exploring!',
                  style: AppTextStyles.bodyLarge
                      .copyWith(color: AppColors.textMuted),
                ),
              ),
            );
          }

          final badgeWidgets = <Widget>[];
          for (final badgeId in collectedBadgeIds) {
            final badgeMeta = DustBunniesService.getBadgeById(badgeId);
            if (badgeMeta != null) {
              badgeWidgets.add(
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${badgeMeta.name}: ${badgeMeta.description}',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textWhite),
                        ),
                        backgroundColor: AppColors.primaryMedium,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  },
                  child: Chip(
                    avatar:
                        Icon(badgeMeta.icon, color: AppColors.accent, size: 18),
                    label: Text(
                      badgeMeta.name,
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.textWhite),
                    ),
                    backgroundColor:
                        AppColors.primaryLight.withValues(alpha: 0.3),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              );
            }
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              alignment: WrapAlignment.center,
              children: [
                ...badgeWidgets,
                if (collectedBadgeIds.isNotEmpty)
                  ActionChip(
                    label: const Text('View All'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AchievementsScreen(),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      );
}

// Stats Section Widget
class _StatsSection extends StatelessWidget {
  const _StatsSection({this.userProfile});
  final UserProfile? userProfile;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          _buildStatRow(
            context,
            'Total Entries',
            userProfile?.totalEntries.toString() ?? '0',
          ),
          _buildStatRow(
            context,
            'Active Entries',
            userProfile?.activeEntries.toString() ?? '0',
          ),
          _buildStatRow(
            context,
            'Total Wins',
            userProfile?.totalWins.toString() ?? '0',
          ),
          _buildStatRow(
            context,
            'Win Rate',
            '${userProfile?.winRate.toStringAsFixed(1) ?? '0.0'}%',
          ),
          _buildStatRow(
              context, 'Points', userProfile?.points.toString() ?? '0'),
          _buildStatRow(
            context,
            'Current Streak',
            '${userProfile?.streak ?? 0} days',
          ),
        ],
      );

  Widget _buildStatRow(BuildContext context, String label, String value) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style:
                  AppTextStyles.bodyLarge.copyWith(color: AppColors.textWhite),
            ),
            Text(
              value,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
}

// Contest History Section Widget
class _ContestHistorySection extends StatelessWidget {
  const _ContestHistorySection({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('entries')
            .where('userId', isEqualTo: userId)
            .orderBy('enteredAt', descending: true)
            .limit(5)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: LoadingIndicator(size: 20));
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'No contest entries yet.',
                  style: AppTextStyles.bodyLarge
                      .copyWith(color: AppColors.textMuted),
                ),
              ),
            );
          }

          return Column(
            children: snapshot.data!.docs.map((doc) {
              final entry = doc.data()! as Map<String, dynamic>;
              final contestTitle = entry['contestTitle'] ?? 'Unknown Contest';
              final enteredAt = entry['enteredAt'] as Timestamp?;
              final dateString = enteredAt != null
                  ? DateFormat('MMM d, y').format(enteredAt.toDate())
                  : 'Unknown Date';

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      const Icon(Icons.emoji_events, color: AppColors.accent),
                ),
                title: Text(
                  contestTitle,
                  style: AppTextStyles.bodyLarge
                      .copyWith(color: AppColors.textWhite),
                ),
                subtitle: Text(
                  'Entered on $dateString',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textMuted),
                ),
                trailing:
                    const Icon(Icons.chevron_right, color: AppColors.textLight),
              );
            }).toList(),
          );
        },
      );
}
