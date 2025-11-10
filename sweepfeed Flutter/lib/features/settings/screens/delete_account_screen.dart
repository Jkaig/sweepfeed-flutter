import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_back_button.dart';

final deleteAccountStateProvider =
    StateNotifierProvider<DeleteAccountNotifier, DeleteAccountState>(
        (ref) => DeleteAccountNotifier());

sealed class DeleteAccountState {
  const DeleteAccountState();
  const factory DeleteAccountState.initial() = DeleteAccountInitial;
  const factory DeleteAccountState.loading() = DeleteAccountLoading;
  const factory DeleteAccountState.success() = DeleteAccountSuccess;
  const factory DeleteAccountState.error({required String errorMessage}) =
      DeleteAccountError;
}

class DeleteAccountInitial extends DeleteAccountState {
  const DeleteAccountInitial();
}

class DeleteAccountLoading extends DeleteAccountState {
  const DeleteAccountLoading();
}

class DeleteAccountSuccess extends DeleteAccountState {
  const DeleteAccountSuccess();
}

class DeleteAccountError extends DeleteAccountState {
  const DeleteAccountError({required this.errorMessage});
  final String errorMessage;
}

enum DeleteError {
  wrongPassword,
  requiresRecentLogin,
  networkRequestFailed,
  tooManyRequests,
  unknown,
}

class DeleteAccountNotifier extends StateNotifier<DeleteAccountState> {
  DeleteAccountNotifier() : super(const DeleteAccountState.initial());

  Future<void> deleteAccount(String password) async {
    state = const DeleteAccountState.loading();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        state =
            const DeleteAccountState.error(errorMessage: 'No user logged in');
        return;
      }

      if (user.email == null) {
        state = const DeleteAccountState.error(
          errorMessage: 'User email is not available. Please log in again.',
        );
        return;
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);

      await _markAccountForDeletion(user.uid);

