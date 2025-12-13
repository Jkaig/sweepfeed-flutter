import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/services/unified_notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/logger.dart';

class QuietHoursSettingsScreen extends ConsumerStatefulWidget {
  const QuietHoursSettingsScreen({super.key});

  @override
  ConsumerState<QuietHoursSettingsScreen> createState() =>
      _QuietHoursSettingsScreenState();
}

class _QuietHoursSettingsScreenState
    extends ConsumerState<QuietHoursSettingsScreen> {
  bool _isLoading = true;
  bool _enabled = false;
  TimeOfDay _startTime = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 8, minute: 0);
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final user = ref.read(firebaseServiceProvider).currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }
      _userId = user.uid;

      final settings = await unifiedNotificationService.getSettings(_userId!);
      
      setState(() {
        _enabled = settings.quietHours.enabled;
        _startTime = _parseTime(settings.quietHours.start);
        _endTime = _parseTime(settings.quietHours.end);
        _isLoading = false;
      });
    } catch (e) {
      logger.e('Error loading quiet hours settings', error: e);
      setState(() => _isLoading = false);
    }
  }

  TimeOfDay _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } catch (e) {
      return const TimeOfDay(hour: 22, minute: 0);
    }
  }

  String _formatTimeForStorage(TimeOfDay time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  Future<void> _saveSettings() async {
    if (_userId == null) return;

    try {
      final currentSettings =
          await unifiedNotificationService.getSettings(_userId!);
      
      final updatedQuietHours = QuietHoursSettings(
        enabled: _enabled,
        start: _formatTimeForStorage(_startTime),
        end: _formatTimeForStorage(_endTime),
      );

      final updatedSettings = NotificationSettings(
        permissionStatus: currentSettings.permissionStatus,
        push: currentSettings.push,
        email: currentSettings.email,
        sms: currentSettings.sms,
        quietHours: updatedQuietHours,
        preferences: currentSettings.preferences,
      );

      await unifiedNotificationService.updateSettings(_userId!, updatedSettings);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quiet hours settings saved'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      logger.e('Error saving quiet hours', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save settings'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _selectTime(bool isStart) async {
    final initialTime = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.brandCyan,
              onPrimary: AppColors.primaryDark,
              surface: AppColors.primaryMedium,
              onSurface: AppColors.textWhite,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.brandCyan,
              ),
            ),
          ),
          child: child!,
        ),
    );

    if (picked != null && picked != initialTime) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
      _saveSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.primaryDark,
        appBar: AppBar(
          backgroundColor: AppColors.primaryDark,
          title: const Text('Quiet Hours'),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.brandCyan),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: const Text('Quiet Hours'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryMedium,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.nightlight_round,
                      color: Color(0xFF9C27B0),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enable Quiet Hours',
                            style: TextStyle(
                              color: AppColors.textWhite,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Mute notifications during specific times',
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _enabled,
                      onChanged: (value) {
                        setState(() => _enabled = value);
                        _saveSettings();
                      },
                      activeThumbColor: const Color(0xFF9C27B0),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          if (_enabled) ...[
            const SizedBox(height: 24),
            const Text(
              'Schedule',
              style: TextStyle(
                color: AppColors.textWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildTimeTile(
              'Start Time',
              'When quiet hours begin',
              _startTime,
              () => _selectTime(true),
            ),
            
            const SizedBox(height: 12),
            
            _buildTimeTile(
              'End Time',
              'When quiet hours end',
              _endTime,
              () => _selectTime(false),
            ),
            
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryMedium.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryLight.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.textLight, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Critical alerts and high-priority security notifications will still be delivered during quiet hours.',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeTile(
    String title,
    String subtitle,
    TimeOfDay time,
    VoidCallback onTap,
  ) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryMedium,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryLight),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.brandCyan.withOpacity(0.3)),
              ),
              child: Text(
                time.format(context),
                style: const TextStyle(
                  color: AppColors.brandCyan,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
}

