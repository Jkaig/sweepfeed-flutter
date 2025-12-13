import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/models/brand_model.dart';
import '../../../core/services/brand_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_back_button.dart';

class BrandSelectionScreen extends StatefulWidget {
  const BrandSelectionScreen({
    super.key,
    this.selectedBrandNames = const [],
  });
  final List<String> selectedBrandNames;

  @override
  State<BrandSelectionScreen> createState() => _BrandSelectionScreenState();
}

class _BrandSelectionScreenState extends State<BrandSelectionScreen> {
  final BrandService _brandService = BrandService();
  final TextEditingController _searchController = TextEditingController();

  List<Brand> _allBrands = [];
  List<Brand> _filteredBrands = [];
  Set<String> _selectedBrandNames = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedBrandNames = Set.from(widget.selectedBrandNames);
    _loadBrands();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBrands() async {
    setState(() => _isLoading = true);

    try {
      final brands = await _brandService.getBrandsFromSponsors();
      setState(() {
        _allBrands = brands;
        _filteredBrands = brands;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading brands: $e')),
        );
      }
    }
  }

  void _filterBrands(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredBrands = _allBrands;
      } else {
        _filteredBrands = _allBrands
            .where((brand) =>
                brand.name.toLowerCase().contains(query.toLowerCase()),)
            .toList();
      }
    });
  }

  void _toggleBrand(String brandName) {
    setState(() {
      if (_selectedBrandNames.contains(brandName)) {
        _selectedBrandNames.remove(brandName);
      } else {
        _selectedBrandNames.add(brandName);
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.primaryDark,
        appBar: CustomAppBar(
          title: 'Select Favorite Brands',
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
                  Navigator.pop(context, _selectedBrandNames.toList());
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
                    onChanged: _filterBrands,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search brands or sponsors...',
                      hintStyle: const TextStyle(color: AppColors.textLight),
                      prefixIcon:
                          const Icon(Icons.search, color: AppColors.brandCyan),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear,
                                  color: AppColors.textLight,),
                              onPressed: () {
                                _searchController.clear();
                                _filterBrands('');
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
                            color: AppColors.brandCyan, width: 2,),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${_selectedBrandNames.length} brands selected',
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
                  : _filteredBrands.isEmpty
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
                                'No brands found',
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
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: _filteredBrands.length,
                          itemBuilder: (context, index) {
                            final brand = _filteredBrands[index];
                            final isSelected =
                                _selectedBrandNames.contains(brand.name);

                            return GestureDetector(
                              onTap: () => _toggleBrand(brand.name),
                              child: Column(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.brandCyan
                                            : AppColors.primaryLight
                                                .withValues(alpha: 0.3),
                                        width: isSelected ? 3 : 2,
                                      ),
                                      color: AppColors.primaryMedium,
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: AppColors.brandCyan
                                                    .withValues(alpha: 0.3),
                                                blurRadius: 8,
                                                spreadRadius: 2,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: ClipOval(
                                      child: brand.logoUrl != null
                                          ? CachedNetworkImage(
                                              imageUrl: brand.logoUrl!,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: AppColors.brandCyan,
                                                ),
                                              ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      Center(
                                                child: Text(
                                                  brand.name
                                                      .substring(0, 1)
                                                      .toUpperCase(),
                                                  style: const TextStyle(
                                                    color: AppColors.brandCyan,
                                                    fontSize: 32,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : Center(
                                              child: Text(
                                                brand.name
                                                    .substring(0, 1)
                                                    .toUpperCase(),
                                                style: const TextStyle(
                                                  color: AppColors.brandCyan,
                                                  fontSize: 32,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    brand.name,
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
                            );
                          },
                        ),
            ),
          ],
        ),
      );
}
