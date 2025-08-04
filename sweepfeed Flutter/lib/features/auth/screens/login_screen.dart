import 'package:flutter/material.dart';
import 'package:sweep_feed/core/widgets/custom_text_field.dart';
import 'package:sweep_feed/core/widgets/primary_button.dart';
import 'package:sweep_feed/core/widgets/social_sign_in_button.dart';
import 'package:sweep_feed/core/theme/app_colors.dart';
import 'package:sweep_feed/core/theme/app_text_styles.dart';
import '../services/auth_service.dart';
import './register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _showEmailForm = false;
  String? _errorMessage; // Keep for auth errors not handled by service UI

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // Assuming AuthService.signInWithEmail updates UI or navigates on success
      // and throws an error that can be caught here for specific UI feedback.
      await _authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
        context, // Pass context if needed by service for navigation/dialogs
      );
      // If successful, navigation should be handled by AuthWrapper or SplashScreen logic
    } catch (e) {
      setState(() {
        _errorMessage = e.toString(); // Display error message
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
      await _authService.signInWithGoogle(context);
      // Navigation handled by AuthWrapper/SplashScreen
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
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
      await _authService.signInWithApple(context);
      // Navigation handled by AuthWrapper/SplashScreen
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark, // Updated background color
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title and Logo
              Text(
                'Find your next win!',
                style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Sweep Feed',
                style: AppTextStyles.displaySmall.copyWith(color: AppColors.textWhite),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Center(
                child: Image.asset(
                  'assets/icon/appicon.png', // Assuming this is a transparent logo suitable for dark bg
                  width: 150, // Adjusted size
                  height: 150,
                ),
              ),
              const SizedBox(height: 48),

              // Error message display
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.errorRed.withOpacity(0.5)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.errorRed),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              
              // Sign in options
              if (!_showEmailForm) ...[
                PrimaryButton(
                  text: 'Sign in with Email',
                  onPressed: () => setState(() => _showEmailForm = true),
                  // This button's style will be different from PrimaryButton's accent
                  // Consider a SecondaryButton or styling PrimaryButton
                ),
                const SizedBox(height: 16),
                SocialSignInButton(
                  providerName: "Google",
                  icon: Image.asset('assets/icon/google_logo.png', height: 24, width: 24),
                  onPressed: _isLoading ? (){} : _handleGoogleSignIn,
                  backgroundColor: Colors.white,
                  textColor: Colors.black87,
                ),
                const SizedBox(height: 16),
                SocialSignInButton(
                  providerName: "Apple",
                  // Using Icon as apple_logo.png is not available
                  icon: const Icon(Icons.apple, size: 28, color: Colors.white),
                  onPressed: _isLoading ? (){} : _handleAppleSignIn,
                  backgroundColor: Colors.black, // Or AppColors.textWhite for consistency if needed
                  textColor: Colors.white,
                ),
              ],

              // Email Sign In Form
              if (_showEmailForm) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _showEmailForm = false),
                    icon: const Icon(Icons.arrow_back, color: AppColors.textLight),
                    label: Text('Back', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight)),
                  ),
                ),
                const SizedBox(height: 24),
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
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _passwordController,
                        label: 'Password',
                        prefixIcon: Icons.lock_outlined,
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // TODO: Implement forgot password
                          },
                          child: Text(
                            'Forgot Password?',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.accent),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        text: 'Sign In',
                        onPressed: _signInWithEmail,
                        isLoading: _isLoading,
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Sign up link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
                  ),
                  TextButton(
                    onPressed: _navigateToRegister,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Sign up',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.accent, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
