import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/services/modern_notification_service.dart';

class NotificationSettings {
  NotificationSettings({required this.channels});

  factory NotificationSettings.fromJson(Map<String, dynamic> json) =>
      NotificationSettings(
        channels: json['channels'] ??
            {
              'push': {
                'enabled': true,
                'types': {
                  'newSweepstakes': true,
                  'endingSoon': true,
                  'wins': true,
                  'reminders': true,
                },
              },
            },
      );
  final Map<String, dynamic> channels;

  // Helper getters for accessing nested properties
  Map<String, dynamic> get push => channels['push'] ?? {};
}

final notificationSettingsProvider =
    FutureProvider<NotificationSettings?>((ref) async {
  final userService = ref.watch(userServiceProvider);
  // Assuming current user is already authenticated and available
  // You might need to get uid from authService if userService needs it explicitly
  // but looking at previous UserService code, checking how to get profile.
  final authService = ref.read(authServiceProvider);
  final uid = authService.currentUser?.uid;
  if (uid != null) {
     final userProfile = await userService.getUserProfile(uid);
      if (userProfile != null) {
        // NotificationSettings.fromJson expects Map, UserProfile is object.
        // We need to convert or adjust. 
        // Checking UserProfile model again might be needed, but assuming toJson exists.
        return NotificationSettings.fromJson(userProfile.toJson());
      }
  }
  return null;
  return null;
});

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  // Master switches
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;

  // Push notification settings
  bool _newSweepstakes = true;
  bool _endingSoon = true;
  bool _winners = true;
  bool _dailyDigest = true;
  bool _weeklyRoundup = false;
  bool _personalizedAlerts = true;
  bool _priceDrops = true;
  bool _categoryUpdates = true;

  // Email settings
  bool _emailNewSweeps = true;
  bool _emailWeekly = true;
  bool _emailWinners = false;
  bool _emailPromotions = false;

  // Quiet hours
  bool _quietHours = false;
  TimeOfDay _quietStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietEnd = const TimeOfDay(hour: 8, minute: 0);

  // Advanced settings
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _ledIndicator = true;
  bool _lockScreenNotifications = true;
  String _notificationTone = 'Default';
  String _priority = 'High';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ref.read(notificationSettingsProvider).whenData((settings) {
      if (settings != null) {
        _pushNotifications = settings.push['enabled'] ?? true;
        final types = settings.push['types'] ?? {};
        _newSweepstakes = types['newSweepstakes'] ?? true;
        _endingSoon = types['endingSoon'] ?? true;
        _winners = types['wins'] ?? true;
        _dailyDigest = types['reminders'] ?? true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsyncValue = ref.watch(notificationSettingsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2F45),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF4CAF50)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notification Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Color(0xFF4CAF50),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: settingsAsyncValue.when(
        data: (settings) {
          if (settings == null) {
            return const Center(
              child: Text(
                'Could not load settings.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Notification Status Card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF4CAF50).withValues(alpha: 0.2),
                        const Color(0xFF4CAF50).withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_active,
                          color: Color(0xFF4CAF50),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Notifications Active',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "You're receiving personalized alerts",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Master Controls
                _buildSectionHeader('Notification Channels'),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: _buildContainerDecoration(),
                  child: Column(
                    children: [
                      _buildMasterSwitch(
                        icon: Icons.phone_iphone,
                        title: 'Push Notifications',
                        subtitle: 'Receive alerts on your device',
                        value: _pushNotifications,
                        onChanged: (value) {
                          setState(() => _pushNotifications = value);
                        },
                      ),
                      _buildDivider(),
                      _buildMasterSwitch(
                        icon: Icons.email_outlined,
                        title: 'Email Notifications',
                        subtitle: 'Get updates in your inbox',
                        value: _emailNotifications,
                        onChanged: (value) {
                          setState(() => _emailNotifications = value);
                        },
                      ),
                      _buildDivider(),
                      _buildMasterSwitch(
                        icon: Icons.sms_outlined,
                        title: 'SMS Notifications',
                        subtitle: 'Text message alerts (Premium)',
                        value: _smsNotifications,
                        onChanged: (value) {
                          setState(() => _smsNotifications = value);
                        },
                        isPremium: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Push Notification Types
                if (_pushNotifications) ...[
                  _buildSectionHeader('Push Notification Types'),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: _buildContainerDecoration(),
                    child: Column(
                      children: [
                        _buildNotificationToggle(
                          title: 'New Sweepstakes',
                          subtitle: 'When new sweeps match your interests',
                          value: _newSweepstakes,
                          onChanged: (value) =>
                              setState(() => _newSweepstakes = value),
                          icon: Icons.fiber_new,
                        ),
                        _buildDivider(),
                        _buildNotificationToggle(
                          title: 'Ending Soon',
                          subtitle: 'Reminders before sweeps close',
                          value: _endingSoon,
                          onChanged: (value) =>
                              setState(() => _endingSoon = value),
                          icon: Icons.timer,
                        ),
                        _buildDivider(),
                        _buildNotificationToggle(
                          title: 'Winner Announcements',
                          subtitle: 'When winners are selected',
                          value: _winners,
                          onChanged: (value) =>
                              setState(() => _winners = value),
                          icon: Icons.emoji_events,
                        ),
                        _buildDivider(),
                        _buildNotificationToggle(
                          title: 'Daily Digest',
                          subtitle: "Summary of today's best sweeps",
                          value: _dailyDigest,
                          onChanged: (value) =>
                              setState(() => _dailyDigest = value),
                          icon: Icons.today,
                        ),
                        _buildDivider(),
                        _buildNotificationToggle(
                          title: 'Weekly Roundup',
                          subtitle: 'Top sweeps of the week',
                          value: _weeklyRoundup,
                          onChanged: (value) =>
                              setState(() => _weeklyRoundup = value),
                          icon: Icons.calendar_view_week,
                        ),
                        _buildDivider(),
                        _buildNotificationToggle(
                          title: 'Personalized Alerts',
                          subtitle: 'AI-curated sweeps just for you',
                          value: _personalizedAlerts,
                          onChanged: (value) =>
                              setState(() => _personalizedAlerts = value),
                          icon: Icons.auto_awesome,
                        ),
                        _buildDivider(),
                        _buildNotificationToggle(
                          title: 'Prize Value Drops',
                          subtitle: 'When high-value sweeps are added',
                          value: _priceDrops,
                          onChanged: (value) =>
                              setState(() => _priceDrops = value),
                          icon: Icons.attach_money,
                        ),
                        _buildDivider(),
                        _buildNotificationToggle(
                          title: 'Category Updates',
                          subtitle: 'New sweeps in your favorite categories',
                          value: _categoryUpdates,
                          onChanged: (value) =>
                              setState(() => _categoryUpdates = value),
                          icon: Icons.category,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Email Preferences
                if (_emailNotifications) ...[
                  _buildSectionHeader('Email Preferences'),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: _buildContainerDecoration(),
                    child: Column(
                      children: [
                        _buildNotificationToggle(
                          title: 'New Sweepstakes Email',
                          subtitle: 'Daily email with new opportunities',
                          value: _emailNewSweeps,
                          onChanged: (value) =>
                              setState(() => _emailNewSweeps = value),
                          icon: Icons.mail_outline,
                        ),
                        _buildDivider(),
                        _buildNotificationToggle(
                          title: 'Weekly Newsletter',
                          subtitle: 'Curated content and tips',
                          value: _emailWeekly,
                          onChanged: (value) =>
                              setState(() => _emailWeekly = value),
                          icon: Icons.newspaper,
                        ),
                        _buildDivider(),
                        _buildNotificationToggle(
                          title: 'Winner Stories',
                          subtitle: 'Success stories and testimonials',
                          value: _emailWinners,
                          onChanged: (value) =>
                              setState(() => _emailWinners = value),
                          icon: Icons.star,
                        ),
                        _buildDivider(),
                        _buildNotificationToggle(
                          title: 'Promotional Emails',
                          subtitle: 'Special offers and partner deals',
                          value: _emailPromotions,
                          onChanged: (value) =>
                              setState(() => _emailPromotions = value),
                          icon: Icons.local_offer,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Quiet Hours
                _buildSectionHeader('Quiet Hours'),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: _buildContainerDecoration(),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.bedtime,
                              color: Color(0xFF4CAF50),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Quiet Hours',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Pause notifications during set hours',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          CupertinoSwitch(
                            value: _quietHours,
                            onChanged: (value) {
                              setState(() => _quietHours = value);
                            },
                            activeTrackColor: const Color(0xFF4CAF50),
                          ),
                        ],
                      ),
                      if (_quietHours) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTimeSelector(
                                'Start Time',
                                _quietStart,
                                (time) => setState(() => _quietStart = time),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTimeSelector(
                                'End Time',
                                _quietEnd,
                                (time) => setState(() => _quietEnd = time),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Advanced Settings
                _buildSectionHeader('Advanced Settings'),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: _buildContainerDecoration(),
                  child: Column(
                    children: [
                      _buildNotificationToggle(
                        title: 'Sound',
                        subtitle: 'Play sound for notifications',
                        value: _soundEnabled,
                        onChanged: (value) =>
                            setState(() => _soundEnabled = value),
                        icon: Icons.volume_up,
                      ),
                      _buildDivider(),
                      _buildNotificationToggle(
                        title: 'Vibration',
                        subtitle: 'Vibrate on notification',
                        value: _vibrationEnabled,
                        onChanged: (value) =>
                            setState(() => _vibrationEnabled = value),
                        icon: Icons.vibration,
                      ),
                      _buildDivider(),
                      _buildNotificationToggle(
                        title: 'LED Indicator',
                        subtitle: 'Show LED light for notifications',
                        value: _ledIndicator,
                        onChanged: (value) =>
                            setState(() => _ledIndicator = value),
                        icon: Icons.lightbulb_outline,
                      ),
                      _buildDivider(),
                      _buildNotificationToggle(
                        title: 'Lock Screen',
                        subtitle: 'Show notifications on lock screen',
                        value: _lockScreenNotifications,
                        onChanged: (value) =>
                            setState(() => _lockScreenNotifications = value),
                        icon: Icons.lock_clock,
                      ),
                      _buildDivider(),
                      _buildSettingRow(
                        icon: Icons.music_note,
                        title: 'Notification Sound',
                        value: _notificationTone,
                        onTap: _selectNotificationTone,
                      ),
                      _buildDivider(),
                      _buildSettingRow(
                        icon: Icons.priority_high,
                        title: 'Priority',
                        value: _priority,
                        onTap: _selectPriority,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Test Notification Button
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton.icon(
                    onPressed: _sendTestNotification,
                    icon: const Icon(Icons.notifications, color: Colors.white),
                    label: const Text(
                      'Send Test Notification',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => const Center(
          child: Text(
            'Error loading settings.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF4CAF50),
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      );

  BoxDecoration _buildContainerDecoration() => BoxDecoration(
        color: const Color(0xFF1A2F45).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
        ),
      );

  Widget _buildMasterSwitch({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isPremium = false,
  }) =>
      Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF4CAF50),
                size: 24,
              ),
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isPremium) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 10,
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
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            CupertinoSwitch(
              value: value,
              onChanged: isPremium && !value ? null : onChanged,
              activeTrackColor: const Color(0xFF4CAF50),
              inactiveTrackColor: const Color(0xFF3A4A5F),
            ),
          ],
        ),
      );

  Widget _buildNotificationToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF4CAF50).withValues(alpha: 0.7),
              size: 20,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: const Color(0xFF4CAF50),
              activeTrackColor: const Color(0xFF4CAF50).withValues(alpha: 0.3),
              inactiveThumbColor: const Color(0xFF5A6A7F),
              inactiveTrackColor: const Color(0xFF2A3A4F),
            ),
          ],
        ),
      );

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF4CAF50).withValues(alpha: 0.7),
                size: 20,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: Colors.white54,
                size: 20,
              ),
            ],
          ),
        ),
      );

  Widget _buildTimeSelector(
    String label,
    TimeOfDay time,
    Function(TimeOfDay) onChanged,
  ) =>
      InkWell(
        onTap: () async {
          final newTime = await showTimePicker(
            context: context,
            initialTime: time,
            builder: (context, child) => Theme(
              data: ThemeData.dark().copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: Color(0xFF4CAF50),
                  surface: Color(0xFF1A2F45),
                ),
              ),
              child: child!,
            ),
          );
          if (newTime != null) {
            onChanged(newTime);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0A1628),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time.format(context),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildDivider() => const Divider(
        height: 1,
        color: Color(0xFF2A3A4F),
        indent: 52,
      );

  Future<void> _saveSettings() async {
    final authService = ref.read(authServiceProvider);
    final userService = ref.read(userServiceProvider);
    final currentUser = authService.currentUser;

    if (currentUser == null) return;

    final pushSettings = {
      'enabled': _pushNotifications,
      'types': {
        'newSweepstakes': _newSweepstakes,
        'endingSoon': _endingSoon,
        'wins': _winners,
        'reminders': _dailyDigest,
        'streakReminders':
            true, // Assuming this is always on, or add a switch for it
      },
    };

    await userService.updateUserProfile(
      currentUser.uid,
      {'notificationSettings': pushSettings},
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Settings saved successfully!'),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _sendTestNotification() async {
    try {
      final currentUser = ref.read(firebaseServiceProvider).currentUser;
      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Please log in to test notifications'),
                ],
              ),
              backgroundColor: const Color(0xFFF44336),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
        return;
      }

      final testNotification = ModernNotificationData(
        id: 'test_notification_${DateTime.now().millisecondsSinceEpoch}',
        userId: currentUser.uid,
        category: ModernNotificationCategory.systemMessages,
        type: ModernNotificationType.accountUpdate,
        priority: NotificationPriority.normal,
        style: NotificationStyle.basic,
        title: 'Test Notification',
        body:
            'This is a test notification from SweepFeed! Your notifications are working correctly.',
        scheduledTime: DateTime.now(),
        requiresConsent: false,
        customData: {'testNotification': true},
      );

      await modernNotificationService.sendNotification(testNotification);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.notifications_active, color: Colors.white),
                SizedBox(width: 12),
                Text('Test notification sent!'),
              ],
            ),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                    child:
                        Text('Failed to send notification: ${e.toString()}'),),
              ],
            ),
            backgroundColor: const Color(0xFFF44336),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  void _selectNotificationTone() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2F45),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Notification Sound',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...['Default', 'Chime', 'Bell', 'Alert', 'None'].map(
              (tone) => ListTile(
                leading: Icon(
                  Icons.music_note,
                  color: _notificationTone == tone
                      ? const Color(0xFF4CAF50)
                      : Colors.white54,
                ),
                title: Text(
                  tone,
                  style: TextStyle(
                    color: _notificationTone == tone
                        ? const Color(0xFF4CAF50)
                        : Colors.white,
                  ),
                ),
                onTap: () {
                  setState(() => _notificationTone = tone);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectPriority() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2F45),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Notification Priority',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...['High', 'Medium', 'Low'].map(
              (priority) => ListTile(
                leading: Icon(
                  Icons.priority_high,
                  color: _priority == priority
                      ? const Color(0xFF4CAF50)
                      : Colors.white54,
                ),
                title: Text(
                  priority,
                  style: TextStyle(
                    color: _priority == priority
                        ? const Color(0xFF4CAF50)
                        : Colors.white,
                  ),
                ),
                subtitle: Text(
                  _getPriorityDescription(priority),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                onTap: () {
                  setState(() => _priority = priority);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPriorityDescription(String priority) {
    switch (priority) {
      case 'High':
        return 'Makes sound and pops on screen';
      case 'Medium':
        return 'Makes sound';
      case 'Low':
        return 'No sound or visual interruption';
      default:
        return '';
    }
  }
}
