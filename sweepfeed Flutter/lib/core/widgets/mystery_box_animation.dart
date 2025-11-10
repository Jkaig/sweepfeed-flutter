import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../features/mystery/services/mystery_box_service.dart';
import '../theme/app_colors.dart';
import 'animated_backgrounds.dart';
import 'dustbunnies_display.dart';

// Mystery box 3D widget with floating animation
class MysteryBoxWidget extends StatefulWidget {
  const MysteryBoxWidget({
    required this.boxType,
    super.key,
    this.size = 120,
    this.onTap,
  });
  final MysteryBoxType boxType;
  final double size;
  final VoidCallback? onTap;

  @override
  State<MysteryBoxWidget> createState() => _MysteryBoxWidgetState();
}

class _MysteryBoxWidgetState extends State<MysteryBoxWidget>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _rotateController;
  late AnimationController _glowController;
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _rotateController.dispose();
    _glowController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Color _getBoxColor() {
    final config = MysteryBoxService.boxConfigs[widget.boxType];
    return config?.color ?? Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final boxColor = _getBoxColor();

    return GestureDetector(
      onTapDown: (_) {
        _scaleController.forward();
        HapticFeedback.mediumImpact();
      },
      onTapUp: (_) {
        _scaleController.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () {
        _scaleController.reverse();
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _floatController,
          _rotateController,
          _glowController,
          _scaleController,
        ]),
        builder: (context, child) => Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..translate(
              0.0,
              math.sin(_floatController.value * math.pi * 2) * 10,
            )
            ..rotateY(_rotateController.value * math.pi * 2 * 0.1)
            ..scale(1 - (_scaleController.value * 0.1)),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glow effect
                Container(
                  width: widget.size * 1.5,
                  height: widget.size * 1.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        boxColor.withValues(alpha: _glowController.value * 0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                // Box container
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        boxColor.withValues(alpha: 0.9),
                        boxColor.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: boxColor.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Question mark pattern
                      Center(
                        child: Text(
                          '?',
                          style: TextStyle(
                            fontSize: widget.size * 0.4,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                      ),

                      // Sparkle effects
                      ...List.generate(5, (index) {
                        final angle = (index * 72) * math.pi / 180;
                        final radius = widget.size * 0.35;
                        return Positioned(
                          left: widget.size / 2 + math.cos(angle) * radius - 10,
                          top: widget.size / 2 + math.sin(angle) * radius - 10,
                          child: Icon(
                            Icons.auto_awesome,
                            size: 20,
                            color: Colors.white.withValues(alpha: 0.6),
                          )
                              .animate(
                                onPlay: (controller) => controller.repeat(),
                              )
                              .scale(
                                begin: const Offset(0.8, 0.8),
                                end: const Offset(1.2, 1.2),
                                duration: Duration(
                                  milliseconds: 1000 + index * 200,
                                ),
                              )
                              .fadeIn(
                                duration:
                                    Duration(milliseconds: 500 + index * 100),
                              ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Mystery box opening animation
class MysteryBoxOpeningAnimation extends StatefulWidget {
  const MysteryBoxOpeningAnimation({
    required this.boxType,
    required this.rewards,
    required this.onComplete,
    super.key,
  });
  final MysteryBoxType boxType;
  final List<dynamic> rewards;
  final VoidCallback onComplete;

  @override
  State<MysteryBoxOpeningAnimation> createState() =>
      _MysteryBoxOpeningAnimationState();
}

class _MysteryBoxOpeningAnimationState extends State<MysteryBoxOpeningAnimation>
    with TickerProviderStateMixin {
  late AnimationController _wheelController;
  late AnimationController _boxController;
  late AnimationController _revealController;
  int _selectedIndex = 0;
  bool _isSpinning = true;

  @override
  void initState() {
    super.initState();

    _wheelController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _boxController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _revealController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    // Spin the wheel
    await _wheelController.forward();

    setState(() {
      _isSpinning = false;
      _selectedIndex = math.Random().nextInt(widget.rewards.length);
    });

    // Open the box
    await _boxController.forward();

    // Reveal rewards
    await _revealController.forward();

    await Future.delayed(const Duration(seconds: 2));
    widget.onComplete();
  }

  @override
  void dispose() {
    _wheelController.dispose();
    _boxController.dispose();
    _revealController.dispose();
    super.dispose();
  }

  Widget _buildRewardDisplay(dynamic reward) {
    // Check if reward is a MysteryReward with DustBunnies type
    if (reward is MysteryReward && reward.type == RewardType.dustBunnies) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DustBunniesRewardDisplay(
            amount: reward.value,
            size: DustBunniesRewardSize.medium,
            color: Colors.white,
            glowEffect: true,
          ),
        ],
      );
    }

    // For other reward types, show with appropriate icon
    IconData icon;
    String text;

    if (reward is MysteryReward) {
      switch (reward.type) {
        case RewardType.entries:
          icon = Icons.event_note;
          text = reward.name;
          break;
        case RewardType.coins:
          icon = Icons.monetization_on;
          text = reward.name;
          break;
        case RewardType.streakFreeze:
          icon = Icons.ac_unit;
          text = reward.name;
          break;
        case RewardType.dustBunniesBooster:
          icon = Icons.rocket_launch;
          text = reward.name;
          break;
        case RewardType.premium:
          icon = Icons.star;
          text = reward.name;
          break;
        case RewardType.mysteryBox:
          icon = Icons.card_giftcard;
          text = reward.name;
          break;
        default:
          icon = Icons.star;
          text = reward.name;
      }
    } else {
      // Fallback for non-MysteryReward objects
      icon = Icons.star;
      text = reward.toString();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: AppColors.cyberYellow,
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final boxColor =
        MysteryBoxService.boxConfigs[widget.boxType]?.color ?? Colors.grey;

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.9),
      body: Stack(
        children: [
          // Background effects
          const AnimatedGradientBackground(),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Wheel of fortune
                if (_isSpinning)
                  AnimatedBuilder(
                    animation: _wheelController,
                    builder: (context, child) => Transform.rotate(
                      angle: _wheelController.value * math.pi * 10,
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: boxColor,
                            width: 3,
                          ),
                        ),
                        child: CustomPaint(
                          painter: WheelPainter(
                            segments: widget.rewards.length,
                            selectedIndex: _selectedIndex,
                            color: boxColor,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Box opening
                if (!_isSpinning)
                  AnimatedBuilder(
                    animation: _boxController,
                    builder: (context, child) => Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateX(-_boxController.value * math.pi / 4),
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              boxColor,
                              boxColor.withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: boxColor.withValues(alpha: 0.5),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.card_giftcard,
                            size: 80,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 50),

                // Rewards reveal
                if (!_isSpinning)
                  AnimatedBuilder(
                    animation: _revealController,
                    builder: (context, child) => Opacity(
                      opacity: _revealController.value,
                      child: Transform.scale(
                        scale: _revealController.value,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: boxColor.withValues(alpha: 0.5),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'YOU WON!',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  foreground: Paint()
                                    ..shader = const LinearGradient(
                                      colors: [
                                        AppColors.cyberYellow,
                                        AppColors.electricBlue,
                                      ],
                                    ).createShader(
                                      const Rect.fromLTWH(
                                        0.0,
                                        0.0,
                                        200.0,
                                        70.0,
                                      ),
                                    ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Display rewards
                              ...widget.rewards.map(
                                (reward) => Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 5,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        boxColor.withValues(alpha: 0.3),
                                        boxColor.withValues(alpha: 0.1),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: _buildRewardDisplay(reward),
                                ),
                              ),
                            ],
                          ),
                        ),
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
}

// Wheel painter for spinning animation
class WheelPainter extends CustomPainter {
  WheelPainter({
    required this.segments,
    required this.selectedIndex,
    required this.color,
  });
  final int segments;
  final int selectedIndex;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final angle = 2 * math.pi / segments;

    for (var i = 0; i < segments; i++) {
      final startAngle = i * angle;
      final paint = Paint()
        ..color = i == selectedIndex ? color : color.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          angle,
          false,
        )
        ..close();

      canvas.drawPath(path, paint);

      // Draw border
      final borderPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      canvas.drawPath(path, borderPaint);
    }
  }

  @override
  bool shouldRepaint(WheelPainter oldDelegate) => true;
}
