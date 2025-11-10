import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../utils/onboarding_constants.dart';
import '../widgets/common_onboarding_widgets.dart';

class WelcomeValueScreen extends ConsumerStatefulWidget {
  const WelcomeValueScreen({
    required this.onNext,
    super.key,
    this.currentStep = 1,
  });
  final VoidCallback onNext;
  final int currentStep;

  @override
  ConsumerState<WelcomeValueScreen> createState() => _WelcomeValueScreenState();
}

class _WelcomeValueScreenState extends ConsumerState<WelcomeValueScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _orbitController;

  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _orbitController.dispose();
    super.dispose();
  }

  Future<void> _handleNext() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('hasSeenWelcomeScreen', true);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) => OnboardingScaffold(
        semanticLabel: OnboardingConstants.semanticWelcomeScreen,
        currentStep: widget.currentStep,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primaryMedium],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    (OnboardingConstants.screenPadding * 2) -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom -
                    60,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 320,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Center(
                          child: const AnimatedLottieOrFallback(
                            assetPath:
                                OnboardingConstants.lottieWelcomeAnimation,
                            fallbackIcon: Icons.card_giftcard,
                            fallbackColor: AppColors.brandCyan,
                          )
                              .animate()
                              .fadeIn(
                                  duration: OnboardingConstants.fadeInDuration)
                              .scale(
                                duration: Duration(milliseconds: 800),
                                curve: Curves.elasticOut,
                              )
                              .shimmer(
                                delay: Duration(milliseconds: 400),
                                duration: Duration(milliseconds: 1500),
                                color:
                                    AppColors.brandCyan.withValues(alpha: 0.3),
                              ),
                        ),
                        AnimatedBuilder(
                          animation: _orbitController,
                          builder: (context, child) => Stack(
                            alignment: Alignment.center,
                            children: [
                              _buildOrbitingPill(
                                angle: _orbitController.value * 2 * math.pi,
                                icon: Icons.emoji_events,
                                label: 'Win Prizes',
                                color: AppColors.brandCyan,
                                delay: 0,
                              ),
                              _buildOrbitingPill(
                                angle: (_orbitController.value * 2 * math.pi) +
                                    (2 * math.pi / 3),
                                icon: Icons.favorite,
                                label: 'Help Charity',
                                color: Colors.pinkAccent,
                                delay: 1,
                              ),
                              _buildOrbitingPill(
                                angle: (_orbitController.value * 2 * math.pi) +
                                    (4 * math.pi / 3),
                                icon: Icons.people,
                                label: 'Have Fun',
                                color: Colors.deepPurple,
                                delay: 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Semantics(
                    header: true,
                    child: Text(
                      'Welcome to SweepFeed!',
                      style: AppTextStyles.displaySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    )
                        .animate()
                        .fadeIn(delay: OnboardingConstants.fadeInDelayShort)
                        .slideY(
                          begin: -0.3,
                          end: 0,
                          duration: Duration(milliseconds: 600),
                          curve: Curves.easeOutBack,
                        ),
                  ),
                  const SizedBox(
                      height: OnboardingConstants.verticalSpacingMedium),
                  Text(
                    'Win amazing prizes, support great causes, and connect with friends!',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.textLight,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: OnboardingConstants.fadeInDelayMedium)
                      .slideY(
                        begin: 0.2,
                        end: 0,
                        duration: Duration(milliseconds: 500),
                      ),
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: OnboardingContinueButton(
                      onPressed: _handleNext,
                      label: "Let's Get Started",
                    )
                        .animate()
                        .fadeIn(delay: OnboardingConstants.fadeInDelayXLong)
                        .slideY(
                          begin: 0.5,
                          end: 0,
                          duration: Duration(milliseconds: 600),
                          curve: Curves.easeOut,
                        )
                        .shimmer(
                          delay: Duration(milliseconds: 1200),
                          duration: Duration(milliseconds: 800),
                        ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _buildOrbitingPill({
    required double angle,
    required IconData icon,
    required String label,
    required Color color,
    required int delay,
  }) {
    final radius = 140.0;
    final x = radius * math.cos(angle);
    final y = radius * math.sin(angle);

    return Transform.translate(
      offset: Offset(x, y),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      )
          .animate(
            onPlay: (controller) => controller.forward(from: delay * 0.15),
          )
          .fadeIn(duration: 600.ms)
          .scale(begin: Offset(0.5, 0.5), end: Offset(1, 1)),
    );
  }
}
