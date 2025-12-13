import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../models/daily_challenge_model.dart';
import '../../../challenges/services/daily_challenge_service.dart';
import '../../../../core/providers/providers.dart';

class DailyChallengeCard extends ConsumerWidget {
  final DailyChallengeDisplay challenge;

  const DailyChallengeCard({
    super.key,
    required this.challenge,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final definition = challenge.definition;
    final progress = challenge.progressPercentage;
    final isComplete = challenge.isComplete;
    final canClaim = challenge.canClaim;
    final isClaimed = challenge.userChallenge.isClaimed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryMedium.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isComplete 
              ? AppColors.successGreen.withValues(alpha: 0.5) 
              : Colors.white.withValues(alpha: 0.1),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isComplete ? AppColors.successGreen.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isComplete ? AppColors.successGreen.withValues(alpha: 0.2) : AppColors.brandCyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              IconData(definition.iconCodePoint, fontFamily: 'MaterialIcons'),
              color: isComplete ? AppColors.successGreen : AppColors.brandCyan,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        definition.title,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (isClaimed)
                      const Icon(Icons.check_circle, color: AppColors.successGreen, size: 20)
                    else 
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.brandCyan.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '+${definition.reward} DB',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.brandCyan,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  definition.description,
                  style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                
                // Progress Bar or Claim Button
                if (canClaim)
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () async {
                         try {
                           await ref.read(dailyChallengeServiceProvider).claimChallengeReward(
                             userId: challenge.userChallenge.userId,
                             userChallengeId: challenge.userChallenge.id
                           );
                         } catch (e) {
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                         }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.successGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text('Claim Reward!', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ).animate().pulse(duration: 1.seconds)
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isComplete ? AppColors.successGreen : AppColors.brandCyan,
                          ),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        challenge.progressText,
                        style: AppTextStyles.labelSmall.copyWith(color: Colors.white54),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
