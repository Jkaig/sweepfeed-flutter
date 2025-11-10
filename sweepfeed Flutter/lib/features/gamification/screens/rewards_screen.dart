import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_indicator.dart';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewards = ref.watch(rewardsProvider);
    final userProfile = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rewards Store'),
      ),
      body: userProfile.when(
        loading: () => const Center(child: LoadingIndicator()),
        error: (error, stack) => Center(
          child: Text('Failed to load user data: $error'),
        ),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Please log in to see rewards.'));
          }

          return rewards.when(
            loading: () => const Center(child: LoadingIndicator()),
            error: (error, stack) =>
                Center(child: Text('Failed to load rewards: $error')),
            data: (rewardsList) => ListView.builder(
              itemCount: rewardsList.length,
              itemBuilder: (context, index) {
                final reward = rewardsList[index];
                // For now, using dummy reward data since rewardsList is List<dynamic>
                const isUnlocked =
                    false; // user.unlockedRewardIds.contains(reward.id);
                const canAfford = true; // user.points >= reward.pointsRequired;
                const canClaim = !isUnlocked && canAfford;

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: isUnlocked
                      ? AppColors.primaryLight.withValues(alpha: 0.5)
                      : Theme.of(context).cardColor,
                  child: ListTile(
                    leading: const Icon(
                      Icons.star,
                      size: 40,
                      color: AppColors.accent,
                    ), // Placeholder
                    title: Text(reward.name),
                    subtitle: Text(
                      '${reward.description}\nCost: ${reward.pointsRequired} points',
                    ),
                    trailing: isUnlocked
                        ? const Chip(
                            label: Text('Claimed'),
                            backgroundColor: AppColors.accent,
                          )
                        : ElevatedButton(
                            onPressed: canClaim
                                ? () async {
                                    final userId = ref
                                        .read(firebaseAuthProvider)
                                        .currentUser
                                        ?.uid;
                                    if (userId != null) {
                                      try {
                                        // TODO: Migrate reward claiming to DustBunniesService
                                        // Reward claiming temporarily disabled during gamification migration
                                        // See GAMIFICATION_MIGRATION.md for full migration plan
                                        throw Exception(
                                            'Reward claiming temporarily disabled during migration');

                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.check_circle,
                                                    color: Colors.white,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Claimed ${reward.title}!',
                                                  ),
                                                ],
                                              ),
                                              backgroundColor:
                                                  AppColors.successGreen,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Failed to claim reward',
                                              ),
                                              backgroundColor:
                                                  AppColors.errorRed,
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  }
                                : null,
                            child: const Text(canAfford ? 'Claim' : 'Locked'),
                          ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
