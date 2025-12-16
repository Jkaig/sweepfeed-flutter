import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../models/dust_bunnies_shop.dart';
import '../providers/dust_bunnies_provider.dart';
import '../widgets/shop_item_card.dart';

/// Screen displaying user's cosmetic inventory
class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(cosmeticInventoryProvider);

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
          'My Inventory',
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textWhite,
          ),
        ),
        centerTitle: true,
      ),
      body: inventoryAsync.when(
        data: (inventory) {
          if (inventory.ownedItems.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.inventory_2_outlined,
              title: 'Empty Inventory',
              message: "You haven't purchased any items yet.\nVisit the shop to get started!",
              useDustBunny: true,
              dustBunnyImage: 'assets/images/dustbunnies/dustbunny_icon.png',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.refresh(cosmeticInventoryProvider);
            },
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: inventory.ownedItems.length,
              itemBuilder: (context, index) {
                final item = inventory.ownedItems[index];
                final isEquipped = inventory.equippedItems[item.type] == item.id;

                return ShopItemCard(
                  item: item,
                  onViewDetails: () => _showItemDetails(context, item, isEquipped),
                );
              },
            ),
          );
        },
        loading: () => const ContestGridSkeleton(
          
        ),
        error: (error, stack) => EmptyStateWidget(
          icon: Icons.error_outline,
          title: 'Error Loading Inventory',
          message: 'Could not load your inventory.\nPlease try again.',
          actionText: 'Retry',
          onAction: () => ref.refresh(cosmeticInventoryProvider),
        ),
      ),
    );
  }

  void _showItemDetails(
    BuildContext context,
    ShopItem item,
    bool isEquipped,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.primaryMedium,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.name,
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.textWhite,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.description,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            if (isEquipped)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.successGreen,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Currently Equipped',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.successGreen,
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
}
