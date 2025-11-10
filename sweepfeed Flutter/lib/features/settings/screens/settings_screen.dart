import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/list_tile_item.dart';
import '../../notifications/screens/notification_preferences_screen.dart';
import 'about_screen.dart';
import 'account_settings_screen.dart';
import 'appearance_settings_screen.dart';
import 'help_support_screen.dart';
import 'privacy_security_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(
          title: Text(
            'Settings',
            style:
                AppTextStyles.titleLarge.copyWith(color: AppColors.textWhite),
          ),
          backgroundColor: AppColors.primaryMedium,
        ),
        backgroundColor: AppColors.primaryDark,
        body: ListView(
          children: [
            const SizedBox(height: 16),
            ListTileItem(
              icon: Icons.account_circle_outlined,
              title: 'Account',
              subtitle: 'Manage your account details',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AccountSettingsScreen(),
                  ),
                );
              },
            ),
            ListTileItem(
              icon: Icons.palette_outlined,
              title: 'Appearance',
              subtitle: 'Customize the look and feel',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AppearanceSettingsScreen(),
                  ),
                );
              },
            ),
            ListTileItem(
              icon: Icons.notifications_none,
              title: 'Notifications',
              subtitle: 'Choose your notification preferences',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationPreferencesScreen(),
                  ),
                );
              },
            ),
            ListTileItem(
              icon: Icons.security_outlined,
              title: 'Privacy & Security',
              subtitle: 'Control your data and security',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacySecurityScreen(),
                  ),
                );
              },
            ),
            const Divider(color: AppColors.primaryLight),
            ListTileItem(
              icon: Icons.help_outline,
              title: 'Help & Support',
              subtitle: 'Get help and support',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HelpSupportScreen(),
                  ),
                );
              },
            ),
            ListTileItem(
              icon: Icons.info_outline,
              title: 'About',
              subtitle: 'App version and legal information',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AboutScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      );
}
