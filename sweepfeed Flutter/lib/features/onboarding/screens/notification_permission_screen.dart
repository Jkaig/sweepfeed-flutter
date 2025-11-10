import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../utils/onboarding_constants.dart';
import '../widgets/common_onboarding_widgets.dart';

class NotificationPermissionScreen extends StatelessWidget {
  const NotificationPermissionScreen({
    required this.onNext,
    required this.onSkip,
    super.key,
    this.currentStep = 6,
  });
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final int currentStep;

  @override
  Widget build(BuildContext context) => OnboardingScaffold(
        semanticLabel: OnboardingConstants.semanticNotificationScreen,
        currentStep: currentStep,
        skipButton: OnboardingSkipButton(onPressed: onSkip),
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
              const Icon(
                Icons.notifications_active,
                size: OnboardingConstants.iconSize,
                color: AppColors.brandCyan,
              )
                  .animate()
                  .scale(duration: OnboardingConstants.scaleAnimationDuration)
                  .then()
                  .shake(),
              const SizedBox(height: OnboardingConstants.verticalSpacingLarge),
              Semantics(
                header: true,
                child: Text(
                  'Never Miss a Win!',
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
                'Get notified about new sweepstakes, expiring entries, and big wins!',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textLight,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: OnboardingConstants.fadeInDelayMedium),
              const SizedBox(
                  height: OnboardingConstants.verticalSpacingXXLarge),
              Semantics(
                label:
                    'Example notifications: New sweepstakes alerts, Entry reminders, Win announcements',
                child: Column(
                  children: [
                    _buildNotificationExample(
                      icon: Icons.emoji_events,
                      iconColor: Colors.amber,
                      title: 'New Prize Alert',
                      message: '\$10,000 Dream Vacation just posted!',
                      time: '2m ago',
                    )
                        .animate()
                        .fadeIn(delay: OnboardingConstants.fadeInDelayMedium)
                        .slideX(),
                    const SizedBox(
                      height: OnboardingConstants.verticalSpacingMedium,
                    ),
                    _buildNotificationExample(
                      icon: Icons.timer,
                      iconColor: Colors.orange,
                      title: 'Reminder',
                      message: 'Daily streak expires in 2 hours!',
                      time: '1h ago',
                    )
                        .animate()
                        .fadeIn(delay: OnboardingConstants.fadeInDelayLong)
                        .slideX(),
                    const SizedBox(
                      height: OnboardingConstants.verticalSpacingMedium,
                    ),
                    _buildNotificationExample(
                      icon: Icons.celebration,
                      iconColor: Colors.green,
                      title: 'You Won!',
                      message: 'Congrats! You won the \$50 Gift Card!',
                      time: '5m ago',
                    )
                        .animate()
                        .fadeIn(delay: OnboardingConstants.fadeInDelayXLong)
                        .slideX(),
                  ],
                ),
              ),
              const SizedBox(
                  height: OnboardingConstants.verticalSpacingXXLarge),
              Semantics(
                label:
                    'Privacy notice: You can change notification settings anytime',
                child: Container(
                  padding: const EdgeInsets.all(
                    OnboardingConstants.verticalSpacingMedium,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(
                      OnboardingConstants.buttonBorderRadius,
                    ),
                    border: Border.all(
                      color: AppColors.textMuted.withValues(alpha: 0.3),
                      width: OnboardingConstants.borderWidth,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        color: AppColors.textLight,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You can change notification preferences anytime in settings',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: const Duration(milliseconds: 1000)),
              ),
              const Spacer(),
              OnboardingContinueButton(
                onPressed: onNext,
                label: 'Enable Notifications',
              ).animate().fadeIn(delay: const Duration(milliseconds: 1200)),
              const SizedBox(height: OnboardingConstants.verticalSpacingMedium),
            ],
          ),
        ),
      );

  Widget _buildNotificationExample({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String time,
  }) =>
      Semantics(
        label: '$title notification. $message. Received $time',
        child: Container(
          padding:
              const EdgeInsets.all(OnboardingConstants.verticalSpacingMedium),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.5),
            borderRadius:
                BorderRadius.circular(OnboardingConstants.buttonBorderRadius),
            border: Border.all(
              color: iconColor.withValues(alpha: 0.3),
              width: OnboardingConstants.borderWidth,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: OnboardingConstants.verticalSpacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.titleSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          time,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: OnboardingConstants.verticalSpacingSmall,
                    ),
                    Text(
                      message,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
