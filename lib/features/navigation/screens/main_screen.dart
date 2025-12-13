import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../ads/widgets/admob_banner.dart';
import '../../gamification/screens/daily_check_in_screen.dart';
import '../../subscription/widgets/active_trial_banner.dart';
import '../../subscription/widgets/trial_banner.dart';
import 'main_navigation_wrapper.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Original checks
    _checkDailyCheckIn();
    
    // Checks from main.dart
    // Note: checkDailyLoginBonus might be redundant with my new checkDailyCheckIn, 
    // but keeping it if it does something else (like API calls).
    // Assuming checkDailyLoginBonus triggers the OLD bonus system or just backend sync.
    // I will call it to be safe.
    WidgetsBinding.instance.addPostFrameCallback((_) {
       ref.read(mainScreenServiceProvider).checkDailyLoginBonus(context);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(mainScreenServiceProvider).checkForReturnDialog(context);
    }
  }

  Future<void> _checkDailyCheckIn() async {
    // Wait for frame to build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userId = ref.read(firebaseServiceProvider).currentUser?.uid;
      if (userId != null) {
        final needsCheckIn = await ref
            .read(streakServiceProvider)
            .needsCheckInToday(userId);
        
        if (mounted && needsCheckIn) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const DailyCheckInScreen(),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionService = ref.watch(subscriptionServiceProvider);

    return Scaffold(
      body: Column(
        children: [
          // Show trial banner based on subscription status
          if (!subscriptionService.isSubscribed &&
              !subscriptionService.isInTrialPeriod)
            const TrialBanner(),

          // Show active trial banner for users in trial period
          if (subscriptionService.isInTrialPeriod) const ActiveTrialBanner(),

          // Main content
          const Expanded(child: MainNavigationWrapper()),

          // Ad banner at the bottom for free users
          if (!subscriptionService.isSubscribed)
            const AdMobBanner(),
        ],
      ),
    );
  }
}
