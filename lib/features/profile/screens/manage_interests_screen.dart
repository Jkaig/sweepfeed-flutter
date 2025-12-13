import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../contests/providers/contest_providers.dart';

final manageInterestsProvider =
    StateProvider.autoDispose<Set<String>>((ref) {
  final userPreferences = ref.watch(userPreferencesProvider).asData?.value;
  return userPreferences?.explicitInterests ?? {};
});

class ManageInterestsScreen extends ConsumerWidget {
  const ManageInterestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedInterests = ref.watch(manageInterestsProvider);
    final userPreferencesService = ref.watch(userPreferencesServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Your Interests'),
        backgroundColor: AppColors.primaryDark,
      ),
      backgroundColor: AppColors.primaryDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Select the topics you're most interested in to help us tailor your feed.",
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 24),
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
                            final notifier =
                                ref.read(manageInterestsProvider.notifier);
                            final currentSelection = Set<String>.from(notifier.state);
                            if (isSelected) {
                              currentSelection.remove(category.name);
                            } else {
                              currentSelection.add(category.name);
                            }
                            notifier.state = currentSelection;
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
                text: 'Save Changes',
                onPressed: () async {
                  await userPreferencesService
                      .updateExplicitInterests(selectedInterests);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Your interests have been updated!'),
                        backgroundColor: AppColors.successGreen,
                      ),
                    );
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
