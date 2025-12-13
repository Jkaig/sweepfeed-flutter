import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/services/streak_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/animated_gradient_background.dart';
import '../../../core/widgets/glassmorphic_container.dart';
import '../../../core/widgets/primary_button.dart';
import '../widgets/day_card.dart';
import '../widgets/streak_flame_widget.dart';

class DailyCheckInScreen extends ConsumerStatefulWidget {
  const DailyCheckInScreen({super.key});

  @override
  ConsumerState<DailyCheckInScreen> createState() => _DailyCheckInScreenState();
}

class _DailyCheckInScreenState extends ConsumerState<DailyCheckInScreen> {
  bool _isClaiming = false;
  bool _hasClaimed = false;
  StreakData? _streakData;

  @override
  void initState() {
    super.initState();
    _loadStreakData();
  }

  Future<void> _loadStreakData() async {
    final userId = ref.read(firebaseServiceProvider).currentUser?.uid;
    if (userId != null) {
      final data = await ref.read(streakServiceProvider).getUserStreakData(userId);
      if (mounted) {
        setState(() {
          _streakData = data;
          
          // Check if already claimed today
          if (data.lastCheckIn != null) {
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final last = DateTime(
              data.lastCheckIn!.year, 
              data.lastCheckIn!.month, 
              data.lastCheckIn!.day
            );
            _hasClaimed = last == today;
          }
        });
      }
    }
  }

  Future<void> _handleClaim() async {
    setState(() => _isClaiming = true);
    
    final userId = ref.read(firebaseServiceProvider).currentUser?.uid;
    if (userId == null) return;

    // Simulate network delay for effect
    await Future.delayed(1000.ms);

    final result = await ref.read(streakServiceProvider).checkIn(userId);
    
    if (mounted) {
      if (result.success) {
        setState(() {
           _hasClaimed = true;
           _isClaiming = false;
        });
        // Reload data to update UI
        _loadStreakData();
      } else {
        setState(() => _isClaiming = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If loading, show skeleton or transparency
    if (_streakData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Determine current day in the 7-day cycle
    // (Current streak % 7) gives us position, handling 0-index
    // If streak is 0, we are on day 1 (index 0)
    // If streak is 1 (claimed), we want to show day 1 completed
    final currentStreak = _streakData!.currentStreak;
    var dayIndex = currentStreak % 7;
    if (_hasClaimed && currentStreak > 0) {
      // If we just claimed, the streak updated, so dayIndex reflects NEXT day target
      // But we want to show the CURRENT day as completed.
      // E.g. Streak was 0, became 1. dayIndex is now 1 (Day 2). 
      // We want to highlight Day 1 as done.
       dayIndex = (currentStreak - 1) % 7;
    }
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 600,
          width: double.infinity,
          child: Stack(
            children: [
              const Positioned.fill(child: AnimatedGradientBackground()),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Daily Check-in',
                          style: AppTextStyles.headlineSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Flame
                    StreakFlameWidget(
                      streakDays: _streakData!.currentStreak,
                      size: 120,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _hasClaimed ? 'Streak Kept!' : 'Keep the Streak Alive!',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Check in daily to earn Dustbunnies',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    
                    const SizedBox(height: 32),

                    // Calendar Grid
                    GlassmorphicContainer(
                      borderRadius: 16,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: List.generate(7, (index) {
                            final dayNum = index + 1;
                            
                            // Determine status
                            // If index < dayIndex, it's a past completed day
                            // If index == dayIndex, it's today
                            var isPast = index < dayIndex;
                            var isToday = index == dayIndex;
                            var isCompleted = isPast || (_hasClaimed && isToday);

                            // Logic adjustment:
                            // We need to look at if it's completed based on 'currentStreak'
                            // Simpler approach:
                            // We construct the view based on a 7-day window.
                            // If streak is 3... Days 1, 2, 3 are done. Day 4 is next.
                            return DayCard(
                              dayNumber: dayNum,
                              isCompleted: isCompleted,
                              isToday: isToday && !_hasClaimed, // Highlight if actionable
                              rewardAmount: dayNum * 5 + 10, // Example logic
                              isMysteryBox: dayNum == 7,
                            );
                          }),
                        ),
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Claim Button
                    if (!_hasClaimed)
                      PrimaryButton(
                        text: 'Claim Reward',
                        onPressed: _handleClaim,
                        isLoading: _isClaiming,
                      ).animate().shimmer(delay: 500.ms, duration: 1500.ms)
                    else 
                      const SizedBox(
                        height: 50,
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check, color: AppColors.successGreen),
                              SizedBox(width: 8),
                              Text(
                                'Come back tomorrow!',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
