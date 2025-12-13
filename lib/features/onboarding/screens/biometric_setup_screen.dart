import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/services/biometric_auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../utils/onboarding_constants.dart';
import '../widgets/common_onboarding_widgets.dart';

class BiometricSetupScreen extends StatefulWidget {
  const BiometricSetupScreen({
    required this.onNext,
    required this.onSkip,
    super.key,
    this.currentStep = 5,
  });
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final int currentStep;

  @override
  State<BiometricSetupScreen> createState() => _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends State<BiometricSetupScreen> {
  final BiometricAuthService _biometricService = BiometricAuthService();
  bool _isLoading = false;
  bool _canUseBiometrics = false;
  List<BiometricType> _availableBiometrics = [];
  String _biometricType = 'Biometric';

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final canUse = await _biometricService.canUseBiometrics();
    final available = await _biometricService.getAvailableBiometrics();

    if (mounted) {
      setState(() {
        _canUseBiometrics = canUse;
        _availableBiometrics = available;
        _biometricType = _biometricService.getBiometricTypeString(available);
      });
    }
  }

  Future<void> _enableBiometrics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _biometricService.enableBiometrics();

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$_biometricType login enabled successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onNext();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Failed to enable biometric login. You can enable it later in settings.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_canUseBiometrics) {
      Future.microtask(() => widget.onSkip());
      return const SizedBox.shrink();
    }

    return OnboardingScaffold(
      semanticLabel: 'Biometric authentication setup screen',
      currentStep: widget.currentStep,
      skipButton: OnboardingSkipButton(onPressed: widget.onSkip),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primaryMedium],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Icon(
              _getBiometricIcon(),
              size: OnboardingConstants.iconSize,
              color: AppColors.brandCyan,
            )
                .animate()
                .scale(duration: OnboardingConstants.scaleAnimationDuration)
                .then()
                .shimmer(),
            const SizedBox(height: OnboardingConstants.verticalSpacingLarge),
            Semantics(
              header: true,
              child: Text(
                'Quick & Secure Login',
                style: AppTextStyles.displaySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(delay: OnboardingConstants.fadeInDelayShort)
                  .slideY(),
            ),
            const SizedBox(height: OnboardingConstants.verticalSpacingMedium),
            Text(
              'Enable $_biometricType for instant access',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: OnboardingConstants.fadeInDelayMedium),
            const SizedBox(height: OnboardingConstants.verticalSpacingXXLarge),
            Semantics(
              label: 'Benefits of biometric login',
              child: Column(
                children: [
                  _buildBenefitItem(
                    icon: Icons.flash_on,
                    title: 'Lightning Fast',
                    description: 'Sign in instantly with $_biometricType',
                    color: Colors.amber,
                  )
                      .animate()
                      .fadeIn(delay: OnboardingConstants.fadeInDelayMedium)
                      .slideX(),
                  const SizedBox(
                    height: OnboardingConstants.verticalSpacingMedium,
                  ),
                  _buildBenefitItem(
                    icon: Icons.security,
                    title: 'Ultra Secure',
                    description: 'Your data stays encrypted on your device',
                    color: Colors.green,
                  )
                      .animate()
                      .fadeIn(delay: OnboardingConstants.fadeInDelayLong)
                      .slideX(),
                  const SizedBox(
                    height: OnboardingConstants.verticalSpacingMedium,
                  ),
                  _buildBenefitItem(
                    icon: Icons.privacy_tip,
                    title: 'Private',
                    description: 'No passwords to remember or share',
                    color: AppColors.brandCyan,
                  )
                      .animate()
                      .fadeIn(delay: OnboardingConstants.fadeInDelayXLong)
                      .slideX(),
                ],
              ),
            ),
            const Spacer(),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(
                  color: AppColors.brandCyan,
                ),
              )
            else
              OnboardingContinueButton(
                onPressed: _enableBiometrics,
                label: 'Enable $_biometricType',
              ).animate().fadeIn(delay: const Duration(milliseconds: 1000)),
            const SizedBox(height: OnboardingConstants.verticalSpacingMedium),
          ],
        ),
      ),
    );
  }

  IconData _getBiometricIcon() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return Icons.face;
    } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return Icons.fingerprint;
    }
    return Icons.security;
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) =>
      Semantics(
        label: '$title: $description',
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.5),
                  width: OnboardingConstants.borderWidth,
                ),
              ),
              child: Icon(
                icon,
                color: color,
                size: OnboardingConstants.smallIconSize,
              ),
            ),
            const SizedBox(width: OnboardingConstants.verticalSpacingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: OnboardingConstants.verticalSpacingSmall,
                  ),
                  Text(
                    description,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
