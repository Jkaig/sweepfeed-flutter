import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/category_model.dart';
import '../../../../core/providers/providers.dart' hide selectedInterestsProvider;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glassmorphic_container.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../controllers/unified_onboarding_controller.dart';
import '../../widgets/onboarding_button.dart';
import '../../widgets/onboarding_template.dart';

class InterestSelectionStepScreen extends ConsumerWidget {
  const InterestSelectionStepScreen({
    required this.onNext,
    this.onSkip,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedInterests = ref.watch(selectedInterestsProvider);

    return OnboardingTemplate(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),

          // Headers container with glass effect
          GlassmorphicContainer(
            borderRadius: 16,
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.1),
            ],
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                   // Title
                   Text(
                     'What are you interested in winning?',
                     style: AppTextStyles.displaySmall.copyWith(
                       color: AppColors.textWhite,
                       fontWeight: FontWeight.bold,
                       height: 1.2,
                       shadows: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                       ],
                     ),
                     textAlign: TextAlign.center,
                   ),

                   const SizedBox(height: 16),

                   // Subtitle
                   Text(
                     'Select a few to personalize your feed. You can change this anytime.',
                     style: AppTextStyles.titleMedium.copyWith(
                       color: AppColors.textWhite.withValues(alpha: 0.9),
                         shadows: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            offset: const Offset(0, 1),
                            blurRadius: 2,
                          ),
                       ],
                     ),
                     textAlign: TextAlign.center,
                   ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Categories grid
          Expanded(
            child: categoriesAsync.when(
              loading: () => const Center(
                child: LoadingIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.errorRed,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Unable to load categories',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please check your connection and try again',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textWhite,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              data: (categories) =>
                  _buildCategoriesGrid(context, ref, categories),
            ),
          ),

          const SizedBox(height: 24),

          // Continue button
          OnboardingButton(
            text: selectedInterests.isEmpty ? 'Skip for now' : 'Continue',
            onPressed: onNext,
            isPrimary: selectedInterests.isNotEmpty,
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCategoriesGrid(
      BuildContext context, WidgetRef ref, List<Category> categories,) => GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryTile(context, ref, category);
      },
    );

  Widget _buildCategoryTile(
      BuildContext context, WidgetRef ref, Category category,) {
    final selectedInterests = ref.watch(selectedInterestsProvider);
    final isSelected = selectedInterests.contains(category.name);

    return GestureDetector(
      onTap: () {
        ref.read(selectedInterestsProvider.notifier).toggle(category.name);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.primaryMedium,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.primaryLight,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Category icon
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryDark.withValues(alpha: 0.2)
                      : AppColors.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(category.name),
                  size: 18,
                  color: isSelected ? AppColors.primaryDark : AppColors.accent,
                ),
              ),

              const SizedBox(width: 12),

              // Category name
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    category.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isSelected
                          ? AppColors.primaryDark
                          : AppColors.textWhite,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                    maxLines: 1,
                  ),
                ),
              ),

              // Check icon
              if (isSelected)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.check_circle,
                    size: 18,
                    color: AppColors.primaryDark,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'cash':
      case 'cash prizes':
        return Icons.attach_money;
      case 'cars':
      case 'vehicles':
      case 'automotive':
        return Icons.directions_car;
      case 'home improvement':
      case 'home & garden':
        return Icons.home_repair_service;
      case 'vacations':
      case 'travel':
        return Icons.flight_takeoff;
      case 'electronics':
      case 'tech':
        return Icons.devices;
      case 'gift cards':
        return Icons.card_giftcard;
      case 'gaming':
        return Icons.sports_esports;
      case 'appliances':
        return Icons.kitchen;
      case 'jewelry':
        return Icons.diamond;
      case 'shopping sprees':
        return Icons.shopping_bag;
      case 'experiences':
        return Icons.celebration;
      case 'sports':
        return Icons.sports_basketball;
      default:
        return Icons.emoji_events;
    }
  }
}
