import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/error_display.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/social_sign_in_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  DateTime? _dob;

  bool _isLoading = false;
  bool _showEmailForm = false;
  bool _showPhoneForm = false;
  String? _errorMessage; // Keep for auth errors not handled by service UI
  bool _biometricsAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final biometricService = ref.read(biometricAuthServiceProvider);
    final isAvailable = await biometricService.canUseBiometrics();
    if (mounted) {
      setState(() {
        _biometricsAvailable = isAvailable;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _dob) {
      setState(() {
        _dob = picked;
        _dobController.text = '${picked.toLocal()}'.split(' ')[0];
      });
    }
  }

  Future<void> _sendSignInLinkToEmail() async {
    final enhancedAuth = ref.read(enhancedAuthServiceProvider);
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_dob == null) {
      setState(() {
        _errorMessage = 'Please enter your date of birth.';
      });
      return;
    }
    final age = DateTime.now().difference(_dob!).inDays / 365;
    if (age < 13) {
      setState(() {
        _errorMessage = 'You must be at least 13 years old to sign up.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await enhancedAuth.sendSecureMagicLink(
        _emailController.text.trim(),
        context,
      );
    } catch (e) {
      setState(() {
        _errorMessage =
            'Unable to send sign-in link. Please check your email and try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithPhone() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_dob == null) {
      setState(() {
        _errorMessage = 'Please enter your date of birth.';
      });
      return;
    }
    final age = DateTime.now().difference(_dob!).inDays / 365;
    if (age < 13) {
      setState(() {
        _errorMessage = 'You must be at least 13 years old to sign up.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final enhancedAuth = ref.read(enhancedAuthServiceProvider);
      await enhancedAuth.sendSecureOTP(
        _phoneController.text.trim(),
        context,
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Unable to verify phone number. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final enhancedAuth = ref.read(enhancedAuthServiceProvider);
      await enhancedAuth.signInWithGoogle();
      // Navigation handled by AuthWrapper/SplashScreen
    } catch (e) {
      if (mounted) {
        final errorStr = e.toString();
        if (!errorStr.contains('canceled') && !errorStr.contains('cancelled')) {
          setState(() {
            _errorMessage = errorStr;
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final enhancedAuth = ref.read(enhancedAuthServiceProvider);
      await enhancedAuth.signInWithApple();
      // Navigation handled by AuthWrapper/SplashScreen
    } catch (e) {
      if (mounted) {
        final errorStr = e.toString();
        if (!errorStr.contains('canceled') && !errorStr.contains('cancelled')) {
          setState(() {
            _errorMessage = errorStr;
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleBiometricSignIn() async {
    setState(() => _isLoading = true);
    try {
      final biometricService = ref.read(biometricAuthServiceProvider);
      final user = await biometricService.signInWithBiometrics();
      final success = user != null;
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometric sign-in failed.')),
        );
      }
      // On success, AuthWrapper will handle navigation
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.primaryDark, // Updated background color
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title and Logo
                Text(
                  'Find your next win!',
                  style: AppTextStyles.headlineSmall
                      .copyWith(color: AppColors.textLight),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.small),
                Text(
                  'SweepFeed',
                  style: AppTextStyles.displaySmall
                      .copyWith(color: AppColors.cyberYellow),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xlarge),
                Center(
                  child: Image.asset(
                    'assets/icon/appicon.png', // Assuming this is a transparent logo suitable for dark bg
                    width: 150, // Adjusted size
                    height: 150,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxlarge),

                // Error message display
                if (_errorMessage != null)
                  ErrorDisplay(message: _errorMessage!),

                // Sign in options
                if (!_showEmailForm && !_showPhoneForm) ...[
                  PrimaryButton(
                    text: 'Sign in with Email',
                    onPressed: () => setState(() => _showEmailForm = true),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  PrimaryButton(
                    text: 'Sign in with Phone',
                    onPressed: () => setState(() => _showPhoneForm = true),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  SocialSignInButton(
                    providerName: 'Google',
                    icon: Image.asset(
                      'assets/icon/google_logo.png',
                      height: 24,
                      width: 24,
                    ),
                    onPressed: _isLoading ? () {} : _handleGoogleSignIn,
                    backgroundColor: Colors.white,
                    textColor: Colors.black87,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  if (Platform.isIOS)
                    SignInWithAppleButton(
                      onPressed: _isLoading ? () {} : _handleAppleSignIn,
                    ),
                  const SizedBox(height: AppSpacing.medium),
                  if (_biometricsAvailable)
                    IconButton(
                      icon: const Icon(
                        Icons.fingerprint,
                        color: Colors.white,
                        size: 48,
                      ),
                      onPressed: _isLoading ? null : _handleBiometricSignIn,
                      tooltip: 'Sign in with biometrics',
                    ),
                ],

                // Email Sign In Form
                if (_showEmailForm) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => setState(() {
                        _showEmailForm = false;
                        _showPhoneForm = false;
                      }),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppColors.textLight,
                      ),
                      label: Text(
                        'Back',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textLight),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.large),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CustomTextField(
                          controller: _emailController,
                          label: 'Email',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@') || !value.contains('.')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.large),
                        TextFormField(
                          controller: _dobController,
                          readOnly: true,
                          onTap: () => _selectDate(context),
                          decoration: const InputDecoration(
                            labelText: 'Date of Birth',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your date of birth';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.large),
                        PrimaryButton(
                          text: 'Send Sign-In Link',
                          onPressed: _sendSignInLinkToEmail,
                          isLoading: _isLoading,
                        ),
                      ],
                    ),
                  ),
                ],

                // Phone Sign In Form
                if (_showPhoneForm) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => setState(() {
                        _showEmailForm = false;
                        _showPhoneForm = false;
                      }),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppColors.textLight,
                      ),
                      label: Text(
                        'Back',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textLight),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.large),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CustomTextField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your phone number';
                            }
                            if (!value.startsWith('+')) {
                              return 'Please include country code (e.g., +1 for US)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.large),
                        TextFormField(
                          controller: _dobController,
                          readOnly: true,
                          onTap: () => _selectDate(context),
                          decoration: const InputDecoration(
                            labelText: 'Date of Birth',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your date of birth';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.large),
                        PrimaryButton(
                          text: 'Send Sign-In Code',
                          onPressed: _signInWithPhone,
                          isLoading: _isLoading,
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      );
}
