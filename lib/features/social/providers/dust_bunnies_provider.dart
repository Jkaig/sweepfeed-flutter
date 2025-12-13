import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dust_bunnies_shop.dart';

/// Provider for managing DustBunnies shop
class DustBunniesShopNotifier extends StateNotifier<AsyncValue<List<ShopItem>>> {
  DustBunniesShopNotifier({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance, 
        super(const AsyncValue.loading());

  final FirebaseFirestore _firestore;

  /// Fetch all shop items
  Future<void> fetchShopItems() async {
    try {
      state = const AsyncValue.loading();
      
      final snapshot = await _firestore.collection('shop_items').get();
      
      if (snapshot.docs.isNotEmpty) {
        // Parse from Firestore
        final items = snapshot.docs.map((doc) {
           final data = doc.data();
           // Allow ID in data to override doc ID, or use doc ID
           final id = data['id'] as String? ?? doc.id;
           return ShopItem.fromJson({...data, 'id': id});
        }).toList();
        state = AsyncValue.data(items);
      } else {
        // Fallback to mock data if collection is empty
        final items = _generateMockShopItems();
        state = AsyncValue.data(items);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Purchase an item
  Future<bool> purchaseItem(String itemId, int userBalance) async {
    try {
      // Mock purchase for now
      await Future.delayed(const Duration(milliseconds: 600));
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
      // Power-ups
      const ShopItem(
        id: 'powerup_streak_freeze',
        name: 'Streak Freeze',
        description: 'Protect your streak for one missed day. Max 3.',
        type: ShopItemType.powerUp,
        rarity: ShopItemRarity.rare,
        price: 500,
        imageUrl: '', // Use emoji icon fallback
        isLimited: false,
        isOwned: false,
        isEquipped: false,
        properties: {'freeze_duration': 1, 'max_stack': 3},
        tags: ['streak', 'protection', 'essential'],
      ),

      const ShopItem(
        id: 'powerup_double_dust',
        name: 'Double Dust (24h)',
        description: 'Earn 2x DustBunnies from all activities for 24 hours.',
        type: ShopItemType.powerUp,
        rarity: ShopItemRarity.epic,
        price: 1000,
        imageUrl: '',
        isLimited: false,
        isOwned: false,
        isEquipped: false,
        properties: {'multiplier': 2.0, 'duration_hours': 24},
        tags: ['boost', 'earnings', 'dustbunnies'],
      ),
      
      // Productivity Tools
      const ShopItem(
        id: 'tool_entry_tracker',
        name: 'Entry Tracker Pro',
        description: 'Advanced tracking to see which contests you\'ve entered. Never miss a daily entry again!',
        type: ShopItemType.utility,
        rarity: ShopItemRarity.rare,
        price: 300,
        imageUrl: '',
        isLimited: false,
        isOwned: false,
        isEquipped: false,
        properties: {'feature': 'entry_tracking', 'lifetime': true},
        tags: ['productivity', 'tracking', 'essential', 'power_user'],
      ),
      
      const ShopItem(
        id: 'tool_sort_ending_soon',
        name: 'Sort by Ending Soon',
        description: 'Unlock all sorting options! Sort by ending date, prize value, trending, and more.',
        type: ShopItemType.utility,
        rarity: ShopItemRarity.uncommon,
        price: 550, // 🎯 PSYCHOLOGICAL SWEET SPOT: Day 2-3 unlock for free users (Day 1: ~315 DB, Day 2: +265 DB = 580 total. Feels like early progress reward)
        imageUrl: '',
        isLimited: false,
        isOwned: false,
        isEquipped: false,
        properties: {'feature': 'sort_unlock', 'lifetime': true},
        tags: ['productivity', 'sorting', 'priority', 'power_user'],
      ),
      
      const ShopItem(
        id: 'tool_filter_pro',
        name: 'Filter Pro',
        description: 'Unlock advanced filters! Filter by prize value, entry method, categories, and more.',
        type: ShopItemType.utility,
        rarity: ShopItemRarity.rare,
        price: 1100, // 🎯 PSYCHOLOGICAL SWEET SPOT: Day 4-5 unlock for free users (After sort, need ~2 more days = meaningful milestone)
        imageUrl: '',
        isLimited: false,
        isOwned: false,
        isEquipped: false,
        properties: {'feature': 'filter_unlock', 'lifetime': true},
        tags: ['productivity', 'filtering', 'power_user', 'essential'],
      ),
      
      const ShopItem(
        id: 'tool_search_pro',
        name: 'Search Pro',
        description: 'Unlock advanced search to find contests by title, sponsor, prize, and more!',
        type: ShopItemType.utility,
        rarity: ShopItemRarity.rare,
        price: 1800, // 🎯 PSYCHOLOGICAL SWEET SPOT: Day 6-7 unlock for free users (After filter, need ~2-3 more days = major achievement feeling)
        imageUrl: '',
        isLimited: false,
        isOwned: false,
        isEquipped: false,
        properties: {'feature': 'search_unlock', 'lifetime': true},
        tags: ['productivity', 'search', 'power_user', 'essential'],
      ),
      
      const ShopItem(
        id: 'tool_daily_reminder',
        name: 'Daily Entry Reminder',
        description: 'Smart reminders for your daily entries. Never break your streak!',
        type: ShopItemType.utility,
        rarity: ShopItemRarity.common,
        price: 150,
        imageUrl: '',
        isLimited: false,
        isOwned: false,
        isEquipped: false,
        properties: {'feature': 'daily_reminders', 'lifetime': true},
        tags: ['productivity', 'reminders', 'streak', 'power_user'],
      ),
      
      const ShopItem(
        id: 'tool_batch_entry',
        name: 'Batch Entry Assistant',
        description: 'Streamlined batch entry for multiple contests. Save time, enter more!',
        type: ShopItemType.utility,
        rarity: ShopItemRarity.epic,
        price: 500,
        imageUrl: '',
        isLimited: false,
        isOwned: false,
        isEquipped: false,
        properties: {'feature': 'batch_entry', 'lifetime': true},
        tags: ['productivity', 'batch', 'power_user', 'time_saver'],
      ),
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
        name: 'Contests Legend',
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

/// Provider for user's DustBunnies wallet
class DustBunniesWalletNotifier
    extends StateNotifier<AsyncValue<DustBunniesWallet>> {
  DustBunniesWalletNotifier(this._ref) : super(const AsyncValue.loading());

  final Ref _ref;

  /// Fetch user's wallet
  Future<void> fetchWallet(String userId) async {
    try {
      state = const AsyncValue.loading();
      
      final dustBunniesService = _ref.read(dustBunniesServiceProvider);
      final data = await dustBunniesService.getUserDustBunniesData(userId);
      
      // Fetch recent transactions
      // Note: This matches the structure in DustBunniesService._logDustBunniesTransaction
      final historySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('dustBunniesHistory')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      final transactions = historySnapshot.docs.map((doc) {
        final d = doc.data();
        return DustBunniesTransaction(
          id: doc.id,
          type: (d['dustBunniesGained'] as int? ?? 0) >= 0 
              ? TransactionType.earned 
              : TransactionType.spent,
          amount: (d['dustBunniesGained'] as int? ?? 0).abs(),
          reason: d['action'] as String? ?? 'Unknown',
          timestamp: (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();

      final wallet = DustBunniesWallet(
        userId: userId,
        balance: data['currentDB'] as int? ?? 0,
        totalEarned: data['totalDB'] as int? ?? 0,
        totalSpent: 0, // Not explicitly tracked in simple data, effectively derived
        recentTransactions: transactions,
      );
      
      state = AsyncValue.data(wallet);
      
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Spend DustBunnies
  Future<void> spendCoins(int amount, String reason, {String? itemId}) async {
    final currentWallet = state.valueOrNull;
    if (currentWallet == null) return;

    if (currentWallet.balance < amount) {
      throw Exception('Insufficient balance');
    }

    // In production, update Firestore
    await Future.delayed(const Duration(milliseconds: 300));

    final transaction = DustBunniesTransaction(
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

  /// Add DustBunnies (from challenges, etc.)
  Future<void> addCoins(int amount, String reason) async {
    final currentWallet = state.valueOrNull;
    if (currentWallet == null) return;

    // In production, update Firestore
    await Future.delayed(const Duration(milliseconds: 300));

    final transaction = DustBunniesTransaction(
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
  DustBunniesWallet _generateMockWallet(String userId) {
    final now = DateTime.now();

    return DustBunniesWallet(
      userId: userId,
      balance: 450,
      totalEarned: 1250,
      totalSpent: 800,
      recentTransactions: [
        DustBunniesTransaction(
          id: 'tx_001',
          type: TransactionType.earned,
          amount: 50,
          reason: 'Daily Challenge Completed',
          timestamp: now.subtract(const Duration(hours: 2)),
        ),
        DustBunniesTransaction(
          id: 'tx_002',
          type: TransactionType.spent,
          amount: 100,
          reason: 'Lucky Cat Sticker',
          itemId: 'sticker_lucky_cat',
          timestamp: now.subtract(const Duration(hours: 5)),
        ),
        DustBunniesTransaction(
          id: 'tx_003',
          type: TransactionType.earned,
          amount: 25,
          reason: 'Contest Entry Bonus',
          timestamp: now.subtract(const Duration(hours: 8)),
        ),
        DustBunniesTransaction(
          id: 'tx_004',
          type: TransactionType.spent,
          amount: 300,
          reason: 'Fire Border Avatar Frame',
          itemId: 'frame_fire_border',
          timestamp: now.subtract(const Duration(days: 1)),
        ),
        DustBunniesTransaction(
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
final dustBunniesShopProvider =
    StateNotifierProvider<DustBunniesShopNotifier, AsyncValue<List<ShopItem>>>(
  (ref) => DustBunniesShopNotifier(),
);

final dustBunniesWalletProvider = StateNotifierProvider<DustBunniesWalletNotifier,
    AsyncValue<DustBunniesWallet>>((ref) => DustBunniesWalletNotifier(ref));

/// Alias for SweepCoins wallet provider (uses same wallet as DustBunnies)
final sweepCoinsWalletProvider = dustBunniesWalletProvider;

final cosmeticInventoryProvider = StateNotifierProvider<
    CosmeticInventoryNotifier,
    AsyncValue<CosmeticInventory>>((ref) => CosmeticInventoryNotifier());

/// Provider for shop items by type
final shopItemsByTypeProvider =
    Provider.family<List<ShopItem>, ShopItemType>((ref, type) {
  final shopAsync = ref.watch(dustBunniesShopProvider);
  return shopAsync.when(
    data: (items) => items.where((item) => item.type == type).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider for available shop items (not owned)
final availableShopItemsProvider = Provider<List<ShopItem>>((ref) {
  final shopAsync = ref.watch(dustBunniesShopProvider);
  return shopAsync.when(
    data: (items) => items.where((item) => item.isAvailable).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider for limited time items
final limitedTimeItemsProvider = Provider<List<ShopItem>>((ref) {
  final shopAsync = ref.watch(dustBunniesShopProvider);
  return shopAsync.when(
    data: (items) =>
        items.where((item) => item.isLimited && item.isAvailable).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider for user's current balance
final userBalanceProvider = Provider<int>((ref) {
  final walletAsync = ref.watch(dustBunniesWalletProvider);
  return walletAsync.when(
    data: (wallet) => wallet.balance,
    loading: () => 0,
    error: (_, __) => 0,
  );
});
