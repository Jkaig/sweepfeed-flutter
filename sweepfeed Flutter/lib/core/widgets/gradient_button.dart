import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// High-energy gradient button with haptic feedback and glow effect
class GradientButton extends StatefulWidget {
  const GradientButton({
    required this.text,
    required this.onPressed,
    super.key,
    this.isLoading = false,
    this.width,
    this.height = 56,
    this.icon,
    this.enableGlow = true,
    this.enableHaptic = true,
  });
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final double height;
  final IconData? icon;
  final bool enableGlow;
  final bool enableHaptic;

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.enableGlow) {
      // Continuous glow pulse animation
      _glowAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeInOut,
        ),
      );

      // Start continuous pulse if enabled
      _startGlowPulse();
    }
  }

  void _startGlowPulse() {
    if (widget.enableGlow && widget.onPressed != null && !widget.isLoading) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(GradientButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enableGlow != oldWidget.enableGlow ||
        widget.onPressed != oldWidget.onPressed ||
        widget.isLoading != oldWidget.isLoading) {
      if (widget.enableGlow && widget.onPressed != null && !widget.isLoading) {
        _startGlowPulse();
      } else {
        _animationController.stop();
        _animationController.reset();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = true);
      _animationController.forward();
      if (widget.enableHaptic) {
        HapticFeedback.lightImpact();
      }
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isPressed) {
      setState(() => _isPressed = false);
      _animationController.reverse();
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: isDisabled
          ? null
          : () {
              if (widget.enableHaptic) {
                HapticFeedback.selectionClick();
              }
              widget.onPressed!();
            },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) => Transform.scale(
          scale: _isPressed ? _scaleAnimation.value : 1.0,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: isDisabled
                  ? LinearGradient(
                      colors: [
                        AppColors.textMuted.withValues(alpha: 0.5),
                        AppColors.textMuted.withValues(alpha: 0.3),
                      ],
                    )
                  : AppColors.primaryGradient,
              boxShadow: widget.enableGlow && !isDisabled
                  ? [
                      BoxShadow(
                        color: AppColors.mangoTangoStart.withValues(
                          alpha: 0.3 + (_glowAnimation.value * 0.2),
                        ),
                        blurRadius: 20 + (_glowAnimation.value * 10),
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isDisabled ? null : widget.onPressed,
                borderRadius: BorderRadius.circular(16),
                splashColor: AppColors.cyberYellow.withValues(alpha: 0.3),
                highlightColor: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Center(
                    child: widget.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.textWhite,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (widget.icon != null) ...[
                                Icon(
                                  widget.icon,
                                  color: AppColors.textWhite,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                widget.text.toUpperCase(),
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: AppColors.textWhite,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
