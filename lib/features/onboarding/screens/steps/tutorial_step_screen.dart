import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/dustbunny_icon.dart';
import '../../widgets/onboarding_button.dart';
import '../../widgets/onboarding_template.dart';

/// Interactive tutorial step showing how to use SweepFeed
class TutorialStepScreen extends StatefulWidget {
  const TutorialStepScreen({
    required this.onNext,
    this.onSkip,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback? onSkip;

  @override
  State<TutorialStepScreen> createState() => _TutorialStepScreenState();
}

class _TutorialStepScreenState extends State<TutorialStepScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Tutorial steps data
  final List<_TutorialStep> _steps = [
    const _TutorialStep(
      title: 'Browse Contests',
      description: 'Scroll through hundreds of free contests from top brands',
      icon: Icons.explore_outlined,
      highlightArea: _HighlightArea.card,
    ),
    const _TutorialStep(
      title: 'Tap to Enter',
      description: 'Just tap "Enter Now" - we\'ll take you directly to the entry page',
      icon: Icons.touch_app_outlined,
      highlightArea: _HighlightArea.enterButton,
    ),
    const _TutorialStep(
      title: 'Save Favorites',
      description: 'Bookmark contests to enter later - never miss a deadline',
      icon: Icons.bookmark_add_outlined,
      highlightArea: _HighlightArea.saveButton,
    ),
    const _TutorialStep(
      title: 'Earn Dust Bunnies',
      description: 'Complete daily tasks to earn Dust Bunnies for extra rewards and chances to win',
      icon: Icons.pets_outlined, // Placeholder, actual dust bunny shown via image
      highlightArea: _HighlightArea.points,
      useDustBunnyIcon: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) => OnboardingTemplate(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              children: [
                Text(
                  'Quick Tutorial',
                  style: AppTextStyles.displaySmall.copyWith(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Learn how to win in 4 easy steps',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Page indicator dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _steps.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: _currentPage == index ? 24 : 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? AppColors.brandCyan
                      : AppColors.textLight.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Tutorial content
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (page) => setState(() => _currentPage = page),
              itemCount: _steps.length,
              itemBuilder: (context, index) => SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildTutorialPage(_steps[index]),
                ),
            ),
          ),

          // Bottom buttons
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                OnboardingButton(
                  text: _currentPage == _steps.length - 1
                      ? 'Start Winning!'
                      : 'Next',
                  onPressed: _nextPage,
                ),
                if (widget.onSkip != null) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: widget.onSkip,
                    child: Text(
                      'Skip tutorial',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

  Widget _buildTutorialPage(_TutorialStep step) => Column(
      children: [
        // Step icon with pulse animation
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) => Transform.scale(
              scale: _pulseAnimation.value,
              child: step.useDustBunnyIcon
                  ? Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.brandCyan.withValues(alpha: 0.2),
                        border: Border.all(
                          color: AppColors.brandCyan,
                          width: 2,
                        ),
                      ),
                      child: Image.asset(
                        'assets/images/dustbunnies/dustbunny_happy.png',
                        width: 64,
                        height: 64,
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.brandCyan.withValues(alpha: 0.2),
                        border: Border.all(
                          color: AppColors.brandCyan,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        step.icon,
                        size: 40,
                        color: AppColors.brandCyan,
                      ),
                    ),
            ),
        ),

        const SizedBox(height: 20),

        // Step title
        Text(
          step.title,
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.textWhite,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        // Step description
        Text(
          step.description,
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textLight,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 24),

        // Mock contests card with highlighted area
        _buildMockSweepstakesCard(step.highlightArea),
      ],
    );

  Widget _buildMockSweepstakesCard(_HighlightArea highlightArea) => Container(
      decoration: BoxDecoration(
        color: AppColors.primaryMedium,
        borderRadius: BorderRadius.circular(12),
        border: highlightArea == _HighlightArea.card
            ? Border.all(color: AppColors.brandCyan, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row with logo and prize
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Brand logo placeholder
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'N',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '\$10,000',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Nintendo',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Save button with highlight
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    final isHighlighted =
                        highlightArea == _HighlightArea.saveButton;
                    return Transform.scale(
                      scale: isHighlighted ? _pulseAnimation.value : 1.0,
                      child: Container(
                        decoration: isHighlighted
                            ? BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.brandCyan,
                                  width: 2,
                                ),
                              )
                            : null,
                        child: IconButton(
                          icon: Icon(
                            Icons.bookmark_border,
                            color: isHighlighted
                                ? AppColors.brandCyan
                                : AppColors.textWhite,
                          ),
                          onPressed: () {},
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Title and description
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Win a Nintendo Switch Bundle + Games!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Enter for your chance to win the ultimate gaming setup',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),

                // Metadata and enter button row
                Row(
                  children: [
                    // Points indicator with highlight - shows cute dust bunny!
                    if (highlightArea == _HighlightArea.points)
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) => Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.brandCyan.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.brandCyan,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  DustBunnyIcon(size: 18),
                                  SizedBox(width: 4),
                                  Text(
                                    '+5 DB',
                                    style: TextStyle(
                                      color: AppColors.brandCyan,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      )
                    else ...[
                      _buildMetadataItem('Daily', Icons.repeat),
                      const SizedBox(width: 12),
                      _buildMetadataItem('Ends in 5 days', Icons.calendar_today),
                    ],
                    const Spacer(),

                    // Enter button with highlight
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        final isHighlighted =
                            highlightArea == _HighlightArea.enterButton;
                        return Transform.scale(
                          scale: isHighlighted ? _pulseAnimation.value : 1.0,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isHighlighted
                                  ? Colors.white
                                  : AppColors.brandCyan,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: isHighlighted ? 4 : 0,
                            ),
                            child: const Text(
                              'Enter Now',
                              style: TextStyle(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

  Widget _buildMetadataItem(String text, IconData icon) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: AppColors.textLight,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 12,
            ),
          ),
        ],
      );
}

/// Tutorial step data model
class _TutorialStep {
  const _TutorialStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.highlightArea,
    this.useDustBunnyIcon = false,
  });

  final String title;
  final String description;
  final IconData icon;
  final _HighlightArea highlightArea;
  final bool useDustBunnyIcon;
}

/// Areas that can be highlighted on the mock card
enum _HighlightArea {
  card,
  enterButton,
  saveButton,
  points,
}
