import 'package:flutter/material.dart';
// Assuming AppColors and AppTextStyles are now in core/theme
import 'package:sweep_feed/core/theme/app_colors.dart'; 
import 'package:sweep_feed/core/theme/app_text_styles.dart';
import 'package:sweep_feed/core/widgets/primary_button.dart'; // For PrimaryButton

class OnboardingTemplate extends StatelessWidget {
  final Widget animationWidget;
  final String title;
  final String subtitle;
  final List<String> highlights; // Existing highlights (bullet points)
  final List<Widget>? featureHighlightsList; // New list for FeatureHighlightCard
  final bool showPremiumCTA;
  final VoidCallback onNext;
  final VoidCallback? onSkip;
  final String nextButtonText;

  const OnboardingTemplate({
    super.key,
    required this.animationWidget,
    required this.title,
    required this.subtitle,
    required this.highlights,
    this.featureHighlightsList, // Added to constructor
    this.showPremiumCTA = false,
    required this.onNext,
    this.onSkip,
    this.nextButtonText = 'Next',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark, // Use new theme color
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.25, // Adjusted height
                child: animationWidget,
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineMedium.copyWith(color: AppColors.textWhite),
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textLight),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView( // Changed to ListView to accommodate both types of highlights
                  children: [
                    // Existing highlights (bullet points)
                    if (highlights.isNotEmpty)
                      ...highlights.map((highlight) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Icon(
                                  Icons.check_circle_outline,
                                  color: AppColors.accent, // Use new theme color
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    highlight,
                                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textWhite),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    
                    // New Feature Highlights
                    if (featureHighlightsList != null && featureHighlightsList!.isNotEmpty) ...[
                      const SizedBox(height: 24), // Spacing before feature highlights
                      // Padding for this section can be adjusted or inherited
                      // Padding(
                      //   padding: const EdgeInsets.symmetric(horizontal: 0.0), // No extra horizontal padding if parent provides
                      //   child: Column(
                      //     crossAxisAlignment: CrossAxisAlignment.start,
                      //     children: [
                      //       // Optional Title for this section
                      //       // Text( 
                      //       //   "Discover Key Features:",
                      //       //   style: AppTextStyles.titleLarge.copyWith(color: AppColors.textWhite),
                      //       // ),
                      //       // const SizedBox(height: 12),
                            ...featureHighlightsList!,
                      //     ],
                      //   ),
                      // ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16), // Space before buttons
              PrimaryButton(
                text: nextButtonText,
                onPressed: onNext,
                isLoading: false, // Assuming not loading by default
              ),
              if (onSkip != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onSkip,
                  child: Text(
                    'Skip',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                  ),
                ),
              ],
              const SizedBox(height: 16), 
            ],
          ),
        ),
      ),
    );
  }
}
