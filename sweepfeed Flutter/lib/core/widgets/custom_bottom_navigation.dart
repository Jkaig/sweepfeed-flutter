import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';

/// Custom Bottom Navigation Bar with Animations and Badges
class CustomBottomNavigation extends StatefulWidget {
  const CustomBottomNavigation({
    required this.currentIndex,
    required this.onTap,
    required this.items,
    super.key,
    this.backgroundColor,
    this.height = 70,
  });
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavItem> items;
  final Color? backgroundColor;
  final double height;

  @override
  State<CustomBottomNavigation> createState() => _CustomBottomNavigationState();
}

class _CustomBottomNavigationState extends State<CustomBottomNavigation>
    with TickerProviderStateMixin {
  late List<AnimationController> _itemControllers;
  late AnimationController _indicatorController;
  late AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    _itemControllers = List.generate(
      widget.items.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      ),
    );

    _indicatorController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Animate the initially selected item
    if (widget.currentIndex >= 0 &&
        widget.currentIndex < _itemControllers.length) {
      _itemControllers[widget.currentIndex].forward();
    }
  }

  @override
  void didUpdateWidget(CustomBottomNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _animateToIndex(widget.currentIndex);
    }
  }

  void _animateToIndex(int index) {
    // Reset previous item
    for (var i = 0; i < _itemControllers.length; i++) {
      if (i != index) {
        _itemControllers[i].reverse();
      }
    }

    // Animate new item
    _itemControllers[index].forward();
    _indicatorController.forward(from: 0);
    _rippleController.forward(from: 0);
  }

  @override
  void dispose() {
    for (final controller in _itemControllers) {
      controller.dispose();
    }
    _indicatorController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
        height: widget.height + MediaQuery.of(context).padding.bottom,
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? AppColors.primaryMedium,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Moving indicator
            AnimatedBuilder(
              animation: _indicatorController,
              builder: (context, child) {
                final itemWidth =
                    MediaQuery.of(context).size.width / widget.items.length;
                final indicatorPosition = widget.currentIndex * itemWidth;

                return Positioned(
                  left: indicatorPosition + itemWidth * 0.25,
                  top: 0,
                  child: Container(
                    width: itemWidth * 0.5,
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.cyberYellow,
                          AppColors.mangoTangoStart,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cyberYellow.withValues(alpha: 0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Navigation items
            SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: widget.items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isSelected = index == widget.currentIndex;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onTap(index);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: _buildNavItem(
                        item: item,
                        isSelected: isSelected,
                        controller: _itemControllers[index],
                        index: index,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      );

  Widget _buildNavItem({
    required BottomNavItem item,
    required bool isSelected,
    required AnimationController controller,
    required int index,
  }) =>
      SizedBox(
        height: widget.height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ripple effect on selection
            if (isSelected)
              AnimatedBuilder(
                animation: _rippleController,
                builder: (context, child) => Transform.scale(
                  scale: _rippleController.value * 2,
                  child: Opacity(
                    opacity: 1 - _rippleController.value,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: item.activeColor.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
              ),

            // Main item content
            AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                final scale = 1.0 + controller.value * 0.2;
                final yOffset = -controller.value * 5;

                return Transform.translate(
                  offset: Offset(0, yOffset),
                  child: Transform.scale(
                    scale: scale,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon with badge
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Icon with glow effect
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: isSelected
                                  ? BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: item.activeColor
                                              .withValues(alpha: 0.3),
                                          blurRadius: 15,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    )
                                  : null,
                              child: Icon(
                                isSelected ? item.activeIcon : item.icon,
                                color: isSelected
                                    ? item.activeColor
                                    : Colors.white.withValues(alpha: 0.5),
                                size: 24,
                              ),
                            ),

                            // Badge
                            if (item.badgeCount > 0)
                              Positioned(
                                right: -4,
                                top: -4,
                                child: _buildBadge(
                                    item.badgeCount, item.badgeColor),
                              ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        // Label
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            color: isSelected
                                ? item.activeColor
                                : Colors.white.withValues(alpha: 0.5),
                            fontSize: isSelected ? 12 : 10,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          child: Text(item.label),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      )
          .animate(delay: Duration(milliseconds: index * 50))
          .fadeIn()
          .slideY(begin: 0.3, end: 0);

  Widget _buildBadge(int count, Color? color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color ?? AppColors.mangoTangoStart,
              (color ?? AppColors.mangoTangoEnd).withValues(alpha: 0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color:
                  (color ?? AppColors.mangoTangoStart).withValues(alpha: 0.5),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        constraints: const BoxConstraints(
          minWidth: 18,
          minHeight: 18,
        ),
        child: Center(
          child: Text(
            count > 99 ? '99+' : '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ).animate().scale(
            begin: const Offset(0, 0),
            end: const Offset(1, 1),
            duration: 300.ms,
            curve: Curves.elasticOut,
          );
}

/// Bottom Navigation Item Model
class BottomNavItem {
  const BottomNavItem({
    required this.icon,
    required this.label,
    IconData? activeIcon,
    this.activeColor = AppColors.cyberYellow,
    this.badgeCount = 0,
    this.badgeColor,
  }) : activeIcon = activeIcon ?? icon;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color activeColor;
  final int badgeCount;
  final Color? badgeColor;
}

/// Floating Bottom Navigation Bar (Alternative Style)
class FloatingBottomNavigation extends StatefulWidget {
  const FloatingBottomNavigation({
    required this.currentIndex,
    required this.onTap,
    required this.items,
    super.key,
  });
  final int currentIndex;
  final Function(int) onTap;
  final List<FloatingNavItem> items;

  @override
  State<FloatingBottomNavigation> createState() =>
      _FloatingBottomNavigationState();
}

class _FloatingBottomNavigationState extends State<FloatingBottomNavigation>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _floatController,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, math.sin(_floatController.value * math.pi * 2) * 3),
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(
                colors: [
                  AppColors.primaryMedium,
                  AppColors.primaryLight,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: const ColorFilter.mode(
                  Colors.transparent,
                  BlendMode.multiply,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: widget.items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final isSelected = index == widget.currentIndex;

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onTap(index);
                      },
                      child: _buildFloatingItem(item, isSelected, index),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _buildFloatingItem(FloatingNavItem item, bool isSelected, int index) =>
      AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 12,
          vertical: 12,
        ),
        decoration: isSelected
            ? BoxDecoration(
                color: item.color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              )
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              color:
                  isSelected ? item.color : Colors.white.withValues(alpha: 0.5),
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                item.label,
                style: TextStyle(
                  color: item.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      )
          .animate(delay: Duration(milliseconds: index * 50))
          .fadeIn()
          .scale(duration: 300.ms);
}

/// Floating Navigation Item Model
class FloatingNavItem {
  const FloatingNavItem({
    required this.icon,
    required this.label,
    this.color = AppColors.cyberYellow,
  });
  final IconData icon;
  final String label;
  final Color color;
}

/// Curved Bottom Navigation Bar (Alternative Style)
class CurvedBottomNavigation extends StatelessWidget {
  const CurvedBottomNavigation({
    required this.currentIndex,
    required this.onTap,
    required this.icons,
    super.key,
    this.backgroundColor,
    this.activeColor,
  });
  final int currentIndex;
  final Function(int) onTap;
  final List<IconData> icons;
  final Color? backgroundColor;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 80,
        child: Stack(
          children: [
            // Curved background
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: CustomPaint(
                size: Size(MediaQuery.of(context).size.width, 80),
                painter: CurvedNavigationPainter(
                  backgroundColor: backgroundColor ?? AppColors.primaryMedium,
                  selectedIndex: currentIndex,
                  itemCount: icons.length,
                ),
              ),
            ),

            // Icons
            Positioned.fill(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: icons.asMap().entries.map((entry) {
                  final index = entry.key;
                  final icon = entry.value;
                  final isSelected = index == currentIndex;

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onTap(index);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: isSelected
                          ? BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  (activeColor ?? AppColors.cyberYellow)
                                      .withValues(alpha: 0.3),
                                  (activeColor ?? AppColors.cyberYellow)
                                      .withValues(alpha: 0.1),
                                ],
                              ),
                            )
                          : null,
                      child: Icon(
                        icon,
                        color: isSelected
                            ? activeColor ?? AppColors.cyberYellow
                            : Colors.white.withValues(alpha: 0.5),
                        size: isSelected ? 28 : 24,
                      ),
                    ).animate(target: isSelected ? 1 : 0).scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.2, 1.2),
                          duration: 300.ms,
                        ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      );
}

// Custom painter for curved navigation
class CurvedNavigationPainter extends CustomPainter {
  CurvedNavigationPainter({
    required this.backgroundColor,
    required this.selectedIndex,
    required this.itemCount,
  });
  final Color backgroundColor;
  final int selectedIndex;
  final int itemCount;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final path = Path();
    final itemWidth = size.width / itemCount;
    final curveStart = selectedIndex * itemWidth;
    final curveEnd = (selectedIndex + 1) * itemWidth;

    path.moveTo(0, 20);

    // Draw curve for selected item
    for (double x = 0; x <= size.width; x += 1) {
      double y = 20;

      if (x >= curveStart && x <= curveEnd) {
        final relativeX = (x - curveStart) / itemWidth;
        y = 20 - math.sin(relativeX * math.pi) * 15;
      }

      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    // Add shadow
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.3), 10, false);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
