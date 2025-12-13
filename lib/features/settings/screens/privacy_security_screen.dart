import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_back_button.dart';
import '../../../core/widgets/list_tile_item.dart';
import 'data_management_screen.dart';
import 'login_history_screen.dart';

class PrivacySecurityScreen extends ConsumerWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: const CustomAppBar(
          title: 'Privacy & Security',
          leading: CustomBackButton(),
        ),
        backgroundColor: AppColors.primaryDark,
        body: ListView(
          children: [
            const SizedBox(height: 16),
            ListTileItem(
              icon: Icons.history_outlined,
              title: 'Login History',
              subtitle: 'View your recent login activity',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const LoginHistoryScreen(),
                  ),
                );
              },
            ),
            const Divider(color: AppColors.primaryLight),
            ListTileItem(
              icon: Icons.data_usage_outlined,
              title: 'Manage Your Data',
              subtitle: 'Download or delete your account data',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const DataManagementScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      );
}
