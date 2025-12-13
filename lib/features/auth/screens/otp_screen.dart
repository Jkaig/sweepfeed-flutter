import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/primary_button.dart';

class OTPScreen extends ConsumerStatefulWidget {
  const OTPScreen({
    required this.verificationId,
    required this.phoneNumber,
    this.isLinking = false,
    super.key,
  });
  final String verificationId;
  final String phoneNumber;
  final bool isLinking; // True when linking phone to existing account

  @override
  ConsumerState<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends ConsumerState<OTPScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _otpController = TextEditingController();

  bool _isLoading = false;
  bool _isResending = false;
  int _resendCooldown = 0;
  String? _errorMessage;
  String _currentVerificationId = '';

  @override
  void initState() {
    super.initState();
    _currentVerificationId = widget.verificationId;
    _startResendCooldown();
  }

  void _startResendCooldown() {
    _resendCooldown = 30;
    _tickCooldown();
  }

  void _tickCooldown() {
    if (_resendCooldown > 0 && mounted) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _resendCooldown--;
          });
          _tickCooldown();
        }
      });
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _signInWithOTP() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final enhancedAuth = ref.read(enhancedAuthServiceProvider);
      if (widget.isLinking) {
        // Link phone to existing account - use verifyOTP and then link
        final credential = await enhancedAuth.verifyOTP(
          _currentVerificationId,
          _otpController.text.trim(),
        );
        if (credential != null && mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Phone number linked successfully!')),
          );
        }
      } else {
        // Normal phone sign-in
        await enhancedAuth.verifyOTP(
          _currentVerificationId,
          _otpController.text.trim(),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendOTP() async {
    if (_resendCooldown > 0 || _isResending) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      final enhancedAuth = ref.read(enhancedAuthServiceProvider);
      await enhancedAuth.sendSecureOTP(widget.phoneNumber, context);
      // Note: sendSecureOTP handles navigation internally

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP code sent successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        _startResendCooldown();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to resend code: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.primaryDark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Enter OTP',
                  style: AppTextStyles.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the 6-digit code sent to your phone.',
                  style: AppTextStyles.bodyLarge
                      .copyWith(color: AppColors.textLight),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: AppColors.errorRed.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.errorRed.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.errorRed),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CustomTextField(
                        controller: _otpController,
                        label: 'OTP',
                        prefixIcon: Icons.password_outlined,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the OTP';
                          }
                          if (value.length != 6) {
                            return 'OTP must be 6 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        text: 'Sign In',
                        onPressed: _signInWithOTP,
                        isLoading: _isLoading,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: (_resendCooldown > 0 || _isResending)
                      ? null
                      : _resendOTP,
                  child: _isResending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textLight,
                          ),
                        )
                      : Text(
                          _resendCooldown > 0
                              ? 'Resend Code ($_resendCooldown s)'
                              : 'Resend Code',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: _resendCooldown > 0
                                ? AppColors.textLight.withOpacity(0.5)
                                : AppColors.textLight,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      );
}
