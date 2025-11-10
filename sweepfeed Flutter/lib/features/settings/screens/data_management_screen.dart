import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/security_utils.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_back_button.dart';

final dataManagementStateProvider =
    StateNotifierProvider<DataManagementNotifier, DataManagementState>(
        (ref) => DataManagementNotifier());

sealed class DataManagementState {
  const DataManagementState();
  const factory DataManagementState.initial() = DataManagementInitial;
  const factory DataManagementState.loading({required String progress}) =
      DataManagementLoading;
  const factory DataManagementState.success({required String message}) =
      DataManagementSuccess;
  const factory DataManagementState.error({required String errorMessage}) =
      DataManagementError;
}

class DataManagementInitial extends DataManagementState {
  const DataManagementInitial();
}

class DataManagementLoading extends DataManagementState {
  const DataManagementLoading({required this.progress});
  final String progress;
}

class DataManagementSuccess extends DataManagementState {
  const DataManagementSuccess({required this.message});
  final String message;
}

class DataManagementError extends DataManagementState {
  const DataManagementError({required this.errorMessage});
  final String errorMessage;
}

class DataManagementNotifier extends StateNotifier<DataManagementState> {
  DataManagementNotifier() : super(const DataManagementState.initial());

  Future<void> exportUserData() async {
    state = const DataManagementState.loading(progress: 'Preparing export...');

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        state =
            const DataManagementState.error(errorMessage: 'No user logged in');
        return;
      }

      final firestore = FirebaseFirestore.instance;
      final userData = <String, dynamic>{};

      state = const DataManagementState.loading(
        progress: 'Fetching profile data...',
      );
      final userDoc = await firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        userData['profile'] = SecurityUtils.sanitizeData(userDoc.data()!);
      }

      state =
          const DataManagementState.loading(progress: 'Fetching entries...');
      final entriesSnapshot = await firestore
          .collection('sweepstakes_entries')
          .where('userId', isEqualTo: user.uid)
          .get();
      userData['entries'] = entriesSnapshot.docs
          .map((doc) => SecurityUtils.sanitizeData(doc.data()))
          .toList();

      state = const DataManagementState.loading(progress: 'Fetching wins...');
      final winsSnapshot = await firestore
          .collection('sweepstakes_wins')
          .where('userId', isEqualTo: user.uid)
          .get();
      userData['wins'] = winsSnapshot.docs
          .map((doc) => SecurityUtils.sanitizeData(doc.data()))
          .toList();

      state = const DataManagementState.loading(
        progress: 'Fetching submissions...',
      );
      final submissionsSnapshot = await firestore
          .collection('sweepstakes_submissions')
          .where('userId', isEqualTo: user.uid)
          .get();
      userData['submissions'] = submissionsSnapshot.docs
          .map((doc) => SecurityUtils.sanitizeData(doc.data()))
          .toList();

      userData['exportDate'] = DateTime.now().toIso8601String();
      userData['userId'] = user.uid;
      userData['email'] = user.email;
      userData['privacyNotice'] =
          'This export contains your personal data. Keep it secure and encrypted.';

      state = const DataManagementState.loading(progress: 'Formatting data...');
      final jsonString = const JsonEncoder.withIndent('  ').convert(userData);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'sweepfeed_data_export_$timestamp.json';

      state = const DataManagementState.loading(progress: 'Preparing file...');
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'SweepFeed User Data Export',
        text:
            'Your SweepFeed data export. File size: ${(jsonString.length / 1024).toStringAsFixed(2)} KB',
      );

      state = const DataManagementState.success(
        message: 'Data exported successfully',
      );
    } catch (e) {
      debugPrint('Error exporting user data: $e');
      state = const DataManagementState.error(
        errorMessage: 'Failed to export data. Please try again.',
      );
    }
  }

  void reset() {
    state = const DataManagementState.initial();
  }
}

class DataManagementScreen extends ConsumerWidget {
  const DataManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dataManagementStateProvider);

    ref.listen<DataManagementState>(dataManagementStateProvider,
        (previous, next) {
      switch (next) {
        case DataManagementSuccess(:final message):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(message)),
                ],
              ),
              backgroundColor: AppColors.successGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
          break;
        case DataManagementError(:final errorMessage):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(errorMessage)),
                ],
              ),
              backgroundColor: AppColors.errorRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
          break;
        case DataManagementInitial():
        case DataManagementLoading():
          break;
      }
    });

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: const CustomAppBar(
        title: 'Manage Your Data',
        leading: CustomBackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: AppColors.primaryMedium,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: AppColors.brandCyan.withValues(alpha: 0.3),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.brandCyan.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.download_outlined,
                            color: AppColors.brandCyan,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Export Your Data',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Download a copy of your account information',
                                style: TextStyle(
                                  color: AppColors.textLight,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Your export will include:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDataItem(Icons.person_outline, 'Profile information'),
                    _buildDataItem(
                      Icons.card_giftcard_outlined,
                      'Sweepstakes entries',
                    ),
                    _buildDataItem(Icons.emoji_events_outlined, 'Win history'),
                    _buildDataItem(Icons.upload_file_outlined, 'Submissions'),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.brandCyan,
                              AppColors.brandCyanDark,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: state is DataManagementLoading
                              ? null
                              : () => ref
                                  .read(dataManagementStateProvider.notifier)
                                  .exportUserData(),
                          icon: switch (state) {
                            DataManagementLoading() => const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primaryDark,
                                  ),
                                ),
                              ),
                            _ => const Icon(Icons.download, size: 20),
                          },
                          label: Text(
                            switch (state) {
                              DataManagementLoading() => 'Exporting...',
                              _ => 'Export Data',
                            },
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: AppColors.primaryDark,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              color: AppColors.primaryMedium,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: AppColors.brandCyan.withValues(alpha: 0.3),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.brandCyan.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.info_outline,
                            color: AppColors.brandCyan,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Data Rights',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Under data protection laws, you have the right to:',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildRightItem('Access your personal data'),
                    _buildRightItem('Correct inaccurate data'),
                    _buildRightItem('Request deletion of your data'),
                    _buildRightItem('Export your data in a portable format'),
                    _buildRightItem('Object to processing of your data'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              color: AppColors.errorRed.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: AppColors.errorRed.withValues(alpha: 0.5),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.delete_forever_outlined,
                          color: AppColors.errorRed,
                          size: 28,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Delete Your Data',
                            style: TextStyle(
                              color: AppColors.errorRed,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'To permanently delete your account and all associated data, go to Account Settings.',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushNamed('/account-settings');
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.errorRed,
                          side: const BorderSide(
                            color: AppColors.errorRed,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Go to Account Settings',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataItem(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: AppColors.brandCyan,
            ),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );

  Widget _buildRightItem(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 16,
              color: AppColors.brandCyan,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
}
