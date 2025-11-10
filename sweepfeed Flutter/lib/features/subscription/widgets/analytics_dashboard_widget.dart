import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/subscription_tiers.dart';
import '../services/subscription_analytics_service.dart';

class AnalyticsDashboardWidget extends ConsumerStatefulWidget {
  const AnalyticsDashboardWidget({super.key});

  @override
  ConsumerState<AnalyticsDashboardWidget> createState() =>
      _AnalyticsDashboardWidgetState();
}

class _AnalyticsDashboardWidgetState
    extends ConsumerState<AnalyticsDashboardWidget> {
  bool _isLoading = true;
  Map<String, int> _tierDistribution = {};
  Map<String, dynamic> _conversionMetrics = {};

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    final analyticsService = ref.read(subscriptionAnalyticsServiceProvider);

    final tierDist = await analyticsService.getTierDistribution();
    final convMetrics = await analyticsService.getConversionMetrics();

    setState(() {
      _tierDistribution = tierDist.cast<String, int>();
      _conversionMetrics = convMetrics;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Subscription Analytics',
            style: AppTextStyles.headlineMedium,
          ),
          const SizedBox(height: 24),
          _buildTierDistributionSection(),
          const SizedBox(height: 24),
          _buildConversionMetricsSection(),
          const SizedBox(height: 24),
          _buildRevenueProjectionSection(),
        ],
      ),
    );
  }

  Widget _buildTierDistributionSection() {
    final total = _tierDistribution.values.fold(0, (sum, count) => sum + count);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tier Distribution',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildTierDistributionBar(
              'Free',
              _tierDistribution['free'] ?? 0,
              total,
              SubscriptionTier.free.color,
            ),
            const SizedBox(height: 12),
            _buildTierDistributionBar(
              'Basic (${_getBasicPrice(ref)})',
              _tierDistribution['basic'] ?? 0,
              total,
              SubscriptionTier.basic.color,
            ),
            const SizedBox(height: 12),
            _buildTierDistributionBar(
              'Premium (${_getPremiumPrice(ref)})',
              _tierDistribution['premium'] ?? 0,
              total,
              SubscriptionTier.premium.color,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Users',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  total.toString(),
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierDistributionBar(
    String label,
    int count,
    int total,
    Color color,
  ) {
    final percentage = total > 0 ? (count / total) * 100 : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.bodyMedium),
            Text(
              '$count (${percentage.toStringAsFixed(1)}%)',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: total > 0 ? count / total : 0,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildConversionMetricsSection() {
    final promptsShown = _conversionMetrics['prompts_shown'] as int? ?? 0;
    final promptsClicked = _conversionMetrics['prompts_clicked'] as int? ?? 0;
    final purchases = _conversionMetrics['purchases'] as int? ?? 0;
    final clickThroughRate =
        _conversionMetrics['click_through_rate'] as double? ?? 0.0;
    final conversionRate =
        _conversionMetrics['conversion_rate'] as double? ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Conversion Metrics',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              'Upgrade Prompts Shown',
              promptsShown.toString(),
              Icons.visibility,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildMetricRow(
              'Prompts Clicked',
              promptsClicked.toString(),
              Icons.touch_app,
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildMetricRow(
              'Successful Purchases',
              purchases.toString(),
              Icons.shopping_cart,
              Colors.green,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPercentageCard(
                    'Click-Through Rate',
                    clickThroughRate,
                    Icons.ads_click,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPercentageCard(
                    'Conversion Rate',
                    conversionRate,
                    Icons.trending_up,
                    Colors.teal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: AppTextStyles.bodyMedium),
        ),
        Text(
          value,
          style: AppTextStyles.titleSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPercentageCard(
    String label,
    double percentage,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueProjectionSection() {
    final basicCount = _tierDistribution['basic'] ?? 0;
    final premiumCount = _tierDistribution['premium'] ?? 0;

    final monthlyRevenue = (basicCount * SubscriptionTier.basic.price) +
        (premiumCount * SubscriptionTier.premium.price);

    final annualRevenue = monthlyRevenue * 12;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenue Projection',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildRevenueCard(
                    'Monthly Revenue',
                    '\$${monthlyRevenue.toStringAsFixed(2)}',
                    Icons.calendar_month,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRevenueCard(
                    'Annual Projection',
                    '\$${annualRevenue.toStringAsFixed(2)}',
                    Icons.calendar_today,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Revenue is calculated based on current subscriber counts and standard monthly pricing.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.grey[700],
                      ),
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

  Widget _buildRevenueCard(
    String label,
    String amount,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 12),
          Text(
            amount,
            style: AppTextStyles.headlineSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

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

    return basicPlan?.price ?? '\$4.99/mo'; // Fallback with /mo suffix
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

    return premiumPlan?.price ?? '\$9.99/mo'; // Fallback with /mo suffix
  }
}
