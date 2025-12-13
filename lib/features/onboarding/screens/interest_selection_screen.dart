import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/category_model.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/animated_gradient_background.dart';
import '../../../core/widgets/glassmorphic_container.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/primary_button.dart';

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

    return Stack(
      children: [
        const Positioned.fill(child: AnimatedGradientBackground()),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    'Customize Your Feed',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn().slideY(begin: -0.2, end: 0),
                  const SizedBox(height: 12),
                  Text(
                    'Select categories to help us find the perfect contests for you.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 48),
                  Expanded(
                    child: categoriesAsync.when(
                      loading: () => const Center(
                        child: LoadingIndicator(),
                      ),
                      error: (err, stack) => const Center(
                        child: Text(
                          'Failed to load categories',
                          style: TextStyle(color: AppColors.errorRed),
                        ),
                      ),
                      data: (categories) => GlassmorphicContainer(
                        child: _buildCategoryGrid(
                          categories,
                          ref,
                          selectedInterests,
                        ),
                      ).animate().fadeIn(delay: 400.ms).scale(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: 'Continue',
                    onPressed: selectedInterests.isNotEmpty ? onNext : null,
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
                ],
              ),
            ),
          ),
        ),
      ],
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
