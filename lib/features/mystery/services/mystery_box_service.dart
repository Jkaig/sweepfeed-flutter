import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/services/dust_bunnies_service.dart';

import '../../../core/utils/logger.dart';

class MysteryBoxService extends ChangeNotifier {
  MysteryBoxService(this._dustBunniesService);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DustBunniesService _dustBunniesService;
  final _random = math.Random();

  // Mystery box types and rarities
  static const Map<MysteryBoxType, BoxConfig> boxConfigs = {
    MysteryBoxType.common: BoxConfig(
      name: 'Common Box',
      cost: 100,
      color: Color(0xFF9E9E9E),
      minRewards: 1,
      maxRewards: 2,
      commonChance: 70,
      rareChance: 25,
      epicChance: 5,
      legendaryChance: 0,
    ),
    MysteryBoxType.rare: BoxConfig(
      name: 'Rare Box',
      cost: 500,
      color: Color(0xFF2196F3),
      minRewards: 2,
      maxRewards: 3,
      commonChance: 40,
      rareChance: 40,
      epicChance: 18,
      legendaryChance: 2,
    ),
    MysteryBoxType.epic: BoxConfig(
      name: 'Epic Box',
      cost: 1500,
      color: Color(0xFF9C27B0),
      minRewards: 2,
      maxRewards: 4,
      commonChance: 20,
      rareChance: 35,
      epicChance: 35,
      legendaryChance: 10,
    ),
    MysteryBoxType.legendary: BoxConfig(
      name: 'Legendary Box',
      cost: 5000,
      color: Color(0xFFFF9800),
      minRewards: 3,
      maxRewards: 5,
      commonChance: 10,
      rareChance: 25,
      epicChance: 40,
      legendaryChance: 25,
    ),
  };

  // Possible rewards
  static final List<MysteryReward> possibleRewards = [
    // Common rewards
    const MysteryReward(
      id: 'db_small',
      name: '50 DB',
      type: RewardType.dustBunnies,
      value: 50,
      rarity: Rarity.common,
    ),
    const MysteryReward(
      id: 'entries_1',
      name: '1 Bonus Entry',
      type: RewardType.entries,
      value: 1,
      rarity: Rarity.common,
    ),
    const MysteryReward(
      id: 'coins_100',
      name: '100 Coins',
      type: RewardType.coins,
      value: 100,
      rarity: Rarity.common,
    ),

    // Rare rewards
    const MysteryReward(
      id: 'db_medium',
      name: '200 DB',
      type: RewardType.dustBunnies,
      value: 200,
      rarity: Rarity.rare,
    ),
    const MysteryReward(
      id: 'entries_5',
      name: '5 Bonus Entries',
      type: RewardType.entries,
      value: 5,
      rarity: Rarity.rare,
    ),
    const MysteryReward(
      id: 'coins_500',
      name: '500 Coins',
      type: RewardType.coins,
      value: 500,
      rarity: Rarity.rare,
    ),
    const MysteryReward(
      id: 'streak_freeze',
      name: 'Streak Freeze',
      type: RewardType.streakFreeze,
      value: 1,
      rarity: Rarity.rare,
    ),

    // Epic rewards
    const MysteryReward(
      id: 'db_large',
      name: '500 DB',
      type: RewardType.dustBunnies,
      value: 500,
      rarity: Rarity.epic,
    ),
    const MysteryReward(
      id: 'entries_15',
      name: '15 Bonus Entries',
      type: RewardType.entries,
      value: 15,
      rarity: Rarity.epic,
    ),
    const MysteryReward(
      id: 'coins_2000',
      name: '2000 Coins',
      type: RewardType.coins,
      value: 2000,
      rarity: Rarity.epic,
    ),
    const MysteryReward(
      id: 'db_booster_2x',
      name: '2x DB Booster (1hr)',
      type: RewardType.dustBunniesBooster,
      value: 2,
      rarity: Rarity.epic,
    ),
    const MysteryReward(
      id: 'premium_1d',
      name: '1 Day Premium',
      type: RewardType.premium,
      value: 1,
      rarity: Rarity.epic,
    ),

    // Legendary rewards
    const MysteryReward(
      id: 'db_mega',
      name: '2000 DB',
      type: RewardType.dustBunnies,
      value: 2000,
      rarity: Rarity.legendary,
    ),
    const MysteryReward(
      id: 'entries_50',
      name: '50 Bonus Entries',
      type: RewardType.entries,
      value: 50,
      rarity: Rarity.legendary,
    ),
    const MysteryReward(
      id: 'coins_10000',
      name: '10,000 Coins',
      type: RewardType.coins,
      value: 10000,
      rarity: Rarity.legendary,
    ),
    const MysteryReward(
      id: 'db_booster_3x',
      name: '3x DB Booster (3hr)',
      type: RewardType.dustBunniesBooster,
      value: 3,
      rarity: Rarity.legendary,
    ),
    const MysteryReward(
      id: 'premium_7d',
      name: '7 Days Premium',
      type: RewardType.premium,
      value: 7,
      rarity: Rarity.legendary,
    ),
    const MysteryReward(
      id: 'mystery_box_epic',
      name: 'Free Epic Box',
      type: RewardType.mysteryBox,
      value: 1,
      rarity: Rarity.legendary,
    ),
  ];

