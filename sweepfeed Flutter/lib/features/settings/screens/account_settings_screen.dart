import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_back_button.dart';
import '../../../core/widgets/list_tile_item.dart';
import 'change_email_screen.dart';
import 'change_password_screen.dart';
import 'delete_account_screen.dart';

class AccountSettingsScreen extends ConsumerWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: const CustomAppBar(
          title: 'Account Settings',
          leading: CustomBackButton(),
        ),
        backgroundColor: AppColors.primaryDark,
        body: ListView(
          children: [
            const SizedBox(height: 16),
            ListTileItem(
              icon: Icons.email_outlined,
              title: 'Change Email',
              subtitle: 'Update your email address',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ChangeEmailScreen(),
                  ),
                );
              },
            ),
            ListTileItem(
              icon: Icons.lock_outline,
              title: 'Change Password',
              subtitle: 'Update your password',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ChangePasswordScreen(),
                  ),
                );
              },
            ),
            const Divider(color: AppColors.primaryLight),
            ListTileItem(
              icon: Icons.delete_forever_outlined,
              title: 'Delete Account',
              subtitle: 'Permanently delete your account',
              iconColor: AppColors.errorRed,
              titleColor: AppColors.errorRed,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const DeleteAccountScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      );
}
