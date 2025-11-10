import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/category_model.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_indicator.dart';

class InterestSelectionScreen extends ConsumerWidget {
  const InterestSelectionScreen({
    required this.onNext,
    super.key,
  });
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedInterests = ref.watch(selectedInterestsProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'What are you interested in winning?',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Select a few to personalize your feed. You can change this anytime.',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Colors.grey[400]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: categoriesAsync.when(
                  loading: () => const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        LoadingIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Loading categories...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  error: (err, stack) {
                    // This should not happen with our new FutureProvider,
                    // but we'll keep it as a final safety net
                    return _buildCategoryGrid([], ref, selectedInterests);
                  },
                  data: (categories) => _buildCategoryGrid(
                    categories,
                    ref,
                    selectedInterests,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: selectedInterests.isNotEmpty ? onNext : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.accent,
                  disabledBackgroundColor: Colors.grey[800],
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontSize: 18, color: Colors.black),
                ),
              ).animate().fadeIn(delay: 500.ms),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the category grid with proper error handling and layout
  Widget _buildCategoryGrid(
    List<Category> categories,
    WidgetRef ref,
    List<String> selectedInterests,
  ) {
    // Ensure we have categories to display
    if (categories.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.orange,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'Unable to load categories',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Please check your connection and try again',
              style: TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Wrap(
        spacing: 12.0,
        runSpacing: 12.0,
        alignment: WrapAlignment.center,
        children: categories.map((category) {
          final isSelected = selectedInterests.contains(category.name);

          return FilterChip(
            label: Text('${category.emoji} ${category.name}'),
            selected: isSelected,
            onSelected: (selected) {
              ref
                  .read(selectedInterestsProvider.notifier)
                  .toggle(category.name);
            },
            backgroundColor: AppColors.primaryMedium,
            selectedColor: AppColors.accent,
            labelStyle: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
            ),
            checkmarkColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          );
        }).toList(),
      ),
    );
  }
}
