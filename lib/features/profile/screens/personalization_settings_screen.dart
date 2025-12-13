import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/widgets/loading_indicator.dart';

class PersonalizationSettingsScreen extends ConsumerWidget {
  const PersonalizationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final profileService = ref.read(profileServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personalization'),
      ),
      body: userProfileAsync.when(
        loading: () => const Center(child: LoadingIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (userProfile) {
          if (userProfile == null) {
            return const Center(child: Text('User profile not available.'));
          }

          // Create mutable copies for editing
          final interests = List<String>.from(userProfile.interests);
          final negativePreferences =
              List<String>.from(userProfile.negativePreferences);

          return StatefulBuilder(
            builder: (context, setState) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Your Interests',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Text(
                  "These help us find contests you'll love. Add or remove interests at any time.",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  children: [
                    // This should be populated with your master list of interests
                    ...['Tech', 'Travel', 'Cash', 'Gaming', 'Cars']
                        .map((interest) {
                      final isSelected = interests.contains(interest);
                      return FilterChip(
                        label: Text(interest),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              interests.add(interest);
                            } else {
                              interests.remove(interest);
                            }
                          });
                          profileService.updateInterests(
                            userProfile.id,
                            interests,
                          );
                        },
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Hidden Categories',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Text(
                  "We won't show you contests from these categories. You can un-hide them anytime.",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                if (negativePreferences.isEmpty)
                  const Text('No hidden categories yet.'),
                Wrap(
                  spacing: 8.0,
                  children: negativePreferences
                      .map(
                        (pref) => Chip(
                          label: Text(pref),
                          onDeleted: () {
                            setState(() {
                              negativePreferences.remove(pref);
                            });
                            profileService.removeNegativePreference(
                              userProfile.id,
                              pref,
                            );
                          },
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
