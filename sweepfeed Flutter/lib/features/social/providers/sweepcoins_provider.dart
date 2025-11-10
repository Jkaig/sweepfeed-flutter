import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sweepcoins_shop.dart';

/// Provider for managing SweepCoins shop
class SweepCoinsShopNotifier extends StateNotifier<AsyncValue<List<ShopItem>>> {
  SweepCoinsShopNotifier() : super(const AsyncValue.loading());

  /// Fetch all shop items
  Future<void> fetchShopItems() async {
    try {
      state = const AsyncValue.loading();

      // In production, this would query Firestore
      await Future.delayed(const Duration(milliseconds: 600));

      final items = _generateMockShopItems();
      state = AsyncValue.data(items);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Purchase an item
  Future<bool> purchaseItem(String itemId, int userBalance) async {
    try {
      final currentItems = state.valueOrNull ?? [];
      final item = currentItems.firstWhere((item) => item.id == itemId);

      if (userBalance < item.price) {
        throw Exception('Insufficient SweepCoins');
      }

      if (item.isOwned) {
        throw Exception('Item already owned');
      }

      if (!item.isAvailable) {
        throw Exception('Item not available');
      }

      // In production, this would update Firestore
      await Future.delayed(const Duration(milliseconds: 500));

      // Update local state to mark item as owned
      final updatedItems = currentItems.map((shopItem) {
        if (shopItem.id == itemId) {
          return shopItem.copyWith(isOwned: true);
        }
        return shopItem;
      }).toList();

      state = AsyncValue.data(updatedItems);
      return true;
    } catch (error) {
      rethrow;
    }
  }

  /// Refresh shop items
  Future<void> refresh() async {
    await fetchShopItems();
  }

  /// Generate mock shop items for development
  List<ShopItem> _generateMockShopItems() {
    final now = DateTime.now();

    return [
      // Avatar Frames
      const ShopItem(
        id: 'frame_neon_glow',
        name: 'Neon Glow Frame',
        description: 'A vibrant neon frame that pulses with energy',
        type: ShopItemType.avatarFrame,
        rarity: ShopItemRarity.rare,
        price: 150,
        imageUrl: 'https://example.com/frames/neon_glow.png',
        isLimited: false,
        isOwned: false,
        isEquipped: false,
        properties: {'glow_color': 'cyan', 'animation': 'pulse'},
        tags: ['glow', 'animated', 'popular'],
      ),

      const ShopItem(
        id: 'frame_fire_border',
        name: 'Fire Border',
        description: 'Blazing flames surround your avatar',
        type: ShopItemType.avatarFrame,
        rarity: ShopItemRarity.epic,
        price: 300,
        imageUrl: 'https://example.com/frames/fire_border.png',
        isLimited: false,
        isOwned: true,
        isEquipped: true,
        properties: {'flame_intensity': 'high', 'color_scheme': 'orange_red'},
        tags: ['fire', 'epic', 'animated'],
      ),

      // Limited Edition Frame
      ShopItem(
        id: 'frame_cyber_monday',
        name: 'Cyber Monday Special',
        description: 'Exclusive digital circuit frame - limited time only!',
        type: ShopItemType.avatarFrame,
        rarity: ShopItemRarity.legendary,
        price: 500,
        imageUrl: 'https://example.com/frames/cyber_monday.png',
        isLimited: true,
        limitedUntil: now.add(const Duration(hours: 24)),
        isOwned: false,
        isEquipped: false,
        properties: const {
          'circuit_pattern': 'digital',
          'special_event': 'cyber_monday',
        },
        tags: const ['limited', 'legendary', 'tech', 'exclusive'],
      ),

      // Badges
      const ShopItem(
        id: 'badge_streak_master',
        name: 'Streak Master',
        description: 'Show off your dedication with this flame badge',
        type: ShopItemType.badge,
        rarity: ShopItemRarity.uncommon,
        price: 75,
        imageUrl: 'https://example.com/badges/streak_master.png',
        isLimited: false,
        isOwned: false,
        isEquipped: false,
        properties: {'flame_color': 'orange', 'tier': 'master'},
        tags: ['streak', 'achievement', 'fire'],
      ),

      const ShopItem(
        id: 'badge_contest_king',
        name: 'Contest Royalty',
        description: 'Crown badge for the ultimate contest champions',
        type: ShopItemType.badge,
        rarity: ShopItemRarity.epic,
        price: 250,
        imageUrl: 'https://example.com/badges/contest_king.png',
        isLimited: false,
        isOwned: true,
        isEquipped: false,
        properties: {'crown_type': 'royal', 'gem_count': 3},
        tags: ['crown', 'royal', 'champion'],
      ),

      // Backgrounds
      const ShopItem(
        id: 'bg_starfield',
        name: 'Cosmic Starfield',
        description: 'A beautiful animated starfield background',
        type: ShopItemType.background,
        rarity: ShopItemRarity.rare,
        price: 200,
        imageUrl: 'https://example.com/backgrounds/starfield.png',
        isLimited: false,
        isOwned: false,
        isEquipped: false,
        properties: {'animation_speed': 'slow', 'star_density': 'medium'},
        tags: ['space', 'animated', 'cosmic'],
      ),

      // Themes
      const ShopItem(
        id: 'theme_cyberpunk',
        name: 'Cyberpunk Theme',
        description: 'Dark futuristic theme with neon accents',
        type: ShopItemType.theme,
        rarity: ShopItemRarity.epic,
        price: 400,
        imageUrl: 'https://example.com/themes/cyberpunk.png',
        isLimited: false,
        isOwned: false,
        isEquipped: false,
        properties: {
          'primary_color': '#FF0080',
          'secondary_color': '#00FFFF',
          'background_color': '#0A0A0A',
        },
        tags: ['cyberpunk', 'dark', 'neon', 'futuristic'],
      ),

      // Titles
      const ShopItem(
        id: 'title_sweepstakes_legend',
        name: 'Sweepstakes Legend',
        description: 'Elite title for the most dedicated players',
        type: ShopItemType.title,
        rarity: ShopItemRarity.legendary,
        price: 750,
        imageUrl: 'https://example.com/titles/legend.png',
        isLimited: false,
        isOwned: false,
        isEquipped: false,
        properties: {'text_effect': 'glow', 'rarity_indicator': 'legendary'},
        tags: ['title', 'legendary', 'elite', 'prestige'],
      ),

      // Emoji Packs
      const ShopItem(
        id: 'emoji_gaming_pack',
        name: 'Gaming Emoji Pack',
        description: 'Gaming-themed emojis for reactions',
        type: ShopItemType.emoji,
        rarity: ShopItemRarity.common,
        price: 50,
        imageUrl: 'https://example.com/emoji/gaming_pack.png',
        isLimited: false,
        isOwned: true,
        isEquipped: false,
        properties: {'emoji_count': 12, 'theme': 'gaming'},
        tags: ['emoji', 'gaming', 'reactions'],
      ),

      // Animations
      const ShopItem(
        id: 'anim_victory_confetti',
        name: 'Victory Confetti',
        description: 'Celebratory confetti animation for wins',
        type: ShopItemType.animation,
        rarity: ShopItemRarity.rare,
        price: 180,
        imageUrl: 'https://example.com/animations/confetti.png',
        isLimited: false,
        isOwned: false,
        isEquipped: false,
        properties: {'duration': 3000, 'particle_count': 50},
        tags: ['celebration', 'confetti', 'victory'],
      ),

      // Stickers
      const ShopItem(
        id: 'sticker_lucky_cat',
        name: 'Lucky Cat Sticker',
        description: 'Adorable lucky cat for good fortune',
        type: ShopItemType.sticker,
        rarity: ShopItemRarity.uncommon,
        price: 100,
        imageUrl: 'https://example.com/stickers/lucky_cat.png',
        isLimited: false,
        isOwned: false,
        isEquipped: false,
        properties: {'cat_color': 'golden', 'luck_boost': 'none'},
        tags: ['cute', 'lucky', 'cat', 'fortune'],
      ),
    ];
  }
}

/// Provider for user's SweepCoins wallet
class SweepCoinsWalletNotifier
    extends StateNotifier<AsyncValue<SweepCoinsWallet>> {
  SweepCoinsWalletNotifier() : super(const AsyncValue.loading());

  /// Fetch user's wallet
  Future<void> fetchWallet(String userId) async {
    try {
      state = const AsyncValue.loading();

      // In production, this would query Firestore
      await Future.delayed(const Duration(milliseconds: 400));

      final wallet = _generateMockWallet(userId);
      state = AsyncValue.data(wallet);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Spend SweepCoins
  Future<void> spendCoins(int amount, String reason, {String? itemId}) async {
    final currentWallet = state.valueOrNull;
    if (currentWallet == null) return;

    if (currentWallet.balance < amount) {
      throw Exception('Insufficient balance');
    }

    // In production, update Firestore
    await Future.delayed(const Duration(milliseconds: 300));

    final transaction = SweepCoinsTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      type: TransactionType.spent,
      amount: amount,
      reason: reason,
      itemId: itemId,
      timestamp: DateTime.now(),
    );

    final updatedWallet = currentWallet.copyWith(
      balance: currentWallet.balance - amount,
      totalSpent: currentWallet.totalSpent + amount,
      recentTransactions:
          [transaction, ...currentWallet.recentTransactions.take(9)].toList(),
    );

    state = AsyncValue.data(updatedWallet);
  }

  /// Add SweepCoins (from challenges, etc.)
  Future<void> addCoins(int amount, String reason) async {
    final currentWallet = state.valueOrNull;
    if (currentWallet == null) return;

    // In production, update Firestore
    await Future.delayed(const Duration(milliseconds: 300));

    final transaction = SweepCoinsTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      type: TransactionType.earned,
      amount: amount,
      reason: reason,
      timestamp: DateTime.now(),
    );

    final updatedWallet = currentWallet.copyWith(
      balance: currentWallet.balance + amount,
      totalEarned: currentWallet.totalEarned + amount,
      recentTransactions:
          [transaction, ...currentWallet.recentTransactions.take(9)].toList(),
    );

    state = AsyncValue.data(updatedWallet);
  }

  /// Generate mock wallet for development
  SweepCoinsWallet _generateMockWallet(String userId) {
    final now = DateTime.now();

    return SweepCoinsWallet(
      userId: userId,
      balance: 450,
      totalEarned: 1250,
      totalSpent: 800,
      recentTransactions: [
        SweepCoinsTransaction(
          id: 'tx_001',
          type: TransactionType.earned,
          amount: 50,
          reason: 'Daily Challenge Completed',
          timestamp: now.subtract(const Duration(hours: 2)),
        ),
        SweepCoinsTransaction(
          id: 'tx_002',
          type: TransactionType.spent,
          amount: 100,
          reason: 'Lucky Cat Sticker',
          itemId: 'sticker_lucky_cat',
          timestamp: now.subtract(const Duration(hours: 5)),
        ),
        SweepCoinsTransaction(
          id: 'tx_003',
          type: TransactionType.earned,
          amount: 25,
          reason: 'Contest Entry Bonus',
          timestamp: now.subtract(const Duration(hours: 8)),
        ),
        SweepCoinsTransaction(
          id: 'tx_004',
          type: TransactionType.spent,
          amount: 300,
          reason: 'Fire Border Avatar Frame',
          itemId: 'frame_fire_border',
          timestamp: now.subtract(const Duration(days: 1)),
        ),
        SweepCoinsTransaction(
          id: 'tx_005',
          type: TransactionType.earned,
          amount: 150,
          reason: 'Weekly Challenge Completed',
          timestamp: now.subtract(const Duration(days: 2)),
        ),
      ],
    );
  }
}

/// Provider for cosmetic inventory
class CosmeticInventoryNotifier
    extends StateNotifier<AsyncValue<CosmeticInventory>> {
  CosmeticInventoryNotifier() : super(const AsyncValue.loading());

  /// Fetch user's cosmetic inventory
  Future<void> fetchInventory(String userId) async {
    try {
      state = const AsyncValue.loading();

      // In production, query Firestore
      await Future.delayed(const Duration(milliseconds: 500));

      final inventory = _generateMockInventory(userId);
      state = AsyncValue.data(inventory);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Equip an item
  Future<void> equipItem(String itemId, ShopItemType type) async {
    final currentInventory = state.valueOrNull;
    if (currentInventory == null) return;

    // Check if user owns the item
    if (!currentInventory.ownsItem(itemId)) {
      throw Exception('Item not owned');
    }

    // In production, update Firestore
    await Future.delayed(const Duration(milliseconds: 300));

    final updatedEquipped =
        Map<ShopItemType, String?>.from(currentInventory.equippedItems);
    updatedEquipped[type] = itemId;

    final updatedInventory =
        currentInventory.copyWith(equippedItems: updatedEquipped);
    state = AsyncValue.data(updatedInventory);
  }

  /// Unequip an item
  Future<void> unequipItem(ShopItemType type) async {
    final currentInventory = state.valueOrNull;
    if (currentInventory == null) return;

    // In production, update Firestore
    await Future.delayed(const Duration(milliseconds: 300));

    final updatedEquipped =
        Map<ShopItemType, String?>.from(currentInventory.equippedItems);
    updatedEquipped[type] = null;

    final updatedInventory =
        currentInventory.copyWith(equippedItems: updatedEquipped);
    state = AsyncValue.data(updatedInventory);
  }

  /// Add item to inventory (after purchase)
  Future<void> addItem(ShopItem item) async {
    final currentInventory = state.valueOrNull;
    if (currentInventory == null) return;

    final updatedItems = [
      ...currentInventory.ownedItems,
      item.copyWith(isOwned: true),
    ];
    final updatedInventory =
        currentInventory.copyWith(ownedItems: updatedItems);

    state = AsyncValue.data(updatedInventory);
  }

  /// Generate mock inventory for development
  CosmeticInventory _generateMockInventory(String userId) => CosmeticInventory(
        userId: userId,
        ownedItems: const [
          // Mock owned items - these would match some shop items
        ],
        equippedItems: const {
          ShopItemType.avatarFrame: 'frame_fire_border',
          ShopItemType.badge: null,
          ShopItemType.background: null,
          ShopItemType.theme: null,
          ShopItemType.title: null,
          ShopItemType.emoji: 'emoji_gaming_pack',
          ShopItemType.animation: null,
          ShopItemType.sticker: null,
        },
      );
}

/// Providers
final sweepCoinsShopProvider =
    StateNotifierProvider<SweepCoinsShopNotifier, AsyncValue<List<ShopItem>>>(
  (ref) => SweepCoinsShopNotifier(),
);

final sweepCoinsWalletProvider = StateNotifierProvider<SweepCoinsWalletNotifier,
    AsyncValue<SweepCoinsWallet>>((ref) => SweepCoinsWalletNotifier());

final cosmeticInventoryProvider = StateNotifierProvider<
    CosmeticInventoryNotifier,
    AsyncValue<CosmeticInventory>>((ref) => CosmeticInventoryNotifier());

/// Provider for shop items by type
final shopItemsByTypeProvider =
    Provider.family<List<ShopItem>, ShopItemType>((ref, type) {
  final shopAsync = ref.watch(sweepCoinsShopProvider);
  return shopAsync.when(
    data: (items) => items.where((item) => item.type == type).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider for available shop items (not owned)
final availableShopItemsProvider = Provider<List<ShopItem>>((ref) {
  final shopAsync = ref.watch(sweepCoinsShopProvider);
  return shopAsync.when(
    data: (items) => items.where((item) => item.isAvailable).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider for limited time items
final limitedTimeItemsProvider = Provider<List<ShopItem>>((ref) {
  final shopAsync = ref.watch(sweepCoinsShopProvider);
  return shopAsync.when(
    data: (items) =>
        items.where((item) => item.isLimited && item.isAvailable).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider for user's current balance
final userBalanceProvider = Provider<int>((ref) {
  final walletAsync = ref.watch(sweepCoinsWalletProvider);
  return walletAsync.when(
    data: (wallet) => wallet.balance,
    loading: () => 0,
    error: (_, __) => 0,
  );
});
