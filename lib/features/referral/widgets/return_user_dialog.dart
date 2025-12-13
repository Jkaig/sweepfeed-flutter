import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/models/entry_model.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../entries/services/entry_management_service.dart';
import '../../contests/providers/contest_feed_provider.dart';

class ReturnUserDialog extends ConsumerWidget {
  const ReturnUserDialog({
    required this.contestTitle,
    required this.contestId,
    required this.referralCode,
    super.key,
  });

  final String contestTitle;
  final String contestId;
  final String referralCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.primaryDark,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.celebration,
              size: 48,
              color: AppColors.cyberYellow,
            ),
            const SizedBox(height: 16),
            Text(
              'Did you enter?',
              style: AppTextStyles.headlineSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'We noticed you just checked out:\n"$contestTitle"',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              'Boost your chances by sharing your referral code!',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.electricBlue,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.cyberYellow.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    referralCode,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.cyberYellow,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.white70),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: referralCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Referral code copied!'),
                          backgroundColor: AppColors.successGreen,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'Share with Friends',
              onPressed: () {
                Share.share(
                  'I just entered this awesome contests on SweepFeed! Use my code $referralCode for bonus entries! 🚀\n\nCheck it out: https://sweepfeed.app/contest/$contestId',
                );
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () async {
                final user = ref.read(firebaseAuthProvider).currentUser;
                if (user != null) {
                  try {
                    // Mark as entered in Firestore
                    final contestService = ref.read(contestServiceProvider);
                    await contestService.markAsEntered(user.uid, contestId);
                    
                    // Also record entry for entry management
                    final entryService = ref.read(entryManagementServiceProvider);
                    // Get contest details to create entry
                    final contest = await contestService.getContestById(contestId);
                    if (contest != null) {
                      await entryService.submitEntry(
                        sweepstake: contest,
                        method: EntryMethod.website,
                      );
                      
                      // Record entry in tier management service for daily limit tracking
                      final tierService = ref.read(tierManagementServiceProvider);
                      await tierService.recordContestEntry();
                    }
                    
                    // Log analytics
                    ref.read(analyticsServiceProvider).logEvent(
                      eventName: 'user_confirmed_entry',
                      parameters: {
                        'contest_id': contestId,
                        'confirmed': true,
                      },
                    );
                    
                    // Invalidate feed provider to refresh and remove entered contest
                    ref.invalidate(contestFeedProvider);
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Entry recorded! Contest removed from feed.'),
                          backgroundColor: AppColors.successGreen,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error recording entry: ${e.toString()}'),
                          backgroundColor: AppColors.errorRed,
                        ),
                      );
                    }
                  }
                }
                
                if (context.mounted) {
                  Navigator.of(context).pop(true); // Return true to indicate entry was confirmed
                }
              },
              child: const Text(
                'Yes, I entered!',
                style: TextStyle(color: AppColors.successGreen),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Not yet',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
}

