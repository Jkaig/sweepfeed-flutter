import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';

import '../../constants/app_constants.dart';
import '../theme/app_colors.dart';
import 'dustbunnies_display.dart';
import 'dustbunny_icon.dart';

/// Animated DustBunnies Bar with level display
///
/// Displays user's current DustBunnies (DB) progress toward next level.
/// Widget name kept as `AnimatedXPBar` for backward compatibility.
class AnimatedXPBar extends StatefulWidget {
  const AnimatedXPBar({
    required this.currentDB,
    required this.requiredDB,
    required this.level,
    super.key,
    this.onLevelUp,
    @Deprecated('Use currentDB instead. SweepPoints is now DustBunnies (DB).')
    this.currentSP,
    @Deprecated('Use currentDB instead. XP is now DustBunnies (DB).')
    this.currentXP,
    @Deprecated('Use requiredDB instead. SweepPoints is now DustBunnies (DB).')
    this.requiredSP,
    @Deprecated('Use requiredDB instead. XP is now DustBunnies (DB).')
    this.requiredXP,
  });

  /// Current DustBunnies toward next level
  final int currentDB;

  /// DustBunnies required to reach next level
  final int requiredDB;

  /// Current user level
  final int level;

  /// Callback when user levels up
  final VoidCallback? onLevelUp;

  /// @deprecated Use currentDB instead. SweepPoints is now DustBunnies (DB).
  final int? currentSP;

  /// @deprecated Use currentDB instead. XP is now DustBunnies (DB).
  final int? currentXP;

  /// @deprecated Use requiredDB instead. SweepPoints is now DustBunnies (DB).
  final int? requiredSP;

  /// @deprecated Use requiredDB instead. XP is now DustBunnies (DB).
  final int? requiredXP;

  @override
  State<AnimatedXPBar> createState() => _AnimatedXPBarState();
}

