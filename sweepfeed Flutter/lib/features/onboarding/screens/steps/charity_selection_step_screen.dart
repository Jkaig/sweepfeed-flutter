import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../controllers/unified_onboarding_controller.dart';
import '../../widgets/onboarding_button.dart';
import '../../widgets/onboarding_template.dart';

class CharitySelectionStepScreen extends ConsumerWidget {
  const CharitySelectionStepScreen({
    required this.onNext,
    this.onSkip,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCharities = ref.watch(selectedCharitiesProvider);

    return OnboardingTemplate(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),

          // Title
          Text(
            'Choose Charities to Support',
            style: AppTextStyles.displaySmall.copyWith(
              color: AppColors.textWhite,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Subtitle
          Text(
            'Select causes you care about. 30% of ad revenue goes to your chosen charities.',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Charities list
          Expanded(
            child: _buildCharitiesList(context, ref),
          ),

          const SizedBox(height: 24),

          // Continue button
          OnboardingButton(
            text: selectedCharities.isEmpty ? 'Skip for now' : 'Continue',
            onPressed: onNext,
            isPrimary: selectedCharities.isNotEmpty,
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCharitiesList(BuildContext context, WidgetRef ref) {
    // For demo purposes, showing hardcoded charities
    // In production, this would fetch from a charity API
    final charities = [
      {
        'id': '1',
        'name': 'Red Cross',
        'description': 'Emergency assistance and disaster relief',
        'category': 'Emergency Relief',
      },
      {
        'id': '2',
        'name': 'Doctors Without Borders',
        'description': 'Medical aid where it\'s needed most',
        'category': 'Healthcare',
      },
      {
        'id': '3',
        'name': 'World Wildlife Fund',
        'description': 'Protecting endangered species and habitats',
        'category': 'Environment',
      },
      {
        'id': '4',
        'name': 'Feeding America',
        'description': 'Fighting hunger across the United States',
        'category': 'Hunger Relief',
      },
      {
        'id': '5',
        'name': 'American Cancer Society',
        'description': 'Fighting cancer through research and support',
        'category': 'Healthcare',
      },
    ];

    return ListView.builder(
      itemCount: charities.length,
      itemBuilder: (context, index) {
        final charity = charities[index];
        return _buildCharityTile(context, ref, charity);
      },
    );
  }

  Widget _buildCharityTile(
      BuildContext context, WidgetRef ref, Map<String, String> charity) {
    final selectedCharities = ref.watch(selectedCharitiesProvider);
    final isSelected =
        selectedCharities.any((c) => (c['id'] ?? c.id) == charity['id']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          ref.read(selectedCharitiesProvider.notifier).toggle(charity);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color:
                isSelected ? AppColors.successGreen : AppColors.primaryMedium,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isSelected ? AppColors.successGreen : AppColors.primaryLight,
              width: 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.successGreen.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Charity icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.2)
                        : AppColors.successGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCharityIcon(charity['category']!),
                    size: 24,
                    color: isSelected ? Colors.white : AppColors.successGreen,
                  ),
                ),

                const SizedBox(width: 16),

                // Charity info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        charity['name']!,
                        style: AppTextStyles.titleMedium.copyWith(
                          color:
                              isSelected ? Colors.white : AppColors.textWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        charity['description']!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.9)
                              : AppColors.textMuted,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        charity['category']!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.7)
                              : AppColors.successGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Check icon
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    size: 24,
                    color: Colors.white,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCharityIcon(String category) {
    switch (category.toLowerCase()) {
      case 'emergency relief':
        return Icons.emergency;
      case 'healthcare':
        return Icons.medical_services;
      case 'environment':
        return Icons.eco;
      case 'hunger relief':
        return Icons.restaurant;
      case 'education':
        return Icons.school;
      default:
        return Icons.favorite;
    }
  }
}
