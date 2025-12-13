import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/animated_gradient_background.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_back_button.dart';
import '../../../core/widgets/glass_settings_tile.dart';

class PrivacySecurityScreen extends ConsumerWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Stack(
        children: [
          const Positioned.fill(child: AnimatedGradientBackground()),
          Scaffold(
            appBar: const CustomAppBar(
              title: 'Privacy & Security',
              leading: CustomBackButton(),
            ),
            backgroundColor: Colors.transparent,
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GlassSettingsTile(
                  icon: Icons.history,
                  title: 'Login History',
                  subtitle: 'View your recent login activity',
                  onTap: () {
                    // Navigate to Login History
                  },
                ),
                const SizedBox(height: 12),
                GlassSettingsTile(
                  icon: Icons.data_usage,
                  title: 'Request Data',
                  subtitle: 'Download a copy of your data',
                  onTap: () {
                    // Handle data request
                  },
                ),
                const SizedBox(height: 12),
                GlassSettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  subtitle: 'Read our privacy policy',
                  onTap: () {
                    // Open privacy policy
                  },
                ),
              ],
            ),
          ),
        ],
      );
}
