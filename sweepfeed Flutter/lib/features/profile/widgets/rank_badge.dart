import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class RankBadge extends StatelessWidget {
  const RankBadge({
    required this.tier,
    required this.level,
    super.key,
    this.showLevel = true,
  });
  final String tier;
  final int level;
  final bool showLevel;

  @override
  Widget build(BuildContext context) {
    final rankData = _getRankData(tier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: rankData['gradient'] as List<Color>,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:
                (rankData['gradient'] as List<Color>)[0].withValues(alpha: 0.4),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            rankData['icon'] as IconData,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tier.toUpperCase(),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              if (showLevel)
                Text(
                  'Level $level',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getRankData(String tier) {
    switch (tier.toLowerCase()) {
      case 'rookie':
        return {
          'gradient': [const Color(0xFF8B7355), const Color(0xFF5C4A3A)],
          'icon': Icons.stars_outlined,
        };
      case 'bronze':
        return {
          'gradient': [const Color(0xFFCD7F32), const Color(0xFF8B4513)],
          'icon': Icons.military_tech,
        };
      case 'silver':
        return {
          'gradient': [const Color(0xFFC0C0C0), const Color(0xFF808080)],
          'icon': Icons.workspace_premium,
        };
      case 'gold':
        return {
          'gradient': [const Color(0xFFFFD700), const Color(0xFFDAA520)],
          'icon': Icons.emoji_events,
        };
      case 'platinum':
        return {
          'gradient': [const Color(0xFFE5E4E2), const Color(0xFFB0AFA8)],
          'icon': Icons.stars,
        };
      case 'diamond':
        return {
          'gradient': [const Color(0xFF00D9FF), const Color(0xFF0080FF)],
          'icon': Icons.diamond,
        };
      case 'master':
        return {
          'gradient': [const Color(0xFFFF6B9D), const Color(0xFFC239B3)],
          'icon': Icons.celebration,
        };
      case 'legend':
        return {
          'gradient': [const Color(0xFFFFD700), const Color(0xFFFF8C00)],
          'icon': Icons.auto_awesome,
        };
      default:
        return {
          'gradient': [AppColors.primary, AppColors.primaryDark],
          'icon': Icons.person,
        };
    }
  }
}
