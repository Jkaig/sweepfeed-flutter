import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_back_button.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../settings/screens/help_support_screen.dart';
import '../models/email_message.dart';
import '../services/email_service.dart';

/// Email preferences and settings screen for Premium users
class EmailSettingsScreen extends ConsumerStatefulWidget {
  const EmailSettingsScreen({super.key});

  @override
  ConsumerState<EmailSettingsScreen> createState() =>
      _EmailSettingsScreenState();
}

class _EmailSettingsScreenState extends ConsumerState<EmailSettingsScreen> {
  EmailSettings? _currentSettings;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final emailService = ref.read(emailServiceProvider);
      final settings = await emailService.getEmailSettings();
      setState(() {
        _currentSettings = settings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load email settings');
    }
  }

  Future<void> _saveSettings(EmailSettings settings) async {
    setState(() {
      _isSaving = true;
    });

    try {
      final emailService = ref.read(emailServiceProvider);
      await emailService.updateEmailSettings(settings);
      setState(() {
        _currentSettings = settings;
        _isSaving = false;
      });
      _showSuccessSnackBar('Settings saved successfully');
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      _showErrorSnackBar('Failed to save settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.primaryDark,
        appBar: CustomAppBar(
          title: 'Email Settings',
          leading: CustomBackButton(),
        ),
        body: Center(child: LoadingIndicator()),
      );
    }

    if (_currentSettings == null) {
      return Scaffold(
        backgroundColor: AppColors.primaryDark,
        appBar: const CustomAppBar(
          title: 'Email Settings',
          leading: CustomBackButton(),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.errorRed,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load settings',
                style: AppTextStyles.titleMedium
                    .copyWith(color: AppColors.textWhite),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandCyan,
                  foregroundColor: AppColors.primaryDark,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: CustomAppBar(
        title: 'Email Settings',
        leading: const CustomBackButton(),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.brandCyan),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Email Address Section
          _buildEmailAddressSection(),

          const SizedBox(height: 24),

          // Notification Settings
          _buildNotificationSettings(),

          const SizedBox(height: 24),

          // Email Management Settings
          _buildEmailManagementSettings(),

          const SizedBox(height: 24),

          // Advanced Settings
          _buildAdvancedSettings(),

          const SizedBox(height: 24),

          // Help & Support
          _buildHelpSection(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Build email address section
  Widget _buildEmailAddressSection() => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryMedium.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.brandCyan.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandCyan.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.brandCyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.alternate_email,
                  color: AppColors.brandCyan,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Your SweepFeed Email',
                style: AppTextStyles.titleMedium
                    .copyWith(color: AppColors.textWhite),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Email address display
          Consumer(
            builder: (context, ref, child) {
              final emailAddressAsync = ref.watch(userSweepFeedEmailProvider);
              return emailAddressAsync.when(
                data: (emailAddress) => emailAddress == null
                    ? Text(
                        'No email address configured',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textMuted),
                      )
                    : Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryMedium,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primaryLight.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Email Address:',
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    emailAddress,
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      color: AppColors.brandCyan,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _copyToClipboard(emailAddress),
                              icon: const Icon(
                                Icons.copy,
                                color: AppColors.brandCyan,
                              ),
                              tooltip: 'Copy email address',
                            ),
                          ],
                        ),
                      ),
                loading: () => const LoadingIndicator(size: 20),
                error: (_, __) => Text(
                  'Error loading email address',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.errorRed),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          Text(
            'Use this email address to receive contests notifications directly in your SweepFeed inbox. Forward your existing contests emails here to keep everything organized.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
          ),

          const SizedBox(height: 16),

          // Setup guide button
          OutlinedButton.icon(
            onPressed: _openSetupGuide,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brandCyan,
              side: const BorderSide(color: AppColors.brandCyan),
            ),
            icon: const Icon(Icons.help_outline, size: 18),
            label: const Text('Email Setup Guide'),
          ),
        ],
      ),
    );

  /// Build notification settings section
  Widget _buildNotificationSettings() => _buildSettingsSection(
      title: 'Notifications',
      icon: Icons.notifications,
      children: [
        _buildToggleListTile(
          title: 'Push Notifications',
          subtitle: 'Receive push notifications for new emails',
          value: _currentSettings!.enablePushNotifications,
          onChanged: (value) {
            _saveSettings(
                _currentSettings!.copyWith(enablePushNotifications: value),);
          },
        ),
        _buildToggleListTile(
          title: 'Winner Emails Only',
          subtitle: 'Only get notified for winner announcements',
          value: _currentSettings!.notifyOnWinnerEmailsOnly,
          onChanged: (value) {
            _saveSettings(
                _currentSettings!.copyWith(notifyOnWinnerEmailsOnly: value),);
          },
        ),
        const Divider(color: AppColors.primaryLight),
        _buildToggleListTile(
          title: 'Email Summary',
          subtitle: 'Receive periodic email summaries',
          value: _currentSettings!.enableEmailSummary,
          onChanged: (value) {
            _saveSettings(
                _currentSettings!.copyWith(enableEmailSummary: value),);
          },
        ),
        if (_currentSettings!.enableEmailSummary)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Summary Frequency:',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.textLight),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: EmailSummaryFrequency.values.map((frequency) {
                    final isSelected =
                        _currentSettings!.summaryFrequency == frequency;
                    return ChoiceChip(
                      label: Text(frequency.displayName),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          _saveSettings(_currentSettings!
                              .copyWith(summaryFrequency: frequency),);
                        }
                      },
                      selectedColor: AppColors.brandCyan.withValues(alpha: 0.3),
                      labelStyle: AppTextStyles.labelSmall.copyWith(
                        color: isSelected
                            ? AppColors.brandCyan
                            : AppColors.textLight,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
      ],
    );

  /// Build email management settings section
  Widget _buildEmailManagementSettings() => _buildSettingsSection(
      title: 'Email Management',
      icon: Icons.manage_search,
      children: [
        _buildToggleListTile(
          title: 'Show Promotional Emails',
          subtitle: 'Display promotional emails in your inbox',
          value: _currentSettings!.showPromotionalEmails,
          onChanged: (value) {
            _saveSettings(
                _currentSettings!.copyWith(showPromotionalEmails: value),);
          },
        ),
        _buildToggleListTile(
          title: 'Auto-Categorize Emails',
          subtitle: 'Automatically sort emails into categories',
          value: _currentSettings!.autoCategorizeEmails,
          onChanged: (value) {
            _saveSettings(
                _currentSettings!.copyWith(autoCategorizeEmails: value),);
          },
        ),
      ],
    );

  /// Build advanced settings section
  Widget _buildAdvancedSettings() => _buildSettingsSection(
      title: 'Advanced',
      icon: Icons.tune,
      children: [
        ListTile(
          leading: const Icon(Icons.storage, color: AppColors.textLight),
          title: Text(
            'Manage Storage',
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textWhite),
          ),
          subtitle: Text(
            'Delete old emails to free up space',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
          ),
          trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
          onTap: _showStorageManagement,
        ),
        ListTile(
          leading: const Icon(Icons.download, color: AppColors.textLight),
          title: Text(
            'Export Emails',
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textWhite),
          ),
          subtitle: Text(
            'Download your emails as a backup',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
          ),
          trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
          onTap: _exportEmails,
        ),
      ],
    );

  /// Build help section
  Widget _buildHelpSection() => _buildSettingsSection(
      title: 'Help & Support',
      icon: Icons.help,
      children: [
        ListTile(
          leading: const Icon(Icons.book, color: AppColors.textLight),
          title: Text(
            'SimpleLogin Integration Guide',
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textWhite),
          ),
          subtitle: Text(
            'Learn how to set up email forwarding',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
          ),
          trailing: const Icon(Icons.open_in_new, color: AppColors.textLight),
          onTap: _openSimpleLoginGuide,
        ),
        ListTile(
          leading: const Icon(Icons.mail, color: AppColors.textLight),
          title: Text(
            'Email Troubleshooting',
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textWhite),
          ),
          subtitle: Text(
            'Common issues and solutions',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
          ),
          trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
          onTap: _showTroubleshooting,
        ),
        ListTile(
          leading: const Icon(Icons.support_agent, color: AppColors.textLight),
          title: Text(
            'Contact Support',
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textWhite),
          ),
          subtitle: Text(
            'Get help with your email inbox',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
          ),
          trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
          onTap: _contactSupport,
        ),
      ],
    );

  /// Build a settings section container
  Widget _buildSettingsSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) => Container(
      decoration: BoxDecoration(
        color: AppColors.primaryMedium.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: AppColors.textLight, size: 20),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: AppTextStyles.titleMedium
                      .copyWith(color: AppColors.textWhite),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );

  /// Build a toggle list tile
  Widget _buildToggleListTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) => ListTile(
      title: Text(
        title,
        style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textWhite),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.brandCyan,
        activeTrackColor: AppColors.brandCyan.withValues(alpha: 0.3),
      ),
    );

  /// Private helper methods

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showSuccessSnackBar('Email address copied to clipboard');
  }

  void _openSetupGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryMedium,
        title: Text(
          'Email Setup Guide',
          style: AppTextStyles.titleMedium.copyWith(color: AppColors.textWhite),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Step 1: Get Your SweepFeed Email',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.brandCyan,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Copy your unique SweepFeed email address from above. This is where all your contests emails will be forwarded.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
              ),
              const SizedBox(height: 16),
              Text(
                'Step 2: Set Up Email Forwarding',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.brandCyan,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'In your email client (Gmail, Outlook, etc.), create a filter or forwarding rule that forwards all contests emails to your SweepFeed email address.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
              ),
              const SizedBox(height: 16),
              Text(
                'Step 3: Verify Setup',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.brandCyan,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Send a test email to your SweepFeed address. It should appear in your SweepFeed inbox within a few minutes.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Got it',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.brandCyan),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSimpleLoginGuide() async {
    const url = 'https://simplelogin.io/docs/';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      _showErrorSnackBar('Could not open SimpleLogin guide');
    }
  }

  void _showStorageManagement() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.primaryMedium,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Storage Management',
              style: AppTextStyles.titleMedium
                  .copyWith(color: AppColors.textWhite),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading:
                  const Icon(Icons.auto_delete, color: AppColors.warningOrange),
              title: Text(
                'Delete emails older than 30 days',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textWhite),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmBulkDelete(30);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.auto_delete, color: AppColors.warningOrange),
              title: Text(
                'Delete emails older than 90 days',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textWhite),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmBulkDelete(90);
              },
            ),
            ListTile(
              leading: const Icon(Icons.clear_all, color: AppColors.errorRed),
              title: Text(
                'Delete all read emails',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textWhite),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteAllRead();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportEmails() async {
    try {
      setState(() => _isSaving = true);
      final emailService = ref.read(emailServiceProvider);
      final jsonData = await emailService.exportEmailsAsJson();

      // Save to file
      final appDir = await getApplicationDocumentsDirectory();
      final exportFile = File('${appDir.path}/sweepfeed_emails_export_${DateTime.now().millisecondsSinceEpoch}.json');
      await exportFile.writeAsString(jsonData);

      // Share the file
      await Share.shareXFiles(
        [XFile(exportFile.path)],
        text: 'My SweepFeed Emails Export',
      );

      _showSuccessSnackBar('Emails exported successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to export emails: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showTroubleshooting() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryMedium,
        title: Text(
          'Email Troubleshooting',
          style: AppTextStyles.titleMedium.copyWith(color: AppColors.textWhite),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTroubleshootingItem(
                'Emails not appearing',
                'Check that forwarding is set up correctly. Verify your SweepFeed email address is correct. Wait a few minutes for emails to sync.',
              ),
              const SizedBox(height: 16),
              _buildTroubleshootingItem(
                'Missing emails',
                'Some emails may be filtered by your email provider. Check spam/junk folders. Ensure forwarding rules include all relevant senders.',
              ),
              const SizedBox(height: 16),
              _buildTroubleshootingItem(
                'Notifications not working',
                'Go to Notification Settings and ensure push notifications are enabled. Check your device notification settings.',
              ),
              const SizedBox(height: 16),
              _buildTroubleshootingItem(
                "Can't delete emails",
                'Try refreshing the inbox. If the issue persists, clear the app cache and restart the app.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.brandCyan),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTroubleshootingItem(String title, String description) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.brandCyan,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
        ),
      ],
    );

  void _contactSupport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const HelpSupportScreen(),
      ),
    );
  }

  Future<void> _confirmBulkDelete(int days) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryMedium,
        title: Text(
          'Delete Old Emails',
          style: AppTextStyles.titleMedium.copyWith(color: AppColors.textWhite),
        ),
        content: Text(
          'Are you sure you want to delete all emails older than $days days? This action cannot be undone.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style:
                  AppTextStyles.labelLarge.copyWith(color: AppColors.textLight),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style:
                  AppTextStyles.labelLarge.copyWith(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() => _isSaving = true);
        final emailService = ref.read(emailServiceProvider);
        final deletedCount = await emailService.deleteEmailsOlderThan(days);
        _showSuccessSnackBar('Deleted $deletedCount email${deletedCount != 1 ? 's' : ''}');
      } catch (e) {
        _showErrorSnackBar('Failed to delete emails: $e');
      } finally {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _confirmDeleteAllRead() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryMedium,
        title: Text(
          'Delete Read Emails',
          style: AppTextStyles.titleMedium.copyWith(color: AppColors.textWhite),
        ),
        content: Text(
          'Are you sure you want to delete all read emails? This action cannot be undone.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style:
                  AppTextStyles.labelLarge.copyWith(color: AppColors.textLight),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style:
                  AppTextStyles.labelLarge.copyWith(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() => _isSaving = true);
        final emailService = ref.read(emailServiceProvider);
        final deletedCount = await emailService.deleteAllReadEmails();
        _showSuccessSnackBar('Deleted $deletedCount read email${deletedCount != 1 ? 's' : ''}');
      } catch (e) {
        _showErrorSnackBar('Failed to delete emails: $e');
      } finally {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primaryMedium,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
