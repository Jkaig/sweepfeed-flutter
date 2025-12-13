import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/logger.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_back_button.dart';

class DataSettingsScreen extends ConsumerStatefulWidget {
  const DataSettingsScreen({super.key});

  @override
  ConsumerState<DataSettingsScreen> createState() => _DataSettingsScreenState();
}

class _DataSettingsScreenState extends ConsumerState<DataSettingsScreen> {
  bool _isCalculating = false;
  bool _isClearing = false;
  bool _isExporting = false;
  String _cacheSize = 'Calculating...';
  String _dataSize = 'Calculating...';

  @override
  void initState() {
    super.initState();
    _calculateSizes();
  }

  Future<void> _calculateSizes() async {
    setState(() {
      _isCalculating = true;
    });

    try {
      // Calculate cache size
      final cacheDir = await getTemporaryDirectory();
      final cacheSize = await _getDirectorySize(cacheDir);
      _cacheSize = _formatBytes(cacheSize);

      // Calculate data size (approximate)
      final appDir = await getApplicationDocumentsDirectory();
      final dataSize = await _getDirectorySize(appDir);
      _dataSize = _formatBytes(dataSize);
    } catch (e) {
      logger.e('Error calculating sizes', error: e);
      _cacheSize = 'Error';
      _dataSize = 'Error';
    } finally {
      setState(() {
        _isCalculating = false;
      });
    }
  }

  Future<int> _getDirectorySize(Directory dir) async {
    var size = 0;
    try {
      if (await dir.exists()) {
        await for (final entity in dir.list(recursive: true)) {
          if (entity is File) {
            size += await entity.length();
          }
        }
      }
    } catch (e) {
      logger.e('Error getting directory size', error: e);
    }
    return size;
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryMedium,
        title: Text(
          'Clear Cache',
          style: AppTextStyles.titleMedium.copyWith(color: AppColors.textWhite),
        ),
        content: Text(
          'This will clear all cached data including images and temporary files. This action cannot be undone.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.textLight),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Clear',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isClearing = true;
    });

    try {
      final cacheDir = await getTemporaryDirectory();
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        await cacheDir.create();
      }

      _showSuccessSnackBar('Cache cleared successfully');
      await _calculateSizes();
    } catch (e) {
      logger.e('Error clearing cache', error: e);
      _showErrorSnackBar('Failed to clear cache');
    } finally {
      setState(() {
        _isClearing = false;
      });
    }
  }

  Future<void> _exportData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryMedium,
        title: Text(
          'Export Data',
          style: AppTextStyles.titleMedium.copyWith(color: AppColors.textWhite),
        ),
        content: Text(
          'This will export all your SweepFeed data including profile, entries, and preferences as a JSON file.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.textLight),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Export',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.brandCyan),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isExporting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorSnackBar('Please sign in to export data');
        return;
      }

      // Get user data from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        _showErrorSnackBar('User data not found');
        return;
      }

      final userData = userDoc.data()!;
      
      // Get user's entries
      final entriesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('entries')
          .get();

      final entries = entriesSnapshot.docs.map((doc) => doc.data()).toList();

      // Compile export data
      final exportData = {
        'exportDate': DateTime.now().toIso8601String(),
        'userId': user.uid,
        'userEmail': user.email,
        'profile': userData,
        'entries': entries,
      };

      // Save to file
      final appDir = await getApplicationDocumentsDirectory();
      final exportFile = File('${appDir.path}/sweepfeed_export_${DateTime.now().millisecondsSinceEpoch}.json');
      await exportFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(exportData),
      );

      // Share the file
      await Share.shareXFiles(
        [XFile(exportFile.path)],
        text: 'My SweepFeed Data Export',
      );

      _showSuccessSnackBar('Data exported successfully');
    } catch (e) {
      logger.e('Error exporting data', error: e);
      _showErrorSnackBar('Failed to export data');
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryMedium,
        title: Text(
          'Delete Account',
          style: AppTextStyles.titleMedium.copyWith(color: AppColors.errorRed),
        ),
        content: Text(
          'WARNING: This will permanently delete your account and all associated data. This action cannot be undone.\n\nAre you absolutely sure?',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.textLight),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete Account',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Second confirmation
    final doubleConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryMedium,
        title: Text(
          'Final Confirmation',
          style: AppTextStyles.titleMedium.copyWith(color: AppColors.errorRed),
        ),
        content: Text(
          'This is your last chance. Your account and all data will be permanently deleted. Type "DELETE" to confirm.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.textLight),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete Forever',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );

    if (doubleConfirmed != true) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Delete user data from Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();

      // Delete user account
      await user.delete();

      _showSuccessSnackBar('Account deleted successfully');
      
      // Navigate to login
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      logger.e('Error deleting account', error: e);
      _showErrorSnackBar('Failed to delete account. Please contact support.');
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

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: const CustomAppBar(
        title: 'Data Settings',
        leading: CustomBackButton(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Storage Information
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryMedium.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.brandCyan.withValues(alpha: 0.3),
              ),
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
                        Icons.storage,
                        color: AppColors.brandCyan,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Storage Information',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textWhite,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_isCalculating)
                  const Center(child: CircularProgressIndicator())
                else
                  Column(
                    children: [
                      _buildStorageRow('Cache Size', _cacheSize),
                      const SizedBox(height: 12),
                      _buildStorageRow('Data Size', _dataSize),
                    ],
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Cache Management
          _buildSection(
            title: 'Cache Management',
            icon: Icons.cached,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.textLight),
                title: Text(
                  'Clear Cache',
                  style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textWhite),
                ),
                subtitle: Text(
                  'Free up space by clearing cached data',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
                ),
                trailing: _isClearing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chevron_right, color: AppColors.textLight),
                onTap: _isClearing ? null : _clearCache,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Data Export
          _buildSection(
            title: 'Data Export',
            icon: Icons.download,
            children: [
              ListTile(
                leading: const Icon(Icons.file_download, color: AppColors.textLight),
                title: Text(
                  'Export All Data',
                  style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textWhite),
                ),
                subtitle: Text(
                  'Download your data as a JSON file',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
                ),
                trailing: _isExporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chevron_right, color: AppColors.textLight),
                onTap: _isExporting ? null : _exportData,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Account Deletion
          _buildSection(
            title: 'Account Management',
            icon: Icons.warning,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_forever, color: AppColors.errorRed),
                title: Text(
                  'Delete Account',
                  style: AppTextStyles.bodyLarge.copyWith(color: AppColors.errorRed),
                ),
                subtitle: Text(
                  'Permanently delete your account and all data',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
                ),
                trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
                onTap: _deleteAccount,
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );

  Widget _buildStorageRow(String label, String value) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.brandCyan,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );

  Widget _buildSection({
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
                  style: AppTextStyles.titleMedium.copyWith(color: AppColors.textWhite),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
}
