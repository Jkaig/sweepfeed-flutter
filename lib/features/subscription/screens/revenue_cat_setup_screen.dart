import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/primary_button.dart';
import '../services/revenue_cat_setup_service.dart';

/// Admin screen to programmatically set up RevenueCat configuration
/// 
/// This screen allows you to configure RevenueCat via API instead of
/// manually using the dashboard.
class RevenueCatSetupScreen extends ConsumerStatefulWidget {
  const RevenueCatSetupScreen({super.key});

  @override
  ConsumerState<RevenueCatSetupScreen> createState() =>
      _RevenueCatSetupScreenState();
}

class _RevenueCatSetupScreenState
    extends ConsumerState<RevenueCatSetupScreen> {
  bool _isLoading = false;
  Map<String, bool>? _results;
  String? _error;

  Future<void> _setupEntitlementOnly() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _results = null;
    });

    try {
      final setupService = ref.read(revenueCatSetupServiceProvider);
      final success = await setupService.setupEntitlementOnly();

      setState(() {
        _isLoading = false;
        _results = {'entitlement': success};
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Entitlement created successfully!'
                  : 'Entitlement setup may have failed. Check logs.',
            ),
            backgroundColor:
                success ? AppColors.successGreen : AppColors.warningOrange,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _setupComplete() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _results = null;
    });

    try {
      final setupService = ref.read(revenueCatSetupServiceProvider);

      // For now, we'll set up without store product IDs
      // User can add them later via the API
      final results = await setupService.setupSweepFeedPro(
        // Leave null - will create entitlement and offering only
        // Store products must be added after creating them in stores
      );

      setState(() {
        _isLoading = false;
        _results = results;
      });

      if (mounted) {
        final successCount = results.values.where((v) => v == true).length;
        final totalCount = results.length;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Setup completed: $successCount/$totalCount operations succeeded',
            ),
            backgroundColor: successCount == totalCount
                ? AppColors.successGreen
                : AppColors.warningOrange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: const Text(
          'RevenueCat Setup',
          style: AppTextStyles.titleLarge,
        ),
        backgroundColor: AppColors.primaryDark,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Programmatic RevenueCat Setup',
                style: AppTextStyles.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Configure RevenueCat via API instead of manually using the dashboard.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 32),
              
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: LoadingIndicator(),
                )
              else ...[
                // Setup Entitlement Only
                Card(
                  color: AppColors.primaryMedium,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Setup',
                          style: AppTextStyles.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Creates the "SweepFeed Pro" entitlement. '
                          'This is the minimum needed to get started.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 16),
                        PrimaryButton(
                          text: 'Create Entitlement',
                          onPressed: _setupEntitlementOnly,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Complete Setup
                Card(
                  color: AppColors.primaryMedium,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Complete Setup',
                          style: AppTextStyles.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Creates entitlement, offering, and prepares for products. '
                          'Store products must be created in Google Play/App Store first.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 16),
                        PrimaryButton(
                          text: 'Complete Setup',
                          onPressed: _setupComplete,
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Results
              if (_results != null) ...[
                const SizedBox(height: 32),
                const Text(
                  'Setup Results',
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: 16),
                ..._results!.entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Icon(
                          entry.value ? Icons.check_circle : Icons.error,
                          color: entry.value
                              ? AppColors.successGreen
                              : AppColors.errorRed,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),),
              ],

              // Error
              if (_error != null) ...[
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.errorRed),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Error',
                        style: AppTextStyles.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),
              
              // Info
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: AppColors.brandCyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.brandCyan),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.brandCyan,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Setup Requirements',
                          style: AppTextStyles.titleSmall,
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      '• RevenueCat Secret API Key must be set in .env\n'
                      '• Store products must be created in Google Play/App Store first\n'
                      '• Then link them using the API or dashboard',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
}

