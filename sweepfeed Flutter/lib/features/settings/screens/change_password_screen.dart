import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_back_button.dart';

final changePasswordStateProvider =
    StateNotifierProvider<ChangePasswordNotifier, ChangePasswordState>(
        (ref) => ChangePasswordNotifier());

sealed class ChangePasswordState {
  const ChangePasswordState();
  const factory ChangePasswordState.initial() = ChangePasswordInitial;
  const factory ChangePasswordState.loading() = ChangePasswordLoading;
  const factory ChangePasswordState.success() = ChangePasswordSuccess;
  const factory ChangePasswordState.error({required String errorMessage}) =
      ChangePasswordError;
}

class ChangePasswordInitial extends ChangePasswordState {
  const ChangePasswordInitial();
}

class ChangePasswordLoading extends ChangePasswordState {
  const ChangePasswordLoading();
}

class ChangePasswordSuccess extends ChangePasswordState {
  const ChangePasswordSuccess();
}

class ChangePasswordError extends ChangePasswordState {
  const ChangePasswordError({required this.errorMessage});
  final String errorMessage;
}

enum PasswordError {
  wrongPassword,
  weakPassword,
  requiresRecentLogin,
  networkRequestFailed,
  tooManyRequests,
  unknown,
}

class ChangePasswordNotifier extends StateNotifier<ChangePasswordState> {
  ChangePasswordNotifier() : super(const ChangePasswordState.initial());

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = const ChangePasswordState.loading();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        state =
            const ChangePasswordState.error(errorMessage: 'No user logged in');
        return;
      }

      if (user.email == null) {
        state = const ChangePasswordState.error(
          errorMessage: 'User email is not available. Please log in again.',
        );
        return;
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      state = const ChangePasswordState.success();
    } on FirebaseAuthException catch (e) {
      state = ChangePasswordState.error(errorMessage: _getErrorMessage(e.code));
    } catch (e) {
      debugPrint('Unexpected error during password change: $e');
      state = const ChangePasswordState.error(
        errorMessage: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  String _getErrorMessage(String code) {
    PasswordError error;
    switch (code) {
      case 'wrong-password':
        error = PasswordError.wrongPassword;
        break;
      case 'weak-password':
        error = PasswordError.weakPassword;
        break;
      case 'requires-recent-login':
        error = PasswordError.requiresRecentLogin;
        break;
      case 'network-request-failed':
        error = PasswordError.networkRequestFailed;
        break;
      case 'too-many-requests':
        error = PasswordError.tooManyRequests;
        break;
      default:
        error = PasswordError.unknown;
    }

    switch (error) {
      case PasswordError.wrongPassword:
        return 'Current password is incorrect';
      case PasswordError.weakPassword:
        return 'New password is too weak. Use at least 8 characters with letters and numbers.';
      case PasswordError.requiresRecentLogin:
        return 'Please log out and log in again before changing password';
      case PasswordError.networkRequestFailed:
        return 'Network error. Please check your connection';
      case PasswordError.tooManyRequests:
        return 'Too many attempts. Please try again later';
      default:
        return 'Failed to change password. Please try again';
    }
  }

  void reset() {
    state = const ChangePasswordState.initial();
  }
}

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (value.length > 128) {
      return 'Password must be less than 128 characters';
    }
    if (!RegExp('[A-Za-z]').hasMatch(value)) {
      return 'Password must contain at least one letter';
    }
    if (!RegExp('[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Password should contain at least one special character';
    }

    final commonPasswords = [
      'password',
      '12345678',
      'qwerty',
      'abc123',
      'password123',
      'welcome',
      'monkey',
      'dragon',
      'master',
      'freedom',
    ];
    if (commonPasswords.any((common) => value.toLowerCase().contains(common))) {
      return 'Password is too common. Please choose a stronger password';
    }

    return null;
  }

  int _getPasswordStrength(String password) {
    var strength = 0;
    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;
    if (RegExp('[a-z]').hasMatch(password)) strength++;
    if (RegExp('[A-Z]').hasMatch(password)) strength++;
    if (RegExp('[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;
    return strength;
  }

  Color _getStrengthColor(int strength) {
    if (strength <= 2) return AppColors.errorRed;
    if (strength <= 4) return Colors.orange;
    return AppColors.successGreen;
  }

  String _getStrengthText(int strength) {
    if (strength <= 2) return 'Weak';
    if (strength <= 4) return 'Medium';
    return 'Strong';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(changePasswordStateProvider);

    ref.listen<ChangePasswordState>(changePasswordStateProvider,
        (previous, next) {
      switch (next) {
        case ChangePasswordSuccess():
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(child: Text('Password changed successfully!')),
                ],
              ),
              backgroundColor: AppColors.successGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop();
          break;
        case ChangePasswordError(:final errorMessage):
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
        case ChangePasswordInitial():
        case ChangePasswordLoading():
          break;
      }
    });

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: const CustomAppBar(
        title: 'Change Password',
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
                              Icons.shield_outlined,
                              color: AppColors.brandCyan,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Password Requirements',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildRequirementRow('At least 8 characters'),
                      const SizedBox(height: 8),
                      _buildRequirementRow('Contains letters and numbers'),
                      const SizedBox(height: 8),
                      _buildRequirementRow('Different from current password'),
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
                        'Change Your Password',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _currentPasswordController,
                        obscureText: _obscureCurrentPassword,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Current Password',
                          labelStyle:
                              const TextStyle(color: AppColors.textLight),
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: AppColors.brandCyan,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureCurrentPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppColors.textLight,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureCurrentPassword =
                                    !_obscureCurrentPassword;
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
                            return 'Please enter your current password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: _obscureNewPassword,
                        style: const TextStyle(color: Colors.white),
                        onChanged: (value) {
                          setState(() {});
                        },
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          labelStyle:
                              const TextStyle(color: AppColors.textLight),
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: AppColors.brandCyan,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNewPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppColors.textLight,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureNewPassword = !_obscureNewPassword;
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
                        validator: _validatePassword,
                      ),
                      if (_newPasswordController.text.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'Password Strength: ',
                                        style: TextStyle(
                                          color: AppColors.textLight,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        _getStrengthText(
                                          _getPasswordStrength(
                                            _newPasswordController.text,
                                          ),
                                        ),
                                        style: TextStyle(
                                          color: _getStrengthColor(
                                            _getPasswordStrength(
                                              _newPasswordController.text,
                                            ),
                                          ),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  LinearProgressIndicator(
                                    value: _getPasswordStrength(
                                          _newPasswordController.text,
                                        ) /
                                        6,
                                    backgroundColor: AppColors.primaryLight
                                        .withValues(alpha: 0.3),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _getStrengthColor(
                                        _getPasswordStrength(
                                          _newPasswordController.text,
                                        ),
                                      ),
                                    ),
                                    minHeight: 4,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Confirm New Password',
                          labelStyle:
                              const TextStyle(color: AppColors.textLight),
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: AppColors.brandCyan,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppColors.textLight,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
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
                            return 'Please confirm your new password';
                          }
                          if (value != _newPasswordController.text) {
                            return 'Passwords do not match';
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
                    onPressed: state is ChangePasswordLoading
                        ? null
                        : _handleChangePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: switch (state) {
                      ChangePasswordLoading() => const SizedBox(
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
                          'Change Password',
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

  Widget _buildRequirementRow(String text) => Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: AppColors.brandCyan,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 14,
            ),
          ),
        ],
      );

  void _handleChangePassword() {
    if (_formKey.currentState!.validate()) {
      if (_currentPasswordController.text == _newPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('New password must be different from current password'),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      ref.read(changePasswordStateProvider.notifier).changePassword(
            currentPassword: _currentPasswordController.text,
            newPassword: _newPasswordController.text,
          );
    }
  }
}
