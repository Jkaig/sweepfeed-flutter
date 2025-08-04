import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/sweepstake.dart';
import '../services/entry_service.dart';
import '../../tracking/services/tracking_service.dart';
import 'package:intl/intl.dart';
import '../../../core/models/sweepstake.dart';

class SweepstakesCard extends StatelessWidget {
  final Sweepstakes sweepstakes;
  final VoidCallback onTap;  
  final VoidCallback? onEnter;
  final VoidCallback? onSave;
  final bool isSaved;

  const SweepstakesCard({
    super.key,
    required this.sweepstakes,
    required this.onTap,
    this.onEnter,
    this.onSave,
    this.isSaved = false,
  });

  @override
  Widget build(BuildContext context) {
    final trackingService = context.watch<TrackingService>();
    final entryService = EntryService(trackingService);
    final canEnter =
        !sweepstakes.isDailyEntry || entryService.canEnterDaily(sweepstakes);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF153450), // Dark blue background
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
                      color: Colors.white.withOpacity(0.7),
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
                            backgroundColor: const Color(0xFF1D8B75),
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
                              color: Colors.white,
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

  Widget _buildTopRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
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
                        );
                      },
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
                    color: Colors.white.withOpacity(0.7),
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
                color: isSaved ? Colors.yellow : Colors.white,
              ),
              onPressed: onSave,
            ),
        ],
      ),
    );
  }

  Widget _buildMetadataItem(String text, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: Colors.white.withOpacity(0.7),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

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
