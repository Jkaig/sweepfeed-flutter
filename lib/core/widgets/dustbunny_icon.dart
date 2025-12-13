import 'package:flutter/material.dart';

/// A reusable DustBunny character icon widget
///
/// Displays the cute DustBunny character icon with configurable size and color tinting.
/// Used throughout the app to represent DustBunnies (DB) currency.
class DustBunnyIcon extends StatelessWidget {
  const DustBunnyIcon({
    super.key,
    this.size = 20.0,
    this.tintColor,
  });

  /// Size of the icon (width and height)
  final double size;

  /// Optional color to tint the icon. If null, uses original colors.
  final Color? tintColor;

  @override
  Widget build(BuildContext context) => SizedBox(
      width: size,
      height: size,
      child: tintColor != null
          ? ColorFiltered(
              colorFilter: ColorFilter.mode(tintColor!, BlendMode.srcIn),
              child: Image.asset(
                'assets/images/dustbunnies/dustbunny_icon.png',
                width: size,
                height: size,
                fit: BoxFit.contain,
              ),
            )
          : Image.asset(
              'assets/images/dustbunnies/dustbunny_icon.png',
              width: size,
              height: size,
              fit: BoxFit.contain,
            ),
    );
}

/// An animated version of the DustBunny icon for rewards and celebrations
class AnimatedDustBunnyIcon extends StatefulWidget {
  const AnimatedDustBunnyIcon({
    super.key,
    this.size = 20.0,
    this.tintColor,
    this.animate = true,
  });

  /// Size of the icon (width and height)
  final double size;

  /// Optional color to tint the icon. If null, uses original colors.
  final Color? tintColor;

  /// Whether to animate the icon
  final bool animate;

  @override
  State<AnimatedDustBunnyIcon> createState() => _AnimatedDustBunnyIconState();
}

class _AnimatedDustBunnyIconState extends State<AnimatedDustBunnyIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.animate) {
      // Trigger animation once on creation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerAnimation();
      });
    }
  }

  void _triggerAnimation() {
    if (mounted && widget.animate) {
      _controller.reset();
      _controller.forward().then((_) {
        if (mounted) {
          _controller.reverse();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: DustBunnyIcon(
            size: widget.size,
            tintColor: widget.tintColor,
          ),
        ),
    );
}
