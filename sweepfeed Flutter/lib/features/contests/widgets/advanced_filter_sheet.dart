import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/advanced_filter_model.dart';

class AdvancedFilterSheet extends ConsumerStatefulWidget {
  const AdvancedFilterSheet({
    required this.onApply,
    super.key,
    this.currentFilter,
  });
  final AdvancedFilter? currentFilter;
  final Function(AdvancedFilter) onApply;

  @override
  ConsumerState<AdvancedFilterSheet> createState() =>
      _AdvancedFilterSheetState();
}

class _AdvancedFilterSheetState extends ConsumerState<AdvancedFilterSheet> {
  late AdvancedFilter _filter;
  final TextEditingController _brandSearchController = TextEditingController();
  final TextEditingController _minValueController = TextEditingController();
  final TextEditingController _maxValueController = TextEditingController();
  List<String> _allBrands = [];
  List<String> _filteredBrands = [];
  List<String> _favoriteBrands = [];
  bool _isLoadingBrands = true;

  @override
  void initState() {
    super.initState();
    _filter = widget.currentFilter ?? AdvancedFilter();
    _loadBrands();
    _loadFavoriteBrands();
    _brandSearchController.addListener(_filterBrands);
  }

  @override
  void dispose() {
    _brandSearchController.dispose();
    _minValueController.dispose();
    _maxValueController.dispose();
    super.dispose();
  }

  Future<void> _loadBrands() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('contests').get();

