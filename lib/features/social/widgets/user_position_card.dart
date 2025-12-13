import 'package:flutter/material.dart';
import '../models/leaderboard_entry.dart';

class UserPositionCard extends StatelessWidget {
  const UserPositionCard({
    required this.entry,
    super.key,
  });
  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF00E5FF),
              Color(0xFF0288D1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: Color(0xFF0A1929),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Your Position',
                  style: TextStyle(
                    color: Color(0xFF0A1929),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A1929).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Rank #${entry.rank}',
                    style: const TextStyle(
                      color: Color(0xFF0A1929),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Main content
            Row(
              children: [
                // Avatar
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF0A1929),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0A1929).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: entry.avatarUrl.isNotEmpty
                        ? Image.network(
                            entry.avatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.person,
                              color: Color(0xFF0A1929),
                              size: 30,
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            color: Color(0xFF0A1929),
                            size: 30,
                          ),
                  ),
                ),

                const SizedBox(width: 16),

                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.displayName,
                        style: const TextStyle(
                          color: Color(0xFF0A1929),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.stars,
                            color:
                                const Color(0xFF0A1929).withValues(alpha: 0.8),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Level ${entry.level}',
                            style: TextStyle(
                              color: const Color(0xFF0A1929)
                                  .withValues(alpha: 0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.military_tech,
                            color:
                                const Color(0xFF0A1929).withValues(alpha: 0.8),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            entry.userLevel,
                            style: TextStyle(
                              color: const Color(0xFF0A1929)
                                  .withValues(alpha: 0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (entry.badge.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF0A1929).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getBadgeDisplayName(entry.badge),
                            style: const TextStyle(
                              color: Color(0xFF0A1929),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Score display
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${entry.score}',
                      style: const TextStyle(
                        color: Color(0xFF0A1929),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'SP',
                      style: TextStyle(
                        color: const Color(0xFF0A1929).withValues(alpha: 0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Motivational message based on rank
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0A1929).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _getMotivationIcon(),
                    color: const Color(0xFF0A1929),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getMotivationalMessage(),
                      style: const TextStyle(
                        color: Color(0xFF0A1929),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  String _getBadgeDisplayName(String badge) {
    switch (badge.toLowerCase()) {
      case 'streakmaster':
        return 'Streak Master';
      case 'contestking':
        return 'Contest King';
      case 'socialbutterfly':
        return 'Social Butterfly';
      case 'veteran':
        return 'Veteran';
      case 'achiever':
        return 'Achiever';
      case 'challenger':
        return 'Challenger';
      case 'explorer':
        return 'Explorer';
      case 'winner':
        return 'Winner';
      case 'rookie':
        return 'Rookie';
      case 'newbie':
        return 'Newbie';
      default:
        return badge.toUpperCase();
    }
  }

  IconData _getMotivationIcon() {
    if (entry.rank <= 50) return Icons.trending_up;
    if (entry.rank <= 100) return Icons.rocket_launch;
    if (entry.rank <= 500) return Icons.fitness_center;
    return Icons.sports_score;
  }

  String _getMotivationalMessage() {
    if (entry.rank <= 10) {
      return "Amazing! You're in the top 10! Keep it up!";
    } else if (entry.rank <= 50) {
      return "Great job! You're in the top 50. Push for top 10!";
    } else if (entry.rank <= 100) {
      return "Nice work! You're in the top 100. Keep climbing!";
    } else if (entry.rank <= 500) {
      return 'Good progress! Complete more challenges to climb higher.';
    } else {
      return 'Every expert was once a beginner. Keep entering contests!';
    }
  }
}
