import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/logger.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_back_button.dart';

class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  _NotificationPreferencesScreenState createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends ConsumerState<NotificationPreferencesScreen> {
  final Map<String, bool> _preferences = {
    'new_contests': false,
    'ending_soon': false,
    'high_value': false,
    'winner_announcements': false,
    'weekly_digest': false,
    'promotional': false,
    'security_alerts': true,
  };

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _preferences['new_contests'] =
          prefs.getBool('new_contests') ?? false;
      _preferences['ending_soon'] = prefs.getBool('ending_soon') ?? false;
      _preferences['high_value'] = prefs.getBool('high_value') ?? false;
      _preferences['winner_announcements'] =
          prefs.getBool('winner_announcements') ?? false;
      _preferences['weekly_digest'] = prefs.getBool('weekly_digest') ?? false;
      _preferences['promotional'] = prefs.getBool('promotional') ?? false;
      _preferences['security_alerts'] =
          prefs.getBool('security_alerts') ?? true;
    });
  }

  Future<void> _togglePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _preferences[key] = value;
    });
    await prefs.setBool(key, value);

    // Subscribe/unsubscribe to relevant topics
    try {
      if (value) {
        await ref
            .read(unifiedNotificationServiceProvider)
            .subscribeToTopic(key);
      } else {
        await ref
            .read(unifiedNotificationServiceProvider)
            .unsubscribeFromTopic(key);
      }
    } catch (e) {
      // Handle subscription errors gracefully
      logger.w('Failed to manage subscription for $key', error: e);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.primaryDark,
        appBar: const CustomAppBar(
          title: 'Notification Preferences',
          leading: CustomBackButton(),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sweepstakes Notifications Section
              _buildNotificationSection(
                'Sweepstakes Notifications',
                'Stay updated on new opportunities and deadlines',
                [
                  _buildPreferenceTile(
                    'New Sweepstakes',
                    'Get notified when new contests are available',
                    'new_contests',
                    Icons.card_giftcard_outlined,
                  ),
                  _buildPreferenceTile(
                    'Ending Soon Alerts',
                    'Get notified when contests are about to end',
                    'ending_soon',
                    Icons.schedule,
                  ),
                  _buildPreferenceTile(
                    'High Value Prizes',
                    'Get alerts for contests with valuable prizes',
                    'high_value',
                    Icons.stars_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Community & Updates Section
              _buildNotificationSection(
                'Community & Updates',
                'Stay connected with winners and app updates',
                [
                  _buildPreferenceTile(
                    'Winner Announcements',
                    'Get notified about recent contests winners',
                    'winner_announcements',
                    Icons.emoji_events_outlined,
                  ),
                  _buildPreferenceTile(
                    'Weekly Digest',
                    'Receive a weekly summary of new opportunities',
                    'weekly_digest',
                    Icons.article_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Marketing & Security Section
              _buildNotificationSection(
                'Marketing & Security',
                'Control promotional content and security alerts',
                [
                  _buildPreferenceTile(
                    'Promotional Offers',
                    'Receive special offers and partner promotions',
                    'promotional',
                    Icons.local_offer_outlined,
                  ),
                  _buildPreferenceTile(
                    'Security Alerts',
                    'Important account and security notifications',
                    'security_alerts',
                    Icons.security,
                    isRequired: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildNotificationSection(
    String title,
    String description,
    List<Widget> tiles,
  ) =>
      Card(
        color: AppColors.primaryMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.brandCyan.withValues(alpha: 0.3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              ...tiles.map(
                (tile) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: tile,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildPreferenceTile(
    String title,
    String subtitle,
    String key,
    IconData icon, {
    bool isRequired = false,
  }) {
    final currentValue = _preferences[key] ?? false;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: currentValue
              ? AppColors.brandCyan.withValues(alpha: 0.5)
              : AppColors.primaryLight.withValues(alpha: 0.3),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: currentValue
                ? AppColors.brandCyan.withValues(alpha: 0.2)
                : AppColors.primaryLight.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: currentValue ? AppColors.brandCyan : AppColors.textLight,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isRequired)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warningOrange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppColors.warningOrange.withValues(alpha: 0.5),
                  ),
                ),
                child: const Text(
                  'REQUIRED',
                  style: TextStyle(
                    color: AppColors.warningOrange,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textLight,
            fontSize: 12,
          ),
        ),
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
                    _togglePreference(key, value);
                  }
                : (value) => _togglePreference(key, value),
            activeThumbColor: AppColors.brandCyan,
            activeTrackColor: AppColors.brandCyan.withValues(alpha: 0.3),
            inactiveThumbColor: AppColors.textLight,
            inactiveTrackColor: AppColors.primaryLight,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }
}
