import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../navigation/screens/main_navigation_wrapper.dart';

class ImprovedOnboardingFlow extends ConsumerStatefulWidget {
  const ImprovedOnboardingFlow({super.key});

  @override
  ConsumerState<ImprovedOnboardingFlow> createState() =>
      _ImprovedOnboardingFlowState();
}

class _ImprovedOnboardingFlowState
    extends ConsumerState<ImprovedOnboardingFlow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _onSkip() {
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    final userId = ref.read(firebaseServiceProvider).currentUser?.uid;
    if (userId != null) {
      await ref
          .read(firebaseServiceProvider)
          .firestore
          .collection('users')
          .doc(userId)
          .update({'onboardingCompleted': true});

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const MainNavigationWrapper(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.primaryDark,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: _onSkip,
                      child: Text(
                        'Skip',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textWhite,
                        ),
                      ),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index == _currentPage
                                ? AppColors.accent
                                : AppColors.primaryLight,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (page) {
                    setState(() => _currentPage = page);
                  },
                  children: [
                    _buildWelcomeScreen(),
                    _buildHowItWorksScreen(),
                    _buildCharityScreen(),
                    _buildPointsScreen(),
                    _buildStartScreen(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _onNextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.primaryDark,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _currentPage == 4 ? 'Start Winning!' : 'Next',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildWelcomeScreen() => Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.emoji_events,
              size: 120,
              color: AppColors.accent,
            ),
            const SizedBox(height: 32),
            Text(
              'Win Real Prizes,\nCompletely Free!',
              style: AppTextStyles.displaySmall.copyWith(
                color: AppColors.textWhite,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              'Enter daily contests for a chance to win amazing prizes – gift cards, electronics, cash, and more!',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textLight,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryMedium,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildFeaturePill('100% Free', Icons.check_circle),
                  _buildFeaturePill('Daily Prizes', Icons.calendar_today),
                  _buildFeaturePill('Easy Entry', Icons.touch_app),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildFeaturePill(String text, IconData icon) => Column(
        children: [
          Icon(icon, color: AppColors.accent, size: 32),
          const SizedBox(height: 8),
          Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );

  Widget _buildHowItWorksScreen() => Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.swipe_right,
              size: 100,
              color: AppColors.electricBlue,
            ),
            const SizedBox(height: 32),
            Text(
              'Simple to Enter,\nFun to Win',
              style: AppTextStyles.displaySmall.copyWith(
                color: AppColors.textWhite,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildStep(1, 'Browse contests', 'Find prizes you love'),
            const SizedBox(height: 16),
            _buildStep(2, 'Tap to enter', "One tap, you're entered!"),
            const SizedBox(height: 16),
            _buildStep(3, 'Win & celebrate', 'We notify winners instantly'),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryMedium,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.refresh,
                      color: AppColors.electricBlue, size: 24,),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'New contests added daily!',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildStep(int number, String title, String description) => Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.electricBlue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: AppTextStyles.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textWhite,
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildCharityScreen() => Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
            Text(
              'Enter to Win &\nSupport Charity',
              style: AppTextStyles.displaySmall.copyWith(
                color: AppColors.textWhite,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              'Every contest entry supports verified charities through Every.org',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textLight,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
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
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        Color(0xFFFF6B6B), // Red
                        Color(0xFFFF8E53), // Orange
                        Color(0xFFFFD93D), // Yellow
                        Color(0xFF6BCB77), // Green
                        Color(0xFF4D96FF), // Blue
                        Color(0xFF9B59B6), // Purple
                      ],
                    ).createShader(bounds),
                    child: Text(
                      'Your participation makes a real difference!',
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
          ],
        ),
      );

  Widget _buildPointsScreen() => Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Dust Bunny mascot image
            Image.asset(
              'assets/images/dustbunnies/dustbunny_excited.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.pets,
                size: 80,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Collect Dust Bunnies,\nGet Extra Chances!',
              style: AppTextStyles.displaySmall.copyWith(
                color: AppColors.textWhite,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              'Earn cute Dust Bunnies to unlock bonus entries and exclusive rewards',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textLight,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildEarnMethod(Icons.login, 'Daily login', '+10'),
            _buildEarnMethod(Icons.share, 'Share contests', '+10'),
            _buildEarnMethod(Icons.slideshow, 'Watch ads', '+50'),
            _buildEarnMethod(Icons.person, 'Complete profile', '+50'),
          ],
        ),
      );

  Widget _buildEarnMethod(IconData icon, String title, String amount) =>
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryMedium,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.accent, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textWhite,
                ),
              ),
            ),
            // Amount with small dust bunny icon
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  amount,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Image.asset(
                  'assets/images/dustbunnies/dustbunny_icon_24.png',
                  width: 20,
                  height: 20,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.pets,
                    size: 16,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildStartScreen() => Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.accent, AppColors.electricBlue],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.rocket_launch,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Ready to Win?',
              style: AppTextStyles.displaySmall.copyWith(
                color: AppColors.textWhite,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              "Let's get started!",
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryMedium,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildReadyFeature(
                    Icons.emoji_events,
                    'Browse hundreds of contests',
                  ),
                  const SizedBox(height: 12),
                  _buildReadyFeature(
                    Icons.favorite,
                    'Support verified charities',
                  ),
                  const SizedBox(height: 12),
                  _buildReadyFeature(Icons.pets, 'Collect Dust Bunnies'),
                  const SizedBox(height: 12),
                  _buildReadyFeature(Icons.celebration, 'Win amazing prizes!'),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildReadyFeature(IconData icon, String text) => Row(
        children: [
          Icon(icon, color: AppColors.accent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textLight,
              ),
            ),
          ),
        ],
      );
}
