import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/animated_gradient_background.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_back_button.dart';
import '../../../core/widgets/glass_settings_tile.dart';
import 'change_email_screen.dart';
import 'delete_account_screen.dart';

class AccountSettingsScreen extends ConsumerWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Stack(
        children: [
          const Positioned.fill(child: AnimatedGradientBackground()),
          Scaffold(
            appBar: const CustomAppBar(
              title: 'Account Settings',
              leading: CustomBackButton(),
            ),
            backgroundColor: Colors.transparent,
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GlassSettingsTile(
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
                const SizedBox(height: 12),
                GlassSettingsTile(
                  icon: Icons.delete_forever_outlined,
                  title: 'Delete Account',
                  subtitle: 'Permanently delete your account',
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
          ),
        ],
      );
}
