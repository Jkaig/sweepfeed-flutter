import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sweep_feed/core/widgets/custom_text_field.dart';
import 'package:sweep_feed/core/widgets/primary_button.dart';
import 'package:sweep_feed/core/theme/app_colors.dart';
import 'package:sweep_feed/core/theme/app_text_styles.dart';
import '../services/auth_service.dart';
import 'package:sweep_feed/core/widgets/custom_text_field.dart';
import 'package:sweep_feed/core/widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referralCodeController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;
  String _selectedCountry = 'United States';
  bool _isOver18 = false;

  final List<String> _countries = ['United States', 'Canada', 'United Kingdom', 'Australia'];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!_isOver18) {
      setState(() => _errorMessage = 'You must be 18 or older to register.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final userProfile = {
        'preferences': {},
        'country': _selectedCountry,
        'state': '',
        'ageVerified': _isOver18,
      };
      await _authService.registerWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
        userProfile,
        _referralCodeController.text.trim().isEmpty ? null : _referralCodeController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'Registration failed. Please try again.';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create Account',
                style: AppTextStyles.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Join SweepFeed to start winning',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

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

              CustomTextField(
                controller: _nameController,
                label: 'Full Name',
                prefixIcon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter your name';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _emailController,
                label: 'Email',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter your email';
                  if (!value.contains('@') || !value.contains('.')) return 'Please enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _passwordController,
                label: 'Password',
                prefixIcon: Icons.lock_outline,
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter a password';
                  if (value.length < 6) return 'Password must be at least 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _confirmPasswordController,
                label: 'Confirm Password',
                prefixIcon: Icons.lock_outline,
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please confirm your password';
                  if (value != _passwordController.text) return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _referralCodeController,
                label: 'Referral Code (Optional)',
                prefixIcon: Icons.group_add_outlined,
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: _selectedCountry,
                decoration: InputDecoration(
                  labelText: 'Country',
                  labelStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
                  prefixIcon: const Icon(Icons.public, color: AppColors.textLight),
                  filled: true,
                  fillColor: AppColors.primaryMedium,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primaryLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primaryLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.accent, width: 2.0),
                  ),
                ),
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textWhite),
                dropdownColor: AppColors.primaryMedium,
                items: _countries.map((String country) {
                  return DropdownMenuItem(
                    value: country,
                    child: Text(country, style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textWhite)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) setState(() => _selectedCountry = newValue);
                },
              ),
              const SizedBox(height: 24),
              CheckboxListTile(
                value: _isOver18,
                onChanged: (bool? value) => setState(() => _isOver18 = value ?? false),
                title: Text('I am 18 years or older', style: AppTextStyles.bodyMedium),
                checkColor: AppColors.primaryDark,
                activeColor: AppColors.accent,
                tileColor: AppColors.primaryMedium,
                controlAffinity: ListTileControlAffinity.leading,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Create Account',
                onPressed: _register,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 24),
              Text(
                'By creating an account, you agree to our Terms of Service and Privacy Policy.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