  // Get user's mystery box inventory
  Future<Map<MysteryBoxType, int>> getUserBoxInventory(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return {};

      final data = userDoc.data()!;
      final mysteryData = data['mysteryBoxes'] as Map<String, dynamic>? ?? {};

      return {
        MysteryBoxType.common: mysteryData['common'] ?? 0,
        MysteryBoxType.rare: mysteryData['rare'] ?? 0,
        MysteryBoxType.epic: mysteryData['epic'] ?? 0,
        MysteryBoxType.legendary: mysteryData['legendary'] ?? 0,
      };
    } catch (e) {
      logger.e('Error getting box inventory', error: e);
      return {};
    }
  }

  // Get user's coins
  Future<int> getUserCoins(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return 0;

      final data = userDoc.data()!;
      return data['coins'] ?? 0;
    } catch (e) {
      logger.e('Error getting user coins', error: e);
      return 0;
    }
  }

  // Purchase mystery box with coins
  Future<PurchaseResult> purchaseBox(
    String userId,
    MysteryBoxType boxType,
  ) async {
    try {
      final config = boxConfigs[boxType]!;
      final userCoins = await getUserCoins(userId);

      if (userCoins < config.cost) {
        return PurchaseResult(
          success: false,
          message: 'Not enough coins! Need ${config.cost} coins.',
        );
      }

      // Deduct coins and add box to inventory
      await _firestore.collection('users').doc(userId).update({
        'coins': FieldValue.increment(-config.cost),
        'mysteryBoxes.${boxType.name}': FieldValue.increment(1),
      });

      // Log purchase
      await _logBoxActivity(userId, 'purchase', boxType, null);

      notifyListeners();

      return PurchaseResult(
        success: true,
        message: 'Mystery box purchased!',
        boxType: boxType,
      );
    } catch (e) {
      logger.e('Error purchasing box', error: e);
      return PurchaseResult(
        success: false,
        message: 'Purchase failed. Please try again.',
      );
    }
  }

  // Open mystery box
  Future<OpenBoxResult> openBox(String userId, MysteryBoxType boxType) async {
    try {
      // Check if user has the box
      final inventory = await getUserBoxInventory(userId);
      if ((inventory[boxType] ?? 0) <= 0) {
        return OpenBoxResult(
          success: false,
          message: "You don't have any ${boxConfigs[boxType]!.name}s!",
          rewards: [],
        );
      }

      // Generate rewards
      final rewards = _generateRewards(boxType);

      // Apply rewards to user
      await _applyRewards(userId, rewards);

      // Remove box from inventory
      await _firestore.collection('users').doc(userId).update({
        'mysteryBoxes.${boxType.name}': FieldValue.increment(-1),
      });

      // Log opening
      await _logBoxActivity(userId, 'open', boxType, rewards);

      // Track statistics
      await _updateBoxStatistics(userId, boxType, rewards);

      notifyListeners();

      return OpenBoxResult(
        success: true,
        message: 'Box opened successfully!',
        rewards: rewards,
        boxType: boxType,
      );
    } catch (e) {
      logger.e('Error opening box', error: e);
      return OpenBoxResult(
        success: false,
        message: 'Failed to open box. Please try again.',
        rewards: [],
      );
    }
  }

  // Generate rewards based on box type
  List<MysteryReward> _generateRewards(MysteryBoxType boxType) {
    final config = boxConfigs[boxType]!;
    final numRewards = config.minRewards +
        _random.nextInt(config.maxRewards - config.minRewards + 1);

    final rewards = <MysteryReward>[];

    for (var i = 0; i < numRewards; i++) {
      // Determine rarity based on chances
      final rarity = _determineRarity(config);

      // Get all possible rewards of this rarity
      final possibleRewardsOfRarity =
          possibleRewards.where((r) => r.rarity == rarity).toList();

      if (possibleRewardsOfRarity.isNotEmpty) {
        // Pick random reward
        final reward = possibleRewardsOfRarity[
            _random.nextInt(possibleRewardsOfRarity.length)];
        rewards.add(reward);
      }
    }

    return rewards;
  }

  // Determine rarity based on box configuration
  Rarity _determineRarity(BoxConfig config) {
    final roll = _random.nextInt(100);

    if (roll < config.legendaryChance) return Rarity.legendary;
    if (roll < config.legendaryChance + config.epicChance) return Rarity.epic;
    if (roll < config.legendaryChance + config.epicChance + config.rareChance) {
      return Rarity.rare;
    }
    return Rarity.common;
  }

  // Apply rewards to user account
  Future<void> _applyRewards(String userId, List<MysteryReward> rewards) async {
    for (final reward in rewards) {
      switch (reward.type) {
        case RewardType.dustBunnies:
          await _dustBunniesService.awardDustBunnies(
            userId: userId,
            action: 'mystery_box_open',
            customAmount: reward.value,
          );
          break;

        case RewardType.entries:
          await _firestore.collection('users').doc(userId).update({
            'bonusEntries': FieldValue.increment(reward.value),
          });
          break;

        case RewardType.coins:
          await _firestore.collection('users').doc(userId).update({
            'coins': FieldValue.increment(reward.value),
          });
          break;

        case RewardType.streakFreeze:
          await _firestore.collection('users').doc(userId).update({
            'streaks.freezesAvailable': FieldValue.increment(reward.value),
          });
          break;

        case RewardType.dustBunniesBooster:
          final duration = Duration(hours: reward.value == 2 ? 1 : 3);
          await _dustBunniesService.applyDustBunniesBooster(
            userId,
            reward.value.toDouble(),
            duration,
          );
          break;

        case RewardType.premium:
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('rewards')
              .add({
            'type': 'premium_days',
            'days': reward.value,
            'source': 'mystery_box',
            'claimed': false,
            'timestamp': FieldValue.serverTimestamp(),
          });
          break;

        case RewardType.mysteryBox:
          await _firestore.collection('users').doc(userId).update({
            'mysteryBoxes.epic': FieldValue.increment(reward.value),
          });
          break;
      }
    }
  }

  // Log box activity
  Future<void> _logBoxActivity(
    String userId,
    String action,
    MysteryBoxType boxType,
    List<MysteryReward>? rewards,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('mysteryBoxHistory')
          .add({
        'action': action,
        'boxType': boxType.name,
        'rewards': rewards
            ?.map(
              (r) => {
                'id': r.id,
                'name': r.name,
                'value': r.value,
                'rarity': r.rarity.name,
              },
            )
            .toList(),
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      logger.e('Error logging box activity', error: e);
    }
  }

  // Update box opening statistics
  Future<void> _updateBoxStatistics(
    String userId,
    MysteryBoxType boxType,
    List<MysteryReward> rewards,
  ) async {
    try {
      final statsUpdate = {
        'mysteryBoxStats.totalOpened': FieldValue.increment(1),
        'mysteryBoxStats.${boxType.name}Opened': FieldValue.increment(1),
      };

      // Count rarities
      for (final reward in rewards) {
        statsUpdate['mysteryBoxStats.${reward.rarity.name}Count'] =
            FieldValue.increment(1);
      }

      await _firestore.collection('users').doc(userId).update(statsUpdate);
    } catch (e) {
      logger.e('Error updating box statistics', error: e);
    }
  }

  // Award free daily box
  Future<bool> claimDailyBox(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final data = userDoc.data()!;
      final lastClaim = data['lastDailyBoxClaim'] as Timestamp?;

      if (lastClaim != null) {
        final now = DateTime.now();
        final lastClaimDate = lastClaim.toDate();
        final difference = now.difference(lastClaimDate);

        if (difference.inHours < 24) {
          return false; // Already claimed today
        }
      }

      // Award daily box (common)
      await _firestore.collection('users').doc(userId).update({
        'mysteryBoxes.common': FieldValue.increment(1),
        'lastDailyBoxClaim': FieldValue.serverTimestamp(),
      });

      notifyListeners();
      return true;
    } catch (e) {
      logger.e('Error claiming daily box', error: e);
      return false;
    }
  }
}

