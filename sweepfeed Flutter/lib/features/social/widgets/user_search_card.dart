import 'package:flutter/material.dart';
import '../models/user_profile.dart';

class UserSearchCard extends StatefulWidget {
  const UserSearchCard({
    required this.user,
    required this.onSendRequest,
    required this.onViewProfile,
    super.key,
  });
  final UserProfile user;
  final VoidCallback onSendRequest;
  final VoidCallback onViewProfile;

  @override
  State<UserSearchCard> createState() => _UserSearchCardState();
}

class _UserSearchCardState extends State<UserSearchCard> {
  bool _requestSent = false;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2332),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: widget.user.avatarUrl.isNotEmpty
                        ? Image.network(
                            widget.user.avatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
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
                              widget.user.displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.user.badges.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getBadgeColor(widget.user.badges.first)
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color:
                                      _getBadgeColor(widget.user.badges.first),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                _getBadgeDisplayName(widget.user.badges.first),
                                style: TextStyle(
                                  color:
                                      _getBadgeColor(widget.user.badges.first),
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
                            'Level ${widget.user.level}',
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
                            '${widget.user.totalPrizesWon} wins',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            widget.user.isOnline
                                ? Icons.radio_button_checked
                                : Icons.access_time,
                            color: widget.user.isOnline
                                ? const Color(0xFF4CAF50)
                                : Colors.white.withValues(alpha: 0.5),
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.user.isOnline
                                ? 'Online now'
                                : _formatLastActive(),
                            style: TextStyle(
                              color: widget.user.isOnline
                                  ? const Color(0xFF4CAF50)
                                  : Colors.white.withValues(alpha: 0.5),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // DB display
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${widget.user.dustBunnies} DB',
                    style: const TextStyle(
                      color: Color(0xFF00E5FF),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            // Bio section (if available)
            if (widget.user.bio.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A1929).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.user.bio,
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
                  icon: Icons.assignment_turned_in,
                  label: 'Contests',
                  value: '${widget.user.totalContestsEntered}',
                  color: const Color(0xFF4CAF50),
                ),
                const SizedBox(width: 12),
                _buildStatItem(
                  icon: Icons.local_fire_department,
                  label: 'Streak',
                  value: '${widget.user.currentStreak}',
                  color: const Color(0xFFFF5722),
                ),
                const SizedBox(width: 12),
                _buildStatItem(
                  icon: Icons.schedule,
                  label: 'Joined',
                  value: _formatJoinDate(),
                  color: const Color(0xFF9C27B0),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                // View Profile button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onViewProfile,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00E5FF),
                      side: const BorderSide(
                        color: Color(0xFF00E5FF),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.person, size: 18),
                    label: const Text(
                      'Profile',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Add Friend button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _requestSent ? null : _sendFriendRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _requestSent
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFF00E5FF),
                      foregroundColor:
                          _requestSent ? Colors.white : const Color(0xFF0A1929),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: _requestSent ? 0 : 4,
                    ),
                    icon: Icon(
                      _requestSent ? Icons.check : Icons.person_add,
                      size: 18,
                    ),
                    label: Text(
                      _requestSent ? 'Sent' : 'Add Friend',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
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
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 9,
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
    final difference = now.difference(widget.user.lastActiveDate);

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

  String _formatJoinDate() {
    final now = DateTime.now();
    final difference = now.difference(widget.user.joinedDate);

    if (difference.inDays < 30) {
      return '${difference.inDays}d';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo';
    } else {
      final years = (difference.inDays / 365).floor();
      return '${years}y';
    }
  }

  void _sendFriendRequest() {
    setState(() => _requestSent = true);
    widget.onSendRequest();
  }
}
