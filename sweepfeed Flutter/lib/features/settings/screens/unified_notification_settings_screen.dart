import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user_model.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/permission_manager.dart';
import '../../../core/services/unified_notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

final notificationSettingsProvider =
    FutureProvider.autoDispose<NotificationSettings>((ref) async {
  final currentUser = ref.watch(firebaseServiceProvider).currentUser;
  if (currentUser == null) throw Exception('No user logged in');

  return unifiedNotificationService.getSettings(currentUser.uid);
});

final userProfileProvider =
    FutureProvider.autoDispose<UserProfile?>((ref) async {
  final currentUser = ref.watch(firebaseServiceProvider).currentUser;
  if (currentUser == null) return null;

  final authService = ref.watch(authServiceProvider);
  return await authService.getUserProfile();
});

class UnifiedNotificationSettingsScreen extends ConsumerStatefulWidget {
  const UnifiedNotificationSettingsScreen({super.key});

  @override
  ConsumerState<UnifiedNotificationSettingsScreen> createState() =>
      _UnifiedNotificationSettingsScreenState();
}

class _UnifiedNotificationSettingsScreenState
    extends ConsumerState<UnifiedNotificationSettingsScreen> {
  NotificationSettings? _settings;
  NotificationPermissionStatus _permissionStatus =
      NotificationPermissionStatus.notDetermined;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionStatus();
  }

  Future<void> _checkPermissionStatus() async {
    final status = await permissionManager.checkStatus();
    setState(() {
      _permissionStatus = status;
    });
  }

  Future<void> _requestPermission() async {
    setState(() => _isLoading = true);

    final status = await permissionManager.request();

    setState(() {
      _permissionStatus = status;
      _isLoading = false;
    });

    if (status == NotificationPermissionStatus.granted) {
      final currentUser = ref.read(firebaseServiceProvider).currentUser;
      if (currentUser != null) {
        await unifiedNotificationService.initialize(currentUser.uid);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifications enabled successfully!'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    }
  }

  bool _isPremiumUser(UserProfile? user) {
    if (user == null) return false;
    if (user.tier == 'premium') return true;
    if (user.premiumUntil != null) {
      return user.premiumUntil!.toDate().isAfter(DateTime.now());
    }
    return false;
  }

  Future<void> _saveSettings() async {
    if (_settings == null || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      final currentUser = ref.read(firebaseServiceProvider).currentUser;
      if (currentUser == null) throw Exception('No user logged in');

      await unifiedNotificationService.updateSettings(
        currentUser.uid,
        _settings!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Settings saved successfully!'),
              ],
            ),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(notificationSettingsProvider);
    final userAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        backgroundColor: AppColors.primaryMedium,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.brandCyan),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notification Settings',
          style:
              AppTextStyles.headingMedium.copyWith(color: AppColors.textWhite),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppColors.brandCyan),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveSettings,
              child: Text(
                'Save',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.brandCyan,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: settingsAsync.when(
        data: (settings) {
          _settings ??= settings;

          return userAsync.when(
            data: _buildContent,
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text(
                'Error loading user profile',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.errorRed),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Error loading settings',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.errorRed),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(UserProfile? user) {
    final isPremium = _isPremiumUser(user);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPermissionStatusCard(),
          if (isPremium) _buildPremiumBadge(),
          const SizedBox(height: 16),
          _buildSectionHeader('Push Notifications'),
          _buildPushNotificationMasterSwitch(),
          if (_settings!.push.enabled) ...[
            const SizedBox(height: 16),
            _buildSectionHeader('Free Tier Notifications'),
            _buildFreeNotificationTypes(isPremium),
            const SizedBox(height: 16),
            _buildSectionHeader('Premium Notifications'),
            _buildPremiumNotificationTypes(isPremium),
          ],
          const SizedBox(height: 16),
          _buildSectionHeader('Email Notifications'),
          _buildEmailSettings(),
          if (isPremium) ...[
            const SizedBox(height: 16),
            _buildSectionHeader('SMS Notifications (Premium)'),
            _buildSmsSettings(),
            const SizedBox(height: 16),
            _buildSectionHeader('Quiet Hours (Premium)'),
            _buildQuietHoursSettings(),
          ],
          const SizedBox(height: 16),
          _buildSectionHeader('Preferences'),
          _buildPreferencesSettings(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPermissionStatusCard() {
    final color = _permissionStatus == NotificationPermissionStatus.granted
        ? AppColors.successGreen
        : AppColors.warningOrange;

    final icon = _permissionStatus == NotificationPermissionStatus.granted
        ? Icons.notifications_active
        : Icons.notifications_off;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  permissionManager
                      .getPermissionStatusMessage(_permissionStatus),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_permissionStatus !=
                    NotificationPermissionStatus.granted) ...[
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _requestPermission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandCyan,
                      foregroundColor: AppColors.textWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text('Enable Notifications'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBadge() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              'Premium Member - Unlimited Notifications',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );

  Widget _buildSectionHeader(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Text(
          title.toUpperCase(),
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.brandCyan,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      );

  Widget _buildPushNotificationMasterSwitch() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: _buildContainerDecoration(),
        child: SwitchListTile(
          value: _settings!.push.enabled,
          onChanged: (value) {
            setState(() {
              _settings = NotificationSettings(
                permissionStatus: _settings!.permissionStatus,
                push:
                    PushSettings(enabled: value, types: _settings!.push.types),
                email: _settings!.email,
                sms: _settings!.sms,
                quietHours: _settings!.quietHours,
                preferences: _settings!.preferences,
              );
            });
          },
          title: Text(
            'Push Notifications',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            'Receive alerts on your device',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
          ),
          activeThumbColor: AppColors.brandCyan,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      );

  Widget _buildFreeNotificationTypes(bool isPremium) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: _buildContainerDecoration(),
        child: Column(
          children: [
            _buildNotificationToggle(
              'newSweepstakes',
              'New Sweepstakes',
              isPremium ? 'Unlimited alerts' : 'Up to 5 per day',
              Icons.card_giftcard,
              false,
              isPremium,
            ),
            _buildDivider(),
            _buildNotificationToggle(
              'endingSoon',
              'Ending Soon',
              isPremium ? 'Unlimited alerts' : 'Up to 5 per day',
              Icons.schedule,
              false,
              isPremium,
            ),
            _buildDivider(),
            _buildNotificationToggle(
              'wins',
              'Winner Announcements',
              'Celebrate when winners are selected',
              Icons.emoji_events,
              false,
              isPremium,
            ),
            _buildDivider(),
            _buildNotificationToggle(
              'securityAlerts',
              'Security Alerts',
              'Important account notifications (always on)',
              Icons.security,
              false,
              isPremium,
              isRequired: true,
            ),
          ],
        ),
      );

  Widget _buildPremiumNotificationTypes(bool isPremium) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: _buildContainerDecoration(),
        child: Column(
          children: [
            _buildNotificationToggle(
              'highValue',
              'High Value Prizes',
              'Alerts for valuable sweepstakes',
              Icons.attach_money,
              true,
              isPremium,
            ),
            _buildDivider(),
            _buildNotificationToggle(
              'personalizedAlerts',
              'Personalized AI Alerts',
              'Smart recommendations just for you',
              Icons.auto_awesome,
              true,
              isPremium,
            ),
            _buildDivider(),
            _buildNotificationToggle(
              'dailyDigest',
              'Daily Digest',
              "Summary of today's best sweepstakes",
              Icons.today,
              true,
              isPremium,
            ),
            _buildDivider(),
            _buildNotificationToggle(
              'weeklyRoundup',
              'Weekly Roundup',
              'Top sweepstakes of the week',
              Icons.calendar_view_week,
              true,
              isPremium,
            ),
          ],
        ),
      );

  Widget _buildNotificationToggle(
    String key,
    String title,
    String subtitle,
    IconData icon,
    bool premiumOnly,
    bool isPremium, {
    bool isRequired = false,
  }) {
    final isLocked = premiumOnly && !isPremium;
    final value = _settings!.push.types[key] ?? false;

    return InkWell(
      onTap: isLocked
          ? _showPremiumDialog
          : (isRequired ? null : () => _toggleNotificationType(key, !value)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: isLocked
                  ? AppColors.textMuted
                  : AppColors.brandCyan.withValues(alpha: 0.7),
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isLocked
                              ? AppColors.textMuted
                              : AppColors.textWhite,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (premiumOnly) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFFFD700).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: const Color(0xFFFFD700),
                            ),
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      if (isRequired) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                AppColors.warningOrange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'REQUIRED',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.warningOrange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            if (isLocked)
              const Icon(Icons.lock, color: AppColors.textMuted, size: 20)
            else
              Switch(
                value: isRequired ? true : value,
                onChanged: isRequired
                    ? null
                    : (val) => _toggleNotificationType(key, val),
                activeThumbColor: AppColors.brandCyan,
              ),
          ],
        ),
      ),
    );
  }

  void _toggleNotificationType(String key, bool value) {
    final newTypes = Map<String, bool>.from(_settings!.push.types);
    newTypes[key] = value;

    setState(() {
      _settings = NotificationSettings(
        permissionStatus: _settings!.permissionStatus,
        push: PushSettings(enabled: _settings!.push.enabled, types: newTypes),
        email: _settings!.email,
        sms: _settings!.sms,
        quietHours: _settings!.quietHours,
        preferences: _settings!.preferences,
      );
    });
  }

  Widget _buildEmailSettings() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: _buildContainerDecoration(),
        child: SwitchListTile(
          value: _settings!.email.enabled,
          onChanged: (value) {
            setState(() {
              _settings = NotificationSettings(
                permissionStatus: _settings!.permissionStatus,
                push: _settings!.push,
                email: EmailSettings(
                    enabled: value, types: _settings!.email.types),
                sms: _settings!.sms,
                quietHours: _settings!.quietHours,
                preferences: _settings!.preferences,
              );
            });
          },
          title: Text(
            'Email Notifications',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            'Receive updates in your inbox',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
          ),
          activeThumbColor: AppColors.brandCyan,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      );

  Widget _buildSmsSettings() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: _buildContainerDecoration(),
        child: SwitchListTile(
          value: _settings!.sms.enabled,
          onChanged: (value) {
            setState(() {
              _settings = NotificationSettings(
                permissionStatus: _settings!.permissionStatus,
                push: _settings!.push,
                email: _settings!.email,
                sms: SmsSettings(enabled: value, types: _settings!.sms.types),
                quietHours: _settings!.quietHours,
                preferences: _settings!.preferences,
              );
            });
          },
          title: Row(
            children: [
              Text(
                'SMS Notifications',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.star, color: Color(0xFFFFD700), size: 16),
            ],
          ),
          subtitle: Text(
            'Text message alerts for high-value sweepstakes',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
          ),
          activeThumbColor: AppColors.brandCyan,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      );

  Widget _buildQuietHoursSettings() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: _buildContainerDecoration(),
        child: SwitchListTile(
          value: _settings!.quietHours.enabled,
          onChanged: (value) {
            setState(() {
              _settings = NotificationSettings(
                permissionStatus: _settings!.permissionStatus,
                push: _settings!.push,
                email: _settings!.email,
                sms: _settings!.sms,
                quietHours: QuietHoursSettings(
                  enabled: value,
                  start: _settings!.quietHours.start,
                  end: _settings!.quietHours.end,
                ),
                preferences: _settings!.preferences,
              );
            });
          },
          title: Row(
            children: [
              Text(
                'Quiet Hours',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.star, color: Color(0xFFFFD700), size: 16),
            ],
          ),
          subtitle: Text(
            'Pause notifications: ${_settings!.quietHours.start} - ${_settings!.quietHours.end}',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
          ),
          activeThumbColor: AppColors.brandCyan,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      );

  Widget _buildPreferencesSettings() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: _buildContainerDecoration(),
        child: Column(
          children: [
            _buildPreferenceToggle('sound', 'Sound', Icons.volume_up),
            _buildDivider(),
            _buildPreferenceToggle('vibration', 'Vibration', Icons.vibration),
            _buildDivider(),
            _buildPreferenceToggle(
                'lockScreen', 'Lock Screen', Icons.lock_clock),
          ],
        ),
      );

  Widget _buildPreferenceToggle(String key, String title, IconData icon) {
    bool value;
    switch (key) {
      case 'sound':
        value = _settings!.preferences.sound;
        break;
      case 'vibration':
        value = _settings!.preferences.vibration;
        break;
      case 'lockScreen':
        value = _settings!.preferences.lockScreen;
        break;
      default:
        value = false;
    }

    return SwitchListTile(
      value: value,
      onChanged: (val) => _togglePreference(key, val),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textWhite,
          fontWeight: FontWeight.w500,
        ),
      ),
      secondary: Icon(icon, color: AppColors.brandCyan.withValues(alpha: 0.7)),
      activeThumbColor: AppColors.brandCyan,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  void _togglePreference(String key, bool value) {
    setState(() {
      _settings = NotificationSettings(
        permissionStatus: _settings!.permissionStatus,
        push: _settings!.push,
        email: _settings!.email,
        sms: _settings!.sms,
        quietHours: _settings!.quietHours,
        preferences: PreferencesSettings(
          sound: key == 'sound' ? value : _settings!.preferences.sound,
          vibration:
              key == 'vibration' ? value : _settings!.preferences.vibration,
          led: _settings!.preferences.led,
          lockScreen:
              key == 'lockScreen' ? value : _settings!.preferences.lockScreen,
          tone: _settings!.preferences.tone,
          priority: _settings!.preferences.priority,
        ),
      );
    });
  }

  BoxDecoration _buildContainerDecoration() => BoxDecoration(
        color: AppColors.primaryMedium.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.brandCyan.withValues(alpha: 0.2),
        ),
      );

  Widget _buildDivider() => Divider(
        height: 1,
        color: AppColors.primaryLight.withValues(alpha: 0.3),
        indent: 52,
      );

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.star, color: Color(0xFFFFD700)),
            const SizedBox(width: 8),
            Text(
              'Premium Feature',
              style: AppTextStyles.headingSmall
                  .copyWith(color: AppColors.textWhite),
            ),
          ],
        ),
        content: Text(
          'Upgrade to Premium to unlock unlimited notifications, high-value alerts, AI recommendations, and more!',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Maybe Later',
              style:
                  AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: AppColors.primaryDark,
            ),
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }
}
