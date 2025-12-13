import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class FrequencySettingsScreen extends ConsumerStatefulWidget {
  const FrequencySettingsScreen({super.key});

  @override
  ConsumerState<FrequencySettingsScreen> createState() => _FrequencySettingsScreenState();
}

class _FrequencySettingsScreenState extends ConsumerState<FrequencySettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: const Text('Frequency Control'),
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Limit',
                  style: AppTextStyles.titleMedium.copyWith(color: AppColors.textWhite),
                ),
                const SizedBox(height: 8),
                Text(
                  'Maximum number of notifications per day (excluding critical alerts)',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      settings.maxNotificationsPerDay.toInt().toString(),
                      style: AppTextStyles.headlineMedium.copyWith(color: AppColors.brandCyan),
                    ),
                    Expanded(
                      child: Slider(
                        value: settings.maxNotificationsPerDay,
                        min: 1,
                        max: 50,
                        divisions: 49,
                        activeColor: AppColors.brandCyan,
                        onChanged: notifier.setMaxNotificationsPerDay,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Group Notifications', style: TextStyle(color: Colors.white)),
            subtitle: const Text(
              'Bundle similar notifications together (e.g. "3 new contests")',
              style: TextStyle(color: Colors.white70),
            ),
            value: settings.groupNotifications,
            activeThumbColor: AppColors.brandCyan,
            onChanged: notifier.setGroupNotifications,
          ),
        ],
      ),
    );
  }
}

