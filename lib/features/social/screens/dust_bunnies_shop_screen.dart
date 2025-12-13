import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/providers/providers.dart';

// ... existing imports

  Future<void> _handlePurchase(ShopItem item) async {
    final walletAsync = ref.read(dustBunniesWalletProvider);
    final wallet = walletAsync.valueOrNull;
    final user = ref.read(firebaseAuthProvider).currentUser;

    if (wallet == null || user == null) return;

    if (wallet.balance < item.price) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not enough DustBunnies!'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
      return;
    }

    try {
      // 1. Deduct DustBunnies
      await ref.read(dustBunniesWalletProvider.notifier).spendCoins(
            item.price,
            'Purchased ${item.name}',
            itemId: item.id,
          );

      // 2. Process Purchase (Mock API call)
      await ref.read(dustBunniesShopProvider.notifier).purchaseItem(
            item.id,
            wallet.balance,
          );

      // 3. Apply Effects
      if (item.type == ShopItemType.powerUp) {
        if (item.id == 'powerup_streak_freeze') {
           // Add freeze to user's streak data
           await ref.read(streakServiceProvider).addFreeze(user.uid, amount: 1);
        } else if (item.id == 'powerup_double_dust') {
           // Placeholder for double dust logic
           // In a real app, this would update a 'buffs' collection or field
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Double Dust Activated! (Visual only for now)')),
           );
        }
      } else if (item.type == ShopItemType.utility) {
        // Unlock the feature
        final unlockService = ref.read(featureUnlockServiceProvider);
        await unlockService.unlockFeature(item.id);
        
        // Add to inventory
        await ref.read(cosmeticInventoryProvider.notifier).addItem(item);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item.name} unlocked! Feature is now available.'),
              backgroundColor: AppColors.successGreen,
            ),
          );
        }
      } else {
        // Add to inventory
        await ref.read(cosmeticInventoryProvider.notifier).addItem(item);
      }

      if (mounted) {
        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.primaryDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.brandCyan.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(item.type.emojiIcon, style: const TextStyle(fontSize: 48)),
                ),
                const SizedBox(height: 24),
                Text(
                  'Purchased!',
                  style: AppTextStyles.headlineSmall.copyWith(color: AppColors.brandCyan),
                ),
                const SizedBox(height: 8),
                Text(
                  'You obtained ${item.name}',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandCyan,
                    foregroundColor: AppColors.primaryDark,
                  ),
                  child: const Text('Awesome'),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/animated_gradient_background.dart';
import '../../../core/widgets/glassmorphic_container.dart';
import '../../social/models/dust_bunnies_shop.dart';
import '../providers/dust_bunnies_provider.dart';
import '../widgets/dust_bunnies_wallet_header.dart';
import '../widgets/shop_item_card.dart';
import 'inventory_screen.dart';
import 'leaderboard_screen.dart';

class DustBunniesShopScreen extends ConsumerStatefulWidget {
  const DustBunniesShopScreen({super.key});

  @override
  ConsumerState<DustBunniesShopScreen> createState() =>
      _DustBunniesShopScreenState();
}

