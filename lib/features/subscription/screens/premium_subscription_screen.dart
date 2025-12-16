import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/animated_gradient_background.dart';
import '../../../core/widgets/custom_back_button.dart';
import '../../../core/widgets/glassmorphic_container.dart';
import '../../../core/widgets/primary_button.dart';
import '../../subscription/services/subscription_service.dart';

class PremiumSubscriptionScreen extends ConsumerStatefulWidget {
  const PremiumSubscriptionScreen({super.key});

  @override
  ConsumerState<PremiumSubscriptionScreen> createState() =>
      _PremiumSubscriptionScreenState();
}

class _PremiumSubscriptionScreenState
    extends ConsumerState<PremiumSubscriptionScreen> {
  int _selectedTierIndex = 2; // Default to Pro
  bool _isAnnual = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(subscriptionServiceProvider.notifier).loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionService = ref.watch(subscriptionServiceProvider);
    final isProcessing = subscriptionService.isPurchasePending;

    return Stack(
      children: [
        const Positioned.fill(child: AnimatedGradientBackground()),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: const CustomBackButton(),
            title: Text(
              'Upgrade Your Plan',
              style: AppTextStyles.titleLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              TextButton(
                onPressed: isProcessing
                    ? null
                    : () {
                        ref
                            .read(subscriptionServiceProvider.notifier)
                            .restorePurchases();
                      },
                child: Text(
                  'Restore',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildBillingToggle(),
                const SizedBox(height: 32),
                _buildTierCards(),
                const SizedBox(height: 100), // Spacing for bottom bar
              ]
                  .animate(interval: 100.ms)
                  .fadeIn(duration: 500.ms, curve: Curves.easeOut)
                  .slideY(begin: 0.2, end: 0),
            ),
          ),
          bottomSheet: _buildBottomBar(),
        ),
      ],
    );
  }

  Widget _buildHeader() => Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(Icons.stars_rounded,
                color: AppColors.accent, size: 48,),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.1, 1.1),
                  duration: 2000.ms,),
          const SizedBox(height: 24),
          Text(
            'Unlock Your Potential',
            style: AppTextStyles.headlineMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Get unlimited entries, advanced AI filtering, and an ad-free experience to maximize your winning changes.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );

  Widget _buildBillingToggle() => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.1), width: 1.5,),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildToggleOption('Monthly', !_isAnnual),
            _buildToggleOption('Annual', _isAnnual, 'SAVE 20%'),
          ],
        ),
      );

  Widget _buildToggleOption(String text, bool isSelected, [String? badge]) =>
      GestureDetector(
        onTap: () => setState(() => _isAnnual = text == 'Annual'),
        child: AnimatedContainer(
          duration: 300.ms,
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Text(
                text,
                style: TextStyle(
                  color: isSelected ? AppColors.primaryDark : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryDark.withValues(alpha: 0.2)
                        : AppColors.accent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.primaryDark
                          : AppColors.primaryDark,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );

  Widget _buildTierCards() => Column(
        children: [
          _buildTierCard(
            index: 0,
            title: 'Free',
            price: 'Free Forever',
            description: 'The essentials to get you started.',
            features: [
              'Daily entries allowance',
              'Basic contest filtering',
              'Community access',
              'Ad-supported',
            ],
            isRecommended: false,
          ),
          const SizedBox(height: 20),
          _buildTierCard(
            index: 2, // Prioritize Pro visually
            title: 'Pro',
            price: _isAnnual ? '\$7.99/mo' : '\$9.99/mo',
            description: 'Maximize your odds with AI tools.',
            features: [
              'Everything in Free',
              'Unlimited entries & saves',
              'AI Winning Prediction',
              'Advanced Auto-Fill',
              'Ad-free experience',
              'Priority Support',
            ],
            isRecommended: true,
          ),
        ],
      );

  Widget _buildTierCard({
    required int index,
    required String title,
    required String price,
    required String description,
    required List<String> features,
    required bool isRecommended,
  }) {
    final isSelected = _selectedTierIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTierIndex = index),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GlassmorphicContainer(
            borderRadius: 24,
            border: isSelected ? 2.0 : 1.0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: isSelected
                  ? BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.05),
                    )
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title.toUpperCase(),
                            style: AppTextStyles.labelMedium.copyWith(
                              color: isSelected
                                  ? AppColors.accent
                                  : Colors.white.withValues(alpha: 0.6),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            price,
                            style: AppTextStyles.headlineSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.accent,
                          size: 32,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...features.map(_buildFeatureItem),
                ],
              ),
            ),
          ),
          if (isRecommended)
            Positioned(
              top: -12,
              right: 24,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accent, Color(0xFF4DE2C1)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars, color: AppColors.primaryDark, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'MOST POPULAR',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              )
                  .animate(
                      onPlay: (controller) => controller.repeat(reverse: true),)
                  .shimmer(duration: 2000.ms, delay: 1000.ms),
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check, color: AppColors.accent, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style:
                    AppTextStyles.bodyMedium.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      );

  Widget _buildBottomBar() {
    final titles = ['Continue with Free', 'Upgrade to Plus', 'Start Pro Trial'];
    final subscriptionService = ref.watch(subscriptionServiceProvider);
    final isProcessing = subscriptionService.isPurchasePending;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      decoration: const BoxDecoration(
        color: Colors.transparent, // Let gradient show through (or blur)
      ),
      child: GlassmorphicContainer(
        border: 1.0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: PrimaryButton(
            text: titles[_selectedTierIndex],
            onPressed: isProcessing ? null : _handleSubscription, // Null disables
            isLoading: isProcessing,
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubscription() async {
    if (_selectedTierIndex == 0) {
      Navigator.of(context).pop();
      return;
    }

    final service = ref.read(subscriptionServiceProvider.notifier);
    final isPro = _selectedTierIndex == 2;

    final productId = isPro
        ? (_isAnnual
            ? SubscriptionService.premiumAnnualId
            : SubscriptionService.premiumMonthlyId)
        : (_isAnnual
            ? SubscriptionService.basicAnnualId
            : SubscriptionService.basicMonthlyId);

    try {
      final plan = service.plans.firstWhere(
        (p) => p.id == productId,
        orElse: () => throw Exception('Product not found: $productId'),
      );
      final success = await service.purchaseSubscription(plan);
      if (mounted && success && service.isSubscribed) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
