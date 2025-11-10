import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../models/subscription_tiers.dart';
import '../services/subscription_service.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  SubscriptionTier _selectedTier = SubscriptionTier.basic;
  bool _isAnnual = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final subscriptionService =
          ref.read(subscriptionServiceProvider.notifier);
      if (!subscriptionService.productsLoaded) {
        subscriptionService.loadProducts();
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Choose Your Plan'),
          actions: [
            TextButton(
              onPressed: () {
                ref
                    .read(subscriptionServiceProvider.notifier)
                    .restorePurchases();
              },
              child:
                  const Text('Restore', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        body: Consumer(
          builder: (context, ref, _) {
            final subscriptionService = ref.watch(subscriptionServiceProvider);
            if (subscriptionService.isLoading) {
              return const Center(child: LoadingIndicator());
            }

            if (subscriptionService.isSubscribed &&
                !subscriptionService.isInTrialPeriod) {
              return _buildActiveSubscriptionView(subscriptionService);
            }

            if (subscriptionService.error.isNotEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 60,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Error loading subscription plans',
                        style: AppTextStyles.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subscriptionService.error,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => ref
                            .read(subscriptionServiceProvider.notifier)
                            .loadProducts(),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return _buildSubscriptionPlansView(subscriptionService);
          },
        ),
      );

  Widget _buildActiveSubscriptionView(SubscriptionService service) {
    final plan = service.currentSubscriptionPlan;
    final tier = service.currentTier.name;
    final expiryDate = service.subscriptionExpiryDate;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "You're a $tier Member!",
                    style:
                        AppTextStyles.titleLarge.copyWith(color: Colors.green),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your subscription: ${plan ?? tier}',
                    style: AppTextStyles.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  if (expiryDate != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Valid until: ${_formatDate(expiryDate)}',
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Enjoy access to all your subscription benefits!',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionPlansView(SubscriptionService service) {
    // Trial banner if user is in trial
    final Widget? trialBanner = service.isInTrialPeriod
        ? Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "You're in your Basic trial period",
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Trial ends: ${service.trialTimeRemaining}',
                  style: TextStyle(color: Colors.green.shade700),
                ),
              ],
            ),
          )
        : null;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Choose Your Subscription Plan',
              style: AppTextStyles.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Unlock premium features and remove ads',
              style: AppTextStyles.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Show trial banner if applicable
            if (trialBanner != null) trialBanner,

            // Billing toggle
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Billing'),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment<bool>(
                          value: false,
                          label: Text('Monthly'),
                        ),
                        ButtonSegment<bool>(
                          value: true,
                          label: Text('Annual'),
                        ),
                      ],
                      selected: {_isAnnual},
                      onSelectionChanged: (selected) {
                        setState(() {
                          _isAnnual = selected.first;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Subscription tier cards
            _buildTierCard(
              context,
              SubscriptionTier.free,
              service,
              isSelected: _selectedTier == SubscriptionTier.free,
            ),
            _buildTierCard(
              context,
              SubscriptionTier.basic,
              service,
              isSelected: _selectedTier == SubscriptionTier.basic,
            ),
            _buildTierCard(
              context,
              SubscriptionTier.premium,
              service,
              isSelected: _selectedTier == SubscriptionTier.premium,
            ),
            const SizedBox(height: 16),

            // Subscribe button (disabled for free tier)
            ElevatedButton(
              onPressed: _selectedTier == SubscriptionTier.free || _isProcessing
                  ? null
                  : () => _subscribe(
                        context,
                        ref.read(subscriptionServiceProvider.notifier),
                      ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedTier.color,
                disabledBackgroundColor: Colors.grey.shade300,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _selectedTier == SubscriptionTier.free
                          ? 'Free Plan Selected'
                          : 'Subscribe to ${_selectedTier.name}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),

            // Free trial button (only for free users selecting basic tier)
            if (!service.isInTrialPeriod &&
                !service.trialStarted &&
                _selectedTier == SubscriptionTier.basic)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: OutlinedButton(
                  onPressed: _isProcessing
                      ? null
                      : () => _startFreeTrial(
                            context,
                            ref.read(subscriptionServiceProvider.notifier),
                          ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Start 3-Day Free Trial'),
                ),
              ),

            const SizedBox(height: 24),
            const Text(
              'Subscriptions will automatically renew unless canceled before the renewal date. '
              'You can manage your subscriptions in your App Store account settings.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierCard(
    BuildContext context,
    SubscriptionTier tier,
    SubscriptionService service, {
    required bool isSelected,
  }) {
    final tierFeatures = tier.features;
    final currentTier = service.currentTier;

    // Determine price based on billing cycle
    final price = _isAnnual ? tier.annualPrice : tier.price;

    // Check if this is the user's current tier
    final isCurrentTier = currentTier == tier &&
        (service.isSubscribed || service.isInTrialPeriod);

    // Show savings badge for annual billing on paid tiers
    final showSavingsBadge = _isAnnual && tier != SubscriptionTier.free;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTier = tier;
        });
      },
      child: Card(
        elevation: isSelected ? 4 : 1,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? tier.color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Tier name and price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tier.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: tier.color,
                        ),
                      ),
                      if (tier != SubscriptionTier.free)
                        Row(
                          children: [
                            Text(
                              '\$${price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (showSavingsBadge) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Save 16%',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                    ],
                  ),

                  // Selection indicator
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: tier.color,
                      size: 24,
                    ),

                  // Current plan indicator
                  if (isCurrentTier && !isSelected)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.green),
                      ),
                      child: const Text(
                        'Current Plan',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                tier.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),

              // Features list
              ...tierFeatures.take(4).map(
                    (feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check,
                            color: Colors.green,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              feature,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _subscribe(
    BuildContext context,
    SubscriptionService service,
  ) async {
    if (_selectedTier == SubscriptionTier.free) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Find the appropriate subscription plan based on tier and billing cycle
      final isPremium = _selectedTier == SubscriptionTier.premium;
      final productId = isPremium
          ? (_isAnnual
              ? SubscriptionService.premiumAnnualProductId
              : SubscriptionService.premiumMonthlyProductId)
          : (_isAnnual
              ? SubscriptionService.basicAnnualProductId
              : SubscriptionService.basicMonthlyProductId);

      final plan = service.plans.firstWhere(
        (plan) => plan.id == productId,
        orElse: () => service.plans.firstWhere(
          (plan) =>
              plan.id.contains(isPremium ? 'premium' : 'basic') &&
              plan.id.contains(_isAnnual ? 'annual' : 'monthly'),
          orElse: () => throw Exception('Subscription plan not found'),
        ),
      );

      await service.purchaseSubscription(plan);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _startFreeTrial(
    BuildContext context,
    SubscriptionService service,
  ) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final success = await service.startFreeTrial();

      if (success && mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Free trial started successfully!')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start free trial')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}
