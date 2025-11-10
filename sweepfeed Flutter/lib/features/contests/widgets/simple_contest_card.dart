import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_text_styles.dart';

class SimpleContestCard extends StatelessWidget {
  const SimpleContestCard({
    required this.contest,
    required this.onEnter,
    super.key,
  });
  final Map<String, dynamic> contest;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A2F4B),
              Color(0xFF0F1F35),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Brand Logo
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: contest['logoColor'] ??
                      Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    contest['logoText'] ?? 'a',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: contest['sponsor'] == 'Amazon' ? 28 : 24,
                      fontWeight: FontWeight.bold,
                      fontStyle: contest['sponsor'] == 'Amazon'
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Contest Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contest['title'] ?? '',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          contest['frequency'] ?? 'Daily',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white54,
                          ),
                        ),
                        if (contest['status'] != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '• ${contest['status']}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ends in ${contest['endsIn'] ?? '2 days'}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.red.shade300,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Enter Button
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onEnter();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'Enter Now',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
