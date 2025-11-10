import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/dustbunnies_display.dart';

class TrophyRoom extends StatefulWidget {
  const TrophyRoom({super.key});

  @override
  State<TrophyRoom> createState() => _TrophyRoomState();
}

class _TrophyRoomState extends State<TrophyRoom> with TickerProviderStateMixin {
  late AnimationController _sparkleController;
  late AnimationController _trophyController;

  // Player stats - mock data for demo
  final Map<String, dynamic> _playerStats = {
    'level': 15,
    'totalDB': 12750,
    'nextLevelDB': 15000,
    'entriesThisWeek': 23,
    'currentStreak': 7,
    'longestStreak': 28,
    'totalEntries': 156,
    'contestsWon': 3,
    'totalWinnings': 2850.00,
    'joinDate': DateTime(2023, 6, 15),
  };

  // Achievement badges
  final List<Map<String, dynamic>> _achievements = [
    {
      'id': 'first_entry',
      'name': 'First Entry',
      'description': 'Entered your first contest',
      'icon': '🎯',
      'unlocked': true,
      'unlockedDate': DateTime(2023, 6, 15),
      'rarity': 'common',
    },
    {
      'id': 'week_warrior',
      'name': 'Week Warrior',
      'description': '7-day entry streak',
      'icon': '🔥',
      'unlocked': true,
      'unlockedDate': DateTime(2023, 11, 2),
      'rarity': 'rare',
    },
    {
      'id': 'lucky_winner',
      'name': 'Lucky Winner',
      'description': 'Won your first contest',
      'icon': '🍀',
      'unlocked': true,
      'unlockedDate': DateTime(2023, 8, 22),
      'rarity': 'epic',
    },
    {
      'id': 'streak_master',
      'name': 'Streak Master',
      'description': '30-day entry streak',
      'icon': '⚡',
      'unlocked': false,
      'unlockedDate': null,
      'rarity': 'legendary',
    },
    {
      'id': 'contest_explorer',
      'name': 'Contest Explorer',
      'description': 'Entered 100 different contests',
      'icon': '🗺️',
      'unlocked': true,
      'unlockedDate': DateTime(2023, 10, 5),
      'rarity': 'rare',
    },
    {
      'id': 'big_winner',
      'name': 'Big Winner',
      'description': 'Won a prize worth over \$1000',
      'icon': '💰',
      'unlocked': true,
      'unlockedDate': DateTime(2023, 9, 18),
      'rarity': 'epic',
    },
    {
      'id': 'social_sharer',
      'name': 'Social Sharer',
      'description': 'Shared 25 contests',
      'icon': '📲',
      'unlocked': true,
      'unlockedDate': DateTime(2023, 7, 30),
      'rarity': 'common',
    },
    {
      'id': 'ultimate_champion',
      'name': 'Ultimate Champion',
      'description': 'Reach level 50',
      'icon': '👑',
      'unlocked': false,
      'unlockedDate': null,
      'rarity': 'mythical',
    },
  ];

  @override
  void initState() {
    super.initState();

    _sparkleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _trophyController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
  }

