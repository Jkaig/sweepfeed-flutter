import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../models/dust_bunnies_shop.dart';
import '../providers/dust_bunnies_provider.dart';

/// Screen displaying user's transaction history
class TransactionHistoryScreen extends ConsumerWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(dustBunniesWalletProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.brandCyan),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Transaction History',
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textWhite,
          ),
        ),
        centerTitle: true,
      ),
      body: walletAsync.when(
        data: (wallet) {
          final transactions = wallet.recentTransactions;

          if (transactions.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.history,
              title: 'No Transactions',
              message: 'Your transaction history will appear here.',
              useDustBunny: true,
              dustBunnyImage: 'assets/images/dustbunnies/dustbunny_icon.png',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.refresh(dustBunniesWalletProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: transactions.length,
              cacheExtent: 500,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                return _buildTransactionCard(transaction);
              },
            ),
          );
        },
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 5,
          itemBuilder: (context, index) => const ListItemSkeleton(),
        ),
        error: (error, stack) => EmptyStateWidget(
          icon: Icons.error_outline,
          title: 'Error Loading History',
          message: 'Could not load transaction history.\nPlease try again.',
          actionText: 'Retry',
          onAction: () => ref.refresh(dustBunniesWalletProvider),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(DustBunniesTransaction transaction) {
    final isEarned = transaction.type == TransactionType.earned;
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    final currencyFormat = NumberFormat('#,###');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isEarned ? AppColors.successGreen : AppColors.errorRed)
                  .withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isEarned ? Icons.add_circle : Icons.remove_circle,
              color: isEarned ? AppColors.successGreen : AppColors.errorRed,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.reason,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateFormat.format(transaction.timestamp),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isEarned ? '+' : '-'}${currencyFormat.format(transaction.amount)}',
            style: AppTextStyles.titleMedium.copyWith(
              color: isEarned ? AppColors.successGreen : AppColors.errorRed,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
