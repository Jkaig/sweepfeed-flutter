import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class TikTokContestCard extends StatelessWidget {
  const TikTokContestCard({
    required this.contest,
    required this.onEnter,
    required this.onSave,
    super.key,
    this.isEntered = false,
  });
  final Map<String, dynamic> contest;
  final VoidCallback onEnter;
  final VoidCallback onSave;
  final bool isEntered;

  @override
  Widget build(BuildContext context) {
    final endDate = contest['endDate'] as DateTime?;
    final value = contest['value']?.toString() ?? '0';
    final entryCount = contest['entryCount'] ?? 0;
    final category = contest['category'] ?? 'General';
    final frequency = contest['frequency'] ?? 'Single Entry';
    final eligibility = contest['eligibility'] ?? '18+, US only';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A1929),
            Color(0xFF1E3A5F),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section with TikTok branding
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // TikTok Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.music_note,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TikTok Exclusive Giveaway!',
                        style: AppTextStyles.headlineSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        contest['title'] ?? 'Win amazing prizes!',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sponsor Tag
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Sponsor: ',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white54,
                  ),
                ),
                Text(
                  'Giveaways Daily',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Product Image Section
          Container(
            height: 200,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0A1929),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getIconForCategory(category),
                    size: 60,
                    color: AppColors.accent,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Prize',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white54,
                    ),
                  ),
                  Text(
                    contest['title'] ?? '',
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Value',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white54,
                    ),
                  ),
                  Text(
                    '\$$value',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Category and Frequency Tags
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildTag('Category', category),
                const SizedBox(width: 8),
                _buildTag('Frequency', frequency),
              ],
            ),
          ),

          // Contest Details Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contest Details',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDetailRow('Start:', _formatDate(DateTime.now())),
                _buildDetailRow('Ends:', _formatDate(endDate)),
                _buildDetailRow('Eligibility:', eligibility),
                _buildDetailRow('Entry Method:', 'Online'),
              ],
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Enter Contest Button
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    onEnter();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isEntered ? Colors.green : const Color(0xFF0066FF),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: (isEntered
                                  ? Colors.green
                                  : const Color(0xFF0066FF))
                              .withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        isEntered ? '✓ Already Entered' : 'Enter Contest',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 12),

                // View Rules Button
                GestureDetector(
                  onTap: HapticFeedback.lightImpact,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'View Rules',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Save and Comment Row
                Row(
                  children: [
                    // Save for Later
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onSave();
                      },
                      child: Row(
                        children: [
                          const Icon(
                            Icons.bookmark_border,
                            color: Colors.white70,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Save for later',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Add Comment
                    Row(
                      children: [
                        Text(
                          'Add a comment',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white54,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          child: Center(
                            child: Text(
                              '2',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildTag(String label, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: ',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white54,
                fontSize: 11,
              ),
            ),
            Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );

  Widget _buildDetailRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80,
              child: Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white54,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'electronics':
        return Icons.devices;
      case 'cash':
        return Icons.attach_money;
      case 'travel':
        return Icons.flight;
      case 'cars':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'home':
        return Icons.home;
      case 'gift cards':
        return Icons.card_giftcard;
      default:
        return Icons.card_giftcard;
    }
  }
}
