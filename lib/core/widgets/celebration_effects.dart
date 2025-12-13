import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:haptic_feedback/haptic_feedback.dart';

import '../theme/app_colors.dart';

class CelebrationEffects extends StatefulWidget {
  const CelebrationEffects({
    required this.type,
    required this.child,
    super.key,
    this.onComplete,
    this.autoPlay = true,
    this.duration,
  });
  final CelebrationType type;
  final VoidCallback? onComplete;
  final Widget child;
  final bool autoPlay;
  final Duration? duration;

  @override
  State<CelebrationEffects> createState() => _CelebrationEffectsState();
}

class _CelebrationEffectsState extends State<CelebrationEffects>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _scaleController;
  late AnimationController _rotateController;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: widget.duration ?? const Duration(seconds: 3),
    );
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    if (widget.autoPlay) {
      _startCelebration();
    }
  }

  Future<void> _startCelebration() async {
    // Haptic feedback
    await Haptics.vibrate(HapticsType.success);

    // Play sound effect
    _playSound();

    // Start visual effects
    _confettiController.play();
    _scaleController.forward();

    if (widget.type == CelebrationType.levelUp ||
        widget.type == CelebrationType.achievement) {
      _rotateController.repeat();
    }

    // Call completion callback after animation
    if (widget.onComplete != null) {
      Future.delayed(
        widget.duration ?? const Duration(seconds: 3),
        widget.onComplete!,
      );
    }
  }

  Future<void> _playSound() async {
    String soundFile;
    switch (widget.type) {
      case CelebrationType.win:
        soundFile = 'sounds/big_win.mp3';
        break;
      case CelebrationType.levelUp:
        soundFile = 'sounds/level_up.mp3';
        break;
      case CelebrationType.achievement:
        soundFile = 'sounds/achievement.mp3';
        break;
      case CelebrationType.streak:
        soundFile = 'sounds/streak_bonus.mp3';
        break;
      case CelebrationType.entry:
        soundFile = 'sounds/entry_success.mp3';
        break;
      default:
        soundFile = 'sounds/success.mp3';
    }

    try {
      await _audioPlayer.play(AssetSource(soundFile));
    } catch (e) {
      // Silently fail if sound file doesn't exist
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scaleController.dispose();
    _rotateController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
        alignment: Alignment.center,
        children: [
          // Main content with scale animation
          AnimatedBuilder(
            animation: _scaleController,
            builder: (context, child) => Transform.scale(
              scale: 1.0 + (_scaleController.value * 0.1),
              child: widget.child,
            ),
          ),

          // Confetti overlay
          Align(
            alignment: _getConfettiAlignment(),
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: _getBlastDirection(),
              blastDirectionality: _getBlastDirectionality(),
              maxBlastForce: _getMaxBlastForce(),
              minBlastForce: _getMinBlastForce(),
              emissionFrequency: _getEmissionFrequency(),
              numberOfParticles: _getNumberOfParticles(),
              gravity: _getGravity(),
              colors: _getConfettiColors(),
              createParticlePath: _drawStar,
            ),
          ),

          // Additional effects based on type
          if (widget.type == CelebrationType.levelUp) _buildLevelUpEffect(),

          if (widget.type == CelebrationType.achievement)
            _buildAchievementEffect(),

          if (widget.type == CelebrationType.streak) _buildStreakEffect(),
        ],
      );

  Alignment _getConfettiAlignment() {
    switch (widget.type) {
      case CelebrationType.win:
        return Alignment.topCenter;
      case CelebrationType.levelUp:
        return Alignment.center;
      default:
        return Alignment.bottomCenter;
    }
  }

  double _getBlastDirection() {
    switch (widget.type) {
      case CelebrationType.win:
        return math.pi / 2; // Down
      case CelebrationType.levelUp:
        return 0; // All directions
      default:
        return -math.pi / 2; // Up
    }
  }

  BlastDirectionality _getBlastDirectionality() =>
      widget.type == CelebrationType.levelUp
          ? BlastDirectionality.explosive
          : BlastDirectionality.directional;

  double _getMaxBlastForce() {
    switch (widget.type) {
      case CelebrationType.win:
        return 100;
      case CelebrationType.levelUp:
        return 50;
      default:
        return 20;
    }
  }

  double _getMinBlastForce() {
    switch (widget.type) {
      case CelebrationType.win:
        return 50;
      case CelebrationType.levelUp:
        return 20;
      default:
        return 10;
    }
  }

  double _getEmissionFrequency() {
    switch (widget.type) {
      case CelebrationType.win:
        return 0.01;
      case CelebrationType.levelUp:
        return 0.02;
      default:
        return 0.05;
    }
  }

  int _getNumberOfParticles() {
    switch (widget.type) {
      case CelebrationType.win:
        return 50;
      case CelebrationType.levelUp:
        return 30;
      default:
        return 20;
    }
  }

  double _getGravity() {
    switch (widget.type) {
      case CelebrationType.win:
        return 0.1;
      case CelebrationType.levelUp:
        return 0.05;
      default:
        return 0.2;
    }
  }

  List<Color> _getConfettiColors() {
    switch (widget.type) {
      case CelebrationType.win:
        return [
          Colors.yellow,
          Colors.orange,
          Colors.red,
          AppColors.accent,
          Colors.purple,
        ];
      case CelebrationType.levelUp:
        return [
          AppColors.accent,
          Colors.blue,
          Colors.cyan,
          Colors.teal,
        ];
      case CelebrationType.achievement:
        return [
          Colors.amber,
          Colors.orange,
          AppColors.accent,
        ];
      case CelebrationType.streak:
        return [
          Colors.red,
          Colors.orange,
          Colors.yellow,
        ];
      default:
        return [
          AppColors.accent,
          AppColors.success,
          Colors.blue,
        ];
    }
  }

  Path _drawStar(Size size) {
    // Draw a simplified broom shape for SweepFeed theme
    final path = Path();
    final width = size.width;
    final height = size.height;

    // Broom bristles (bottom part)
    path.moveTo(width * 0.3, height * 0.7);
    path.lineTo(width * 0.2, height);
    path.lineTo(width * 0.35, height);
    path.lineTo(width * 0.4, height * 0.8);
    path.lineTo(width * 0.45, height);
    path.lineTo(width * 0.5, height * 0.85);
    path.lineTo(width * 0.55, height);
    path.lineTo(width * 0.6, height * 0.8);
    path.lineTo(width * 0.65, height);
    path.lineTo(width * 0.8, height);
    path.lineTo(width * 0.7, height * 0.7);

    // Broom handle (top part)
    path.lineTo(width * 0.55, height * 0.5);
    path.lineTo(width * 0.52, height * 0.2);
    path.lineTo(width * 0.5, 0);
    path.lineTo(width * 0.48, height * 0.2);
    path.lineTo(width * 0.45, height * 0.5);
    path.lineTo(width * 0.3, height * 0.7);

    path.close();
    return path;
  }

  Widget _buildLevelUpEffect() => AnimatedBuilder(
        animation: _rotateController,
        builder: (context, child) => Transform.rotate(
          angle: _rotateController.value * 2 * math.pi,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.accent.withValues(alpha: 0.3),
                  AppColors.accent.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      )
          .animate()
          .fadeIn(duration: 500.ms)
          .scale(
            begin: const Offset(0.5, 0.5),
            end: const Offset(2, 2),
            duration: 1000.ms,
          )
          .fadeOut(delay: 2000.ms, duration: 500.ms);

  Widget _buildAchievementEffect() => Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.amber,
            width: 3,
          ),
        ),
        child: const Icon(
          Icons.emoji_events,
          size: 80,
          color: Colors.amber,
        ),
      )
          .animate()
          .scale(
            begin: const Offset(0, 0),
            duration: 600.ms,
            curve: Curves.elasticOut,
          )
          .shimmer(
              duration: 3000.ms, color: Colors.amber.withValues(alpha: 0.5),)
          .fadeOut(delay: 2500.ms, duration: 500.ms);

  Widget _buildStreakEffect() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          3,
          (index) => const Icon(
            Icons.local_fire_department,
            size: 50,
            color: Colors.orange,
          )
              .animate()
              .fadeIn(delay: Duration(milliseconds: index * 100))
              .scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1.2, 1.2),
                duration: 500.ms,
                curve: Curves.easeOutBack,
              )
              .then()
              .shimmer(duration: 2500.ms)
              .fadeOut(delay: 2000.ms),
        ),
      );
}

enum CelebrationType {
  win,
  levelUp,
  achievement,
  streak,
  entry,
  bonus,
}

// Utility widget for quick celebrations
class QuickCelebration extends StatelessWidget {
  const QuickCelebration({
    required this.child,
    required this.onTap,
    super.key,
    this.celebrationType = CelebrationType.entry,
  });
  final Widget child;
  final Future<void> Function() onTap;
  final CelebrationType celebrationType;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () async {
          // Show celebration overlay
          showDialog(
            context: context,
            barrierDismissible: false,
            barrierColor: Colors.black54,
            builder: (context) => CelebrationEffects(
              type: celebrationType,
              duration: const Duration(seconds: 2),
              onComplete: () => Navigator.of(context).pop(),
              child: const SizedBox.shrink(),
            ),
          );

          // Execute the actual action
          await onTap();
        },
        child: child,
      );
}
