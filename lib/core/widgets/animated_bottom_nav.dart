import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Premium animated bottom navigation bar
class AnimatedBottomNav extends StatefulWidget {
  const AnimatedBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.items,
    super.key,
    this.height = 65,
    this.iconSize = 24,
    this.animationDuration = const Duration(milliseconds: 300),
    this.enableHaptic = true,
  });
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AnimatedNavItem> items;
  final double height;
  final double iconSize;
  final Duration animationDuration;
  final bool enableHaptic;

  @override
  State<AnimatedBottomNav> createState() => _AnimatedBottomNavState();
}

class _AnimatedBottomNavState extends State<AnimatedBottomNav>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _iconRotations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.items.length,
      (index) => AnimationController(
        duration: widget.animationDuration,
        vsync: this,
      ),
    );

    _scaleAnimations = _controllers
        .map(
          (controller) => Tween<double>(begin: 1.0, end: 1.2).animate(
            CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
          ),
        )
        .toList();

    _iconRotations = _controllers
        .map(
          (controller) => Tween<double>(begin: 0.0, end: 0.1).animate(
            CurvedAnimation(parent: controller, curve: Curves.easeInOut),
          ),
        )
        .toList();

    // Animate the initially selected item
    if (widget.currentIndex >= 0 && widget.currentIndex < _controllers.length) {
      _controllers[widget.currentIndex].forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      // Animate out old selection
      if (oldWidget.currentIndex >= 0 &&
          oldWidget.currentIndex < _controllers.length) {
        _controllers[oldWidget.currentIndex].reverse();
      }
      // Animate in new selection
      if (widget.currentIndex >= 0 &&
          widget.currentIndex < _controllers.length) {
        _controllers[widget.currentIndex].forward();
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.primaryMedium,
          boxShadow: [
            BoxShadow(
              color: AppColors.cyberYellow.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: widget.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = widget.currentIndex == index;

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  if (widget.enableHaptic) {
                    HapticFeedback.lightImpact();
                  }
                  widget.onTap(index);
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: widget.height,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _controllers[index],
                        builder: (context, child) => Transform.scale(
                          scale: _scaleAnimations[index].value,
                          child: Transform.rotate(
                            angle: _iconRotations[index].value,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Glow effect for selected item
                                if (isSelected)
                                  Container(
                                    width: widget.iconSize + 20,
                                    height: widget.iconSize + 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.cyberYellow
                                              .withValues(alpha: 0.5),
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                Icon(
                                  isSelected ? item.activeIcon : item.icon,
                                  size: widget.iconSize,
                                  color: isSelected
                                      ? AppColors.cyberYellow
                                      : AppColors.textMuted,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedDefaultTextStyle(
                        duration: widget.animationDuration,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isSelected
                              ? AppColors.cyberYellow
                              : AppColors.textMuted,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        child: Text(item.label),
                      ),
                      // Active indicator dot
                      AnimatedContainer(
                        duration: widget.animationDuration,
                        margin: const EdgeInsets.only(top: 4),
                        width: isSelected ? 6 : 0,
                        height: isSelected ? 6 : 0,
                        decoration: BoxDecoration(
                          color: AppColors.cyberYellow,
                          shape: BoxShape.circle,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.cyberYellow
                                        .withValues(alpha: 0.8),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : [],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
}

/// Data class for navigation items
class AnimatedNavItem {
  const AnimatedNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
  final IconData icon;
  final IconData activeIcon;
  final String label;
}
