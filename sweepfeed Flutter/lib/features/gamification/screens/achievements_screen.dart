import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/gamification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        backgroundColor: AppColors.primaryDark,
        appBar: AppBar(
          title: const Text('Achievements'),
          backgroundColor: AppColors.primaryMedium,
        ),
        body: Column(
          children: [
            _Header(),
            Expanded(
              child: _AchievementGrid(),
            ),
          ],
        ),
      );
}

class _Header extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.primaryMedium,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: userProfile.when(
        data: (user) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(title: 'Level', value: user?.level.toString() ?? '1'),
            _StatItem(title: 'Points', value: user?.points.toString() ?? '0'),
            _StatItem(title: 'Streak', value: '${user?.streak ?? 0} days'),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => const Text('Could not load stats'),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.title, required this.value});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(
            value,
            style: AppTextStyles.headlineSmall
                .copyWith(color: AppColors.textWhite),
          ),
          Text(
            title,
            style:
                AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
          ),
        ],
      );
}

class _AchievementGrid extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievements = ref.watch(achievementsProvider);
    final userProfile = ref.watch(userProfileProvider);

    return userProfile.when(
      data: (user) {
        final unlockedBadges = user?.unlockedBadgeIds ?? [];
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount:
              0, // achievements.length, // Placeholder since achievements is AsyncValue
          itemBuilder: (context, index) {
            // Placeholder since achievements is AsyncValue<List<dynamic>>
            return const _AchievementCard(achievement: null, isUnlocked: false);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => const Text('Could not load achievements'),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement, required this.isUnlocked});
  final Badge? achievement;
  final bool isUnlocked;

  @override
  Widget build(BuildContext context) {
    if (achievement == null) {
      return const Card(
        child: Center(child: Text('No achievement')),
      );
    }

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(achievement!.name),
            content: Text(achievement!.description),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
      child: Card(
        color: isUnlocked
            ? AppColors.accent.withValues(alpha: 0.3)
            : AppColors.primaryMedium,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              achievement!.icon,
              size: 40,
              color: isUnlocked ? AppColors.accent : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              achievement!.name,
              textAlign: TextAlign.center,
              style:
                  AppTextStyles.bodyMedium.copyWith(color: AppColors.textWhite),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
