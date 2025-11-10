import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_back_button.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  _PrivacySettingsScreenState createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  // Privacy Settings
  bool _analyticsTracking = true;
  bool _personalizedAds = true;
  bool _dataCollection = true;
  bool _locationTracking = false;
  bool _crashReporting = true;
  bool _performanceMonitoring = true;
  bool _profileVisibility = true;
  bool _activitySharing = false;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _analyticsTracking = prefs.getBool('analytics_tracking') ?? true;
      _personalizedAds = prefs.getBool('personalized_ads') ?? true;
      _dataCollection = prefs.getBool('data_collection') ?? true;
      _locationTracking = prefs.getBool('location_tracking') ?? false;
      _crashReporting = prefs.getBool('crash_reporting') ?? true;
      _performanceMonitoring = prefs.getBool('performance_monitoring') ?? true;
      _profileVisibility = prefs.getBool('profile_visibility') ?? true;
      _activitySharing = prefs.getBool('activity_sharing') ?? false;
      _isLoading = false;
    });
  }

  Future<void> _savePrivacySetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.errorRed.withValues(alpha: 0.5),
          ),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.warning,
              color: AppColors.errorRed,
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              'Delete Account',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'This action will permanently delete your account and all associated data. This cannot be undone.\n\nAre you sure you want to continue?',
          style: TextStyle(
            color: AppColors.textLight,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textLight),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.errorRed,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAccount();
              },
              child: const Text(
                'Delete Account',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteAccount() {
    // Implement account deletion logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Account deletion request submitted'),
        backgroundColor: AppColors.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _exportData() {
    // Implement data export logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.download, color: Colors.white),
            SizedBox(width: 8),
            Text('Data export request submitted'),
          ],
        ),
        backgroundColor: AppColors.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.primaryDark,
        appBar: const CustomAppBar(
          title: 'Privacy Settings',
          leading: CustomBackButton(),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.brandCyan,
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Data Collection Section
                    _buildPrivacySection(
                      'Data Collection & Analytics',
                      'Control how your data is used for improving the app',
                      [
                        _buildPrivacyToggle(
                          'Analytics Tracking',
                          'Help us improve the app by sharing usage analytics',
                          _analyticsTracking,
                          Icons.analytics_outlined,
                          (value) {
                            setState(() => _analyticsTracking = value);
                            _savePrivacySetting('analytics_tracking', value);
                          },
                        ),
                        _buildPrivacyToggle(
                          'Crash Reporting',
                          'Automatically send crash reports to help fix bugs',
                          _crashReporting,
                          Icons.bug_report_outlined,
                          (value) {
                            setState(() => _crashReporting = value);
                            _savePrivacySetting('crash_reporting', value);
                          },
                        ),
                        _buildPrivacyToggle(
                          'Performance Monitoring',
                          'Monitor app performance to optimize user experience',
                          _performanceMonitoring,
                          Icons.speed_outlined,
                          (value) {
                            setState(() => _performanceMonitoring = value);
                            _savePrivacySetting(
                                'performance_monitoring', value);
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Advertising Section
                    _buildPrivacySection(
                      'Advertising & Personalization',
                      'Manage how ads and content are personalized for you',
                      [
                        _buildPrivacyToggle(
                          'Personalized Ads',
                          'Show ads based on your interests and activity',
                          _personalizedAds,
                          Icons.ad_units_outlined,
                          (value) {
                            setState(() => _personalizedAds = value);
                            _savePrivacySetting('personalized_ads', value);
                          },
                        ),
                        _buildPrivacyToggle(
                          'Data Collection for Ads',
                          'Allow data collection for advertising purposes',
                          _dataCollection,
                          Icons.data_usage_outlined,
                          (value) {
                            setState(() => _dataCollection = value);
                            _savePrivacySetting('data_collection', value);
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Location & Social Section
                    _buildPrivacySection(
                      'Location & Social Features',
                      'Control location services and social features',
                      [
                        _buildPrivacyToggle(
                          'Location Tracking',
                          'Allow the app to access your location for better sweepstakes matching',
                          _locationTracking,
                          Icons.location_on_outlined,
                          (value) {
                            setState(() => _locationTracking = value);
                            _savePrivacySetting('location_tracking', value);
                          },
                        ),
                        _buildPrivacyToggle(
                          'Profile Visibility',
                          'Make your profile visible to other users',
                          _profileVisibility,
                          Icons.person_outline,
                          (value) {
                            setState(() => _profileVisibility = value);
                            _savePrivacySetting('profile_visibility', value);
                          },
                        ),
                        _buildPrivacyToggle(
                          'Activity Sharing',
                          'Share your sweepstakes activity with friends',
                          _activitySharing,
                          Icons.share_outlined,
                          (value) {
                            setState(() => _activitySharing = value);
                            _savePrivacySetting('activity_sharing', value);
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Data Rights Section
                    Card(
                      color: AppColors.primaryMedium,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: AppColors.brandCyan.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 8.0,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.admin_panel_settings_outlined,
                                    color: AppColors.brandCyan,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Your Data Rights',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _buildActionTile(
                              'Export My Data',
                              'Download a copy of your personal data',
                              Icons.download_outlined,
                              _exportData,
                              AppColors.brandCyan,
                            ),
                            Divider(
                              color:
                                  AppColors.primaryLight.withValues(alpha: 0.5),
                              height: 1,
                            ),
                            _buildActionTile(
                              'Delete Account',
                              'Permanently delete your account and all data',
                              Icons.delete_forever_outlined,
                              _showDeleteAccountDialog,
                              AppColors.errorRed,
                              isDangerous: true,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Privacy Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.brandCyan.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppColors.brandCyan,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Privacy Information',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'These settings control how your personal data is collected, used, and shared. Changes take effect immediately. For more details, see our Privacy Policy.',
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      );

  Widget _buildPrivacySection(
    String title,
    String description,
    List<Widget> children,
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
              ...children,
            ],
          ),
        ),
      );

  Widget _buildPrivacyToggle(
    String title,
    String subtitle,
    bool value,
    IconData icon,
    Function(bool) onChanged,
  ) =>
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value
                ? AppColors.brandCyan.withValues(alpha: 0.5)
                : AppColors.primaryLight.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: value
                    ? AppColors.brandCyan.withValues(alpha: 0.2)
                    : AppColors.primaryLight.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: value ? AppColors.brandCyan : AppColors.textLight,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: AppColors.brandCyan,
                activeTrackColor: AppColors.brandCyan.withValues(alpha: 0.3),
                inactiveThumbColor: AppColors.textLight,
                inactiveTrackColor: AppColors.primaryLight,
              ),
            ),
          ],
        ),
      );

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
    Color color, {
    bool isDangerous = false,
  }) =>
      ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: isDangerous
                ? Border.all(
                    color: color.withValues(alpha: 0.5),
                  )
                : null,
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDangerous ? color : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textLight,
            fontSize: 12,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: AppColors.textLight,
          size: 16,
        ),
        onTap: onTap,
      );
}