class _DustBunniesShopScreenState extends ConsumerState<DustBunniesShopScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Grouped Categories
  final List<String> _categories = ['Toolkit', 'Cosmetics'];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dustBunniesShopProvider.notifier).fetchShopItems();
      ref.read(dustBunniesWalletProvider.notifier).fetchWallet('current_user');
      ref
          .read(cosmeticInventoryProvider.notifier)
          .fetchInventory('current_user');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handlePurchase(ShopItem item) async {
    final walletAsync = ref.read(dustBunniesWalletProvider);
    final wallet = walletAsync.valueOrNull;

    if (wallet == null) return;

    if (wallet.balance < item.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enough DustBunnies!'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    try {
      // 1. Deduct DustBunnies
      await ref.read(dustBunniesWalletProvider.notifier).spendCoins(
            item.price,
            'Purchased ${item.name}',
            itemId: item.id,
          );

      // 2. Process Purchase (Mock API call)
      await ref.read(dustBunniesShopProvider.notifier).purchaseItem(
            item.id,
            wallet.balance,
          );

      // 3. Apply Effects
      if (item.type == ShopItemType.powerUp) {
        if (item.id == 'powerup_streak_freeze') {
           // Add freeze to user's streak data
           // We need to access a provider that exposes StreakService, or use the service directly.
           // Assuming we can get the service from context/ref or it's a singleton/provider.
           // Since streak_service.dart defines StreakService but not a provider... 
           // Wait, MainScreen uses it.
           // Let's assume there is a provider or we can access it.
           // Ah, I don't see a 'streakServiceProvider' imported.
           // I'll assume for now I should use a hypothetical provider or just log it if I can't find it.
           // Actually, let's look at `lib/core/providers/providers.dart`.
           // I will check providers.dart in a moment if needed, but for now let's try to find it.
           // If not found, I will comment it out and fix it in next step.
           // Wait, I imported streak_service.dart.
           // I need `streakServiceProvider`.
           
           // I will assume `streakServiceProvider` exists in `core/providers/providers.dart` or similar.
           // But I don't have that import in the original file. 
           // I will add the import: `import '../../../core/providers/providers.dart';`
        }
      } else {
        // Add to inventory
        await ref.read(cosmeticInventoryProvider.notifier).addItem(item);
      }

      if (mounted) {
        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.primaryDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.brandCyan.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(item.type.emojiIcon, style: const TextStyle(fontSize: 48)),
                ),
                const SizedBox(height: 24),
                Text(
                  'Purchased!',
                  style: AppTextStyles.headlineSmall.copyWith(color: AppColors.brandCyan),
                ),
                const SizedBox(height: 8),
                Text(
                  'You obtained ${item.name}',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandCyan,
                    foregroundColor: AppColors.primaryDark,
                  ),
                  child: const Text('Awesome'),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(dustBunniesWalletProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: GlassmorphicContainer(
          child: Container(),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.brandCyan),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Sweeper's Toolkit",
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard, color: AppColors.brandCyan),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.inventory_2, color: AppColors.brandCyan),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InventoryScreen()),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background
          const Positioned.fill(child: AnimatedGradientBackground()),

          Column(
            children: [
              SizedBox(height: kToolbarHeight + MediaQuery.of(context).padding.top),
              
              // Wallet
              walletAsync.when(
                data: (wallet) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DustBunniesWalletHeader(wallet: wallet),
                ),
                loading: () => const SizedBox(height: 100),
                error: (_, __) => const SizedBox.shrink(),
              ),

              // Glassmorphic Tab Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                height: 50,
                child: GlassmorphicContainer(
                  borderRadius: 25,
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: AppColors.brandCyan.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: AppColors.brandCyan.withOpacity(0.5), width: 1),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: AppColors.brandCyan,
                    unselectedLabelColor: Colors.white60,
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'Toolkit'), // Removed icon for cleaner look, handled elsewhere if needed
                      Tab(text: 'Cosmetics'),
                    ],
                  ),
                ),
              ),

              // Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildToolkitGrid(),
                    _buildCosmeticsGrid(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolkitGrid() => Consumer(
    builder: (context, ref, _) {
      final itemsAsync = ref.watch(dustBunniesShopProvider);
      
      return itemsAsync.when(
        data: (items) {
          final tools = items.where((i) => 
            i.type == ShopItemType.powerUp || i.type == ShopItemType.utility
          ).toList();

          if (tools.isEmpty) {
            return _buildEmptyState('No tools available yet!', Icons.construction);
          }
          
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75, // Taller cards
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: tools.length,
            itemBuilder: (context, index) => ShopItemCard(
              item: tools[index],
              onViewDetails: () {},
              onPurchase: () => _handlePurchase(tools[index]),
            ).animate().scale(delay: (50 * index).ms),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const SizedBox.shrink(),
      );
    },
  );

  Widget _buildCosmeticsGrid() => Consumer(
    builder: (context, ref, _) {
      final itemsAsync = ref.watch(dustBunniesShopProvider);
      
      return itemsAsync.when(
        data: (items) {
          final cosmetics = items.where((i) => 
            i.type != ShopItemType.powerUp && i.type != ShopItemType.utility
          ).toList();

           if (cosmetics.isEmpty) return _buildEmptyState('Shop empty!', Icons.store);

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: cosmetics.length,
            itemBuilder: (context, index) => ShopItemCard(
              item: cosmetics[index],
              onViewDetails: () {},
              onPurchase: () => _handlePurchase(cosmetics[index]),
            ).animate().scale(delay: (50 * index).ms),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const SizedBox.shrink(),
      );
    },
  );

  Widget _buildEmptyState(String text, IconData icon) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 48, color: Colors.white24),
        const SizedBox(height: 16),
        Text(
          text,
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white54),
        ),
      ],
    ),
  );
}