  Color _getRarityColor(String rarity) {
    switch (rarity) {
      case 'common':
        return Colors.grey;
      case 'rare':
        return AppColors.electricBlue;
      case 'epic':
        return Colors.purple;
      case 'legendary':
        return AppColors.cyberYellow;
      case 'mythical':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  Widget _buildPlayerCard() {
    final levelProgress = (_playerStats['totalDB'] % 2500) / 2500.0;
    final daysActive =
        DateTime.now().difference(_playerStats['joinDate']).inDays;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryMedium.withValues(alpha: 0.9),
            AppColors.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cyberYellow.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyberYellow.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          // Player avatar and level
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.cyberYellow, AppColors.mangoTangoStart],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cyberYellow.withValues(alpha: 0.4),
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${_playerStats['level']}',
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              )
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  )
                  .scale(
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(1.05, 1.05),
                    duration: 2000.ms,
                  ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contest Champion',
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Level ${_playerStats['level']} • $daysActive days active',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // DB Progress bar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'DB Progress',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textLight,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CompactDustBunniesDisplay(
                                  amount: _playerStats['totalDB'],
                                  color: AppColors.cyberYellow,
                                  fontSize: 11,
                                ),
                                Text(
                                  ' / ',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.cyberYellow,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                CompactDustBunniesDisplay(
                                  amount: _playerStats['nextLevelDB'],
                                  color: AppColors.cyberYellow,
                                  fontSize: 11,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: levelProgress,
                            minHeight: 8,
                            backgroundColor:
                                AppColors.primaryLight.withValues(alpha: 0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.cyberYellow,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Stats grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _buildStatBox('🎯', '${_playerStats['totalEntries']}', 'Entries'),
              _buildStatBox('🔥', '${_playerStats['currentStreak']}', 'Streak'),
              _buildStatBox('🏆', '${_playerStats['contestsWon']}', 'Wins'),
              _buildStatBox(
                '💰',
                '\$${_playerStats['totalWinnings'].toStringAsFixed(0)}',
                'Won',
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .slideY(begin: -0.3, duration: 600.ms, curve: Curves.easeOutBack)
        .fadeIn(duration: 400.ms);
  }

  Widget _buildStatBox(String emoji, String value, String label) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.cyberYellow.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textWhite,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textLight,
                fontSize: 10,
              ),
            ),
          ],
        ),
      );

  Widget _buildAchievementBadge(Map<String, dynamic> achievement, int index) {
    final isUnlocked = achievement['unlocked'] == true;
    final rarity = achievement['rarity'] as String;
    final rarityColor = _getRarityColor(rarity);
    final delay = Duration(milliseconds: index * 150);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showAchievementDetails(achievement);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isUnlocked
              ? LinearGradient(
                  colors: [
                    rarityColor.withValues(alpha: 0.3),
                    rarityColor.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    Colors.grey.withValues(alpha: 0.2),
                    Colors.grey.withValues(alpha: 0.05),
                  ],
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isUnlocked ? rarityColor : Colors.grey.withValues(alpha: 0.3),
            width: isUnlocked ? 2 : 1,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: rarityColor.withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Achievement icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: isUnlocked
                    ? LinearGradient(
                        colors: [
                          rarityColor,
                          rarityColor.withValues(alpha: 0.7)
                        ],
                      )
                    : null,
                color: isUnlocked ? null : Colors.grey.withValues(alpha: 0.3),
                shape: BoxShape.circle,
                boxShadow: isUnlocked
                    ? [
                        BoxShadow(
                          color: rarityColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  isUnlocked ? achievement['icon'] : '🔒',
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            )
                .animate(
                  target: isUnlocked ? 1 : 0,
                  onPlay: (controller) {
                    if (isUnlocked && rarity == 'legendary' ||
                        rarity == 'mythical') {
                      controller.repeat(reverse: true);
                    }
                  },
                )
                .scale(
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.1, 1.1),
                  duration: 1500.ms,
                ),

            const SizedBox(height: 12),

            // Achievement name
            Text(
              achievement['name'],
              style: AppTextStyles.titleSmall.copyWith(
                color: isUnlocked ? AppColors.textWhite : Colors.grey,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 4),

            // Rarity indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: rarityColor.withValues(alpha: isUnlocked ? 0.3 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                rarity.toUpperCase(),
                style: AppTextStyles.bodySmall.copyWith(
                  color: isUnlocked ? rarityColor : Colors.grey,
                  fontWeight: FontWeight.w600,
                  fontSize: 9,
                ),
              ),
            ),

            if (isUnlocked) ...[
              const SizedBox(height: 8),
              Text(
                _formatDate(achievement['unlockedDate']),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textLight,
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    )
        .animate()
        .slideX(
          begin: 0.3,
          duration: Duration(milliseconds: 600 + delay.inMilliseconds),
          curve: Curves.easeOutBack,
        )
        .fadeIn(
          duration: Duration(milliseconds: 400 + delay.inMilliseconds),
        );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAchievementDetails(Map<String, dynamic> achievement) {
    final isUnlocked = achievement['unlocked'] == true;
    final rarity = achievement['rarity'] as String;
    final rarityColor = _getRarityColor(rarity);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppColors.primaryMedium,
                AppColors.primaryDark,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: rarityColor.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: rarityColor.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Achievement icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [rarityColor, rarityColor.withValues(alpha: 0.7)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: rarityColor.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    isUnlocked ? achievement['icon'] : '🔒',
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
              )
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.elasticOut)
                  .then()
                  .shimmer(duration: 1000.ms),

              const SizedBox(height: 20),

              Text(
                achievement['name'],
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [rarityColor, rarityColor.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${rarity.toUpperCase()} BADGE',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                achievement['description'],
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textLight,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              if (isUnlocked) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.successGreen.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.successGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Unlocked on ${_formatDate(achievement['unlockedDate'])}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.successGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: rarityColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Awesome!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),
      ),
    );
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    _trophyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unlockedAchievements =
        _achievements.where((a) => a['unlocked'] == true).toList();
    final lockedAchievements =
        _achievements.where((a) => a['unlocked'] != true).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Player card
          _buildPlayerCard(),

          // Trophy room header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.cyberYellow,
                        AppColors.mangoTangoStart,
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: 28,
                  ),
                )
                    .animate(
                      onPlay: (controller) => controller.repeat(reverse: true),
                    )
                    .rotate(begin: -0.1, end: 0.1, duration: 2000.ms),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trophy Room',
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: AppColors.textWhite,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '${unlockedAchievements.length} of ${_achievements.length} achievements unlocked',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Achievement badges grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: _achievements.length,
              itemBuilder: (context, index) =>
                  _buildAchievementBadge(_achievements[index], index),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
