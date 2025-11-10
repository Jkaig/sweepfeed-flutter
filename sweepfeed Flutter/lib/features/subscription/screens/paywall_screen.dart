import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'subscription_screen.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({
    required this.feature,
    super.key,
    this.description,
    this.icon,
  });
  final String feature;
  final String? description;
  final Widget? icon;

  static Future<bool> show(
    BuildContext context, {
    required String feature,
    String? description,
    Widget? icon,
  }) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => PaywallScreen(
          feature: feature,
          description: description,
          icon: icon,
        ),
        fullscreenDialog: true,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(
          title: const Text('Premium Feature'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Icon at the top
                  icon ??
                      const Icon(
                        Icons.workspace_premium,
                        size: 80,
                        color: AppColors.primary,
                      ),
                  const SizedBox(height: 24),

                  // Feature title
                  Text(
                    'Unlock $feature',
                    style: AppTextStyles.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Feature description
                  Text(
                    description ??
                        'This is a premium feature available exclusively to our subscribers.',
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Feature comparison table
                  const _FeatureComparisonTable(),
                  const SizedBox(height: 32),

                  // Subscription button
                  ElevatedButton(
                    onPressed: () => _navigateToSubscription(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Subscribe Now',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Start free trial button
                  OutlinedButton(
                    onPressed: () => _startFreeTrial(context, ref),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Start 3-Day Free Trial',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Limited trial button
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text(
                      'Continue with Limited Access',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Future<void> _navigateToSubscription(
      BuildContext context, WidgetRef ref) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const SubscriptionScreen(),
        fullscreenDialog: true,
      ),
    );

    if (result == true || ref.read(subscriptionServiceProvider).isSubscribed) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _startFreeTrial(BuildContext context, WidgetRef ref) async {
    final subscriptionService = ref.read(subscriptionServiceProvider.notifier);

    final success = await subscriptionService.startFreeTrial();

    if (success) {
      if (context.mounted) {
        Navigator.of(context).pop(true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Your 3-day free trial has started!'),
            action: SnackBarAction(
              label: 'See Plans',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionScreen(),
                  ),
                );
              },
            ),
          ),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not start free trial. Please try again.'),
          ),
        );
      }
    }
  }
}

class _FeatureComparisonTable extends StatelessWidget {
  const _FeatureComparisonTable();

  @override
  Widget build(BuildContext context) => Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Compare Plans',
                style: AppTextStyles.titleMedium,
              ),
              const SizedBox(height: 16),

              // Table header
              Row(
                children: [
                  const SizedBox(width: 120),
                  _buildTableHeader('Free', Colors.grey),
                  _buildTableHeader('Basic', Colors.blue),
                  _buildTableHeader('Premium', Colors.purple),
                ],
              ),

              const Divider(height: 32),

              // Feature rows
              _buildFeatureRow('Daily sweepstakes', '15', '100', 'Unlimited'),
              _buildFeatureRow('Saved sweepstakes', '5', '50', 'Unlimited'),
              _buildFeatureRow('Ad-free', 'No', 'Yes', 'Yes'),
              _buildFeatureRow('Basic filtering', 'Yes', 'Yes', 'Yes'),
              _buildFeatureRow('Advanced filters', 'No', 'Yes', 'Yes'),
              _buildFeatureRow('High-value contests', 'No', 'Yes', 'Yes'),
              _buildFeatureRow('Early notifications', 'No', 'No', 'Yes'),
              _buildFeatureRow('Premium contests', 'No', 'No', 'Yes'),

              const Divider(height: 32),

              // Price row
              Row(
                children: [
                  const SizedBox(
                    width: 120,
                    child: Text(
                      'Monthly price',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  _buildTableCell('Free', isPrimary: true),
                  _buildTableCell(_getBasicPrice(ref), isPrimary: true),
                  _buildTableCell(_getPremiumPrice(ref), isPrimary: true),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildTableHeader(String text, Color color) => Expanded(
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
        ),
      );

  Widget _buildFeatureRow(
    String feature,
    String free,
    String basic,
    String premium,
  ) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              child: Text(feature),
            ),
            _buildTableCell(free),
            _buildTableCell(basic),
            _buildTableCell(premium),
          ],
        ),
      );

  Widget _buildTableCell(String text, {bool isPrimary = false}) => Expanded(
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      );

  /// Get dynamic basic plan price from subscription service
  String _getBasicPrice(WidgetRef ref) {
    final subscriptionService = ref.watch(subscriptionServiceProvider);
    final plans = subscriptionService.plans;

    // Look for basic monthly plan first, then any basic plan
    final basicPlan = plans.firstWhere(
      (plan) => plan.id.contains('basic') && plan.id.contains('monthly'),
      orElse: () => plans.firstWhere(
        (plan) => plan.id.contains('basic'),
        orElse: () => plans.isNotEmpty ? plans.first : null,
      ),
    );

    return basicPlan?.price ?? '\$4.99'; // Fallback if no plans loaded
  }

  /// Get dynamic premium plan price from subscription service
  String _getPremiumPrice(WidgetRef ref) {
    final subscriptionService = ref.watch(subscriptionServiceProvider);
    final plans = subscriptionService.plans;

    // Look for premium monthly plan first, then any premium plan
    final premiumPlan = plans.firstWhere(
      (plan) => plan.id.contains('premium') && plan.id.contains('monthly'),
      orElse: () => plans.firstWhere(
        (plan) => plan.id.contains('premium'),
        orElse: () => plans.length > 1 ? plans[1] : null,
      ),
    );

    return premiumPlan?.price ?? '\$9.99'; // Fallback if no plans loaded
  }
}
