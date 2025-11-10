import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// SweepCoins shop item for cosmetic purchases
@immutable
class ShopItem {
  const ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.rarity,
    required this.price,
    required this.imageUrl,
    required this.isLimited,
    required this.isOwned,
    required this.isEquipped,
    required this.properties,
    required this.tags,
    this.limitedUntil,
  });

  factory ShopItem.fromJson(Map<String, dynamic> json) => ShopItem(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        type: ShopItemType.values.firstWhere(
          (type) => type.name == json['type'],
          orElse: () => ShopItemType.avatarFrame,
        ),
        rarity: ShopItemRarity.values.firstWhere(
          (rarity) => rarity.name == json['rarity'],
          orElse: () => ShopItemRarity.common,
        ),
        price: json['price'] as int,
        imageUrl: json['imageUrl'] as String? ?? '',
        isLimited: json['isLimited'] as bool? ?? false,
        limitedUntil: json['limitedUntil'] != null
            ? DateTime.parse(json['limitedUntil'] as String)
            : null,
        isOwned: json['isOwned'] as bool? ?? false,
        isEquipped: json['isEquipped'] as bool? ?? false,
        properties: Map<String, dynamic>.from(json['properties'] as Map? ?? {}),
        tags: List<String>.from(json['tags'] as List? ?? []),
      );
  final String id;
  final String name;
  final String description;
  final ShopItemType type;
  final ShopItemRarity rarity;
  final int price; // Price in SweepCoins
  final String imageUrl;
  final bool isLimited;
  final DateTime? limitedUntil;
  final bool isOwned;
  final bool isEquipped;
  final Map<String, dynamic> properties; // Item-specific properties
  final List<String> tags;

  /// Check if item is currently available for purchase
  bool get isAvailable {
    if (isOwned) return false;
    if (!isLimited) return true;
    if (limitedUntil == null) return true;
    return DateTime.now().isBefore(limitedUntil!);
  }

  /// Time remaining for limited items
  String get timeRemaining {
    if (!isLimited || limitedUntil == null) return '';

    final now = DateTime.now();
    if (now.isAfter(limitedUntil!)) return 'Expired';

    final difference = limitedUntil!.difference(now);
    if (difference.inDays > 0) {
      return '${difference.inDays}d ${difference.inHours % 24}h';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    } else {
      return '${difference.inMinutes}m';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'type': type.name,
        'rarity': rarity.name,
        'price': price,
        'imageUrl': imageUrl,
        'isLimited': isLimited,
        'limitedUntil': limitedUntil?.toIso8601String(),
        'isOwned': isOwned,
        'isEquipped': isEquipped,
        'properties': properties,
        'tags': tags,
      };

  ShopItem copyWith({
    String? id,
    String? name,
    String? description,
    ShopItemType? type,
    ShopItemRarity? rarity,
    int? price,
    String? imageUrl,
    bool? isLimited,
    DateTime? limitedUntil,
    bool? isOwned,
    bool? isEquipped,
    Map<String, dynamic>? properties,
    List<String>? tags,
  }) =>
      ShopItem(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        type: type ?? this.type,
        rarity: rarity ?? this.rarity,
        price: price ?? this.price,
        imageUrl: imageUrl ?? this.imageUrl,
        isLimited: isLimited ?? this.isLimited,
        limitedUntil: limitedUntil ?? this.limitedUntil,
        isOwned: isOwned ?? this.isOwned,
        isEquipped: isEquipped ?? this.isEquipped,
        properties: properties ?? this.properties,
        tags: tags ?? this.tags,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShopItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ShopItem(id: $id, name: $name, price: $price, rarity: $rarity)';
}

/// Types of cosmetic items in the shop
enum ShopItemType {
  avatarFrame(
      'Avatar Frame', '🖼️', 'Decorative frames for your profile picture'),
  badge('Badge', '🏅', 'Achievement badges to display on your profile'),
  background('Background', '🎨', 'Custom backgrounds for your profile'),
  theme('Theme', '🌈', 'App color themes and styles'),
  title('Title', '👑', 'Special titles to show under your name'),
  emoji('Emoji Pack', '😄', 'Custom emoji sets for reactions'),
  animation('Animation', '✨', 'Special effects and animations'),
  sticker('Sticker', '🎭', 'Fun stickers for social interactions');

  const ShopItemType(this.displayName, this.emoji, this.description);

  final String displayName;
  final String emoji;
  final String description;
}

/// Rarity levels for shop items
enum ShopItemRarity {
  common('Common', 0xFF9E9E9E, 1.0), // Gray
  uncommon('Uncommon', 0xFF4CAF50, 1.2), // Green
  rare('Rare', 0xFF2196F3, 1.5), // Blue
  epic('Epic', 0xFF9C27B0, 2.0), // Purple
  legendary('Legendary', 0xFFFF9800, 3.0), // Orange
  mythic('Mythic', 0xFFF44336, 5.0); // Red

  const ShopItemRarity(this.displayName, this.color, this.priceMultiplier);

  final String displayName;
  final int color;
  final double priceMultiplier;
}

/// User's SweepCoins wallet and transaction history
@immutable
class SweepCoinsWallet {
  const SweepCoinsWallet({
    required this.userId,
    required this.balance,
    required this.totalEarned,
    required this.totalSpent,
    required this.recentTransactions,
  });

  factory SweepCoinsWallet.fromJson(Map<String, dynamic> json) =>
      SweepCoinsWallet(
        userId: json['userId'] as String,
        balance: json['balance'] as int,
        totalEarned: json['totalEarned'] as int,
        totalSpent: json['totalSpent'] as int,
        recentTransactions: (json['recentTransactions'] as List?)
                ?.map((tx) => SweepCoinsTransaction.fromJson(tx))
                .toList() ??
            [],
      );
  final String userId;
  final int balance;
  final int totalEarned;
  final int totalSpent;
  final List<SweepCoinsTransaction> recentTransactions;

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'balance': balance,
        'totalEarned': totalEarned,
        'totalSpent': totalSpent,
        'recentTransactions':
            recentTransactions.map((tx) => tx.toJson()).toList(),
      };

  SweepCoinsWallet copyWith({
    String? userId,
    int? balance,
    int? totalEarned,
    int? totalSpent,
    List<SweepCoinsTransaction>? recentTransactions,
  }) =>
      SweepCoinsWallet(
        userId: userId ?? this.userId,
        balance: balance ?? this.balance,
        totalEarned: totalEarned ?? this.totalEarned,
        totalSpent: totalSpent ?? this.totalSpent,
        recentTransactions: recentTransactions ?? this.recentTransactions,
      );
}