      state = const DeleteAccountState.success();
    } on FirebaseAuthException catch (e) {
      state = DeleteAccountState.error(errorMessage: _getErrorMessage(e.code));
    } catch (e) {
      debugPrint('Unexpected error during account deletion: $e');
      state = const DeleteAccountState.error(
        errorMessage: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  Future<void> _markAccountForDeletion(String uid) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final deletionDate = DateTime.now().add(const Duration(days: 7));

      await firestore.collection('users').doc(uid).update({
        'markedForDeletion': true,
        'deletionScheduledFor': Timestamp.fromDate(deletionDate),
        'deletionMarkedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Account marked for deletion. Scheduled for: $deletionDate');
    } catch (e) {
      debugPrint('Error marking account for deletion: $e');
      rethrow;
    }
  }

  Future<void> _deleteUserData(String uid) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      var operationCount = 0;

      final userDoc = firestore.collection('users').doc(uid);
      batch.delete(userDoc);
      operationCount++;

      final collectionsToClean = [
        'sweepstakes_entries',
        'sweepstakes_wins',
        'sweepstakes_submissions',
      ];

      for (final collectionName in collectionsToClean) {
        final query = await firestore
            .collection(collectionName)
            .where('userId', isEqualTo: uid)
            .limit(500)
            .get();

        for (final doc in query.docs) {
          batch.delete(doc.reference);
          operationCount++;

          if (operationCount >= 500) {
            await batch.commit();
            operationCount = 0;
          }
        }
      }

      if (operationCount > 0) {
        await batch.commit();
      }

      debugPrint('Successfully deleted user data for uid: $uid');
    } catch (e) {
      debugPrint('Error deleting user data: $e');
      rethrow;
    }
  }

  String _getErrorMessage(String code) {
    DeleteError error;
    switch (code) {
      case 'wrong-password':
        error = DeleteError.wrongPassword;
        break;
      case 'requires-recent-login':
        error = DeleteError.requiresRecentLogin;
        break;
      case 'network-request-failed':
        error = DeleteError.networkRequestFailed;
        break;
      case 'too-many-requests':
        error = DeleteError.tooManyRequests;
        break;
      default:
        error = DeleteError.unknown;
    }

    switch (error) {
      case DeleteError.wrongPassword:
        return 'Password is incorrect';
      case DeleteError.requiresRecentLogin:
        return 'Please log out and log in again before deleting your account';
      case DeleteError.networkRequestFailed:
        return 'Network error. Please check your connection';
      case DeleteError.tooManyRequests:
        return 'Too many attempts. Please try again later';
      default:
        return 'Failed to delete account. Please try again';
    }
  }

  void reset() {
    state = const DeleteAccountState.initial();
  }
}

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _confirmDelete = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deleteAccountStateProvider);

    ref.listen<DeleteAccountState>(deleteAccountStateProvider,
        (previous, next) {
      switch (next) {
        case DeleteAccountSuccess():
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              backgroundColor: AppColors.primaryMedium,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: AppColors.brandCyan.withValues(alpha: 0.3),
                ),
              ),
              title: const Row(
                children: [
                  Icon(Icons.schedule, color: AppColors.brandCyan),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Account Deletion Scheduled',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your account has been scheduled for deletion in 7 days.',
                    style: TextStyle(color: AppColors.textLight),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'During this time, you can still log in to cancel the deletion and restore your account.',
                    style: TextStyle(color: AppColors.textLight),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'After 7 days, all your data will be permanently deleted.',
                    style: TextStyle(
                      color: AppColors.errorRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              actions: [
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.brandCyan, AppColors.brandCyanDark],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context)
                          .pushNamedAndRemoveUntil('/login', (route) => false);
                    },
                    child: const Text(
                      'I Understand',
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
          break;
        case DeleteAccountError(:final errorMessage):
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
        case DeleteAccountInitial():
        case DeleteAccountLoading():
          break;
      }
    });

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: const CustomAppBar(
        title: 'Delete Account',
        leading: CustomBackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: AppColors.errorRed.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: AppColors.errorRed.withValues(alpha: 0.5),
                    width: 2,
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
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.errorRed.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.warning_outlined,
                              color: AppColors.errorRed,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Warning: This is Permanent',
                              style: TextStyle(
                                color: AppColors.errorRed,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Deleting your account will:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildWarningRow(
                        'Permanently delete your profile and account data',
                      ),
                      const SizedBox(height: 8),
                      _buildWarningRow('Remove all your sweepstakes entries'),
                      const SizedBox(height: 8),
                      _buildWarningRow('Delete your win history'),
                      const SizedBox(height: 8),
                      _buildWarningRow('Cancel any pending submissions'),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.brandCyan.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              color: AppColors.brandCyan,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '7-day grace period: You can cancel deletion within 7 days',
                                style: TextStyle(
                                  color: AppColors.brandCyan,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
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
                      const Text(
                        'Confirm Account Deletion',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Please enter your password to confirm',
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle:
                              const TextStyle(color: AppColors.textLight),
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: AppColors.brandCyan,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppColors.textLight,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.primaryLight),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.primaryLight),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.brandCyan,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor:
                              AppColors.primaryLight.withValues(alpha: 0.3),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      CheckboxListTile(
                        value: _confirmDelete,
                        onChanged: (value) {
                          setState(() {
                            _confirmDelete = value ?? false;
                          });
                        },
                        title: const Text(
                          'I understand that this action is permanent and cannot be undone',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        activeColor: AppColors.errorRed,
                        checkColor: Colors.white,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.errorRed,
                        AppColors.errorRed.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    onPressed:
                        (state is DeleteAccountLoading || !_confirmDelete)
                            ? null
                            : _handleDeleteAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      disabledBackgroundColor:
                          AppColors.primaryLight.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: switch (state) {
                      DeleteAccountLoading() => const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      _ => Text(
                          'Delete My Account',
                          style: TextStyle(
                            color: _confirmDelete
                                ? Colors.white
                                : AppColors.textLight,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Cancel and Go Back',
                    style: TextStyle(
                      color: AppColors.brandCyan,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWarningRow(String text) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.close,
            color: AppColors.errorRed,
            size: 18,
          ),
          const SizedBox(width: 8),
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
      );

  void _handleDeleteAccount() {
    if (_formKey.currentState!.validate()) {
      if (!_confirmDelete) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please confirm that you understand this action is permanent',
            ),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.primaryMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: AppColors.errorRed.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppColors.errorRed,
                size: 28,
              ),
              SizedBox(width: 12),
              Text(
                'Final Confirmation',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: const Text(
            'Are you absolutely sure you want to delete your account? This action is permanent and cannot be undone.',
            style: TextStyle(color: AppColors.textLight),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.brandCyan),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.errorRed,
                    AppColors.errorRed.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ref.read(deleteAccountStateProvider.notifier).deleteAccount(
                        _passwordController.text,
                      );
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
  }
}
