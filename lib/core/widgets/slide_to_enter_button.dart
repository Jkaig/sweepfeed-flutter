import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Epic slide-to-confirm button with confetti celebration
class SlideToEnterButton extends StatefulWidget {
  const SlideToEnterButton({
    required this.onConfirmed,
    super.key,
    this.text = 'SLIDE TO ENTER',
    this.height = 70,
    this.slideDuration = const Duration(milliseconds: 300),
    this.enabled = true,
  });
  final VoidCallback onConfirmed;
  final String text;
  final double height;
  final Duration slideDuration;
  final bool enabled;

  @override
  State<SlideToEnterButton> createState() => _SlideToEnterButtonState();
}

class _SlideToEnterButtonState extends State<SlideToEnterButton>
    with TickerProviderStateMixin {
  static const double _thumbSize = 60;
  static const double _padding = 5;

  late ConfettiController _confettiController;
  late AnimationController _resetController;
  late AnimationController _pulseController;
  late AnimationController _successController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _successScaleAnimation;
  late Animation<double> _successFadeAnimation;

  double _dragPosition = 0;
  double _maxDragPosition = 0;
  bool _isDragging = false;
  bool _isConfirmed = false;
  bool _isResetting = false;

  @override
  void initState() {
    super.initState();

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _successScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _successController,
        curve: Curves.easeInBack,
      ),
    );

    _successFadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _successController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _resetController.dispose();
    _pulseController.dispose();
    _successController.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails details) {
    if (!widget.enabled || _isConfirmed) return;

    setState(() {
      _isDragging = true;
    });
    HapticFeedback.lightImpact();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!widget.enabled || _isConfirmed) return;

    setState(() {
      _dragPosition =
          (_dragPosition + details.delta.dx).clamp(0.0, _maxDragPosition);

      // Haptic feedback at intervals
      final progress = _dragPosition / _maxDragPosition;
      if ((progress * 10).floor() != ((progress - 0.1) * 10).floor()) {
        HapticFeedback.selectionClick();
      }
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (!widget.enabled || _isConfirmed) return;

    final progress = _dragPosition / _maxDragPosition;

    if (progress >= 0.95) {
      // Confirmed!
      _handleConfirmation();
    } else {
      // Reset
      _resetSlider();
    }

    setState(() {
      _isDragging = false;
    });
  }

  void _handleConfirmation() {
    setState(() {
      _isConfirmed = true;
      _dragPosition = _maxDragPosition;
    });

    // Trigger success animations
    HapticFeedback.heavyImpact();
    _successController.forward();
    _confettiController.play();

    // Call the callback
    widget.onConfirmed();

    // Reset after celebration
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _resetSlider();
        setState(() {
          _isConfirmed = false;
        });
        _successController.reset();
      }
    });
  }

  void _resetSlider() {
    if (_isResetting) return;

    _isResetting = true;
    _resetController.forward().then((_) {
      if (mounted) {
        setState(() {
          _dragPosition = 0;
          _isResetting = false;
        });
        _resetController.reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          _maxDragPosition = constraints.maxWidth - _thumbSize - (2 * _padding);
          final progress = _dragPosition / _maxDragPosition;

          return Stack(
            alignment: Alignment.center,
            children: [
              // Main button container
              AnimatedBuilder(
                animation: _successController,
                builder: (context, child) => Transform.scale(
                  scale: _isConfirmed ? _successScaleAnimation.value : 1.0,
                  child: Opacity(
                    opacity: _isConfirmed ? _successFadeAnimation.value : 1.0,
                    child: Container(
                      height: widget.height,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(widget.height / 2),
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryMedium,
                            AppColors.primaryLight.withValues(alpha: 0.8),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.cyberYellow.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Progress fill
                          AnimatedContainer(
                            duration: _isResetting
                                ? _resetController.duration!
                                : Duration.zero,
                            width: _dragPosition + _thumbSize,
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(widget.height / 2),
                              gradient: AppColors.primaryGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.mangoTangoStart
                                      .withValues(alpha: 0.5),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),

                          // Text
                          Center(
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: _isDragging ? 0.5 : 1.0,
                              child: Text(
                                _isConfirmed
                                    ? 'ENTERING...'
                                    : progress > 0.5
                                        ? 'ALMOST THERE!'
                                        : widget.text,
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: progress > 0.3
                                      ? AppColors.textWhite
                                      : AppColors.cyberYellow,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),

                          // Draggable thumb
                          AnimatedPositioned(
                            duration: _isResetting
                                ? _resetController.duration!
                                : Duration.zero,
                            left: _dragPosition + _padding,
                            top: _padding,
                            child: GestureDetector(
                              onHorizontalDragStart: _onDragStart,
                              onHorizontalDragUpdate: _onDragUpdate,
                              onHorizontalDragEnd: _onDragEnd,
                              child: AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) => Transform.scale(
                                  scale:
                                      _isDragging ? 1.1 : _pulseAnimation.value,
                                  child: Container(
                                    width: _thumbSize,
                                    height: _thumbSize,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          AppColors.cyberYellow,
                                          AppColors.mangoTangoStart,
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.cyberYellow
                                              .withValues(alpha: 0.6),
                                          blurRadius: _isDragging ? 30 : 20,
                                          spreadRadius: _isDragging ? 5 : 2,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: AppColors.primaryDark,
                                      size: 30,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Confetti overlay
              Align(
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  maxBlastForce: 50,
                  minBlastForce: 20,
                  emissionFrequency: 0.05,
                  numberOfParticles: 50,
                  colors: const [
                    AppColors.cyberYellow,
                    AppColors.mangoTangoStart,
                    AppColors.mangoTangoEnd,
                    AppColors.electricBlue,
                    AppColors.successGreen,
                  ],
                  strokeWidth: 1,
                  strokeColor: AppColors.cyberYellow,
                ),
              ),

              // Success checkmark
              if (_isConfirmed)
                AnimatedBuilder(
                  animation: _successController,
                  builder: (context, child) => Transform.scale(
                    scale: _successController.value,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.successGreen,
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.successGreen.withValues(alpha: 0.5),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      );
}
