import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../widgets/onboarding_button.dart';
import '../../widgets/onboarding_template.dart';

class CharityImpactStepScreen extends StatefulWidget {
  const CharityImpactStepScreen({
    required this.onNext,
    this.onSkip,
    this.onSkipCharity,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback? onSkip;
  final VoidCallback? onSkipCharity; // Skip charity selection entirely

  @override
  State<CharityImpactStepScreen> createState() =>
      _CharityImpactStepScreenState();
}

class _CharityImpactStepScreenState extends State<CharityImpactStepScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => OnboardingTemplate(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main icon - heart with money symbol
          const Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.favorite,
                size: 100,
                color: AppColors.successGreen,
              ),
              Icon(
                Icons.attach_money,
                size: 40,
                color: Colors.white,
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Title
          Text(
            'Enter to Win &\nSupport Charity',
            style: AppTextStyles.displaySmall.copyWith(
              color: AppColors.textWhite,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Description
          Text(
            "When you watch ads, 30% of that revenue goes to verified charities. You don't pay anything - we redirect ad revenue.",
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textLight,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Impact visualization
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryMedium,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.successGreen.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  '30% of ad revenue → Charity',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.successGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Revenue split visualization
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppColors.successGreen,
                          borderRadius: BorderRadius.horizontal(
                            left: Radius.circular(8),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            '30%\nCharity',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 7,
                      child: Container(
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppColors.electricBlue,
                          borderRadius: BorderRadius.horizontal(
                            right: Radius.circular(8),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            '70% Development',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, child) => ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: const [
                          Color(0xFFFF6B6B), // Red
                          Color(0xFFFF8E53), // Orange
                          Color(0xFFFFD93D), // Yellow
                          Color(0xFF6BCB77), // Green
                          Color(0xFF4D96FF), // Blue
                          Color(0xFF9B59B6), // Purple
                          Color(0xFFFF6B6B), // Red again for seamless loop
                        ],
                        stops: const [
                          0.0,
                          0.17,
                          0.33,
                          0.5,
                          0.67,
                          0.83,
                          1.0,
                        ],
                        begin: Alignment(-3.0 + _shimmerController.value * 6, 0),
                        end: Alignment(-1.0 + _shimmerController.value * 6, 0),
                      ).createShader(bounds),
                      child: child,
                    ),
                  child: Text(
                    'You can change the world!',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Continue button
          OnboardingButton(
            text: 'Choose My Charities',
            onPressed: widget.onNext,
          ),

          // Prominent No Thanks button
          if (widget.onSkipCharity != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: widget.onSkipCharity,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(
                    color: AppColors.textLight.withValues(alpha: 0.5),
                    width: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'No Thanks - Keep All Ad Revenue',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You can always change this later in settings',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
}
