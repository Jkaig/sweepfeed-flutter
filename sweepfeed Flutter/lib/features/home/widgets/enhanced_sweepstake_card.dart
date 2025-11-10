import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_colors.dart';

/// Enhanced Sweepstake Card with improved UI and interactions
class EnhancedSweepstakeCard extends StatefulWidget {
  const EnhancedSweepstakeCard({
    required this.contest,
    required this.onTap,
    required this.onEnter,
    required this.onSave,
    super.key,
    this.isCompact = false,
  });
  final Map<String, dynamic> contest;
  final VoidCallback onTap;
  final VoidCallback onEnter;
  final VoidCallback onSave;
  final bool isCompact;

  @override
  State<EnhancedSweepstakeCard> createState() => _EnhancedSweepstakeCardState();
}

class _EnhancedSweepstakeCardState extends State<EnhancedSweepstakeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isHovered = false;
  bool _isEntered = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contest = widget.contest;
    final isExpiringSoon = (contest['daysLeft'] ?? 30) <= 3;
    final isHighValue =
        (int.tryParse(contest['prizeValue']?.toString() ?? '0') ?? 0) >= 5000;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) {
        HapticFeedback.selectionClick();
        setState(() => _isHovered = true);
        _animationController.forward();
      },
      onTapUp: (_) {
        setState(() => _isHovered = false);
        _animationController.reverse();
      },
      onTapCancel: () {
        setState(() => _isHovered = false);
        _animationController.reverse();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(_isHovered ? 0.98 : 1.0),
        child: Container(
          height: widget.isCompact ? null : 220,
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.9),
                AppColors.secondary.withValues(alpha: 0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isExpiringSoon
                  ? Colors.red
                  : isHighValue
                      ? AppColors.cyberYellow
                      : AppColors.electricBlue,
              width: _isHovered ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (isHighValue ? AppColors.cyberYellow : AppColors.primary)
                    .withValues(alpha: _isHovered ? 0.5 : 0.3),
                blurRadius: _isHovered ? 20 : 10,
                spreadRadius: _isHovered ? 5 : 2,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Shimmer effect overlay
              if (isHighValue)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Shimmer.fromColors(
                      baseColor: Colors.transparent,
                      highlightColor:
                          AppColors.cyberYellow.withValues(alpha: 0.1),
                      period: const Duration(seconds: 3),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.1),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Status badges
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Row(
                  children: [
                    if (contest['isFeatured'] == true)
                      _buildBadge(
                        'FEATURED',
                        AppColors.cyberYellow,
                        Icons.star,
                      ),
                    if (isExpiringSoon)
                      _buildBadge(
                        'ENDING SOON',
                        Colors.red,
                        Icons.timer,
                      ),
                    if (isHighValue)
                      _buildBadge(
                        'HIGH VALUE',
                        AppColors.neonGreen,
                        Icons.diamond,
                      ),
                    const Spacer(),
                    if (_isEntered)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.neonGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 14,
                              color: Colors.black,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'ENTERED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Main content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!widget.isCompact) const Spacer(),

                    // Prize value
                    Row(
                      children: [
                        Icon(
                          Icons.attach_money,
                          color: AppColors.cyberYellow,
                          size: widget.isCompact ? 20 : 24,
                        ),
                        Text(
                          contest['prizeValue'] ?? '1,000',
                          style: TextStyle(
                            color: AppColors.cyberYellow,
                            fontSize: widget.isCompact ? 20 : 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Title
                    Text(
                      contest['title'] ?? 'Amazing Contest',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: widget.isCompact ? 14 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Sponsor
                    if (contest['sponsor'] != null)
                      Text(
                        'by ${contest['sponsor']}',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: widget.isCompact ? 11 : 12,
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Bottom row with timer and actions
                    Row(
                      children: [
                        // Timer
                        Icon(
                          Icons.timer_outlined,
                          size: widget.isCompact ? 14 : 16,
                          color: isExpiringSoon ? Colors.red : Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${contest['daysLeft'] ?? 7} days',
                          style: TextStyle(
                            color: isExpiringSoon ? Colors.red : Colors.white70,
                            fontSize: widget.isCompact ? 11 : 12,
                          ),
                        ),

                        // Entry count
                        if (contest['entryCount'] != null) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.people_outline,
                            size: widget.isCompact ? 14 : 16,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${contest['entryCount']}',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: widget.isCompact ? 11 : 12,
                            ),
                          ),
                        ],

                        const Spacer(),

                        // Action buttons
                        if (!widget.isCompact) ...[
                          _buildActionButton(
                            icon: _isSaved
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color: _isSaved
                                ? AppColors.cyberYellow
                                : Colors.white70,
                            onTap: () {
                              setState(() => _isSaved = !_isSaved);
                              widget.onSave();
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildActionButton(
                            icon: Icons.share,
                            color: Colors.white70,
                            onTap: () {
                              // Share functionality
                            },
                          ),
                          const SizedBox(width: 8),
                        ],

                        // Enter button
                        ElevatedButton(
                          onPressed: _isEntered
                              ? null
                              : () {
                                  setState(() => _isEntered = true);
                                  widget.onEnter();
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isEntered
                                ? Colors.grey
                                : AppColors.cyberYellow,
                            foregroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(
                              horizontal: widget.isCompact ? 12 : 16,
                              vertical: widget.isCompact ? 6 : 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            _isEntered ? 'Entered' : 'Enter',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: widget.isCompact ? 12 : 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Sparkle animation for high value
              if (isHighValue)
                Positioned(
                  top: 8,
                  right: 8,
                  child: const Icon(
                    Icons.auto_awesome,
                    color: AppColors.cyberYellow,
                    size: 20,
                  )
                      .animate(
                        onPlay: (controller) => controller.repeat(),
                      )
                      .scale(
                        begin: const Offset(1.0, 1.0),
                        end: const Offset(1.2, 1.2),
                        duration: 1.seconds,
                      )
                      .then()
                      .scale(
                        begin: const Offset(1.2, 1.2),
                        end: const Offset(1.0, 1.0),
                        duration: 1.seconds,
                      ),
                ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.1, end: 0, duration: 500.ms);
  }

  Widget _buildBadge(String text, Color color, IconData icon) => Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.black),
            const SizedBox(width: 4),
            Text(
              text,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      );

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Icon(
            icon,
            size: 18,
            color: color,
          ),
        ),
      );
}
