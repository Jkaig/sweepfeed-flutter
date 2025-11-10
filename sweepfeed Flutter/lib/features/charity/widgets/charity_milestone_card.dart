import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class CharityMilestoneCard extends StatefulWidget {
  const CharityMilestoneCard({
    required this.totalAdsWatched,
    required this.totalDonated,
    required this.currentRank,
    super.key,
  });
  final int totalAdsWatched;
  final double totalDonated;
  final int currentRank;

  @override
  State<CharityMilestoneCard> createState() => _CharityMilestoneCardState();
}

class _CharityMilestoneCardState extends State<CharityMilestoneCard>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _scaleController.forward();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  String _getMilestoneMessage() {
    if (widget.totalAdsWatched >= 100) {
      return '🌟 LEGENDARY IMPACT! 🌟';
    } else if (widget.totalAdsWatched >= 50) {
      return '💫 UNSTOPPABLE FORCE! 💫';
    } else if (widget.totalAdsWatched >= 25) {
      return '🔥 ON FIRE! 🔥';
    } else if (widget.totalAdsWatched >= 10) {
      return '✨ MAKING WAVES! ✨';
    } else {
      return '🎉 MILESTONE REACHED! 🎉';
    }
  }

  String _getEncouragingMessage() {
    if (widget.totalAdsWatched >= 100) {
      return "You've made a massive difference! You're a charity champion!";
    } else if (widget.totalAdsWatched >= 50) {
      return "Half a hundred ads! You're changing lives every day!";
    } else if (widget.totalAdsWatched >= 25) {
      return 'Quarter century! Your generosity is inspiring!';
    } else if (widget.totalAdsWatched >= 10) {
      return 'Double digits! Keep up the amazing work!';
    } else {
      return 'Every ad you watch makes a real difference!';
    }
  }

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Confetti
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.03,
                numberOfParticles: 30,
                gravity: 0.15,
                colors: const [
                  Colors.purple,
                  Colors.orange,
                  Colors.green,
                  Colors.pink,
                  Colors.yellow,
                  AppColors.brandCyan,
                  AppColors.primary,
                ],
              ),
            ),

            // Card content
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.shade700,
                      Colors.deepPurple.shade900,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.purple.shade300.withValues(alpha: 0.6),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withValues(alpha: 0.5),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Trophy icon
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Colors.orange, Colors.amber],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withValues(alpha: 0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.emoji_events,
                        color: Colors.white,
                        size: 56,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Milestone message
                    Text(
                      _getMilestoneMessage(),
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    // Ads watched count
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${widget.totalAdsWatched}',
                            style: AppTextStyles.headlineLarge.copyWith(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 42,
                            ),
                          ),
                          Text(
                            'Total Ads Watched',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Total donated
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.brandCyan.withValues(alpha: 0.3),
                            AppColors.primary.withValues(alpha: 0.3),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.brandCyan.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.favorite,
                                color: Colors.pink,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Total Charity Impact',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '\$${widget.totalDonated.toStringAsFixed(2)}',
                            style: AppTextStyles.headlineMedium.copyWith(
                              color: AppColors.brandCyan,
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (widget.currentRank > 0) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.orange, Colors.deepOrange],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.military_tech,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Ranked #${widget.currentRank} This Month',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Encouraging message
                    Text(
                      _getEncouragingMessage(),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),

                    // Continue button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 8,
                        ),
                        child: Text(
                          'Keep Going! 🚀',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}
