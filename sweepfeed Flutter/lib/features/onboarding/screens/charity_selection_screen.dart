import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/charity_model.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_indicator.dart';

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

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Support a Cause You Love',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Select one or more charities. Your contributions from watching ads will be tracked, divided equally, and are editable later.',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Colors.grey[400]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: charitiesAsync.when(
                  loading: () => const Center(child: LoadingIndicator()),
                  error: (err, stack) =>
                      const Center(child: Text('Failed to load charities')),
                  data: (charities) =>
                      _buildCharityGrid(charities, ref, selectedCharities),
                ),
              ),
              ElevatedButton(
                onPressed: selectedCharities.isNotEmpty ? onNext : null,
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
        (ref) => SelectedCharitiesNotifier());

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
