import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dust_bunnies_shop.dart';
import '../providers/dust_bunnies_provider.dart';
import '../widgets/shop_category_tabs.dart';
import '../widgets/shop_item_card.dart';
import '../widgets/sweepcoins_wallet_header.dart';
import 'inventory_screen.dart';
import 'transaction_history_screen.dart';

class SweepCoinsShopScreen extends ConsumerStatefulWidget {
  const SweepCoinsShopScreen({super.key});

  @override
  ConsumerState<SweepCoinsShopScreen> createState() =>
      _SweepCoinsShopScreenState();
}

class _SweepCoinsShopScreenState extends ConsumerState<SweepCoinsShopScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  ShopItemType _selectedType = ShopItemType.avatarFrame;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: ShopItemType.values.length, vsync: this);

    // Fetch data on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dustBunniesShopProvider.notifier).fetchShopItems();
      ref.read(dustBunniesWalletProvider.notifier).fetchWallet('current_user');
      ref
          .read(cosmeticInventoryProvider.notifier)
          .fetchInventory('current_user');
    });

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedType = ShopItemType.values[_tabController.index];
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(dustBunniesWalletProvider);
    final limitedItems = ref.watch(limitedTimeItemsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A1929),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1929),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00E5FF)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'SweepCoins Shop',
          style: TextStyle(
            color: Color(0xFF00E5FF),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          // Inventory button
          IconButton(
            icon: const Icon(
              Icons.inventory,
              color: Color(0xFF00E5FF),
            ),
            onPressed: _showInventory,
          ),
          // Transaction history button
          IconButton(
            icon: const Icon(
              Icons.history,
              color: Color(0xFF00E5FF),
            ),
            onPressed: _showTransactionHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          // Wallet header
          walletAsync.when(
            data: (wallet) => SweepCoinsWalletHeader(wallet: wallet),
            loading: () => const SizedBox(height: 80),
            error: (_, __) => const SizedBox(height: 80),
          ),

          // Limited time items banner
          if (limitedItems.isNotEmpty) _buildLimitedItemsBanner(limitedItems),

          // Category tabs
          ShopCategoryTabs(
            tabController: _tabController,
            selectedType: _selectedType,
          ),

          // Shop content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: ShopItemType.values.map(_buildShopContent).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitedItemsBanner(List<ShopItem> limitedItems) => Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF9800),
              Color(0xFFF57C00),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF9800).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Limited Time Only!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${limitedItems.length} item${limitedItems.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Exclusive items available for a limited time. Don't miss out!",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: limitedItems.length,
                itemBuilder: (context, index) {
                  final item = limitedItems[index];
                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    child: _buildLimitedItemPreview(item),
                  );
                },
              ),
            ),
          ],
        ),
      );

  Widget _buildLimitedItemPreview(ShopItem item) => GestureDetector(
        onTap: () => _showItemDetails(item),
        child: Container(
          width: 120,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                item.type.emojiIcon,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 4),
              Text(
                item.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                item.timeRemaining,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 8,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildShopContent(ShopItemType type) => Consumer(
        builder: (context, ref, child) {
          final itemsAsync = ref.watch(shopItemsByTypeProvider(type));
          final shopAsync = ref.watch(dustBunniesShopProvider);

          return RefreshIndicator(
            onRefresh: () async {
              ref.read(dustBunniesShopProvider.notifier).refresh();
            },
            color: const Color(0xFF00E5FF),
            backgroundColor: const Color(0xFF1A2332),
            child: shopAsync.when(
              data: (allItems) {
                final typeItems =
                    allItems.where((item) => item.type == type).toList();

                if (typeItems.isEmpty) {
                  return _buildEmptyState(type);
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: typeItems.length,
                  itemBuilder: (context, index) {
                    final item = typeItems[index];
                    return ShopItemCard(
                      item: item,
                      onPurchase: () => _purchaseItem(item),
                      onViewDetails: () => _showItemDetails(item),
                    );
                  },
                );
              },
              loading: _buildLoadingState,
              error: (error, stack) => _buildErrorState(error, () {
                ref.read(dustBunniesShopProvider.notifier).refresh();
              }),
            ),
          );
        },
      );

  Widget _buildEmptyState(ShopItemType type) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              type.emojiIcon,
              style: const TextStyle(fontSize: 60),
            ),
            const SizedBox(height: 20),
            Text(
              'No ${type.displayName}s Available',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new items!',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );

  Widget _buildLoadingState() => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
        ),
      );

  Widget _buildErrorState(Object error, VoidCallback onRetry) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Color(0xFFFF9800),
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load shop items',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: const Color(0xFF0A1929),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );

  Future<void> _purchaseItem(ShopItem item) async {
    final walletAsync = ref.read(sweepCoinsWalletProvider);
    final wallet = walletAsync.valueOrNull;

    if (wallet == null) {
      _showErrorSnackBar('Wallet not loaded');
      return;
    }

    if (wallet.balance < item.price) {
      _showInsufficientFundsDialog(item);
      return;
    }

    try {
      // Attempt purchase
      final success = await ref
          .read(dustBunniesShopProvider.notifier)
          .purchaseItem(item.id, wallet.balance);

      if (success) {
        // Deduct coins from wallet
        await ref
            .read(sweepCoinsWalletProvider.notifier)
            .spendCoins(item.price, item.name, itemId: item.id);

        // Add to inventory
        await ref.read(cosmeticInventoryProvider.notifier).addItem(item);

        _showSuccessSnackBar('${item.name} purchased successfully!');
      }
    } catch (error) {
      _showErrorSnackBar('Purchase failed: ${error.toString()}');
    }
  }

  void _showItemDetails(ShopItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildItemDetailsSheet(item),
    );
  }

  Widget _buildItemDetailsSheet(ShopItem item) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Color(0xFF1A2332),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Color(item.rarity.color).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Color(item.rarity.color),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      item.type.emojiIcon,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        item.type.displayName,
                        style: const TextStyle(
                          color: Color(0xFF00E5FF),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              Color(item.rarity.color).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.rarity.displayName,
                          style: TextStyle(
                            color: Color(item.rarity.color),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Description
            const Text(
              'Description',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
                height: 1.4,
              ),
            ),

            // Properties and tags
            if (item.properties.isNotEmpty || item.tags.isNotEmpty) ...[
              const SizedBox(height: 24),
              if (item.tags.isNotEmpty) ...[
                const Text(
                  'Tags',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: item.tags
                      .map(
                        (tag) => Chip(
                          label: Text(
                            tag,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          backgroundColor:
                              const Color(0xFF00E5FF).withValues(alpha: 0.2),
                          side: const BorderSide(color: Color(0xFF00E5FF)),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],

            const Spacer(),

            // Limited time warning
            if (item.isLimited) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFF9800)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      color: Color(0xFFFF9800),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Limited time: ${item.timeRemaining} remaining',
                        style: const TextStyle(
                          color: Color(0xFFFF9800),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Purchase button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: item.isOwned
                    ? null
                    : () {
                        Navigator.pop(context);
                        _purchaseItem(item);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: item.isOwned
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFF00E5FF),
                  foregroundColor:
                      item.isOwned ? Colors.white : const Color(0xFF0A1929),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(
                  item.isOwned ? Icons.check_circle : Icons.shopping_cart,
                  size: 20,
                ),
                label: Text(
                  item.isOwned ? 'Owned' : '${item.price} SweepCoins',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  void _showInsufficientFundsDialog(ShopItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2332),
        title: const Text(
          'Insufficient SweepCoins',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You need ${item.price} SweepCoins to purchase ${item.name}.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: Color(0xFF00E5FF),
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Earn more SweepCoins by completing challenges and contests!',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to main screen
              // Navigate to challenges screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5FF),
              foregroundColor: const Color(0xFF0A1929),
            ),
            child: const Text('Earn Coins'),
          ),
        ],
      ),
    );
  }

  void _showInventory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const InventoryScreen(),
      ),
    );
  }

  void _showTransactionHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TransactionHistoryScreen(),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFF44336),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
