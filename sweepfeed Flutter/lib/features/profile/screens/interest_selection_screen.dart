import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/models/category_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_back_button.dart';

class InterestSelectionScreen extends StatefulWidget {
  const InterestSelectionScreen({
    super.key,
    this.selectedInterests = const [],
  });
  final List<String> selectedInterests;

  @override
  State<InterestSelectionScreen> createState() =>
      _InterestSelectionScreenState();
}

class _InterestSelectionScreenState extends State<InterestSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Category> _allCategories = [];
  List<Category> _filteredCategories = [];
  Set<String> _selectedInterests = {};
  bool _isLoading = true;

  final List<Map<String, String>> _defaultInterests = [
    {'name': 'Cash & Money', 'emoji': '💰'},
    {'name': 'Electronics', 'emoji': '📱'},
    {'name': 'Travel', 'emoji': '✈️'},
    {'name': 'Gift Cards', 'emoji': '🎁'},
    {'name': 'Cars & Vehicles', 'emoji': '🚗'},
    {'name': 'Home & Garden', 'emoji': '🏡'},
    {'name': 'Fashion & Beauty', 'emoji': '👗'},
    {'name': 'Sports & Fitness', 'emoji': '⚽'},
    {'name': 'Gaming', 'emoji': '🎮'},
    {'name': 'Food & Dining', 'emoji': '🍔'},
    {'name': 'Entertainment', 'emoji': '🎬'},
    {'name': 'Books & Education', 'emoji': '📚'},
    {'name': 'Pets', 'emoji': '🐾'},
    {'name': 'Music', 'emoji': '🎵'},
    {'name': 'Art & Crafts', 'emoji': '🎨'},
    {'name': 'Health & Wellness', 'emoji': '💪'},
    {'name': 'Technology', 'emoji': '💻'},
    {'name': 'Outdoor & Adventure', 'emoji': '🏕️'},
    {'name': 'Jewelry & Accessories', 'emoji': '💎'},
    {'name': 'Baby & Kids', 'emoji': '👶'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedInterests = Set.from(widget.selectedInterests);
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);

    try {
      final querySnapshot = await _firestore
          .collection('categories')
          .orderBy('popularity', descending: true)
          .get();

      var categories = querySnapshot.docs.map(Category.fromFirestore).toList();

      if (categories.isEmpty) {
        categories = _defaultInterests
            .map(
              (interest) => Category(
                id: interest['name']!.toLowerCase().replaceAll(' ', '_'),
                name: interest['name']!,
                emoji: interest['emoji']!,
              ),
            )
            .toList();
      }

      setState(() {
        _allCategories = categories;
        _filteredCategories = categories;
        _isLoading = false;
      });
    } catch (e) {
      final defaultCategories = _defaultInterests
          .map(
            (interest) => Category(
              id: interest['name']!.toLowerCase().replaceAll(' ', '_'),
              name: interest['name']!,
              emoji: interest['emoji']!,
            ),
          )
          .toList();

      setState(() {
        _allCategories = defaultCategories;
        _filteredCategories = defaultCategories;
        _isLoading = false;
      });
    }
  }

  void _filterCategories(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCategories = _allCategories;
      } else {
        _filteredCategories = _allCategories
            .where((category) =>
                category.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _toggleInterest(String interestName) {
    setState(() {
      if (_selectedInterests.contains(interestName)) {
        _selectedInterests.remove(interestName);
      } else {
        _selectedInterests.add(interestName);
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.primaryDark,
        appBar: CustomAppBar(
          title: 'Select Interests',
          leading: const CustomBackButton(),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: AppColors.brandCyan.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.brandCyan.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context, _selectedInterests.toList());
                },
                tooltip: 'Done',
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: _filterCategories,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search interests...',
                      hintStyle: const TextStyle(color: AppColors.textLight),
                      prefixIcon:
                          const Icon(Icons.search, color: AppColors.brandCyan),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear,
                                  color: AppColors.textLight),
                              onPressed: () {
                                _searchController.clear();
                                _filterCategories('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.primaryLight.withValues(alpha: 0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.brandCyan, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${_selectedInterests.length} interests selected',
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredCategories.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: AppColors.textLight,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No interests found',
                                style: TextStyle(
                                  color: AppColors.textLight,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.9,
                          ),
                          itemCount: _filteredCategories.length,
                          itemBuilder: (context, index) {
                            final category = _filteredCategories[index];
                            final isSelected =
                                _selectedInterests.contains(category.name);

                            return GestureDetector(
                              onTap: () => _toggleInterest(category.name),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.brandCyan
                                          .withValues(alpha: 0.2)
                                      : AppColors.primaryMedium,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.brandCyan
                                        : AppColors.primaryLight
                                            .withValues(alpha: 0.3),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: AppColors.brandCyan
                                                .withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      category.emoji,
                                      style: const TextStyle(fontSize: 40),
                                    ),
                                    const SizedBox(height: 8),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: Text(
                                        category.name,
                                        style: TextStyle(
                                          color: isSelected
                                              ? AppColors.brandCyan
                                              : Colors.white,
                                          fontSize: 12,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isSelected)
                                      const Padding(
                                        padding: EdgeInsets.only(top: 4),
                                        child: Icon(
                                          Icons.check_circle,
                                          color: AppColors.brandCyan,
                                          size: 16,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      );
}
