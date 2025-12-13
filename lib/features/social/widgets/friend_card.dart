import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/screens/public_profile_screen.dart';
import '../models/user_profile.dart';
import '../services/challenge_service.dart';

class FriendCard extends ConsumerWidget {
  const FriendCard({
    required this.friend,
    required this.onRemove,
    required this.onViewProfile,
    super.key,
  });
  final UserProfile friend;
  final VoidCallback onRemove;
  final VoidCallback onViewProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2332),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: friend.isOnline
                ? const Color(0xFF4CAF50).withValues(alpha: 0.5)
                : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar with online indicator
                Stack(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: friend.isOnline
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFF00E5FF).withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: friend.avatarUrl.isNotEmpty
                            ? Image.network(
                                friend.avatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                  Icons.person,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  size: 28,
                                ),
                              )
                            : Icon(
                                Icons.person,
                                color: Colors.white.withValues(alpha: 0.7),
                                size: 28,
                              ),
                      ),
                    ),

                    // Online status indicator
                    if (friend.isOnline)
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF1A2332),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
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
                              friend.displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (friend.badges.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getBadgeColor(friend.badges.first)
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _getBadgeColor(friend.badges.first),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                _getBadgeDisplayName(friend.badges.first),
                                style: TextStyle(
                                  color: _getBadgeColor(friend.badges.first),
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
                            'Level ${friend.level}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.emoji_events,
                            color:
                                const Color(0xFFFFD700).withValues(alpha: 0.8),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${friend.totalPrizesWon} wins',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        friend.isOnline ? 'Online now' : _formatLastActive(),
                        style: TextStyle(
                          color: friend.isOnline
                              ? const Color(0xFF4CAF50)
                              : Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                          fontWeight: friend.isOnline
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),

                // Action buttons
                Column(
                  children: [
                    // DB display
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4,),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${friend.dustBunnies} DB',
                        style: const TextStyle(
                          color: Color(0xFF00E5FF),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Menu button
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: Colors.white.withValues(alpha: 0.6),
                        size: 20,
                      ),
                      color: const Color(0xFF1A2332),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                        ),
                      ),
                      onSelected: (value) {
                        switch (value) {
                          case 'profile':
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PublicProfileScreen(userId: friend.id),
                              ),
                            );
                            break;
                          case 'challenge':
                            _challengeFriend(context, ref);
                            break;
                          case 'remove':
                            onRemove();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'profile',
                          child: Row(
                            children: [
                              Icon(
                                Icons.person,
                                color: Colors.white.withValues(alpha: 0.8),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'View Profile',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'challenge',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.sports_esports,
                                color: Color(0xFF00E5FF),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Challenge',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'remove',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.person_remove,
                                color: Color(0xFFF44336),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Remove Friend',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            // Bio section (if available)
            if (friend.bio.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A1929).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  friend.bio,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

            // Stats row
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatItem(
                  icon: Icons.local_fire_department,
                  label: 'Streak',
                  value: '${friend.currentStreak}',
                  color: const Color(0xFFFF5722),
                ),
                const SizedBox(width: 16),
                _buildStatItem(
                  icon: Icons.assignment_turned_in,
                  label: 'Challenges',
                  value: '${friend.challengesCompleted}',
                  color: const Color(0xFF4CAF50),
                ),
                const SizedBox(width: 16),
                _buildStatItem(
                  icon: Icons.monetization_on,
                  label: 'Coins',
                  value: '${friend.sweepCoins}',
                  color: const Color(0xFFFFD700),
                ),
              ],
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
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(height: 4),
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
        ),
      );

  Color _getBadgeColor(String badge) {
    switch (badge.toLowerCase()) {
      case 'veteran':
        return const Color(0xFF9C27B0);
      case 'achiever':
        return const Color(0xFF4CAF50);
      case 'challenger':
        return const Color(0xFFFF9800);
      case 'winner':
        return const Color(0xFFFFD700);
      case 'contestking':
        return const Color(0xFFFFD700);
      case 'rookie':
        return const Color(0xFF2196F3);
      default:
        return const Color(0xFF00E5FF);
    }
  }

  String _getBadgeDisplayName(String badge) {
    switch (badge.toLowerCase()) {
      case 'veteran':
        return 'Veteran';
      case 'achiever':
        return 'Achiever';
      case 'challenger':
        return 'Challenger';
      case 'winner':
        return 'Winner';
      case 'contestking':
        return 'King';
      case 'rookie':
        return 'Rookie';
      default:
        return badge.toUpperCase();
    }
  }

  String _formatLastActive() {
    final now = DateTime.now();
    final difference = now.difference(friend.lastActiveDate);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return 'Last week';
    }
  }

  void _challengeFriend(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2332),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.sports_esports,
              color: Color(0xFF00E5FF),
            ),
            const SizedBox(width: 8),
            Text(
              'Challenge ${friend.displayName}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Challenge your friend to a weekly contest battle!',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFF00E5FF),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'See who can earn more DB this week!',
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(challengeServiceProvider).createChallenge(friend.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Challenge sent to ${friend.displayName}!'),
                  backgroundColor: const Color(0xFF4CAF50),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5FF),
              foregroundColor: const Color(0xFF0A1929),
            ),
            child: const Text('Send Challenge'),
          ),
        ],
      ),
    );
  }
}
