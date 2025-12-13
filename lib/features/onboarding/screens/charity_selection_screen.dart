import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/charity_model.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/animated_gradient_background.dart';
import '../../../core/widgets/glassmorphic_container.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/primary_button.dart';

class CharitySelectionScreen extends ConsumerWidget {
  const CharitySelectionScreen({
    required this.onNext,
    super.key,
  });
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final charitiesAsync = ref.watch(charitiesProvider);
    final selectedCharities = ref.watch(selectedCharitiesProvider);

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
                  const SizedBox(height: 16),
                  Text(
                    'Support a Cause',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn().slideY(begin: -0.2, end: 0),
                  const SizedBox(height: 8),
                  Text(
                    'Select charities to support. Your ad views help generate donations.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 32),
                  Expanded(
                    child: charitiesAsync.when(
                      loading: () => const Center(child: LoadingIndicator()),
                      error: (err, stack) => const Center(
                        child: Text(
                          'Failed to load charities',
                          style: TextStyle(color: AppColors.errorRed),
                        ),
                      ),
                      data: (charities) => GlassmorphicContainer(
                        child: _buildCharityGrid(charities, ref, selectedCharities),
                      ).animate().fadeIn(delay: 400.ms).scale(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: 'Start Winning',
                    onPressed: selectedCharities.isNotEmpty ? onNext : null,
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCharityGrid(
    List<Charity> charities,
    WidgetRef ref,
    List<Charity> selectedCharities,
  ) =>
      GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: charities.length,
        itemBuilder: (context, index) {
          final charity = charities[index];
          final isSelected = selectedCharities.contains(charity);

          return GestureDetector(
            onTap: () {
              ref.read(selectedCharitiesProvider.notifier).toggle(charity);
            },
            child: Card(
              color: isSelected ? AppColors.accent : AppColors.primaryMedium,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: isSelected
                    ? const BorderSide(color: AppColors.accent, width: 2)
                    : BorderSide.none,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      child: Image.network(
                        charity.emblemUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        // Placeholder for images that fail to load
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                          Icons.business,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      charity.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
}

final selectedCharitiesProvider =
    StateNotifierProvider<SelectedCharitiesNotifier, List<Charity>>(
        (ref) => SelectedCharitiesNotifier(),);

class SelectedCharitiesNotifier extends StateNotifier<List<Charity>> {
  SelectedCharitiesNotifier() : super([]);

  void toggle(Charity charity) {
    if (state.contains(charity)) {
      state = state.where((item) => item.id != charity.id).toList();
    } else {
      state = [...state, charity];
    }
  }
}
