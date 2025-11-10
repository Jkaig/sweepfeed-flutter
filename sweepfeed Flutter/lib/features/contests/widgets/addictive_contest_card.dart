import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class AddictiveContestCard extends StatefulWidget {
  const AddictiveContestCard({
    required this.contest,
    required this.onTap,
    super.key,
    this.onBookmark,
    this.onShare,
    this.isHighValue = false,
    this.index,
  });
  final Map<String, dynamic> contest;
  final VoidCallback onTap;
  final VoidCallback? onBookmark;
  final VoidCallback? onShare;
  final bool isHighValue;
  final int? index;

  @override
  State<AddictiveContestCard> createState() => _AddictiveContestCardState();
}

class _AddictiveContestCardState extends State<AddictiveContestCard>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late AnimationController _countdownController;
  late Timer _countdownTimer;

  bool _isPressed = false;
  Duration _timeRemaining = const Duration();
  String _urgencyLevel = 'normal';

  @override
  void initState() {
    super.initState();

    _shimmerController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _countdownController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _initializeCountdown();

    // Start shimmer for high-value prizes
    if (widget.isHighValue) {
      _shimmerController.repeat();
    }
  }

  void _initializeCountdown() {
    // Parse end date from contest data
    final endDate = _parseEndDate(widget.contest['endDate']);
    if (endDate != null) {
      _updateTimeRemaining(endDate);
      _startCountdownTimer(endDate);
    }
  }

  DateTime? _parseEndDate(endDate) {
    if (endDate == null) return null;

    if (endDate is String) {
      try {
        return DateTime.parse(endDate);
      } catch (e) {
        // Handle different date formats
        return DateTime.now().add(const Duration(days: 7)); // Fallback
      }
    }

    // For Firestore Timestamp
    try {
      return endDate.toDate();
    } catch (e) {
      return DateTime.now().add(const Duration(days: 7)); // Fallback
    }
  }

  void _startCountdownTimer(DateTime endDate) {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateTimeRemaining(endDate);
      }
    });
  }

  void _updateTimeRemaining(DateTime endDate) {
    final now = DateTime.now();
    final remaining = endDate.difference(now);

    setState(() {
      _timeRemaining = remaining.isNegative ? Duration.zero : remaining;

      // Determine urgency level for UI changes
      final hoursLeft = _timeRemaining.inHours;
      if (hoursLeft <= 24) {
        _urgencyLevel = 'critical';
        _pulseController.repeat(reverse: true);
      } else if (hoursLeft <= 72) {
        _urgencyLevel = 'urgent';
        _pulseController.repeat(reverse: true);
      } else {
        _urgencyLevel = 'normal';
        _pulseController.stop();
      }
    });

    // Trigger countdown animation
    _countdownController.reset();
    _countdownController.forward();
  }

  Color _getUrgencyColor() {
    switch (_urgencyLevel) {
      case 'critical':
        return AppColors.errorRed;
      case 'urgent':
        return AppColors.warningOrange;
      default:
        return AppColors.successGreen;
    }
  }

  String _formatTimeRemaining() {
    if (_timeRemaining.inDays > 0) {
      return '${_timeRemaining.inDays}d ${_timeRemaining.inHours % 24}h';
    } else if (_timeRemaining.inHours > 0) {
      return '${_timeRemaining.inHours}h ${_timeRemaining.inMinutes % 60}m';
    } else if (_timeRemaining.inMinutes > 0) {
      return '${_timeRemaining.inMinutes}m ${_timeRemaining.inSeconds % 60}s';
    } else {
      return 'ENDED';
    }
  }

  Widget _buildShimmerOverlay() => Positioned.fill(
        child: Shimmer.fromColors(
          baseColor: Colors.transparent,
          highlightColor: AppColors.cyberYellow.withValues(alpha: 0.3),
          period: const Duration(seconds: 4),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.cyberYellow.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
                begin: const Alignment(-1.0, -1.0),
                end: const Alignment(1.0, 1.0),
              ),
            ),
          ),
        ),
      );

  Widget _buildCountdownTimer() => AnimatedBuilder(
        animation: _countdownController,
        builder: (context, child) => AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final pulseValue = _urgencyLevel != 'normal'
                ? (1.0 + (_pulseController.value * 0.1))
                : 1.0;

            return Transform.scale(
              scale: pulseValue * (1.0 + (_countdownController.value * 0.05)),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getUrgencyColor().withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _getUrgencyColor().withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _urgencyLevel == 'critical'
                          ? Icons.timer_outlined
                          : Icons.schedule,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTimeRemaining(),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

  Widget _buildPrizeValue() {
    final prizeValue = widget.contest['prizeValue'] ?? 'Unknown';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.cyberYellow,
            AppColors.mangoTangoStart,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyberYellow.withValues(alpha: 0.3),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        '\$$prizeValue',
        style: AppTextStyles.titleSmall.copyWith(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildActionButtons() => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.onShare != null)
            _buildActionButton(
              icon: Icons.share,
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onShare!();
              },
            ),
          const SizedBox(width: 8),
          if (widget.onBookmark != null)
            _buildActionButton(
              icon: Icons.bookmark_border,
              onTap: () {
                HapticFeedback.mediumImpact();
                widget.onBookmark!();
              },
            ),
        ],
      );

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.primaryLight,
            ),
          ),
          child: Icon(
            icon,
            color: AppColors.textLight,
            size: 16,
          ),
        ),
      );

  @override
  void dispose() {
    _shimmerController.dispose();
    _pulseController.dispose();
    _countdownController.dispose();
    _countdownTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final delay = Duration(milliseconds: (widget.index ?? 0) * 100);

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()..scale(_isPressed ? 0.95 : 1.0),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [
                AppColors.primaryMedium,
                AppColors.primaryDark,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: widget.isHighValue
                  ? AppColors.cyberYellow.withValues(alpha: 0.5)
                  : AppColors.primaryLight,
              width: widget.isHighValue ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isHighValue
                    ? AppColors.cyberYellow.withValues(alpha: 0.2)
                    : AppColors.primaryDark.withValues(alpha: 0.3),
                blurRadius: widget.isHighValue ? 15 : 10,
                spreadRadius: widget.isHighValue ? 3 : 1,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              // High-value shimmer effect
              if (widget.isHighValue) _buildShimmerOverlay(),

              // Main content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with countdown and actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildCountdownTimer(),
                        _buildActionButtons(),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Contest title
                    Text(
                      widget.contest['title'] ?? 'Amazing Contest',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Contest description
                    Text(
                      widget.contest['description'] ?? 'Win amazing prizes!',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textLight,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),

                    // Bottom row with prize value and entry info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildPrizeValue(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color:
                                AppColors.primaryLight.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.people,
                                color: AppColors.textLight,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.contest['entryCount'] ?? 0} entries',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textLight,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // "HOT" badge for high-value contests
              if (widget.isHighValue)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.errorRed, Colors.orange],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.errorRed.withValues(alpha: 0.4),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Text(
                      'HOT 🔥',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                  )
                      .animate()
                      .scale(
                        duration: 400.ms,
                        curve: Curves.elasticOut,
                      )
                      .then(delay: 200.ms)
                      .shake(hz: 2, curve: Curves.easeInOut),
                ),
            ],
          ),
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
}
