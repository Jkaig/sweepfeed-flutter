import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/sweepstake.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';

class SweepstakesCard extends ConsumerWidget {
  const SweepstakesCard({
    required this.sweepstakes,
    required this.onTap,
    super.key,
    this.onEnter,
    this.onSave,
    this.isSaved = false,
  });
  final Sweepstakes sweepstakes;
  final VoidCallback onTap;
  final VoidCallback? onEnter;
  final VoidCallback? onSave;
  final bool isSaved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entryService = ref.watch(entryServiceProvider);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryMedium, // Matches website #112240
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopRow(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sweepstakes.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sweepstakes.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildMetadataItem(
                        sweepstakes.frequencyText,
                        Icons.repeat,
                      ),
                      const SizedBox(width: 16),
                      _buildMetadataItem(
                        'Ends in ${_formatDaysRemaining()}',
                        Icons.calendar_today,
                      ),
                      const Spacer(),
                      if (onEnter != null)
                        ElevatedButton(
                          onPressed: onEnter,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                AppColors.brandCyan, // Match website accent
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Enter Now',
                            style: TextStyle(
                              color: AppColors.primaryDark, // Dark text on cyan
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopRow() => Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: sweepstakes.imageUrl.isNotEmpty
                    ? Image.network(
                        sweepstakes.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Text(
                            sweepstakes.sponsor.isNotEmpty
                                ? sweepstakes.sponsor[0].toUpperCase()
                                : 'S',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          sweepstakes.sponsor.isNotEmpty
                              ? sweepstakes.sponsor[0].toUpperCase()
                              : 'S',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sweepstakes.formattedPrizeValue,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    sweepstakes.sponsor,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (onSave != null)
              IconButton(
                icon: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: isSaved ? AppColors.brandCyan : AppColors.textWhite,
                ),
                onPressed: onSave,
              ),
          ],
        ),
      );

  Widget _buildMetadataItem(String text, IconData icon) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: AppColors.textLight,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 12,
            ),
          ),
        ],
      );

  String _formatDaysRemaining() {
    final days = sweepstakes.daysRemaining;
    if (days == 0) {
      return 'Today';
    } else if (days == 1) {
      return '1 day';
    } else {
      return '$days days';
    }
  }
}
