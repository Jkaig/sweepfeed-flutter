import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../navigation/screens/main_screen.dart';

final selectedOnboardingInterestsProvider =
    StateProvider<Set<String>>((ref) => {});

class InterestOnboardingScreen extends ConsumerWidget {
  const InterestOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedInterests = ref.watch(selectedOnboardingInterestsProvider);
    final userPreferencesService = ref.watch(userPreferencesServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Text(
                'Customize Your Feed',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Select a few of your interests to get started.',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textWhite),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Expanded(
                child: categoriesAsync.when(
                  data: (categories) => GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.5,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final isSelected =
                            selectedInterests.contains(category.name);
                        return GestureDetector(
                          onTap: () {
                            final notifier = ref.read(
                                selectedOnboardingInterestsProvider.notifier,);
                            if (isSelected) {
                              notifier.state = notifier.state
                                ..remove(category.name);
                            } else {
                              notifier.state = notifier.state
                                ..add(category.name);
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.brandCyan
                                  : AppColors.primaryMedium,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.brandCyan
                                    : AppColors.primaryLight,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${category.emoji} ${category.name}',
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: isSelected
                                      ? AppColors.primaryDark
                                      : AppColors.textWhite,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, s) =>
                      const Center(child: Text('Could not load interests')),
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                text: 'Finish',
                onPressed: selectedInterests.isNotEmpty
                    ? () {
                        userPreferencesService
                            .updateExplicitInterests(selectedInterests)
                            .then((_) {
                          if (context.mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MainScreen(),
                              ),
                            );
                          }
                        });
                      }
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
