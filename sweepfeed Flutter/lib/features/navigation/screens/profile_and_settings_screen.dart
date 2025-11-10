import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../profile/screens/profile_screen.dart';
import '../../settings/screens/settings_screen.dart';

class ProfileAndSettingsScreen extends ConsumerWidget {
  const ProfileAndSettingsScreen({super.key});

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

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.accent,
                  child: Text(
                    userName?.substring(0, 1).toUpperCase() ?? 'S',
                    style: AppTextStyles.headlineMedium
                        .copyWith(color: AppColors.primaryDark),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName ?? 'Sweepstakes Fan',
                      style: AppTextStyles.titleLarge
                          .copyWith(color: Colors.white),
                    ),
                    Text(
                      userEmail ?? '',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textLight),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildNavItem(
              icon: Icons.person_outline,
              text: 'Profile',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              ),
            ),
            _buildNavItem(
              icon: Icons.settings_outlined,
              text: 'Settings',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              ),
            ),
            const Divider(color: AppColors.primaryLight, height: 32),
            _buildNavItem(
              icon: Icons.logout,
              text: 'Logout',
              onTap: () => ref.read(authServiceProvider).signOut(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String text,
    required GestureTapCallback onTap,
  }) =>
      ListTile(
        leading: Icon(icon, color: AppColors.textWhite),
        title: Text(
          text,
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textWhite),
        ),
        onTap: onTap,
      );
}
