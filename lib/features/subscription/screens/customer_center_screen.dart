import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:sweepfeed/features/subscription/screens/premium_subscription_screen.dart';

import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/logger.dart';

/// Customer Center screen using RevenueCat's built-in customer center UI
/// 
/// Allows users to manage their subscriptions, restore purchases,
/// and view subscription details.
class CustomerCenterScreen extends ConsumerStatefulWidget {
  const CustomerCenterScreen({super.key});

  @override
  ConsumerState<CustomerCenterScreen> createState() =>
      _CustomerCenterScreenState();
}

class _CustomerCenterScreenState extends ConsumerState<CustomerCenterScreen> {
  bool _isLoading = true;
  CustomerInfo? _customerInfo;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCustomerInfo();
  }

  Future<void> _loadCustomerInfo() async {
    try {
      final revenueCatService = ref.read(revenueCatServiceProvider);
      final customerInfo = await revenueCatService.getCustomerInfo();
      
      if (mounted) {
        setState(() {
          _customerInfo = customerInfo;
          _isLoading = false;
        });
      }
    } catch (e) {
      logger.e('Error loading customer info', error: e);
      if (mounted) {
        setState(() {
          _error = 'Failed to load subscription information.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: const Text(
          'Subscription Management',
          style: AppTextStyles.titleLarge,
        ),
        backgroundColor: AppColors.primaryDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.brandCyan,
              ),
            )
          : _error != null
              ? _buildErrorState()
              : _buildCustomerCenter(),
    );

  Widget _buildErrorState() => Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.errorRed,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textWhite,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _error = null;
                  _isLoading = true;
                });
                _loadCustomerInfo();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );

  Widget _buildCustomerCenter() {
    if (_customerInfo?.entitlements.active.isEmpty ?? true) {
      return _buildPlaceholder();
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.manage_accounts,
              color: AppColors.brandCyan,
              size: 64,
            ),
            const SizedBox(height: 24),
            Text(
              'Subscription Management',
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.textWhite,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You have an active subscription. You can manage it here.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  await RevenueCatUI.presentCustomerCenter();
                } catch (e) {
                  logger.e('Error presenting Customer Center', error: e);
                }
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open Customer Center'),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () async {
                try {
                  final revenueCatService = ref.read(revenueCatServiceProvider);
                  final success = await revenueCatService.restorePurchases();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Purchases restored successfully'
                              : 'No purchases to restore',
                        ),
                        backgroundColor:
                            success ? AppColors.successGreen : AppColors.errorRed,
                      ),
                    );
                    if (success) {
                      _loadCustomerInfo();
                    }
                  }
                } catch (e) {
                  logger.e('Error restoring purchases', error: e);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Restore failed. Please try again.'),
                        backgroundColor: AppColors.errorRed,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.restore, color: AppColors.brandCyan),
              label: const Text(
                'Restore Purchases',
                style: TextStyle(color: AppColors.brandCyan),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.subscriptions_outlined,
              color: AppColors.textMuted,
              size: 64,
            ),
            const SizedBox(height: 24),
            Text(
              'No Active Subscription',
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.textWhite,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You do not have an active subscription to manage.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PremiumSubscriptionScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.star),
              label: const Text('View Premium Options'),
            ),
          ],
        ),
      ),
    );
  }
}

