import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/dustbunnies_display.dart';

class SwipeToEnterCard extends StatefulWidget {
  const SwipeToEnterCard({
    required this.contest,
    required this.onEntered,
    super.key,
    this.isHighValue = false,
  });
  final Map<String, dynamic> contest;
  final VoidCallback onEntered;
  final bool isHighValue;

  @override
  State<SwipeToEnterCard> createState() => _SwipeToEnterCardState();
}

class _SwipeToEnterCardState extends State<SwipeToEnterCard>
    with TickerProviderStateMixin {
  late AnimationController _swipeController;
  late AnimationController _celebrationController;
  late AnimationController _pulseController;
  late ConfettiController _confettiController;

  double _swipeProgress = 0.0;
  bool _isEntered = false;
  bool _isSwipeActive = false;
  Timer? _resetTimer;

  // Entry animation states
  bool _showSuccess = false;
  int _entryNumber = 0;

  @override
  void initState() {
    super.initState();

    _swipeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    // Generate random entry number for demo
    _entryNumber = 1234 + Random().nextInt(8766);
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_isEntered) return;

    setState(() {
      _isSwipeActive = true;
      _swipeProgress =
          (_swipeProgress + details.primaryDelta! / 200).clamp(0.0, 1.0);
    });

    // Haptic feedback at different stages
    if (_swipeProgress > 0.3 && _swipeProgress < 0.35) {
      HapticFeedback.lightImpact();
    } else if (_swipeProgress > 0.6 && _swipeProgress < 0.65) {
      HapticFeedback.mediumImpact();
    } else if (_swipeProgress > 0.9 && _swipeProgress < 0.95) {
      HapticFeedback.heavyImpact();
    }

    // Complete entry when fully swiped
    if (_swipeProgress >= 1.0) {
      _completeEntry();
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_isEntered) return;

    setState(() => _isSwipeActive = false);

    // Reset if not completed
    if (_swipeProgress < 1.0) {
      _swipeController.forward().then((_) {
        setState(() => _swipeProgress = 0.0);
        _swipeController.reset();
      });

      // Auto-reset timer
      _resetTimer?.cancel();
      _resetTimer = Timer(const Duration(milliseconds: 800), () {
        if (mounted && _swipeProgress < 1.0) {
          setState(() => _swipeProgress = 0.0);
        }
      });
    }
  }

  Future<void> _completeEntry() async {
    if (_isEntered) return;

    setState(() {
      _isEntered = true;
      _showSuccess = true;
    });

    // Epic celebration sequence
    HapticFeedback.heavyImpact();

    // Start confetti
    _confettiController.play();

    // Start celebration animation
    _celebrationController.forward();

    // Multiple haptic pulses for success
    Future.delayed(
      const Duration(milliseconds: 100),
      HapticFeedback.mediumImpact,
    );
    Future.delayed(
      const Duration(milliseconds: 200),
      HapticFeedback.lightImpact,
    );
    Future.delayed(
      const Duration(milliseconds: 300),
      HapticFeedback.lightImpact,
    );

    // Call callback
    widget.onEntered();

    // Auto-hide success after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showSuccess = false);
      }
    });
  }

  Widget _buildSwipeTrack() => Container(
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryLight.withValues(alpha: 0.3),
              AppColors.primaryMedium.withValues(alpha: 0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: widget.isHighValue
                ? AppColors.cyberYellow
                : AppColors.primaryLight,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            // Progress fill
            AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: MediaQuery.of(context).size.width * 0.8 * _swipeProgress,
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.cyberYellow,
                    AppColors.mangoTangoStart,
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
              ),
            ),

            // Swipe indicator
            AnimatedPositioned(
              duration: const Duration(milliseconds: 100),
              left: (MediaQuery.of(context).size.width * 0.8 - 56) *
                  _swipeProgress,
              top: 2,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      AppColors.cyberYellow.withValues(alpha: 0.9),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cyberYellow.withValues(alpha: 0.5),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  _swipeProgress > 0.8 ? Icons.check : Icons.chevron_right,
                  color: AppColors.primaryDark,
                  size: 28,
                ),
              )
                  .animate(
                    target: _isSwipeActive ? 1 : 0,
                  )
                  .scale(
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(1.1, 1.1),
                    duration: 150.ms,
                  ),
            ),

            // Instruction text
            Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _swipeProgress < 0.5 ? 1.0 : 0.0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.swipe,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Swipe to Enter',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Progress text
            Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _swipeProgress >= 0.5 ? 1.0 : 0.0,
                child: Text(
                  _swipeProgress >= 1.0 ? 'ENTERED!' : 'Keep Swiping...',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildSuccessOverlay() => AnimatedPositioned(
        duration: const Duration(milliseconds: 500),
        top: _showSuccess ? 0 : -100,
        left: 0,
        right: 0,
        child: Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppColors.successGreen,
                AppColors.cyberYellow,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.successGreen.withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(
                Icons.celebration,
                color: Colors.white,
                size: 40,
              )
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.elasticOut)
                  .then()
                  .shake(hz: 3, duration: 400.ms),
              const SizedBox(height: 12),
              Text(
                'ENTRY CONFIRMED!',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Entry #$_entryNumber',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatChip('🎯', 'Entries Today: 3'),
                  _buildStatChip('🔥', '5-Day Streak!'),
                  _buildStatChipWithDB(50),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildStatChip(String emoji, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );

  Widget _buildStatChipWithDB(int amount) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: CompactDustBunniesDisplay(
          amount: amount,
          showPlus: true,
          color: Colors.white,
          fontSize: 11,
        ),
      );

  @override
  void dispose() {
    _swipeController.dispose();
    _celebrationController.dispose();
    _pulseController.dispose();
    _confettiController.dispose();
    _resetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          // Main swipe area
          GestureDetector(
            onPanUpdate: _handlePanUpdate,
            onPanEnd: _handlePanEnd,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    if (widget.isHighValue)
                      AppColors.primaryMedium.withValues(alpha: 0.9)
                    else
                      AppColors.primaryLight.withValues(alpha: 0.8),
                    if (widget.isHighValue)
                      AppColors.primaryDark
                    else
                      AppColors.primaryMedium,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: widget.isHighValue
                      ? AppColors.cyberYellow.withValues(alpha: 0.6)
                      : AppColors.primaryLight.withValues(alpha: 0.4),
                  width: widget.isHighValue ? 3 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.isHighValue
                        ? AppColors.cyberYellow.withValues(alpha: 0.3)
                        : AppColors.primaryDark.withValues(alpha: 0.3),
                    blurRadius: widget.isHighValue ? 20 : 15,
                    spreadRadius: widget.isHighValue ? 4 : 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Contest header
                  Row(
                    children: [
                      if (widget.isHighValue) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.cyberYellow, Colors.orange],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'HOT 🔥',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Text(
                          widget.contest['title'] ?? 'Amazing Contest',
                          style: AppTextStyles.titleLarge.copyWith(
                            color: AppColors.textWhite,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Prize value
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.cyberYellow,
                          AppColors.mangoTangoStart,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cyberYellow.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Text(
                      '\$${widget.contest['prizeValue'] ?? '1,000'}',
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Swipe track
                  if (!_isEntered) _buildSwipeTrack(),

                  // Entry confirmation message
                  if (_isEntered && !_showSuccess)
                    Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.successGreen,
                            AppColors.cyberYellow
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: Text(
                          'ENTERED! Good luck! 🍀',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    )
                        .animate()
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          duration: 400.ms,
                          curve: Curves.elasticOut,
                        )
                        .then()
                        .shimmer(
                          duration: 1000.ms,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                ],
              ),
            ),
          ),

          // Confetti overlay
          Positioned.fill(
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [
                AppColors.cyberYellow,
                AppColors.successGreen,
                AppColors.mangoTangoStart,
                Colors.orange,
                Colors.purple,
              ],
              numberOfParticles: 150,
              gravity: 0.3,
            ),
          ),

          // Success overlay
          _buildSuccessOverlay(),
        ],
      );
}
