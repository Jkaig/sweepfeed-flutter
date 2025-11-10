import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../services/subscription_service.dart';

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
  final bool _isProcessing = false;

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

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: const Text('Upgrade Your Plan'),
        backgroundColor: AppColors.primaryMedium,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: isProcessing
                ? null
                : () {
                    ref
                        .read(subscriptionServiceProvider.notifier)
                        .restorePurchases();
                  },
            child: const Text(
              'Restore',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildBillingToggle(),
              const SizedBox(height: 24),
              _buildTierCards(),
            ]
                .animate(interval: 100.ms)
                .fadeIn(duration: 300.ms, curve: Curves.easeOut),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHeader() => Column(
        children: [
          const Icon(Icons.stars, color: AppColors.accent, size: 48),
          const SizedBox(height: 16),
          Text(
            'Unlock Your Winning Potential',
            style: AppTextStyles.headlineMedium
                .copyWith(color: AppColors.textWhite),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a plan to get more entries, better filters, and an ad-free experience.',
            style:
                AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
            textAlign: TextAlign.center,
          ),
        ],
      );

  Widget _buildBillingToggle() => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.primaryMedium,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildToggleOption('Monthly', !_isAnnual),
            _buildToggleOption('Annual', _isAnnual, 'Save 20%'),
          ],
        ),
      );

  Widget _buildToggleOption(String text, bool isSelected, [String? badge]) =>
      GestureDetector(
        onTap: () => setState(() => _isAnnual = text == 'Annual'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Row(
            children: [
              Text(
                text,
                style: TextStyle(
                  color:
                      isSelected ? AppColors.primaryDark : AppColors.textWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
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
            price: '_0/mo',
            description: 'The standard experience to get you started.',
            features: [
              'Enter Sweepstakes',
              'Basic Filtering',
              'Earn Points & Badges',
              'Ad-Supported',
            ],
            isRecommended: false,
          ),
          const SizedBox(height: 16),
          _buildTierCard(
            index: 1,
            title: 'Plus',
            price: _isAnnual ? '_3.99/mo' : '_4.99/mo',
            description: 'For the engaged user who wants more.',
            features: [
              'Ad-Free Experience',
              'Unlimited Entries & Saves',
              'Advanced Filtering',
              'Streak Protection',
              'Plus Member Profile Badge',
            ],
            isRecommended: false,
          ),
          const SizedBox(height: 16),
          _buildTierCard(
            index: 2,
            title: 'Pro',
            price: _isAnnual ? '_7.99/mo' : '_9.99/mo',
            description: 'For the power user who wants it all.',
            features: [
              'Everything in Plus',
              'Exclusive Sweepstakes',
              'Entry Assistant',
              'Personalized Analytics',
              'Advanced Notifications',
              'Pro Member Profile Badge',
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
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primaryMedium,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.accent : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isRecommended)
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Text(
                    'Best Value',
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            Text(
              title,
              style: AppTextStyles.headlineSmall
                  .copyWith(color: AppColors.textWhite),
            ),
            const SizedBox(height: 8),
            Text(
              price,
              style:
                  AppTextStyles.titleLarge.copyWith(color: AppColors.textWhite),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style:
                  AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.primaryLight),
            const SizedBox(height: 16),
            ...features.map(_buildFeatureItem),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.accent, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textWhite),
              ),
            ),
          ],
        ),
      );

  Widget _buildBottomBar() {
    final titles = ['Continue with Free', 'Upgrade to Plus', 'Upgrade to Pro'];
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: const BoxDecoration(
        color: AppColors.primaryMedium,
        border: Border(
          top: BorderSide(color: AppColors.primaryLight),
        ),
      ),
      child: PrimaryButton(
        text: titles[_selectedTierIndex],
        onPressed: _handleSubscription,
        isLoading: _isProcessing,
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
            ? SubscriptionService.premiumAnnualProductId
            : SubscriptionService.premiumMonthlyProductId)
        : (_isAnnual
            ? SubscriptionService.basicAnnualProductId
            : SubscriptionService.basicMonthlyProductId);

    try {
      final plan = service.plans.firstWhere((p) => p.id == productId);
      await service.purchaseSubscription(plan);
      if (mounted && (await service.isSubscribedStream.first)) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
