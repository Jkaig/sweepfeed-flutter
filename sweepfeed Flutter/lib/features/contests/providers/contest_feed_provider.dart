import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/contest_model.dart';
import '../../../core/providers/providers.dart';
import '../models/advanced_filter_model.dart';

final baseContestFeedProvider = FutureProvider<List<Contest>>((ref) async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('contests')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();

    return snapshot.docs
        .map((doc) => Contest.fromMap(doc.data(), doc.id))
        .toList();
  } catch (error) {
    throw Exception('Failed to load contests: $error');
  }
});

final contestFeedProvider = FutureProvider<List<Contest>>((ref) async {
  final contests = await ref.watch(baseContestFeedProvider.future);
  final activeFilter = ref.watch(activeContestFilterProvider);
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase().trim();
  final advancedFilter = ref.watch(advancedFilterProvider);

  var filtered = contests;

  // Apply advanced filters first
  if (advancedFilter != null && !advancedFilter.isEmpty) {
    // Filter by brands
    if (advancedFilter.selectedBrands.isNotEmpty) {
      filtered = filtered
          .where(
            (c) => advancedFilter.selectedBrands.contains(c.sponsor),
          )
          .toList();
    }

    // Filter by prize value range
    if (advancedFilter.prizeValueRange != null) {
      final range = advancedFilter.prizeValueRange!;
      filtered = filtered.where((c) {
        final value = c.value ?? 0;
        if (range.min != null && value < range.min!) return false;
        if (range.max != null && value > range.max!) return false;
        return true;
      }).toList();
    }

    // Filter by prize types
    if (advancedFilter.selectedPrizeTypes.isNotEmpty) {
      filtered = filtered.where((c) {
        final prize = c.prize.toLowerCase();
        return advancedFilter.selectedPrizeTypes.any((type) {
          switch (type) {
            case PrizeType.cash:
              return prize.contains('cash') ||
                  prize.contains('\$') ||
                  prize.contains('money');
            case PrizeType.electronics:
              return prize.contains('phone') ||
                  prize.contains('laptop') ||
                  prize.contains('tablet') ||
                  prize.contains('tv') ||
                  prize.contains('electronics');
            case PrizeType.travel:
              return prize.contains('trip') ||
                  prize.contains('travel') ||
                  prize.contains('vacation') ||
                  prize.contains('flight');
            case PrizeType.giftCard:
              return prize.contains('gift card') || prize.contains('giftcard');
            case PrizeType.vehicle:
              return prize.contains('car') ||
                  prize.contains('vehicle') ||
                  prize.contains('truck') ||
                  prize.contains('suv');
            case PrizeType.experience:
              return prize.contains('experience') ||
                  prize.contains('tickets') ||
                  prize.contains('concert') ||
                  prize.contains('event');
            case PrizeType.merchandise:
              return prize.contains('product') || prize.contains('merch');
            case PrizeType.other:
              return true;
          }
        });
      }).toList();
    }

    // Filter by categories
    if (advancedFilter.selectedCategories.isNotEmpty) {
      filtered = filtered
          .where(
            (c) => c.categories.any(advancedFilter.selectedCategories.contains),
          )
          .toList();
    }
  }

  // Apply search query
  if (searchQuery.isNotEmpty) {
    filtered = filtered.where((contest) {
      final title = contest.title.toLowerCase();
      final sponsor = contest.sponsor.toLowerCase();
      final prize = contest.prize.toLowerCase();
      final category = contest.category.toLowerCase();

      return title.contains(searchQuery) ||
          sponsor.contains(searchQuery) ||
          prize.contains(searchQuery) ||
          category.contains(searchQuery);
    }).toList();
  }

  // Apply quick filters
  switch (activeFilter) {
    case 'highValue':
      filtered = filtered.where((c) => (c.value ?? 0) >= 1000).toList();
      filtered.sort((a, b) => (b.value ?? 0).compareTo(a.value ?? 0));
      break;
    case 'endingSoon':
      final now = DateTime.now();
      final cutoff = now.add(const Duration(days: 7));
      filtered = filtered
          .where((c) => c.endDate.isAfter(now) && c.endDate.isBefore(cutoff))
          .toList();
      filtered.sort((a, b) => a.endDate.compareTo(b.endDate));
      break;
    case 'dailyEntry':
      filtered = filtered.where((c) {
        final frequency = c.frequency.toLowerCase() ?? '';
        return frequency.contains('daily') || frequency.contains('day');
      }).toList();
      break;
    case 'easyEntry':
      filtered = filtered.where((c) {
        final frequency = c.frequency.toLowerCase() ?? '';
        return frequency == 'one-time' ||
            frequency == 'once' ||
            frequency == 'single' ||
            frequency.contains('one time') ||
            frequency.contains('1 time') ||
            frequency.contains('1x');
      }).toList();
      break;
    case 'trending':
      filtered.sort((a, b) {
        final aScore = (a.likes * 2) + (a.entryCount ?? 0);
        final bScore = (b.likes * 2) + (b.entryCount ?? 0);
        return bScore.compareTo(aScore);
      });
      filtered = filtered.take(20).toList();
      break;
    case 'newToday':
      final now = DateTime.now();
      filtered = filtered.where((c) {
        final difference = now.difference(c.createdAt);
        return difference.inHours < 24;
      }).toList();
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      break;
    default:
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  return filtered;
});
