import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/filter_options.dart';
import '../providers/contest_feed_provider.dart';
import '../providers/filter_providers.dart';

class AdvancedFilterSheet extends ConsumerWidget {
  const AdvancedFilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterOptions = ref.watch(filterOptionsProvider);
    final notifier = ref.read(filterOptionsProvider.notifier);
    final minValueController =
        TextEditingController(text: filterOptions.minPrizeValue.toString() ?? '');
    final maxValueController =
        TextEditingController(text: filterOptions.maxPrizeValue.toString() ?? '');

    return Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
          _buildHeader(context, notifier),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                _buildSortOptions(context, filterOptions, notifier),
                  const SizedBox(height: 24),
                _buildPrizeValueFilter(
                    context, filterOptions, notifier, minValueController, maxValueController,),
                  const SizedBox(height: 24),
                _buildEntryMethodFilter(context, filterOptions, notifier),
                  const SizedBox(height: 24),
                _buildOtherOptions(context, filterOptions, notifier),
                ],
              ),
            ),
          _buildFooter(context, ref, notifier),
          ],
        ),
      );
  }

  Widget _buildHeader(BuildContext context, FilterOptionsNotifier notifier) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border(
          bottom: BorderSide(color: AppColors.primaryLight.withOpacity(0.3)),
          ),
        ),
        child: Row(
          children: [
          const Icon(Icons.tune, color: AppColors.brandCyan, size: 28),
            const SizedBox(width: 12),
            Text(
            'Filters & Sort',
              style: AppTextStyles.headlineSmall.copyWith(color: Colors.white),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );

  Widget _buildSortOptions(BuildContext context, FilterOptions filterOptions,
      FilterOptionsNotifier notifier,) {
    return Consumer(
      builder: (context, ref, child) {
        final hasUnlockedSort = ref.watch(
          FutureProvider((ref) async {
            final unlockService = ref.watch(featureUnlockServiceProvider);
            return await unlockService.hasUnlockedFeature('tool_sort_ending_soon');
          }),
        );

        final isUnlocked = hasUnlockedSort.valueOrNull ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Sort By',
              style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
            ),
            if (!isUnlocked) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warningOrange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.warningOrange,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock,
                      size: 12,
                      color: AppColors.warningOrange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'LOCKED',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.warningOrange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (!isUnlocked)
          _buildLockedSortOverlay(context)
        else
          DropdownButtonFormField<SortOption>(
            initialValue: filterOptions.sortOption,
            onChanged: (value) {
              if (value != null) {
                notifier.setSortOption(value);
              }
            },
            items: SortOption.values
                .map(
                  (option) => DropdownMenuItem(
                    value: option,
                    child: Text(option.label),
                  ),
                )
                .toList(),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.primaryMedium,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            dropdownColor: AppColors.primaryMedium,
            style: const TextStyle(color: Colors.white),
          ),
      ],
    );
      },
    );
  }

  Widget _buildLockedSortOverlay(BuildContext context) {
    return GestureDetector(
      onTap: () => _showUnlockDialog(context, 'Sort by Ending Soon'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryMedium.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.warningOrange.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.lock_outline,
              color: AppColors.warningOrange,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unlock Sorting',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Purchase "Sort by Ending Soon" in the shop to unlock all sorting options',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.brandCyan,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showUnlockDialog(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryDark,
        title: Text(
          'Unlock $featureName',
          style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
        ),
        content: Text(
          'This feature is locked. Purchase it in the shop to unlock all sorting options and maximize your contest entries!',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to shop - you'll need to add this navigation
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandCyan,
            ),
            child: Text(
              'Go to Shop',
              style: TextStyle(color: AppColors.primaryDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrizeValueFilter(
    BuildContext context,
    FilterOptions filterOptions,
    FilterOptionsNotifier notifier,
    TextEditingController minController,
    TextEditingController maxController,
  ) {
    return Consumer(
      builder: (context, ref, child) {
        final hasUnlockedFilter = ref.watch(
          FutureProvider((ref) async {
            final unlockService = ref.watch(featureUnlockServiceProvider);
            return await unlockService.hasUnlockedFeature('tool_filter_pro');
          }),
        );

        final isUnlocked = hasUnlockedFilter.valueOrNull ?? false;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Prize Value (USD)',
                  style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
                ),
                if (!isUnlocked) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warningOrange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.warningOrange,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock,
                          size: 12,
                          color: AppColors.warningOrange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'LOCKED',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.warningOrange,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            if (!isUnlocked)
              _buildLockedFilterOverlay(context)
            else
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Min \$',
                        labelStyle: const TextStyle(color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.primaryMedium,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) => notifier.setPrizeValueRange(
                        double.tryParse(value),
                        filterOptions.maxPrizeValue,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('to', style: TextStyle(color: AppColors.textMuted)),
                  ),
                  Expanded(
                    child: TextField(
                      controller: maxController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Max \$',
                        labelStyle: const TextStyle(color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.primaryMedium,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) => notifier.setPrizeValueRange(
                        filterOptions.minPrizeValue,
                        double.tryParse(value),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildLockedFilterOverlay(BuildContext context) {
    return GestureDetector(
      onTap: () => _showUnlockDialog(context, 'Filter Pro'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryMedium.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.warningOrange.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.lock_outline,
              color: AppColors.warningOrange,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unlock Filters',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Purchase "Filter Pro" in the shop to unlock advanced filtering options',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.brandCyan,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryMethodFilter(BuildContext context,
      FilterOptions filterOptions, FilterOptionsNotifier notifier,) {
    return Consumer(
      builder: (context, ref, child) {
        final hasUnlockedFilter = ref.watch(
          FutureProvider((ref) async {
            final unlockService = ref.watch(featureUnlockServiceProvider);
            return await unlockService.hasUnlockedFeature('tool_filter_pro');
          }),
        );

        final isUnlocked = hasUnlockedFilter.valueOrNull ?? false;
        
        // In a real app, these would come from a config or backend
        const allMethods = {'Gleam', 'Twitter', 'Instagram', 'Website', 'Other'};

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Entry Method',
                  style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
                ),
                if (!isUnlocked) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warningOrange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.warningOrange,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock,
                          size: 12,
                          color: AppColors.warningOrange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'LOCKED',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.warningOrange,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            if (!isUnlocked)
              _buildLockedFilterOverlay(context)
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: allMethods.map((method) {
                  final isSelected = filterOptions.entryMethods.contains(method);
                  return FilterChip(
                    label: Text(method),
                    selected: isSelected,
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      notifier.toggleEntryMethod(method);
                    },
                    backgroundColor: AppColors.primaryMedium,
                    selectedColor: AppColors.brandCyan,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                    ),
                  );
                }).toList(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildOtherOptions(BuildContext context, FilterOptions filterOptions,
      FilterOptionsNotifier notifier,) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              Text(
          'Other Options',
                style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
              ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('No Purchase Necessary',
              style: TextStyle(color: Colors.white),),
          value: filterOptions.requiresPurchase == false,
          onChanged: (value) {
            notifier.setPurchaseRequirement(value ? false : null);
          },
          activeThumbColor: AppColors.brandCyan,
          inactiveTrackColor: AppColors.primaryMedium,
        ),
        SwitchListTile(
          title: const Text("Show Contests I've Entered",
              style: TextStyle(color: Colors.white),),
          value: filterOptions.showEnteredContests,
          onChanged: (value) => notifier.setShowEnteredContests(value),
          activeThumbColor: AppColors.brandCyan,
          inactiveTrackColor: AppColors.primaryMedium,
        ),
      ],
    );

  Widget _buildFooter(BuildContext context, WidgetRef ref, FilterOptionsNotifier notifier) {
    final contestFeed = ref.watch(contestFeedProvider);
    final resultsCount = contestFeed.whenOrNull(data: (contests) => contests.length) ?? 0;

    return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border(
          top: BorderSide(color: AppColors.primaryLight.withOpacity(0.3)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                notifier.clearFilters();
              },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.primaryLight),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Clear All'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
                style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandCyan,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Show $resultsCount Results',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
          ),
          ),
        ],
      ),
    );
  }
}
