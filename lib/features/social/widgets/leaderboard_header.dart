import 'package:flutter/material.dart';
import '../models/leaderboard_entry.dart';

class LeaderboardHeader extends StatelessWidget {
  const LeaderboardHeader({
    required this.metadata,
    super.key,
  });
  final LeaderboardMetadata metadata;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A2332),
              Color(0xFF0F1A26),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getLeaderboardIcon(),
                    color: const Color(0xFF00E5FF),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${metadata.type.displayName} Leaderboard',
                        style: const TextStyle(
                          color: Color(0xFF00E5FF),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        metadata.type.description,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Refresh indicator
                _buildRefreshIndicator(),
              ],
            ),

            const SizedBox(height: 16),

            // Stats row
            Row(
              children: [
                _buildStatItem(
                  icon: Icons.groups,
                  label: 'Competitors',
                  value: '${metadata.totalEntries}',
                  color: const Color(0xFF4CAF50),
                ),
                const SizedBox(width: 16),
                _buildStatItem(
                  icon: Icons.schedule,
                  label: 'Last Updated',
                  value: _formatLastUpdated(),
                  color: const Color(0xFFFF9800),
                ),
                const Spacer(),
                _buildBracketIndicator(),
              ],
            ),

            const SizedBox(height: 12),

            // Competition description
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.8),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getCompetitionDescription(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) =>
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      );

  Widget _buildBracketIndicator() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Color(metadata.bracket.color).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Color(metadata.bracket.color),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.military_tech,
              color: Color(metadata.bracket.color),
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              metadata.bracket.name,
              style: TextStyle(
                color: Color(metadata.bracket.color),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );

  Widget _buildRefreshIndicator() => Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.refresh,
          color: Color(0xFF4CAF50),
          size: 16,
        ),
      );

  IconData _getLeaderboardIcon() {
    switch (metadata.type) {
      case LeaderboardType.daily:
        return Icons.today;
      case LeaderboardType.weekly:
        return Icons.date_range;
      case LeaderboardType.allTime:
        return Icons.emoji_events;
      case LeaderboardType.friends:
        return Icons.groups;
    }
  }

  String _formatLastUpdated() {
    final now = DateTime.now();
    final difference = now.difference(metadata.lastUpdated);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  String _getCompetitionDescription() {
    switch (metadata.type) {
      case LeaderboardType.daily:
        return 'Rankings reset daily at midnight. Enter contests and complete challenges to earn SP!';
      case LeaderboardType.weekly:
        return 'Weekly competition runs Monday to Sunday. Consistency is key to staying on top!';
      case LeaderboardType.allTime:
        return 'Hall of Fame showcasing the most dedicated SweepFeed champions of all time.';
      case LeaderboardType.friends:
        return 'Compete with your friends! Add more friends to make the competition more exciting.';
    }
  }
}
