import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class CharityImpactCard extends StatefulWidget {
  const CharityImpactCard({
    required this.charityId,
    required this.donationAmount,
    required this.pointsEarned,
    super.key,
  });
  final String charityId;
  final double donationAmount;
  final int pointsEarned;

  @override
  State<CharityImpactCard> createState() => _CharityImpactCardState();
}

class _CharityImpactCardState extends State<CharityImpactCard> {
  late ConfettiController _confettiController;
  String charityName = '';
  double communityTotal = 0.0;
  int userRank = 0;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    _confettiController.play();
    _loadData();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/logger.dart';

class CharityImpactCard extends StatefulWidget {
  const CharityImpactCard({
    required this.charityId,
    required this.donationAmount,
    required this.pointsEarned,
    super.key,
  });
  final String charityId;
  final double donationAmount;
  final int pointsEarned;

  @override
  State<CharityImpactCard> createState() => _CharityImpactCardState();
}

class _CharityImpactCardState extends State<CharityImpactCard> {
  late ConfettiController _confettiController;
  String charityName = '';
  double communityTotal = 0.0;
  int userRank = 0;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    _confettiController.play();
    _loadData();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // Load charity name
      final charityDoc = await FirebaseFirestore.instance
          .collection('charities')
          .doc(widget.charityId)
          .get();

      // Load community total
      final communityDoc = await FirebaseFirestore.instance
          .collection('stats')
          .doc('community')
          .get();

      // Calculate user rank
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final usersSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .orderBy('points', descending: true)
            .get();

        final userIndex =
            usersSnapshot.docs.indexWhere((doc) => doc.id == user.uid);

        setState(() {
          charityName = charityDoc.data()?['name'] ?? 'Selected Charity';
          communityTotal =
              (communityDoc.data()?['totalDonated'] ?? 0.0).toDouble();
          userRank = userIndex >= 0 ? userIndex + 1 : 0;
        });
      }
    } catch (e) {
      logger.e('Error loading charity data: $e');
    }
  }

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Confetti
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.05,
                numberOfParticles: 20,
                colors: const [
                  AppColors.primary,
                  AppColors.brandCyan,
                  Colors.orange,
                  Colors.green,
                  Colors.purple,
                ],
              ),
            ),

            // Card content
            Container(
              margin: const EdgeInsets.only(top: 50),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primaryMedium],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.brandCyan.withValues(alpha: 0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandCyan.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Success icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.green, Colors.green.shade700],
                      ),
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Main message
                  Text(
                    'Thank You! 💚',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Donation amount
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style:
                          AppTextStyles.bodyLarge.copyWith(color: Colors.white),
                      children: [
                        const TextSpan(text: 'You just contributed '),
                        TextSpan(
                          text: '\$${widget.donationAmount.toStringAsFixed(3)}',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.brandCyan,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const TextSpan(text: ' to\n'),
                        TextSpan(
                          text: charityName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.brandCyan,
                          ),
                        ),
                        const TextSpan(text: '!'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Community impact
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryMedium.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Community Impact',
                          style: AppTextStyles.titleSmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '\$${communityTotal.toStringAsFixed(2)}',
                          style: AppTextStyles.headlineLarge.copyWith(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'donated this month',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Points earned
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12,),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.brandCyan],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '+${widget.pointsEarned} Sweep Points',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (userRank > 0) ...[
                    const SizedBox(height: 12),
                    Text(
                      "🏆 You're ranked #$userRank this month!",
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Close button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandCyan,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Awesome!',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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
