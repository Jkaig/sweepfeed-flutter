import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../models/advanced_filter_model.dart';

class FilterBottomSheet extends ConsumerStatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  RangeValues _prizeValueRange = const RangeValues(0, 10000);
  List<String> _selectedCategories = [];
  List<PrizeType> _selectedPrizeTypes = [];

  @override
  void initState() {
    super.initState();
    final currentFilter = ref.read(advancedFilterProvider);
    if (currentFilter != null) {
      _prizeValueRange = RangeValues(
        currentFilter.prizeValueRange?.min ?? 0,
        currentFilter.prizeValueRange?.max ?? 10000,
      );
      _selectedCategories = List.from(currentFilter.selectedCategories);
      _selectedPrizeTypes = List.from(currentFilter.selectedPrizeTypes);
    }
  }

  void _applyFilters() {
    final filter = AdvancedFilter(
      selectedCategories: _selectedCategories,
      selectedPrizeTypes: _selectedPrizeTypes,
      prizeValueRange: PrizeValueRange(
        min: _prizeValueRange.start,
        max: _prizeValueRange.end,
      ),
    );

    ref.read(advancedFilterProvider.notifier).state = filter;

    ref.read(analyticsServiceProvider).logFilterApplied(filters: {
      'categories_count': _selectedCategories.length,
      'prize_types_count': _selectedPrizeTypes.length,
      'min_prize': _prizeValueRange.start.round(),
      'max_prize': _prizeValueRange.end.round(),
    },);

    Navigator.of(context).pop(filter);
  }

  void _clearFilters() {
    setState(() {
      _prizeValueRange = const RangeValues(0, 10000);
      _selectedCategories.clear();
      _selectedPrizeTypes.clear();
    });
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.primaryMedium,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filters',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(color: Colors.white),
                  ),
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text(
                      'Clear All',
                      style: TextStyle(color: AppColors.accent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildPrizeValueSlider(),
              const SizedBox(height: 24),
              _buildPrizeTypeSelection(),
              const SizedBox(height: 24),
              _buildCategorySelection(),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        side: const BorderSide(color: AppColors.accent),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _applyFilters,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: AppColors.accent,
                      ),
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildPrizeValueSlider() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Prize Value: \$${_prizeValueRange.start.round()} - \$${_prizeValueRange.end.round()}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold,),
          ),
          const SizedBox(height: 8),
          RangeSlider(
            values: _prizeValueRange,
            max: 10000,
            divisions: 100,
            activeColor: AppColors.accent,
            inactiveColor: AppColors.primaryLight,
            labels: RangeLabels(
              '\$${_prizeValueRange.start.round()}',
              '\$${_prizeValueRange.end.round()}',
            ),
            onChanged: (values) {
              setState(() {
                _prizeValueRange = values;
              });
            },
          ),
        ],
      );

  Widget _buildPrizeTypeSelection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Prize Types',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PrizeType.values.map((type) {
              final isSelected = _selectedPrizeTypes.contains(type);
              return FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(type.emoji),
                    const SizedBox(width: 4),
                    Text(type.label),
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedPrizeTypes.add(type);
                    } else {
                      _selectedPrizeTypes.remove(type);
                    }
                  });
                },
                selectedColor: AppColors.accent.withValues(alpha: 0.3),
                checkmarkColor: AppColors.accent,
                backgroundColor: AppColors.primaryLight,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textLight,
                ),
              );
            }).toList(),
          ),
        ],
      );

  Widget _buildCategorySelection() {
    final categories = ref.watch(categoriesProvider);

    return categories.when(
      data: (categoryList) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Categories',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categoryList.map((category) {
              final isSelected = _selectedCategories.contains(category.id);
              return FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(category.emoji),
                    const SizedBox(width: 4),
                    Text(category.name),
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedCategories.add(category.id);
                    } else {
                      _selectedCategories.remove(category.id);
                    }
                  });
                },
                selectedColor: AppColors.accent.withValues(alpha: 0.3),
                checkmarkColor: AppColors.accent,
                backgroundColor: AppColors.primaryLight,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textLight,
                ),
              );
            }).toList(),
          ),
        ],
      ),
      loading: () => const CircularProgressIndicator(color: AppColors.accent),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}
