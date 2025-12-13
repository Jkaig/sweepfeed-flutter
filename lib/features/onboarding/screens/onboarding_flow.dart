import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/animated_gradient_background.dart';
import '../../../core/widgets/primary_button.dart';
import '../../navigation/screens/main_screen.dart';
import 'charity_selection_screen.dart';
import 'interest_selection_screen.dart';

class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNextPage() {
    if (_pageController.page == 2) {
      // Last page (Welcome -> Interests -> Charity)
      _saveOnboarding();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  Future<void> _saveOnboarding() async {
    final userId = ref.read(firebaseAuthProvider).currentUser?.uid;
    final selectedInterests = ref.read(selectedInterestsProvider);
    final selectedCharities = ref.read(selectedCharitiesProvider);

    if (userId != null) {
      await ref
          .read(profileServiceProvider)
          .updateInterests(userId, selectedInterests);

      final charityIds = selectedCharities.map((c) => c.id).toList();
      await ref
          .read(profileServiceProvider)
          .updateCharities(userId, charityIds);

      await ref.read(userServiceProvider).markOnboardingComplete(userId);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(
          children: [
            PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // Disable swiping
              children: [
                _buildWelcomeScreen(),
                InterestSelectionScreen(
                  onNext: _onNextPage,
                ),
                CharitySelectionScreen(
                  onNext: _onNextPage,
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildWelcomeScreen() {
    return Stack(
      children: [
        const Positioned.fill(child: AnimatedGradientBackground()),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 100,
                    height: 100,
                    errorBuilder: (c, e, s) => const Icon(
                      Icons.emoji_events_rounded,
                      size: 80,
                      color: AppColors.accent,
                    ),
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .scale(
                        begin: const Offset(0.9, 0.9),
                        end: const Offset(1.1, 1.1),
                        duration: 3000.ms,),
                const SizedBox(height: 48),
                Text(
                  'Welcome to\nSweepFeed',
                  style: AppTextStyles.displayMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 16),
                Text(
                  'Your daily dose of winning. Enter best-in-class sweepstakes faster than ever.',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
                const Spacer(flex: 2),
                PrimaryButton(
                  text: "Let's Get Started",
                  onPressed: _onNextPage,
                ).animate().fadeIn(delay: 600.ms).shimmer(delay: 1500.ms),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

final selectedInterestsProvider =
    StateNotifierProvider<SelectedInterestsNotifier, List<String>>(
        (ref) => SelectedInterestsNotifier(),);

class SelectedInterestsNotifier extends StateNotifier<List<String>> {
  SelectedInterestsNotifier() : super([]);

  void toggle(String interest) {
    if (state.contains(interest)) {
      state = state.where((item) => item != interest).toList();
    } else {
      state = [...state, interest];
    }
  }
}
