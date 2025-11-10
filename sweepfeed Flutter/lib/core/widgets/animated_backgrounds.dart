import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

// Animated gradient background with moving colors
class AnimatedGradientBackground extends StatefulWidget {
  const AnimatedGradientBackground({
    super.key,
    this.colors,
    this.duration = const Duration(seconds: 5),
  });
  final List<Color>? colors;
  final Duration duration;

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Color> _colors;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();

    _colors = widget.colors ??
        [
          AppColors.primaryDark,
          AppColors.primary,
          AppColors.secondary.withValues(alpha: 0.8),
          AppColors.electricBlue.withValues(alpha: 0.6),
        ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(
                math.cos(_controller.value * 2 * math.pi),
                math.sin(_controller.value * 2 * math.pi),
              ),
              end: Alignment(
                -math.cos(_controller.value * 2 * math.pi),
                -math.sin(_controller.value * 2 * math.pi),
              ),
              colors: _colors,
            ),
          ),
        ),
      );
}

// Glass morphism container with blur effect
class GlassMorphismContainer extends StatelessWidget {
  const GlassMorphismContainer({
    required this.child,
    super.key,
    this.blur = 10.0,
    this.opacity = 0.1,
    this.borderRadius,
    this.border,
    this.padding,
    this.margin,
  });
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final Border? border;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) => Container(
        margin: margin,
        child: ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: opacity),
                borderRadius: borderRadius ?? BorderRadius.circular(20),
                border: border ??
                    Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
              ),
              child: child,
            ),
          ),
        ),
      );
}

// Neumorphism container with soft shadows
class NeumorphismContainer extends StatelessWidget {
  const NeumorphismContainer({
    required this.child,
    super.key,
    this.backgroundColor,
    this.depth = 10.0,
    this.borderRadius,
    this.padding,
    this.margin,
  });
  final Widget child;
  final Color? backgroundColor;
  final double depth;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final bgColor =
        backgroundColor ?? Theme.of(context).scaffoldBackgroundColor;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.8),
            offset: Offset(-depth, -depth),
            blurRadius: depth,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            offset: Offset(depth, depth),
            blurRadius: depth,
          ),
        ],
      ),
      child: Container(
        padding: padding,
        child: child,
      ),
    );
  }
}

// Animated particles background
class ParticlesBackground extends StatefulWidget {
  const ParticlesBackground({
    super.key,
    this.particleColor = Colors.white24,
    this.particleCount = 30,
  });
  final Color particleColor;
  final int particleCount;

  @override
  State<ParticlesBackground> createState() => _ParticlesBackgroundState();
}

class _ParticlesBackgroundState extends State<ParticlesBackground>
    with TickerProviderStateMixin {
  late List<Particle> particles;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    particles = List.generate(
      widget.particleCount,
      (index) => Particle(
        position: Offset(
          math.Random().nextDouble(),
          math.Random().nextDouble(),
        ),
        velocity: Offset(
          (math.Random().nextDouble() - 0.5) * 0.01,
          (math.Random().nextDouble() - 0.5) * 0.01,
        ),
        radius: math.Random().nextDouble() * 3 + 1,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => CustomPaint(
          painter: ParticlesPainter(
            particles: particles,
            color: widget.particleColor,
            animation: _controller.value,
          ),
          size: Size.infinite,
        ),
      );
}

class Particle {
  Particle({
    required this.position,
    required this.velocity,
    required this.radius,
  });
  Offset position;
  final Offset velocity;
  final double radius;

  void update() {
    position += velocity;

    // Wrap around edges
    if (position.dx < 0) position = Offset(1.0, position.dy);
    if (position.dx > 1) position = Offset(0.0, position.dy);
    if (position.dy < 0) position = Offset(position.dx, 1.0);
    if (position.dy > 1) position = Offset(position.dx, 0.0);
  }
}

class ParticlesPainter extends CustomPainter {
  ParticlesPainter({
    required this.particles,
    required this.color,
    required this.animation,
  });
  final List<Particle> particles;
  final Color color;
  final double animation;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (final particle in particles) {
      particle.update();

      final position = Offset(
        particle.position.dx * size.width,
        particle.position.dy * size.height,
      );

      canvas.drawCircle(position, particle.radius, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlesPainter oldDelegate) => true;
}

// Aurora/Northern Lights background effect
class AuroraBackground extends StatefulWidget {
  const AuroraBackground({
    super.key,
    this.colors,
  });
  final List<Color>? colors;

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Color> _colors;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();

    _colors = widget.colors ??
        [
          AppColors.cyberYellow.withValues(alpha: 0.3),
          Colors.blue.withValues(alpha: 0.3),
          Colors.purple.withValues(alpha: 0.3),
          Colors.pink.withValues(alpha: 0.3),
        ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => CustomPaint(
          painter: AuroraPainter(
            colors: _colors,
            animation: _controller.value,
          ),
          size: Size.infinite,
        ),
      );
}

class AuroraPainter extends CustomPainter {
  AuroraPainter({
    required this.colors,
    required this.animation,
  });
  final List<Color> colors;
  final double animation;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    for (var i = 0; i < colors.length; i++) {
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment(
            math.sin(animation * 2 * math.pi + i),
            math.cos(animation * 2 * math.pi + i),
          ),
          end: Alignment(
            -math.sin(animation * 2 * math.pi + i),
            -math.cos(animation * 2 * math.pi + i),
          ),
          colors: [
            colors[i].withValues(alpha: 0),
            colors[i],
            colors[i].withValues(alpha: 0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(rect)
        ..blendMode = BlendMode.screen;

      final path = Path();
      final waveHeight = size.height * 0.3;
      final waveOffset = animation * size.width;

      path.moveTo(0, size.height * 0.5);

      for (double x = 0; x <= size.width; x++) {
        final y = size.height * 0.5 +
            math.sin((x + waveOffset) / size.width * 4 * math.pi + i) *
                waveHeight;
        path.lineTo(x, y);
      }

      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(AuroraPainter oldDelegate) => true;
}
