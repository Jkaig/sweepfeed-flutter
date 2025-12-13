import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_back_button.dart';

final changeEmailStateProvider =
    StateNotifierProvider<ChangeEmailNotifier, ChangeEmailState>(
        (ref) => ChangeEmailNotifier(),);

sealed class ChangeEmailState {
  const ChangeEmailState();
  const factory ChangeEmailState.initial() = ChangeEmailInitial;
  const factory ChangeEmailState.loading() = ChangeEmailLoading;
  const factory ChangeEmailState.success({required bool needsVerification}) =
      ChangeEmailSuccess;
  const factory ChangeEmailState.error({required String errorMessage}) =
      ChangeEmailError;
}

class ChangeEmailInitial extends ChangeEmailState {
  const ChangeEmailInitial();
}

class ChangeEmailLoading extends ChangeEmailState {
  const ChangeEmailLoading();
}

class ChangeEmailSuccess extends ChangeEmailState {
  const ChangeEmailSuccess({required this.needsVerification});
  final bool needsVerification;
}

class ChangeEmailError extends ChangeEmailState {
  const ChangeEmailError({required this.errorMessage});
  final String errorMessage;
}

class ChangeEmailNotifier extends StateNotifier<ChangeEmailState> {
  ChangeEmailNotifier() : super(const ChangeEmailState.initial());
  DateTime? _lastEmailSentTime;

  Future<void> changeEmail(String newEmail) async {
    state = const ChangeEmailState.loading();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        state = const ChangeEmailState.error(errorMessage: 'No user logged in');
        return;
      }

      await user.verifyBeforeUpdateEmail(newEmail);

      state = const ChangeEmailState.success(needsVerification: true);
    } on FirebaseAuthException catch (e) {
      state = ChangeEmailState.error(errorMessage: _getErrorMessage(e.code));
    } catch (e) {
      debugPrint('Unexpected error during email change: $e');
      state = const ChangeEmailState.error(
        errorMessage: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  Future<void> resendVerificationEmail() async {
    try {
      if (_lastEmailSentTime != null) {
        final timeSinceLastEmail =
            DateTime.now().difference(_lastEmailSentTime!);
        if (timeSinceLastEmail.inMinutes < 2) {
          final waitTime = 2 - timeSinceLastEmail.inMinutes;
          state = ChangeEmailState.error(
            errorMessage:
                'Please wait $waitTime minute${waitTime > 1 ? 's' : ''} before requesting another email',
          );
          return;
        }
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
        _lastEmailSentTime = DateTime.now();
      }
    } catch (e) {
      debugPrint('Error resending verification email: $e');
      state = const ChangeEmailState.error(
        errorMessage: 'Failed to resend verification email',
      );
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Invalid email format';
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'requires-recent-login':
        return 'For security, please sign out and sign back in before changing your email';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      default:
        return 'Failed to change email. Please try again';
    }
  }

  void reset() {
    state = const ChangeEmailState.initial();
  }
}

class ChangeEmailScreen extends ConsumerStatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  ConsumerState<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends ConsumerState<ChangeEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newEmailController = TextEditingController();

  @override
  void dispose() {
    _newEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(changeEmailStateProvider);
    final user = FirebaseAuth.instance.currentUser;

    ref.listen<ChangeEmailState>(changeEmailStateProvider, (previous, next) {
      switch (next) {
        case ChangeEmailSuccess(:final needsVerification):
          if (needsVerification) {
            _showVerificationDialog();
          }
          break;
        case ChangeEmailError(:final errorMessage):
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
        case ChangeEmailInitial():
        case ChangeEmailLoading():
          break;
      }
    });

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: const CustomAppBar(
        title: 'Change Email',
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
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.brandCyan.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.info_outline,
                              color: AppColors.brandCyan,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Current Email',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          user?.email ?? 'No email',
                          style: const TextStyle(
                            color: AppColors.textLight,
                            fontSize: 14,
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
                      const Text(
                        'New Email Address',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'A verification link will be sent to your new email',
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _newEmailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'New Email Address',
                          labelStyle:
                              const TextStyle(color: AppColors.textLight),
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: AppColors.brandCyan,
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
                            return 'Please enter a new email address';
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Please enter a valid email address';
                          }
                          if (value == user?.email) {
                            return 'New email must be different from current email';
                          }
                          return null;
                        },
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
                    gradient: const LinearGradient(
                      colors: [AppColors.brandCyan, AppColors.brandCyanDark],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    onPressed:
                        state is ChangeEmailLoading ? null : _handleChangeEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: switch (state) {
                      ChangeEmailLoading() => const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryDark,
                            ),
                          ),
                        ),
                      _ => const Text(
                          'Change Email',
                          style: TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleChangeEmail() {
    if (_formKey.currentState!.validate()) {
      ref.read(changeEmailStateProvider.notifier).changeEmail(
            _newEmailController.text,
          );
    }
  }

  void _showVerificationDialog() {
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
            Icon(Icons.mark_email_read_outlined, color: AppColors.brandCyan),
            SizedBox(width: 12),
            Text(
              'Verify Your Email',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A verification email has been sent to ${_newEmailController.text}',
              style: const TextStyle(color: AppColors.textLight),
            ),
            const SizedBox(height: 12),
            const Text(
              'Please check your inbox and click the verification link to complete the email change.',
              style: TextStyle(color: AppColors.textLight),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref
                  .read(changeEmailStateProvider.notifier)
                  .resendVerificationEmail();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Verification email sent'),
                  backgroundColor: AppColors.successGreen,
                ),
              );
            },
            child: const Text(
              'Resend Email',
              style: TextStyle(color: AppColors.brandCyan),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.brandCyan, AppColors.brandCyanDark],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () {
                ref.read(changeEmailStateProvider.notifier).reset();
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text(
                'Done',
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
  }
}
