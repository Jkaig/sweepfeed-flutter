import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/services/unified_notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/logger.dart';
import '../../../core/widgets/animated_gradient_background.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_back_button.dart';
import '../../../core/widgets/glass_settings_tile.dart';
import '../../../core/widgets/loading_indicator.dart';

class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  _NotificationPreferencesScreenState createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends ConsumerState<NotificationPreferencesScreen> {
  bool _isLoading = true;
  NotificationSettings? _settings;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final userId = ref.read(firebaseAuthProvider).currentUser?.uid;
      if (userId == null) return;

      final settings = await ref
          .read(unifiedNotificationServiceProvider)
          .getSettings(userId);
      
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    } catch (e) {
      logger.e('Error loading notification settings', error: e);
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSetting(String key, bool value) async {
    final userId = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (userId == null || _settings == null) return;

    // Create updated types map
    final currentTypes = Map<String, bool>.from(_settings!.push.types);
    currentTypes[key] = value;

    // Create updated settings object
    final updatedSettings = NotificationSettings(
      permissionStatus: _settings!.permissionStatus,
      push: PushSettings(
        enabled: _settings!.push.enabled,
        types: currentTypes,
      ),
      email: _settings!.email,
      sms: _settings!.sms,
      quietHours: _settings!.quietHours,
      preferences: _settings!.preferences,
    );

    // Update state immediately for UI responsiveness
    setState(() {
      _settings = updatedSettings;
    });

    try {
      await ref
          .read(unifiedNotificationServiceProvider)
          .updateSettings(userId, updatedSettings);
    } catch (e) {
      logger.e('Error updating notification setting $key', error: e);
      // Revert on error (could add more sophisticated error handling/rollback here)
      _loadSettings();
    }
  }

  bool _getValue(String key) {
    return _settings?.push.types[key] ?? false;
  }

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          const Positioned.fill(child: AnimatedGradientBackground()),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: const CustomAppBar(
              title: 'Notification Preferences',
              leading: CustomBackButton(),
            ),
            body: _isLoading
                ? const Center(child: LoadingIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sweepstakes Notifications Section
                        _buildSectionHeader('Sweepstakes Notifications'),
                        const SizedBox(height: 8),
                        _buildPreferenceTile(
                          'New Sweepstakes',
                          'Get notified when new contests are available',
                          'newSweepstakes',
                          Icons.card_giftcard_outlined,
                        ),
                        const SizedBox(height: 12),
                        _buildPreferenceTile(
                          'Ending Soon Alerts',
                          'Get notified when contests are about to end',
                          'endingSoon',
                          Icons.schedule,
                        ),
                        const SizedBox(height: 12),
                        _buildPreferenceTile(
                          'High Value Prizes',
                          'Get alerts for contests with valuable prizes',
                          'highValue',
                          Icons.stars_outlined,
                        ),
                        
                        const SizedBox(height: 24),

                        // Community & Updates Section
                        _buildSectionHeader('Community & Updates'),
                        const SizedBox(height: 8),
                        _buildPreferenceTile(
                          'Winner Announcements',
                          'Get notified about recent contests winners',
                          'wins',
                          Icons.emoji_events_outlined,
                        ),
                        const SizedBox(height: 12),
                        _buildPreferenceTile(
                          'Weekly Roundup',
                          'Receive a weekly summary of new opportunities',
                          'weeklyRoundup',
                          Icons.article_outlined,
                        ),

                        const SizedBox(height: 24),

                        // Marketing & Security Section
                        _buildSectionHeader('Marketing & Security'),
                        const SizedBox(height: 8),
                        _buildPreferenceTile(
                          'Personalized Alerts',
                          'Receive special offers and preferences',
                          'personalizedAlerts',
                          Icons.local_offer_outlined,
                        ),
                        const SizedBox(height: 12),
                        _buildPreferenceTile(
                          'Security Alerts',
                          'Important account and security notifications',
                          'securityAlerts',
                          Icons.security,
                          isRequired: true,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      );

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.brandCyan,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildPreferenceTile(
    String title,
    String subtitle,
    String key,
    IconData icon, {
    bool isRequired = false,
  }) {
    final currentValue = _getValue(key);

    return GlassSettingsTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: isRequired
          ? () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Security alerts cannot be disabled for your account safety',
                  ),
                  backgroundColor: AppColors.warningOrange,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          : () => _updateSetting(key, !currentValue),
      trailing: Transform.scale(
        scale: 0.8,
        child: Switch(
          value: currentValue,
          onChanged: isRequired
              ? (value) {
                  if (!value) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Security alerts cannot be disabled for your account safety',
                        ),
                        backgroundColor: AppColors.warningOrange,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  _updateSetting(key, value);
                }
              : (value) => _updateSetting(key, value),
          activeThumbColor: AppColors.brandCyan,
          activeTrackColor: AppColors.brandCyan.withValues(alpha: 0.3),
          inactiveThumbColor: AppColors.textLight,
          inactiveTrackColor: AppColors.primaryLight,
        ),
      ),
    );
  }
}
