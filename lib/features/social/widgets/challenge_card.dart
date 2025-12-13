import 'package:flutter/material.dart';
import '../models/enhanced_challenge.dart';

class ChallengeCard extends StatefulWidget {
  const ChallengeCard({
    required this.challenge,
    super.key,
    this.onClaim,
  });
  final EnhancedChallenge challenge;
  final VoidCallback? onClaim;

  @override
  State<ChallengeCard> createState() => _ChallengeCardState();
}

class _ChallengeCardState extends State<ChallengeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Animate if challenge can be claimed
    if (widget.challenge.canClaim) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final challenge = widget.challenge;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) => Transform.scale(
        scale: challenge.canClaim ? _pulseAnimation.value : 1.0,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: _getCardGradient(),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _getBorderColor(),
              width: challenge.canClaim ? 2 : 1,
            ),
            boxShadow: challenge.canClaim
                ? [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Category icon and emoji
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(challenge.difficulty.color)
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Color(challenge.difficulty.color),
                      ),
                    ),
                    child: Text(
                      challenge.iconCode,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Challenge info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                challenge.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (challenge.canClaim)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.redeem,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'CLAIM',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildCategoryChip(),
                            const SizedBox(width: 8),
                            _buildDifficultyChip(),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Time remaining
                  if (!challenge.isExpired) _buildTimeChip(),
                ],
              ),

              const SizedBox(height: 16),

              // Description
              Text(
                challenge.description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 16),

              // Progress section
              if (!challenge.isCompleted) _buildProgressSection(),

              // Rewards section
              const SizedBox(height: 16),
              _buildRewardsSection(),

              // Action button
              if (challenge.canClaim || challenge.isCompleted) ...[
                const SizedBox(height: 16),
                _buildActionButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  LinearGradient _getCardGradient() {
    if (widget.challenge.canClaim) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF00E5FF),
          Color(0xFF1A2332),
        ],
        stops: [0.02, 0.02],
      );
    } else if (widget.challenge.isExpired) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF1A2332).withValues(alpha: 0.5),
          const Color(0xFF0F1A26).withValues(alpha: 0.5),
        ],
      );
    } else {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF1A2332),
          Color(0xFF0F1A26),
        ],
      );
    }
  }

  Color _getBorderColor() {
    if (widget.challenge.canClaim) {
      return const Color(0xFF00E5FF);
    } else if (widget.challenge.isExpired) {
      return Colors.white.withValues(alpha: 0.1);
    } else {
      return Color(widget.challenge.difficulty.color).withValues(alpha: 0.3);
    }
  }

  Widget _buildCategoryChip() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
        child: Text(
          widget.challenge.category.displayName,
          style: const TextStyle(
            color: Color(0xFF00E5FF),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Widget _buildDifficultyChip() {
    final difficulty = widget.challenge.difficulty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Color(difficulty.color).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Color(difficulty.color),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(
            difficulty.level,
            (index) => Icon(
              Icons.star,
              color: Color(difficulty.color),
              size: 8,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            difficulty.displayName,
            style: TextStyle(
              color: Color(difficulty.color),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeChip() {
    final isUrgent =
        widget.challenge.expiresAt.difference(DateTime.now()).inHours < 6;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isUrgent
            ? const Color(0xFFF44336).withValues(alpha: 0.2)
            : const Color(0xFF757575).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUrgent ? Icons.warning : Icons.schedule,
            color: isUrgent ? const Color(0xFFF44336) : const Color(0xFF757575),
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            widget.challenge.timeRemaining,
            style: TextStyle(
              color:
                  isUrgent ? const Color(0xFFF44336) : const Color(0xFF757575),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    final progress = widget.challenge.progressPercentage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              widget.challenge.progressText,
              style: const TextStyle(
                color: Color(0xFF00E5FF),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF00E5FF),
                    Color(widget.challenge.difficulty.color),
                  ],
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRewardsSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rewards',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: widget.challenge.rewards
                .map(
                  (reward) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          _getRewardColor(reward.type).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getRewardColor(reward.type),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          reward.type.emoji,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          reward.displayName,
                          style: TextStyle(
                            color: _getRewardColor(reward.type),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      );

  Widget _buildActionButton() {
    if (widget.challenge.canClaim && widget.onClaim != null) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: widget.onClaim,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
          icon: const Icon(Icons.redeem, size: 20),
          label: const Text(
            'Claim Rewards',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    } else if (widget.challenge.isCompleted) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF4CAF50),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              color: Color(0xFF4CAF50),
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Completed',
              style: TextStyle(
                color: Color(0xFF4CAF50),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Color _getRewardColor(RewardType type) {
    switch (type) {
      case RewardType.dustBunnies:
        return const Color(0xFF00E5FF);
      case RewardType.sweepCoins:
        return const Color(0xFFFFD700);
      case RewardType.badge:
        return const Color(0xFF9C27B0);
      case RewardType.cosmetic:
        return const Color(0xFFE91E63);
      case RewardType.streak:
        return const Color(0xFFFF5722);
      case RewardType.special:
        return const Color(0xFF8BC34A);
    }
  }
}
