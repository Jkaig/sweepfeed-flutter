import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to control confetti globally
final confettiProvider = Provider((ref) => ConfettiController(duration: const Duration(seconds: 2)));

/// Wrapper to display confetti on top of the screen
class ConfettiOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const ConfettiOverlay({
    required this.child,
    super.key,
  });

  @override
  ConsumerState<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends ConsumerState<ConfettiOverlay> {
  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(confettiProvider);
    
    return Stack(
      children: [
        widget.child,
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: controller,
            blastDirection: pi / 2,
            maxBlastForce: 5,
            minBlastForce: 2,
            emissionFrequency: 0.05,
            numberOfParticles: 50,
            gravity: 0.1,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple
            ], 
          ),
        ),
      ],
    );
  }
}
