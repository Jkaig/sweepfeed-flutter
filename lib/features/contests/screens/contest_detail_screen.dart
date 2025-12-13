import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/contest.dart';
import '../../../core/models/entry_model.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/webview_screen.dart';
import '../../../features/subscription/screens/premium_subscription_screen.dart';
import '../widgets/contest_share_dialog.dart';
import '../widgets/unified_contest_card.dart';

/// Displays the details for a single contest.
class ContestDetailScreen extends ConsumerStatefulWidget {
  /// Creates a [ContestDetailScreen].
  const ContestDetailScreen({
    required this.contestId,
    super.key,
  });

  /// The ID of the contest to display.
  final String contestId;

  @override
  ConsumerState<ContestDetailScreen> createState() =>
      _ContestDetailScreenState();
}

class _ContestDetailScreenState extends ConsumerState<ContestDetailScreen>
    with SingleTickerProviderStateMixin {
  Future<Contest?>? _contestFuture;
  late AnimationController _bookmarkAnimationController;
  late Animation<double> _bookmarkScaleAnimation;
  bool _canView = true;

  @override
  void initState() {
    super.initState();
    _loadContestDetails();
    _bookmarkAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _bookmarkScaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _bookmarkAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _bookmarkAnimationController.dispose();
    super.dispose();
  }

  void _loadContestDetails() {
    _contestFuture =
        ref.read(contestServiceProvider).getContestById(widget.contestId);
    _contestFuture!.then((contest) async {
      if (contest != null) {
        // Track contest view for preferences
        ref
            .read(userPreferencesServiceProvider)
            .trackContestView(contest.id, contest.category, contest.sponsor);
        
        // Record view for usage limits (only counts for free tier)
        final usageLimits = ref.read(usageLimitsServiceProvider);
        final canView = await usageLimits.recordContestView();
        if (mounted) {
          setState(() {
            _canView = canView;
          });
        }
      }
    });
  }

  Future<void> _openWebView(Contest contest) async {
    final entered = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => WebViewScreen(
          url: contest.entryUrl,
          title: contest.title,
        ),
      ),
    );

    if (entered == true && mounted) {
      _showPostEntryDialog(contest);
    }
  }

  void _showPostEntryDialog(Contest contest) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Did you enter?',
          style: TextStyle(color: AppColors.textWhite),
        ),
        content: const Text(
          'Confirming your entry will track it in your history and award you DustBunnies!',
          style: TextStyle(color: AppColors.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              // Do nothing else, user didn't enter
            },
            child: const Text('No, I didn\'t', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close dialog
              
              // Show loading overlay or just process
              try {
                // Submit entry
                await ref.read(entryManagementServiceProvider).submitEntry(
                  sweepstake: Sweepstakes(
                    id: contest.id,
                    title: contest.title,
                    value: contest.value,
                    endDate: contest.endDate,
                    sponsor: contest.sponsor,
                    entryUrl: contest.entryUrl,
                    isDailyEntry: contest.isDailyEntry,
                    // Map other necessary fields from Contest to Sweepstakes
                    // Assuming Contest model is compatible or we have a mapper
                  ), 
                  method: EntryMethod.web,
                );
                
                if (mounted) {
                   // Show success feedback
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(
                       content: Text('Entry Confirmed! + DustBunnies awarded 🐰'),
                       backgroundColor: AppColors.successGreen,
                     ),
                   );
                   Navigator.of(context).pop(); // Go back to feed
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error recording entry: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandCyan,
              foregroundColor: AppColors.primaryDark,
            ),
            child: const Text('Yes, I Entered!'),
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final contestPreferences = ref.watch(contestPreferencesServiceProvider);
    final isSaved = contestPreferences.isSavedForLater(widget.contestId);

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: FutureBuilder<Contest?>(
        future: _contestFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: LoadingIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.errorRed,),
                  const SizedBox(height: 16),
                  const Text('Failed to load contest details',
                      style: TextStyle(color: AppColors.textLight),),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    text: 'Retry',
                    onPressed: () {
                      setState(_loadContestDetails);
                    },
                  ),
                ],
              ),
            );
          }

          final contest = snapshot.data!;

          if (!_canView) {
            return _buildUpgradePrompt();
          }

          return UnifiedContestCard(
            contest: contest,
            style: CardStyle.full,
          );
        },
      ),
    );
  }

  Widget _buildUpgradePrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline,
              color: AppColors.accent,
              size: 64,
            ),
            const SizedBox(height: 24),
            Text(
              'You\'ve reached your daily view limit',
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.textWhite,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Upgrade to a premium plan to view unlimited contests!',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              text: 'Upgrade Now',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PremiumSubscriptionScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(Contest contest) {
    final reportReasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Contest'),
        content: TextField(
          controller: reportReasonController,
          decoration: const InputDecoration(
            hintText: 'Enter reason for reporting',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final reason = reportReasonController.text;
              if (reason.isNotEmpty) {
                await ref.read(contestServiceProvider).reportContest(contest.id, reason);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Contest reported')),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