// Models and Enums
enum MysteryBoxType { common, rare, epic, legendary }

enum Rarity { common, rare, epic, legendary }

enum RewardType {
  dustBunnies,
  entries,
  coins,
  streakFreeze,
  dustBunniesBooster,
  premium,
  mysteryBox;

  /// @deprecated Use dustBunnies instead. SweepPoints is now DustBunnies (DB).
  @Deprecated('Use dustBunnies instead. SweepPoints is now DustBunnies (DB).')
  static RewardType get sweepPoints => dustBunnies;

  /// @deprecated Use dustBunniesBooster instead. SweepPoints is now DustBunnies (DB).
  @Deprecated(
      'Use dustBunniesBooster instead. SweepPoints is now DustBunnies (DB).',)
  static RewardType get sweepPointsBooster => dustBunniesBooster;
}

class BoxConfig {
  const BoxConfig({
    required this.name,
    required this.cost,
    required this.color,
    required this.minRewards,
    required this.maxRewards,
    required this.commonChance,
    required this.rareChance,
    required this.epicChance,
    required this.legendaryChance,
  });
  final String name;
  final int cost;
  final Color color;
  final int minRewards;
  final int maxRewards;
  final int commonChance;
  final int rareChance;
  final int epicChance;
  final int legendaryChance;
}

class MysteryReward {
  const MysteryReward({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    required this.rarity,
  });
  final String id;
  final String name;
  final RewardType type;
  final int value;
  final Rarity rarity;
}

class PurchaseResult {
  PurchaseResult({
    required this.success,
    required this.message,
    this.boxType,
  });
  final bool success;
  final String message;
  final MysteryBoxType? boxType;
}

class OpenBoxResult {
  OpenBoxResult({
    required this.success,
    required this.message,
    required this.rewards,
    this.boxType,
  });
  final bool success;
  final String message;
  final List<MysteryReward> rewards;
  final MysteryBoxType? boxType;
}