class _AnimatedXPBarState extends State<AnimatedXPBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  double _previousProgress = 0;

  int get currentDB => widget.currentDB;
  int get requiredDB => widget.requiredDB;

  /// Backward compatibility getters
  @Deprecated('Use currentDB instead. SweepPoints is now DustBunnies (DB).')
  int get currentSP => currentDB;

  @Deprecated('Use currentDB instead. XP is now DustBunnies (DB).')
  int get currentXP => currentDB;

  @Deprecated('Use requiredDB instead. SweepPoints is now DustBunnies (DB).')
  int get requiredSP => requiredDB;

  @Deprecated('Use requiredDB instead. XP is now DustBunnies (DB).')
  int get requiredXP => requiredDB;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _updateProgress();
  }

  @override
  void didUpdateWidget(AnimatedXPBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.currentDB != currentDB ||
        oldWidget.requiredDB != requiredDB) {
      _updateProgress();

      // Check for level up
      if (widget.level > oldWidget.level) {
        widget.onLevelUp?.call();
        HapticFeedback.heavyImpact();
      }
    }
  }

  void _updateProgress() {
    final newProgress = currentDB / requiredDB;

    _progressAnimation = Tween<double>(
      begin: _previousProgress,
      end: newProgress.clamp(0.0, 1.0),
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _animationController.forward(from: 0);
    _previousProgress = newProgress;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
        height: WidgetSizeConstants.kSmallContainerHeight,
        padding: LayoutConstants.kSmallPaddingAll,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withValues(alpha: 0.3),
              Colors.black.withValues(alpha: 0.1),
            ],
          ),
          borderRadius:
              BorderRadius.circular(UIConstants.kExtraLargeBorderRadius),
          border: Border.all(
            color: AppColors.cyberYellow.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            // Level badge
            Container(
              width: WidgetSizeConstants.kLargeAvatarRadius,
              height: WidgetSizeConstants.kLargeAvatarRadius,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.cyberYellow,
                    AppColors.electricBlue,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cyberYellow.withValues(alpha: 0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${widget.level}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
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
                  duration: 2.seconds,
                ),

            const SizedBox(width: 12),

            // DustBunnies Progress bar
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Level ${widget.level}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      CompactDustBunniesDisplay(
                        amount: currentDB,
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 10,
                      ),
                      Text(
                        ' / $requiredDB DB',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Progress bar
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) => Stack(
                        children: [
                          // Progress fill
                          FractionallySizedBox(
                            widthFactor: _progressAnimation.value,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.cyberYellow,
                                    AppColors.neonGreen,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.cyberYellow
                                        .withValues(alpha: 0.5),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Shimmer effect
                          if (_progressAnimation.value > 0)
                            FractionallySizedBox(
                              widthFactor: _progressAnimation.value,
                              child: Shimmer.fromColors(
                                baseColor: Colors.transparent,
                                highlightColor:
                                    Colors.white.withValues(alpha: 0.3),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

// Level up animation overlay
class LevelUpAnimation extends StatefulWidget {
  const LevelUpAnimation({
    required this.newLevel,
    required this.onComplete,
    super.key,
  });
  final int newLevel;
  final VoidCallback onComplete;

  @override
  State<LevelUpAnimation> createState() => _LevelUpAnimationState();
}

class _LevelUpAnimationState extends State<LevelUpAnimation>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _confettiController.play();
    _animationController.forward().then((_) {
      widget.onComplete();
    });

    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Positioned.fill(
        child: Container(
          color: Colors.black.withValues(alpha: 0.7),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Confetti
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  colors: const [
                    AppColors.cyberYellow,
                    AppColors.electricBlue,
                    AppColors.neonGreen,
                    Colors.orange,
                    Colors.purple,
                  ],
                  numberOfParticles: 50,
                ),
              ),

              // Level up content
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // DustBunny celebration with star burst
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.cyberYellow.withValues(alpha: 0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background star
                        const Icon(
                          Icons.star,
                          size: 100,
                          color: AppColors.cyberYellow,
                        )
                            .animate()
                            .scale(
                              begin: const Offset(0, 0),
                              end: const Offset(1, 1),
                              duration: 500.ms,
                            )
                            .then()
                            .rotate(
                              begin: 0,
                              end: 1,
                              duration: 1500.ms,
                            ),

                        // Celebrating DustBunny
                        const AnimatedDustBunnyIcon(
                          size: 60,
                          tintColor: Colors.white,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'LEVEL UP!',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      foreground: Paint()
                        ..shader = const LinearGradient(
                          colors: [
                            AppColors.cyberYellow,
                            AppColors.electricBlue,
                          ],
                        ).createShader(
                          const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0),
                        ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .scale(
                        begin: const Offset(0.5, 0.5),
                        end: const Offset(1, 1),
                      )
                      .then()
                      .shake(duration: 200.ms),

                  const SizedBox(height: 10),

                  Text(
                    'Level ${widget.newLevel}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 20),

                  // Rewards preview
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                          UIConstants.kExtraLargeBorderRadius,),
                      border: Border.all(
                        color: AppColors.cyberYellow.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.card_giftcard,
                          color: AppColors.cyberYellow,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'New rewards unlocked!',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 1000.ms).scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1, 1),
                      ),
                ],
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 200.ms)
            .then(delay: 2500.ms)
            .fadeOut(duration: 300.ms),
      );
}

/// DustBunnies gain floating animation
///
/// Shows floating "+X DB" text when user earns DustBunnies.
/// Widget name kept as `XPGainAnimation` for backward compatibility.
class XPGainAnimation extends StatefulWidget {
  const XPGainAnimation({
    required this.dbAmount,
    required this.startPosition,
    super.key,
    @Deprecated('Use dbAmount instead. SweepPoints is now DustBunnies (DB).')
    this.spAmount,
    @Deprecated('Use dbAmount instead. XP is now DustBunnies (DB).')
    this.xpAmount,
  });

  /// Amount of DustBunnies gained
  final int dbAmount;

  /// Starting position for animation
  final Offset startPosition;

  /// @deprecated Use dbAmount instead. SweepPoints is now DustBunnies (DB).
  final int? spAmount;

  /// @deprecated Use dbAmount instead. XP is now DustBunnies (DB).
  final int? xpAmount;

  @override
  State<XPGainAnimation> createState() => _XPGainAnimationState();
}

class _XPGainAnimationState extends State<XPGainAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _positionAnimation;
  late Animation<double> _opacityAnimation;

  int get dbAmount => widget.dbAmount;

  /// Backward compatibility getters
  @Deprecated('Use dbAmount instead. SweepPoints is now DustBunnies (DB).')
  int get spAmount => dbAmount;

  @Deprecated('Use dbAmount instead. XP is now DustBunnies (DB).')
  int get xpAmount => dbAmount;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _positionAnimation = Tween<Offset>(
      begin: widget.startPosition,
      end: Offset(
        widget.startPosition.dx + (math.Random().nextDouble() - 0.5) * 100,
        widget.startPosition.dy - 100,
      ),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Positioned(
          left: _positionAnimation.value.dx,
          top: _positionAnimation.value.dy,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.cyberYellow,
                    AppColors.neonGreen,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cyberYellow.withValues(alpha: 0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: DustBunniesRewardDisplay(
                amount: dbAmount,
                color: Colors.black,
              ),
            ),
          ),
        ),
      );
}
