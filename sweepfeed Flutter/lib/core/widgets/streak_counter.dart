import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';

// Animated streak counter with fire effect
class StreakCounter extends StatefulWidget {
  const StreakCounter({
    required this.currentStreak,
    super.key,
    this.onTap,
  });
  final int currentStreak;
  final VoidCallback? onTap;

  @override
  State<StreakCounter> createState() => _StreakCounterState();
}

class _StreakCounterState extends State<StreakCounter>
    with TickerProviderStateMixin {
  late AnimationController _fireController;
  late AnimationController _scaleController;
  late List<FireParticle> _fireParticles;

  @override
  void initState() {
    super.initState();

    _fireController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _generateFireParticles();
  }

  void _generateFireParticles() {
    _fireParticles = List.generate(
      20,
      (index) => FireParticle(
        position: Offset(
          math.Random().nextDouble() * 40,
          40 + math.Random().nextDouble() * 20,
        ),
        velocity: Offset(
          (math.Random().nextDouble() - 0.5) * 2,
          -math.Random().nextDouble() * 3 - 1,
        ),
        life: math.Random().nextDouble(),
        size: math.Random().nextDouble() * 4 + 2,
      ),
    );
  }

  Color _getFireColor(int streak) {
    if (streak == 0) return Colors.grey;
    if (streak < 3) return Colors.orange.shade400;
    if (streak < 7) return Colors.orange;
    if (streak < 14) return Colors.deepOrange;
    if (streak < 30) return Colors.red;
    return Colors.red.shade900; // Epic streak!
  }

  String _getStreakTitle(int streak) {
    if (streak == 0) return 'Start Streak';
    if (streak < 3) return 'Getting Started';
    if (streak < 7) return 'On Fire!';
    if (streak < 14) return 'Blazing!';
    if (streak < 30) return 'Unstoppable!';
    if (streak < 60) return 'Legendary!';
    return 'GODLIKE!';
  }

  @override
  void dispose() {
    _fireController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fireColor = _getFireColor(widget.currentStreak);
    final isActive = widget.currentStreak > 0;

    return GestureDetector(
      onTapDown: (_) {
        _scaleController.forward();
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        _scaleController.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () {
        _scaleController.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleController,
        builder: (context, child) => Transform.scale(
          scale: 1 - (_scaleController.value * 0.05),
          child: Container(
            width: 80,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isActive
                    ? [
                        fireColor.withValues(alpha: 0.3),
                        fireColor.withValues(alpha: 0.1),
                      ]
                    : [
                        Colors.grey.withValues(alpha: 0.2),
                        Colors.grey.withValues(alpha: 0.1),
                      ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive
                    ? fireColor.withValues(alpha: 0.5)
                    : Colors.grey.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: fireColor.withValues(alpha: 0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Fire particles
                if (isActive)
                  AnimatedBuilder(
                    animation: _fireController,
                    builder: (context, child) => CustomPaint(
                      size: const Size(80, 60),
                      painter: FirePainter(
                        particles: _fireParticles,
                        animation: _fireController.value,
                        color: fireColor,
                      ),
                    ),
                  ),

                // Fire icon
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glow effect
                        if (isActive)
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  fireColor.withValues(alpha: 0.6),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),

                        Icon(
                          Icons.local_fire_department,
                          color: isActive ? fireColor : Colors.grey,
                          size: 28,
                        )
                            .animate(
                              onPlay: isActive
                                  ? (controller) =>
                                      controller.repeat(reverse: true)
                                  : null,
                            )
                            .scale(
                              begin: const Offset(1.0, 1.0),
                              end: const Offset(1.1, 1.1),
                              duration: 1.seconds,
                            ),
                      ],
                    ),

                    const SizedBox(height: 2),

                    // Streak count
                    Text(
                      '${widget.currentStreak}',
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Fire particle for animation
class FireParticle {
  FireParticle({
    required this.position,
    required this.velocity,
    required this.life,
    required this.size,
  });
  Offset position;
  final Offset velocity;
  double life;
  final double size;

  void update(double dt) {
    position += velocity * dt * 20;
    life -= dt * 0.5;

    if (life <= 0) {
      // Reset particle
      position = Offset(
        20 + math.Random().nextDouble() * 40,
        40 + math.Random().nextDouble() * 20,
      );
      life = 1.0;
    }
  }
}

class FirePainter extends CustomPainter {
  FirePainter({
    required this.particles,
    required this.animation,
    required this.color,
  });
  final List<FireParticle> particles;
  final double animation;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      particle.update(0.016); // ~60fps

      if (particle.life <= 0) continue;

      final paint = Paint()
        ..color = color.withValues(alpha: particle.life * 0.8)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        particle.position,
        particle.size * particle.life,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(FirePainter oldDelegate) => true;
}

// Streak calendar widget
class StreakCalendar extends StatelessWidget {
  const StreakCalendar({
    required this.streakHistory,
    required this.currentStreak,
    required this.longestStreak,
    super.key,
  });
  final Map<DateTime, bool> streakHistory;
  final int currentStreak;
  final int longestStreak;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withValues(alpha: 0.3),
            Colors.black.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.cyberYellow.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Streak',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '$currentStreak days',
                    style: const TextStyle(
                      color: AppColors.cyberYellow,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Longest Streak',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '$longestStreak days',
                    style: const TextStyle(
                      color: AppColors.electricBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: daysInMonth,
            itemBuilder: (context, index) {
              final day = index + 1;
              final date = DateTime(now.year, now.month, day);
              final hasStreak = streakHistory[date] ?? false;
              final isToday = day == now.day;
              final isFuture = date.isAfter(now);

              return Container(
                decoration: BoxDecoration(
                  color: hasStreak
                      ? AppColors.cyberYellow.withValues(alpha: 0.8)
                      : isFuture
                          ? Colors.grey.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: isToday
                      ? Border.all(
                          color: AppColors.electricBlue,
                          width: 2,
                        )
                      : null,
                  boxShadow: hasStreak
                      ? [
                          BoxShadow(
                            color: AppColors.cyberYellow.withValues(alpha: 0.5),
                            blurRadius: 4,
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      color: hasStreak
                          ? Colors.black
                          : isFuture
                              ? Colors.grey
                              : Colors.white.withValues(alpha: 0.5),
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: index * 10))
                  .scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.0, 1.0),
                  );
            },
          ),

          const SizedBox(height: 20),

          // Streak milestones
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMilestone(3, 'Starter', currentStreak >= 3),
              _buildMilestone(7, 'Week', currentStreak >= 7),
              _buildMilestone(30, 'Month', currentStreak >= 30),
              _buildMilestone(100, 'Legend', currentStreak >= 100),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMilestone(int days, String label, bool achieved) => Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: achieved
                  ? const LinearGradient(
                      colors: [
                        AppColors.cyberYellow,
                        AppColors.electricBlue,
                      ],
                    )
                  : null,
              color: achieved ? null : Colors.grey.withValues(alpha: 0.3),
              boxShadow: achieved
                  ? [
                      BoxShadow(
                        color: AppColors.cyberYellow.withValues(alpha: 0.5),
                        blurRadius: 10,
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: Text(
                '$days',
                style: TextStyle(
                  color: achieved ? Colors.black : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: achieved ? Colors.white : Colors.grey,
              fontSize: 10,
            ),
          ),
        ],
      ).animate().fadeIn().scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1.0, 1.0),
          );
}