      final brands = snapshot.docs
          .map((doc) => doc.data()['sponsor'] as String?)
          .where((sponsor) => sponsor != null && sponsor.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList()
        ..sort();

      setState(() {
        _allBrands = brands;
        _filteredBrands = brands;
        _isLoadingBrands = false;
      });
    } catch (e) {
      setState(() => _isLoadingBrands = false);
    }
  }

  Future<void> _loadFavoriteBrands() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data();
          setState(() {
            _favoriteBrands = List<String>.from(data?['favoriteBrands'] ?? []);
          });
        }
      }
    } catch (e) {
      print('Error loading favorite brands: $e');
    }
  }

  void _filterBrands() {
    final query = _brandSearchController.text.toLowerCase();
    setState(() {
      _filteredBrands = _allBrands
          .where((brand) => brand.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildBrandFilter(),
                  const SizedBox(height: 24),
                  _buildPrizeValueFilter(),
                  const SizedBox(height: 24),
                  _buildPrizeTypeFilter(),
                  const SizedBox(height: 24),
                  _buildSavedFilters(),
                ],
              ),
            ),
            _buildFooter(),
          ],
        ),
      );

  Widget _buildHeader() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
                color: AppColors.primaryLight.withValues(alpha: 0.3)),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.tune, color: AppColors.primary, size: 28),
            const SizedBox(width: 12),
            Text(
              'Advanced Filters',
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

  Widget _buildBrandFilter() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.business, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Brands',
                style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_favoriteBrands.isNotEmpty) ...[
            Text(
              'Your Favorites',
              style:
                  AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _favoriteBrands.map((brand) {
                final isSelected = _filter.selectedBrands.contains(brand);
                return FilterChip(
                  label: Text(brand),
                  selected: isSelected,
                  onSelected: (_) => _toggleBrand(brand),
                  backgroundColor: AppColors.primaryMedium,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textLight,
                  ),
                  avatar: Icon(
                    Icons.star,
                    size: 16,
                    color: isSelected ? Colors.white : AppColors.primary,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _brandSearchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search brands...',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.primaryMedium,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: _isLoadingBrands
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredBrands.length,
                    itemBuilder: (context, index) {
                      final brand = _filteredBrands[index];
                      final isSelected = _filter.selectedBrands.contains(brand);
                      return CheckboxListTile(
                        title: Text(
                          brand,
                          style: const TextStyle(color: Colors.white),
                        ),
                        value: isSelected,
                        onChanged: (_) => _toggleBrand(brand),
                        activeColor: AppColors.primary,
                        checkColor: Colors.white,
                      );
                    },
                  ),
          ),
        ],
      );

  Widget _buildPrizeValueFilter() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.attach_money,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Prize Value Range',
                style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minValueController,
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
                  onChanged: (_) => _updatePrizeRange(),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'to',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _maxValueController,
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
                  onChanged: (_) => _updatePrizeRange(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _buildQuickValueChip('Any', null, null),
              _buildQuickValueChip('\$100+', 100, null),
              _buildQuickValueChip('\$500+', 500, null),
              _buildQuickValueChip('\$1K+', 1000, null),
              _buildQuickValueChip('\$5K+', 5000, null),
              _buildQuickValueChip('\$10K+', 10000, null),
            ],
          ),
        ],
      );

  Widget _buildQuickValueChip(String label, double? min, double? max) {
    final isSelected = _filter.prizeValueRange?.min == min &&
        _filter.prizeValueRange?.max == max;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _filter = _filter.copyWith(
            prizeValueRange: (min != null || max != null)
                ? PrizeValueRange(min: min, max: max)
                : null,
          );
          _minValueController.text = min?.toString() ?? '';
          _maxValueController.text = max?.toString() ?? '';
        });
      },
      backgroundColor: AppColors.primaryMedium,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textLight,
      ),
    );
  }

  Widget _buildPrizeTypeFilter() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.category, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Prize Type',
                style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PrizeType.values.map((type) {
              final isSelected = _filter.selectedPrizeTypes.contains(type);
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
                onSelected: (_) => _togglePrizeType(type),
                backgroundColor: AppColors.primaryMedium,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textLight,
                ),
              );
            }).toList(),
          ),
        ],
      );

  Widget _buildSavedFilters() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bookmark, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Saved Filters',
                style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
              ),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Save Current'),
                onPressed: _saveCurrentFilter,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _loadSavedFilters(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryMedium,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'No saved filters yet',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                );
              }

              return Column(
                children: snapshot.data!
                    .map(
                      (filterData) => ListTile(
                        title: Text(
                          filterData['name'],
                          style: const TextStyle(color: Colors.white),
                        ),
                        leading: const Icon(Icons.filter_list,
                            color: AppColors.primary),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              _deleteSavedFilter(filterData['name']),
                        ),
                        onTap: () => _applySavedFilter(filterData),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      );

  Widget _buildFooter() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
                color: AppColors.primaryLight.withValues(alpha: 0.3)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _clearFilters,
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
                  widget.onApply(_filter);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Apply Filters'),
              ),
            ),
          ],
        ),
      );

  void _toggleBrand(String brand) {
    setState(() {
      final brands = List<String>.from(_filter.selectedBrands);
      if (brands.contains(brand)) {
        brands.remove(brand);
      } else {
        brands.add(brand);
      }
      _filter = _filter.copyWith(selectedBrands: brands);
    });
  }

  void _togglePrizeType(PrizeType type) {
    setState(() {
      final types = List<PrizeType>.from(_filter.selectedPrizeTypes);
      if (types.contains(type)) {
        types.remove(type);
      } else {
        types.add(type);
      }
      _filter = _filter.copyWith(selectedPrizeTypes: types);
    });
  }

  void _updatePrizeRange() {
    final min = double.tryParse(_minValueController.text);
    final max = double.tryParse(_maxValueController.text);

    setState(() {
      _filter = _filter.copyWith(
        prizeValueRange: (min != null || max != null)
            ? PrizeValueRange(min: min, max: max)
            : null,
      );
    });
  }

  void _clearFilters() {
    setState(() {
      _filter = AdvancedFilter();
      _minValueController.clear();
      _maxValueController.clear();
      _brandSearchController.clear();
    });
  }

  Future<void> _saveCurrentFilter() async {
    final name = await _showSaveFilterDialog();
    if (name == null || name.isEmpty) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final filterData = _filter.copyWith(savedFilterName: name).toJson();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('savedFilters')
          .doc(name)
          .set(filterData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Filter saved as "$name"')),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save filter: $e')),
        );
      }
    }
  }

  Future<String?> _showSaveFilterDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryDark,
        title: const Text('Save Filter', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Filter name',
            hintStyle: const TextStyle(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.primaryMedium,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadSavedFilters() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('savedFilters')
          .get();

      return snapshot.docs
          .map((doc) => {'name': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      return [];
    }
  }

  void _applySavedFilter(Map<String, dynamic> filterData) {
    setState(() {
      _filter = AdvancedFilter.fromJson(filterData);
      _minValueController.text = _filter.prizeValueRange?.min?.toString() ?? '';
      _maxValueController.text = _filter.prizeValueRange?.max?.toString() ?? '';
    });
  }

  Future<void> _deleteSavedFilter(String name) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('savedFilters')
          .doc(name)
          .delete();

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Filter "$name" deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete filter: $e')),
        );
      }
    }
  }
}
