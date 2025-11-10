import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/subscription/screens/paywall_screen.dart';
import '../providers/providers.dart';

/// A widget that wraps content that requires a subscription or has usage limits
/// It will show the appropriate UI based on the user's subscription status
class PremiumFeatureWrapper extends ConsumerWidget {
  const PremiumFeatureWrapper({
    required this.child,
    super.key,
    this.requiresSubscription = false,
    this.featureName = 'Premium Feature',
    this.featureDescription,
    this.featureIcon,
    this.checkViewLimit = false,
    this.checkSavedItemsLimit = false,
  });
  final Widget child;
  final bool requiresSubscription;
  final String featureName;
  final String? featureDescription;
  final Widget? featureIcon;
  final bool checkViewLimit;
  final bool checkSavedItemsLimit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionService = ref.watch(subscriptionServiceProvider);
    final usageLimitsService = ref.watch(usageLimitsServiceProvider);

    // Check if the user has an active subscription
    if (requiresSubscription && !subscriptionService.hasBasicOrPremiumAccess) {
      return _buildSubscriptionPrompt(context);
    }

    // Check if the user has reached their view limit
    if (checkViewLimit &&
        !subscriptionService.hasBasicOrPremiumAccess &&
        usageLimitsService.hasReachedViewLimit) {
      return _buildViewLimitReached(context, ref);
    }

    // Check if the user has reached their saved items limit
    if (checkSavedItemsLimit &&
        !subscriptionService.hasBasicOrPremiumAccess &&
        usageLimitsService.hasReachedSavedItemsLimit) {
      return _buildSavedItemsLimitReached(context, ref);
    }

    // If all checks pass, show the child
    return child;
  }

  Widget _buildSubscriptionPrompt(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              featureIcon ??
                  const Icon(
                    Icons.lock,
                    size: 64,
                    color: Colors.grey,
                  ),
              const SizedBox(height: 16),
              Text(
                featureName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                featureDescription ?? 'This feature requires a subscription.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _showPaywall(context),
                child: const Text('Upgrade to Access'),
              ),
            ],
          ),
        ),
      );

  Widget _buildViewLimitReached(BuildContext context, WidgetRef ref) {
    final usageLimitsService = ref.watch(usageLimitsServiceProvider);
    final limit = usageLimitsService.maxFreeTierViewsPerDay;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.visibility_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Daily Limit Reached',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "You've reached your daily limit of $limit sweepstakes views. "
              'Subscribe to get unlimited access!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _showPaywall(context),
              child: const Text('Upgrade to Premium'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedItemsLimitReached(BuildContext context, WidgetRef ref) {
    final usageLimitsService = ref.watch(usageLimitsServiceProvider);
    final limit = usageLimitsService.maxFreeTierSavedItems;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.bookmark_border,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Saved Items Limit Reached',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "You've reached your limit of $limit saved sweepstakes. "
              'Subscribe to save unlimited sweepstakes!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _showPaywall(context),
              child: const Text('Upgrade to Premium'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPaywall(BuildContext context) async {
    final result = await PaywallScreen.show(
      context,
      feature: featureName,
      description: featureDescription,
      icon: featureIcon,
    );

    // Return from the method if the paywall screen is dismissed
    if (!result) return;

    // If the user subscribed or started a trial, the child will be shown
    // because the subscription service will update its state
  }
}
