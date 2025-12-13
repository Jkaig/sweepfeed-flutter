import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_error_widget.dart';
import '../../../core/widgets/loading_indicator.dart';

/// A screen that displays the RevenueCat paywall.
///
/// This screen uses `PurchasesPresenterView` from `purchases_ui_flutter`
/// to show the offerings and handle purchases.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _isLoading = true;
  String? _error;
  Offering? _offering;

  @override
  void initState() {
    super.initState();
    _fetchOffering();
  }

  Future<void> _fetchOffering() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final revenueCatService = ref.read(revenueCatServiceProvider);
      _offering = await revenueCatService.getCurrentOffering();
      if (_offering == null) {
        _error = 'No offerings available. Please configure in RevenueCat.';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.primaryDark,
        body: Center(
          child: LoadingIndicator(message: 'Loading subscription options...'),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.primaryDark,
        appBar: AppBar(
          title: const Text('Subscribe'),
          backgroundColor: AppColors.primaryDark,
        ),
        body: AppErrorWidget(
          message: 'Error loading subscriptions: $_error',
          onRetry: _fetchOffering,
        ),
      );
    }

    if (_offering == null) {
      return Scaffold(
        backgroundColor: AppColors.primaryDark,
        appBar: AppBar(
          title: const Text('Subscribe'),
          backgroundColor: AppColors.primaryDark,
        ),
        body: const AppErrorWidget(
          message: 'No subscription offerings available.',
        ),
      );
    }

    return PaywallView(
      displayCloseButton: true,
      offering: _offering,
      onPurchaseCompleted: (customerInfo, storeTransaction) {
        // Purchase successful, dismiss paywall
        if (customerInfo.entitlements.active.isNotEmpty && mounted) {
          Navigator.of(context).pop();
        }
      },
      onPurchaseError: (error) {
        // Handle purchase error, e.g., show a snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase error: ${error.message}')),
        );
      },
      onRestoreCompleted: (customerInfo) {
        // Restore successful, dismiss paywall if active subscription
        if (customerInfo.entitlements.active.isNotEmpty && mounted) {
          Navigator.of(context).pop();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No active subscriptions to restore.')),
          );
        }
      },
      onRestoreError: (error) {
        // Handle restore error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore error: ${error.message}')),
        );
      },
      onDismiss: () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      },
    );
  }
}
