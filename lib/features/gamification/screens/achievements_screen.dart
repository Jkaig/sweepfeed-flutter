import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glassmorphic_container.dart';
import '../../../../core/widgets/animated_gradient_background.dart';
import '../widgets/badge_widget.dart';
import '../models/badge_model.dart' as model;

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _showBadgeDetails(model.Badge badge, bool isUnlocked) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(
              isUnlocked ? badge.icon : Icons.lock,
              size: 64,
              color: isUnlocked ? AppColors.brandGold : Colors.white24,
            ),
            const SizedBox(height: 16),
            Text(badge.name, style: const TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          isUnlocked 
              ? badge.description 
              : 'Keep using SweepFeed to unlock this badge!',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: AppColors.brandCyan)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final achievementsAsync = ref.watch(achievementsProvider);
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Achievements'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedGradientBackground()),
          SafeArea(
            child: achievementsAsync.when(
              data: (badges) {
                return userProfileAsync.when(
                  data: (user) {
                    final unlockedIds = user?.unlockedBadgeIds ?? [];
                    final unlockedCount = unlockedIds.length;
                    final totalCount = badges.length;
                    
                    // Simple progress header
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: GlassmorphicContainer(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                children: [
                                  const Text(
                                    'Your Progress',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  LinearProgressIndicator(
                                    value: totalCount > 0 ? unlockedCount / totalCount : 0,
                                    backgroundColor: Colors.white10,
                                    color: AppColors.brandCyan,
                                    minHeight: 10,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '$unlockedCount / $totalCount Badges Unlocked',
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 0.8,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: badges.length,
                            itemBuilder: (context, index) {
                              final badge = badges[index];
                              final isUnlocked = unlockedIds.contains(badge.id);
                              return BadgeWidget(
                                badge: badge,
                                isUnlocked: isUnlocked,
                                onTap: () => _showBadgeDetails(badge, isUnlocked),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Center(child: Text('Error loading profile')),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, __) => Center(child: Text('Error: $e')),
            ),
          ),
          
          // Confetti Overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
              colors: const [
                AppColors.brandCyan,
                AppColors.brandGold,
                AppColors.brandMagenta,
                Colors.white,
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Debug function to test confetti
          _confettiController.play();
        },
        child: const Icon(Icons.celebration),
        tooltip: 'Celebrate!',
      ),
    );
  }
}