/// Individual SweepCoins transaction
@immutable
class SweepCoinsTransaction {
  const SweepCoinsTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.reason,
    required this.timestamp,
    this.itemId,
  });

  factory SweepCoinsTransaction.fromJson(Map<String, dynamic> json) =>
      SweepCoinsTransaction(
        id: json['id'] as String,
        type: TransactionType.values.firstWhere(
          (type) => type.name == json['type'],
          orElse: () => TransactionType.earned,
        ),
        amount: json['amount'] as int,
        reason: json['reason'] as String,
        itemId: json['itemId'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
  final String id;
  final TransactionType type;
  final int amount;
  final String reason;
  final String? itemId;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'amount': amount,
        'reason': reason,
        'itemId': itemId,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Types of SweepCoins transactions
enum TransactionType {
  earned(
    'Earned',
    0xFF4CAF50,
    Icons.add_circle,
    'Gained from challenges and activities',
  ),
  spent('Spent', 0xFFF44336, Icons.remove_circle, 'Used to purchase items'),
  gift('Gift', 0xFF9C27B0, Icons.card_giftcard, 'Received as a gift or bonus'),
  refund('Refund', 0xFF2196F3, Icons.refresh, 'Refunded from a purchase');

  const TransactionType(
    this.displayName,
    this.color,
    this.icon,
    this.description,
  );

  final String displayName;
  final int color;
  final IconData icon;
  final String description;
}

/// User's cosmetic inventory
@immutable
class CosmeticInventory {
  // Type -> Item ID

  const CosmeticInventory({
    required this.userId,
    required this.ownedItems,
    required this.equippedItems,
  });

  factory CosmeticInventory.fromJson(Map<String, dynamic> json) =>
      CosmeticInventory(
        userId: json['userId'] as String,
        ownedItems: (json['ownedItems'] as List?)
                ?.map((item) => ShopItem.fromJson(item))
                .toList() ??
            [],
        equippedItems: Map<ShopItemType, String?>.from(
          (json['equippedItems'] as Map?)?.map(
                (key, value) => MapEntry(
                  ShopItemType.values.firstWhere((type) => type.name == key),
                  value as String?,
                ),
              ) ??
              {},
        ),
      );
  final String userId;
  final List<ShopItem> ownedItems;
  final Map<ShopItemType, String?> equippedItems;

  /// Get equipped item of specific type
  ShopItem? getEquippedItem(ShopItemType type) {
    final equippedId = equippedItems[type];
    if (equippedId == null) return null;

    try {
      return ownedItems.firstWhere((item) => item.id == equippedId);
    } catch (e) {
      return null;
    }
  }

  /// Get all items of a specific type
  List<ShopItem> getItemsByType(ShopItemType type) =>
      ownedItems.where((item) => item.type == type).toList();

  /// Check if user owns a specific item
  bool ownsItem(String itemId) => ownedItems.any((item) => item.id == itemId);

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'ownedItems': ownedItems.map((item) => item.toJson()).toList(),
        'equippedItems':
            equippedItems.map((key, value) => MapEntry(key.name, value)),
      };

  CosmeticInventory copyWith({
    String? userId,
    List<ShopItem>? ownedItems,
    Map<ShopItemType, String?>? equippedItems,
  }) =>
      CosmeticInventory(
        userId: userId ?? this.userId,
        ownedItems: ownedItems ?? this.ownedItems,
        equippedItems: equippedItems ?? this.equippedItems,
      );
}
