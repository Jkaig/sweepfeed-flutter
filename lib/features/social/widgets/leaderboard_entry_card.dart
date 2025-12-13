import 'package:flutter/material.dart';

import '../../../core/widgets/dustbunnies_display.dart';
import '../models/leaderboard_entry.dart';

class LeaderboardEntryCard extends StatelessWidget {
  const LeaderboardEntryCard({
    required this.entry,
    super.key,
    this.isCurrentUser = false,
  });
  final LeaderboardEntry entry;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isCurrentUser
              ? const LinearGradient(
                  colors: [
                    Color(0xFF00E5FF),
                    Color(0xFF0A1929),
                  ],
                  stops: [0.02, 0.02],
                )
              : null,
          color: isCurrentUser ? null : const Color(0xFF1A2332),
          borderRadius: BorderRadius.circular(12),
          border: isCurrentUser
              ? Border.all(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                )
              : null,
        ),
        child: Row(
          children: [
            // Rank
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getRankColor(entry.rank).withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getRankColor(entry.rank),
                ),
              ),
              child: Center(
                child: Text(
                  '#${entry.rank}',
                  style: TextStyle(
                    color: _getRankColor(entry.rank),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Avatar
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCurrentUser
                      ? const Color(0xFF00E5FF)
                      : Colors.white.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: entry.avatarUrl.isNotEmpty
                    ? Image.network(
                        entry.avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.person,
                          color: isCurrentUser
                              ? const Color(0xFF00E5FF)
                              : Colors.white.withValues(alpha: 0.7),
                        ),
                      )
                    : Icon(
                        Icons.person,
                        color: isCurrentUser
                            ? const Color(0xFF00E5FF)
                            : Colors.white.withValues(alpha: 0.7),
                      ),
              ),
            ),

            const SizedBox(width: 16),

            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isCurrentUser ? 'You' : entry.displayName,
                          style: TextStyle(
                            color: isCurrentUser
                                ? const Color(0xFF00E5FF)
                                : Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (entry.badge.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getBadgeColor(entry.badge)
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getBadgeColor(entry.badge),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            _getBadgeDisplayName(entry.badge),
                            style: TextStyle(
                              color: _getBadgeColor(entry.badge),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.stars,
                        color: Colors.white.withValues(alpha: 0.6),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Level ${entry.level}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.military_tech,
                        color: Color(
                            UserLevelBracket.getBracket(entry.level).color,),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        entry.userLevel,
                        style: TextStyle(
                          color: Color(
                            UserLevelBracket.getBracket(entry.level).color,
                          ),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Score with DustBunny icon
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                CompactDustBunniesDisplay(
                  amount: entry.score,
                  color: isCurrentUser ? const Color(0xFF00E5FF) : Colors.white,
                  fontSize: 16,
                ),
                Text(
                  'Total DB',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 10,
                  ),
                ),
              ],
            ),

            // Rank change indicator (if applicable)
            if (entry.rank <= 10)
              Container(
                margin: const EdgeInsets.only(left: 8),
                child: _buildRankChangeIndicator(),
              ),
          ],
        ),
      );

  Color _getRankColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700); // Gold
    if (rank == 2) return const Color(0xFFC0C0C0); // Silver
    if (rank == 3) return const Color(0xFFCD7F32); // Bronze
    if (rank <= 10) return const Color(0xFF00E5FF); // Top 10
    return Colors.white.withValues(alpha: 0.7); // Others
  }

  Color _getBadgeColor(String badge) {
    switch (badge.toLowerCase()) {
      case 'streakmaster':
        return const Color(0xFFFF5722);
      case 'contestking':
        return const Color(0xFFFFD700);
      case 'socialbutterfly':
        return const Color(0xFFE91E63);
      case 'veteran':
        return const Color(0xFF9C27B0);
      case 'achiever':
        return const Color(0xFF4CAF50);
      case 'challenger':
        return const Color(0xFFFF9800);
      case 'explorer':
        return const Color(0xFF2196F3);
      case 'winner':
        return const Color(0xFF00BCD4);
      default:
        return const Color(0xFF00E5FF);
    }
  }

  String _getBadgeDisplayName(String badge) {
    switch (badge.toLowerCase()) {
      case 'streakmaster':
        return 'Streak Master';
      case 'contestking':
        return 'Contest King';
      case 'socialbutterfly':
        return 'Social';
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
        return 'New';
      default:
        return badge.toUpperCase();
    }
  }

  Widget _buildRankChangeIndicator() {
    // Mock rank change - in production, calculate from previous rankings
    final isRankUp = entry.rank % 2 == 0;
    final change = (entry.rank % 5) + 1;

    if (change == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: isRankUp
            ? const Color(0xFF4CAF50).withValues(alpha: 0.2)
            : const Color(0xFFF44336).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRankUp ? Icons.arrow_upward : Icons.arrow_downward,
            color: isRankUp ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
            size: 12,
          ),
          Text(
            '$change',
            style: TextStyle(
              color:
                  isRankUp ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
