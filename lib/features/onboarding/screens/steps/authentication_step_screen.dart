import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../widgets/onboarding_template.dart';

/// Authentication step screen for onboarding flow.
/// Allows users to sign in with Google, Apple, or email before profile setup.
class AuthenticationStepScreen extends ConsumerStatefulWidget {
  const AuthenticationStepScreen({
    required this.onNext,
    this.onSkip,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback? onSkip;

  @override
  ConsumerState<AuthenticationStepScreen> createState() =>
      _AuthenticationStepScreenState();
}

class _AuthenticationStepScreenState
    extends ConsumerState<AuthenticationStepScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  bool _showEmailForm = false;
  bool _emailLinkSent = false;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithGoogle(context);

      // Check if sign-in was successful by checking currentUser
      if (!mounted) return;
      
      if (authService.currentUser != null) {
        logger.i('Google sign-in successful during onboarding');
        // Reset loading state before navigation
        setState(() {
          _isLoading = false;
        });
        // Small delay to ensure state is updated
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          widget.onNext();
        }
      } else {
        setState(() {
          _errorMessage = 'Google sign-in was cancelled';
          _isLoading = false;
        });
      }
    } catch (e) {
      logger.e('Google sign-in error during onboarding: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Sign-in failed. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithApple() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithApple(context);

      // Check if sign-in was successful by checking currentUser
      if (!mounted) return;
      
      if (authService.currentUser != null) {
        logger.i('Apple sign-in successful during onboarding');
        // Reset loading state before navigation
        setState(() {
          _isLoading = false;
        });
        // Small delay to ensure state is updated
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          widget.onNext();
        }
      } else {
        setState(() {
          _errorMessage = 'Apple sign-in was cancelled';
          _isLoading = false;
        });
      }
    } catch (e) {
      logger.e('Apple sign-in error during onboarding: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Sign-in failed. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendEmailLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.sendSignInLinkToEmail(
        _emailController.text.trim(),
        context,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _emailLinkSent = true;
        });
      }
    } catch (e) {
      logger.e('Email link error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addPhoneBackup() async {
    // Show phone number input dialog
    final phoneController = TextEditingController();
    final phone = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.primaryMedium,
        title: Text(
          'Add Phone Backup',
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.textWhite,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add your phone number as a backup for account recovery.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: AppColors.textWhite),
              decoration: InputDecoration(
                hintText: '+1 234 567 8900',
                hintStyle: TextStyle(
                  color: AppColors.textLight.withValues(alpha: 0.5),
                ),
                prefixIcon: const Icon(
                  Icons.phone,
                  color: AppColors.brandCyan,
                ),
                filled: true,
                fillColor: AppColors.primaryDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textLight),
            ),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(dialogContext, phoneController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandCyan,
            ),
            child: const Text(
              'Verify',
              style: TextStyle(color: AppColors.primaryDark),
            ),
          ),
        ],
      ),
    );

    if (phone == null || phone.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      // linkPhoneNumberForBackup handles navigation to OTP screen internally
      await authService.linkPhoneNumberForBackup(phone, context);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildEmailForm() {
    // Show success message if email link was sent
    if (_emailLinkSent) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Back button
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textWhite,
                ),
                onPressed: () => setState(() {
                  _showEmailForm = false;
                  _emailLinkSent = false;
                  _errorMessage = null;
                }),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Success icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.successGreen.withValues(alpha: 0.2),
            ),
            child: const Icon(
              Icons.mark_email_read_outlined,
              size: 40,
              color: AppColors.successGreen,
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Check Your Email',
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textWhite,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          Text(
            'We sent a sign-in link to',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Text(
            _emailController.text.trim(),
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.brandCyan,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          Text(
            'Click the link in your email to sign in.\nNo password needed!',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Resend button
          TextButton(
            onPressed: _sendEmailLink,
            child: Text(
              'Resend Email Link',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.brandCyan,
              ),
            ),
          ),
        ],
      );
    }

    // Email input form
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Back button and title
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textWhite,
                ),
                onPressed: () => setState(() {
                  _showEmailForm = false;
                  _errorMessage = null;
                }),
              ),
              const SizedBox(width: 8),
              Text(
                'Continue with Email',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Email field
          CustomTextField(
            controller: _emailController,
            label: 'Email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Info text
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.brandCyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.brandCyan.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.brandCyan,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "We'll send you a magic link to sign in - no password needed!",
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _sendEmailLink,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandCyan,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Send Sign-In Link',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Add phone backup option
          TextButton.icon(
            onPressed: _addPhoneBackup,
            icon: const Icon(
              Icons.phone_android,
              color: AppColors.textLight,
              size: 18,
            ),
            label: Text(
              'Or sign in with phone number',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => OnboardingTemplate(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),

            // Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandCyan.withValues(alpha: 0.2),
                border: Border.all(
                  color: AppColors.brandCyan,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.person_add_outlined,
                size: 50,
                color: AppColors.brandCyan,
              ),
            ),

            const SizedBox(height: 32),

            // Title
            Text(
              'Create Your Account',
              style: AppTextStyles.displaySmall.copyWith(
                color: AppColors.textWhite,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Subtitle
            Text(
              'Sign in to save your progress and\nunlock all features',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textWhite.withValues(alpha: 0.85),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // Error message
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.errorRed,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.errorRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Loading indicator
            if (_isLoading) ...[
              const CircularProgressIndicator(
                color: AppColors.brandCyan,
              ),
              const SizedBox(height: 16),
              Text(
                'Signing in...',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textLight,
                ),
              ),
            ] else if (_showEmailForm) ...[
              // Email sign-in/sign-up form
              _buildEmailForm(),
            ] else ...[
              // Google Sign In Button
              _AuthButton(
                onPressed: _signInWithGoogle,
                icon: 'assets/images/google_logo.png',
                fallbackIcon: Icons.g_mobiledata,
                label: 'Continue with Google',
                backgroundColor: Colors.white,
                textColor: Colors.black87,
              ),

              const SizedBox(height: 16),

              // Apple Sign In Button (iOS only)
              if (Platform.isIOS) ...[
                _AuthButton(
                  onPressed: _signInWithApple,
                  icon: null,
                  fallbackIcon: Icons.apple,
                  label: 'Continue with Apple',
                  backgroundColor: Colors.black,
                  textColor: Colors.white,
                ),
                const SizedBox(height: 16),
              ],

              // Email Sign In Button
              _AuthButton(
                onPressed: () => setState(() => _showEmailForm = true),
                icon: null,
                fallbackIcon: Icons.email_outlined,
                label: 'Continue with Email',
                backgroundColor: AppColors.primaryMedium,
                textColor: AppColors.textWhite,
              ),

              const SizedBox(height: 24),

              // Divider
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: AppColors.textLight.withValues(alpha: 0.3),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Quick & Secure',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textWhite.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: AppColors.textLight.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Benefits list
              const _BenefitItem(
                icon: Icons.cloud_done_outlined,
                text: 'Your progress is saved automatically',
              ),
              const SizedBox(height: 12),
              const _BenefitItem(
                icon: Icons.emoji_events_outlined,
                text: 'Track your entries and wins',
              ),
              const SizedBox(height: 12),
              const _BenefitItem(
                icon: Icons.notifications_active_outlined,
                text: 'Get notified about new contests',
              ),
            ],

            const SizedBox(height: 32),

            // Skip button (if allowed)
            if (widget.onSkip != null && !_isLoading)
              TextButton(
                onPressed: widget.onSkip,
                child: Text(
                  'Skip for now',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textWhite,
                  ),
                ),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
}

/// Custom auth button widget
class _AuthButton extends StatelessWidget {
  const _AuthButton({
    required this.onPressed,
    required this.icon,
    required this.fallbackIcon,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final VoidCallback onPressed;
  final String? icon;
  final IconData fallbackIcon;
  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) => SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              Image.asset(
                icon!,
                width: 24,
                height: 24,
                errorBuilder: (context, error, stackTrace) => Icon(
                  fallbackIcon,
                  size: 24,
                  color: textColor,
                ),
              )
            else
              Icon(
                fallbackIcon,
                size: 28,
                color: textColor,
              ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
}

/// Benefit item widget
class _BenefitItem extends StatelessWidget {
  const _BenefitItem({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.brandCyan.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.brandCyan.withValues(alpha: 0.5),
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textWhite,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
}
