import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/providers/providers.dart';
import '../../../core/services/live_activities_service.dart';
import '../../../core/services/modern_notification_service.dart';
import '../../../core/utils/logger.dart';
import 'frequency_settings_screen.dart';
import 'quiet_hours_settings_screen.dart';
import 'sound_settings_screen.dart';

/// Modern notification settings screen with granular controls
/// Supports iOS 17+ and Android 14+ features
class ModernNotificationSettingsScreen extends ConsumerStatefulWidget {
  const ModernNotificationSettingsScreen({super.key});

  @override
  ConsumerState<ModernNotificationSettingsScreen> createState() =>
      _ModernNotificationSettingsScreenState();
}

class _ModernNotificationSettingsScreenState
    extends ConsumerState<ModernNotificationSettingsScreen> {
  Map<ModernNotificationCategory, bool> _consents = {};
  bool _isLoading = true;
  bool _liveActivitiesSupported = false;
  bool _liveActivitiesEnabled = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    try {
      // Get current user ID from Firebase Auth
      final currentUser = ref.read(firebaseServiceProvider).currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      _userId = currentUser.uid;

      // Load current consent settings
      final consents = await modernNotificationService.getAllConsents(_userId!);

      // Check Live Activities support
      final liveActivitiesSupported =
          await liveActivitiesService.areSupported();

      setState(() {
        _consents = consents;
        _liveActivitiesSupported = liveActivitiesSupported;
        _liveActivitiesEnabled =
            liveActivitiesSupported; // Default enabled if supported
        _isLoading = false;
      });
    } catch (e) {
      logger.e('Error initializing notification settings', error: e);
      setState(() {
        _isLoading = false;
      });
    }
  }



  Future<void> _requestPermissions() async {
    try {
      final status = await Permission.notification.request();
      if (status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification permissions granted!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification permissions required for alerts'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      logger.e('Error requesting notification permissions', error: e);
    }
  }

  Future<void> _openSystemSettings() async {
    await openAppSettings();
  }

  void _showPrivacyInfo(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateConsent(
    ModernNotificationCategory category,
    bool enabled,
  ) async {
    if (_userId == null) return;

    try {
      await modernNotificationService.updateConsent(
        _userId!,
        category,
        enabled,
      );
      setState(() {
        _consents[category] = enabled;
      });

      if (category == ModernNotificationCategory.hotSweepstakes) {
        _updateHotSweepstakesSubscription(enabled);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled
                ? '${_getCategoryDisplayName(category)} notifications enabled'
                : '${_getCategoryDisplayName(category)} notifications disabled',
          ),
          backgroundColor: enabled ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      logger.e('Error updating consent for $category', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update notification settings'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateHotSweepstakesSubscription(bool enabled) async {
    final isPremium = ref.read(subscriptionServiceProvider).isSubscribed;
    if (!isPremium) return;

    final messaging = ref.read(firebaseMessagingProvider);
    if (enabled) {
      await messaging.subscribeToTopic('premium-hot-contests');
      logger.i('Subscribed to premium-hot-contests topic');
    } else {
      await messaging.unsubscribeFromTopic('premium-hot-contests');
      logger.i('Unsubscribed from premium-hot-contests topic');
    }
  }

  String _getCategoryDisplayName(ModernNotificationCategory category) {
    switch (category) {
      case ModernNotificationCategory.contestUpdates:
        return 'Contest Updates';
      case ModernNotificationCategory.socialActivity:
        return 'Social Activity';
      case ModernNotificationCategory.systemMessages:
        return 'System Messages';
      case ModernNotificationCategory.highPriority:
        return 'High Priority Alerts';
      case ModernNotificationCategory.reminders:
        return 'Reminders';
      case ModernNotificationCategory.promotions:
        return 'Promotions & Offers';
      case ModernNotificationCategory.gameUpdates:
        return 'Game Updates';
      case ModernNotificationCategory.achievements:
        return 'Achievements';
      case ModernNotificationCategory.hotSweepstakes:
        return 'Hot Sweepstakes';
    }
  }

  String _getCategoryDescription(ModernNotificationCategory category) {
    switch (category) {
      case ModernNotificationCategory.contestUpdates:
        return 'New contests, deadlines, and winner announcements';
      case ModernNotificationCategory.socialActivity:
        return 'Followers, comments, and social interactions';
      case ModernNotificationCategory.systemMessages:
        return 'Important system updates and security alerts';
      case ModernNotificationCategory.highPriority:
        return 'Critical alerts requiring immediate attention';
      case ModernNotificationCategory.reminders:
        return 'Daily reminders and scheduled notifications';
      case ModernNotificationCategory.promotions:
        return 'Special offers and promotional content';
      case ModernNotificationCategory.gameUpdates:
        return 'New features and game-related updates';
      case ModernNotificationCategory.achievements:
        return 'Badges, levels, and milestone notifications';
      case ModernNotificationCategory.hotSweepstakes:
        return 'Get notified about trending and high-value sweepstakes';
    }
  }

  IconData _getCategoryIcon(ModernNotificationCategory category) {
    switch (category) {
      case ModernNotificationCategory.contestUpdates:
        return Icons.emoji_events;
      case ModernNotificationCategory.socialActivity:
        return Icons.people;
      case ModernNotificationCategory.systemMessages:
        return Icons.security;
      case ModernNotificationCategory.highPriority:
        return Icons.priority_high;
      case ModernNotificationCategory.reminders:
        return Icons.alarm;
      case ModernNotificationCategory.promotions:
        return Icons.local_offer;
      case ModernNotificationCategory.gameUpdates:
        return Icons.games;
      case ModernNotificationCategory.achievements:
        return Icons.military_tech;
      case ModernNotificationCategory.hotSweepstakes:
        return Icons.whatshot;
    }
  }

  Color _getCategoryColor(ModernNotificationCategory category) {
    switch (category) {
      case ModernNotificationCategory.contestUpdates:
        return const Color(0xFF00E5FF);
      case ModernNotificationCategory.socialActivity:
        return const Color(0xFF4CAF50);
      case ModernNotificationCategory.systemMessages:
        return const Color(0xFFFF9800);
      case ModernNotificationCategory.highPriority:
        return const Color(0xFFF44336);
      case ModernNotificationCategory.reminders:
        return const Color(0xFF9C27B0);
      case ModernNotificationCategory.promotions:
        return const Color(0xFFE91E63);
      case ModernNotificationCategory.gameUpdates:
        return const Color(0xFF2196F3);
      case ModernNotificationCategory.achievements:
        return const Color(0xFFFFD700);
      case ModernNotificationCategory.hotSweepstakes:
        return const Color(0xFFFF6D00);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A1929),
        appBar: AppBar(
          title: const Text('Notification Settings'),
          backgroundColor: const Color(0xFF0A1929),
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A1929),
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: const Color(0xFF0A1929),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSystemSettings,
            tooltip: 'System Settings',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF334155)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.notifications_active,
                      color: Color(0xFF00E5FF),
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Smart Notifications',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Control how and when you receive notifications. Your preferences help us deliver relevant updates.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Permission Status
          _buildPermissionCard(),

          const SizedBox(height: 24),

          // Live Activities (iOS only)
          if (_liveActivitiesSupported) ...[
            _buildLiveActivitiesCard(),
            const SizedBox(height: 24),
          ],

          // Notification Categories
          const Text(
            'Notification Categories',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose which types of notifications you want to receive',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),

          // Category List
          ...ModernNotificationCategory.values.map(_buildCategoryCard),

          const SizedBox(height: 24),

          // Advanced Settings
          _buildAdvancedSettingsCard(),

          const SizedBox(height: 24),

          // GDPR Compliance Info
          _buildComplianceCard(),
        ],
      ),
    );
  }

  Widget _buildPermissionCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.shield_outlined, color: Color(0xFF00E5FF)),
                SizedBox(width: 8),
                Text(
                  'Permission Status',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Grant notification permissions to receive contest updates and important alerts',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _requestPermissions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    foregroundColor: const Color(0xFF0A1929),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Grant Access'),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildLiveActivitiesCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.dynamic_form, color: Color(0xFF00E5FF)),
                const SizedBox(width: 8),
                const Text(
                  'Live Activities',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: _liveActivitiesEnabled,
                  onChanged: (value) {
                    setState(() {
                      _liveActivitiesEnabled = value;
                    });
                  },
                  activeThumbColor: const Color(0xFF00E5FF),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Show contest countdowns on your Lock Screen and Dynamic Island',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );

  Widget _buildCategoryCard(ModernNotificationCategory category) {
    final isEnabled = _consents[category] ?? false;
    final color = _getCategoryColor(category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEnabled
              ? color.withValues(alpha: 0.3)
              : const Color(0xFF334155),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getCategoryIcon(category),
            color: color,
            size: 24,
          ),
        ),
        title: Text(
          _getCategoryDisplayName(category),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            _getCategoryDescription(category),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ),
        trailing: Switch(
          value: isEnabled,
          onChanged: (value) => _updateConsent(category, value),
          activeThumbColor: color,
        ),
      ),
    );
  }

  Widget _buildAdvancedSettingsCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.tune, color: Color(0xFF00E5FF)),
                SizedBox(width: 8),
                Text(
                  'Advanced Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Quiet Hours
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading:
                  const Icon(Icons.nightlight_round, color: Color(0xFF9C27B0)),
              title: const Text(
                'Quiet Hours',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                'Customize when you receive notifications',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white54,
                size: 16,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const QuietHoursSettingsScreen(),
                  ),
                );
              },
            ),

            const Divider(color: Color(0xFF334155)),

            // Notification Sounds
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.volume_up, color: Color(0xFF4CAF50)),
              title: const Text(
                'Sounds & Vibration',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                'Customize notification sounds and haptics',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white54,
                size: 16,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SoundSettingsScreen(),
                  ),
                );
              },
            ),

            const Divider(color: Color(0xFF334155)),

            // Frequency Control
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.speed, color: Color(0xFFFF9800)),
              title: const Text(
                'Frequency Control',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                'Control how often you receive notifications',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white54,
                size: 16,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FrequencySettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      );

  Widget _buildComplianceCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.privacy_tip, color: Color(0xFF4CAF50)),
                SizedBox(width: 8),
                Text(
                  'Privacy & Compliance',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Your notification preferences are stored securely and comply with GDPR regulations. You can change your consent at any time.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    _showPrivacyInfo(
                      'Privacy Policy',
                      'SweepFeed is committed to protecting your privacy. We only use your data to provide you with relevant contests updates and improve your experience. \n\nWe do not sell your personal data to third parties. For full details, please visit our website.',
                    );
                  },
                  child: const Text(
                    'Privacy Policy',
                    style: TextStyle(color: Color(0xFF00E5FF)),
                  ),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () {
                    _showPrivacyInfo(
                      'Your Rights',
                      'Under GDPR and CCPA, you have the right to:\n\n• Access your data\n• Correct inaccuracies\n• Request deletion\n• Object to processing\n• Data portability\n\nContact support@sweepfeed.app for assistance.',
                    );
                  },
                  child: const Text(
                    'Your Rights',
                    style: TextStyle(color: Color(0xFF00E5FF)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}
