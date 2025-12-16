import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../referral/widgets/return_user_dialog.dart';

class MainScreenService {
  MainScreenService(this._ref);

  final Ref _ref;

  Future<void> checkForReturnDialog(BuildContext context) async {
    final prefs = await _ref.read(sharedPreferencesProvider.future);
    final pendingContestId = prefs.getString('pending_contest_interaction_id');
    final pendingContestTitle =
        prefs.getString('pending_contest_interaction_title');

    if (pendingContestId != null && pendingContestTitle != null) {
      await prefs.remove('pending_contest_interaction_id');
      await prefs.remove('pending_contest_interaction_title');

      final user = _ref.read(firebaseServiceProvider).currentUser;
      if (user != null && context.mounted) {
        final userDoc = await _ref
            .read(firestoreProvider)
            .collection('users')
            .doc(user.uid)
            .get();
        final referralCode =
            userDoc.data()?['referralCode'] as String? ?? 'SWEEPFEED';

        showDialog(
          context: context,
          builder: (context) => ReturnUserDialog(
            contestTitle: pendingContestTitle,
            contestId: pendingContestId,
            referralCode: referralCode,
          ),
        );
      }
    }
  }

  Future<void> checkDailyLoginBonus(BuildContext context) async {
    final currentUser = _ref.read(firebaseServiceProvider).currentUser;
    if (currentUser == null) return;

    final dustBunniesService = _ref.read(dustBunniesServiceProvider);
    final reward = await dustBunniesService.awardDustBunnies(
      userId: currentUser.uid,
      action: 'daily_login',
    );
    final awarded = reward.pointsAwarded > 0;

    if (awarded && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.stars, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Daily Login Bonus!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/dustbunnies/dustbunny_icon.png',
                          width: 16,
                          height: 16,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.stars,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '+10 DB earned',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF00D9FF),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}

final mainScreenServiceProvider = Provider<MainScreenService>((ref) {
  return MainScreenService(ref);
});
