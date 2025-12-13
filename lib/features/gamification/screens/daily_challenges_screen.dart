import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../challenges/models/daily_challenge_model.dart';
import '../../challenges/services/daily_challenge_service.dart';

// Provider for DailyChallengeService
final dailyChallengeServiceProvider = Provider<DailyChallengeService>((ref) => DailyChallengeService());

// Provider for user's daily challenges
final userDailyChallengesProvider =
    FutureProvider<List<DailyChallengeDisplay>>((ref) async {
  final challengeService = ref.read(dailyChallengeServiceProvider);
  final currentUser = ref.read(firebaseAuthProvider).currentUser;

  if (currentUser == null) {
    return [];
  }

  return challengeService.getUserDailyChallenges(currentUser.uid);
});

class DailyChallengesScreen extends ConsumerWidget {
  const DailyChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesAsyncValue = ref.watch(userDailyChallengesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Challenges'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(userDailyChallengesProvider);
            },
            tooltip: 'Refresh challenges',
          ),
        ],
      ),
      body: challengesAsyncValue.when(
        data: (challenges) {
          if (challenges.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment,
                    size: 64,
                    color: AppColors.primaryMedium,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No challenges available today',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Check back tomorrow for new challenges!',
                    style: TextStyle(color: AppColors.primaryMedium),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: challenges.length,
            itemBuilder: (context, index) {
              final challengeDisplay = challenges[index];
              return _ChallengeCard(
                challengeDisplay: challengeDisplay,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.errorRed,
              ),
              const SizedBox(height: 16),
              const Text(
                'Could not load challenges',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(color: AppColors.primaryMedium),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(userDailyChallengesProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChallengeCard extends ConsumerStatefulWidget {
  const _ChallengeCard({
    required this.challengeDisplay,
  });
  final DailyChallengeDisplay challengeDisplay;

  @override
  ConsumerState<_ChallengeCard> createState() => _ChallengeCardState();
}

class _ChallengeCardState extends ConsumerState<_ChallengeCard> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final definition = widget.challengeDisplay.definition;
    final userChallenge = widget.challengeDisplay.userChallenge;
    final isComplete = widget.challengeDisplay.isComplete;
    final canClaim = widget.challengeDisplay.canClaim;
    final isClaimed = userChallenge.isClaimed;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isComplete ? AppColors.primaryMedium : AppColors.primaryDark,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  IconData(definition.iconCodePoint,
                      fontFamily: 'MaterialIcons',),
                  size: 40,
                  color: isComplete ? AppColors.accent : Colors.white,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        definition.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        definition.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[300],
                            ),
                      ),
                    ],
                  ),
                ),
                if (isComplete)
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.successGreen,
                    size: 24,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            LinearPercentIndicator(
              percent:
                  widget.challengeDisplay.progressPercentage.clamp(0.0, 1.0),
              lineHeight: 8.0,
              backgroundColor: Colors.grey[800],
              progressColor:
                  isComplete ? AppColors.successGreen : AppColors.accent,
              barRadius: const Radius.circular(4),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress: ${widget.challengeDisplay.progressText}',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accent),
                  ),
                  child: Text(
                    '${definition.reward} DB',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            if (canClaim && !_isLoading) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      _isLoading = true;
                    });

                    final challengeService =
                        ref.read(dailyChallengeServiceProvider);
                    final userId =
                        ref.read(firebaseAuthProvider).currentUser?.uid;

                    if (userId != null) {
                      try {
                        final result =
                            await challengeService.claimChallengeReward(
                          userId: userId,
                          userChallengeId: userChallenge.id,
                        );

                        if (mounted) {
                          if (result.success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      result.message ?? 'Reward claimed!',
                                    ),
                                  ],
                                ),
                                backgroundColor: AppColors.successGreen,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );

                            // Refresh the challenges list
                            ref.invalidate(userDailyChallengesProvider);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  result.error ?? 'Failed to claim reward',
                                ),
                                backgroundColor: AppColors.errorRed,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: AppColors.errorRed,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    }

                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.primaryDark,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Claim Reward',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
            if (_isLoading) ...[
              const SizedBox(height: 16),
              const Center(
                child: CircularProgressIndicator(
                  color: AppColors.accent,
                ),
              ),
            ],
            if (isClaimed && !_isLoading) ...[
              const SizedBox(height: 16),
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.successGreen),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppColors.successGreen,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Reward Claimed',
                        style: TextStyle(
                          color: AppColors.successGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.1, end: 0);
  }
}
