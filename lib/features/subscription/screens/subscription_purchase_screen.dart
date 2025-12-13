import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/providers.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/subscription_tiers.dart';
import '../widgets/tier_comparison_card.dart';

class SubscriptionPurchaseScreen extends ConsumerStatefulWidget {
  const SubscriptionPurchaseScreen({
    super.key,
    this.preselectedTier,
  });

  final SubscriptionTier? preselectedTier;

  @override
  ConsumerState<SubscriptionPurchaseScreen> createState() =>
      _SubscriptionPurchaseScreenState();
}

class _SubscriptionPurchaseScreenState
    extends ConsumerState<SubscriptionPurchaseScreen> {
  Offerings? _offerings;
  bool _isLoading = true;
  bool _isPurchasing = false;
  SubscriptionTier? _selectedTier;
  bool _isAnnual = false;

  @override
  void initState() {
    super.initState();
    _selectedTier = widget.preselectedTier ?? SubscriptionTier.basic;
    _loadOfferings();
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _loadOfferings() async {
    setState(() => _isLoading = true);

    try {
      final revenueCat = ref.read(revenueCatServiceProvider);
      final offerings = await revenueCat.getOfferings();

      setState(() {
        _offerings = offerings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load subscription options: $e')),
        );
      }
    }
  }

  Future<void> _purchasePackage(Package package) async {
    setState(() => _isPurchasing = true);

    try {
      final revenueCat = ref.read(revenueCatServiceProvider);
      final success = await revenueCat.purchasePackage(package);

      setState(() => _isPurchasing = false);

      if (success && mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      setState(() => _isPurchasing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase failed: $e')),
        );
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isLoading = true);

    try {
      final revenueCat = ref.read(revenueCatServiceProvider);
      final hasActiveSubscription = await revenueCat.restorePurchases();

      setState(() => _isLoading = false);

      if (mounted) {
        if (hasActiveSubscription) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Purchases restored successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No active subscriptions found'),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to restore purchases: $e')),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: _selectedTier?.color ?? Colors.green,
              size: 32,
            ),
            const SizedBox(width: 12),
            const Text('Welcome!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "You're now a ${_selectedTier?.displayName} member!",
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: 12),
            const Text(
              'Thank you for upgrading. Your new features are now active!',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Get Started'),
          ),
        ],
      ),
    );
  }

  Package? _getPackageForTier(SubscriptionTier tier, bool isAnnual) {
    if (_offerings == null) return null;

    final offering = _offerings!.current;
    if (offering == null) return null;

    final packageId = isAnnual ? '${tier.id}_annual' : '${tier.id}_monthly';

    return offering.availablePackages.firstWhere(
      (package) => package.identifier == packageId,
      orElse: () => offering.availablePackages.first,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade Your Plan'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _restorePurchases,
            child: const Text('Restore'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Choose Your Plan',
                              style: AppTextStyles.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Unlock unlimited entries, exclusive contests, and more!',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Monthly'),
                            const SizedBox(width: 12),
                            Switch(
                              value: _isAnnual,
                              onChanged: (value) {
                                setState(() => _isAnnual = value);
                              },
                              activeThumbColor: Colors.green,
                            ),
                            const SizedBox(width: 12),
                            Row(
                              children: [
                                const Text('Annual'),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Save 17%',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TierComparisonCard(
                        tier: SubscriptionTier.basic,
                        isSelected: _selectedTier == SubscriptionTier.basic,
                        onSelect: () {
                          setState(
                              () => _selectedTier = SubscriptionTier.basic,);
                        },
                        isAnnual: _isAnnual,
                        showPopularBadge: true,
                        showSavingsBadge: _isAnnual,
                      ),
                      TierComparisonCard(
                        tier: SubscriptionTier.premium,
                        isSelected: _selectedTier == SubscriptionTier.premium,
                        onSelect: () {
                          setState(
                              () => _selectedTier = SubscriptionTier.premium,);
                        },
                        isAnnual: _isAnnual,
                        showSavingsBadge: _isAnnual,
                      ),
                      const SizedBox(height: 16),
                      const TierLimitsComparisonWidget(),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Terms & Policies',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Subscriptions automatically renew unless cancelled at least 24 hours before the end of the current period. '
                          'You can manage your subscription in your account settings. Payment will be charged to your app store account.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () =>
                                _launchURL('https://sweepfeed.app/privacy'),
                            child: Text(
                              'Privacy Policy',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const Text('  -  '),
                          TextButton(
                            onPressed: () =>
                                _launchURL('https://sweepfeed.app/terms'),
                            child: Text(
                              'Terms of Use',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isPurchasing || _selectedTier == null
                            ? null
                            : () {
                                final package = _getPackageForTier(
                                  _selectedTier!,
                                  _isAnnual,
                                );
                                if (package != null) {
                                  _purchasePackage(package);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedTier?.color ?? Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isPurchasing
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                'Subscribe to ${_selectedTier?.displayName ?? "Plan"}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
}
