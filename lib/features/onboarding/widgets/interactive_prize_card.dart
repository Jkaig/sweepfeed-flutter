import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class InteractivePrizeCard extends StatefulWidget {
  const InteractivePrizeCard({
    required this.title,
    required this.icon,
    required this.description,
    required this.isSelected,
    required this.onTap,
    required this.accentColor,
    super.key,
  });
  final String title;
  final IconData icon;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;
  final Color accentColor;

  @override
  State<InteractivePrizeCard> createState() => _InteractivePrizeCardState();
}

class _InteractivePrizeCardState extends State<InteractivePrizeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void didUpdateWidget(InteractivePrizeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _animationController.forward();
        // Powerful haptic feedback for selection
        HapticFeedback.mediumImpact();
      } else {
        _animationController.reverse();
        HapticFeedback.lightImpact();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
          HapticFeedback.lightImpact();
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
        },
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) => Transform.scale(
            scale: _isPressed ? 0.95 : _scaleAnimation.value,
            child: Container(
              height: 180,
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: widget.isSelected
                    ? LinearGradient(
                        colors: [
                          widget.accentColor.withValues(alpha: 0.8),
                          widget.accentColor.withValues(alpha: 0.6),
                          AppColors.primaryMedium,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : const LinearGradient(
                        colors: [
                          AppColors.primaryMedium,
                          AppColors.primaryDark,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                border: Border.all(
                  color: widget.isSelected
                      ? widget.accentColor
                      : AppColors.primaryLight,
                  width: widget.isSelected ? 3 : 1,
                ),
                boxShadow: [
                  if (widget.isSelected)
                    BoxShadow(
                      color: widget.accentColor
                          .withValues(alpha: 0.5 * _glowAnimation.value),
                      blurRadius: 20 * _glowAnimation.value,
                      spreadRadius: 5 * _glowAnimation.value,
                    ),
                  BoxShadow(
                    color: AppColors.primaryDark.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Animated background particles
                  if (widget.isSelected)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) => Container(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                colors: [
                                  widget.accentColor.withValues(
                                    alpha: 0.1 * _glowAnimation.value,
                                  ),
                                  Colors.transparent,
                                ],
                                stops: const [0.3, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Main content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated Icon with glow
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.isSelected
                                ? widget.accentColor.withValues(alpha: 0.2)
                                : AppColors.primaryLight.withValues(alpha: 0.2),
                            boxShadow: widget.isSelected
                                ? [
                                    BoxShadow(
                                      color: widget.accentColor
                                          .withValues(alpha: 0.4),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            widget.icon,
                            size: 32,
                            color: widget.isSelected
                                ? widget.accentColor
                                : AppColors.textLight,
                          ),
                        )
                            .animate()
                            .scale(
                              duration: 300.ms,
                              curve: Curves.elasticOut,
                            )
                            .then(delay: 100.ms)
                            .shimmer(
                              duration: widget.isSelected ? 1000.ms : 0.ms,
                              color: widget.accentColor,
                            ),
                        const SizedBox(height: 16),
                        // Title with dynamic styling
                        Text(
                          widget.title,
                          style: AppTextStyles.titleLarge.copyWith(
                            color: widget.isSelected
                                ? widget.accentColor
                                : AppColors.textWhite,
                            fontWeight: widget.isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        // Description
                        Text(
                          widget.description,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: widget.isSelected
                                ? AppColors.textWhite
                                : AppColors.textLight,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        // Selection indicator with animation
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: widget.isSelected ? 40 : 20,
                          height: 4,
                          decoration: BoxDecoration(
                            color: widget.isSelected
                                ? widget.accentColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: widget.isSelected
                                ? [
                                    BoxShadow(
                                      color: widget.accentColor,
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Success checkmark animation
                  if (widget.isSelected)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.accentColor,
                          boxShadow: [
                            BoxShadow(
                              color: widget.accentColor.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        ),
                      )
                          .animate()
                          .scale(
                            begin: const Offset(0, 0),
                            end: const Offset(1, 1),
                            duration: 400.ms,
                            curve: Curves.elasticOut,
                          )
                          .then(delay: 100.ms)
                          .shake(hz: 2, curve: Curves.easeInOut),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
}
