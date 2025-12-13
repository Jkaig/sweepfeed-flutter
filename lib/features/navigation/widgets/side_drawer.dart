import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../charity/screens/charity_impact_screen.dart';
import '../../email/screens/email_inbox_screen.dart';
import '../../friends/screens/friend_requests_screen.dart';
import '../../friends/screens/friends_list_screen.dart';
import '../../gamification/screens/daily_challenges_screen.dart';
import '../../gamification/screens/leaderboard_screen.dart';
import '../../impact/screens/my_impact_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../profile/widgets/profile_picture_avatar.dart';
import '../../settings/screens/settings_screen.dart';
import '../../winners/screens/winners_screen.dart';

class SideDrawer extends ConsumerWidget {
  const SideDrawer({super.key});

  IconData _getProviderIcon(String? provider) {
    if (provider == null) return Icons.person;
    switch (provider.toLowerCase()) {
      case 'google':
      case 'google.com':
        return Icons.g_mobiledata;
      case 'apple':
      case 'apple.com':
        return Icons.apple;
      case 'phone':
        return Icons.phone_android;
      case 'password':
      case 'email':
        return Icons.email;
      default:
        return Icons.person;
    }
  }

  String _getProviderDisplayName(String? provider) {
    if (provider == null) return '';
    switch (provider.toLowerCase()) {
      case 'google':
      case 'google.com':
        return 'Google';
      case 'apple':
      case 'apple.com':
        return 'Apple';
      case 'phone':
        return 'Phone';
      case 'password':
      case 'email':
        return 'Email';
      default:
        return provider;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider);
    final userName = userProfile.when(
      data: (user) => user?.name,
      loading: () => 'User',
      error: (_, __) => 'User',
    );
    final userEmail = userProfile.when(
      data: (user) => user?.email,
      loading: () => '',
      error: (_, __) => '',
    );
    final signInProvider = userProfile.when(
      data: (user) => user?.signInProvider,
      loading: () => null,
      error: (_, __) => null,
    );

    return Drawer(
      child: Container(
        color: AppColors.primaryDark,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                userName ?? 'Contests Fan',
                style: AppTextStyles.titleLarge,
              ),
              accountEmail: Row(
                children: [
                  if (signInProvider != null) ...[
                    Icon(
                      _getProviderIcon(signInProvider),
                      size: 16,
                      color: AppColors.textLight,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Signed in with ${_getProviderDisplayName(signInProvider)}',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textLight),
                    ),
                  ] else
                    Text(userEmail ?? '', style: AppTextStyles.bodyMedium),
                ],
              ),
              currentAccountPicture: userProfile.when(
                data: (profile) {
                  if (profile != null) {
                    return ProfilePictureAvatar(
                      user: profile,
                      radius: 40,
                    );
                  }
                  return CircleAvatar(
                    backgroundColor: AppColors.accent,
                    child: Image.asset('assets/icon/appicon.png'),
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => CircleAvatar(
                  backgroundColor: AppColors.accent,
                  child: Image.asset('assets/icon/appicon.png'),
                ),
              ),
              decoration: const BoxDecoration(
                color: AppColors.primaryMedium,
              ),
            ),
            _buildDrawerItem(
              icon: Icons.person_outline,
              title: 'Profile',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              ),
            ),
            _buildDrawerItem(
              icon: Icons.leaderboard_outlined,
              title: 'Leaderboard',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LeaderboardScreen(),
                ),
              ),
            ),
            _buildDrawerItem(
              icon: Icons.people_outline,
              title: 'Friends',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FriendsListScreen(),
                ),
              ),
            ),
            _buildFriendRequestsTile(context, ref),
            _buildDrawerItem(
              icon: Icons.military_tech_outlined,
              title: 'Daily Challenges',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DailyChallengesScreen(),
                ),
              ),
            ),
            _buildDrawerItem(
              icon: Icons.share_outlined,
              title: 'Share with Friends',
              onTap: () => _shareWithFriends(context, ref),
            ),
            _buildDrawerItem(
              icon: Icons.card_giftcard,
              title: 'Winners',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const WinnersScreen(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.mail_outline,
              title: 'Email Inbox',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const EmailInboxScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            _buildDrawerItem(
              icon: Icons.volunteer_activism,
              title: 'Charity Impact',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CharityImpactScreen(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.favorite,
              title: 'My Impact',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const MyImpactScreen(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.settings,
              title: 'Settings',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
            const Divider(color: AppColors.primaryLight),
            _buildDrawerItem(
              icon: Icons.logout,
              title: 'Logout',
              onTap: () => ref.read(authServiceProvider).signOut(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
  }) =>
      ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        onTap: onTap,
        trailing: trailing,
      );

  Widget _buildFriendRequestsTile(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(friendRequestsProvider);
    return requests.when(
      data: (snapshot) {
        final count = snapshot.docs.length;
        return _buildDrawerItem(
          icon: Icons.group_add_outlined,
          title: 'Friend Requests',
          trailing: count > 0
              ? CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.accent,
                  child: Text(
                    count.toString(),
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : null,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FriendRequestsScreen(),
            ),
          ),
        );
      },
      loading: () => _buildDrawerItem(
        icon: Icons.group_add_outlined,
        title: 'Friend Requests',
        onTap: () {},
      ),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }

  Future<void> _shareWithFriends(BuildContext context, WidgetRef ref) async {
    final referralLink =
        await ref.read(referralServiceProvider).generateReferralLink('123');
    Share.share('Join me on SweepFeed! $referralLink');
  }
}
