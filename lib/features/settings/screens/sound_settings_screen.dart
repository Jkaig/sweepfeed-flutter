import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class SoundSettingsScreen extends ConsumerStatefulWidget {
  const SoundSettingsScreen({super.key});

  @override
  ConsumerState<SoundSettingsScreen> createState() => _SoundSettingsScreenState();
}

class _SoundSettingsScreenState extends ConsumerState<SoundSettingsScreen> {
  final List<String> _sounds = [
    'Default',
    'Chime',
    'Alert',
    'Subtle',
    'None',
  ];

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: const Text('Sounds & Vibration'),
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Vibration', style: TextStyle(color: Colors.white)),
            subtitle: const Text(
              'Vibrate when a new notification arrives',
              style: TextStyle(color: Colors.white70),
            ),
            value: settings.vibrationEnabled,
            activeThumbColor: AppColors.brandCyan,
            onChanged: notifier.setVibrationEnabled,
          ),
          const Divider(color: AppColors.primaryLight),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Notification Sound',
              style: AppTextStyles.titleMedium.copyWith(color: AppColors.brandCyan),
            ),
          ),
          ..._sounds.map((sound) => RadioListTile<String>(
            title: Text(sound, style: const TextStyle(color: Colors.white)),
            value: sound,
            groupValue: settings.notificationSound,
            activeColor: AppColors.brandCyan,
            onChanged: (value) {
              if (value != null) {
                notifier.setNotificationSound(value);
              }
            },
          ),),
        ],
      ),
    );
  }
}

